//
//  RTMP+AnyObject+DecodeObject.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/11/21.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation

extension Dictionary {
    
    func decodeObject<T: Decodable>() -> T? {
        if let data = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted),
           let obj = try? JSONDecoder().decode(T.self, from: data) {
            return obj
        }
        return nil
    }
}
