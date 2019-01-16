//
//  AMF3ReferenceTable.swift
//  RtmpSwift
//
//  Created by Millman YANG on 2017/12/19.
//  Copyright © 2017年 Millman YANG. All rights reserved.
//

import Foundation

//Note that 3 separate reference tables are used for Strings, Complex Objects and Object Traits respectively.
public class AMF3ReferenceTable {
    private(set) lazy var string = {
       return [String]()
    }()
    private(set) lazy var objects = {
        return [Any]()
    }()
}

extension AMF3ReferenceTable {
    func append(_ value: String) {
        self.string.append(value)
    }
    
    func string(index: Int) -> String {
        return self.string[index]
    }
}

extension AMF3ReferenceTable {
    func createReserved() -> Int {
        self.objects.append([Any]())
        return self.objects.count-1
    }
    
    func replace(_ value: Any, idx: Int) {
        self.objects[idx] = value
    }
    
    func append(_ value: Any) {
        self.objects.append(value)
    }
    
    func object<T>(_ index: Int) -> T? {
        return self.objects[index] as? T
    }
}

