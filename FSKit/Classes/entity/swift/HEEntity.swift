//
//  HEEntity.swift
//  ModuleOxfordUtils
//
//  Created by pwrd on 2026/1/23.
//

import Foundation

// MARK: - 基础协议
protocol HEEntityProtocol: AnyObject {
    var aid: Int { get set }
    var meta: [String: Any]? { get set }
    var valid: Bool { get set }
    var insets: UIEdgeInsets { get set }
    
    init()
    
    func beforeSetProperties()
    func afterSetProperties()
}

// MARK: - 基类实现
open class HEEntity: NSObject, HEEntityProtocol {
    public var aid: Int = 0
    public var meta: [String: Any]?
    public var valid: Bool = true
    public var insets: UIEdgeInsets = .zero
    
    // 钩子闭包（用于批量转换时的回调）
    private var beforeSetPropertiesBlock: ((HEEntity) -> Void)?
    private var afterSetPropertiesBlock: ((HEEntity) -> Void)?
    
    required public override init() {
        super.init()
    }
    
    // MARK: - 从Dictionary初始化
    convenience init(dictionary: [String: Any]) {
        self.init(dictionary: dictionary, beforeSetProperties: nil, afterSetProperties: nil)
    }
    
    convenience init(dictionary: [String: Any], beforeSetProperties: ((HEEntity) -> Void)?) {
        self.init(dictionary: dictionary, beforeSetProperties: beforeSetProperties, afterSetProperties: nil)
    }
    
    convenience init(
        dictionary: [String: Any],
        beforeSetProperties: ((HEEntity) -> Void)?,
        afterSetProperties: ((HEEntity) -> Void)?
    ) {
        self.init()
        self.beforeSetPropertiesBlock = beforeSetProperties
        self.afterSetPropertiesBlock = afterSetProperties
        self.beforeSetProperties()
        self.setProperties(dictionary)
    }
    
    // MARK: - 生命周期钩子
    @objc public dynamic func beforeSetProperties() {
        // 子类重写
    }
    
    @objc public dynamic func afterSetProperties() {
        // 子类重写
        
        // 执行外部传入的钩子
        beforeSetPropertiesBlock?(self)
        afterSetPropertiesBlock?(self)
    }
    
    // MARK: - 设置属性
    func setProperties(_ dictionary: [String: Any]) {
        guard !dictionary.isEmpty else { return }
        
        self.meta = dictionary
        
        // 使用 KVC 设置属性
        for (key, value) in dictionary {
            // 检查属性是否存在
            if self.responds(to: NSSelectorFromString(key)) {
                let convertedValue = convertValue(value, forKey: key)
                self.setValue(convertedValue, forKey: key)
            } else {
                #if DEBUG
                print("⚠️ \(type(of: self)) 存在未定义的属性: \(key) = \(value)")
                #endif
            }
        }
        
        self.afterSetProperties()
    }
    
    // MARK: - 类型转换
    private func convertValue(_ value: Any, forKey key: String) -> Any? {
        // 处理 NSNull
        if value is NSNull {
            return ""  // 与 OC 版本保持一致，NSNull 转为空字符串
        }
        
        // 处理基本类型
        if value is String || value is NSArray || value is NSDictionary {
            return value
        }
        
        // 处理 NSNumber（转为字符串，与 OC 版本保持一致）
        if let number = value as? NSNumber {
            return number.stringValue
        }
        
        // 其他类型转为描述字符串
        if let obj = value as? NSObject {
            return obj.description
        }
        
        return value
    }
    
    // MARK: - KVC 支持
    public override func setValue(_ value: Any?, forUndefinedKey key: String) {
        #if DEBUG
        print("⚠️ \(type(of: self)) 设置未定义的属性: \(key) = \(String(describing: value))")
        #endif
    }
    
    // MARK: - 批量转换
    public static func models<T: HEEntity>(from dictionaries: [[String: Any]]) -> [T] {
        return models(from: dictionaries, modelClass: T.self, beforeSetProperties: nil, afterSetProperties: nil)
    }
    
    static func models<T: HEEntity>(
        from dictionaries: [[String: Any]],
        beforeSetProperties: ((T) -> Void)?
    ) -> [T] {
        return models(from: dictionaries, modelClass: T.self, beforeSetProperties: beforeSetProperties, afterSetProperties: nil)
    }
    
    static func models<T: HEEntity>(
        from dictionaries: [[String: Any]],
        beforeSetProperties: ((T) -> Void)?,
        afterSetProperties: ((T) -> Void)?
    ) -> [T] {
        return models(from: dictionaries, modelClass: T.self, beforeSetProperties: beforeSetProperties, afterSetProperties: afterSetProperties)
    }
    
    // 内部实现方法
    private static func models<T: HEEntity>(
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
            
            // 使用 modelClass.init() 创建实例
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

// MARK: - 使用示例

/*
 // 1. 定义模型
 class User: HEEntity {
     @objc dynamic var name: String = ""
     @objc dynamic var age: Int = 0
     @objc dynamic var email: String = ""
     @objc dynamic var avatar: String = ""
     
     override func beforeSetProperties() {
         super.beforeSetProperties()
         // 设置默认值
         self.valid = true
     }
     
     override func afterSetProperties() {
         super.afterSetProperties()
         // 数据验证
         if name.isEmpty {
             self.valid = false
         }
     }
 }

 // 2. 使用示例
 let dict: [String: Any] = [
     "name": "张三",
     "age": 25,
     "email": "zhangsan@example.com",
     "avatar": "https://example.com/avatar.jpg"
 ]

 // 单个模型
 let user = User(dictionary: dict)
 print(user.name)  // 张三

 // 批量转换
 let dicts: [[String: Any]] = [
     ["name": "张三", "age": 25],
     ["name": "李四", "age": 30]
 ]

 let users: [User] = HEEntity.models(from: dicts)
 print(users.count)  // 2

 // 带钩子的批量转换
 let users2: [User] = HEEntity.models(
     from: dicts,
     beforeSetProperties: { user in
         user.valid = true
     },
     afterSetProperties: { user in
         print("处理完成: \(user.name)")
     }
 )
 */
