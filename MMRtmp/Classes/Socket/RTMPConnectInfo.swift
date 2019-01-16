//
//  RTMPConnectInfo.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2018/1/4.
//  Copyright © 2018年 Millman YANG. All rights reserved.
//

import Foundation

public struct RTMPConnectInfo {
    public enum Status {
        case none
        case open
        case connectd(id: Int)
        case closed
        
        var connectId: Int {
            get {
                switch self {
                case .connectd(let id):
                    return id
                default:
                    return -1
                }
            }
        }
    }
    public private (set) var connectStatus: RTMPConnectInfo.Status = .none
    var raw = [Int: RTMPBaseMessage]()
    private (set) var url: URL?
    private (set) var host: String?
    private (set) var port = 1935
    private (set) var transactionId = 1

    mutating func reset(_ clearHost: Bool = true) {
        connectStatus = .none
        if clearHost {
            url = nil
            host = nil
            port = 1935
        }
        transactionId = 1
    }
    
    @discardableResult
    mutating func shiftTransactionId () -> Int {
        self.transactionId += 1
        return self.transactionId
    }
    
    mutating func register(message: RTMPBaseMessage) {
        raw[transactionId] = message
    }
    
    mutating func removeMessage(id: Int) -> RTMPBaseMessage? {
        let value = raw[transactionId]
        raw[transactionId] = nil
        return value
    }
    
    mutating func set(status: RTMPConnectInfo.Status) {
        self.connectStatus = status
    }
    
    mutating func set(url: URL, host: String, port: Int) {
        self.url = url
        self.host = host
        self.port = port
    }
}


