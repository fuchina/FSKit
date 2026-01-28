//
//  SwiftEntity.swift
//  ModuleOxfordUtils
//
//  Created by pwrd on 2026/1/23.
//  纯 Swift 实现的模型基类，不依赖 Objective-C
//

import Foundation
import UIKit

// MARK: - 协议定义
protocol SwiftEntityProtocol: AnyObject {
    var aid: Int { get set }
    var meta: [String: Any]? { get set }
    var valid: Bool { get set }
    var insets: UIEdgeInsets { get set }
    
    init()
    func beforeSetProperties()
    func afterSetProperties()
}

// MARK: - 纯 Swift 基类
open class SwiftEntity: SwiftEntityProtocol {
    public var aid: Int = 0
    public var meta: [String: Any]?
    var valid: Bool = true
    var insets: UIEdgeInsets = .zero
    
    // 钩子闭包
    private var beforeSetPropertiesBlock: ((SwiftEntity) -> Void)?
    private var afterSetPropertiesBlock: ((SwiftEntity) -> Void)?
    
    required public init() {}
    
    // MARK: - 初始化方法
    convenience init(dictionary: [String: Any]) {
        self.init(dictionary: dictionary, beforeSetProperties: nil, afterSetProperties: nil)
    }
    
    convenience init(dictionary: [String: Any], beforeSetProperties: ((SwiftEntity) -> Void)?) {
        self.init(dictionary: dictionary, beforeSetProperties: beforeSetProperties, afterSetProperties: nil)
    }
    
    convenience init(
        dictionary: [String: Any],
        beforeSetProperties: ((SwiftEntity) -> Void)?,
        afterSetProperties: ((SwiftEntity) -> Void)?
    ) {
        self.init()
        self.beforeSetPropertiesBlock = beforeSetProperties
        self.afterSetPropertiesBlock = afterSetProperties
        self.beforeSetProperties()
        self.setProperties(dictionary)
    }
    
    // MARK: - 生命周期钩子
    open func beforeSetProperties() {
        // 子类重写
    }
    
    open func afterSetProperties() {
        // 子类重写
        
        // 执行外部传入的钩子
        beforeSetPropertiesBlock?(self)
        afterSetPropertiesBlock?(self)
    }
    
    // MARK: - 设置属性（核心方法）
    func setProperties(_ dictionary: [String: Any]) {
        guard !dictionary.isEmpty else { return }
        
        self.meta = dictionary
                
        // 使用 Mirror 反射获取所有属性
        let mirror = Mirror(reflecting: self)
        
        for (key, value) in dictionary {
            // 查找匹配的属性
            if let property = findProperty(named: key, in: mirror) {
                setPropertyValue(property: property, value: value, key: key)
            } else {
                handleUndefinedKey(key: key, value: value)
            }
        }
                
        self.afterSetProperties()
    }
    
    // MARK: - 反射查找属性
    private func findProperty(named key: String, in mirror: Mirror) -> Mirror.Child? {
        // 遍历当前类的属性
        for child in mirror.children {
            if child.label == key {
                return child
            }
        }
        
        // 递归查找父类的属性
        if let superMirror = mirror.superclassMirror {
            return findProperty(named: key, in: superMirror)
        }
        
        return nil
    }
    
    // MARK: - 设置属性值（类型转换）
    private func setPropertyValue(property: Mirror.Child, value: Any, key: String) {
        let propertyValue = property.value
        let propertyType = type(of: propertyValue)
                
        // 转换值
        guard let convertedValue = convertValue(value, to: propertyType) else {
            return
        }
                
        // 使用类型匹配来设置值
        setValueByType(key: key, value: convertedValue, originalType: propertyType)
    }
    
