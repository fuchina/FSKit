//
//  FSEntity.swift
//  FSKit
//
//  Created by Dongdong Fu on 2026/1/25.
//

import Foundation

open class FSEntity: NSObject {
    public var     aid      :   Int = 0
    public var     meta     :   Dictionary<String, Any>? = nil
    
    required public override init() {}
    
       /// 子类 override：定义 key -> setter 映射
    class open func keyMapper() -> [String: (FSEntity, Any) -> Void] {
        
        let mapper = Dictionary(uniqueKeysWithValues: [

            FSEntity.map("aid") { (obj: FSEntity, v: Int) in
                obj.aid = v
            },
        ])
        
        return mapper
        
//        return [:]
    }

    /// 从 dictionary 映射
    public func fill(from dict: [String: Any]) {
        self.fill(from: dict, before: nil, after: nil)
    }
    
    public func fill(from dict: [String: Any], before:(()-> Void)?, after:(()->Void)?) {
        self.meta = dict
        
        self.beforeSetProperties()
        
        if before != nil {
            before!()
        }
        
        let mapper = type(of: self).keyMapper()
        for (key, value) in dict {
            mapper[key]?(self, value)
        }
        
        self.afterSetProperties()
        
        if after != nil {
            after!()
        }
    }
    
    open func beforeSetProperties() {}
    open func afterSetProperties() {}
    
    /// 单个
    static public func tom<T: FSEntity>(from dict: [String: Any]) -> T {
        let model = T.init()
        model.fill(from: dict)
        return model
    }

    /// 批量
    static public func toms<T: FSEntity>(from dictionaries: [[String: Any]]) -> [T] {
        dictionaries.map {
            let model = T.init()
            model.fill(from: $0)
            return model
        }
    }
    
    /// 批量
    static public func toms<T: FSEntity>(from dictionaries: [[String: Any]], before: (() -> Void)?, after: (() -> Void)?) -> [T] {
        dictionaries.map {
            let model = T.init()
            model.fill(from: $0)
            return model
        }
    }
        
    // 原泛型map方法 + 兼容类型转换扩展（核心修改：新增value转换逻辑）
        public static func map<T: FSEntity, V>(
            _ key: String,
            _ setter: @escaping (T, V) -> Void
        ) -> (String, (FSEntity, Any) -> Void) {
            
            return (
                key,
                { obj, rawValue in
                    guard let model = obj as? T else { return }
                    
                    guard let targetValue = Self.convertValue(rawValue, to: V.self) else {
                        print("FSLog 字段\(key)类型不匹配，原始值：\(rawValue)，目标类型：\(V.self)，已跳过解析")
                        return
                    }
                    
                    setter(model, targetValue)
                }
            )
        }
        
        private static func convertValue<V>(_ value: Any, to targetType: V.Type) -> V? {
            if let matchedValue = value as? V {
                return matchedValue
            }
            
            switch targetType {

            case is Int.Type:
                return convertToInt(value) as? V
            case is Double.Type:
                return convertToDouble(value) as? V
            case is String.Type:
                return convertToString(value) as? V
            case is Bool.Type:
                return convertToBool(value) as? V
            default:
                return nil
            }
        }
        
        private static func convertToInt(_ value: Any) -> Int? {
            switch value {
            case let num as NSNumber: return num.intValue
            case let d as Double: return Int(d)
            case let s as String: return Int(s)
            default: return nil
            }
        }
        
        private static func convertToDouble(_ value: Any) -> Double? {
            switch value {
            case let num as NSNumber: return num.doubleValue
            case let i as Int: return Double(i)
            case let s as String: return Double(s)
            default: return nil
            }
        }
        
        private static func convertToString(_ value: Any) -> String? {
            switch value {
            case let s as String: return s
            case let num as NSNumber: return num.stringValue
            case let i as Int: return "\(i)"
            case let d as Double: return "\(d)"
            case let b as Bool: return b ? "true" : "false"
            default: return nil
            }
        }
        
        private static func convertToBool(_ value: Any) -> Bool? {
            switch value {
            case let b as Bool: return b
            case let num as NSNumber: return num.boolValue
            case let i as Int: return i != 0
            case let s as String:
                let lowerS = s.lowercased()
                return lowerS == "true" || lowerS == "1"
            default: return nil
            }
        }
}


