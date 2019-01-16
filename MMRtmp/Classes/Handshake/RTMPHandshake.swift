//
//  RTMPHandshake.swift
//  FLVTest
//
//  Created by Millman YANG on 2017/11/12.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation

class RTMPHandshake {
    
    enum RTMPHandshakeStatus {
        case uninitalized
        case verSent
        case ackSent
        case handshakeDone
        case none
    }
    
    static let PacketSize = 1536
    static let RtmpVer:UInt8 = 3
    var timestamp:TimeInterval = 0
    var data = Data() {
        didSet {
            if checkTimer == nil && data.count > 0 {
                checkTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(statusCheck), userInfo: nil, repeats: true)
            }
        }
    }
    
    var checkTimer: Timer?
    public var changeBlock:((_ status:RTMPHandshakeStatus)->Void)?
    public init(statusChange: ((_ status:RTMPHandshakeStatus)->Void)?) {
        self.changeBlock = statusChange
    }
    
    private(set) var status = RTMPHandshakeStatus.none {
        didSet {
            switch status {
            case .none, .uninitalized:
                timestamp = 0
            case .verSent:
                break
            default:
                break
            }
            self.changeBlock?(status)
        }
    }
    
    var c0c1Packet: Data {
        var data = Data()
        data.extendWrite.write(RTMPHandshake.RtmpVer)
                       .write(UInt32(timestamp))
                       .write([UInt8]([0x00,0x00,0x00,0x00]))
        let randomSize = RTMPHandshake.PacketSize - data.count
        (0...randomSize).forEach { _ in
            data.extendWrite.write(UInt8(arc4random_uniform(0xff)))
        }

        return data
    }

    var c2Packet: Data {
        
        var data = Data()
        data.append(self.data.subdata(in: 1..<5))
        data.extendWrite.write(UInt32(Date().timeIntervalSince1970 - timestamp))
        data.append(self.data.subdata(in: 9..<RTMPHandshake.PacketSize+1))
        return data
    }

   
    func startHandShake() {
        self.status = .uninitalized
    }
    
    func reset() {
        checkTimer?.invalidate()
        checkTimer = nil
        data.removeAll()
        self.status = .none
    }
    
    @objc func statusCheck() {
        switch self.status {
        case .uninitalized:
            if self.data.count < RTMPHandshake.PacketSize+1  {
                break
            }
            self.status = .verSent
            self.data.removeSubrange(0...RTMPHandshake.PacketSize)
        case .verSent:
            if self.data.count < RTMPHandshake.PacketSize {
                return
            }
            self.status = .ackSent
        case .ackSent:
            if self.data.isEmpty {
                return
            }
            self.status = .handshakeDone
            self.data.removeAll()
            checkTimer?.invalidate()
            checkTimer = nil
        default:
            break
        }
    }
}
