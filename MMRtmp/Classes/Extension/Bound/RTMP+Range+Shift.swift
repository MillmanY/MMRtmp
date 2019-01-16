//
//  RTMP+Range+Shift.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/6.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
extension CountableClosedRange where Bound == Int {
    func shift(index: Int) -> CountableClosedRange<Int> {
        return self.lowerBound+index...self.upperBound+index
    }
}
extension CountableRange where Bound == Int {
    func shift(index: Int) -> CountableRange<Int> {
        return self.lowerBound+index..<self.upperBound+index
    }
}
