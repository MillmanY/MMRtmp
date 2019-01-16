
//  DrawImageView.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/30.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
import MMRtmp

import AVFoundation

class VideoView: UIView {
    
     let displayLayer = RTMPPlayLayer()

    
    func stop() {
        self.displayLayer.stop()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.displayLayer.frame = self.bounds
    }
    
    required init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        self.setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    func setup() {
        self.layer.backgroundColor = UIColor.black.cgColor
        self.layer.addSublayer(displayLayer)
        self.layoutIfNeeded()
    }
}


