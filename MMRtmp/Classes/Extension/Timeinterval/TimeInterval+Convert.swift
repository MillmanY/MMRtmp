//
//  TimeInterval+Convert.swift
//  MMRtmp
//
//  Created by Millman on 2018/12/7.
//

import Foundation

extension TimeInterval {
    var millSecond: TimeInterval {
        get {
            return self*1000
        }
    }
}
