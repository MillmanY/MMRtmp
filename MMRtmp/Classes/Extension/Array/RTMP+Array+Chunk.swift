//
//  RTMP+Array+Chunk.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/17.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
extension Array {
    func split(size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map({
            let end = $0 + size >= count ? count : $0 + size
            return Array(self[$0..<end])
        })
    }
}
