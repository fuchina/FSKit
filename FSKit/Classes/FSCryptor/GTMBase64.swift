//
//  GTMBase64.swift
//  FSCryptor
//
//  Translated from Objective-C to Swift.
//

import Foundation

open class GTMBase64: NSObject {

    public static func encode(_ data: Data) -> Data? {
        encodeData(data)
    }

    public static func decode(_ string: String) -> Data? {
        decodeString(string)
    }

    public static func encodeData(_ data: Data) -> Data? {
        data.base64EncodedData(options: [])
    }

    public static func decodeData(_ data: Data) -> Data? {
        decodeBytes((data as NSData).bytes, length: UInt(data.count))
    }

    public static func encodeBytes(_ bytes: UnsafeRawPointer, length: UInt) -> Data? {
        let data = Data(bytes: bytes, count: Int(length))
        return encodeData(data)
    }

    public static func decodeBytes(_ bytes: UnsafeRawPointer, length: UInt) -> Data? {
        decodeBytesInternal(bytes, length: Int(length), webSafe: false, requirePadding: true)
    }

    public static func stringByEncodingData(_ data: Data) -> String? {
        encodeData(data).flatMap { String(data: $0, encoding: .utf8) }
    }

    public static func stringByEncodingBytes(_ bytes: UnsafeRawPointer, length: UInt) -> String? {
        encodeBytes(bytes, length: length).flatMap { String(data: $0, encoding: .utf8) }
    }

    public static func decodeString(_ string: String) -> Data? {
        decodeStringInternal(string, webSafe: false, requirePadding: true)
    }

    public static func webSafeEncodeData(_ data: Data, padded: Bool) -> Data? {
        let base64 = data.base64EncodedString(options: [])
        let webSafe = base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
        let result = padded ? webSafe : webSafe.replacingOccurrences(of: "=", with: "")
        return result.data(using: .utf8)
    }

    public static func webSafeDecodeData(_ data: Data) -> Data? {
        webSafeDecodeBytes((data as NSData).bytes, length: UInt(data.count))
    }

    public static func webSafeEncodeBytes(_ bytes: UnsafeRawPointer, length: UInt, padded: Bool) -> Data? {
        let data = Data(bytes: bytes, count: Int(length))
        return webSafeEncodeData(data, padded: padded)
    }

    public static func webSafeDecodeBytes(_ bytes: UnsafeRawPointer, length: UInt) -> Data? {
        decodeBytesInternal(bytes, length: Int(length), webSafe: true, requirePadding: false)
    }

    public static func stringByWebSafeEncodingData(_ data: Data, padded: Bool) -> String? {
        webSafeEncodeData(data, padded: padded).flatMap { String(data: $0, encoding: .utf8) }
    }

    public static func stringByWebSafeEncodingBytes(_ bytes: UnsafeRawPointer, length: UInt, padded: Bool) -> String? {
        webSafeEncodeBytes(bytes, length: length, padded: padded).flatMap { String(data: $0, encoding: .utf8) }
    }

    public static func webSafeDecodeString(_ string: String) -> Data? {
        decodeStringInternal(string, webSafe: true, requirePadding: false)
    }

    private static func decodeBytesInternal(_ bytes: UnsafeRawPointer, length: Int, webSafe: Bool, requirePadding: Bool) -> Data? {
        let encoded = Data(bytes: bytes, count: length)
        guard let string = String(data: encoded, encoding: .utf8) else {
            return nil
        }
        return decodeStringInternal(string, webSafe: webSafe, requirePadding: requirePadding)
    }

    private static func decodeStringInternal(_ string: String, webSafe: Bool, requirePadding: Bool) -> Data? {
        let trimmed = string.unicodeScalars.filter { !$0.properties.isWhitespace }.map(String.init).joined()
        let normalized = webSafe
            ? trimmed.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
            : trimmed

        if requirePadding, normalized.count % 4 != 0 {
            return nil
        }

        let remainder = normalized.count % 4
        let padded: String
        if remainder == 0 {
            padded = normalized
        } else {
            padded = normalized + String(repeating: "=", count: 4 - remainder)
        }

        return Data(base64Encoded: padded, options: [])
    }
}
