//
//  RTMP+AMF0+Int.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/16.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
extension Int: AMF0Encode {
    var amf0Encode: Data {
        return Double(self).amf0Encode
    }
}

extension Int8: AMF0Encode {
    var amf0Encode: Data {
        return Double(self).amf0Encode
    }
}

extension Int16: AMF0Encode {
    var amf0Encode: Data {
        return Double(self).amf0Encode
    }
}

extension Int32: AMF0Encode {
    var amf0Encode: Data {
        return Double(self).amf0Encode
    }
}
