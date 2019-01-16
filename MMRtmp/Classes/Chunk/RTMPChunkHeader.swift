//
//  RTMPChunkHeader.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/18.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
struct RTMPChunkHeader: MessageHeaderProtocol {
    let streamId: Int
    let messageHeader: MessageHeaderProtocol
    let basicHeaderType: MessageHeaderType
    var chunkPayload = Data()

    init(streamId: Int,messageHeader: MessageHeaderProtocol, chunkPayload: Data) {
        self.streamId = streamId
        self.messageHeader = messageHeader
        self.chunkPayload = chunkPayload
        
        switch messageHeader {
        case _ as MessageHeaderType0Protocol:
            basicHeaderType = .type0
        case _ as MessageHeaderType1Protocol:
            basicHeaderType = .type1
        case _ as MessageHeaderType2Protocol:
            basicHeaderType = .type2
        case _ as MessageHeaderType3Protocol:
            basicHeaderType = .type3
        default:
            basicHeaderType = .type0
        }
    }
    
    func encode() -> Data {
        return (self.encodeBasicHeader()+messageHeader.encode()+chunkPayload)
    }
    
    private func encodeBasicHeader() -> Data {
        
        var data = Data()
        let fmt = basicHeaderType.rawValue << 6
        switch streamId {
        case 2...63:
            data.extendWrite.write(UInt8(fmt | streamId))
        case 64...319:
            let appendNumber = 0b00000000
            data.extendWrite.write(UInt8(fmt | appendNumber))
                .write(UInt8(streamId - 64))
        case 319...:
            let appendNumber = 0b00000001
            data.extendWrite
                .write(UInt8(fmt | appendNumber))
                .write(UInt16(streamId-64))

        default:
            break
        }
        return data
    }
}
