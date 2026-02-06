//
//  FSSafeValue.swift
//  FSKit
//
//  Created by pwrd on 2026/2/6.
//

import Foundation

open class FSSafe {
    
    public static func bool(_ value: Any?) -> Bool {
        switch value {
        case let t as TimeInterval:
            return Int(t) != 0

        case let i as Int:
            return i != 0

        case let i as Int64:
            return i != 0

        case let d as Double:
            return Int(d) != 0

        case let n as NSNumber:
            return n.boolValue

        case let s as String:
            return Bool(s) ?? false

        default:
            return false
        }
    }
    
    public static func float(_ value: Any?) -> Float {
        switch value {
        case let t as TimeInterval:
            return Float(t)

        case let i as Int:
            return Float(i)

        case let i as Int64:
            return Float(i)

        case let d as Double:
            return Float(d)

        case let n as NSNumber:
            return n.floatValue

        case let s as String:
            return Float(s) ?? 0

        default:
            return 0
        }
    }
    
    public static func int(_ value: Any?) -> Int {
        switch value {
        case let t as TimeInterval:
            return Int(t)

        case let i as Int:
            return i

        case let i as Int64:
            return Int(i)

        case let d as Double:
            return Int(d)

        case let n as NSNumber:
            return n.intValue

        case let s as String:
            return Int(s) ?? 0

        default:
            return 0
        }
    }
    
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
    
    public static func dictionary(_ value: Any?) -> [String: Any] {
        if let nsDict = value as? NSDictionary {
             return nsDict as! [String: Any]
         } else if let swiftDict = value as? [String: Any] {
             return swiftDict
         } else {
             return [:]
         }
    }
    
    public static func array(_ value: Any?) -> [Any] {
        if let swiftArray = value as? [Any] {
            return swiftArray
        } else if let nsArray = value as? NSArray {
            return nsArray.map { $0 as Any }
        } else {
            return []
        }
    }

}
