//
//  RTMPLayer.swift
//  MMRtmp
//
//  Created by Millman on 2018/12/5.
//

import Foundation
import AVFoundation

public extension RTMPPlayLayer {
    enum BufferStatus {
        case keepUp
        case empty
    }
}

public class RTMPPlayLayer: AVSampleBufferDisplayLayer {
    fileprivate var audioCollection: AudioQueueCollection?
    fileprivate var session =  RTMPPlaySession()
    fileprivate var statusCallBack: ((RTMPPlaySession.Status)->Void?)?
    fileprivate var willResignObserver: Any?
    fileprivate var didBecomeActiveObserver: Any?
    public var reConnectWhenForground = true
    
    public var bufferStatus: BufferStatus = .empty {
        didSet {
            if oldValue == bufferStatus { return }
        }
    }

    public var currentStatus: RTMPPlaySession.Status {
        get {
            return session.playStatus
        }
    }
    
    public override init() {
        super.init()
        self.setup()
    }
    
    public override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    var video = [VideoBuffer]()
    var displayLink: CADisplayLink?
    @objc func update(link: CADisplayLink) {
        DispatchQueue.main.async { [weak self] in
            self?._update()
        }
    }
    
    func _update() {
        guard let info = video.first else {
            return
        }
        if self.error != nil { self.flushAndRemoveImage() }
        if let audio = audioCollection,
            let base = self.controlTimebase {
            let contain = info.isAudioContain(audioTime: audio.timeStamp)
            if info.buffer.frameTimeRangeDuration.upperBound <= audio.timeStamp.seconds {
                self.enqueue(info.buffer)
                video.removeFirst()
            } else if contain {
                self.enqueue(info.buffer)
                bufferStatus = (audio.bufferCount == 0 && video.count <= 1) ? .empty : .keepUp
            }
            CMTimebaseSetTime(base, time: audio.timeStamp)
        } else {
            self.enqueue(info.buffer)
            video.removeFirst()
            bufferStatus = video.count == 0 ? .empty : .keepUp
        }
    }
}

extension RTMPPlayLayer {
    
    public func setMessageType(type: ObjectEncodingType) {
        session.encodeType = type
    }
    public func stop() {
        session.invalidate()
        self.refreshData()
        displayLink?.invalidate()
        displayLink = nil
        self.audioCollection = nil
        self.flushAndRemoveImage()
        self.removeobserver()
    }
    
    public func playStatus(callBack: ((RTMPPlaySession.Status)->Void)?) {
        statusCallBack = callBack
    }
    
    public func play(host: String, name: String, port:Int = defaultPort) {
        self.resetDisplayLink()
        self.addObserver()
        session.play(host: host, port: port, name: name).resume()
    }
        
    public func pause() {
        if  session.pause(isPause: true) {
            audioCollection?.pause()
        }
    }
    
    public func unPause() {
        if session.pause(isPause: false) {
            audioCollection?.playQueue()
        }
    }
    
    public func seek(duration: TimeInterval) {
        session.seek(duration: duration)
    }
}

extension RTMPPlayLayer {

    fileprivate func setup() {
        session.delegate = self
        CMTimebaseCreateWithMasterClock(allocator: kCFAllocatorDefault, masterClock: CMClockGetHostTimeClock(), timebaseOut: &self.controlTimebase)
        if let base = self.controlTimebase {
            CMTimebaseSetRate(base, rate: 0.0)
        }
        self.layoutIfNeeded()
    }
    
    fileprivate func resetDisplayLink() {
        if displayLink == nil {
            displayLink = CADisplayLink(target: self, selector: #selector(update(link:)))
            displayLink?.preferredFramesPerSecond = 60
            displayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.default)
        }
    }
    
    fileprivate func refreshData() {
        video.removeAll()
        self.audioCollection = nil
    }
}

extension RTMPPlayLayer: RTMPPlaySessionDelegate {
    func sessionReceiveAudioHeader(_ session: RTMPPlaySession, audioHeader: AudioHeader) {
        self.audioCollection = AudioQueueCollection(streamDesc: audioHeader.desc, startTime: audioHeader.startTime)
        self.audioCollection?.createAudioQueue(completed: { [weak self] in
            guard let self = self else {return}
            self.audioCollection?.playQueue()
        })
    }
    
    func sessionReceiveVideoHeader(_ session: RTMPPlaySession, videoHeader: VideoHeader) {
        video.removeAll()
    }
    
    func sessionReceiveData(_ session: RTMPPlaySession, audio: AudioBuffer) {
        self.audioCollection?.append(audio: audio)
    }

    func sessionReceiveData(_ session: RTMPPlaySession, video: VideoBuffer) {
        self.video.append(video)
    }
    
    func sessionStatusChange(_ session: RTMPPlaySession, status: RTMPPlaySession.Status) {
        DispatchQueue.main.async { [weak self] in
            self?.statusCallBack?(status)
        }
    }
}


extension RTMPPlayLayer {
    fileprivate func addObserver() {
        if willResignObserver == nil {
            willResignObserver = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil, using: { [weak self] (nitification) in
                if self?.reConnectWhenForground == true {
                    self?.refreshData()
                    self?.session.invalidate(clearInfo: false)
                }
            })
        }
        
        if didBecomeActiveObserver == nil {
            didBecomeActiveObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil, using: { [weak self] (nitification) in
                if self?.reConnectWhenForground == true {
                    self?.session.socket.resume()
                }
            })
        }
    }
    
    fileprivate func removeobserver() {
        if let w = willResignObserver {
            NotificationCenter.default.removeObserver(w)
        }
        
        if let d = didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(d)
        }
        willResignObserver = nil
        didBecomeActiveObserver = nil
    }
}
