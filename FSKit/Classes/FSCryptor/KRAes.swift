//
//  KRAes.swift
//  FSCryptor
//
//  Translated from Objective-C to Swift.
//

import Foundation
import CommonCrypto

open class KRAes: NSObject {

    public static func encryptAES256(with data: Data, password key: String) -> Data? {
        aes256(with: data, key: key, isEncrypt: true)
    }

    public static func decryptAES256(with data: Data, password key: String) -> Data? {
        aes256(with: data, key: key, isEncrypt: false)
    }

    private static func aes256(with data: Data, key password: String, isEncrypt: Bool) -> Data? {
        var keyPattern = [CChar](repeating: 0, count: kCCKeySizeAES256 + 1)
        if let keyData = password.data(using: .utf8) {
            let copyCount = min(keyData.count, keyPattern.count - 1)
            keyPattern.withUnsafeMutableBytes { buffer in
                keyData.withUnsafeBytes { keyBuffer in
                    guard let destination = buffer.baseAddress,
                          let source = keyBuffer.baseAddress else {
                        return
                    }
                    destination.copyMemory(from: source, byteCount: copyCount)
                }
            }
        }

        let bufferSize = data.count + kCCBlockSizeAES128
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var totalBytes: size_t = 0

        let status = data.withUnsafeBytes { dataBytes in
            CCCrypt(
                isEncrypt ? CCOperation(kCCEncrypt) : CCOperation(kCCDecrypt),
                CCAlgorithm(kCCAlgorithmAES128),
                CCOptions(kCCOptionPKCS7Padding | kCCOptionECBMode),
                keyPattern,
                kCCKeySizeAES256,
                nil,
                dataBytes.baseAddress,
                data.count,
                &buffer,
                bufferSize,
                &totalBytes
            )
        }

        guard status == kCCSuccess else {
            return nil
        }

        return Data(buffer.prefix(totalBytes))
    }
}
