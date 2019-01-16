//
//  RTMPPublishSession.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2018/1/8.
//  Copyright © 2018年 Millman YANG. All rights reserved.
//

import Foundation
import AVFoundation
public protocol RTMPPublishSessionDelegate: class {
    func sessionMetaData(_ session: RTMPPublishSession) -> [String: Any]
    func sessionStatusChange(_ session: RTMPPublishSession,  status: RTMPPublishSession.Status)
}

extension RTMPPublishSession {
    public enum Status {
        case unknown
        case connect
        case publishStart
        case failed(err: RTMPError)
        case disconnected
    }
}
public class RTMPPublishSession: NSObject {
    public weak var delegate: RTMPPublishSessionDelegate?
    public var encodeType: ObjectEncodingType = .amf0

    var message: PublishMessage?
    public var socket = RTMPSocket()

    var timestamp: TimeInterval?
    var h264: H264Encoder?
    var audio: AudioEncoder?
    public override init() {
        super.init()
        socket.delegate = self
    }

    public var publishStatus: Status = .unknown {
        didSet {
            delegate?.sessionStatusChange(self, status: publishStatus)
        }
    }
    
}

extension RTMPPublishSession {
    @discardableResult
    public func publishStream(host: String,
                              port: Int,
                              name: String,
                              type: PubishType =  PubishType.live) -> Self {
        socket.connect(host: host, port: port)
        
        self.h264 = H264Encoder(delegate: self)
        self.audio = AudioEncoder(delegate: self)
        self.publishStatus = .unknown
        message = PublishMessage(encodeType: encodeType, streamName: name, type: type)
        return self
    }
    
    public func setVideoSizeIfNeed(_ size: CGSize) {
        self.h264?.frameSize = size
    }
    
    public func resume() {
        self.socket.resume()
    }
    
    public func publishVideo(buffer: CMSampleBuffer) {
        h264?.encode(buffer: buffer)
    }
    
    public func publishAudio(buffer: CMSampleBuffer) {
        audio?.encode(buffer: buffer)
    }
    
    public func invalidate() {
        self.socket.invalidate()
        self.message = nil
        self.publishStatus = .unknown
        h264 = nil
        audio = nil
    }
}

extension RTMPPublishSession: RTMPSocketDelegate {
    func socketError(_ socket: RTMPSocket, err: RTMPError) {
        self.publishStatus = .failed(err: err)
    }
    
    func socketGetMeta(_ socket: RTMPSocket, meta: MetaDataResponse) {
//        self.streamInfo = meta
    }
    func socketPinRequest(_ socket: RTMPSocket, data: Data) {
        let message = UserControlMessage(type: .pingRequest, data: data)
        self.socket.send(message: message)
    }
    
    func socketPeerBandWidth(_ socket: RTMPSocket, size: UInt32) {
        self.socket.send(message: WindowAckMessage(size: size))
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
        
        let size = ChunkSizeMessage(size: chunkSize)
        socket.send(message: size)
    }
    
    func socketCreateStreamDone(_ socket: RTMPSocket, obj: StreamResponse) {
        guard let m = self.message else {
            return
        }
        m.msgStreamId = obj.streamId
        self.socket.send(message: m)
        self.publishStatus = .connect
    }

    public func socketDisconnected(_ socket: RTMPSocket) {
        self.publishStatus = .disconnected
    }
}

extension RTMPPublishSession {
    public func socketStreamPublishStart(_ socket: RTMPSocket) {
        if let meta = self.delegate?.sessionMetaData(self) {
            let m = MetaMessage(encodeType: encodeType, msgStreamId: socket.info.connectStatus.connectId, meta: meta)
            self.socket.send(message: m)
        }
        h264?.isStartEncode = true
        audio?.isStartEncode = true
    }
}

extension RTMPPublishSession: H264EncoderDelegate {
    public func output(encoder: H264Encoder, data: Data, delta: TimeInterval) {
        let message = VideoMessage(msgStreamId: socket.info.connectStatus.connectId, data: data, timestamp: delta)
        socket.send(message: message, firstType: false)
    }

    public func outputHeader(encoder: H264Encoder, data: Data, time: TimeInterval) {
        let message = VideoMessage(msgStreamId: socket.info.connectStatus.connectId, data: data, timestamp: time)
        socket.send(message: message)
    }
}

extension RTMPPublishSession: AudioEncoderDelegate {
    func output(encoder: AudioEncoder, data: Data, delta: TimeInterval) {
        let message = AudioMessage(msgStreamId: socket.info.connectStatus.connectId, data: data, timestamp: delta)
        socket.send(message: message, firstType: false)
    }
    
    func outputHeader(encoder: AudioEncoder, data: Data) {
        let message = AudioMessage(msgStreamId: socket.info.connectStatus.connectId, data: data, timestamp: 0)
        socket.send(message: message)
    }
}
