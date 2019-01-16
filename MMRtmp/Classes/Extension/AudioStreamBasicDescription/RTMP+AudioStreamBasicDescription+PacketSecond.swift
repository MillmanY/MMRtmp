//
//  RTMP+AudioStreamBasicDescription+PacketSecond.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/11.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
import AudioToolbox
extension AudioStreamBasicDescription {
    var packetPerSecond: Int {
        get {
            return Int(Float(self.mSampleRate)/Float(self.mFramesPerPacket))
        }
    }
}
