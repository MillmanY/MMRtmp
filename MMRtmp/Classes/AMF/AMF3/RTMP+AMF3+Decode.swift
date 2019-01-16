//
//  RTMP+AMF3+Decode.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/16.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
public enum AMF3DecodeError: Error {
    case rangeError
    case parseError
    case parseArrayError
    case referenceParseError
}

extension Data {
    public func decodeAMF3() -> [Any]? {
        var b = self
        var reference = AMF3ReferenceTable()
        return b.decode(reference: &reference)
    }
}
private extension Data {
    mutating func decode(reference: inout AMF3ReferenceTable) -> [Any]? {
        var decodeData = [Any]()
        while let first = self.first {
            guard let realType = RTMPAMF3Type(rawValue: first) else {
                return nil
            }
            self.remove(at: 0)
            do {
                let value = try self.parseValue(type: realType, reference: &reference)
                decodeData.append(value)
            } catch let error {
                print("Decode Error \(error.localizedDescription)")
                return nil
            }
    
        }
        return decodeData
    }
    
    mutating func parseValue(type: RTMPAMF3Type, reference: inout AMF3ReferenceTable) throws -> Any {
        switch type {
        case .undefined ,.null:
            return nullString
        case .boolTrue:
            return true
        case .boolFalse:
            return false
        case .int:
            return self.convertLength()
        case .double:
            return try self.decodeDouble()
        case .string:
            return try self.decodeString(&reference)
        case .xml:
            return try self.decodeXML(&reference)
        case .date:
            return try self.decodeDate(&reference)
        case .array:
            return try self.decodeArray(&reference)
        case .object:
            return try self.decodeObject(&reference)
        case .xmlEnd:
            break
        case .byteArray:
            return try self.decodeByteArray(&reference)
        case .vectorInt:
            let value: [Int32] = try self.decodeVectorNumber(&reference)
            return value
        case .vectorUInt:
            let value: [UInt32] = try self.decodeVectorNumber(&reference)
            return value
        case .vectorDouble:
            let value: [Double] = try self.decodeVectorNumber(&reference)
            return value
        case .vectorObject:
            let value: [Any] = try self.decodeVectorObject(&reference)
            return value
        case .dictionary:
            break
        }
        return 0
    }
    
    mutating func decodeDouble() throws -> Double {
        let range = 0..<8
        guard let value = self[safe: range] else {
            throw AMF3DecodeError.rangeError
        }
        self.removeSubrange(range)
        return Data(value.reversed()).double
    }
    
    mutating func decodeString(_ reference: inout AMF3ReferenceTable) throws -> String {
        
        let (length, type) = try self.decodeLengthWithType()
        switch type {
        case .value:
            let range = 0..<length
            guard let rangeBytes = self[safe: range] else {
                throw AMF3DecodeError.rangeError
            }
            let value = rangeBytes.string
            if value.count > 0 {
                reference.append(value)
            }
            self.removeSubrange(range)
            return value
        case .reference:
            return reference.string(index: length)
        }
    }
    
    mutating func decodeDate(_ reference: inout AMF3ReferenceTable) throws -> Date {
        let (length, type) = try self.decodeLengthWithType()

        switch type {
        case .reference:
            guard let date: Date = reference.object(length) else {
                throw AMF3DecodeError.referenceParseError
            }
            return date
        case .value:
            let range = 0..<8
            guard let rangeByte = self[safe: range] else {
                throw AMF3DecodeError.rangeError
            }
            let value = Date(timeIntervalSince1970: Data(rangeByte.reversed()).double / 1000)
            reference.append(value)
            self.removeSubrange(range)
            return value
        }
    }
    
    mutating func decodeArray(_ reference: inout AMF3ReferenceTable) throws -> [Any] {
        let (length, type) = try self.decodeLengthWithType()
        switch type {
        case .reference:
            guard let array: [Any] = reference.object(length) else {
                throw AMF3DecodeError.referenceParseError
            }
            return array
        case .value:
            let value = try self.decodeArray(length: length, reference: &reference)
            reference.append(value)
            return value
        }
    }
    
    private mutating func decodeArray(length: Int, reference: inout AMF3ReferenceTable) throws -> [Any] {
        self.remove(at: 0)
        var decodeData = [Any]()
        do {
            try (0..<length).forEach { _ in
                guard let first = self.first, let type = RTMPAMF3Type(rawValue: first) else {
                    throw AMF3DecodeError.rangeError
                }
                self.remove(at: 0)
                let value = try self.parseValue(type: type, reference: &reference)
                decodeData.append(value)
            }
        } catch {
            throw AMF3DecodeError.parseArrayError
        }
        return decodeData
    }
    
    mutating func decodeXML(_ reference: inout AMF3ReferenceTable) throws -> String {
        let (length, type) = try self.decodeLengthWithType()
        switch type {
        case .value:
            let range = 0..<length
            guard let rangeBytes = self[safe: range] else {
                throw AMF3DecodeError.rangeError
            }
            let value = rangeBytes.string
            self.removeSubrange(range)
            reference.append(value)
            return value
        case .reference:
            guard let xml: String = reference.object(length) else {
                throw AMF3DecodeError.referenceParseError
            }
            return xml
        }
    }
    
