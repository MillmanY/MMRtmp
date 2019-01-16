//
//  RTMPMessage.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/20.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import UIKit

public class RTMPBaseMessage: RTMPBaseMessageProtocol {
    let messageType: MessageType
    var msgStreamId: Int
    let streamId: Int
    
    init(type: MessageType, msgStreamId: Int = 0, streamId: Int) {
        self.messageType = type
        self.msgStreamId = msgStreamId
        self.streamId = streamId
    }

    private var _timeInterval: TimeInterval = 0
    public var timestamp:TimeInterval  {
        set {
            _timeInterval = newValue >= maxTimestamp ? maxTimestamp : newValue
        } get {
            return _timeInterval
        }
    }
}
