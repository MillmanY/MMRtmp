//
//  BitData.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/8.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
enum BitDataError: Error {
    case overflow
}

enum BitType: Int {
    case zero = 0
    case one = 1
}

class BitData {
    private(set) var bit = [BitType]()
    
    public func append(data: BitType) {
        bit.append(data)
    }
    
    public func append(datas: [BitType]) {
        bit += datas
    }
    
    func append(number: Int, bitCount: Int) throws {
        var convert = [BitType]()
        
        var n = number
        while n != 0 {
            if let b = BitType(rawValue: n%2) {
                convert.insert(b, at: 0)
            }
            n = n/2
        }
        let append = bitCount - convert.count
        if append >= 0 {
            bit += ((0..<append).map({ _ in return BitType.zero }) + convert)
        } else {
            throw BitDataError.overflow
        }
    }
    
    func bytes() -> [UInt8] {
        return bit.split(size: 8).map {
            $0.reversed().enumerated().reduce(0, { (rc, current) -> UInt8 in
                switch current.element {
                case .zero:
                    return rc
                case .one:
                    return rc + UInt8(pow(Double(2), Double(current.offset)))
                }
            })
        }
    }
}
