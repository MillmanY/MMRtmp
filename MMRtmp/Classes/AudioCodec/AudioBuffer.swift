//
//  AudioInfo.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/12.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
import AudioToolbox

//public struct AudioBuffer {
//    let data: UnsafeRawPointer
//    let size: Int
//    let desc: AudioStreamPacketDescription
//    let timeStamp: Int64
//}

public struct AudioBuffer {
    let data: Data
    let desc: AudioStreamPacketDescription
    let timestamp: Int64
}


public struct AudioHeader {
    var desc: AudioStreamBasicDescription
    var startTime: Int64
}
