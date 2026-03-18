//
//  FSModel.swift
//  FSKit
//
//  Created by pwrd on 2026/3/18.
//

import Foundation

public enum FSModel {

    public static func decode<T: Decodable>(
        _ type: T.Type,
        from json: Any,
        decoder: JSONDecoder = JSONDecoder()
    ) -> T? {
        
        if json is NSNull {
            fsModelLog("decode failed: json is NSNull")
            return nil
        }

        guard JSONSerialization.isValidJSONObject(json) else {
            fsModelLog("decode failed: invalid top-level JSON object")
            return nil
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            return try decoder.decode(type, from: data)
        } catch {
            fsModelLog("decode failed: \(error)")
            return nil
        }
    }

    public static func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data,
        decoder: JSONDecoder = JSONDecoder()
    ) -> T? {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            fsModelLog("decode failed: \(error)")
            return nil
        }
    }

    public static func encode<T: Encodable>(
        _ model: T,
        encoder: JSONEncoder = JSONEncoder()
    ) -> Data? {
        do {
            return try encoder.encode(model)
        } catch {
            fsModelLog("encode failed: \(error)")
            return nil
        }
    }

    private static func fsModelLog(_ info: String) {
        print("FSLog FSModel.ERROR: \(info)")
    }
}

public protocol FSDefaultValueProvider {
    associatedtype Value: Codable
    static var defaultValue: Value { get }
}

@propertyWrapper
public struct FSDefault<P: FSDefaultValueProvider>: Codable {
    public var wrappedValue: P.Value

    public init() {
        self.wrappedValue = P.defaultValue
    }

    public init(wrappedValue: P.Value) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = (try? container.decode(P.Value.self)) ?? P.defaultValue
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

public enum FSDefaults {
    public enum ZeroInt: FSDefaultValueProvider {
        public static let defaultValue: Int = 0
    }

    public enum ZeroDouble: FSDefaultValueProvider {
        public static let defaultValue: Double = 0
    }

    public enum FalseBool: FSDefaultValueProvider {
        public static let defaultValue: Bool = false
    }

    public enum EmptyString: FSDefaultValueProvider {
        public static let defaultValue: String = ""
    }
}

@propertyWrapper
public struct FSLossyInt: Codable {
    public var wrappedValue: Int

    public init(wrappedValue: Int = 0) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(Int.self) {
            wrappedValue = value
            return
        }
        if let value = try? container.decode(String.self), let intValue = Int(value) {
            wrappedValue = intValue
            return
        }
        if let value = try? container.decode(Double.self) {
            wrappedValue = Int(value)
            return
        }
        if let value = try? container.decode(Bool.self) {
            wrappedValue = value ? 1 : 0
            return
        }

        wrappedValue = 0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

@propertyWrapper
public struct FSLossyDouble: Codable {
    public var wrappedValue: Double

    public init(wrappedValue: Double = 0) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(Double.self) {
            wrappedValue = value
            return
        }
        if let value = try? container.decode(Int.self) {
            wrappedValue = Double(value)
            return
        }
        if let value = try? container.decode(String.self), let doubleValue = Double(value) {
            wrappedValue = doubleValue
            return
        }
        if let value = try? container.decode(Bool.self) {
            wrappedValue = value ? 1 : 0
            return
        }

        wrappedValue = 0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

@propertyWrapper
public struct FSLossyBool: Codable {
    public var wrappedValue: Bool

    public init(wrappedValue: Bool = false) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(Bool.self) {
            wrappedValue = value
            return
        }
        if let value = try? container.decode(Int.self) {
            wrappedValue = value != 0
            return
        }
        if let value = try? container.decode(String.self) {
            let lower = value.lowercased()
            wrappedValue = lower == "true" || lower == "1" || lower == "yes"
            return
        }

        wrappedValue = false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

@propertyWrapper
public struct FSLossyString: Codable {
    public var wrappedValue: String

    public init(wrappedValue: String = "") {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(String.self) {
            wrappedValue = value
            return
        }
        if let value = try? container.decode(Int.self) {
            wrappedValue = String(value)
            return
        }
        if let value = try? container.decode(Double.self) {
            wrappedValue = String(value)
            return
        }
        if let value = try? container.decode(Bool.self) {
            wrappedValue = value ? "true" : "false"
            return
        }

        wrappedValue = ""
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

public struct FSModelExample: Codable {
    @FSLossyInt public var aid: Int = 0
    @FSLossyString public var name: String = ""
    @FSDefault<FSDefaults.ZeroDouble> public var score: Double = 0
}
