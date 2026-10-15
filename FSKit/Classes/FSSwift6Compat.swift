//
//  FSSwift6Compat.swift
//  FSKit
//
//  Swift 6 语言模式（严格并发检查）的兼容声明集中在这里。
//
//  【为什么单独开一个文件】
//  `FSNavRouter` 定义在 `FSPageReturnHighlight.swift` 内，该文件承载分页返回高亮的
//  敏感逻辑，约定不改动其本体；但其中：
//
//      private struct FSNavRouterKey: EnvironmentKey {
//          static let defaultValue = FSNavRouter()
//      }
//
//  在 Swift 6 模式下报错：
//      static property 'defaultValue' is not concurrency-safe because
//      non-'Sendable' type 'FSNavRouter' may have shared mutable state
//
//  同一模块内允许在任意文件补充一致性声明，因此在这里补 `@unchecked Sendable`，
//  从而不必改动 FSPageReturnHighlight.swift。
//
//  【语义】
//  `FSNavRouter` 的实例由 `FSPushStack` 的 `@StateObject` 在主隔离域持有与修改。
//  该声明与 Swift 5 模式下的行为完全一致 —— 此前同样没有任何并发检查，
//  这里只是把「已知共享状态、由使用方保证访问时机」这一事实显式写出来。
//

import Foundation

// MARK: - 通用工具

/// 把非 `Sendable` 的值临时包成 `Sendable`，用于「跨隔离域传递、但线程安全由调用方保证」的场景。
///
/// 典型用途：老式「后台线程收数据 → 主线程回调」的 API，回调闭包本身不是 `Sendable`
/// （可能捕获了调用方的状态），Swift 6 的区域隔离分析会拒绝把它送进
/// `DispatchQueue.main.async` / `Task { @MainActor in }`。
///
/// 用本类型包一层后，**公共 API 签名与所有调用点都不变**，行为与 Swift 5 模式完全一致。
public struct FSUncheckedSendable<T>: @unchecked Sendable {
    public let value: T

    public init(_ value: T) { self.value = value }
}

// MARK: - 补充一致性声明

/// 分页返回高亮中心。
///
/// 定义在 `FSPageReturnHighlight.swift` 内 —— 该文件按约定不改动本体，故一致性声明补在这里。
/// 它的 `resetIfReturning()` 可从任意来源并发调用，内部用 `DispatchQueue.main.async`
/// 回主线程；Swift 6 要求这样的类显式声明可跨隔离域传递。
extension FSPageReturnHighlight: @unchecked Sendable {}

