//
//  RTMP+AMF0+UInt.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/16.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
extension UInt: AMF0Encode {
    var amf0Encode: Data {
        return Double(self).amf0Encode
    }
}

extension UInt8: AMF0Encode {
    var amf0Encode: Data {
        return Double(self).amf0Encode
    }
}

extension UInt16: AMF0Encode {
    var amf0Encode: Data {
        return Double(self).amf0Encode
    }
}

extension UInt32: AMF0Encode {
    var amf0Encode: Data {
        return Double(self).amf0Encode
    }
}
