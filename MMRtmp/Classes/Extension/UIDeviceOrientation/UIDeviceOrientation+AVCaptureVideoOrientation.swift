//
//  UIDeviceOrientation.swift
//  MMRtmp
//
//  Created by Millman on 2018/12/27.
//

import Foundation
import AVFoundation
extension UIDeviceOrientation {
    var avcaptureOrientation: AVCaptureVideoOrientation {
        get {
            switch self {
            case .landscapeLeft:
                return .landscapeRight
            case .landscapeRight:
                return .landscapeLeft
            case .portrait:
                return .portrait
            case .portraitUpsideDown:
                return .portraitUpsideDown
            default:
                return .portrait
            }
        }
    }
    
}

