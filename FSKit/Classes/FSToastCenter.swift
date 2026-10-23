//
//  FSToastCenter.swift
//  FSKit
//

import SwiftUI

public struct FSToastMessage: Identifiable, Equatable {

    /// 由 center 分配的自增序号，唯一标识一条 toast
    public let id: Int

    public var text: String

    public var duration: Double

    public init(id: Int, text: String, duration: Double) {
        self.id = id
        self.text = text
        self.duration = duration
    }

    /// 兼容旧写法：id 由 center 在 show 时分配，这里给 0
    public init(text: String, duration: Double) {
        self.init(id: 0, text: text, duration: duration)
    }
}

/// 全局 toast 中心：允许**多条同时存在**，每条独立计时、独立消失。
/// 旧版只保留一个槽位（`current`），后来的 toast 会顶掉前一条 —— 已废弃该行为。
@Observable
public final class FSToastCenter: @unchecked Sendable {

    public static let shared = FSToastCenter()

    /// 当前存活的全部 toast，按加入顺序排列（最旧的在前）
    public private(set) var items: [FSToastMessage] = []

    /// 同时最多保留几条；超出时丢弃最旧的。
    /// 之所以要上限：debug 通知里有 `duration: 600` 的长驻 toast，不设上限会无限堆叠。
    @ObservationIgnored public var maxVisible: Int = 6

    @ObservationIgnored private var seq: Int = 0

    /// 待插入队列。`show()` 只往这里入队，由 `drainPending()` 逐条落到 `items` 上。
    /// 之所以要排队：SwiftUI 会把「同一帧内的所有状态变更」合并成一次更新，
    /// 一次回调里连打多条日志时直接 append 会让它们同帧出现，既没有淡入也没有「上方让位」动画。
    @ObservationIgnored private var pending: [FSToastMessage] = []

    /// 是否已有排空任务在跑（避免并发起多个 drain 循环）
    @ObservationIgnored private var isDraining = false

    /// 连续多条时的入队间隔（秒）。必须大于一帧，否则又会被合并；0.14s ≈ 8 帧 @60Hz。
    private let insertInterval: Double = 0.14

    /// 插入 / 上方让位 / 移除的动画时长。
    /// 视图层 `.animation(_:value:)` 也要用同一个值，故设为 static（实例方法里引用须写 `Self.`）。
    public static let overlayAnimationDuration: Double = 0.24

    /// 单条移除的动画时长
    private let removeDuration: Double = 0.25

    private init() {}

    /// 兼容旧接口：最后加入的那条
    public var current: FSToastMessage? { items.last }

    public func show(_ text: String, duration: Double) {
        guard !text.isEmpty else { return }
        if Thread.isMainThread {
            MainActor.assumeIsolated { self.showOnMain(text, duration: duration) }
        } else {
            DispatchQueue.main.async {
                MainActor.assumeIsolated { self.showOnMain(text, duration: duration) }
            }
        }
    }

    /// 主动收掉某一条（id 来自 show 时分配）
    public func dismiss(_ id: Int) {
        if Thread.isMainThread {
            MainActor.assumeIsolated { self.dismissOnMain(id) }
        } else {
            DispatchQueue.main.async {
                MainActor.assumeIsolated { self.dismissOnMain(id) }
            }
        }
    }

    /// 一次清空
    public func dismissAll() {
        if Thread.isMainThread {
            MainActor.assumeIsolated { self.dismissAllOnMain() }
        } else {
            DispatchQueue.main.async {
                MainActor.assumeIsolated { self.dismissAllOnMain() }
            }
        }
    }

    @MainActor
    private func showOnMain(_ text: String, duration: Double) {
        seq += 1
        // 注意：这里**不直接**改 items，只入队。真正的插入在 drainPending 里按间隔逐条进行，
        // 这样每一条都能独占一帧，插入 + 已有条目上移的动画一定看得见。
        pending.append(FSToastMessage(id: seq, text: text, duration: duration))

        // 队列同样设上限：日志刷屏时若入队几十条，逐条 0.14s 会把屏幕占满好几秒，
        // 直接丢掉最旧的排队项，只保留最新的 maxVisible 条。
        let limit = max(maxVisible, 1)
        if pending.count > limit {
            pending.removeFirst(pending.count - limit)
        }

        drainPending()
    }

    /// 逐条把 `pending` 落进 `items`，两条之间隔 `insertInterval`。
    @MainActor
    private func drainPending() {
        guard !isDraining else { return }
        isDraining = true

        Task { @MainActor in
            while !self.pending.isEmpty {
                let next = self.pending.removeFirst()
                self.insertOnMain(next)

                // 后面还有排队的话，让本条动画先跑出去一帧再插下一条
                if !self.pending.isEmpty {
                    try? await Task.sleep(for: .seconds(self.insertInterval))
                }
            }
            // 本循环内没有 await 跨越，这里置回 false 不会被别的 show 抢跑
            self.isDraining = false
        }
    }

    @MainActor
    private func insertOnMain(_ msg: FSToastMessage) {
        var list = items
        list.append(msg)
        let limit = max(maxVisible, 1)
        if list.count > limit {
            list.removeFirst(list.count - limit)
        }

        withAnimation(.easeOut(duration: Self.overlayAnimationDuration)) {
            items = list
        }

        // 停留计时从「真正出现在屏幕上」开始算，排队等待的时间不计入，
        // 否则多条同时来时，后面的会还没露脸就被收掉。
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(max(msg.duration, 0)))
            self.dismissOnMain(msg.id)
        }
    }

    @MainActor
    private func dismissOnMain(_ id: Int) {
        guard items.contains(where: { $0.id == id }) else { return }
        withAnimation(.easeOut(duration: removeDuration)) {
            items.removeAll { $0.id == id }
        }
    }

    @MainActor
    private func dismissAllOnMain() {
        // 排队的也一并丢掉，否则清空后它们还会一条条冒出来
        pending.removeAll()
        guard !items.isEmpty else { return }
        withAnimation(.easeOut(duration: removeDuration)) {
            items.removeAll()
        }
    }
}

/// 浮层：把 `FSToastCenter.items` 竖直排列，多条并存时逐条往上让位
public struct FSToastOverlay: View {

    private let center = FSToastCenter.shared

    private var maxWidth: CGFloat { WIDTHFC - 50 }

    public init() {}

    public var body: some View {
        VStack(spacing: 10) {
            ForEach(center.items) { msg in
                toastView(msg)
                    .transition(.opacity)
            }
        }
        // 视图层再声明一次动画：模型层的 `withAnimation` 依赖事务传递，
        // 若 show 恰好发生在某次视图更新中途，事务会被吞掉（表现为「有时候没有动画」）。
        // 这里按 id 列表变化兜底，保证插入 / 让位 / 移除一定走动画。
        .animation(.easeOut(duration: FSToastCenter.overlayAnimationDuration),
                   value: center.items.map(\.id))
        .allowsHitTesting(false)
    }

    private func toastView(_ msg: FSToastMessage) -> some View {
        Text(msg.text)
            .font(.system(size: 14))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 10)
            .frame(minHeight: 40)
            .fixedSize(horizontal: false, vertical: true)
            .background(Color(red: 73.0 / 255, green: 80.0 / 255, blue: 86.0 / 255).opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            .frame(maxWidth: maxWidth)
    }
}
