//
//  Codable+Dictionary.swift
//  ModuleOxfordUtils
//
//  Created by pwrd on 2026/1/23.
//  Codable 扩展：支持字典和数组的便捷转换
//  ⚠️ Codable 不需要基类，直接使用即可
//

import Foundation

// MARK: - Decodable 扩展
extension Decodable {
    /// 从字典初始化模型
    static func decode(from dictionary: [String: Any]) -> Self? {
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else {
            return nil
        }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
    
    /// 从字典数组批量初始化模型
    static func decode(from dictionaries: [[String: Any]]) -> [Self] {
        return dictionaries.compactMap { decode(from: $0) }
    }
    
    /// 从 JSON 字符串初始化模型
    static func decode(from jsonString: String) -> Self? {
        guard let data = jsonString.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
}

// MARK: - Encodable 扩展
extension Encodable {
    /// 转为字典
    func toDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        return dict
    }
    
    /// 转为 JSON 字符串
    func toJSONString(prettyPrinted: Bool = false) -> String? {
        let encoder = JSONEncoder()
        if prettyPrinted {
            encoder.outputFormatting = .prettyPrinted
        }
        guard let data = try? encoder.encode(self),
              let jsonString = String(data: data, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }
}

// MARK: - 使用示例

/*
 // 1. 定义模型（使用 Codable）
 struct User: Codable {
     var name: String
     var age: Int
     var email: String?
     
     // 可选：自定义键映射
     enum CodingKeys: String, CodingKey {
         case name
         case age
         case email
     }
 }

 // 2. 从字典创建模型
 let dict: [String: Any] = [
     "name": "张三",
     "age": 25,
     "email": "zhangsan@example.com"
 ]

 if let user = User.decode(from: dict) {
     print(user.name)  // 张三
     print(user.age)   // 25
 }

 // 3. 批量转换
 let dicts: [[String: Any]] = [
     ["name": "张三", "age": 25],
     ["name": "李四", "age": 30]
 ]

 let users: [User] = User.decode(from: dicts)
 print(users.count)  // 2

 // 4. 模型转字典
 let user = User(name: "张三", age: 25, email: "zhangsan@example.com")
 if let dict = user.toDictionary() {
     print(dict)  // ["name": "张三", "age": 25, "email": "zhangsan@example.com"]
 }

 // 5. 模型转 JSON 字符串
 if let jsonString = user.toJSONString() {
     print(jsonString)  // {"name":"张三","age":25,"email":"zhangsan@example.com"}
 }

 // 6. 从 JSON 字符串创建模型
 let jsonString = """
 {
     "name": "张三",
     "age": 25,
     "email": "zhangsan@example.com"
 }
 """

 if let user = User.decode(from: jsonString) {
     print(user.name)  // 张三
 }

 // 7. 嵌套模型
 struct Address: Codable {
     var city: String
     var street: String
 }

 struct UserWithAddress: Codable {
     var name: String
     var age: Int
     var address: Address
 }

 let dict2: [String: Any] = [
     "name": "张三",
     "age": 25,
     "address": [
         "city": "北京",
         "street": "长安街"
     ]
 ]

 if let user = UserWithAddress.decode(from: dict2) {
     print(user.address.city)  // 北京
 }

 // 8. 可选属性和默认值
 struct UserWithDefaults: Codable {
     var name: String
     var age: Int = 0  // 默认值
     var email: String?  // 可选
     var isVIP: Bool = false  // 默认值
 }

 let dict3: [String: Any] = ["name": "张三"]
 if let user = UserWithDefaults.decode(from: dict3) {
     print(user.name)   // 张三
     print(user.age)    // 0（默认值）
     print(user.email)  // nil
     print(user.isVIP)  // false（默认值）
 }

 // 9. 自定义解码逻辑
 struct CustomUser: Codable {
     var name: String
     var age: Int
     var displayName: String  // 计算属性
     
     enum CodingKeys: String, CodingKey {
         case name
         case age
     }
     
     init(from decoder: Decoder) throws {
         let container = try decoder.container(keyedBy: CodingKeys.self)
         name = try container.decode(String.self, forKey: .name)
         age = try container.decode(Int.self, forKey: .age)
         displayName = "\(name) (\(age)岁)"  // 自定义逻辑
     }
 }

 // 10. 类型转换（宽松模式）
 struct FlexibleUser: Codable {
     var name: String
     var age: Int
     
     enum CodingKeys: String, CodingKey {
         case name
         case age
     }
     
     init(from decoder: Decoder) throws {
         let container = try decoder.container(keyedBy: CodingKeys.self)
         
         // 宽松的字符串解码
         if let nameStr = try? container.decode(String.self, forKey: .name) {
             name = nameStr
         } else if let nameInt = try? container.decode(Int.self, forKey: .name) {
             name = String(nameInt)
         } else {
             name = ""
         }
         
         // 宽松的整数解码
         if let ageInt = try? container.decode(Int.self, forKey: .age) {
             age = ageInt
         } else if let ageStr = try? container.decode(String.self, forKey: .age),
                   let ageInt = Int(ageStr) {
             age = ageInt
         } else {
             age = 0
         }
     }
 }

 ============================================
 总结：Codable vs HEEntity
 ============================================
 
 Codable 优点：
 ✅ 纯 Swift，类型安全
 ✅ 编译时检查，减少运行时错误
 ✅ 性能更好（无需 OC 运行时）
 ✅ 支持嵌套模型
 ✅ 自动生成编解码代码
 ✅ 可以转为 JSON 字符串
 
 Codable 缺点：
 ❌ 需要定义所有属性
 ❌ 不支持动态属性
 ❌ 类型必须匹配（可通过自定义 init 解决）
 
 HEEntity 优点：
 ✅ 自动映射，无需定义所有属性
 ✅ 支持动态属性
 ✅ 类型自动转换（NSNumber → String）
 ✅ 保留原始字典（meta）
 
 HEEntity 缺点：
 ❌ 依赖 OC 运行时
 ❌ 运行时错误风险
 ❌ 性能稍差
 
 推荐：
 - 新项目 → Codable
 - 混编项目 → HEEntity
 - 需要动态属性 → HEEntity
 */
