//
//  FSEntityCore.swift
//  FSKit
//
//  Translated from Objective-C to Swift
//

import Foundation

open class FSEntityBase: NSObject {
    
    /// 数据id
    public var aid: Int = 0
    
    /// 元数据，还可以通过其判断dictionary是否为NSDictionary，判断属性是否已经被设置
    public private(set) var meta: [String: Any]?
    
    /// 有效
    public var valid: Bool = false
    
    private var beforeSetPropertiesBlock: ((Any) -> Void)?
    private var afterSetPropertiesBlock: ((Any) -> Void)?
    
    public override init() {
        super.init()
    }
    
    /// 比如一个映射的属性需要设置默认值，就可以调用这个方法
    open func beforeSetProperties() {}
    
    public convenience init(dictionary: [String: Any]?) {
        self.init(dictionary: dictionary, beforeSetProperties: nil, afterSetProperties: nil)
    }
    
    public convenience init(dictionary: [String: Any]?, beforeSetProperties: ((Any) -> Void)?) {
        self.init(dictionary: dictionary, beforeSetProperties: beforeSetProperties, afterSetProperties: nil)
    }
    
    public init(dictionary: [String: Any]?, beforeSetProperties: ((Any) -> Void)?, afterSetProperties: ((Any) -> Void)?) {
        super.init()
        self.beforeSetProperties()
        self.beforeSetPropertiesBlock = beforeSetProperties
        self.afterSetPropertiesBlock = afterSetProperties
        self.setProperties(dictionary)
    }
    
    public func setProperties(_ dictionary: [String: Any]?) {
        guard let dictionary = dictionary else { return }
        
        valid = true
        meta = dictionary
        
        for (key, value) in dictionary {
            setValue(value, forKey: key)
        }
        
        beforeSetPropertiesBlock?(self)
        afterSetProperties()
        afterSetPropertiesBlock?(self)
    }
    
    open func afterSetProperties() {}
    
    open override func setValue(_ value: Any?, forKey key: String) {
        var finalValue: Any? = value
        
        if let value = value {
            if value is [Any] || value is [String: Any] || value is String {
                // Keep as is
            } else if value is NSNull {
                finalValue = ""
            } else if let number = value as? NSNumber {
                finalValue = number.stringValue
            } else {
                finalValue = String(describing: value)
            }
        }
        
        do {
            try super.setValue(finalValue, forKey: key)
        } catch {
            // Silently ignore
        }
    }
    
    open override func setValue(_ value: Any?, forUndefinedKey key: String) {
        #if DEBUG
        print("\(type(of: self)) set UndefinedKey (\(key) - \(String(describing: value)))")
        #endif
    }
    
    // MARK: - Class Methods
    public static func models<T: FSEntityBase>(from dictionaries: [[String: Any]]?, modelClass: T.Type) -> [T] {
        return models(from: dictionaries, modelClass: modelClass, beforeSetProperties: nil, afterSetProperties: nil)
    }
    
    public static func models<T: FSEntityBase>(from dictionaries: [[String: Any]]?, modelClass: T.Type, beforeSetProperties: ((Any) -> Void)?) -> [T] {
        return models(from: dictionaries, modelClass: modelClass, beforeSetProperties: beforeSetProperties, afterSetProperties: nil)
    }
    
    public static func models<T: FSEntityBase>(from dictionaries: [[String: Any]]?, modelClass: T.Type, beforeSetProperties: ((Any) -> Void)?, afterSetProperties: ((Any) -> Void)?) -> [T] {
        guard let dictionaries = dictionaries else { return [] }
        
        var results: [T] = []
        for dict in dictionaries {
            let model = modelClass.init(dictionary: dict, beforeSetProperties: beforeSetProperties, afterSetProperties: afterSetProperties)
            results.append(model)
        }
        return results
    }
}
