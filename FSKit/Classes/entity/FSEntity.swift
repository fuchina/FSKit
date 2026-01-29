//
//  FSEntity.swift
//  FSKit
//
//  Created by Dongdong Fu on 2026/1/25.
//

import Foundation

open class FSEntitySwift {
    public var     aid      :   Int = 0
    public var     meta     :   Dictionary<String, Any>? = nil
    
    required public init() {}
    
       /// 子类 override：定义 key -> setter 映射
    class open func keyMapper() -> [String: (FSEntitySwift, Any) -> Void] {
        
        let mapper = Dictionary(uniqueKeysWithValues: [

            FSEntitySwift.map("aid") { (obj: FSEntitySwift, v: Int) in
                obj.aid = v
            },
        ])
        
        return mapper
        
//        return [:]
    }

    /// 从 dictionary 映射
    func fill(from dict: [String: Any]) {
        self.meta = dict
        
        let mapper = type(of: self).keyMapper()
        for (key, value) in dict {
            mapper[key]?(self, value)
        }
        
        self.afterSetProperties()
    }
    
    open func afterSetProperties() {}
    
    /// 单个
    static public func tom<T: FSEntitySwift>(from dict: [String: Any]) -> T {
        let model = T.init()
        model.fill(from: dict)
        return model
    }

    /// 批量
    static public func toms<T: FSEntitySwift>(from dictionaries: [[String: Any]]) -> [T] {
        dictionaries.map {
            let model = T.init()
            model.fill(from: $0)
            return model
        }
    }
    
    public static func map<T: FSEntitySwift, V>(
           _ key: String,
           _ setter: @escaping (T, V) -> Void
       ) -> (String, (FSEntitySwift, Any) -> Void) {

           return (
               key,
               { obj, value in
                   
                   guard
                       let obj = obj as? T,
                       let v = value as? V
                   else { return }
                   
                   setter(obj, v)
               }
           )
       }
}


