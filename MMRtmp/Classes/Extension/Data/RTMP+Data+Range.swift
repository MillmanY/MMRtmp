//
//  RTMP+Data+Range.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/17.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
extension Data {
    subscript (r: Range<Int>) -> Data {
        let range = Range(uncheckedBounds: (lower: Swift.max(0, r.lowerBound),
                                            upper: Swift.min(count, r.upperBound)))
        return self.subdata(in: range)
    }
    
    subscript (safe range: CountableRange<Int>) -> Data? {
        if range.lowerBound < 0 || range.upperBound > self.count {
            return nil
        }
        
        return self[range]
    }
    
    subscript (safe range: CountableClosedRange<Int>) -> Data? {
        if range.lowerBound < 0 || range.upperBound >= self.count {
            return nil
        }
        
        return self[range]
    }

    subscript (safe index: Int) -> UInt8? {
        if index > 0 && index < self.count {
            return self[index]
        }
        return nil
    }
}


