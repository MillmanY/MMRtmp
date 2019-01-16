//
//  RTMP+AMF3+Double.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/16.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation

extension Double: AMF3Encode {
    var amf3Encode: Data {
        var data = Data()
        data.extendWrite.write(RTMPAMF3Type.double.rawValue)
            .write(self)
        return data
    }
}

extension Double: AMF3VectorUnitEncode {
    var vectorData: Data {
        return Data(self.data.reversed())
    }
}
