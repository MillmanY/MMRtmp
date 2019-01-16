//
//  RTMPCommandMessage.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/20.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation

class CommandMessage: RTMPBaseMessage, RTMPCommandMessageProtocol {
    let encodeType: ObjectEncodingType
    let commandName: String
    let transactionId: Int
    let commandObject: [String: Any?]?
    
    init(encodeType: ObjectEncodingType,
         commandName: String,
         msgStreamId: Int = 0,
         transactionId: Int,
         commandObject: [String: Any?]? = nil) {
        self.commandName = commandName
        self.transactionId = transactionId
        self.commandObject = commandObject
        self.encodeType = encodeType
        super.init(type: .command(type: encodeType),msgStreamId: msgStreamId, streamId: RTMPStreamId.command.rawValue)
    }
}

class ConnectMessage: CommandMessage, ChunkEncoderTypeProtocol {
    let argument: [String: Any?]?
    init(encodeType: ObjectEncodingType = .amf0,
         url: URL,
         flashVer: String,
         swfURL: URL? = nil,
         fpad: Bool,
         audio: RTMPAudioCodecsType,
         video: RTMPVideoCodecsType,
         pageURL: URL? = nil,
         argument: [String: Any?]? = nil) {
        self.argument = argument
        let u = url.path.split(separator: "/").first ?? "urlEmpty"
        let obj:[String: Any?] = ["app": String(u),
                                  "flashver": flashVer,
                                  "swfUrl":swfURL?.absoluteString,
                                  "tcUrl":url.absoluteString,
                                  "fpad":fpad,
                                  "audioCodecs": audio.rawValue,
                                  "videoCodecs":video.rawValue,
                                  "videoFunction":RTMPVideoFunction.seek.rawValue,
                                  "pageUrl":pageURL?.absoluteString,
                                  "objectEncoding":encodeType.rawValue]
        
        super.init(encodeType: encodeType, commandName: "connect", transactionId: commonTransactionId.connect, commandObject: obj)
    }
    
    func encode() -> Data {
        var amf: AMFProtocol = encodeType == .amf0 ? AMF0Object() : AMF3Object()
        amf.append(commandName)
        amf.append(Double(transactionId))
        amf.append(commandObject)
        return amf.data
    }
}

class CreateStreamMessage: CommandMessage, ChunkEncoderTypeProtocol {
    init(encodeType: ObjectEncodingType = .amf0, transactionId: Int, commonObject: [String: Any?]? = nil) {
        super.init(encodeType: encodeType,commandName: "createStream", transactionId: transactionId, commandObject: commonObject)
    }
    
    func encode() -> Data {
        var amf: AMFProtocol = encodeType == .amf0 ? AMF0Object() : AMF3Object()
        amf.append(commandName)
        amf.append(Double(transactionId))
        amf.append(commandObject)
        return amf.data
    }
}

class CallMessage: CommandMessage, ChunkEncoderTypeProtocol {
    let argument: [String: Any?]?
    init(encodeType: ObjectEncodingType = .amf0, transactionId: Int, commonObject: [String: Any?]? = nil, argument: [String: Any?]? = nil) {
        self.argument = argument
        super.init(encodeType: encodeType, commandName: "called", transactionId: transactionId, commandObject: commonObject)
    }
    
    func encode() -> Data {
        var amf: AMFProtocol = encodeType == .amf0 ? AMF0Object() : AMF3Object()
        amf.append(commandName)
        amf.append(Double(transactionId))
        amf.append(commandObject)
        if let a = argument {
            amf.append(a)
        }
        return amf.data
    }
}

class PlayMessage: CommandMessage, ChunkEncoderTypeProtocol {
    
    public enum RTMPDurationType {
        case playUntilEnd
        case singleFrame
        case duration(time: Int)
        init(rawValue: Int) {
            switch rawValue {
            case -1:
                self = .playUntilEnd
            case 0:
                self = .singleFrame
            default:
                self = .duration(time: rawValue)
            }
        }
        var raw: Int {
            switch self {
            case .playUntilEnd:
                return -1
            case .singleFrame:
                return 0
            case .duration(let time):
                return time
            }
        }
    }
    
    public enum RTMPStartType {
        case playRecord
        case onlyPlayExist
        case start(time: Int)
        
        init(rawValue: Int) {
            switch rawValue {
            case -2:
                self = .playRecord
            case -1:
                self = .onlyPlayExist
            default:
                self = .start(time: rawValue)
            }
        }
        
        var raw: Int {
            switch self {
            case .playRecord:
                return -2
            case .onlyPlayExist:
                return -1
            case .start(let time):
                return time
            }
        }
    }
    
