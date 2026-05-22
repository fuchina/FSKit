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
    
    public func fill<T: FSEntity>(from dict: [String: Any], before:((T)-> Void)?, after:((T)->Void)?) {
        
        guard let typedSelf = self as? T else {
            assertionFailure("Type mismatch: self is not \(T.self)")
            return
        }
        
        self.meta = dict
        
        self.beforeSetProperties()
        
        if before != nil {
            before!(typedSelf)
        }
        
        let mapper = type(of: self).keyMapper()
        for (key, value) in dict {
            mapper[key]?(self, value)
        }
        
        self.afterSetProperties()
        
        if after != nil {
            after!(typedSelf)
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
        self.toms(from: dictionaries, before: nil, after: nil)
    }
    
    /// 批量
    static public func toms<T: FSEntity>(from dictionaries: [[String: Any]], before: ((T) -> Void)?, after: ((T) -> Void)?) -> [T] {
        if dictionaries.count == 0 {
            return []
        }

        return dictionaries.map {
            let model = T.init()
            model.fill(from: $0, before: before, after: after)
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
                return FSSafe.int(value) as? V
            case is Double.Type:
                return FSSafe.double(value) as? V
            case is String.Type:
                return FSSafe.string(value) as? V
            case is Bool.Type:
                return FSSafe.bool(value) as? V
            default:
                return nil
            }
        }
}


