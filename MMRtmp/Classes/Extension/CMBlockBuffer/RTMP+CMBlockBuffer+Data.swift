//
//  CMBlockBuffer+Data.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2018/1/12.
//  Copyright © 2018年 Millman YANG. All rights reserved.
//

import Foundation
import VideoToolbox
extension CMBlockBuffer {
    
    var data: Data? {
        
        var length: Int = 0
        var pointer: UnsafeMutablePointer<Int8>?
        
        guard CMBlockBufferGetDataPointer(self, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &pointer) == noErr,
              let p = pointer else {
            return nil
        }
        return Data(bytes: p, count: length)
    }
    
    var length: Int {
        
        return CMBlockBufferGetDataLength(self)
    }

}
