//
//  FSDeallocModifier.swift
//  FSKit
//
//  - deinit 时发送 FS_BE_DEBUG_NOTIFICATION（释放通知）
//  - 泄漏检测由外部触发：FSLeakDetector.startCheck(for:)（如 NavigationStack path 变短时）
//  - tracker deinit 自动取消对应的泄漏检测定时器
//  用法：SomeView().debugDealloc("SomeView")
//        父视图 pop 时：FSLeakDetector.startCheck(for: "SomeView")
//

import SwiftUI

// MARK: - FSLeakDetector

/// 泄漏检测器：外部触发（如 NavigationStack path 变短、sheet dismiss）启动 5 秒定时器，
/// tracker deinit 时取消定时器。若定时器触发 → 未释放 → 疑似泄漏。
public final class FSLeakDetector {
    @MainActor private static var timers: [String: DispatchWorkItem] = [:]

    /// 挂过 `debugDealloc` 的页面名（进程内累计）；未登记的页面不检测，避免误报
    @MainActor private static var registered: Set<String> = []

    /// 由 `debugDealloc` 在 onAppear 时调用
    @MainActor
    public static func register(_ viewName: String) {
        registered.insert(viewName)
    }

    /// 启动泄漏检测：5 秒后若对应 tracker 仍未 deinit → 发送 FS_BE_LEAK_NOTIFICATION
    @MainActor
    public static func startCheck(for viewName: String) {
        guard registered.contains(viewName) else { return }
        timers[viewName]?.cancel()
        let item = DispatchWorkItem {
            let msg = "疑似内存泄漏：\(viewName) 未释放"
            NotificationCenter.default.post(
                name: NSNotification.Name(FS_BE_LEAK_NOTIFICATION),
                object: msg
            )
            print("\(msg)")
            // Swift 6：本 block 由 `main.asyncAfter` 派发，必然在主线程执行。
            // 原来的 `Task { @MainActor in … }` 会让编译器把整个 DispatchWorkItem
            //（非 Sendable）判为跨域发送。改为同步断言主线程，语义等价。
            MainActor.assumeIsolated { _ = timers.removeValue(forKey: viewName) }
        }
        timers[viewName] = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: item)
    }

    /// 取消泄漏检测：tracker deinit 时调用
    @MainActor
    public static func cancelCheck(for viewName: String) {
        timers[viewName]?.cancel()
        timers.removeValue(forKey: viewName)
    }
}

// MARK: - Tracker

/// 释放探针：SwiftUI View 被移出视图树且 @State 释放时，deinit 发送通知。
/// 同时取消 FSLeakDetector 中对应的外部泄漏检测定时器。
private final class _FSDeallocTracker {
    let viewName: String

    init(viewName: String) {
        self.viewName = viewName
    }

    deinit {
        let name = viewName
        DispatchQueue.main.async {
            FSLeakDetector.cancelCheck(for: name)
        }
        NotificationCenter.default.post(
            name: NSNotification.Name(FS_BE_DEBUG_NOTIFICATION),
            object: "\(name) deinit"
        )
    }
}

// MARK: - ViewModifier

private struct _FSDeallocViewModifier: ViewModifier {
    let viewName: String
    @State private var tracker: _FSDeallocTracker?

    func body(content: Content) -> some View {
        content.onAppear {
            FSLeakDetector.register(viewName)
            if tracker == nil {
                tracker = _FSDeallocTracker(viewName: viewName)
            }
        }
    }
}

// MARK: - pop 时自动启动检测

/// 挂在导航栈上：路径变短时，对刚被弹出的页面启动 5 秒泄漏检测。
/// 只对登记过的（即挂过 `debugDealloc` 的）页面生效，其余静默跳过。
struct FSLeakCheckOnPopModifier: ViewModifier {
    let routes: [FSPageRoute]

    func body(content: Content) -> some View {
        content.onChange(of: routes) { old, new in
            let kept = Set(new.map(\.uid))
            let names = old.filter { !kept.contains($0.uid) }.map(\.name)
            guard names.isEmpty == false else { return }
            // onChange 在主线程回调；assumeIsolated 让编译器认可 MainActor 隔离
            MainActor.assumeIsolated {
                for name in names {
                    FSLeakDetector.startCheck(for: name)
                }
            }
        }
    }
}

extension View {
    /// 导航栈专用：栈路径变化时自动为被弹出的页面打点
    func fsLeakCheckOnPop(_ routes: [FSPageRoute]) -> some View {
        modifier(FSLeakCheckOnPopModifier(routes: routes))
    }
}

extension View {
    /// 泄漏检测由外部触发：在视图被 pop/dismiss 时调用 `FSLeakDetector.startCheck(for:)`，
    /// tracker deinit 会自动取消检测。5 秒未释放则发送 FS_BE_LEAK_NOTIFICATION。
    public func debugDealloc(_ viewName: String) -> some View {
        modifier(_FSDeallocViewModifier(viewName: viewName))
    }
}
