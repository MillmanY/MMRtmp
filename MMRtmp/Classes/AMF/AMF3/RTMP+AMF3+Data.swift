//
//  RTMP+AMF3+Data.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/16.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation

extension Data: AMF3ByteArrayEncode {
    var byteEncode: Data {
        let encodeLength = (self.count << 1 | 0x01).amf3LengthConvert
        var data = Data()
        data.extendWrite.write(RTMPAMF3Type.byteArray.rawValue)
        data += (encodeLength+self)
        return data
    }
}
