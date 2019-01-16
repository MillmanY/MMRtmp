//
//  RTMPDecoder.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/27.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation

enum RTMPMessageDecodeStatus {
    case payload(data: Data, isChunk: Bool)
    case notEnoughData
    case error(desc: String)
}

class ChunkDecoder {
    let decodeQueue = DispatchQueue(label: "mmRtmp.rtmpDecoder")
    var chunkSize: UInt32 = UInt32(maxChunkSize)
    var map = [Int:RTMPChunkHeader]()
    var chunkBlock:((RTMPChunkHeader)->Void)?
    var isStart = false
    var preLength: UInt32 = 0
    var decodeData = Data() {
        didSet {
            if decodeData.count == 0 {
                self.isStart = false
            } else if !isStart {
                
                if isStart {
                    return
                }
                
                self.isStart = true
                self.handleQueue()
            }
        }
    }
    
    func reset() {
        decodeQueue.async { [weak self] in
            self?.map.removeAll()
            self?.chunkSize = UInt32(maxChunkSize)
            self?.isStart = false
            self?.preLength = 0
            self?.decodeData.removeAll()
        }
    }
    
    func decode(data: Data, chunk:((_ data: RTMPChunkHeader)->Void)?) {
        decodeQueue.async { [weak self] in
            self?.chunkBlock = chunk
            self?.decodeData.append(data)
        }
    }
    
    func handleQueue() {
        decodeQueue.async { [weak self] in
            self?._handleQueue()
        }
    }
    
    fileprivate func _handleQueue() {
        guard let first = self.decodeData.first else {
            self.isStart = false
            return
        }
        
        let type = Int(first >> 6)
        let compare: UInt8 = 0b00111111
        var streamId: Int = 0
        var basicHeaderSize = 0
        switch compare & first {
        case 0:
            basicHeaderSize = 2
            streamId = Int(self.decodeData[1] + 64)
        case 1:
            basicHeaderSize = 3
            streamId = Int(Data(self.decodeData[1...2].reversed()).uint16)
        default:
            basicHeaderSize = 1
            streamId = Int(compare & first)
        }
        var rc:RTMPMessageDecodeStatus = .error(desc: "Empty")
        switch type {
        case 0:
            rc = self.decodeType0(streamId: Int(streamId), basicHeaderSize: basicHeaderSize)
        case 1:
            rc = self.decodeType1(streamId: Int(streamId), basicHeaderSize: basicHeaderSize)
        case 2:
            rc = self.decodeType2(streamId: Int(streamId), basicHeaderSize: basicHeaderSize)
        case 3:
            rc = self.decodeType3(streamId: Int(streamId), basicHeaderSize: basicHeaderSize)
        default: break
        }
        if self.decodeData.count > 0 {
            switch rc {
            case .notEnoughData:
                self.isStart = false
            case .payload(_,_):
                self._handleQueue()
            case .error(let desc):
                print("Error Stop:\(desc)")
            }
        } else {
            self.isStart = false
        }
    }

    func decodeType0(streamId: Int, basicHeaderSize: Int) -> RTMPMessageDecodeStatus {
        guard let dataTime = self.decodeData[safe: (0...2).shift(index: basicHeaderSize)],
              let dataLength = self.decodeData[safe:(3...5).shift(index: basicHeaderSize)] else {
            return .notEnoughData
        }
        
        var time = Data(dataTime.reversed()).uint32
        
        let isExtendTime = (Double(time) == maxTimestamp)
        let headerSize = isExtendTime ? 15 : 11
        if isExtendTime {
            guard let dataExtend = self.decodeData[safe: (11...14).shift(index: basicHeaderSize)] else {
                return .notEnoughData
            }
            time = Data(dataExtend.reversed()).uint32
        }
        
        preLength = Data(dataLength.reversed()).uint32
        
        switch self.decodePayload(length: preLength, headerSize: headerSize+basicHeaderSize) {
        case .payload(let data, let isChunk):
            let type = MessageType(rawValue: Data([self.decodeData[6+basicHeaderSize]]).uint8)
            let msgStreamId = Data(self.decodeData[(7...10).shift(index: basicHeaderSize)].reversed()).uint32
            
            let header0 = MessageHeaderType0(timestamp: TimeInterval(time),
                                             msgLength: Int(preLength),
                                             type: type,
                                             msgStreamId: Int(msgStreamId))

            let header =  RTMPChunkHeader(streamId: Int(streamId),
                                          messageHeader:
                header0,
                                          chunkPayload: Data(data))

            if isChunk {
                self.map[Int(streamId)] = header
            } else {
                chunkBlock?(header)
            }
            self.decodeData.removeSubrange(0..<headerSize+basicHeaderSize+data.count)
            return .payload(data: data, isChunk: isChunk)
        case .notEnoughData:
            return .notEnoughData
        case .error(let desc):
            return .error(desc: desc)
        }
    }
    
