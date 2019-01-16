//
//  RTMP+AMF0+Double.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/16.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
extension Float: AMF0Encode {
    var amf0Encode: Data {
        return Double(self).amf0Encode
    }
}

extension Double: AMF0Encode {
    var amf0Encode: Data {
        var data = Data()
        data.extendWrite.write(RTMPAMF0Type.number.rawValue)
            .write(self)
        return data
    }
}
