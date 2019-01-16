//
//  AMFProtocol.swift
//  MMRtmp
//
//  Created by Millman on 2018/12/26.
//

import Foundation
protocol AMFProtocol {
    var data: Data { get set }
    mutating func append(_ value: Double)
    mutating func append(_ value: String)
    mutating func appned(_ value: Bool)
    mutating func append(_ value: [String: Any?]?)
    mutating func append(_ value: Date)
    mutating func appendNil()
    mutating func append(_ value: [Any])
    mutating func appendXML(_ value: String)
    mutating func decode() -> [Any]?
    static func decode(_ data: Data) -> [Any]?
}

protocol AMF0Protocol: AMFProtocol {
    mutating func appendEcma(_ value: [String: Any?])
}

protocol AMF3Protocol: AMFProtocol {
    mutating func appendUndefined()
    mutating func append(_ value: Int)
    mutating func appendVector(_ value: [Int32])
    mutating func appendVector(_ value: [UInt32])
    mutating func appendVector(_ value: [Double])
    mutating func appendByteArray(_ value: Data)
}
