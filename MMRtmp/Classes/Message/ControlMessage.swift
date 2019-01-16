//
//  RTMPControlMessage.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/20.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import UIKit

class ControlMessage: RTMPBaseMessage {
    init(type: MessageType) {
        super.init(type: type, streamId: RTMPStreamId.control.rawValue)
    }    
}

// Set Chunk Size (1)
class ChunkSizeMessage: ControlMessage, ChunkEncoderTypeProtocol {
    let size: UInt32
    init(size: UInt32) {
        self.size = size
        super.init(type: .chunkSize)
    }
    
    func encode() -> Data {
        var data = Data()
        data.extendWrite.write(size & 0x7FFFFFFF)
        return data
    }
}

// Abort message (2)
class AbortMessage: ControlMessage, ChunkEncoderTypeProtocol {
    var chunkStreamId: Int
    init(chunkStreamId : Int) {
        self.chunkStreamId = chunkStreamId
        super.init(type: .abort)
    }
    
    func encode() -> Data {
        var data = Data()
        data.extendWrite.write(UInt32(chunkStreamId))
        return data
    }
}

// Acknowledgement (3)
class AcknowledgementMessage: ControlMessage, ChunkEncoderTypeProtocol {
    let sequence: UInt32
    init(sequence: UInt32) {
        self.sequence = sequence
        super.init(type: .acknowledgement)
    }
    
    func encode() -> Data {
        var data = Data()
        data.extendWrite.write(sequence)
        return data
    }
}

//Window Acknowledgement Size (5)
class WindowAckMessage: ControlMessage, ChunkEncoderTypeProtocol {
    let size: UInt32
    init(size: UInt32) {
        self.size = size
        super.init(type: .windowAcknowledgement)
    }
    
    func encode() -> Data {
        var data = Data()
        data.extendWrite.write(size)
        return data
    }
}

//Set Peer Bandwidth (6)

class PeerBandwidthMessage: ControlMessage, ChunkEncoderTypeProtocol {
    
    enum LimitType: UInt8 {
        case hard = 0
        case soft = 1
        case dynamic = 2
    }
    
    let windowSize: UInt32
    let limit: LimitType
    init(windowSize: UInt32, limit: LimitType) {
        self.windowSize = windowSize
        self.limit = limit
        super.init(type: .peerBandwidth)
    }
    
    func encode() -> Data {
        var data = Data()
        data.extendWrite.write(windowSize)
        data.extendWrite.write(limit.rawValue)
        return data
    }
}
