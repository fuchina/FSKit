//
//  FSURLSessionCore.swift
//  FSKit
//
//  Translated from Objective-C to Swift
//

import Foundation

public class FSURLSessionManager: NSObject {
    
    // MARK: - GET Request
    public static func sessionGet(_ urlString: String, success: ((Data?) -> Void)?, fail: (() -> Void)?) {
        guard !urlString.isEmpty, let url = URL(string: urlString) else {
            fail?()
            return
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    #if DEBUG
                    print(error.localizedDescription)
                    #endif
                    fail?()
                    return
                }
                success?(data)
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
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    #if DEBUG
                    print(error.localizedDescription)
                    #endif
                    fail?()
                    return
                }
                success?(data)
            }
        }
        task.resume()
    }
}
