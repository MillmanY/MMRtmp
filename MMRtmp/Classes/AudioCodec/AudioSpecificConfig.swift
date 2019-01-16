//
//  AudioSpecificConfig.swift
//  MMRtmp
//
//  Created by Millman on 2018/12/14.
//

import Foundation
import AudioToolbox

/*
 AudioSpecificConfig = 2 bytes,
 number = bits
 ------------------------------
 | audioObjectType (5)        |
 | sampleingFrequencyIndex (4)|
 | channelConfigration (4)    |
 | frameLengthFlag (1)        |
 | dependsOnCoreCoder (1)     |
 | extensionFlag (1)          |
 ------------------------------
*/
struct AudioSpecificConfig {
    let objectType: MPEG4ObjectID
    var channelConfig: ChannelConfigType = .unknown
    var frequencyType: SampleFrequencyType = .unknown
    let frameLengthFlag: Bool
    let dependsOnCoreCoder: UInt8
    let extensionFlag: UInt8
    init (data: Data) {
        self.objectType = MPEG4ObjectID(rawValue: Int((0b11111000 & data[0]) >> 3)) ?? .aac_Main
        self.frequencyType = SampleFrequencyType(rawValue: (0b00000111 & data[0]) << 1 | (0b10000000 & data[1]) >> 7)
        self.channelConfig = ChannelConfigType(rawValue: (0b01111000 & data[1]) >> 3)
        let value = UInt8(data[1] & 0b00100000) == 1
        self.frameLengthFlag = value
        self.dependsOnCoreCoder = data[1] & 0b000000010
        self.extensionFlag = data[1] & 0b000000001
    }
    
    init(objectType: MPEG4ObjectID, channelConfig: ChannelConfigType, frequencyType: SampleFrequencyType, frameLengthFlag: Bool = false, dependsOnCoreCoder: UInt8 = 0, extensionFlag: UInt8 = 0) {
        self.objectType = objectType
        self.channelConfig = channelConfig
        self.frequencyType = frequencyType
        self.frameLengthFlag = frameLengthFlag
        self.dependsOnCoreCoder = dependsOnCoreCoder
        self.extensionFlag = extensionFlag
    }

    var encodeData: Data {
        get {            
            let flag = self.frameLengthFlag ? 1 : 0
            let first = UInt8(self.objectType.rawValue) << 3 | UInt8(self.frequencyType.rawValue >> 1 & 0b00000111)
            let second = (0b10000000 & self.frequencyType.rawValue << 7) |
                         (0b01111000 & self.channelConfig.rawValue << 3) |
                         (UInt8(flag) << 2) |
                         (self.dependsOnCoreCoder << 1) |
                         self.extensionFlag
            return Data([first, second])
        }
    }
}
