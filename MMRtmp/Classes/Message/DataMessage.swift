//
//  RTMPDataMessage.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2018/1/12.
//  Copyright © 2018年 Millman YANG. All rights reserved.
//

import Foundation

class DataMessage: RTMPBaseMessage {
    var encodeType: ObjectEncodingType
    init(encodeType: ObjectEncodingType, msgStreamId: Int) {
        self.encodeType = encodeType
        super.init(type: .data(type: encodeType),
                   msgStreamId: msgStreamId,
                   streamId: RTMPStreamId.command.rawValue)
    }
}

class MetaMessage: DataMessage, ChunkEncoderTypeProtocol {
    let meta: [String: Any]
    init(encodeType: ObjectEncodingType, msgStreamId: Int, meta: [String: Any]) {
        self.meta = meta
        super.init(encodeType: encodeType,
                   msgStreamId: msgStreamId)
    }
    
    func encode() -> Data {
        var amf: AMFProtocol = encodeType == .amf0 ? AMF0Object() : AMF3Object()
        amf.append("onMetaData")
        amf.append(meta)
        return amf.data
    }
}

class VideoMessage: RTMPBaseMessage, ChunkEncoderTypeProtocol {
    let data: Data
    init(msgStreamId: Int, data: Data, timestamp: TimeInterval) {
        self.data = data
        super.init(type: .video,
                   msgStreamId: msgStreamId,
                   streamId: RTMPStreamId.video.rawValue)
        self.timestamp = timestamp
    }
    func encode() -> Data {
        return data
    }
}

class AudioMessage: RTMPBaseMessage, ChunkEncoderTypeProtocol {
    let data: Data

    init(msgStreamId: Int, data: Data, timestamp: TimeInterval) {
        self.data = data
        super.init(type: .audio,
                   msgStreamId: msgStreamId,
                   streamId: RTMPStreamId.audio.rawValue)
        self.timestamp = timestamp
    }
    func encode() -> Data {
        return data
    }
}
