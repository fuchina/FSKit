//
//  FSCryptor.swift
//  FSCryptor
//
//  Created by FudonFuchina on 2017/6/1.
//  Translated to Swift
//

import Foundation
import CommonCrypto

open class FSCryptor: NSObject {
    
    // MARK: - AES256 加解密
    
    /// AES256 加密字符串
    public static func aes256EncryptString(_ content: String?, password: String?) -> String {
        guard let content = content, let password = password else { return "" }
        guard let data = content.data(using: .utf8) else { return "" }
        guard let encryptData = KRAes.encryptAES256(with: data, password: password) else { return "" }
        return encryptData.base64EncodedString(options: .endLineWithLineFeed)
    }
    
    /// AES256 解密字符串
    public static func aes256DecryptString(_ str: String?, password: String?) -> String {
        guard let str = str, let password = password, str != "(null)" else { return "" }
        guard let data = Data(base64Encoded: str, options: .ignoreUnknownCharacters) else { return "" }
        guard let decryptData = KRAes.decryptAES256(with: data, password: password) else { return "" }
        return String(data: decryptData, encoding: .utf8) ?? ""
    }
    
    // MARK: - 3DES 加解密
    
    /// 3DES 加密
    public static func encryptUseDES(_ plainText: String?, key: String?) -> String {
        
        guard let plainText = plainText, let key = key else { return "" }
        guard let textData = plainText.data(using: .utf8) else { return "" }
        
        var buffer = [UInt8](repeating: 0, count: 1024)
        let iv: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
        var numBytesEncrypted: size_t = 0
        
        let cryptStatus = textData.withUnsafeBytes { textBytes in
            key.withCString { keyBytes in
                CCCrypt(
                    CCOperation(kCCEncrypt),
                    CCAlgorithm(kCCAlgorithmDES),
                    CCOptions(kCCOptionPKCS7Padding),
                    keyBytes,
                    kCCKeySizeDES,
                    iv,
                    textBytes.baseAddress,
                    textData.count,
                    &buffer,
                    1024,
                    &numBytesEncrypted
                )
            }
        }
        
        if cryptStatus == kCCSuccess {
            let data = Data(bytes: buffer, count: numBytesEncrypted)
            if let encodedData = GTMBase64.encode(data) {
                return String(data: encodedData, encoding: .utf8) ?? ""
            }
        }
        
        return ""
    }
    
    /// 3DES 解密
    public static func decryptUseDES(_ cipherText: String?, key: String?) -> String {
        
        guard let cipherText = cipherText, let key = key else { return "" }
        guard let cipherData = GTMBase64.decode(cipherText) else { return "" }
        
        var buffer = [UInt8](repeating: 0, count: 1024)
        let iv: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
        var numBytesDecrypted: size_t = 0
        
        let cryptStatus = cipherData.withUnsafeBytes { cipherBytes in
            key.withCString { keyBytes in
                CCCrypt(
                    CCOperation(kCCDecrypt),
                    CCAlgorithm(kCCAlgorithmDES),
                    CCOptions(kCCOptionPKCS7Padding),
                    keyBytes,
                    kCCKeySizeDES,
                    iv,
                    cipherBytes.baseAddress,
                    cipherData.count,
                    &buffer,
                    1024,
                    &numBytesDecrypted
                )
            }
        }
        
        if cryptStatus == kCCSuccess {
            let data = Data(bytes: buffer, count: numBytesDecrypted)
            return String(data: data, encoding: .utf8) ?? ""
        }
        
        return ""
    }
    
    // MARK: - RSA 加解密
    
    /// RSA 公钥加密
    public static func encryptString(_ str: String?) -> String {
        
        guard let str = str else { return "" }
        guard let publicPath = Bundle.main.path(forResource: "rsa_public_key", ofType: "pem"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: publicPath)),
              let publicKey = String(data: data, encoding: .utf8) else {
            return ""
        }
        
        return RSA.encryptString(str, publicKey: publicKey)
    }
    
    /// RSA 私钥解密
    public static func decryptString(_ str: String?) -> String {
        guard let str = str else { return "" }
        guard let privatePath = Bundle.main.path(forResource: "rsa_private_key", ofType: "pem"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: privatePath)),
              let privateKey = String(data: data, encoding: .utf8) else {
            return ""
        }
        return RSA.decryptString(str, privateKey: privateKey)
    }
}
