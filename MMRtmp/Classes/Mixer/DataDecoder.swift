//
//  DataDecodeMixer.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/11.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
import AudioToolbox
import AVFoundation
public protocol DataDecoderDelegate: class {
    func dataDecoder(_ decoder: DataDecoder, audio: AudioBuffer)
    func dataDecoder(_ decoder: DataDecoder, audioHeader: AudioHeader)
    func dataDecoder(_ decoder: DataDecoder, video: VideoBuffer)
    func dataDecoder(_ decoder: DataDecoder, videoHeader: VideoHeader)

}

extension DataDecoder {
    enum DecodeType {
        case live
        case record(duration: TimeInterval)
    }
}

public class DataDecoder: NSObject {
    var currentMaxTime: Double {
        get {
            let aac = self.aac?.lastInterval ?? 0
            let h264 = self.h264?.lastInterval ?? 0
            return Double(max(aac,h264))
        }
    }
    fileprivate var h264: H264Decoder?
    fileprivate var aac: AACDecoder?
    var decodeType: DecodeType = .live
    fileprivate unowned let delegate: DataDecoderDelegate
    init(delegate: DataDecoderDelegate) {
        self.delegate = delegate
    }
}

// Public
extension DataDecoder {
    func append(video: Data, timeStamp: Int64, isFirst: Bool = true) {
        if isFirst {
            h264 = H264Decoder.init(delegate: self, startTime: timeStamp)
        }
        h264?.decode(data: video, delta: timeStamp)
    }
    
    func append(audio: Data, timeStamp: Int64, isFirst: Bool = true) {
        if isFirst {
            aac = try? AACDecoder(delegate: self, type: kAudioFileAAC_ADTSType, startTime: timeStamp)
        }
        aac?.decode(data: audio, delta: timeStamp)
    }
    
    func reset() {
        aac = nil
        h264 = nil
    }
}

extension DataDecoder: AACDecoderDelegate {
    func aacOutput(_ decoder: AACDecoder, info: AudioBuffer) {
        self.delegate.dataDecoder(self, audio: info)
    }

    func aacSetDescOutput(_ decoder: AACDecoder, info: AudioHeader) {
        self.delegate.dataDecoder(self, audioHeader: info)
    }
}

extension DataDecoder: H264DecoderDelegate {
    public func h264Output(_ decoder: H264Decoder, info: VideoBuffer) {
        self.delegate.dataDecoder(self, video: info)
    }
    
    public func h264SetDescOutput(_ decoder: H264Decoder, info: VideoHeader) {
        self.delegate.dataDecoder(self, videoHeader: info)
    }
}
