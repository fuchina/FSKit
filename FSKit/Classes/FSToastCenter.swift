//
//  FSToastCenter.swift
//  FSKit
//
//  2026-10-15 全 SwiftUI 化：
//  原来 `FSToast.toast(_:)` 是构造一个 UIView 直接 addSubview 到 window，必须有 UIView 宿主；
//  现改为「状态 + 根视图渲染」——调用方只往这里塞文案，由根视图（主 App 的 AppRootScreen）
//  统一渲染成 SwiftUI 浮层。
//
//  因此全项目 348 处 `FSToast.toast(...)` 调用点**一行都不用改**，
//  也不再依赖任何 UIView / UIViewController。
//

import SwiftUI

/// 一条 toast 的内容
public struct FSToastMessage: Equatable {

    public var text: String
    /// 停留秒数（原 `duration`）
    public var duration: Double

    public init(text: String, duration: Double) {
        self.text = text
        self.duration = duration
    }
}

/// 全局 toast 中心。**可从任意线程调用**（内部自行切主线程）。
///
/// 不标 `@MainActor`：因为 `FSToast.toast(...)` 是非隔离的 `static` 方法，
/// 348 处调用点未必都在主隔离域；若把本类标成 `@MainActor`，那些调用点会编译报错。
///
/// Swift 6 语言模式：`show` 会把 `self` 送进 `@MainActor` 闭包，需显式声明可跨隔离域传递，
/// 故补 `@unchecked Sendable`（可变状态已由 `MainActor.assumeIsolated` 保证只在主线程访问）。
public final class FSToastCenter: ObservableObject, @unchecked Sendable {

    // 2026-10-17：Pod 与主 App 统一为默认主隔离后，nonisolated(unsafe) 反而报错，故移除。
    public static let shared = FSToastCenter()

    /// 当前要显示的 toast（nil = 不显示）
    @Published public private(set) var current: FSToastMessage?

    /// 序号：连续多次 toast 时，只有最后一个定时器能收起浮层（原 `AppRootScreen` 的 toastSeq 语义）
    private var seq: Int = 0

    private init() {}

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

    @MainActor
    private func showOnMain(_ text: String, duration: Double) {
        seq += 1
        let mine = seq

        withAnimation(.easeIn(duration: 0.1)) {
            current = FSToastMessage(text: text, duration: duration)
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            guard mine == self.seq else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                self.current = nil
            }
        }
    }
}

/// toast 浮层（由根视图挂载，屏幕居中）。
///
/// 外观逐值对齐原 `FSToast.toast(_:duration:to:)`：
/// 底色 rgba(73,80,86,0.9)、圆角 3、白字 14、最小高 40、水平内边距 10、
/// 最大宽 `WIDTHFC - 30 - 20`、居中、0.1s 淡入 / 0.25s 淡出。
public struct FSToastOverlay: View {

    @ObservedObject private var center = FSToastCenter.shared

    public init() {}

    public var body: some View {
        if let msg = center.current {
            Text(msg.text)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .frame(minHeight: 40)
                .frame(maxWidth: WIDTHFC - 50)
                .fixedSize(horizontal: false, vertical: true)
                .background(Color(red: 73.0 / 255, green: 80.0 / 255, blue: 86.0 / 255).opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                .allowsHitTesting(false)
        }
    }
}
