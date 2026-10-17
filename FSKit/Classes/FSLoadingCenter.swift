//
//  FSLoadingCenter.swift
//  FSKit
//
//  2026-10-15 全 SwiftUI 化：
//  原来「转圈等待」是往承载页 addSubview 一个黑底容器（需要 UIView 宿主），
//  现改为「状态 + 根视图渲染」，由主 App 的 AppRootScreen 统一渲染。
//

import SwiftUI

/// 全局等待浮层状态。**可从任意线程调用**。
///
/// Swift 6 语言模式：`show` 会把 `self` 送进 `@MainActor` 闭包，故补 `@unchecked Sendable`
/// （可变状态已由 `MainActor.assumeIsolated` 保证只在主线程访问）。
public final class FSLoadingCenter: ObservableObject, @unchecked Sendable {

    // 2026-10-17：Pod 与主 App 统一为默认主隔离后，nonisolated(unsafe) 反而报错，故移除。
    public static let shared = FSLoadingCenter()

    @Published public private(set) var isLoading = false

    private init() {}

    public func show(_ on: Bool) {
        let apply: @MainActor () -> Void = { [weak self] in self?.isLoading = on }
        if Thread.isMainThread {
            MainActor.assumeIsolated { apply() }
        } else {
            DispatchQueue.main.async { MainActor.assumeIsolated { apply() } }
        }
    }
}

/// 等待浮层（由根视图挂载）。
///
/// 外观对齐原实现：全屏透明遮罩（挡点击但不压暗）+ 80×80 黑底 0.7、圆角 6、白色转圈。
public struct FSLoadingOverlay: View {

    @ObservedObject private var center = FSLoadingCenter.shared

    public init() {}

    public var body: some View {
        if center.isLoading {
            ZStack {
                Color.black.opacity(0.01)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .frame(width: 80, height: 80)
                    .background(Color.black.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
    }
}
