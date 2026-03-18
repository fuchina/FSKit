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
        let v = "FSLog FSModel.ERROR: \(info)"
        NotificationCenter.default.post(name: NSNotification.Name(FS_BE_DEBUG_NOTIFICATION), object: v)
    }
}
