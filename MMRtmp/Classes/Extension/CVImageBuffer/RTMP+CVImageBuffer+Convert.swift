//
//  CVImageBuffer+Convert.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/28.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import UIKit
import AVFoundation
extension CVImageBuffer {
    func convert() -> UIImage {
        return UIImage(ciImage: CIImage(cvImageBuffer: self))
    }
}