    // MARK: - 类型转换
    private func convertValue(_ value: Any, to targetType: Any.Type) -> Any? {
        // 处理 NSNull
        if value is NSNull {
            return getDefaultValue(for: targetType)
        }
        
        // 目标类型是 String
        if targetType is String.Type || targetType is String?.Type {
            if let str = value as? String {
                return str
            } else if let num = value as? NSNumber {
                return num.stringValue
            } else if let num = value as? Int {
                return String(num)
            } else if let num = value as? Double {
                return String(num)
            } else if let bool = value as? Bool {
                return String(bool)
            } else {
                return String(describing: value)
            }
        }
        
        // 目标类型是 Int
        if targetType is Int.Type || targetType is Int?.Type {
            if let num = value as? Int {
                return num
            } else if let str = value as? String {
                return Int(str) ?? 0
            } else if let num = value as? NSNumber {
                return num.intValue
            }
        }
        
        // 目标类型是 Double
        if targetType is Double.Type || targetType is Double?.Type {
            if let num = value as? Double {
                return num
            } else if let str = value as? String {
                return Double(str) ?? 0.0
            } else if let num = value as? NSNumber {
                return num.doubleValue
            }
        }
        
        // 目标类型是 Float
        if targetType is Float.Type || targetType is Float?.Type {
            if let num = value as? Float {
                return num
            } else if let str = value as? String {
                return Float(str) ?? 0.0
            } else if let num = value as? NSNumber {
                return num.floatValue
            }
        }
        
        // 目标类型是 Bool
        if targetType is Bool.Type || targetType is Bool?.Type {
            if let bool = value as? Bool {
                return bool
            } else if let num = value as? NSNumber {
                return num.boolValue
            } else if let str = value as? String {
                return str.lowercased() == "true" || str == "1"
            }
        }
        
        // 目标类型是 Array
        if targetType is [Any].Type || targetType is [Any]?.Type {
            if let array = value as? [Any] {
                return array
            }
        }
        
        // 目标类型是 Dictionary
        if targetType is [String: Any].Type || targetType is [String: Any]?.Type {
            if let dict = value as? [String: Any] {
                return dict
            }
        }
        
        // 直接返回原值
        return value
    }
    
    // MARK: - 获取默认值
    private func getDefaultValue(for type: Any.Type) -> Any? {
        if type is String.Type || type is String?.Type {
            return ""
        } else if type is Int.Type || type is Int?.Type {
            return 0
        } else if type is Double.Type || type is Double?.Type {
            return 0.0
        } else if type is Float.Type || type is Float?.Type {
            return Float(0.0)
        } else if type is Bool.Type || type is Bool?.Type {
            return false
        }
        return nil
    }
    
    // MARK: - 按类型设置值
    private func setValueByType(key: String, value: Any, originalType: Any.Type) {
        // 使用 KeyPath 的方式（需要子类提供具体的 KeyPath）
        // 这里我们使用一个更通用的方法：通过协议扩展
                
        // 由于 Swift 的类型安全，我们需要为每种类型提供设置方法
        if let strValue = value as? String {
            setStringValue(strValue, forKey: key)
        } else if let intValue = value as? Int {
            setIntValue(intValue, forKey: key)
        } else if let doubleValue = value as? Double {
            setDoubleValue(doubleValue, forKey: key)
        } else if let floatValue = value as? Float {
            setFloatValue(floatValue, forKey: key)
        } else if let boolValue = value as? Bool {
            setBoolValue(boolValue, forKey: key)
        } else if let arrayValue = value as? [Any] {
            setArrayValue(arrayValue, forKey: key)
        } else if let dictValue = value as? [String: Any] {
            setDictValue(dictValue, forKey: key)
        } else {
            assert(1==2, "\(self) 解析错误：key = \(key), value = \(value)")
        }
    }
    
    // MARK: - 类型特定的设置方法（子类可重写）
    func setStringValue(_ value: String, forKey key: String) {
        // 子类通过 switch 或 if-else 来设置具体属性
        // 这是纯 Swift 的限制，无法像 OC 的 KVC 那样动态设置
        
        
    }
    
    func setIntValue(_ value: Int, forKey key: String) {}
    func setDoubleValue(_ value: Double, forKey key: String) {}
    func setFloatValue(_ value: Float, forKey key: String) {}
    func setBoolValue(_ value: Bool, forKey key: String) {}
    func setArrayValue(_ value: [Any], forKey key: String) {}
    func setDictValue(_ value: [String: Any], forKey key: String) {}
    
