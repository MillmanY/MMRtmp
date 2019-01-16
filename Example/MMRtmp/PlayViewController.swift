//
//  ViewController.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/13.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import UIKit
import AVFoundation
import MMRtmp

class PlayViewController: UIViewController {
    
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet weak var txtHost: UITextField!
    @IBOutlet weak var txtStreamName: UITextField!
    @IBOutlet weak var drawImageView: VideoView!
    @IBOutlet weak var btnPlay: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        txtHost.text = "rtmp://184.72.239.149/vod"
        txtStreamName.text = "BigBuckBunny_115k.mov"
//        txtHost.text = "rtmp://192.168.37.78/rtmplive"
//        txtStreamName.text = "home"

        drawImageView.displayLayer.playStatus { [unowned self] (status) in
            switch status {
            case .connect:
                self.pauseBtn.isHidden = false
                self.btnPlay.setTitle("Disconnected", for: .normal)
            case .failed(let err):
                print(err)
            case .unknown:
                self.pauseBtn.isHidden = true
            case .disconnected:
                self.btnPlay.setTitle("Play", for: .normal)
            case .pause:
                self.pauseBtn.setTitle("Resume", for: .normal)
            case .playStart:
                self.pauseBtn.setTitle("Pause", for: .normal)
                break
            }
        }
    }
    
    @IBAction func pauseAction() {
//        self.drawImageView.displayLayer.seek(duration: 200)
        switch self.drawImageView.displayLayer.currentStatus {
        case .playStart:
            self.drawImageView.displayLayer.pause()
        case .pause:
            self.drawImageView.displayLayer.unPause()
        default:
          break
        }
    }
    
    @IBAction func playAction(btn: UIButton) {
        guard let host = txtHost.text, let name = txtStreamName.text else {
            return
        }
        switch drawImageView.displayLayer.currentStatus {
        case .unknown:
            drawImageView.displayLayer.play(host: host, name: name)
        default:
            drawImageView.displayLayer.stop()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


