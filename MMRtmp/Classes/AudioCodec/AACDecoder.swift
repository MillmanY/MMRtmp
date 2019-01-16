//
//  AACDecoder.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/7.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
import AudioToolbox
/*
 ADTS(FixHeader+VariableHeader)+AAC = 7 bytes
 FixHeader
 ------------------------------
 | syncword (12)              |
 | id (1)                     |
 | layer (2)                  |
 | protection_absent (1)      |
 | profile(2)                 |
 | sample_frequency_index (4) |
 | private_bit (1)            |
 | channel_configration (3)   |
 | original_copy (1)          |
 | home (1)                   |
 ------------------------------
 VariableHeader
 ------------------------------------------
 | copyright_identification_bit (1)       |
 | copyright_identification_start (1)     |
 | aac_frame_length (13)                  |
 | adts_buffer_fullness (11)              |
 | number_of_raw_data_blocks_in_frame (2) |
 ------------------------------------------
*/
public enum DecodeError: Error {
    public typealias RawValue = Int
    case initError
}

protocol AACDecoderDelegate: class {
    func aacOutput(_ decoder: AACDecoder, info: AudioBuffer)
    func aacSetDescOutput(_ decoder: AACDecoder, info: AudioHeader)
}

public class AACDecoder {
    let queue = DispatchQueue.init(label: "mmRtmp.AACDecoder.lock")

    var audioSpecConfig: AudioSpecificConfig?
    var streamDesc: AudioStreamBasicDescription?
    unowned let delegate: AACDecoderDelegate
    var packetCallBack: AudioFileStream_PacketsProc = { (
        inClientData: UnsafeMutableRawPointer,
        inNumberBytes: UInt32,
        inNumberPackets: UInt32,
        inInputData: UnsafeRawPointer,
        inPacketDescriptions: UnsafeMutablePointer<AudioStreamPacketDescription>) in

        let decode: AACDecoder = unsafeBitCast(inClientData, to: AACDecoder.self)
        decode.packetCallBack(inNumberBytes, numberPackets: inNumberPackets, inputData: inInputData, desc: inPacketDescriptions)
    }
    
    var propertyListenerCallBack: AudioFileStream_PropertyListenerProc = { (
        inClientData: UnsafeMutableRawPointer,
        inAudioFileStream: AudioFileStreamID,
        inPropertyID: AudioFileStreamPropertyID,
        ioFlags: UnsafeMutablePointer<AudioFileStreamPropertyFlags>) in
        let decode: AACDecoder = unsafeBitCast(inClientData, to: AACDecoder.self)
        decode.listenCallBack(inAudioFileStream: inAudioFileStream, inPropertyID: inPropertyID, ioFlags: ioFlags)
    }
    
    var streamID: AudioFileStreamID!
    init(delegate: AACDecoderDelegate, type: AudioFileTypeID, startTime: Int64) throws {
        self.start = startTime
        self.lastInterval = startTime
        self.delegate = delegate
        var streamId: OpaquePointer?
        AudioFileStreamOpen(unsafeBitCast(self, to: UnsafeMutableRawPointer.self), propertyListenerCallBack, packetCallBack, type, &streamId)
        guard let id = streamId else {
            throw DecodeError.initError
        }
        self.streamID = id
    }
    private var headerSize = 0
    private(set) var start: Int64
    private(set) var lastInterval: Int64
//    func setInit(timeStamp: Int64) {
//        queue.async { [weak self] in
//            self?.start = timeStamp
//            self?.lastInterval = timeStamp
//        }
//    }
    
    func decode(data: Data, delta: Int64) {
        queue.async { [weak self] in
            self?._decode(data: data, delta: delta)
        }
    }

