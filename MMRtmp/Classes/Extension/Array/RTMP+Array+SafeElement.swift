//
//  RTMP+Array+SafeElement.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/20.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation

public extension Array {
    subscript (safe range: CountableRange<Int>) -> ArraySlice<Element>? {
        
        if range.lowerBound < 0 || range.count > self.count {
            return nil
        }
        return self[range]
    }
    
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
