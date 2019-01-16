//
//  RTMP+AMF+Decode.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/17.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
let entryPoint = 0...3
enum AMF0DecodeError: Error {
    case rangeError
    case parseError
}

extension Data {
    public func decodeAMF0() -> [Any]? {
        var b = self
        return b.decode()
    }
}

extension Data  {

    mutating func decode() -> [Any]? {
        var decodeData = [Any]()
        while let first = self.first {
            guard let realType = RTMPAMF0Type(rawValue: first) else {
                return decodeData
            }

            self.remove(at: 0)
            do {
                try decodeData.append(self.parseValue(type: realType))
            } catch {
                print("Decode Error \(error.localizedDescription)")
                return nil
            }
        }
        return decodeData
    }
    
    mutating func parseValue(type: RTMPAMF0Type) throws -> Any {
        switch type {
        case .number:
            return try self.decodeNumber()
        case .boolean:
            return try self.decodeBool()
        case .string, .longString:
            return try self.decodeString(type: type)
        case .null:
            return nullString
        case .xml:
            return try self.decodeXML()
        case .date:
            return try self.decodeDate()
        case .object:
            return try self.decodeObj()
        case .typedObject:
            return try self.decodeTypeObject()
        case .array:
            return try self.deocdeArray()
        case .strictArray:
            return try self.decodeStrictArray()
        case .switchAMF3:
            return "Need implement"
        default:
            return AMF0DecodeError.parseError
        }
    }

    mutating func decodeNumber() throws -> Double {
        let range = 0..<8
        guard let value = self[safe: range] else {
            throw AMF0DecodeError.rangeError
        }
        self.removeSubrange(range)
        let convert = Data(value.reversed()).double
        return convert
    }
    
    mutating func decodeBool() throws -> Bool {
        guard let result = self.first else {
            throw AMF0DecodeError.rangeError
        }
        self.remove(at: 0)
        return result == 0x01
    }
    
    mutating func decodeString(type: RTMPAMF0Type) throws -> String {
        let range = 0..<(type == .string ? 2 : 4)
        
        guard let rangeBytes = self[safe: range] else {
            throw AMF0DecodeError.rangeError
        }
        let length = Data(rangeBytes.reversed()).uint32
        self.removeSubrange(range)
        let value = self[0..<Int(length)].string
        self.removeSubrange(0..<Int(length))
        return value
    }
    
    mutating func decodeXML() throws -> String {
        let range = 0..<4
        guard let rangeBytes = self[safe: range] else {
            throw AMF0DecodeError.rangeError
        }
        let length = Data(rangeBytes.reversed()).uint32
        self.removeSubrange(range)
        let value = self[0..<Int(length)].string
        self.removeSubrange(0..<Int(length))
        return value
    }
    
    mutating func decodeDate() throws -> Date {
        guard let value = self[safe: 0..<8] else {
            throw AMF0DecodeError.rangeError
        }
        let convert = Data(value.reversed()).double
        let result = Date(timeIntervalSince1970: convert/1000)
        self.removeSubrange(0..<10)
        return result
    }
    
    mutating func decodeObj() throws -> [String: Any] {
        var map = [String: Any]()
        var key = ""
        while let first = self.first, first != RTMPAMF0Type.objectEnd.rawValue {
            var type: RTMPAMF0Type? = RTMPAMF0Type(rawValue: first)
            if key.isEmpty {
                type = .string
                let value = try self.decodeString(type: .string)
                key = value
                continue
            }

            guard let t = type else {
                throw AMF0DecodeError.rangeError
            }
            self.remove(at: 0)

            switch t {
            case .string, .longString:
                let value = try self.decodeString(type: t)
                map[key] = value
                key = ""
            default:
                
                let value = try self.parseValue(type: t)
                map[key] = value
                key = ""
            }
        }
        self.remove(at: 0)
  
        return map
    }
    
    mutating func decodeTypeObject() throws -> [String: Any] {
        let range = 0..<2
        self.removeSubrange(range)
        return try self.decodeObj()
    }
    
    mutating func deocdeArray() throws -> [String: Any] {
        self.removeSubrange(entryPoint)
        let value = try self.decodeObj()
        return value
    }
    
    mutating func decodeStrictArray() throws -> [Any] {
        guard let rangeBytes = self[safe: entryPoint] else {
            throw AMF0DecodeError.rangeError
        }
        var decodeData = [Any]()

        var count = Int(Data(rangeBytes.reversed()).uint32)
        self.removeSubrange(entryPoint)
        while let first = self.first, count != 0 {
            guard let type = RTMPAMF0Type(rawValue: first) else {
                throw AMF0DecodeError.rangeError
            }
            self.remove(at: 0)
            try decodeData.append(self.parseValue(type: type))
            count -= 1
        }
        return decodeData
    }
}
