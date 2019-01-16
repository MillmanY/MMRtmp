//
//  MMRTMPSocket.swift
//  FLVTest
//
//  Created by Millman YANG on 2017/11/13.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

@objc public protocol RTMPSocketOptinalDelegate {
    @objc optional func socketStreamOutputAudio(_ socket: RTMPSocket, data: Data, timeStamp: Int64, isFirst: Bool)
    @objc optional func socketStreamOutputVideo(_ socket: RTMPSocket, data: Data, timeStamp: Int64, isFirst: Bool)
    @objc optional func socketStreamPublishStart(_ socket: RTMPSocket)
    @objc optional func socketStreamRecord(_ socket: RTMPSocket)
    @objc optional func socketStreamPlayStart(_ socket: RTMPSocket)
    @objc optional func socketStreamPause(_ socket: RTMPSocket, pause: Bool)
}

protocol RTMPSocketDelegate: RTMPSocketOptinalDelegate {
    func socketHandShakeDone(_ socket: RTMPSocket)
    func socketPinRequest(_ socket: RTMPSocket, data: Data)
    func socketConnectDone(_ socket: RTMPSocket, obj: ConnectResponse)
    func socketCreateStreamDone(_ socket: RTMPSocket, obj: StreamResponse)
    func socketError(_ socket: RTMPSocket, err: RTMPError)
    func socketGetMeta(_ socket: RTMPSocket, meta: MetaDataResponse)
    func socketPeerBandWidth(_ socket: RTMPSocket, size: UInt32)
    func socketDisconnected(_ socket: RTMPSocket)
}

public class RTMPSocket: RTMPBaseNetSocket {
    public var info = RTMPConnectInfo()
    private var decoder = ChunkDecoder()
    private var encoder = ChunkEncoder()
    weak var delegate: RTMPSocketDelegate?

    private lazy var handshake: RTMPHandshake = {
        return RTMPHandshake(statusChange: { [unowned self] (status) in
            switch status {
            case .uninitalized:
                self.send(self.handshake.c0c1Packet)
            case .verSent:
                self.send(self.handshake.c2Packet)
            case .ackSent, .none:
                break
            case .handshakeDone:
                guard let i = self.info.url else {
                    self.invalidate()
                    return
                }
                self.delegate?.socketHandShakeDone(self)
            }
        })
    }()
    
    override public func setParameter() {
        info.set(status: .open)
        super.setParameter()
        info.set(status: .none)
    }
    
    override public func clearParameter() {
        self.delegate?.socketDisconnected(self)
        info.set(status: .closed)
        super.clearParameter()
    }
    
    private func inputHandle() {
        
        guard let i = super.input, let b = super.buffer else {
            return
        }
        let length = i.read(b, maxLength: RTMPBaseNetSocket.maxReadSize)
        if length > 0 {
            if self.handshake.status == .handshakeDone {
                inputData.append(b, count: length)
                let bytes:Data = self.inputData
                inputData.removeAll()
                self.decode(data: bytes)
            } else {
                handshake.data.append(Data(bytes: b, count: length))
            }
        }
    }
    func send(message: RTMPBaseMessageProtocol & ChunkEncoderTypeProtocol, firstType: Bool = true) {
        switch message {
        case let m as ChunkSizeMessage:
            encoder.chunkSize = m.size
        default:
            break
        }
        self.sendChunk(encoder.chunk(message: message, isFirstType0: firstType))        
    }
}

extension RTMPSocket {
    @discardableResult
    public func connect(host: String, port: Int) -> Self {
        guard let url = URL(string: host), let h = url.host else {
            return self
        }
        info.set(url: url, host: h, port: port)
        return self
    }
    
    public func resume() {
        switch info.connectStatus {
        case .connectd(_), .open:
            return
        default: break
        }
        guard let h = self.info.url?.host else {
            return
        }
        inputQueue.async { [unowned self] in
            Stream.getStreamsToHost(withName: h,
                                    port: self.info.port,
                                    inputStream: &self.input,
                                    outputStream: &self.output)
            self.setParameter()
        }
    }
    
    public func invalidate(clearInfo: Bool = true) {
        switch info.connectStatus {
        case .none , .closed:
            return
        default: break
        }
        self.clearParameter()
        handshake.reset()
        decoder.reset()
        encoder.reset()
        info.reset(clearInfo)
    }        
}

