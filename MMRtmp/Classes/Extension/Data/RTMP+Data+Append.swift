//
//  RTMP+Data+Append.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/20.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation

public protocol ExtendDataWritterProtocol: class {
    func write(_ value: UInt8) -> Self
    func write(_ value: UInt16, bigEndian: Bool) -> Self
    func write(_ value: Int16, bigEndian: Bool) -> Self
    func write(_ value: UInt32, bigEndian: Bool) -> Self
    func write(_ value: Int32, bigEndian: Bool) -> Self
    func write(_ value: Double, bigEndian: Bool) -> Self
    func writeU24(_ value: Int, bigEndian: Bool) -> Self
    func write(_ data: Data) -> Self
}

extension Data {
    var extendWrite: ExtendDataWritter {
        mutating get {
            return ExtendDataWritter(&self)
        }
    }
}

class ExtendDataWritter {
    var base: UnsafeMutablePointer<Data>
    init(_ base: UnsafeMutablePointer<Data>) {
        self.base = base
    }
}

extension ExtendDataWritter: ExtendDataWritterProtocol {
    @discardableResult
    public func write(_ value: UInt8) -> Self {
        base.pointee.append(value.data)
        return self
    }
    
    @discardableResult
    public func write(_ value: [UInt8]) -> Self {
        base.pointee.append(Data(value))
        return self
    }

    @discardableResult
    public func write(_ value: UInt16, bigEndian: Bool = true) -> Self {
        let convert = bigEndian ? value.bigEndian : value
        base.pointee.append(convert.data)
        return self
    }
    @discardableResult
    public func write(_ value: Int16, bigEndian: Bool = true) -> Self {
        let convert = bigEndian ? value.bigEndian : value
        base.pointee.append(convert.data)
        return self
    }
    @discardableResult
    public func write(_ value: UInt32, bigEndian: Bool = true) -> Self {
        let convert = bigEndian ? value.bigEndian : value
        base.pointee.append(convert.data)
        return self
    }
    @discardableResult
    public func write(_ value: Int32, bigEndian: Bool = true) -> Self {
        let convert = bigEndian ? value.bigEndian : value
        base.pointee.append(convert.data)
        return self
    }
    @discardableResult
    public func write(_ value: Double, bigEndian: Bool = true) -> Self {
        let convert = bigEndian ? Data(value.data.reversed()) : value.data
        base.pointee.append(convert)
        return self
    }
    @discardableResult
    public func writeU24(_ value: Int, bigEndian: Bool = true) -> Self {
        
        if bigEndian {
            let convert = UInt32(value).bigEndian.data
            base.pointee.append(convert[1...(convert.count-1)])
        } else {
            let convert = UInt32(value).data
            base.pointee.append(convert[0..<convert.count-1])
        }
        return self
    }
    
    @discardableResult
    public func writeUTF8(_ value: String) -> Self {
        base.pointee.append(Data(value.utf8))
        return self
    }
    
    @discardableResult
    public func write(_ data: Data) -> Self {
        base.pointee.append(data)
        return self
    }
}

