//
//  FSDatePickerCenter.swift
//  FSKit
//
//  2026-10-15 全 SwiftUI 化：
//  原 `FSDatePickerView` 是「全屏遮罩 + 底部 UIDatePicker 滚轮」的 UIView，需要 UIView 宿主
//  （调用方到处 `UIApplication.fs_topView.addSubview(picker)`）。现改为「状态 + 根视图渲染」。
//
//  外观逐值对齐原实现：遮罩黑 0.28；底部白色面板高 240+34；
//  顶部 40pt 蓝条 (#1298e9)：左「取消」宽 60、右「确认」宽 60、中间 14pt 白字「今天是X月X日」；
//  下方 `UIDatePicker(wheels, .date)` 高 200、locale zh-CN；0.3s 滑入滑出。
//
//  2026-10-18 弹出卡顿修复，见 `FSDatePickerOverlay` 注释（面板常驻 / 静态 locale /
//  滚轮值不 publish / 动画收敛到 show·dismiss 的事务里）。
//

import SwiftUI

/// 一条日期选择请求
///
/// Swift 6 语言模式：spec 会被送进 `@MainActor` 闭包，故声明 `@unchecked Sendable`
/// （纯数据载体；内含的 onConfirm / onCancel 闭包由调用方在主线程执行）。
public struct FSDatePickerSpec: Identifiable, @unchecked Sendable {

    public let id = UUID()
    /// 初始选中日期（nil = 今天）
    public var initialDate: Date?
    public var onConfirm: (Date) -> Void
    public var onCancel: (() -> Void)?

    public init(initialDate: Date?, onConfirm: @escaping (Date) -> Void, onCancel: (() -> Void)?) {
        self.initialDate = initialDate
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }
}

/// 全局日期选择中心。**可从任意线程调用**。
///
/// Swift 6 语言模式：`show` 会把 `self` 送进 `@MainActor` 闭包，故补 `@unchecked Sendable`
/// （可变状态已由 `MainActor.assumeIsolated` 保证只在主线程访问）。
public final class FSDatePickerCenter: ObservableObject, @unchecked Sendable {

    // 2026-10-17：Pod 与主 App 统一为默认主隔离后，nonisolated(unsafe) 反而报错，故移除。
    public static let shared = FSDatePickerCenter()

    @Published public private(set) var current: FSDatePickerSpec?

    /// 滚轮当前选中值。
    ///
    /// 浮层面板是常驻的（见 `FSDatePickerOverlay`），滚轮值要跨「弹出 / 关闭」保留，
    /// 所以放在这里而不是视图的 `@State`。`show` 里**先写它、再 publish `current`**，
    /// 这样入场动画的第一帧就是正确日期（旧实现靠 `onChange` 补设，会先闪一下上次的日期）。
    ///
    /// 故意不加 `@Published`：滚轮每滚一格都会写它，publish 会让整个浮层重算。
    public var draft: Date = Date()

    private init() {}

    public func show(date: Date?, onConfirm: @escaping (Date) -> Void, onCancel: (() -> Void)? = nil) {
        let spec = FSDatePickerSpec(initialDate: date, onConfirm: onConfirm, onCancel: onCancel)
        let apply: @MainActor () -> Void = { [weak self] in
            guard let self else { return }
            self.draft = spec.initialDate ?? Date()
            withAnimation(.easeInOut(duration: 0.3)) { self.current = spec }
        }
        if Thread.isMainThread {
            MainActor.assumeIsolated { apply() }
        } else {
            DispatchQueue.main.async { MainActor.assumeIsolated { apply() } }
        }
    }

    public func dismiss() {
        let apply: @MainActor () -> Void = { [weak self] in
            withAnimation(.easeInOut(duration: 0.3)) { self?.current = nil }
        }
        if Thread.isMainThread {
            MainActor.assumeIsolated { apply() }
        } else {
            DispatchQueue.main.async { MainActor.assumeIsolated { apply() } }
        }
    }
}

