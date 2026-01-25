//
//  DictionaryEntity.swift
//  ModuleOxfordUtils
//
//  Created by pwrd on 2026/1/23.
//  纯 Swift 方案：使用字典存储，不需要定义所有属性
//

import Foundation
import UIKit

// MARK: - 基于字典的纯 Swift 基类
class DictionaryEntity {
    // 使用字典存储所有数据
    private var storage: [String: Any] = [:]
    
    // 基础属性
    var aid: Int {
        get { storage["aid"] as? Int ?? 0 }
        set { storage["aid"] = newValue }
    }
    
    var valid: Bool {
        get { storage["valid"] as? Bool ?? true }
        set { storage["valid"] = newValue }
    }
    
    var insets: UIEdgeInsets {
        get { storage["insets"] as? UIEdgeInsets ?? .zero }
        set { storage["insets"] = newValue }
    }
    
    var meta: [String: Any]? {
        return storage
    }
    
    required init() {}
    
    required init(dictionary: [String: Any]) {
        self.storage = dictionary
        self.beforeSetProperties()
        self.afterSetProperties()
    }
    
    // MARK: - 生命周期钩子
    func beforeSetProperties() {
        // 子类重写
    }
    
    func afterSetProperties() {
        // 子类重写
    }
    
    // MARK: - 下标访问
    subscript(key: String) -> Any? {
        get { storage[key] }
        set { storage[key] = newValue }
    }
    
    // MARK: - 类型安全的访问方法
    func string(forKey key: String) -> String? {
        if let value = storage[key] {
            if let str = value as? String {
                return str
            } else if let num = value as? NSNumber {
                return num.stringValue
            } else if let num = value as? Int {
                return String(num)
            } else if let num = value as? Double {
                return String(num)
            }
        }
        return nil
    }
    
    func int(forKey key: String) -> Int? {
        if let value = storage[key] {
            if let num = value as? Int {
                return num
            } else if let str = value as? String {
                return Int(str)
            } else if let num = value as? NSNumber {
                return num.intValue
            }
        }
        return nil
    }
    
    func double(forKey key: String) -> Double? {
        if let value = storage[key] {
            if let num = value as? Double {
                return num
            } else if let str = value as? String {
                return Double(str)
            } else if let num = value as? NSNumber {
                return num.doubleValue
            }
        }
        return nil
    }
    
    func bool(forKey key: String) -> Bool? {
        if let value = storage[key] {
            if let bool = value as? Bool {
                return bool
            } else if let num = value as? NSNumber {
                return num.boolValue
            } else if let str = value as? String {
                return str.lowercased() == "true" || str == "1"
            }
        }
        return nil
    }
    
    func array(forKey key: String) -> [Any]? {
        return storage[key] as? [Any]
    }
    
    func dictionary(forKey key: String) -> [String: Any]? {
        return storage[key] as? [String: Any]
    }
    
    // MARK: - 批量转换
    static func models<T: DictionaryEntity>(from dictionaries: [[String: Any]]) -> [T] {
        return dictionaries.map { T(dictionary: $0) }
    }
}

// MARK: - 使用示例

/*
 ============================================
 方案 3：DictionaryEntity（折中方案）
 ============================================
 
 优点：
 ✅ 纯 Swift，不依赖 OC
 ✅ 不需要定义所有属性
 ✅ 支持动态访问
 ✅ 类型安全的访问方法
 
 缺点：
 ⚠️ 没有编译时检查（属性名可能写错）
 ⚠️ 需要手动定义常用属性的计算属性
 
 ============================================
 使用方式 1：直接访问字典
 ============================================
 
 class User: DictionaryEntity {
     var name: String? {
         get { string(forKey: "name") }
         set { self["name"] = newValue }
     }
     
     var age: Int? {
         get { int(forKey: "age") }
         set { self["age"] = newValue }
     }
     
     override func afterSetProperties() {
         super.afterSetProperties()
         // 数据验证
         if name?.isEmpty ?? true {
             self.valid = false
         }
     }
 }
 
 let dict: [String: Any] = [
     "name": "张三",
     "age": 25,
     "email": "zhangsan@example.com",
     "extra_field": "不需要定义也能存储"
 ]
 
 let user = User(dictionary: dict)
 print(user.name)  // Optional("张三")
 print(user.age)   // Optional(25)
 print(user["email"])  // Optional("zhangsan@example.com")
 print(user["extra_field"])  // Optional("不需要定义也能存储")
 
 ============================================
 使用方式 2：只定义常用属性
 ============================================
 
 class User: DictionaryEntity {
     var name: String {
         get { string(forKey: "name") ?? "" }
         set { self["name"] = newValue }
     }
     
     var age: Int {
         get { int(forKey: "age") ?? 0 }
         set { self["age"] = newValue }
     }
     
     // 其他字段不定义，直接用下标访问
 }
 
 let user = User(dictionary: dict)
 print(user.name)  // "张三"（非可选）
 print(user.age)   // 25（非可选）
 print(user["email"])  // Optional("zhangsan@example.com")
 
 ============================================
 使用方式 3：完全动态访问
 ============================================
 
 class User: DictionaryEntity {
     // 不定义任何属性，完全动态访问
 }
 
 let user = User(dictionary: dict)
 print(user["name"])   // Optional("张三")
 print(user["age"])    // Optional(25)
 print(user.string(forKey: "name"))  // Optional("张三")
 print(user.int(forKey: "age"))      // Optional(25)
 
 ============================================
 批量转换
 ============================================
 
 let dicts: [[String: Any]] = [
     ["name": "张三", "age": 25],
     ["name": "李四", "age": 30]
 ]
 
 let users: [User] = DictionaryEntity.models(from: dicts)
 print(users.count)  // 2
 
 ============================================
 对比三种方案
 ============================================
 
 | 特性 | HEEntity | Codable | DictionaryEntity |
 |------|----------|---------|------------------|
 | 纯 Swift | ❌ | ✅ | ✅ |
 | 自动映射 | ✅ | ❌ | ✅ |
 | 编译时检查 | ⚠️ | ✅ | ❌ |
 | 性能 | ⚠️ | ✅ | ⚠️ |
 | 定义属性 | 需要 | 需要全部 | 可选 |
 | 动态访问 | ✅ | ❌ | ✅ |
 | 类型转换 | ✅ | ⚠️ | ✅ |
 
 推荐：
 - 混编项目 → HEEntity
 - 纯 Swift + 字段固定 → Codable
 - 纯 Swift + 字段不固定 → DictionaryEntity
 */
