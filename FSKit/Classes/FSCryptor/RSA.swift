//
//  RSA.swift
//  FSCryptor
//
//  Translated from Objective-C to Swift.
//

import Foundation
import Security

open class RSA: NSObject {

    public static func encryptString(_ str: String, publicKey pubKey: String) -> String {
        guard let data = str.data(using: .utf8),
              let encrypted = encryptData(data, publicKey: pubKey) else {
            return ""
        }
        return encrypted.base64EncodedString(options: [])
    }

    public static func encryptData(_ data: Data, publicKey pubKey: String) -> Data? {
        guard let keyRef = addPublicKey(pubKey) else {
            return nil
        }
        return encryptData(data, withKeyRef: keyRef)
    }

    public static func encryptString(_ str: String, privateKey privKey: String) -> String {
        guard let data = str.data(using: .utf8),
              let encrypted = encryptData(data, privateKey: privKey) else {
            return ""
        }
        return encrypted.base64EncodedString(options: [])
    }

    public static func encryptData(_ data: Data, privateKey privKey: String) -> Data? {
        guard let keyRef = addPrivateKey(privKey) else {
            return nil
        }
        return encryptData(data, withKeyRef: keyRef)
    }

    public static func decryptString(_ str: String, publicKey pubKey: String) -> String {
        guard let data = Data(base64Encoded: str, options: .ignoreUnknownCharacters),
              let decrypted = decryptData(data, publicKey: pubKey) else {
            return ""
        }
        return String(data: decrypted, encoding: .utf8) ?? ""
    }

    public static func decryptData(_ data: Data, publicKey pubKey: String) -> Data? {
        guard let keyRef = addPublicKey(pubKey) else {
            return nil
        }
        return decryptData(data, withKeyRef: keyRef)
    }

    public static func decryptString(_ str: String, privateKey privKey: String) -> String {
        guard let data = Data(base64Encoded: str, options: .ignoreUnknownCharacters),
              let decrypted = decryptData(data, privateKey: privKey) else {
            return ""
        }
        return String(data: decrypted, encoding: .utf8) ?? ""
    }

    public static func decryptData(_ data: Data, privateKey privKey: String) -> Data? {
        guard let keyRef = addPrivateKey(privKey) else {
            return nil
        }
        return decryptData(data, withKeyRef: keyRef)
    }

    private static func encryptData(_ data: Data, withKeyRef keyRef: SecKey) -> Data? {
        let srcbuf = [UInt8](data)
        let blockSize = SecKeyGetBlockSize(keyRef)
        let srcBlockSize = blockSize - 11

        var result = Data()
        var idx = 0
        while idx < srcbuf.count {
            let dataLen = min(srcbuf.count - idx, srcBlockSize)
            let chunk = Data(srcbuf[idx..<(idx + dataLen)])

            guard let encrypted = SecKeyCreateEncryptedData(
                keyRef,
                .rsaEncryptionPKCS1,
                chunk as CFData,
                nil
            ) as Data? else {
                return nil
            }
            result.append(encrypted)
            idx += srcBlockSize
        }

        return result
    }

    private static func decryptData(_ data: Data, withKeyRef keyRef: SecKey) -> Data? {
        let srcbuf = [UInt8](data)
        let blockSize = SecKeyGetBlockSize(keyRef)
        let srcBlockSize = blockSize

        var result = Data()
        var outbuf = [UInt8](repeating: 0, count: blockSize)

        var idx = 0
        while idx < srcbuf.count {
            let dataLen = min(srcbuf.count - idx, srcBlockSize)
            let chunk = Data(srcbuf[idx..<(idx + dataLen)])

            guard let decrypted = SecKeyCreateDecryptedData(
                keyRef,
                .rsaEncryptionRaw,
                chunk as CFData,
                nil
            ) as Data? else {
                return nil
            }
            outbuf = [UInt8](decrypted)
            let outLen = outbuf.count

            var idxFirstZero = -1
            var idxNextZero = outLen
            for i in 0..<outLen where outbuf[i] == 0 {
                if idxFirstZero < 0 {
                    idxFirstZero = i
                } else {
                    idxNextZero = i
                    break
                }
            }

            let start = max(idxFirstZero + 1, 0)
            let end = max(idxNextZero, start)
            if start < end {
                result.append(contentsOf: outbuf[start..<end])
            }

            idx += srcBlockSize
        }

        return result
    }

