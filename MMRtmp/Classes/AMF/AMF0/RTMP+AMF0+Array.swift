//
//  RTMP+AMF0+Array.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/16.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
extension Array: AMF0Encode {
    var amf0Encode: Data {
        var data = Data()
        data.extendWrite.write(RTMPAMF0Type.strictArray.rawValue)
            .write(UInt32(self.count))
        self.forEach {
            if let valueEncode = ($0 as? AMF0Encode)?.amf0Encode {
                data.append(valueEncode)
            } else if let dic = $0 as? [String: Any] {
                data.append(dic.amf0Encode)
            }
        }
        return data
    }
}

extension Array {
    var amf0GroupEncode: Data {
        var group = Data()
        self.forEach {
            if let data = ($0 as? AMF0Encode)?.amf0Encode {
                group.append(data)
            } else if let dic = $0 as? [String: Any?] {
                group.append(dic.amf0Encode)
            }
        }
        return group
    }
}