    fileprivate func _decode(data: Data, delta: Int64) {
        if data.count <= headerSize {
            return
        }
        
        
        guard let _ = streamDesc, let type = data[safe: 1],
            AudioData.AACPacketType(rawValue: type) == .raw else {
            self.setDesc(data: data)
            return
        }
        let shift = data.advanced(by: headerSize)
        if let adts = self.adts(dataLength: shift.count) {
            var combine = Data(adts)
            combine.append(shift)
            combine.withUnsafeBytes { [unowned self] (bytes:UnsafePointer<UInt8>) -> Void in
                AudioFileStreamParseBytes(self.streamID, UInt32(combine.count), bytes, AudioFileStreamParseFlags(rawValue: 0))
            }
        }
        self.lastInterval += delta
    }
    
    private func setDesc(data: Data) {
        guard let config0 = data[safe: 2],
            let config1 = data[safe: 3] else {
                return
        }
        let config = AudioSpecificConfig(data: Data([config0,config1]))
        audioSpecConfig = config
        if let first = data.first,
            let format = AudioData.SoundFormat(rawValue: Int(first & 0b11110000) >> 4){
        
            self.streamDesc = AudioStreamBasicDescription(mSampleRate: Float64(config.frequencyType.value),
                                                          mFormatID: kAudioFormatMPEG4AAC,
                                                          mFormatFlags: AudioFormatFlags(config.objectType.rawValue),
                                                          mBytesPerPacket: 0,
                                                          mFramesPerPacket: 1024,
                                                          mBytesPerFrame: 0,
                                                          mChannelsPerFrame: UInt32(config.channelConfig.rawValue),
                                                          mBitsPerChannel: 0,
                                                          mReserved: 0)
            headerSize = format.headerSize
        }
    }
    
    private func packetCallBack(_ numberBytes: UInt32, numberPackets: UInt32, inputData: UnsafeRawPointer, desc: UnsafeMutablePointer<AudioStreamPacketDescription>) {
        (0..<numberPackets).forEach { (value) in
            let packetDesc = desc[Int(value)]
            let start = Int(packetDesc.mStartOffset)
            let size = packetDesc.mDataByteSize

            let data = Data(bytes: inputData.advanced(by: start), count: Int(size))
            let buffer = AudioBuffer(data: data, desc: packetDesc, timestamp: self.lastInterval)
            delegate.aacOutput(self, info: buffer)
        }
    }
    
    private func listenCallBack(inAudioFileStream: AudioFileStreamID, inPropertyID: AudioFileStreamPropertyID, ioFlags: UnsafeMutablePointer<AudioFileStreamPropertyFlags>) {
        switch inPropertyID {
        case kAudioFileStreamProperty_DataFormat:
            guard let fileStreamID:AudioFileStreamID = streamID else {
                return
            }
            var data:AudioStreamBasicDescription = AudioStreamBasicDescription()
            var size:UInt32 = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
            guard AudioFileStreamGetProperty(fileStreamID, kAudioFileStreamProperty_DataFormat, &size, &data) == noErr else {
                return
            }
            self.streamDesc = data
            self.updateStreamDesc()
        default:
            break
        }
    }
    
    private func adts(dataLength: Int) -> [UInt8]? {
        let bitData = BitData()
        do {
            guard let config = self.audioSpecConfig else {
                return nil
            }
            let headerSize = 7
            bitData.append(datas: (0...11).map { _ in BitType.one })
            bitData.append(data: BitType.one)
            bitData.append(datas: [.zero, .zero])
            bitData.append(data: .one)
            try bitData.append(number: 1, bitCount: 2)
            try bitData.append(number: Int(config.frequencyType.rawValue), bitCount: 4)
            bitData.append(data: .zero)
            try bitData.append(number: Int(config.channelConfig.rawValue), bitCount: 3)
            bitData.append(datas: [.zero,.zero,.zero,.zero])
            try bitData.append(number: dataLength+headerSize, bitCount: 13)
            try bitData.append(number: 0x7ff, bitCount: 11)
            try bitData.append(number: 0, bitCount: 2)
        } catch _ {
            return nil
        }
        return bitData.bytes()
    }

    func updateStreamDesc() {
        if var s = streamDesc {
            self.delegate.aacSetDescOutput(self, info: AudioHeader(desc: s, startTime: self.start))
        }
    }
 
    deinit {
        AudioFileStreamClose(streamID)
        print("AACDecoder")
    }
}
