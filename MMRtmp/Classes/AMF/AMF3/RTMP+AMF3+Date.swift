//
//  RTMP+AMF3+Date.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/16.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
extension Date: AMF3Encode {
    var amf3Encode: Data {
        let mileSecondSince1970 = Double(self.timeIntervalSince1970 * 1000)
        var data = Data()
        data.extendWrite.write(RTMPAMF3Type.date.rawValue)
            .write(AMF3EncodeType.U29.value.rawValue)
            .write(mileSecondSince1970)
        return data
    }
}
