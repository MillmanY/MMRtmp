//
//  RTMP+AMF0+Data.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/16.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
extension Date: AMF0Encode {
    var amf0Encode: Data {
        let mileSecondSince1970 = Double(self.timeIntervalSince1970 * 1000)
        var data = Data()
        data.extendWrite.write(RTMPAMF0Type.date.rawValue)
            .write(mileSecondSince1970)
            .write([UInt8]([0x0,0x0]))
        return data
    }
}

