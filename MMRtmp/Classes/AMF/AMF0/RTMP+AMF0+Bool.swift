//
//  RTMP+AMF0+Bool.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/16.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
extension Bool: AMF0Encode {
    var amf0Encode: Data {
        return Data([RTMPAMF0Type.boolean.rawValue, self ? 0x01 : 0x00])
    }
}
