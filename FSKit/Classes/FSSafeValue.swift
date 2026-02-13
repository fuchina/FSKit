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
            
            if s == "1" {
                return true
            }
            return false
            
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
            let d = Double(s) ?? 0
            return Int(d)
        
        case let f as Float:
            return Int(f)
            
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
    
    public static func string(_ value: Any?) -> String {
        if let str = value as? String {
            return str
        } else if let str = value as? NSString {
            return str as String
        }
        return ""
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
    
    // MARK: - 便捷重载：常用类型的快速转换（可选，简化调用）
    // 快速转为 String 数组
    public static func stringArray(_ value: Any?) -> [String] {
        return Self.convertToArray(from: value) { element in
            return self.string(element)
        }
    }
    
    /// 快速转为 Int 数组
    public static func intArray(_ value: Any?) -> [Int] {
        return convertToArray(from: value) { element in
            return self.int(element)
        }
    }
    
    
    // 通用数组转换工厂类
    /// - Parameters:
    ///   - value: 任意类型的输入值（可能是数组、NSArray、nil、其他类型）
    ///   - transform: 元素转换闭包，将任意类型元素转为目标类型 T；转换失败返回 nil
    /// - Returns: 目标类型 T 的数组，非数组/转换失败的元素会被过滤，最终返回空数组或有效元素数组
    static func convertToArray<T>(from value: Any?, transform: (Any) -> T?) -> [T] {
        let rawArray: [Any] = {
            guard let value = value else { return [] } // 处理 nil
            if let swiftArray = value as? [Any] {
                return swiftArray // Swift 原生数组
            } else if let nsArray = value as? NSArray {
                return nsArray.map { $0 as Any } // OC 数组转 Swift 数组
            } else {
                return [] // 非数组类型，返回空数组
            }
        }()
        
        // 步骤2：遍历数组，用转换闭包将元素转为 T 类型，过滤转换失败的元素
        var resultArray = [T]()
        for element in rawArray {
            if let convertedElement = transform(element) {
                resultArray.append(convertedElement)
            } else {
                // 可选：打印转换失败的日志，方便调试
                print("ArrayFactory: 元素 \(element) (类型: \(type(of: element))) 无法转为 \(T.self) 类型")
            }
        }
        
        return resultArray
    }
    
}
