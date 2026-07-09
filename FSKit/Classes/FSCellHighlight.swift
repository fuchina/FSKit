//
//  FSCellHighlight.swift
//  FSKit
//
//  公共能力：UITableViewCell 风格选中高亮（SwiftUI）
//  - 按下瞬间（或外部 highlight=true）变灰，松手淡出
//  - 灰色绘在内容之下，文字始终清晰
//  - 不拦截 List / ScrollView 滑动手势
//  - 动画节奏对齐原生 UITableViewCell（淡入/淡出约 0.15s）
//

import SwiftUI

/// UITableViewCell 风格选中高亮 ButtonStyle。
///
/// 用法：
/// ```swift
/// Button { ... } label: { rowContent }
///     .buttonStyle(CellHighlightButtonStyle())
/// ```
/// - `highlight`：外部强制点亮（用于点击时也保持高亮，避免快速点击看不到动画）。
/// - `pressedColor` / `normalColor`：选中灰与常态底色。
/// - `fadeInDuration`：变灰淡入时长（秒），默认 0（瞬时，对齐原生 cell 选中的脆快节奏）。
/// - `fadeOutDuration`：恢复白底淡出时长（秒），默认 0.1。
public struct CellHighlightButtonStyle: ButtonStyle {
    public var highlight: Bool = false
    public var pressedColor: Color = Color(UIColor.systemGray3)
    public var normalColor: Color = Color(UIColor.systemBackground)
    public var fadeInDuration: Double = 0
    public var fadeOutDuration: Double = 0.1

    public init(highlight: Bool = false,
                pressedColor: Color = Color(UIColor.systemGray3),
                normalColor: Color = Color(UIColor.systemBackground),
                fadeInDuration: Double = 0,
                fadeOutDuration: Double = 0.1) {
        self.highlight = highlight
        self.pressedColor = pressedColor
        self.normalColor = normalColor
        self.fadeInDuration = fadeInDuration
        self.fadeOutDuration = fadeOutDuration
    }

    public func makeBody(configuration: Configuration) -> some View {
        let on = configuration.isPressed || highlight
        configuration.label
            .background(on ? pressedColor : normalColor)
            .animation(.easeOut(duration: on ? fadeInDuration : fadeOutDuration), value: on)
    }
}

/// 可复用的「点击高亮行」封装：点击瞬间点亮灰底、短暂停留后淡出，
/// 模拟原生 UITableViewCell 选中效果。
///
/// 点击回调 `onTap` 由调用方自行决定何时刷新内容
/// （通常是等灰底动画消失后，例如 `DispatchQueue.main.asyncAfter(deadline: .now() + 0.35)`）。
///
/// 用法：
/// ```swift
/// HighlightRow(onTap: { handle(model) }) {
///     MyRow(model: model)
/// }
/// ```
public struct HighlightRow<Content: View>: View {
    public let content: Content
    public let onTap: () -> Void
    /// 灰底淡出前的保持时长（秒），默认 0.2
    public var holdDuration: Double = 0.2
    /// 变灰淡入时长（秒），默认 0（瞬时）
    public var fadeInDuration: Double = 0
    /// 淡出时长（秒），默认 0.1
    public var fadeDuration: Double = 0.1
    /// 选中灰 / 常态底色
    public var pressedColor: Color = Color(UIColor.systemGray3)
    public var normalColor: Color = Color(UIColor.systemBackground)

    @State private var flash = false

    public init(onTap: @escaping () -> Void,
                holdDuration: Double = 0.2,
                fadeInDuration: Double = 0,
                fadeDuration: Double = 0.1,
                pressedColor: Color = Color(UIColor.systemGray3),
                normalColor: Color = Color(UIColor.systemBackground),
                @ViewBuilder content: () -> Content) {
        self.onTap = onTap
        self.holdDuration = holdDuration
        self.fadeInDuration = fadeInDuration
        self.fadeDuration = fadeDuration
        self.pressedColor = pressedColor
        self.normalColor = normalColor
        self.content = content()
    }

    public var body: some View {
        Button {
            flash = true
            onTap()
            // 灰底保持 holdDuration 后开始淡出；淡出 fadeDuration 完全消失
            DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration) {
                withAnimation(.easeOut(duration: fadeDuration)) { flash = false }
            }
        } label: {
            content
        }
        .buttonStyle(CellHighlightButtonStyle(highlight: flash,
                                              pressedColor: pressedColor,
                                              normalColor: normalColor,
                                              fadeInDuration: fadeInDuration,
                                              fadeOutDuration: fadeDuration))
    }
}
