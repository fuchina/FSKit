//
//  FSSafeValue.swift
//  FSKit
//
//  Created by pwrd on 2026/2/6.
//

import Foundation

open class FSSafe {
    
    public static func double(_ value: Any?) -> Double {
        switch value {
        case let t as TimeInterval:
            return t

        case let i as Int:
            return TimeInterval(i)

        case let i as Int64:
            return TimeInterval(i)

        case let d as Double:
            return d

        case let n as NSNumber:
            return n.doubleValue

        case let s as String:
            return Double(s) ?? 0

        default:
            return 0
        }
    }
    
}