extension RTMPSocket: StreamDelegate {
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.openCompleted:
            if input?.streamStatus == .open && output?.streamStatus == .open,
               input == aStream{
                self.handshake.startHandShake()
            }
        case Stream.Event.hasBytesAvailable:
            if aStream == input {
                self.inputHandle()
            }
        case Stream.Event.hasSpaceAvailable:
            break
        case Stream.Event.errorOccurred:
            if let e = aStream.streamError {
                self.delegate?.socketError(self, err: .uknown(desc: e.localizedDescription))
            }
            self.invalidate()
        case Stream.Event.endEncountered:
            self.invalidate()
        default: break
        }
    }
}

extension RTMPSocket {
    fileprivate func decode(data: Data) {
        self.decoder.decode(data: data) { [unowned self] (header) in
            switch header.messageHeader {
            case let c as MessageHeaderType0:
                self.chunk(header0: c, chunk: header)
            case let c as MessageHeaderType1:
                self.chunk(header1: c, chunk: header)
            default:
                break
            }
        }
    }
    
    fileprivate func chunk(header0: MessageHeaderType0, chunk: RTMPChunkHeader) {
        switch header0.type {
        case .control:
            let response: ControlResponse = ControlResponse(decode: chunk.chunkPayload)
            switch response.eventType {
            case .pingRequest:
                self.delegate?.socketPinRequest(self, data: response.data)
            case .streamIsRecorded:
                self.delegate?.socketStreamRecord?(self)
            default:
                break
            }
        case .chunkSize:
            let chunkSize = Data(chunk.chunkPayload.reversed()).uint32
            decoder.chunkSize = chunkSize
        case .peerBandwidth:
            guard let windowAckSize = chunk.chunkPayload[safe: 0..<4]?.reversed() else {
                return
            }
            let peer = Data(windowAckSize).uint32
            self.delegate?.socketPeerBandWidth(self, size: peer)
        case .command(let type) , .data(let type), .share(let type):
            let data = type == .amf0 ? chunk.chunkPayload.decodeAMF0() : chunk.chunkPayload.decodeAMF3()
            self.convert(pay: data)
        case .video:
            self.delegate?.socketStreamOutputVideo?(self, data: chunk.chunkPayload, timeStamp: Int64(header0.timestamp), isFirst: true)
        case .audio:
            self.delegate?.socketStreamOutputAudio?(self, data: chunk.chunkPayload, timeStamp: Int64(header0.timestamp), isFirst: true)
        default:
            break
        }
    }
    
    fileprivate func chunk(header1: MessageHeaderType1, chunk: RTMPChunkHeader) {
        switch header1.type {
        case .video:
            delegate?.socketStreamOutputVideo?(self, data: chunk.chunkPayload, timeStamp: Int64(header1.timestampDelta), isFirst: false)
        case .audio:
            delegate?.socketStreamOutputAudio?(self, data: chunk.chunkPayload, timeStamp: Int64(header1.timestampDelta), isFirst: false)
        case .command(let type) , .data(let type), .share(let type):
            let data = type == .amf0 ? chunk.chunkPayload.decodeAMF0() : chunk.chunkPayload.decodeAMF3()
            self.convert(pay: data)
        default:
            break
        }
    }
    
    fileprivate func convert(pay: [Any]?) {
        if let first = pay?.first as? String, first == "onMetaData",
            let second = pay?[safe: 1] as? [String: Any],
            let meta: MetaDataResponse = second.decodeObject() {
            self.delegate?.socketGetMeta(self, meta: meta)
        } else if let p = pay, let id = p[safe: 1] as? NSNumber,
            let message = info.removeMessage(id: Int(truncating: id)) {
            switch message {
            case _ as ConnectMessage:
                let obj = ConnectResponse(decode: pay)
                switch obj.info?.code {
                case .success?:
                    self.delegate?.socketConnectDone(self, obj: obj)
                default:
                    self.delegate?.socketError(self, err: .command(desc: obj.info?.code.rawValue ?? "Connect error"))
                }
            case _ as CreateStreamMessage:
                let response: StreamResponse = StreamResponse(decode: p)
                info.set(status: .connectd(id: response.streamId))
                self.delegate?.socketCreateStreamDone(self, obj: response)
            default: break
            }
        } else if let first = pay?.first as? String, first == "onStatus" {
            guard let p = pay?.last as? [String: Any] else {
                return
            }
            if let response: StatusResponse = p.decodeObject() {
                if response.level == .error {
                    self.delegate?.socketError(self, err: .command(desc: response.description))
                    return
                }
                switch response.code {
                case .publishStart:
                    self.delegate?.socketStreamPublishStart?(self)
                case .playStart:
                    self.delegate?.socketStreamPlayStart?(self)
                case .pauseNotify:
                    self.delegate?.socketStreamPause?(self, pause: true)
                case .unpauseNotify:
                    self.delegate?.socketStreamPause?(self, pause: false)
                default:
                    break
                }
            }
        }
    }
}
