//
//  MessageHeaderType2.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/18.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
struct MessageHeaderType2: MessageHeaderType2Protocol {
    let timestampDelta: TimeInterval
    public init(timestampDelta: TimeInterval) {
        self.timestampDelta = timestampDelta
    }
    func encode() -> Data {
        var data = Data()
        data.extendWrite.writeU24(Int(timestampDelta))
        return data
    }
}

