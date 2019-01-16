//
//  AudioQueueCollection.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/11.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation
import AudioToolbox
import AVFoundation
public class AudioQueueCollection {
    public var timeStamp: CMTime {
        get {
            if let o = self.outputQueue {
                var stamp = AudioTimeStamp()
                AudioQueueGetCurrentTime(o, nil, &stamp, nil)
                let time = CMTimeMake(value: Int64(stamp.mSampleTime), timescale: Int32(streamDesc.mSampleRate))
                let second = CMTimeMakeWithSeconds(Float64(self.startTime/1000), preferredTimescale: 1000)
                return time+second
            }
            return CMTime.zero
        }
    }
    
    private var start = false
    public var bufferSize: UInt32
    public var outputQueue: AudioQueueRef?
    public var audioQueue = DispatchQueue(label: "mmRtmp.audioQueue")
    public let startTime: Int64
    public var streamDesc: AudioStreamBasicDescription
    var bufferCount: Int = 0
    var outputCallBack: AudioQueueOutputCallback = { (inUserData, inAQ: AudioQueueRef, inBuffer: AudioQueueBufferRef) in
        let collect: AudioQueueCollection = unsafeBitCast(inUserData, to: AudioQueueCollection.self)
        collect.outputCallBack(inAQ, buffer: inBuffer)
    }
    
     public init (streamDesc: AudioStreamBasicDescription,
                  bufferSize: UInt32 = 1024 * 1,
                  startTime: Int64 = 0) {
        self.streamDesc = streamDesc
        self.bufferSize = bufferSize
        self.startTime = startTime
    }

    public func createAudioQueue(completed: @escaping (()->Void)) {
        audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            AudioQueueNewOutput(&self.streamDesc,
                                self.outputCallBack,
                                unsafeBitCast(self, to: UnsafeMutableRawPointer.self),
                                nil,
                                nil,
                                0,
                                &self.outputQueue)
            completed()
        }
    }
    
    fileprivate var audioDataBuffer = (data: Data(), desc: [AudioStreamPacketDescription]())
    
    func append(audio: AudioBuffer) {
        audioQueue.async { [weak self] in
            guard let self = self else {return}
            var copy = audio.desc
            copy.mStartOffset = Int64(self.audioDataBuffer.data.count)
            self.audioDataBuffer.desc.append(copy)
            self.audioDataBuffer.data.append(audio.data)
            if self.audioDataBuffer.data.count >= self.bufferSize, self.outputQueue != nil {
                self.enQueue(data: self.audioDataBuffer.data, desc: self.audioDataBuffer.desc)
                self.audioDataBuffer.data.removeAll()
                self.audioDataBuffer.desc.removeAll()
            }
        }
    }
    public func enQueue(data: Data, desc: [AudioStreamPacketDescription])  {

        guard let queueRef = self.outputQueue else { return }
        var buffer: AudioQueueBufferRef?
        let size = data.count
        let create = AudioQueueAllocateBuffer(queueRef, UInt32(size), &buffer)
        guard let b = buffer, create == noErr else {
            buffer = nil
            return
        }
        var desc = desc
        let rawPtr = data.withUnsafeBytes({ UnsafeRawPointer($0) })
        memcpy(b.pointee.mAudioData, rawPtr, size)
        b.pointee.mAudioDataByteSize = UInt32(size)
        AudioQueueEnqueueBuffer(queueRef, b, UInt32(desc.count), &desc)
        bufferCount += 1
    }
    
    public func playQueue() {
        guard let q = self.outputQueue, !self.start else {
            return
        }
        self.start = true
        AudioQueuePrime(q, 0, nil)
        AudioQueueStart(q, nil)
    }
    
    public func pause() {
        guard let q = self.outputQueue else {
            return
        }
        self.start = false
        AudioQueuePause(q)
    }

    
    public func stop() {
        guard let q = self.outputQueue else {
            return
        }
        self.start = false
        AudioQueueStop(q, true)
    }
    
    private func outputCallBack(_ inAQ: AudioQueueRef, buffer: AudioQueueBufferRef) {

        //        AudioQueueFreeBuffer(inAQ, buffer)
        audioQueue.async { [weak self] in
            self?.bufferCount -= 1
        }
    }
    
    deinit {
        self.stop()
        AudioQueueDispose(self.outputQueue!, true)
    }
}
