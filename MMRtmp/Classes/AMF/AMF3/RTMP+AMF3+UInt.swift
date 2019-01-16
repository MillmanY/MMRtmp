//
//  RTMP+AMF3+UInt.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/16.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
extension UInt8: AMF3Encode {
    var amf3Encode: Data {
        return Int(self).amf3Encode
    }
}

extension UInt16: AMF3Encode {
    var amf3Encode: Data {
        return Int(self).amf3Encode
    }
}

extension UInt32: AMF3Encode {
    var amf3Encode: Data {
        return Int(self).amf3Encode
    }
}

extension UInt32: AMF3VectorUnitEncode {
    var vectorData: Data {
        return self.bigEndian.data
    }
}
