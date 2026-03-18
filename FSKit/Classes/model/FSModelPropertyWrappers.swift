//
//  FSModelPropertyWrappers.swift
//  FSKit
//
//  Created by pwrd on 2026/3/18.
//

import Foundation

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
