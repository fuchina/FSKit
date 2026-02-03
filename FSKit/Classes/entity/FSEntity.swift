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
        self.meta = dict
        
        let mapper = type(of: self).keyMapper()
        for (key, value) in dict {
            mapper[key]?(self, value)
        }
        
        self.afterSetProperties()
    }
    
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
    
//    public static func map<T: FSEntitySwift, V>(
//           _ key: String,
//           _ setter: @escaping (T, V) -> Void
//       ) -> (String, (FSEntitySwift, Any) -> Void) {
//
//           return (
//               key,
//               { obj, value in
//                   
//                   guard
//                       let obj = obj as? T,
//                       let v = value as? V
//                   else { return }
//                   
//                   setter(obj, v)
//               }
//           )
//       }
    
    // 原泛型map方法 + 兼容类型转换扩展（核心修改：新增value转换逻辑）
        public static func map<T: FSEntity, V>(
            _ key: String,
            _ setter: @escaping (T, V) -> Void
        ) -> (String, (FSEntity, Any) -> Void) {
            
            return (
                key,
                { obj, rawValue in
                    // 1. 先校验模型类型：非指定T类型直接返回
                    guard let model = obj as? T else { return }
                    
                    // 2. 尝试将原始值转换为目标类型V（新增核心：兼容类型转换）
                    guard let targetValue = Self.convertValue(rawValue, to: V.self) else {
                        // 转换失败（无兼容类型），才返回不解析
                        print("FSLog 字段\(key)类型不匹配，原始值：\(rawValue)，目标类型：\(V.self)，已跳过解析")
                        return
                    }
                    
                    // 3. 类型匹配/转换成功，执行赋值
                    setter(model, targetValue)
                }
            )
        }
        
        // 新增：通用类型兼容转换方法（支持常见类型的隐式转换，可按需扩展）
        private static func convertValue<V>(_ value: Any, to targetType: V.Type) -> V? {
            // 若类型已匹配，直接返回（保留原严格校验的高效性）
            if let matchedValue = value as? V {
                return matchedValue
            }
            
            // 按目标类型，处理各种兼容转换场景（可根据业务需求无限扩展）
            switch targetType {
            // 目标类型：Int（支持String/NSNumber/Double → Int）
            case is Int.Type:
                return convertToInt(value) as? V
            // 目标类型：Double（支持String/NSNumber/Int → Double）
            case is Double.Type:
                return convertToDouble(value) as? V
            // 目标类型：String（支持NSNumber/Int/Double/Bool → String）
            case is String.Type:
                return convertToString(value) as? V
            // 目标类型：Bool（支持String/NSNumber/Int → Bool）
            case is Bool.Type:
                return convertToBool(value) as? V
            // 其他未扩展类型：返回nil（保持原逻辑，不解析）
            default:
                return nil
            }
        }
        
        // 子方法1：转换为Int（支持多源类型）
        private static func convertToInt(_ value: Any) -> Int? {
            switch value {
            case let num as NSNumber: return num.intValue
            case let d as Double: return Int(d)
            case let s as String: return Int(s)
            default: return nil
            }
        }
        
        // 子方法2：转换为Double（支持多源类型）
        private static func convertToDouble(_ value: Any) -> Double? {
            switch value {
            case let num as NSNumber: return num.doubleValue
            case let i as Int: return Double(i)
            case let s as String: return Double(s)
            default: return nil
            }
        }
        
        // 子方法3：转换为String（支持多源类型）
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
        
        // 子方法4：转换为Bool（支持多源类型，适配常见业务规则）
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


