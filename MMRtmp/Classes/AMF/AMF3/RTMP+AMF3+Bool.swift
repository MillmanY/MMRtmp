//
//  RTMP+AMF3+Bool.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/16.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation

extension Bool: AMF3Encode {
    var amf3Encode: Data {
        return Data([self == false ? 0x02 : 0x03])
    }
}
