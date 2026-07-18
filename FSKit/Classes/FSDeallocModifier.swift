//
//  FSDeallocModifier.swift
//  FSKit
//
//  对齐 FSBaseController 行为：
//  - deinit 时发送 FS_BE_DEBUG_NOTIFICATION（释放通知）
//  - onDisappear 后 5 秒未释放则发送 FS_BE_LEAK_NOTIFICATION（疑似泄漏）
//  用法：SomeView().debugDealloc("SomeView")
//

import SwiftUI

/// 释放探针：SwiftUI View 被移出视图树且 @State 释放时，deinit 发送通知。
/// 同时内置泄漏检测：onDisappear 后 5 秒若仍存活，发送 FS_BE_LEAK_NOTIFICATION。
/// 若期间 onAppear 再次触发（被遮盖后重新可见），自动取消泄漏检测。
private final class _FSDeallocTracker {
    let viewName: String
    private var leakCheckItem: DispatchWorkItem?

    init(viewName: String) {
        self.viewName = viewName
    }

    /// onDisappear 时调用：5 秒后若 self 仍存活 → 疑似泄漏
    func scheduleLeakCheck() {
        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            NotificationCenter.default.post(
                name: NSNotification.Name(FS_BE_LEAK_NOTIFICATION),
                object: "疑似内存泄漏：\(self.viewName) 未释放"
            )
        }
        leakCheckItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: item)
    }

    /// onAppear 再次触发时调用：视图重新可见，取消泄漏检测
    func cancelLeakCheck() {
        leakCheckItem?.cancel()
        leakCheckItem = nil
    }

    deinit {
        leakCheckItem?.cancel()
        let message = "\(viewName) deinit"
        NotificationCenter.default.post(
            name: NSNotification.Name(FS_BE_DEBUG_NOTIFICATION),
            object: message
        )
    }
}

/// ViewModifier：在视图 body 内挂载一个探针，视图存活期间探针被 @State 持有，
/// 视图释放时探针随之释放，触发 deinit 通知；若未按时释放则触发泄漏通知。
private struct _FSDeallocViewModifier: ViewModifier {
    let viewName: String
    @State private var tracker: _FSDeallocTracker?

    func body(content: Content) -> some View {
        content
            .onAppear {
                if tracker == nil {
                    tracker = _FSDeallocTracker(viewName: viewName)
                } else {
                    // 视图重新可见（如被 push 的页面 pop 回来、sheet dismiss），取消之前的泄漏检测
                    tracker?.cancelLeakCheck()
                }
            }
            .onDisappear {
                // 视图不可见，启动泄漏检测定时器
                tracker?.scheduleLeakCheck()
            }
    }
}

extension View {
    /// 视图释放时发送 FS_BE_DEBUG_NOTIFICATION，对齐 FSBaseController.deinit 行为。
    /// 若 onDisappear 后 5 秒仍未释放，发送 FS_BE_LEAK_NOTIFICATION（对齐 checkForLeakIfLeaving）。
    public func debugDealloc(_ viewName: String) -> some View {
        modifier(_FSDeallocViewModifier(viewName: viewName))
    }
}
