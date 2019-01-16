//
//  RTMP+AMF3+String.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/16.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation

extension String: AMF3Encode, AMF3KeyEncode {
    var amf3KeyEncode: Data {
        let encodeLength = (self.count << 1 | 0x01).amf3LengthConvert
        var data = Data()
        data.append(encodeLength)
        data.extendWrite.writeUTF8(self)
        return data
    }
    
    var amf3Encode: Data {
        var data = Data()
        data.extendWrite.write(RTMPAMF3Type.string.rawValue)
        data.append(self.amf3KeyEncode)
        return data
    }
}
