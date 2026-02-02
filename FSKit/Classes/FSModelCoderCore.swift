//
//  FSModelCoderCore.swift
//  FSKit
//
//  Translated from Objective-C to Swift
//

import Foundation

// MARK: - FSTriBool
public enum FSTriBool: Int {
    case unknown = -1
    case no = 0
    case yes = 1
}

// MARK: - FSModelCoder
public class FSModelCoder: NSObject, NSSecureCoding {
    
    public var dictionary: [String: Any]?
    public var list: [Any]?
    public var boolean: FSTriBool = .unknown
    public var string: String?
    
    public static var supportsSecureCoding: Bool { true }
    
    public override init() {
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        super.init()
        dictionary = coder.decodeObject(forKey: "dictionary") as? [String: Any]
        list = coder.decodeObject(forKey: "list") as? [Any]
        boolean = FSTriBool(rawValue: coder.decodeInteger(forKey: "boolean")) ?? .unknown
        string = coder.decodeObject(forKey: "string") as? String
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(dictionary, forKey: "dictionary")
        coder.encode(list, forKey: "list")
        coder.encode(boolean.rawValue, forKey: "boolean")
        coder.encode(string, forKey: "string")
    }
    
    // MARK: - Save Methods
    @discardableResult
    public static func saveBoolean(_ boolean: FSTriBool, forKey key: String) -> Error? {
        return save(dictionary: nil, list: nil, boolean: boolean, string: nil, forKey: key)
    }
    
    @discardableResult
    public static func saveString(_ string: String?, forKey key: String) -> Error? {
        return save(dictionary: nil, list: nil, boolean: .unknown, string: string, forKey: key)
    }
    
    @discardableResult
    public static func saveList(_ list: [Any]?, forKey key: String) -> Error? {
        return save(dictionary: nil, list: list, boolean: .unknown, string: nil, forKey: key)
    }
    
    @discardableResult
    public static func saveDictionary(_ dictionary: [String: Any]?, forKey key: String) -> Error? {
        return save(dictionary: dictionary, list: nil, boolean: .unknown, string: nil, forKey: key)
    }
    
    @discardableResult
    public static func save(dictionary: [String: Any]?, list: [Any]?, boolean: FSTriBool, string: String?, forKey key: String) -> Error? {
        let coder = FSModelCoder()
        coder.dictionary = dictionary
        coder.list = list
        coder.boolean = boolean
        coder.string = string
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: coder, requiringSecureCoding: true)
            guard let path = filePath(key) else { return nil }
            try data.write(to: URL(fileURLWithPath: path), options: .atomic)
            return nil
        } catch {
            return error
        }
    }
    
    // MARK: - Fetch
    public static func fetch(_ key: String) -> FSModelCoder? {
        guard let filePath = filePath(key) else { return nil }
        
        let fm = FileManager.default
        guard fm.fileExists(atPath: filePath) else { return nil }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let classes: [AnyClass] = [FSModelCoder.self, NSDictionary.self, NSArray.self, NSNumber.self, NSString.self]
            let coder = try NSKeyedUnarchiver.unarchivedObject(ofClasses: classes, from: data) as? FSModelCoder
            return coder
        } catch {
            try? fm.removeItem(atPath: filePath)
            return nil
        }
    }
    
    // MARK: - Remove
    @discardableResult
    public static func remove(_ key: String) -> Bool {
        guard let filePath = filePath(key) else { return true }
        
        let fm = FileManager.default
        guard fm.fileExists(atPath: filePath) else { return true }
        
        do {
            try fm.removeItem(atPath: filePath)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - File Path
    private static func filePath(_ key: String) -> String? {
        guard !key.isEmpty else { return nil }
        
        guard let libraryDirectory = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).last else { return nil }
        
        let dir = (libraryDirectory as NSString).appendingPathComponent("FSModelCoder")
        let fm = FileManager.default
        
        var isDir: ObjCBool = true
        if !fm.fileExists(atPath: dir, isDirectory: &isDir) {
            try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: [:])
        }
        
        return (dir as NSString).appendingPathComponent(key)
    }
}
