//
//  RTMP+AMF3+Dictionary.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/16.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
extension Dictionary where Key == String {
    var amf3Encode: Data {
        var data = Data()
        data.extendWrite.write([RTMPAMF3Type.object.rawValue,0x0b,RTMPAMF3Type.null.rawValue])
        self.forEach { (key, value) in
            let keyEncode = key.amf3KeyEncode
            data.append(keyEncode)
            if let value = (value as? AMF3Encode)?.amf3Encode {
                data.append(value)
            } else {
                data.extendWrite.write(RTMPAMF3Type.null.rawValue)
            }
        }
        data.extendWrite.write(RTMPAMF3Type.null.rawValue)
        return data
    }    
}
