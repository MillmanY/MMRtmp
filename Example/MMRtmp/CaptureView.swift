//
//  CaptureView.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2018/1/4.
//  Copyright © 2018年 Millman YANG. All rights reserved.
//

import UIKit
import MMRtmp
import AVFoundation
class CaptureView: UIView {
    lazy var publishLayer: RTMPPublishLayer = {
        let l = RTMPPublishLayer()
        l.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.layer.insertSublayer(l, at: 0)
        return l
    }()

    override func layoutSubviews() {
        super.layoutSubviews()
        publishLayer.frame = self.bounds
    }
    
}

