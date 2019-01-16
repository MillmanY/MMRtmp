//
//  PublishViewController.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2018/1/3.
//  Copyright © 2018年 Millman YANG. All rights reserved.
//

import UIKit
import AVFoundation
import MMRtmp

class PublishViewController: UIViewController {
    @IBOutlet weak var txtHost: UITextField!
    @IBOutlet weak var txtStreamName: UITextField!
    @IBOutlet weak var btnConnect: UIButton!
    @IBOutlet weak var capture: CaptureView!
    override func viewDidLoad() {
        super.viewDidLoad()
        txtHost.text = "rtmp://192.168.37.78/rtmplive"
        txtStreamName.text = "home"
        
        capture.publishLayer.publishStatus { (status) in
            switch status {
            case .unknown, .disconnected:
                self.btnConnect.setTitle("Publish", for: .normal)
            case .connect:
                self.btnConnect.setTitle("Disconnect", for: .normal)
            case .failed(_):
                self.btnConnect.setTitle("Publish", for: .normal)
            case .publishStart:
                break
            }
        }
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        capture.publishLayer.authVideoAudio { (rc) in
            if !rc {
                let alert = UIAlertController.init(title: "Error", message: "you need auth your microphone and camera", preferredStyle: .alert)
                
                let action = UIAlertAction.init(title: "confirm", style: .default, handler: nil)
                alert.addAction(action)
            }
        }
    }
    
    @IBAction func publishAction(button: UIButton) {
        guard let host = txtHost.text, let name = txtStreamName.text else {
            return
        }
        switch capture.publishLayer.currentStatus {
        case .connect, .publishStart:
            capture.publishLayer.stop()
        case .failed(let err):
            print(err.localizedDescription)
        case .unknown, .disconnected:
            capture.publishLayer.publish(host: host, name: name)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
