//
//  FSURLSessionCore.swift
//  FSKit
//
//  Translated from Objective-C to Swift
//
//  2026-10-15 Swift 6：两个方法的回调闭包都不是 Sendable，直接捕获会被区域隔离分析
//  拒绝送进 `DispatchQueue.main.async`。统一用 `FSUncheckedSendable` 包一层 ——
//  对外签名与全部调用点保持不变，行为同 Swift 5 模式。
//

import Foundation

public enum FSURLSessionManager {
    
    // MARK: - GET Request
    public static func sessionGet(_ urlString: String, success: ((Data?) -> Void)?, fail: (() -> Void)?) {
        guard !urlString.isEmpty, let url = URL(string: urlString) else {
            fail?()
            return
        }
        
        let successBox = FSUncheckedSendable(success)
        let failBox = FSUncheckedSendable(fail)
        
        let session = URLSession.shared
        let task = session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    #if DEBUG
                    print(error.localizedDescription)
                    #endif
                    failBox.value?()
                    return
                }
                successBox.value?(data)
            }
        }
        task.resume()
    }
    
    // MARK: - POST Request
    public static func sessionPost(_ urlString: String, parameters: [String: String]? = nil, success: ((Data?) -> Void)?, fail: (() -> Void)?) {
        guard !urlString.isEmpty, let url = URL(string: urlString) else {
            fail?()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        if let parameters = parameters {
            let bodyString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            request.httpBody = bodyString.data(using: .utf8)
        }
        
        let successBox = FSUncheckedSendable(success)
        let failBox = FSUncheckedSendable(fail)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    #if DEBUG
                    print(error.localizedDescription)
                    #endif
                    failBox.value?()
                    return
                }
                successBox.value?(data)
            }
        }
        task.resume()
    }
}