/// 日期选择浮层（由根视图挂载）
///
/// 2026-10-18 卡顿修复（原来点「日期」弹出会明显掉帧）：
/// 1. 面板**常驻**，只做 `offset` 滑入滑出。旧实现用 `if let` 插入 / 移除，等于每次弹出都
///    现建一个 `UIDatePicker`，这笔开销正好落在 0.3s 入场动画里 → 掉帧。
/// 2. `zh-CN` locale 提成 `static let`。旧实现写在 `body` 里，滚轮每动一格 body 重算就
///    重新造一个 Locale 塞进环境（等于反复重配滚轮）。
/// 3. 滚轮值改由 `FSDatePickerCenter.draft`（非 `@Published`）持有，拖动滚轮不再触发
///    浮层重算，只更新 UIDatePicker 自己。
/// 4. 动画从 `body` 上的 `.animation(_:value:)` 挪到 `show` / `dismiss` 内部用 `withAnimation`，
///    只动画「显隐这一次事务」，不在滚轮子树里留常驻的隐式动画。
public struct FSDatePickerOverlay: View {

    @ObservedObject private var center = FSDatePickerCenter.shared

    public init() {}

    /// 面板高：40(蓝条) + 200(滚轮) + 34(底部安全区补偿)
    private static let panelHeight: CGFloat = 274

    private var isPresented: Bool { center.current != nil }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // 遮罩常驻，用透明度显隐（避免插入 / 移除整棵子树）
            Color.black
                .opacity(isPresented ? 0.28 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(isPresented)
                .onTapGesture { cancel() }

            DatePickerPanel(date: draftBinding, onCancel: cancel, onConfirm: confirm)
                .offset(y: isPresented ? 0 : Self.panelHeight)
                .allowsHitTesting(isPresented)
                .accessibilityHidden(!isPresented)
        }
    }

    private var draftBinding: Binding<Date> {
        Binding(get: { center.draft }, set: { center.draft = $0 })
    }

    private func cancel() {
        guard let spec = center.current else { return }
        spec.onCancel?()
        center.dismiss()
    }

    private func confirm() {
        guard let spec = center.current else { return }
        spec.onConfirm(center.draft)
        center.dismiss()
    }
}

// MARK: - 面板

/// 底部面板：40pt 蓝条（取消 / 今天是X月X日 / 确认）+ 滚轮 + 34pt 安全区补偿。
///
/// 拆成独立子视图：滚轮状态只影响这一块。
private struct DatePickerPanel: View {

    @Binding var date: Date
    let onCancel: () -> Void
    let onConfirm: () -> Void

    private let blue = Color(red: 18 / 255.0, green: 152 / 255.0, blue: 233 / 255.0)

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                blue

                Text(todayTitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .allowsHitTesting(false)

                HStack {
                    barButton("取消", action: onCancel)
                    Spacer(minLength: 0)
                    barButton("确认", action: onConfirm)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 40)

            DatePickerWheel(date: $date)

            // 原面板高 240 + 34（34 为底部安全区补偿）
            Color.white.frame(height: 34)
        }
        .background(Color.white)
    }

    /// 蓝条两侧按钮：`contentShape` 让整块 60×40 都能点（原来只有文字能点）
    private func barButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .frame(width: 60, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var todayTitle: String {
        let c = Calendar(identifier: .gregorian).dateComponents([.month, .day], from: Date())
        return "今天是\(c.month ?? 0)月\(c.day ?? 0)日"
    }
}

// MARK: - 滚轮

/// 单独的滚轮视图：避免外层 body 重算时连带重建 `UIDatePicker`。
private struct DatePickerWheel: View {

    @Binding var date: Date

    /// 只建一次。每次 `body` 现造 `Locale(identifier:)` 会让滚轮反复重配（卡顿来源之一）。
    private static let locale = Locale(identifier: "zh-CN")

    var body: some View {
        DatePicker("", selection: $date, displayedComponents: .date)
            .datePickerStyle(.wheel)
            .labelsHidden()
            .environment(\.locale, Self.locale)
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(Color.white)
    }
}
