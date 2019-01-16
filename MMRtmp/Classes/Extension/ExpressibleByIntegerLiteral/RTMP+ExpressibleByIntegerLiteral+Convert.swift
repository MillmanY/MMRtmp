//
//  MMPlayer+ExpressibleByIntegerLiteral+Convert.swift
//  FLVTest
//
//  Created by Millman YANG on 2017/11/12.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation

extension ExpressibleByIntegerLiteral {
    var data: Data {
        var v: Self = self
        let s:Int = MemoryLayout<`Self`>.size
        return withUnsafeMutablePointer(to: &v, {
            return $0.withMemoryRebound(to: UInt8.self, capacity: s, {
                Data(UnsafeBufferPointer(start: $0, count: s))
            })
        })
    }
}
