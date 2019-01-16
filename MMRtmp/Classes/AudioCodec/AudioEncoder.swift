//
//  AudioEncoder.swift
//  MMRtmp
//
//  Created by Millman on 2018/12/14.
//

import Foundation
import VideoToolbox
protocol AudioEncoderDelegate: class {
    func output(encoder: AudioEncoder, data: Data, delta: TimeInterval)
    func outputHeader(encoder: AudioEncoder, data: Data)
}


extension AudioEncoder {
    static let defaultFramesPerPacket: UInt32 = 1024
    static let defaulClassDesc: [AudioClassDescription] = [
        AudioClassDescription(mType: kAudioEncoderComponentType, mSubType: kAudioFormatMPEG4AAC, mManufacturer: kAppleSoftwareAudioCodecManufacturer),
        AudioClassDescription(mType: kAudioEncoderComponentType, mSubType: kAudioFormatMPEG4AAC, mManufacturer: kAppleHardwareAudioCodecManufacturer)
    ]
}

class AudioEncoder {
    var isStartEncode = false {
        didSet {
            if isStartEncode {
                self.outputStreamDesc = nil
            }
        }
    }


    let audioQueue = DispatchQueue(label: "mmrtmp.encode.aac")
    unowned let delegate: AudioEncoderDelegate
    var bufferListParameter = (maxSize: 1, listSize: AudioBufferList.sizeInBytes(maximumBuffers: 1))
    fileprivate var currentBufferList: UnsafeMutableAudioBufferListPointer?
    var timestamp: TimeInterval = 0
    fileprivate var converter: AudioConverterRef?
    fileprivate var outputStreamDesc: AudioStreamBasicDescription?
    fileprivate var inFormatDescription: AudioStreamBasicDescription?
    fileprivate var outFormatDescription: CMFormatDescription? {
        didSet {
            guard isStartEncode,
                  let streamBasicDesc = self.outFormatDescription?.streamBasicDesc,
                  let mp4Id = MPEG4ObjectID(rawValue: Int(streamBasicDesc.mFormatFlags)) else {
                    return
            }
            var descData = Data()
            let config = AudioSpecificConfig(objectType: mp4Id,
                                             channelConfig: ChannelConfigType(rawValue: UInt8(streamBasicDesc.mChannelsPerFrame)),
                                             frequencyType: SampleFrequencyType(value: streamBasicDesc.mSampleRate))
            
            descData.extendWrite.write(aacHeader)
                .write(AudioData.AACPacketType.header.rawValue)
                .write(config.encodeData)
            self.delegate.outputHeader(encoder: self, data: descData)

        }
    }
    
    var aacHeader: Data {
        get {
            guard let desc = self.outFormatDescription,
                  let streamBasicDesc = desc.streamBasicDesc else {
                    return Data()
            }
            let value = (AudioData.SoundFormat.aac.rawValue << 4 |
                AudioData.SoundRate(value: streamBasicDesc.mSampleRate).rawValue << 2 |
                AudioData.SoundSize.snd16Bit.rawValue << 1 |
                AudioData.SoundType.sndStereo.rawValue)
            return Data([UInt8(value)])
        }
    }
    
    fileprivate var inputDataProc: AudioConverterComplexInputDataProc = {(
        converter: AudioConverterRef,
        ioNumberDataPackets: UnsafeMutablePointer<UInt32>,
        ioData: UnsafeMutablePointer<AudioBufferList>,
        outDataPacketDescription: UnsafeMutablePointer<UnsafeMutablePointer<AudioStreamPacketDescription>?>?,
        inUserData: UnsafeMutableRawPointer?) in
        return Unmanaged<AudioEncoder>.fromOpaque(inUserData!).takeUnretainedValue().inputDataForAudioConverter(
            ioNumberDataPackets,
            ioData: ioData,
            outDataPacketDescription: outDataPacketDescription
        )
    }

    
    fileprivate func inputDataForAudioConverter(
        _ ioNumberDataPackets: UnsafeMutablePointer<UInt32>,
        ioData: UnsafeMutablePointer<AudioBufferList>,
        outDataPacketDescription: UnsafeMutablePointer<UnsafeMutablePointer<AudioStreamPacketDescription>?>?) -> OSStatus {
        
        guard let bufferList: UnsafeMutableAudioBufferListPointer = currentBufferList else {
            ioNumberDataPackets.pointee = 0
            return -1
        }
        
        memcpy(ioData, bufferList.unsafePointer, bufferListParameter.listSize)
        ioNumberDataPackets.pointee = 1
        free(bufferList.unsafeMutablePointer)
        currentBufferList = nil
        return noErr
    }

    init(delegate: AudioEncoderDelegate) {
        self.delegate = delegate
    }
    
