//
//  RTMP+AudioStreamBasicDescription+Parameter.swift
//  MMRtmp
//
//  Created by Millman on 2018/12/15.
//

import Foundation
import CoreMedia
extension CMAudioFormatDescription {
  
    var streamBasicDesc: AudioStreamBasicDescription? {
        get {
            return CMAudioFormatDescriptionGetStreamBasicDescription(self)?.pointee
        }
    }
}
