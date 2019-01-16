//
//  MetaDataResponse.swift
//  MMRtmp
//
//  Created by Millman on 2018/11/30.
//

import UIKit
public struct Sampledescription : Codable {
    public let sampletype: String
    public enum CodingKeys: String, CodingKey {
        case sampletype = "sampletype"
    }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sampletype = (try? values.decode(String.self, forKey: .sampletype)) ?? ""
    }
}

public struct Trackinfo : Codable {
    
    public let sampledescription : [Sampledescription]
    public let language : String
    public let timescale : Double
    public let length : Double
    
    public enum CodingKeys: String, CodingKey {
        
        case sampledescription = "sampledescription"
        case language = "language"
        case timescale = "timescale"
        case length = "length"
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sampledescription = (try? values.decode([Sampledescription].self, forKey: .sampledescription)) ?? [Sampledescription]()
        language = (try? values.decode(String.self, forKey: .language)) ?? ""
        timescale = (try? values.decode(Double.self, forKey: .timescale)) ?? 0
        length = (try? values.decode(Double.self, forKey: .length)) ?? 0
    }
}


public struct MetaDataResponse: Codable {
    public var duration : Double = 0
    public var height : Int = 0
    public var frameWidth : Int = 0
    public var moovposition : Int = 0
    public var framerate : Int = 0
    public var avcprofile : Int = 0
    public var videocodecid : String = ""
    public var frameHeight : Int = 0
    public var videoframerate : Int = 0
    public var audiochannels : Int = 0
    public var displayWidth : Int = 0
    public var displayHeight : Int = 0
    public var trackinfo = [Trackinfo]()
    public var width : Int = 0
    public var avclevel : Int = 0
    public var audiosamplerate : Int = 0
    public var aacaot : Int = 0
    public var audiocodecid : String = ""
    
    enum CodingKeys: String, CodingKey {
        
        case duration = "duration"
        case height = "height"
        case frameWidth = "frameWidth"
        case moovposition = "moovposition"
        case framerate = "framerate"
        case avcprofile = "avcprofile"
        case videocodecid = "videocodecid"
        case frameHeight = "frameHeight"
        case videoframerate = "videoframerate"
        case audiochannels = "audiochannels"
        case displayWidth = "displayWidth"
        case displayHeight = "displayHeight"
        case trackinfo = "trackinfo"
        case width = "width"
        case avclevel = "avclevel"
        case audiosamplerate = "audiosamplerate"
        case aacaot = "aacaot"
        case audiocodecid = "audiocodecid"
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        duration = (try? values.decode(Double.self, forKey: .duration)) ?? 0
        height = (try? values.decode(Int.self, forKey: .height)) ?? 0
        frameWidth = (try? values.decode(Int.self, forKey: .frameWidth)) ?? 0
        moovposition = (try? values.decode(Int.self, forKey: .moovposition)) ?? 0
        framerate = (try? values.decode(Int.self, forKey: .framerate)) ?? 0
        avcprofile = (try? values.decode(Int.self, forKey: .avcprofile)) ?? 0
        videocodecid = (try? values.decode(String.self, forKey: .videocodecid)) ?? ""
        frameHeight = (try? values.decode(Int.self, forKey: .frameHeight)) ?? 0
        videoframerate = (try? values.decode(Int.self, forKey: .videoframerate)) ?? 0
        audiochannels = (try? values.decode(Int.self, forKey: .audiochannels)) ?? 0
        displayWidth = (try? values.decode(Int.self, forKey: .displayWidth)) ?? 0
        displayHeight = (try? values.decode(Int.self, forKey: .displayHeight)) ?? 0
        trackinfo = (try? values.decode([Trackinfo].self, forKey: .trackinfo)) ?? [Trackinfo]()
        width = (try? values.decode(Int.self, forKey: .width)) ?? 0
        avclevel = (try? values.decode(Int.self, forKey: .avclevel)) ?? 0
        audiosamplerate = (try? values.decode(Int.self, forKey: .audiosamplerate)) ?? 0
        aacaot = (try? values.decode(Int.self, forKey: .aacaot)) ?? 0
        audiocodecid = (try? values.decode(String.self, forKey: .audiocodecid)) ?? ""
    }
    
    init() {
        
    }
}
