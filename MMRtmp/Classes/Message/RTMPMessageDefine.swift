//
//  RTMPMessageDefine.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/16.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation

public enum PubishType: String {
    case live = "live"
    case record = "record"
    case append = "append"
}


protocol RTMPBaseMessageProtocol {
    var timestamp: TimeInterval { set get }
    var messageType: MessageType { get }
    var msgStreamId: Int  { get set }
    var streamId: Int  { get }
}

protocol RTMPCommandMessageProtocol {
    var commandName: String { get }
    var transactionId: Int { get }
    var commandObject: [String: Any?]? { get }
}


enum UserControlEventType: Int {
    case streamBegin = 0
    case streamEOF = 1
    case streamDry = 2
    case streamBufferLength = 3
    case streamIsRecorded = 4
    case pingRequest = 6
    case pingResponse = 7
    case none = 0xff
    init(rawValue: Int) {
        switch rawValue {
        case 0: self = .streamBegin
        case 1: self = .streamEOF
        case 2: self = .streamDry
        case 3: self = .streamBufferLength
        case 4: self = .streamIsRecorded
        case 6: self = .pingRequest
        case 7: self = .pingResponse
        default:
            self = .none
        }
    }
}

enum MessageType {
    
    case chunkSize
    case abort
    case acknowledgement
    case control
    case windowAcknowledgement
    case peerBandwidth
    case command(type: ObjectEncodingType)
    case data(type: ObjectEncodingType)
    case share(type: ObjectEncodingType)
    case audio
    case video
    case aggreate
    case none
    
    init(rawValue: UInt8) {
        switch rawValue {
        case 1:  self = .chunkSize
        case 2:  self = .abort
        case 3:  self = .acknowledgement
        case 4:  self = .control
        case 5:  self = .windowAcknowledgement
        case 6:  self = .peerBandwidth
        case 20: self = .command(type: .amf0)
        case 17: self = .command(type: .amf3)
        case 18: self = .data(type: .amf0)
        case 15: self = .data(type: .amf3)
        case 19: self = .share(type: .amf0)
        case 16: self = .share(type: .amf3)
        case 8:  self = .audio
        case 9:  self = .video
        case 22: self = .aggreate
        default: self = .none
        }
    }
    
    var rawValue: UInt8 {
        switch self {
        case .chunkSize:
            return 1
        case .abort:
            return 2
        case .acknowledgement:
            return 3
        case .control:
            return 4
        case .windowAcknowledgement:
            return 5
        case .peerBandwidth:
            return 6
        case .command(let type):
            return type == .amf0 ? 20 : 17
        case .data(let type):
            return type == .amf0 ? 18 : 15
        case .share(let type):
            return type == .amf0 ? 19 : 16
        case .audio:
            return 8
        case .video:
            return 9
        case .aggreate:
            return 22
        case .none:
            return 0xff
        }
    }

}