    private static func addPublicKey(_ key: String) -> SecKey? {
        let cleanedKey = cleanKey(key, markers: [("-----BEGIN PUBLIC KEY-----", "-----END PUBLIC KEY-----")])
        guard let decoded = Data(base64Encoded: cleanedKey, options: .ignoreUnknownCharacters),
              let stripped = stripPublicKeyHeader(decoded) else {
            return nil
        }
        return addKey(stripped, tag: "RSAUtil_PubKey", keyClass: kSecAttrKeyClassPublic)
    }

    private static func addPrivateKey(_ key: String) -> SecKey? {
        let cleanedKey = cleanKey(
            key,
            markers: [
                ("-----BEGIN RSA PRIVATE KEY-----", "-----END RSA PRIVATE KEY-----"),
                ("-----BEGIN PRIVATE KEY-----", "-----END PRIVATE KEY-----")
            ]
        )
        guard let decoded = Data(base64Encoded: cleanedKey, options: .ignoreUnknownCharacters),
              let stripped = stripPrivateKeyHeader(decoded) else {
            return nil
        }
        return addKey(stripped, tag: "RSAUtil_PrivKey", keyClass: kSecAttrKeyClassPrivate)
    }

    private static func addKey(_ data: Data, tag: String, keyClass: CFString) -> SecKey? {
        let tagData = tag.data(using: .utf8) ?? Data()
        var query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrApplicationTag: tagData
        ]

        SecItemDelete(query as CFDictionary)

        query[kSecValueData] = data
        query[kSecAttrKeyClass] = keyClass
        query[kSecReturnPersistentRef] = true

        var persistKey: CFTypeRef?
        let status = SecItemAdd(query as CFDictionary, &persistKey)
        guard status == errSecSuccess || status == errSecDuplicateItem else {
            return nil
        }

        query.removeValue(forKey: kSecValueData)
        query.removeValue(forKey: kSecReturnPersistentRef)
        query[kSecReturnRef] = true

        var keyRef: CFTypeRef?
        let copyStatus = SecItemCopyMatching(query as CFDictionary, &keyRef)
        guard copyStatus == errSecSuccess else {
            return nil
        }

        let key = keyRef as! SecKey
        return key
    }

    private static func cleanKey(_ key: String, markers: [(String, String)]) -> String {
        var result = key
        for (begin, end) in markers {
            if let startRange = result.range(of: begin),
               let endRange = result.range(of: end) {
                result = String(result[startRange.upperBound..<endRange.lowerBound])
                break
            }
        }

        return result
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\t", with: "")
            .replacingOccurrences(of: " ", with: "")
    }

    private static func stripPublicKeyHeader(_ keyData: Data) -> Data? {
        let bytes = [UInt8](keyData)
        guard !bytes.isEmpty else { return nil }

        var idx = 0
        guard bytes[safe: idx] == 0x30 else { return nil }
        idx += 1

        guard let current = bytes[safe: idx] else { return nil }
        if current > 0x80 {
            idx += Int(current - 0x80) + 1
        } else {
            idx += 1
        }

        let seqiod: [UInt8] = [0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00]
        guard idx + seqiod.count <= bytes.count,
              Array(bytes[idx..<(idx + seqiod.count)]) == seqiod else {
            return nil
        }
        idx += seqiod.count

        guard bytes[safe: idx] == 0x03 else { return nil }
        idx += 1

        guard let lengthByte = bytes[safe: idx] else { return nil }
        if lengthByte > 0x80 {
            idx += Int(lengthByte - 0x80) + 1
        } else {
            idx += 1
        }

        guard bytes[safe: idx] == 0x00 else { return nil }
        idx += 1

        guard idx < bytes.count else { return nil }
        return Data(bytes[idx...])
    }

    private static func stripPrivateKeyHeader(_ keyData: Data) -> Data? {
        let bytes = [UInt8](keyData)
        let len = bytes.count
        guard len > 22 else { return nil }

        var idx = 22
        guard bytes[safe: idx] == 0x04 else { return nil }
        idx += 1

        guard let firstLength = bytes[safe: idx] else { return nil }
        idx += 1

        let contentLength: Int
        if firstLength & 0x80 == 0 {
            contentLength = Int(firstLength & 0x7f)
        } else {
            let byteCount = Int(firstLength & 0x7f)
            guard byteCount + idx <= len else { return nil }

            var accum = 0
            for offset in 0..<byteCount {
                accum = (accum << 8) + Int(bytes[idx + offset])
            }
            idx += byteCount
            contentLength = accum
        }

        guard idx + contentLength <= len else { return nil }
        return keyData.subdata(in: idx..<(idx + contentLength))
    }
}

private extension Array where Element == UInt8 {
    subscript(safe index: Int) -> UInt8? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}
