//
//  FSHalfListCenter.swift
//  FSKit
//
//  2026-10-15 全 SwiftUI 化：
//  原 `FSHalfView` 是「遮罩 + 右侧滑入的 UITableView」的 UIView，需要 UIView 宿主，
//  且行内容要靠调用方拿 UIKit cell 去填（`configCell`）。现改为「状态 + 根视图渲染」：
//  调用方只提供行数据（标题/右侧说明）与选中回调。
//
//  外观逐值对齐原实现：遮罩黑 0.28；列表从右侧滑入、左边距 `leftWidth`；
//  行高 50、标题 14pt、右侧说明 12pt 灰、右侧 chevron（原 `.value1` + disclosureIndicator）。
//

import SwiftUI

/// 半屏列表的一行
public struct FSHalfListRow: Identifiable {

    public let id = UUID()
    public var title: String
    /// 右侧说明（原 `detailTextLabel`，如「已是此组」）
    public var detail: String

    public init(title: String, detail: String = "") {
        self.title = title
        self.detail = detail
    }
}

/// 一条半屏列表请求
///
/// Swift 6 语言模式：spec 会被送进 `@MainActor` 闭包，故声明 `@unchecked Sendable`
/// （纯数据载体；内含的 onSelect 闭包由调用方在主线程执行）。
public struct FSHalfListSpec: Identifiable, @unchecked Sendable {

    public let id = UUID()
    public var leftWidth: CGFloat
    public var rows: [FSHalfListRow]
    public var onSelect: (Int) -> Void

    public init(leftWidth: CGFloat, rows: [FSHalfListRow], onSelect: @escaping (Int) -> Void) {
        self.leftWidth = leftWidth
        self.rows = rows
        self.onSelect = onSelect
    }
}

/// 全局半屏列表中心。**可从任意线程调用**。
///
/// Swift 6 语言模式：`show` / `dismiss` 会把 `self` 送进 `@MainActor` 闭包，
/// 故补 `@unchecked Sendable`（可变状态已由 `MainActor.assumeIsolated` 保证只在主线程访问）。
public final class FSHalfListCenter: ObservableObject, @unchecked Sendable {

    // Swift 6 语言模式：同上，任意线程可调用。
    public nonisolated(unsafe) static let shared = FSHalfListCenter()

    @Published public private(set) var current: FSHalfListSpec?

    private init() {}

    public func show(leftWidth: CGFloat, rows: [FSHalfListRow], onSelect: @escaping (Int) -> Void) {
        let spec = FSHalfListSpec(leftWidth: leftWidth, rows: rows, onSelect: onSelect)
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

/// 半屏列表浮层（由根视图挂载）
public struct FSHalfListOverlay: View {

    @ObservedObject private var center = FSHalfListCenter.shared

    public init() {}

    public var body: some View {
        ZStack(alignment: .trailing) {
            if let spec = center.current {
                // 遮罩（原 _tapView: 黑 0.28，点空白关闭）
                Color.black.opacity(0.28)
                    .ignoresSafeArea()
                    .onTapGesture { center.dismiss() }

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(spec.rows.enumerated()), id: \.element.id) { index, row in
                            Button {
                                spec.onSelect(index)
                                center.dismiss()
                            } label: {
                                HStack(spacing: 8) {
                                    Text(row.title)
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(uiColor: .label))
                                    Spacer(minLength: 8)
                                    if row.detail.isEmpty == false {
                                        Text(row.detail)
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(uiColor: .secondaryLabel))
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                                }
                                .padding(.horizontal, 15)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(Color(uiColor: .systemBackground))
                                .overlay(alignment: .bottom) {
                                    Rectangle()
                                        .fill(Color(uiColor: .separator))
                                        .frame(height: 0.5)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(width: max(WIDTHFC - spec.leftWidth, 0))
                .ignoresSafeArea(edges: .vertical)
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: center.current?.id)
    }
}
