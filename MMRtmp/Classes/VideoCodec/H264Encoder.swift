//
//  H264Encoder.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2018/1/11.
//  Copyright © 2018年 Millman YANG. All rights reserved.
//

import Foundation
import VideoToolbox

public protocol H264EncoderDelegate: class {
    func outputHeader(encoder: H264Encoder, data: Data, time: TimeInterval)
    func output(encoder: H264Encoder, data: Data, delta: TimeInterval)
}

public class H264Encoder {
    var isStartEncode = false {
        didSet {
            if isStartEncode {
                self.session = nil
            }
        }
    }
    fileprivate var time: (start: TimeInterval, lastInterval: TimeInterval) = (0,0)
    static private let defaultProperties: [NSString: AnyObject] = {
        let d: [NSString: AnyObject] = [kVTCompressionPropertyKey_RealTime: kCFBooleanTrue,
                 kVTCompressionPropertyKey_ProfileLevel: kVTProfileLevel_H264_Baseline_3_1,
                 kVTCompressionPropertyKey_ExpectedFrameRate: NSNumber(value: 30),
                 kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration: NSNumber(value: 2.0),
                 kVTCompressionPropertyKey_PixelTransferProperties: ["ScalingMode": "Trim"] as AnyObject
        ]
        return d
    }()
    var properties = [NSString: Any]() {
        didSet {
            guard let s = session else {
                return
            }
            var copy = properties
            if let isBaseline = (properties[kVTCompressionPropertyKey_ProfileLevel] as? String)?.contains("Baseline") {
                copy[kVTCompressionPropertyKey_AllowFrameReordering] = !isBaseline as AnyObject
            } else {
                copy[kVTCompressionPropertyKey_AllowFrameReordering] = nil
            }
            VTSessionSetProperties(s, propertyDictionary: copy as CFDictionary)
        }
    }
    var frameSize: CGSize = .zero {
        didSet {
            if frameSize == oldValue {
                return
            }
            self.session = nil
        }
    }
    unowned let delegate: H264EncoderDelegate
    init(delegate: H264EncoderDelegate) {
        self.delegate = delegate
    }
    var session: VTCompressionSession? {
        didSet {
            if let old = oldValue {
                VTCompressionSessionInvalidate(old)
            }
            if session != nil {
                self.properties = H264Encoder.defaultProperties
            }
        }
    }
    
    var formatDescription: CMFormatDescription? {
        didSet {
            guard isStartEncode, let desc = self.formatDescription else {
                return
            }
            if let info:NSDictionary = CMFormatDescriptionGetExtension(desc, extensionKey: "SampleDescriptionExtensionAtoms" as CFString) as? NSDictionary,
                let data = info["avcC"] as? Data {
                
                var descData = Data()
                let frameAndCode:UInt8 = UInt8(VideoData.FrameType.keyframe.rawValue << 4 | VideoData.CodecId.avc.rawValue)
                
                descData.extendWrite.write(frameAndCode)
                        .write(VideoData.AVCPacketType.header.rawValue)
                        .writeU24(0)
                        .write(data)
                self.delegate.outputHeader(encoder: self, data: descData, time: (self.time.lastInterval-self.time.start).millSecond)
            }
        }
    }
    
    func encode(buffer: CMSampleBuffer) {
        
        if session == nil {
            var att = [NSString: Any]()
            att[kCVPixelBufferWidthKey] = frameSize.width
            att[kCVPixelBufferHeightKey] = frameSize.height
            VTCompressionSessionCreate(allocator: kCFAllocatorDefault,
                                       width: Int32(frameSize.width), height: Int32(frameSize.height),
                                       codecType: kCMVideoCodecType_H264,
                                       encoderSpecification: nil,
                                       imageBufferAttributes: att as CFDictionary,
                                       compressedDataAllocator: nil,
                                       outputCallback: nil,
                                       refcon: unsafeBitCast(self, to: UnsafeMutableRawPointer.self),
                                       compressionSessionOut: &session)
        }
        guard isStartEncode,
              let s = session,
              let imageBuffer = CMSampleBufferGetImageBuffer(buffer) else {
            return
        }
        var flags:VTEncodeInfoFlags = VTEncodeInfoFlags()

        VTCompressionSessionEncodeFrame(s, imageBuffer: imageBuffer, presentationTimeStamp: buffer.presentedTimestamp, duration: buffer.duration, frameProperties: nil, infoFlagsOut: &flags) { [weak self] (status, flag, buffer) in
            guard let b = buffer, let self = self else {
                return
            }
            let new = CMSampleBufferGetFormatDescription(b)
            if !CMFormatDescriptionEqual(self.formatDescription, otherFormatDescription: new) {
                if self.time.start == 0 {
                    self.time.start = b.presentedTimestamp.seconds
                }
                self.time.lastInterval = b.presentedTimestamp.seconds
                self.formatDescription = new
            }
    
            guard let bufferData = CMSampleBufferGetDataBuffer(b)?.data else {
                return
            }
            let delta = (b.presentedTimestamp.seconds-self.time.lastInterval).millSecond
            var descData = Data()
            let frameType = b.isKeyFrame ? VideoData.FrameType.keyframe : VideoData.FrameType.inter
            let frameAndCode:UInt8 = UInt8(frameType.rawValue << 4 | VideoData.CodecId.avc.rawValue)
            descData.extendWrite.write(frameAndCode)
                .write(VideoData.AVCPacketType.nalu.rawValue)
                .writeU24(Int(delta))
                .write(bufferData)
            self.time.lastInterval = b.presentedTimestamp.seconds
            self.delegate.output(encoder: self, data: descData, delta: delta)
        }
    }
}
