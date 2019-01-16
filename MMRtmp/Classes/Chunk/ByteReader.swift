//
//  ByteReader.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/22.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
struct ByteReader {
    var isEmpty = true
    private var _position = 0
    private(set) var position: Int  {
        set {
            if newValue >= base.count-1 {
                isEmpty = true
                _position = base.count - 1
            } else {
                isEmpty = false
                _position = newValue
            }
            
        } get {
            return _position
        }
    }
    private let base: Data
    init(_ base: Data) {
        self.base = base
    }

    var readUInt8: UInt8? {
        mutating get {
            let data = self.base[safe: position]
            self.position += 1
            return data
        }
    }
    
    mutating func readUInt16(bigEndian: Bool = true) -> UInt16? {
        guard var bytes = self.base[safe: position..<position+2] else {
            return nil
        }
        
        self.position += 2
        if bigEndian { bytes.reverse() }
        return bytes.uint16
    }
    
    mutating func read(length: Int) -> Data? {
        guard let range = self.base[safe: position..<position+length] else {
            return nil
        }
        position += length
        return range
    }
    
    mutating func shiftPosition(loc: Int) {
        self.position = loc
    }
    
    mutating func readUInt32(bigEndian: Bool = true) -> UInt32? {
        guard var bytes = self.base[safe: position..<position+4] else {
            return nil
        }
        
        self.position += 4
        if bigEndian { bytes.reverse() }
        return bytes.uint32
    }
}