    let streamName: String
    let start: RTMPStartType
    let duration: RTMPDurationType?
    let reset: Bool?
    
    init(encodeType: ObjectEncodingType = .amf0, streamName: String, start: RTMPStartType = .playRecord, duration: RTMPDurationType? = nil, reset: Bool? = nil) {
        self.streamName = streamName
        self.start = start
        self.duration = duration
        self.reset = reset
        super.init(encodeType: encodeType, commandName: "play", transactionId: commonTransactionId.stream)
    }
    
    func encode() -> Data {
        var amf: AMFProtocol = encodeType == .amf0 ? AMF0Object() : AMF3Object()
        amf.append(commandName)
        amf.append(Double(transactionId))
        amf.appendNil()
        amf.append(streamName)
        amf.append(Double(start.raw))
        if let d = duration?.raw {
            amf.append(Double(d))
        }
        if let r = reset {
            amf.appned(r)
        }
        return amf.data
    }
}

class Play2Message: CommandMessage {
    let parameter: [String: Any?]
    init(encodeType: ObjectEncodingType = .amf0, len: Double, offset: Double, oldName: String, start: Double, name: String, transition: String) {
        
        parameter = ["len": len,
                     "offset": offset,
                     "oldStreamName": oldName,
                     "start": start,
                     "streamName": name,
                     "transition": transition]
        
        super.init(encodeType: encodeType, commandName: "play2", transactionId: commonTransactionId.stream)
    }
    
    func encode() -> Data {
        var amf: AMFProtocol = encodeType == .amf0 ? AMF0Object() : AMF3Object()
        amf.append(commandName)
        amf.append(Double(transactionId))
        amf.appendNil()
        amf.append(parameter)
        return amf.data
    }
}


class PublishMessage: CommandMessage, ChunkEncoderTypeProtocol {
    let type: PubishType
    let streamName: String
    init(encodeType: ObjectEncodingType = .amf0, streamName: String, type: PubishType) {
        self.streamName = streamName
        self.type = type
        super.init(encodeType: encodeType, commandName: "publish", transactionId: commonTransactionId.stream)
    }
    
    func encode() -> Data {
        var amf: AMFProtocol = encodeType == .amf0 ? AMF0Object() : AMF3Object()
        amf.append(commandName)
        amf.append(Double(transactionId))
        amf.appendNil()
        amf.append(streamName)
        amf.append(self.type.rawValue)
        return amf.data
    }
}

class DeleteStreamMessage: CommandMessage, ChunkEncoderTypeProtocol {
    public let id: Int
    init(encodeType: ObjectEncodingType = .amf0, streamId: Int, commonObject: [String: Any?]? = nil) {
        self.id = streamId
        super.init(encodeType: encodeType, commandName: "deleteStream", transactionId: commonTransactionId.stream)
    }
    
    func encode() -> Data {
        var amf: AMFProtocol = encodeType == .amf0 ? AMF0Object() : AMF3Object()
        amf.append(commandName)
        amf.append(Double(transactionId))
        amf.appendNil()
        amf.append(Double(id))
        return amf.data
    }
}

class SeekMessage: CommandMessage, ChunkEncoderTypeProtocol {
    let millSecond: Double
    init(encodeType: ObjectEncodingType = .amf0, msgStreamId: Int, millSecond: Double) {
        self.millSecond = millSecond
        super.init(encodeType: encodeType, commandName: "seek", msgStreamId: msgStreamId, transactionId: commonTransactionId.stream)
    }
    
    func encode() -> Data {
        var amf: AMFProtocol = encodeType == .amf0 ? AMF0Object() : AMF3Object()
        amf.append(commandName)
        amf.append(Double(transactionId))
        amf.appendNil()
        amf.append(millSecond)
        return amf.data
    }
}

class PauseMessage: CommandMessage, ChunkEncoderTypeProtocol {
    let isPause: Bool
    let millSecond: Double
    init(encodeType: ObjectEncodingType = .amf0, msgStreamId:Int, isPause: Bool, millSecond: Double) {
        self.isPause = isPause
        self.millSecond = millSecond
        super.init(encodeType: encodeType, commandName: "pause", msgStreamId: msgStreamId, transactionId: commonTransactionId.stream)
    }
    
    func encode() -> Data {
        var amf: AMFProtocol = encodeType == .amf0 ? AMF0Object() : AMF3Object()
        amf.append(commandName)
        amf.append(Double(transactionId))
        amf.appendNil()
        amf.appned(isPause)
        amf.append(millSecond)
        return amf.data
    }
}
