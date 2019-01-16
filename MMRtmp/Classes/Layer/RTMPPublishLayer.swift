//
//  RTMPPublishLayer.swift
//  MMRtmp
//
//  Created by Millman on 2018/12/20.
//

import UIKit
import AVFoundation

public class RTMPPublishLayer: AVCaptureVideoPreviewLayer {
    fileprivate var statusCallBack: ((RTMPPublishSession.Status)->Void?)?
    public var publishSession =  RTMPPublishSession()
    
    public var videoFPS: TimeInterval {
        get {
            guard let videoInput = AVCaptureDevice.default(for: .video) else {
                return 30
            }
            return TimeInterval(videoInput.activeVideoMinFrameDuration.timescale)
        } set {
            guard let videoInput = AVCaptureDevice.default(for: .video) else {
                return
            }
            let fps = CMTime(value: 1, timescale: CMTimeScale(newValue))
            try? videoInput.lockForConfiguration()
            videoInput.activeVideoMinFrameDuration = fps
            videoInput.activeVideoMaxFrameDuration = fps
            videoInput.unlockForConfiguration()
        }
    }
    
    public var currentStatus: RTMPPublishSession.Status {
        get {
            return publishSession.publishStatus
        }
    }

    fileprivate lazy var videoOutput: AVCaptureVideoDataOutput = {
        return AVCaptureVideoDataOutput()
    }()
    fileprivate lazy var audioOutput: AVCaptureAudioDataOutput = {
        return AVCaptureAudioDataOutput()
    }()
    required init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
    }
 
    public override init(layer: Any) {
        super.init(layer: layer)
    }
    
    public override init() {
        super.init(session: AVCaptureSession())
    }
    
    public override init(session: AVCaptureSession) {
        super.init(session: session)
    }
}
// Public
extension RTMPPublishLayer {
    public func setMessageType(type: ObjectEncodingType) {
        publishSession.encodeType = type
    }

    public func publishStatus(callBack: ((RTMPPublishSession.Status)->Void)?) {
        statusCallBack = callBack
    }

    public func authVideoAudio(completed: @escaping (Bool)->Void) {
        DispatchQueue.main.async { [unowned self] in
            let video = AVCaptureDevice.authorizationStatus(for: .video)
            let audio = AVCaptureDevice.authorizationStatus(for: .audio)
            self.auth(video: video, audio: audio, completed: completed)
        }
    }

    fileprivate func auth(video: AVAuthorizationStatus, audio: AVAuthorizationStatus, completed: @escaping (Bool)->Void) {
        switch (video, audio) {
        case (.authorized, .authorized):
            self.setup()
            completed(true)
        case (.notDetermined, _), (_, .notDetermined):
            let group = DispatchGroup.init()
            group.enter()
            AVCaptureDevice.requestAccess(for: .video) { (rc) in
                group.leave()
            }
            group.enter()
            AVCaptureDevice.requestAccess(for: .audio) { (rc) in
                group.leave()
            }
            group.notify(queue: DispatchQueue.main) {
                let video = AVCaptureDevice.authorizationStatus(for: .video)
                let audio = AVCaptureDevice.authorizationStatus(for: .audio)
                self.auth(video: video, audio: audio, completed: completed)
            }
        default:
            completed(false)
        }
    }
    
    public func publish(host: String, name: String, port:Int = defaultPort) {
        publishSession.publishStream(host: host, port: port, name: name).resume()
    }
    
    public func stop() {
        publishSession.invalidate()
    }
}
// Private
extension RTMPPublishLayer {
    fileprivate func setup() {
        if session?.outputs.contains(videoOutput) == true && session?.outputs.contains(audioOutput) == true {
            return
        }
        publishSession.delegate = self
        guard let audioInput = AVCaptureDevice.default(for: .audio) else {
            return
        }
        guard let videoInput = AVCaptureDevice.default(for: .video) else {
            return
        }
        do {
            try self.session?.addInput(AVCaptureDeviceInput(device: videoInput))
            try self.session?.addInput(AVCaptureDeviceInput(device: audioInput))
        } catch {
            return
        }
        
        self.session?.sessionPreset = .medium
        self.session?.addOutput(videoOutput)
        self.session?.addOutput(audioOutput)
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        audioOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        self.videoFPS = 30
        if self.session?.isRunning == false {
            self.session?.startRunning()
        }
    }
}

extension RTMPPublishLayer: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        switch output {
        case _ as AVCaptureAudioDataOutput:
            self.publishSession.publishAudio(buffer: sampleBuffer)
        case _ as AVCaptureVideoDataOutput:
            self.connection?.videoOrientation = UIDevice.current.orientation.avcaptureOrientation
            connection.videoOrientation = UIDevice.current.orientation.avcaptureOrientation
            self.publishSession.setVideoSizeIfNeed(self.bounds.size)
            self.publishSession.publishVideo(buffer: sampleBuffer)
        default:
            break
        }
    }
}

extension RTMPPublishLayer: RTMPPublishSessionDelegate {
    public func sessionMetaData(_ session: RTMPPublishSession) -> [String : Any] {
        var meta = [String: Any]()
        meta["width"] = Int32(self.bounds.width)
        meta["height"] = Int32(self.bounds.height)
        meta["displayWidth"] = Int32(self.bounds.width)
        meta["displayHeight"] = Int32(self.bounds.height)
        meta["videocodecid"] = VideoData.CodecId.avc.rawValue
        meta["audiocodecid"] = AudioData.SoundFormat.aac.rawValue
        meta["framerate"] = videoFPS
        meta["videoframerate"] = videoFPS
        return meta
    }
    
    public func sessionStatusChange(_ session: RTMPPublishSession,  status: RTMPPublishSession.Status) {
        DispatchQueue.main.async { [weak self] in
            self?.statusCallBack?(status)
        }
    }
}