    // MARK: - 处理未定义的键
    private func handleUndefinedKey(key: String, value: Any) {
        #if DEBUG
        print("⚠️ \(type(of: self)) 存在未定义的属性: \(key) = \(value)")
        #endif
    }
    
    // MARK: - 批量转换
    public static func models<T: SwiftEntity>(from dictionaries: [[String: Any]]) -> [T] {
        return models(from: dictionaries, modelClass: T.self, beforeSetProperties: nil, afterSetProperties: nil)
    }
    
    static func models<T: SwiftEntity>(
        from dictionaries: [[String: Any]],
        beforeSetProperties: ((T) -> Void)?
    ) -> [T] {
        return models(from: dictionaries, modelClass: T.self, beforeSetProperties: beforeSetProperties, afterSetProperties: nil)
    }
    
    static func models<T: SwiftEntity>(
        from dictionaries: [[String: Any]],
        beforeSetProperties: ((T) -> Void)?,
        afterSetProperties: ((T) -> Void)?
    ) -> [T] {
        return models(from: dictionaries, modelClass: T.self, beforeSetProperties: beforeSetProperties, afterSetProperties: afterSetProperties)
    }
    
    private static func models<T: SwiftEntity>(
        from dictionaries: [[String: Any]],
        modelClass: T.Type,
        beforeSetProperties: ((T) -> Void)?,
        afterSetProperties: ((T) -> Void)?
    ) -> [T] {
        guard !dictionaries.isEmpty else { return [] }
        
        var results: [T] = []
        results.reserveCapacity(dictionaries.count)
        
        for dict in dictionaries {
            guard !dict.isEmpty else { continue }
            
            let model = modelClass.init()
                    
            model.beforeSetPropertiesBlock = { entity in
                if let typedEntity = entity as? T {
                    beforeSetProperties?(typedEntity)
                }
            }
            model.afterSetPropertiesBlock = { entity in
                if let typedEntity = entity as? T {
                    afterSetProperties?(typedEntity)
                }
            }
            model.beforeSetProperties()
            model.setProperties(dict)
                        
            results.append(model)
        }
        
        return results
    }
}

// MARK: - 使用示例和说明

/*
 ⚠️ 纯 Swift 的限制说明：
 
 由于 Swift 的类型安全和编译时检查，无法像 Objective-C 的 KVC 那样在运行时动态设置任意属性。
 
 解决方案：子类需要重写 setXXXValue 方法来手动映射属性。
 
 示例：
 
 class User: SwiftEntity {
     var name: String = ""
     var age: Int = 0
     var email: String = ""
     var avatar: String = ""
     
     override func setStringValue(_ value: String, forKey key: String) {
         switch key {
         case "name":
             self.name = value
         case "email":
             self.email = value
         case "avatar":
             self.avatar = value
         default:
             super.setStringValue(value, forKey: key)
         }
     }
     
     override func setIntValue(_ value: Int, forKey key: String) {
         switch key {
         case "age":
             self.age = value
         case "aid":
             self.aid = value
         default:
             super.setIntValue(value, forKey: key)
         }
     }
     
     override func afterSetProperties() {
         super.afterSetProperties()
         // 数据验证
         if name.isEmpty {
             self.valid = false
         }
     }
 }
 
 // 使用
 let dict: [String: Any] = [
     "name": "张三",
     "age": 25,
     "email": "zhangsan@example.com"
 ]
 
 let user = User(dictionary: dict)
 print(user.name)  // 张三
 print(user.age)   // 25
 
 // 批量转换
 let users: [User] = SwiftEntity.models(from: [dict])
 
 ⚠️ 这种方式的缺点：
 1. 需要手动在 setXXXValue 方法中映射每个属性
 2. 代码量比 OC 版本多
 3. 不如 Codable 优雅
 
 ✅ 优点：
 1. 纯 Swift，无 OC 依赖
 2. 类型安全
 3. 支持生命周期钩子
 4. 支持批量转换
 5. 保留了 meta 元数据
 
 💡 建议：
 如果可以的话，使用 Swift 的 Codable 协议会更优雅：
 
 struct User: Codable {
     var name: String
     var age: Int
     var email: String
 }
 
 let user = try? JSONDecoder().decode(User.self, from: jsonData)
 */
