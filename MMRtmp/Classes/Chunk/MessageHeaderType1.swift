//
//  MessageHeaderType1.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/18.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
struct MessageHeaderType1: MessageHeaderType1Protocol {
    let timestampDelta: TimeInterval
    let msgLength: Int
    let type: MessageType
    
    public init(timestampDelta: TimeInterval, msgLength: Int, type: MessageType) {
        self.timestampDelta = timestampDelta
        self.msgLength = msgLength
        self.type = type
    }

    func encode() -> Data {
        var data = Data()
        data.extendWrite.writeU24(Int(timestampDelta))
            .writeU24(msgLength)
            .write(UInt8(type.rawValue))
        return data
    }
}

