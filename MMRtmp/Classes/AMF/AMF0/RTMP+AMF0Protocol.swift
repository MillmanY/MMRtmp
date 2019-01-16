//
//  RTMP+AMF0Protocol.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/16.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
let nullString = "Null"

enum DecodeSubType {
    case array(count: Int)
    case object(encodeKey: String)
    case ecma(encodeKey: String, count: Int)
    case none
}

protocol DecodeResponseProtocol {
    init(decode: Any?)
}

protocol AMF0KeyEncode {
    var amf0KeyEncode: Data { get }
}

protocol AMF0Encode {
    var amf0Encode: Data { get }
}
