//
//  FSObject.swift
//  FSKit
//
//  Created by pwrd on 2026/3/18.
//

import Foundation

open class FSObject {
    
    public var     aid      :   Int = 0
    public var     meta     :   Dictionary<String, Any>? = nil
    
    public static func jsonToModel<T>(type: T.Type, json: Any) -> T? where T: Codable {
        
            if let _ = json as? NSNull {
                FSObjectShowLog("json is NSNull")
                return nil
            }

            // 验证 JSON 是否为有效的 JSON 对象
            guard JSONSerialization.isValidJSONObject(json) else {
                FSObjectShowLog("Invalid top-level type in JSON")
                return nil
            }

            // 尝试将 JSON 转换为 Data
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])

                // 尝试将 Data 解码为模型
                do {
                    let model = try JSONDecoder().decode(type, from: jsonData)
                    return model
                } catch {
                    FSObjectShowLog("Json Failed to decode JSON to model: \(error)")
                    return nil
                }

            } catch {
                FSObjectShowLog("Json Failed to serialize JSON object to Data: \(error)")
                return nil
            }
    }
    
    private static func FSObjectShowLog(_ info: String) {
        print("FSLog FSObject.ERROR：\(info)")
    }
}
