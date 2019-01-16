//
//  RTMPResponseDefine.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/21.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation

enum CodeType {
    enum Call: String {
        case badVersion = "NetConnection.Call.BadVersion"
        case failed     = "NetConnection.Call.Failed"
    }
    
    enum Connect: String, Decodable {
        case failed         = "NetConnection.Connect.Failed"
        case timeout        = "NetConnection.Connect.IdleTimeOut"
        case invalidApp     = "NetConnection.Connect.InvalidApp"
        case networkChange  = "NetConnection.Connect.NetworkChange"
        case reject         = "NetConnection.Connect.Rejected"
        case success        = "NetConnection.Connect.Success"
    }
}


