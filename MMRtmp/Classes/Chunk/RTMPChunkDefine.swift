//
//  RTMPChunkDefine.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/16.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
protocol RTMPChunkProtocol {
    func chunkFrom(size: Int, firstType0: Bool) -> [Data]
}

enum RTMPStreamId: Int {
    case control = 2
    case command = 3
    case audio = 4
    case video = 5
}

// max timestamp 0xFFFFFF
let maxTimestamp: TimeInterval = 16777215
// chunk size 128
let maxChunkSize: UInt8 = 128
/*
+--------------+----------------+--------------------+--------------+
| Basic Header | Message Header | Extended Timestamp | Chunk Data |
+--------------+----------------+--------------------+--------------+
*/
enum MessageHeaderType: Int {
    case type0 = 0
    case type1 = 1
    case type2 = 2
    case type3 = 3
}

protocol MessageHeaderProtocol {
    func encode() -> Data
}

protocol MessageHeaderType0Protocol: MessageHeaderProtocol {
    init(timestamp: TimeInterval, msgLength: Int, type: MessageType, msgStreamId: Int)
}

protocol MessageHeaderType1Protocol: MessageHeaderProtocol {
    init(timestampDelta: TimeInterval, msgLength: Int, type: MessageType)
}

protocol MessageHeaderType2Protocol: MessageHeaderProtocol {
    init(timestampDelta: TimeInterval)
}

protocol MessageHeaderType3Protocol: MessageHeaderProtocol {}









