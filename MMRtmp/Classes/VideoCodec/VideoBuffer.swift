//
//  VideoInfo.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/26.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
import VideoToolbox
public struct VideoBuffer {
    public let buffer: CMSampleBuffer
    public let timeStamp: Int64
    
    func isAudioContain(audioTime: CMTime) -> Bool {
        return buffer.frameTimeRangeDuration.contains(audioTime.seconds)
    }
}

public struct VideoHeader {
    public let desc: CMVideoFormatDescription
    public let startTime: Int64
}
