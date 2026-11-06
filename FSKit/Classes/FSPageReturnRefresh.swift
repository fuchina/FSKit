//
//  FSPageReturnRefresh.swift
//  FSKit
//
//  「本页从更深一层返回」的统一触发点 —— **纯 SwiftUI 实现，不依赖 UIKit 生命周期探针**。
//
//  替代原先的 `FSReturnProbe`（`UIViewControllerRepresentable` + `viewWillAppear`）：
//  那条链在 `NavigationStack` 的 pop 场景里**不保证触发**（曾导致 AAScreen 购买后返回不刷新），
//  而且 `viewWillAppear` 是在 pop 动画**一开始**回调 —— 数据在转场过程中已经换完，
//  人回到页面上看到的是"本来就这样"，没有刷新过的观感。
//
//  为什么只认 `router.path`：`NavigationStack(path:)` 是**双向绑定**，系统返回按钮、左滑手势、
//  `pop()` / `popTo` / `popToRoot` 每一条路径都必须从 path 里移除元素 ⇒ 变更必然可观察。
//  这是 SwiftUI 真正承诺的东西（数据变化），而不是它从未承诺的 appearance 时机。
//
//  「转场结束」纯 SwiftUI 拿不到（苹果没有这个概念）；系统 push / pop 转场 0.35s，
//  故用该常量做缓冲：动画落地后再换数，眼睛能看到数字跳变。常量收敛在这里一处。
//

import Foundation
import SwiftUI

// MARK: - 公共 API

public extension View {

    /// 本页被重新显示（子页 pop 回来）时执行一次，**等转场结束之后**才真正执行 ——
    /// 与原来 UIKit 的 `viewDidAppear` 取数一致。
    ///
    /// - Parameters:
    ///   - includeFirstAppear: 首次出现是否也回调（默认否；首次取数请放 `onAppear` / `task`）。
    ///                         首次是**立即**回调，不走延迟 —— 页面刚进来就要数据。
    ///   - action: 回到本页时执行；幂等性由页面自己的标记保证（`needRefresh` / `dirty` 之类）。
    func fsOnReturn(includeFirstAppear: Bool = false,
                    _ action: @escaping () -> Void) -> some View {
        modifier(FSPageReturnModifier(delay: 0.35,
                                      includeFirst: includeFirstAppear,
                                      action: action))
    }

    /// 同上，语义更明确（「页面返回」而非「视图重现」），可自定义延迟。
    ///
    /// - Parameter delay: 转场结束后的缓冲，默认 0.35s（系统 push / pop 转场时长）。
    ///                    要跟转场**并行**的动效（如点击高亮淡出）传 0 ⇒ 下一帧执行。
    func fsOnPageReturn(delay: TimeInterval = 0.35,
                        _ action: @escaping () -> Void) -> some View {
        modifier(FSPageReturnModifier(delay: delay, includeFirst: false, action: action))
    }
}

// MARK: - 实现

/// 用 `router.path.count` 判断「从更深一层回到本页」：
/// `onAppear` 时记下本页深度，path 回到该深度且刚从更深层降下来 ⇒ 触发。
@MainActor
private struct FSPageReturnModifier: ViewModifier {

    @Environment(\.fsNavRouter) private var router

    let delay: TimeInterval
    let includeFirst: Bool
    let action: () -> Void

    /// 本页在栈中的深度（首次出现时记录；`path.count` 回到它 = 本页重新可见）
    @State private var depth = -1
    /// 待执行的延迟回调（重复触发时取消重排，保证只跑一次）
    @State private var work: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard depth < 0 else { return }
                // push 时 path 已 append 本页 ⇒ 此时拿到的就是本页序号
                depth = router.path.count
                if includeFirst { action() }
            }
            // `@Observable` 下 body 里读 `router.path.count` 即参与观察，`.onChange` 能收到事件
            .onChange(of: router.path.count) { old, new in
                // 只有「从更深的一层回到本页」才算返回；push 出去（new > depth）不算
                guard depth >= 0, new == depth, old > depth else { return }
                schedule()
            }
            .onDisappear { work?.cancel() }
    }

    /// ★ 2026-11-06：`DispatchWorkItem` → `Task`；取消时 `Task.sleep` 抛出即返回，
    /// 与 `item.cancel()` 语义一致，省掉 `MainActor.assumeIsolated` 这层桥。
    private func schedule() {
        work?.cancel()

        // action 可能捕获页面 store（非 Sendable 闭包），装箱后跨隔离域传递
        let box = FSUncheckedSendable(action)

        // 延时先拷出来：`Task` 闭包里直接写 `delay` 会要求显式 `self.`（struct 的实例属性）
        let d = delay

        if d > 0 {
            work = Task { @MainActor in
                do { try await Task.sleep(for: .seconds(d)) } catch { return }
                box.value()
            }
        } else {
            // 0 = 下一帧（与转场并行，用于高亮淡出这类动画）
            work = Task { @MainActor in box.value() }
        }
    }
}