    func encode(buffer: CMSampleBuffer) {
        audioQueue.async { [weak self] in
            self?._encode(buffer: buffer)
        }
    }
    fileprivate func _encode(buffer: CMSampleBuffer) {
        guard let desc: CMAudioFormatDescription = CMSampleBufferGetFormatDescription(buffer), var streamDesc = desc.streamBasicDesc else {
            return
        }

        if self.inFormatDescription == nil {
            self.inFormatDescription = streamDesc
            bufferListParameter = (Int(streamDesc.mChannelsPerFrame), AudioBufferList.sizeInBytes(maximumBuffers: Int(streamDesc.mChannelsPerFrame)))
        }
        if self.outputStreamDesc == nil {
            self.outputStreamDesc = self.createOutputDesc(formatStreamDesc: &streamDesc)
            CMAudioFormatDescriptionCreate(allocator: kCFAllocatorDefault, asbd: &outputStreamDesc!, layoutSize: 0, layout: nil, magicCookieSize: 0, magicCookie: nil, extensions: nil, formatDescriptionOut: &outFormatDescription)
            self.timestamp = buffer.presentedTimestamp.seconds
        }

        let list = AudioBufferList.allocate(maximumBuffers: bufferListParameter.maxSize)
        
        guard isStartEncode, let blockBuffer = self.generateBlockBufferFrom(buffer: buffer, list: list) else {
            return
        }
        
        currentBufferList = list
        
        if self.converter == nil, var output = self.outputStreamDesc {
            self.converter = self.createAudioConverter(formatStreamDesc: &streamDesc, destinationDesc: &output)
        }
        var ioOutputDataPacketSize: UInt32 = 1
        let outOutputData: UnsafeMutableAudioBufferListPointer = AudioBufferList.allocate(maximumBuffers: Int(ioOutputDataPacketSize))
        outOutputData[0].mNumberChannels = inFormatDescription!.mChannelsPerFrame
        outOutputData[0].mDataByteSize = UInt32(blockBuffer.length)
        outOutputData[0].mData = UnsafeMutableRawPointer.allocate(byteCount: blockBuffer.length, alignment: 0)
        let status = AudioConverterFillComplexBuffer(converter!,
                                                     inputDataProc,
                                                     Unmanaged.passUnretained(self).toOpaque(),
                                                     &ioOutputDataPacketSize,
                                                     outOutputData.unsafeMutablePointer,
                                                     nil)
        let delta = TimeInterval((buffer.presentedTimestamp.seconds-self.timestamp)*1000)
        self.timestamp = buffer.presentedTimestamp.seconds
        switch status {
        case noErr:
            guard let mData = outOutputData[0].mData?.assumingMemoryBound(to: UInt8.self) else {
                return
            }
            let output = Data.init(bytes: mData, count: Int(outOutputData[0].mDataByteSize))
            var data = Data()
            data.extendWrite.write(aacHeader)
                .write(AudioData.AACPacketType.raw.rawValue)
                .write(output)
            self.delegate.output(encoder: self, data: data, delta: delta)
        default:
            break
        }
    }

    fileprivate func generateBlockBufferFrom(buffer: CMSampleBuffer, list: UnsafeMutableAudioBufferListPointer) -> CMBlockBuffer? {
        var blockBuffer: CMBlockBuffer?
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(buffer,
                                                                bufferListSizeNeededOut: nil,
                                                                bufferListOut: list.unsafeMutablePointer,
                                                                bufferListSize: bufferListParameter.listSize,
                                                                blockBufferAllocator: kCFAllocatorDefault,
                                                                blockBufferMemoryAllocator: kCFAllocatorDefault,
                                                                flags: 0,
                                                                blockBufferOut: &blockBuffer)
        
        return blockBuffer
    }
    
    fileprivate func createAudioConverter(formatStreamDesc: inout AudioStreamBasicDescription, destinationDesc: inout AudioStreamBasicDescription) -> AudioConverterRef? {
        var converter: AudioConverterRef?
        AudioConverterNewSpecific(&formatStreamDesc, &destinationDesc, UInt32(AudioEncoder.defaulClassDesc.count), AudioEncoder.defaulClassDesc, &converter)
        return converter
    }
    
    fileprivate func createOutputDesc(formatStreamDesc: inout AudioStreamBasicDescription) -> AudioStreamBasicDescription {
        let flag = UInt32(MPEG4ObjectID.AAC_LC.rawValue)
        let output =  AudioStreamBasicDescription(
            mSampleRate: formatStreamDesc.mSampleRate,
            mFormatID: kAudioFormatMPEG4AAC,
            mFormatFlags: flag,
            mBytesPerPacket: 0,
            mFramesPerPacket: AudioEncoder.defaultFramesPerPacket,
            mBytesPerFrame: 0,
            mChannelsPerFrame: formatStreamDesc.mChannelsPerFrame,
            mBitsPerChannel: 0,
            mReserved: 0)
        return output
    }
}