    mutating func decodeObjectInfo(_ reference: inout AMF3ReferenceTable) throws -> [String: Any] {
        var map = [String: Any]()
        if let className = try? self.decodeString(&reference), className.count > 0 {
            map["className"] = className
        }
        var key = ""
        while let first = self.first {
            var type: RTMPAMF3Type? = RTMPAMF3Type(rawValue: first)
            
            if key.isEmpty {
                type = .string
                let value = try self.decodeString(&reference)
                key = value
                if key.count == 0 { break }
                continue
            }
            guard let t = type else {
                throw AMF3DecodeError.rangeError
            }
            
            self.remove(at: 0)
            switch t {
            case .string:
                let value = try self.decodeString(&reference)
                map[key] = value
                key = ""
            case .object:
                let idx = reference.createReserved()
                let value = try self.decodeObjectInfo(&reference)
                map[key] = value
                reference.replace(value, idx: idx)
                key = ""
            default:
                let value = try self.parseValue(type: t, reference: &reference)
                map[key] = value
                key = ""
            }
        }
        return map
    }
    mutating func decodeObject(_ reference: inout AMF3ReferenceTable) throws -> [String: Any] {
        let value = self.convertLength()
        var map = [String: Any]()
        if value & 0b01 == 0 {
            guard let obj: [String: Any] = reference.object(value >> 1) else {
                throw AMF3DecodeError.referenceParseError
            }
            return obj
        } else if value & 0b10 == 0 {
            guard let obj: [String: Any] = reference.object(value >> 2) else {
                throw AMF3DecodeError.referenceParseError
            }
            return obj
        } else if value & 0x0f == 0x07, let className = try? self.decodeString(&reference), className.count > 0 {
            map["className"] = className
        } else if value & 0x0f == 0x0b {
            
            let idx = reference.createReserved()
            let info = try self.decodeObjectInfo(&reference)
            reference.replace(info, idx: idx)
            return info
        }
        return map
    }
    
    mutating func decodeByteArray(_ reference: inout AMF3ReferenceTable) throws -> Data {
        let (length, type) = try self.decodeLengthWithType()
        switch type {
        case .value:
            let range = 0..<length
            guard let rangeBytes = self[safe: range] else {
                throw AMF3DecodeError.rangeError
            }
            reference.append(rangeBytes)
            self.removeSubrange(range)
            return rangeBytes
        case .reference:
            guard let byte: Data = reference.object(length) else {
                throw AMF3DecodeError.referenceParseError
            }
            return byte
        }
    }
    
    mutating func decodeVectorNumber<T>(_ reference: inout AMF3ReferenceTable) throws -> [T] {
        var decodeData = [T]()
        let (length, type) = try self.decodeLengthWithType()

        guard let first = self.first,
            let _ = AMF3EncodeType.Vector(rawValue: first) else {
                throw AMF3DecodeError.rangeError
        }
        self.remove(at: 0)
        switch type {
        case .value:
            var range = 0..<4
            if T.self == Double.self {
                range = 0..<8
            }
            try (0..<length).forEach { _ in
                guard let rangeBytes = self[safe: range] else {
                    throw AMF3DecodeError.rangeError
                }
                if T.self == UInt32.self {
                    decodeData.append(Data(rangeBytes.reversed()).uint32 as! T)
                } else if T.self == Int32.self {
                    decodeData.append(Data(rangeBytes.reversed()).int32 as! T)
                } else if T.self == Double.self {
                    decodeData.append(Data(rangeBytes.reversed()).double as! T)
                }
                self.removeSubrange(range)
            }
        case .reference:
            guard let number: [T] = reference.object(length) else {
                throw AMF3DecodeError.referenceParseError
            }
            return number
        }
        reference.append(decodeData)
        return decodeData
    }
    
    mutating func decodeVectorObject(_ reference: inout AMF3ReferenceTable) throws -> [Any] {
        let (count, objType) = try self.decodeLengthWithType()
        self.remove(at: 0)
        let (typeLength, _) = try self.decodeLengthWithType()
        switch objType {
        case .value:
            let range = 0..<typeLength
            guard let _ = self[safe: range] else {
                throw AMF3DecodeError.rangeError
            }
            self.removeSubrange(range)
        case .reference:
            guard let vectorObj: [Any] = reference.object(count) else {
                throw AMF3DecodeError.referenceParseError
            }
            return vectorObj
        }
        return [Any]()
    }

    
    mutating func decodeLengthWithType() throws -> (length: Int, type: AMF3EncodeType.U29) {
        let value = self.convertLength()
        
        let length = value >> 1
        let u29Raw = UInt8(value & 0x01)
        
        guard let type = AMF3EncodeType.U29(rawValue: u29Raw) else {
            throw AMF3DecodeError.rangeError
        }
        return (length, type)
    }
    
    mutating func convertLength() -> Int {
        var lastIdx = 0
        var numberArr = [UInt8]()
        while let first = self.first {
            let isEnd = first <= 0x7f || lastIdx == 3
            let byte = isEnd ? first : first & 0x7f
            numberArr.append(byte)
            self.remove(at: 0)
            if isEnd { break }
            lastIdx += 1
        }
        let value = numberArr.enumerated().reduce(0) { (rc, current) -> Int in
            var shift =  (lastIdx-current.offset)*7
            if lastIdx == 3 && current.offset != 3 {
                shift += 1
            }
            return rc + Int(current.element) << shift
        }
        
        return value
    }
}
