//
//  MMBaseNetSocket.swift
//  FLVTest
//
//  Created by Millman YANG on 2017/11/13.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
public class RTMPBaseNetSocket: NSObject {

    var runloop: RunLoop?
    static let maxReadSize = Int(UInt16.max)
    var buffer:UnsafeMutablePointer<UInt8>?
    var inputData = Data()
    var inputQueue = DispatchQueue(label: "mmRtmp.inputQueue")
    var outputQueue = DispatchQueue(label: "mmRtmp.outputQueue")
    var input: InputStream?
    var output: OutputStream?
    
    open func setParameter() {
        buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: RTMPBaseNetSocket.maxReadSize)
        buffer?.initialize(repeating: 0, count: RTMPBaseNetSocket.maxReadSize)
        if let delegate = self as? StreamDelegate {
            self.input?.delegate = delegate
            self.output?.delegate = delegate
        }        
        self.runloop = .current
        self.input?.setProperty(StreamNetworkServiceTypeValue.voIP, forKey: Stream.PropertyKey.networkServiceType)
        self.input?.schedule(in: self.runloop!, forMode: RunLoop.Mode.default)
        self.input?.setProperty(StreamSocketSecurityLevel.none, forKey: .socketSecurityLevelKey)
        self.output?.schedule(in: self.runloop!, forMode: RunLoop.Mode.default)
        self.output?.setProperty(StreamNetworkServiceTypeValue.voIP, forKey: Stream.PropertyKey.networkServiceType)
        self.input?.open()
        self.output?.open()
        self.runloop?.run()
    }
    
    open func clearParameter() {
        self.input?.close()
        self.input?.remove(from: runloop!, forMode: RunLoop.Mode.default)
        self.input?.delegate = nil
        self.output?.close()
        self.output?.remove(from: runloop!, forMode: RunLoop.Mode.default)
        self.output?.delegate = nil
        self.input = nil
        self.output = nil
        buffer?.deinitialize(count: RTMPBaseNetSocket.maxReadSize)
        buffer?.deallocate()
        buffer = nil
        inputData.removeAll()
        
        guard let r = self.runloop else {
            return
        }
        CFRunLoopStop(r.getCFRunLoop())
        self.runloop = nil
    }
    
    public func sendChunk(_ data: [Data]) {
        data.forEach { [unowned self] in self.send($0) }
    }
        
    public func send(_ data: Data) {
        outputQueue.async { [weak self] in
            guard let o = self?.output else {
                return
            }
            data.withUnsafeBytes { (buffer: UnsafePointer<UInt8>) -> Void in
                var total: Int = 0
                while total < data.count {
                    let length = o.write(buffer.advanced(by: total), maxLength: data.count)
                    if length <= 0 {
                        break
                    }
                    total += length
                }
            }
        }
    }
}

