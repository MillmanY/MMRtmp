//
//  MessageHeader0.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/18.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation

struct MessageHeaderType0: MessageHeaderType0Protocol {
    
    let timestamp: TimeInterval
    let msgLength: Int
    let type: MessageType
    
    let msgStreamId: Int
        
    public init(timestamp: TimeInterval, msgLength: Int, type: MessageType, msgStreamId: Int) {
        self.timestamp = timestamp
        self.msgLength = msgLength
        self.type = type
        self.msgStreamId = msgStreamId
    }
    
    func encode() -> Data {
        var data = Data()
        let isExtendTime = timestamp > maxTimestamp
        if isExtendTime {
            data.extendWrite.writeU24(Int(maxTimestamp))
        } else {
            data.extendWrite.writeU24(Int(timestamp))
        }
        data.extendWrite.writeU24(msgLength)
            .write(type.rawValue)
            .write(UInt32(msgStreamId), bigEndian: false)
        if isExtendTime {
            data.extendWrite.write(UInt32(Int(timestamp)))
        }
        return data
    }
}
