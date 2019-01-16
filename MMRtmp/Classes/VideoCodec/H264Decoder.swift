//
//  H264Decoder.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/27.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
import AVFoundation
import VideoToolbox
import UIKit
public protocol H264DecoderDelegate: class {
    func h264Output(_ decoder: H264Decoder, info: VideoBuffer)
    func h264SetDescOutput(_ decoder: H264Decoder, info: VideoHeader)
}

public class H264Decoder {
    let queue = DispatchQueue.init(label: "mmRtmp.h264Decoder.lock")
    var sps = [[UInt8]]()
    var pps = [[UInt8]]()
    unowned let delegate: H264DecoderDelegate
    private(set) var start: Int64
    private(set) var lastInterval: Int64

    init(delegate: H264DecoderDelegate, startTime: Int64) {
        self.delegate = delegate
        self.start = startTime
        self.lastInterval = startTime
    }

    static let defaultAttributes:[NSString: AnyObject] = [
        kCVPixelBufferPixelFormatTypeKey: NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange),
        kCVPixelBufferIOSurfacePropertiesKey: [:] as AnyObject,
        kCVPixelBufferOpenGLCompatibilityKey: NSNumber(value: true),
        kCVPixelBufferOpenGLESCompatibilityKey: NSNumber(value: true)
        ]
    public var videoDesc: CMVideoFormatDescription? {
        didSet {
            guard let desc = videoDesc else {
                return
            }
            VTDecompressionSessionCreate(allocator: kCFAllocatorDefault,
                                         formatDescription: desc,
                                         decoderSpecification: nil ,
                                         imageBufferAttributes: H264Decoder.defaultAttributes as CFDictionary,
                                         outputCallback: nil,
                                         decompressionSessionOut: &session)
        }
    }
    var session: VTDecompressionSession?
    func setDesc(first: Data) {
        if first.count < 5 {
            return
        }
        
        let shift = first.advanced(by: 5)
        var byte = ByteReader(shift)
        byte.shiftPosition(loc: 4)
        if let reservedWithMinusOne = byte.readUInt8 ,
           let reverseWithSPS = byte.readUInt8  {
            let nulaLength = (reservedWithMinusOne & 0b0000011) + 1

            var spsSet = [[UInt8]]()
            var ppsSet = [[UInt8]]()
            let sps = Int(reverseWithSPS & 0b00011111)
            
            if sps == 0 {
                return
            }
            
            (0..<sps).forEach({ _ in
                if let length = byte.readUInt16(),
                    let sub = byte.read(length: Int(length)) {
                    spsSet.append(sub.bytes)
                }
            })
            
            if let pps = byte.readUInt8 {
                (0..<pps).forEach({ _ in
                    if let length = byte.readUInt16(),
                        let sub = byte.read(length: Int(length)) {
                        ppsSet.append(sub.bytes)
                    }
                })
            }
            if spsSet.count > 0 && ppsSet.count > 0 {
                var parameterSetPointers:[UnsafePointer<UInt8>] = [
                    UnsafePointer<UInt8>(ppsSet[0]),
                    UnsafePointer<UInt8>(spsSet[0])
                ]
                var parameterSetSizes:[Int] = [
                    ppsSet[0].count,
                    spsSet[0].count
                ]
                CMVideoFormatDescriptionCreateFromH264ParameterSets(allocator: kCFAllocatorDefault, parameterSetCount: 2, parameterSetPointers: &parameterSetPointers, parameterSetSizes: &parameterSetSizes, nalUnitHeaderLength: Int32(nulaLength), formatDescriptionOut: &videoDesc)
            }
        } else {
        }
    }
    
    func decode(data: Data, delta: Int64) {
        queue.async { [weak self] in
            self?._decode(data: data, delta: delta)
        }
    }
    fileprivate func _decode(data: Data, delta: Int64) {
        guard let packetByte = data[safe: 1] else {
            return
        }
        switch VideoData.AVCPacketType(rawValue: packetByte) {
        case .header:
            self.setDesc(first: data)
            if let d = videoDesc {
                self.delegate.h264SetDescOutput(self, info: VideoHeader(desc: d, startTime: delta))
            }
        case .nalu:
            if data.count <= 5 {
                return
            }
            var d = data.advanced(by: 5)
            let origin = d.count
            d.withUnsafeMutableBytes { [unowned self] (bytes: UnsafeMutablePointer<UInt8>) -> Void in
                var block: CMBlockBuffer?
                if CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault,
                                                      memoryBlock: bytes,
                                                      blockLength: origin,
                                                      blockAllocator: kCFAllocatorNull,
                                                      customBlockSource: nil,
                                                      offsetToData: 0,
                                                      dataLength: origin, flags: 0,
                                                      blockBufferOut: &block) != noErr {
                    return
                }
            
                var timeInfo = CMSampleTimingInfo(duration: CMTimeMake(value: delta, timescale: 1000),
                                                  presentationTimeStamp: CMTimeMake(value: self.lastInterval,
                                                    timescale: 1000),
                                                  decodeTimeStamp: CMTime.invalid)
                
                var sampleBuffer: CMSampleBuffer?
                var size = [origin]
                CMSampleBufferCreateReady(allocator: kCFAllocatorDefault,
                                          dataBuffer: block,
                                          formatDescription: self.videoDesc,
                                          sampleCount: 1,
                                          sampleTimingEntryCount: 1,
                                          sampleTimingArray: &timeInfo,
                                          sampleSizeEntryCount: 1,
                                          sampleSizeArray: &size,
                                          sampleBufferOut: &sampleBuffer)
                guard let sample = sampleBuffer else {
                    return
                }
                guard let s = self.session else {
                    return
                }
                var flagOut = VTDecodeInfoFlags.frameDropped
                let status = VTDecompressionSessionDecodeFrame(s, sampleBuffer: sample, flags: VTDecodeFrameFlags._EnableAsynchronousDecompression, infoFlagsOut: &flagOut, outputHandler: { [weak self] (status, flags, buffer, time, duration) in
                    if let b = buffer {
                        var timingInfo:CMSampleTimingInfo = CMSampleTimingInfo(
                            duration: duration,
                            presentationTimeStamp: time,
                            decodeTimeStamp: CMTime.invalid
                        )
                        
                        var videoFormatDescription:CMVideoFormatDescription? = nil
                        CMVideoFormatDescriptionCreateForImageBuffer(
                            allocator: kCFAllocatorDefault,
                            imageBuffer: b,
                            formatDescriptionOut: &videoFormatDescription
                        )
                
                        var convert:CMSampleBuffer?
                        CMSampleBufferCreateForImageBuffer(
                            allocator: kCFAllocatorDefault,
                            imageBuffer: b,
                            dataReady: true,
                            makeDataReadyCallback: nil,
                            refcon: nil,
                            formatDescription: videoFormatDescription!,
                            sampleTiming: &timingInfo,
                            sampleBufferOut: &convert
                        )
                        
                        if let c = convert, let self = self {
                            self.delegate.h264Output(self, info: VideoBuffer(buffer: c, timeStamp: timeInfo.presentationTimeStamp.value))
                        }
                    } else {
//                        print("Deocde error")
                    }
                })
                
                if status == kVTInvalidSessionErr {
                    guard let d = self.videoDesc else {
                        return
                    }
                    self.videoDesc = d
                } 
            }
            self.lastInterval += delta
        default:
            break
        }
    }
    
}
