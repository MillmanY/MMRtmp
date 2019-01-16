//
//  RTMPDataResponse.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/28.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation

class RTMPDataResponse: DecodeResponseProtocol, Decodable {
    enum VideoEncodingType: Int, Decodable {
        case rgb = 0
        case runLength = 1
        case h263Sorenson = 2
        case screen1 = 3
        case vp6 = 4
        case vp6Alpha = 5
        case screen2 = 6
        case h264 = 7
        case h263ITU = 8
        case mp4ASP = 9
    }
    
    enum AudoEncodingType: Int, Decodable {
        case pcm = 0
        case adpcm = 1
        case mp3 = 2
        case pcmLittleEndian = 3
        case asao16 = 4
        case asao8 = 5
        case asaoRate = 6
        case aLaw = 7
        case uLaw = 8
        case aac = 10
        case speex = 11
    }
    
    
    struct Info: Decodable {
        var width: Double
        var framerate: Double
        var level: String
        var videocodecid: VideoEncodingType
        var audiocodecid: AudoEncodingType
        var height: Double
        var displayWidth: Double
        var displayHeight: Double
        var audiodatarate: Double
        var fps: Double
        var duration: Double
        var Server: String
        var videodatarate: Double
        var profile: String
    }
    let type: String
    var info: Info?
    required init(decode: Any?) {
        guard let d = decode as? [Any] else {
            self.type = ""
            return
        }
        self.type = (d.first as? String) ?? ""
        if let second = d[safe: 1] as? [String: Any] {
            self.info = second.decodeObject()
        }
    }
}

