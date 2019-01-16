//
//  RTMPResponse.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/21.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation

class RTMPResponse {
    var name: String = ""
    var id: Int = -1
}

class ConnectResponse: RTMPResponse, DecodeResponseProtocol {
    struct Common: Decodable {
        var fmsVer: String
        var capabilities: Double
    }
    
    struct Information: Decodable {
        var description: String
        var level: String
        var code: CodeType.Connect
        var objectEncoding: ObjectEncodingType
    }
    
    var commonOjbect: Common?
    var info: Information?
    public required init(decode: Any?) {
        super.init()
        if let d = decode as? [Any],
           let name = d[safe: 0] as? String,
           let id = d[safe: 1] as? NSNumber,
           let obj = d[safe: 2] as? [String: Any],
           let info = d[safe: 3] as? [String: Any]{
            
            self.id = Int(truncating: id)
            self.name = name
            self.commonOjbect = obj.decodeObject()
            self.info = info.decodeObject()
        }
    }
}

class StreamResponse: RTMPResponse, DecodeResponseProtocol {
    var commonOjbect: [String: Any]?
    var streamId = 0
    
    public required init(decode: Any?) {
        super.init()
        if let d = decode as? [Any],
            let name = d[safe: 0] as? String,
            let id = d[safe: 1] as? NSNumber,
            let streamId = d[safe: 3] as? NSNumber {
            
            self.id = Int(truncating: id)
            self.name = name
            self.commonOjbect = d[safe: 2] as? [String: Any]
            self.streamId = Int(truncating: streamId)
        }
    }
}

class ControlResponse: UserControlMessage, DecodeResponseProtocol {
    required init(decode: Any?) {
        if let data = decode as? Data,
            let type = data[safe: 0..<2] {
            let convert = Data(type.reversed()).uint16
            super.init(type: UserControlEventType(rawValue: Int(convert)), data: data[2..<data.count])
        } else {
            super.init(type: .none, data: Data())
        }
    }
}


