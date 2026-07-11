//
//  FSLikeCellClick.swift
//  FSKit
//
//  仿 UITableView cell 点击高亮容器：
//  - 点击：点亮灰底 + 触发 onTap（导航），灰底跨页保留，返回时由共享 store 自动淡出
//  - 长按：按压期间点亮灰底（铺满），松手恢复，不导航，不依赖 ButtonStyle.isPressed
//  - 淡出：store 置空 highlightedId 时，Rectangle 从灰变 normal，播 FSCellFadeAnimation
//
//  设计要点：
//  - 不用 Button，不用 ButtonStyle。灰底由 ZStack 底层 Rectangle 铺满（frame(maxWidth/maxHeight: .infinity)）
//  - 手势：onTapGesture（点击导航）+ onLongPressGesture（按压变灰）
//  - 状态：isPressing（本地，按压即时）+ isHighlighted（store 共享，跨页保留）
//  - 灰底 = isPressing || isHighlighted，Rectangle.fill 由两者统一驱动
//  - 内容由调用方 @ViewBuilder 自定义，容器只负责灰底 + 手势 + 淡出
//
//  复用 FSPageReturnHighlight store（经 @EnvironmentObject 注入）和 FSCellFadeAnimation 淡出曲线
//

import SwiftUI
import UIKit

/// 仿 cell 点击容器：铺满整行的灰底 + 点击/长按手势 + 返回淡出。
/// 内容由调用方 @ViewBuilder 自定义，容器只负责灰底和手势。
///
/// - Example:
///   ```
///   FSLikeCellClick(id: name, onTap: { push(...) }) {
///       HStack { Image(...); Text(...); Spacer() }
///   }
///   ```
public struct FSLikeCellClick<Content: View>: View {
    /// 共享高亮 store，经 @EnvironmentObject 注入（由外层 FSPageReturnList 或手动 .environmentObject）
    @EnvironmentObject private var store: FSPageReturnHighlight
    /// 用于标识本行（与 store.highlightedId 比较，AnyHashable 接受任意 Hashable 类型）
    private let id: AnyHashable
    private let onTap: () -> Void
    private let content: Content
    private let fadeDuration: Double
    private let pressedColor: Color
    private let normalColor: Color
    /// 点击后自动清除高亮（无需跨页保留），默认 false（跨页保留到返回再淡出）
    private let autoDismiss: Bool

    /// 按压即时状态：onLongPressGesture.pressing 驱动，touch-down true、松手 false
    @State private var isPressing = false

    public init(id: AnyHashable,
                fadeDuration: Double = 0.6,
                pressedColor: Color = Color(UIColor.systemGray3),
                normalColor: Color = Color(UIColor.systemBackground),
                autoDismiss: Bool = false,
                onTap: @escaping () -> Void,
                @ViewBuilder content: () -> Content) {
        self.id = id
        self.fadeDuration = fadeDuration
        self.pressedColor = pressedColor
        self.normalColor = normalColor
        self.autoDismiss = autoDismiss
        self.onTap = onTap
        self.content = content()
    }

    public var body: some View {
        /// 本行是否被 store 标记高亮（点击后跨页保留，返回时淡出）
        let isHighlighted = store.highlightedId.map { $0 == id } ?? false
        /// 任意按压或高亮均变灰
        let showGray = isPressing || isHighlighted

        return content
            // 行级背景：listRowBackground 强制铺满整个 row，不依赖 content 尺寸
            .listRowBackground(
                Rectangle()
                    .fill(showGray ? pressedColor : normalColor)
                    .animation(FSCellFadeAnimation(response: fadeDuration), value: showGray)
            )
            .contentShape(Rectangle())
            // 点击：点亮 store + 触发 onTap；autoDismiss 时延时清除（无需跨页保留）
            .onTapGesture {
                store.highlight(id)
                onTap()
                if autoDismiss {
                    // 先保持灰底 0.15s，再清除触发 0.6s 淡出（和 HighlightRow 一致的节奏）
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        store.highlightedId = nil
                    }
                }
            }
            // 长按：仅驱动 isPressing 变灰（铺满），松手恢复，不导航
            .onLongPressGesture(minimumDuration: 0.5, pressing: { isPressing = $0 }, perform: {})
    }
}
