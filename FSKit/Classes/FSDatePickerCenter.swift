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

    // Swift 6 语言模式：同上，任意线程可调用。
    public nonisolated(unsafe) static let shared = FSDatePickerCenter()

    @Published public private(set) var current: FSDatePickerSpec?

    private init() {}

    public func show(date: Date?, onConfirm: @escaping (Date) -> Void, onCancel: (() -> Void)? = nil) {
        let spec = FSDatePickerSpec(initialDate: date, onConfirm: onConfirm, onCancel: onCancel)
        let apply: @MainActor () -> Void = { [weak self] in self?.current = spec }
        if Thread.isMainThread {
            MainActor.assumeIsolated { apply() }
        } else {
            DispatchQueue.main.async { MainActor.assumeIsolated { apply() } }
        }
    }

    public func dismiss() {
        let apply: @MainActor () -> Void = { [weak self] in self?.current = nil }
        if Thread.isMainThread {
            MainActor.assumeIsolated { apply() }
        } else {
            DispatchQueue.main.async { MainActor.assumeIsolated { apply() } }
        }
    }
}

/// 日期选择浮层（由根视图挂载）
public struct FSDatePickerOverlay: View {

    @ObservedObject private var center = FSDatePickerCenter.shared
    @State private var draft: Date = Date()

    public init() {}

    private let blue = Color(red: 18 / 255.0, green: 152 / 255.0, blue: 233 / 255.0)

    public var body: some View {
        ZStack(alignment: .bottom) {
            if let spec = center.current {
                // 全屏遮罩（原 backView: 黑 0.28，点空白取消）
                Color.black.opacity(0.28)
                    .ignoresSafeArea()
                    .onTapGesture { cancel(spec) }

                panel(spec)
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: center.current?.id)
        .onChange(of: center.current?.id) { _, _ in
            draft = center.current?.initialDate ?? Date()
        }
    }

    private func panel(_ spec: FSDatePickerSpec) -> some View {
        VStack(spacing: 0) {
            ZStack {
                blue
                HStack {
                    Button("取消") { cancel(spec) }
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .frame(width: 60)
                    Spacer(minLength: 0)
                    Button("确认") { confirm(spec) }
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .frame(width: 60)
                }
                .padding(.horizontal, 0)
                .frame(maxWidth: .infinity)

                Text(todayTitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .frame(height: 40)

            DatePicker("", selection: $draft, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "zh-CN"))
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color.white)

            // 原面板高 240 + 34（34 为底部安全区补偿）
            Color.white.frame(height: 34)
        }
        .background(Color.white)
    }

    private var todayTitle: String {
        let c = Calendar(identifier: .gregorian).dateComponents([.month, .day], from: Date())
        return "今天是\(c.month ?? 0)月\(c.day ?? 0)日"
    }

    private func cancel(_ spec: FSDatePickerSpec) {
        spec.onCancel?()
        center.dismiss()
    }

    private func confirm(_ spec: FSDatePickerSpec) {
        spec.onConfirm(draft)
        center.dismiss()
    }
}
