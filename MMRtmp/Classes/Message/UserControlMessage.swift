//
//  RTMPUserControlMessage.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2018/1/5.
//  Copyright © 2018年 Millman YANG. All rights reserved.
//

import Foundation

class UserControlMessage: ControlMessage, ChunkEncoderTypeProtocol {
    let eventType: UserControlEventType
    let data: Data

    init(type: UserControlEventType, data: Data) {
        self.data = data
        self.eventType = type
        super.init(type: .control)
    }
    
    convenience init(streamBufferLength: Int, streamId: Int) {
        let id = UInt32(streamId).bigEndian.data
        let length = UInt32(streamBufferLength).bigEndian.data
        self.init(type: .streamBufferLength, data: id+length)
    }
    
    func encode() -> Data {
        var data = Data()
        data.extendWrite.write(UInt16(eventType.rawValue))
            .write(self.data)
        return data
    }
}
