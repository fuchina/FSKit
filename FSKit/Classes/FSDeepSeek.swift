//
//  FSDeepSeek.swift
//  FSKit
//

import Foundation

public enum FSDeepSeekError: LocalizedError {
    case invalidURL
    case unauthorized
    case httpError(Int, String)
    case emptyResponse
    case decodeFailed

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "DeepSeek URL 无效"
        case .unauthorized:
            return "DeepSeek 鉴权失败，请检查 API Key"
        case .httpError(let code, let message):
            return "DeepSeek 请求失败(\(code)): \(message)"
        case .emptyResponse:
            return "DeepSeek 返回为空"
        case .decodeFailed:
            return "DeepSeek 数据解析失败"
        }
    }
}

public struct FSDeepSeekMessage: Codable {
    public let role: String
    public let content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

public struct FSDeepSeekThinking: Codable {
    public let type: String

    public init(type: String = "enabled") {
        self.type = type
    }
}

public struct FSDeepSeekExtraBody: Codable {
    public let thinking: FSDeepSeekThinking?

    public init(thinking: FSDeepSeekThinking? = nil) {
        self.thinking = thinking
    }
}

public struct FSDeepSeekChatRequest: Codable {
    public let model: String
    public let messages: [FSDeepSeekMessage]
    public let reasoning_effort: String?
    public let enable_search: Bool
    public let extra_body: FSDeepSeekExtraBody?

    public init(
        model: String,
        messages: [FSDeepSeekMessage],
        reasoningEffort: String? = nil,
        enableSearch: Bool = true,
        extraBody: FSDeepSeekExtraBody? = nil
    ) {
        self.model = model
        self.messages = messages
        self.reasoning_effort = reasoningEffort
        self.enable_search = enableSearch
        self.extra_body = extraBody
    }
}

public struct FSDeepSeekChatResponse: Codable {
    public struct Choice: Codable {
        public struct Message: Codable {
            public let role: String?
            public let content: String?
        }

        public let index: Int?
        public let message: Message?
        public let finish_reason: String?
    }

    public let id: String?
    public let object: String?
    public let model: String?
    public let created: TimeInterval?
    public let choices: [Choice]?
}

public final class FSDeepSeek {

    public typealias Completion = (Result<FSDeepSeekChatResponse, Error>) -> Void

    public static let shared = FSDeepSeek()

    public var apiKey: String = ""
    public var baseURL: String = "https://api.deepseek.com"
    public var defaultModel: String = "deepseek-v4-pro"

    private init() {}

    public func configure(apiKey: String, baseURL: String = "https://api.deepseek.com", defaultModel: String = "deepseek-v4-pro") {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.defaultModel = defaultModel
    }

    public func chat(
        messages: [FSDeepSeekMessage],
        model: String? = nil,
        reasoningEffort: String? = "high",
        enableSearch: Bool = true,
        enableThinking: Bool = true,
        completion: @escaping Completion
    ) {
        let body = FSDeepSeekChatRequest(
            model: model ?? defaultModel,
            messages: messages,
            reasoningEffort: reasoningEffort,
            enableSearch: enableSearch,
            extraBody: enableThinking ? FSDeepSeekExtraBody(thinking: FSDeepSeekThinking()) : nil
        )
        chat(request: body, completion: completion)
    }

    public func chat(request: FSDeepSeekChatRequest, completion: @escaping Completion) {
        guard let url = URL(string: "\(baseURL)/v1/chat/completions") else {
            completion(.failure(FSDeepSeekError.invalidURL))
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(FSDeepSeekError.emptyResponse))
                }
                return
            }

            let responseData = data ?? Data()
            if httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    completion(.failure(FSDeepSeekError.unauthorized))
                }
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: responseData, encoding: .utf8) ?? "unknown"
                DispatchQueue.main.async {
                    completion(.failure(FSDeepSeekError.httpError(httpResponse.statusCode, message)))
                }
                return
            }

            do {
                let model = try JSONDecoder().decode(FSDeepSeekChatResponse.self, from: responseData)
                DispatchQueue.main.async {
                    completion(.success(model))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(FSDeepSeekError.decodeFailed))
                }
            }
        }.resume()
    }

    public func firstContent(from response: FSDeepSeekChatResponse) -> String {
        return response.choices?.first?.message?.content ?? ""
    }
}
