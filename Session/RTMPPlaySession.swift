//
//  RTMPPlaySession.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2018/1/8.
//  Copyright © 2018年 Millman YANG. All rights reserved.
//

import Foundation

protocol RTMPPlaySessionDelegate: class {
    func sessionReceiveVideoHeader(_ session: RTMPPlaySession, videoHeader: VideoHeader)
    func sessionReceiveAudioHeader(_ session: RTMPPlaySession, audioHeader: AudioHeader)
    func sessionReceiveData(_ session: RTMPPlaySession, video: VideoBuffer)
    func sessionReceiveData(_ session: RTMPPlaySession, audio: AudioBuffer)
    func sessionStatusChange(_ session: RTMPPlaySession,  status: RTMPPlaySession.Status)
}

extension RTMPPlaySession {    
    public enum Status {
        case unknown
        case connect
        case pause
        case playStart
        case failed(err: RTMPError)
        case disconnected
    }
}

public class RTMPPlaySession: NSObject {
    var encodeType: ObjectEncodingType = .amf0
    public var streamInfo: MetaDataResponse?
    weak var delegate: RTMPPlaySessionDelegate?
    var message: PlayMessage?
    public var socket = RTMPSocket()

    public var playStatus: Status = .unknown {
        didSet {
            delegate?.sessionStatusChange(self, status: playStatus)
        }
    }
    
    lazy var dataDecoder: DataDecoder = {
        return DataDecoder(delegate: self)
    }()
    
    public override init() {
        super.init()
        socket.delegate = self
    }
    
    public func resume() {
        self.socket.resume()
    }
    
    public func invalidate(clearInfo: Bool = true) {
        self.socket.invalidate(clearInfo: clearInfo)
        if clearInfo { self.message = nil }
        dataDecoder.reset()
        streamInfo = nil
        self.playStatus = .unknown
    }
}
// Public function
extension RTMPPlaySession {
    @discardableResult
    public func play(host: String, port: Int, name: String) -> Self {
        self.playStatus = .unknown
        socket.connect(host: host, port: port)
        message = PlayMessage(encodeType: encodeType, streamName: name, start: .onlyPlayExist)
        return self
    }
    
    @discardableResult
    public func seek(duration: Double) -> Bool {
        if self.streamInfo?.duration == 0 {
            return false
        }
        switch socket.info.connectStatus {
        case .connectd(let id):
            let seek = SeekMessage(encodeType: encodeType, msgStreamId: id, millSecond: duration*1000)
            self.socket.send(message: seek)
            return true
        default:
            return false
        }
    }
    
    @discardableResult
    public func pause(isPause: Bool) -> Bool {
        if self.streamInfo?.duration == 0 {
            return false
        }
        switch socket.info.connectStatus {
        case .connectd(let id):
            let pause = PauseMessage(encodeType: encodeType, msgStreamId: id,
                                     isPause: isPause,
                                     millSecond: dataDecoder.currentMaxTime)
            self.socket.send(message: pause)
            return true
        default:
            return false
        }
    }
}

extension RTMPPlaySession: DataDecoderDelegate {
    public func dataDecoder(_ decoder: DataDecoder, videoHeader: VideoHeader) {
        self.delegate?.sessionReceiveVideoHeader(self, videoHeader: videoHeader)
    }
    public func dataDecoder(_ decoder: DataDecoder, audio: AudioBuffer) {
        self.delegate?.sessionReceiveData(self, audio: audio)
    }
    public func dataDecoder(_ decoder: DataDecoder, video: VideoBuffer) {
        self.delegate?.sessionReceiveData(self, video: video)
    }
    public func dataDecoder(_ decoder: DataDecoder, audioHeader: AudioHeader) {
        self.delegate?.sessionReceiveAudioHeader(self, audioHeader: audioHeader)
    }
}

extension RTMPPlaySession: RTMPSocketDelegate {

    func socketError(_ socket: RTMPSocket, err: RTMPError) {
        self.playStatus = .failed(err: err)
    }
        
    func socketGetMeta(_ socket: RTMPSocket, meta: MetaDataResponse) {
        self.streamInfo = meta
        if meta.duration > 0 {
            dataDecoder.decodeType = .record(duration: meta.duration)
        } else {
            dataDecoder.decodeType = .live
        }
    }
    
    func socketPeerBandWidth(_ socket: RTMPSocket, size: UInt32) {
        self.socket.send(message: WindowAckMessage(size: size))
    }
    
    func socketPinRequest(_ socket: RTMPSocket, data: Data) {
        let message = UserControlMessage.init(type: .pingRequest, data: data)
        self.socket.send(message: message)
    }
    
    func socketHandShakeDone(_ socket: RTMPSocket) {
        guard let url = socket.info.url else {
            return
        }
        let connect = ConnectMessage(encodeType: encodeType,
                                     url: url,
                                     flashVer: flashVer,
                                     fpad: false,
                                     audio: .aac,
                                     video: .h264)
        self.socket.info.register(message: connect)
        self.socket.send(message: connect)
    }
    
    func socketConnectDone(_ socket: RTMPSocket, obj: ConnectResponse) {
        let message = CreateStreamMessage(encodeType: encodeType, transactionId: self.socket.info.shiftTransactionId())
        self.socket.info.register(message: message)
        self.socket.send(message: message)
    }
    
    func socketCreateStreamDone(_ socket: RTMPSocket, obj: StreamResponse) {
        guard let m = self.message else {
            return
        }
        m.msgStreamId = obj.streamId
        self.socket.send(message: m)
        self.playStatus = .connect
    }

    public func socketStreamOutputVideo(_ socket: RTMPSocket, data: Data, timeStamp: Int64, isFirst: Bool) {
        dataDecoder.append(video: data, timeStamp: timeStamp, isFirst: isFirst)
    }
    
    public func socketStreamOutputAudio(_ socket: RTMPSocket, data: Data, timeStamp: Int64, isFirst: Bool) {
        dataDecoder.append(audio: data, timeStamp: timeStamp, isFirst: isFirst)
    }
    
    public func socketDisconnected(_ socket: RTMPSocket) {
        self.playStatus = .disconnected
    }
        
    public func socketStreamPause(_ socket: RTMPSocket, pause: Bool) {
        if pause {
            self.playStatus = .pause
        }
    }
    
    public func socketStreamPlayStart(_ socket: RTMPSocket) {
        self.playStatus = .playStart
    }
}
