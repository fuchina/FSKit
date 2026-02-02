//
//  FSRuntimeCore.swift
//  FSKit
//
//  Translated from Objective-C to Swift
//

import Foundation
import ObjectiveC

public class FSRuntime: NSObject {
    
    // MARK: - Get Properties
    public static func properties(forClass cls: AnyClass) -> [String] {
        var count: UInt32 = 0
        guard let properties = class_copyPropertyList(cls, &count) else { return [] }
        defer { free(properties) }
        
        var result: [String] = []
        for i in 0..<Int(count) {
            let property = properties[i]
            if let name = property_getName(property) {
                result.append(String(cString: name))
            }
        }
        return result
    }
    
    // MARK: - Get Ivars
    public static func ivars(forClass cls: AnyClass) -> [String] {
        var count: UInt32 = 0
        guard let ivars = class_copyIvarList(cls, &count) else { return [] }
        defer { free(ivars) }
        
        var result: [String] = []
        for i in 0..<Int(count) {
            let ivar = ivars[i]
            if let name = ivar_getName(ivar) {
                result.append(String(cString: name))
            }
        }
        return result
    }
    
    // MARK: - Setter Selector
    public static func setterSelector(withAttributeName attrName: String) -> Selector? {
        guard !attrName.isEmpty else { return nil }
        let capital = attrName.prefix(1).uppercased()
        let rest = String(attrName.dropFirst())
        let setterName = "set\(capital)\(rest):"
        return NSSelectorFromString(setterName)
    }
    
    // MARK: - Set Value
    public static func setValue(_ value: Any?, forPropertyName name: String, of object: NSObject) {
        guard !name.isEmpty else { return }
        guard let selector = setterSelector(withAttributeName: name) else { return }
        guard object.responds(to: selector) else { return }
        object.perform(selector, with: value)
    }
    
    public static func setValue(_ value: Any?, forIvarName name: String, of object: NSObject) {
        guard !name.isEmpty else { return }
        guard let selector = setterSelector(withAttributeName: name) else { return }
        guard object.responds(to: selector) else { return }
        object.perform(selector, with: value)
    }
    
    // MARK: - Create Entity from Dictionary
    public static func entity<T: NSObject>(_ entityClass: T.Type, dic: [String: Any]?) -> T {
        let instance = entityClass.init()
        guard let dic = dic, !dic.isEmpty else { return instance }
        
        for (key, value) in dic {
            setValue(value, forPropertyName: key, of: instance)
        }
        return instance
    }
    
    // MARK: - Get Value
    public static func value(forPropertyName name: String, of object: Any) -> Any? {
        guard !name.isEmpty else { return nil }
        return (object as? NSObject)?.value(forKey: name)
    }
    
    // MARK: - Dictionary from Object
    public static func dictionary(with model: NSObject) -> [String: Any] {
        let properties = self.properties(forClass: type(of: model))
        var dic: [String: Any] = [:]
        
        for property in properties {
            if let value = value(forPropertyName: property, of: model) {
                if value is String || value is NSNumber {
                    dic[property] = value
                } else {
                    dic[property] = ""
                }
            } else {
                dic[property] = ""
            }
        }
        return dic
    }
    
    // MARK: - Get Class Methods
    public static func classMethodList(of cls: AnyClass) -> [String]? {
        var isMeta = class_isMetaClass(cls)
        var meta: AnyClass? = cls
        
        if !isMeta {
            let className = NSStringFromClass(cls)
            meta = objc_getMetaClass(className) as? AnyClass
            isMeta = meta != nil && class_isMetaClass(meta!)
        }
        
        guard isMeta, let metaClass = meta else { return nil }
        
        var count: UInt32 = 0
        guard let methods = class_copyMethodList(metaClass, &count) else { return nil }
        defer { free(methods) }
        
        var result: [String] = []
        for i in 0..<Int(count) {
            let method = methods[i]
            let selector = method_getName(method)
            result.append(NSStringFromSelector(selector))
        }
        
        return result.isEmpty ? nil : result
    }
    
    // MARK: - Get Instance Methods
    public static func methodList(of cls: AnyClass) -> [String] {
        var count: UInt32 = 0
        guard let methods = class_copyMethodList(cls, &count) else { return [] }
        defer { free(methods) }
        
        var result: [String] = []
        for i in 0..<Int(count) {
            let method = methods[i]
            let selector = method_getName(method)
            result.append(NSStringFromSelector(selector))
        }
        return result
    }
}