    func decodeType1(streamId: Int, basicHeaderSize: Int) -> RTMPMessageDecodeStatus {
        
        guard let dataTime = self.decodeData[safe: (0...2).shift(index: basicHeaderSize)],
            let dataLength = self.decodeData[safe:(3...5).shift(index: basicHeaderSize)] else {
                return .notEnoughData
        }
        let time = Double(Data(dataTime.reversed()).uint32)
        let timeDelta = time >= maxTimestamp ? maxTimestamp : time
        preLength = Data(dataLength.reversed()).uint32
     
        switch self.decodePayload(length: preLength, headerSize: 7+basicHeaderSize) {
        case .payload(let data, let isChunk):
            let type = MessageType(rawValue: Data([self.decodeData[6+basicHeaderSize]]).uint8)
            let message1 = MessageHeaderType1(timestampDelta: TimeInterval(timeDelta), msgLength: Int(preLength), type: type)
            let header = RTMPChunkHeader(streamId: Int(streamId), messageHeader: message1, chunkPayload: Data(data))
            if isChunk {
                self.map[Int(streamId)] = header
            } else {
                self.map[Int(streamId)] = nil
                 chunkBlock?(header)
            }
            self.decodeData.removeSubrange(0..<data.count+7+basicHeaderSize)
            return .payload(data: data, isChunk: isChunk)
        case .notEnoughData:
            return .notEnoughData
        case .error(let desc):
            return .error(desc: desc)
        }
    }
    func decodeType2(streamId: Int, basicHeaderSize: Int) -> RTMPMessageDecodeStatus {
        self.decodeData.removeSubrange(0..<3+basicHeaderSize)
        return .notEnoughData
    }
    
    func decodeType3(streamId: Int, basicHeaderSize: Int) -> RTMPMessageDecodeStatus {
        if let header = self.map[Int(streamId)] {
            var total = 0
            switch header.messageHeader {
            case let c as MessageHeaderType0:
                total = c.msgLength
            case let c as MessageHeaderType1:
                total = c.msgLength
            default: break
            }
            
            let needAppend = total - header.chunkPayload.count
            var payloadRange = 0..<0
            let isChunk = needAppend > self.chunkSize
            if isChunk {
                payloadRange = 0..<Int(self.chunkSize)
            } else {
                payloadRange = 0..<Int(needAppend)
            }
            
            guard let payload = self.decodeData[safe: payloadRange.shift(index: basicHeaderSize)] else {
                return .notEnoughData
            }
            
            self.map[Int(streamId)]?.chunkPayload.append(contentsOf: payload)
            self.decodeData.removeSubrange(0..<basicHeaderSize)
            self.decodeData.removeSubrange(payloadRange)
            if let h = self.map[Int(streamId)],
                total == self.map[Int(streamId)]?.chunkPayload.count {
                self.map[Int(streamId)] = nil
                chunkBlock?(h)
            }
            return .payload(data: payload, isChunk: true)
        }
        return .error(desc: "Chunk map data not found")
    }
    
    fileprivate func decodePayload(length: UInt32, headerSize: Int) -> RTMPMessageDecodeStatus {
        var payloadRange = 0..<Int(length)
        let isChunk = length > self.chunkSize
        if isChunk {
            payloadRange = 0..<Int(self.chunkSize)
        }
        if let data = decodeData[safe: payloadRange.shift(index: headerSize)] {
            return .payload(data: data, isChunk: isChunk)
        } else {
            return .notEnoughData
        }
    }
}

