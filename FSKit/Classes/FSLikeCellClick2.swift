//
//  FSLikeCellClick2.swift
//  FSKit
//
//  cell 点击动画容器 v2：
//  - 铺满模式（默认）：listRowBackground 统一管理白色/灰底，铺满整行
//  - 卡片模式（cardStyle=true）：灰底在 content 的 background 上切换，白色卡片+圆角+间距
//  - 点击变灰 + 长按变灰 + 返回淡出（通过 FSPageReturnHighlight store）
//

import SwiftUI
import UIKit

public struct FSLikeCellClick2<Content: View>: View {
    @EnvironmentObject private var store: FSPageReturnHighlight
    private let id: AnyHashable
    private let onTap: () -> Void
    private let content: Content
    private let fadeDuration: Double
    private let pressedColor: Color
    private let normalColor: Color
    private let autoDismiss: Bool
    private let cardStyle: Bool
    private let cornerRadius: CGFloat
    private let padding: EdgeInsets

    @State private var isPressing = false

    public init(id: AnyHashable,
                fadeDuration: Double = 0.6,
                pressedColor: Color = Color(UIColor.systemGray3),
                normalColor: Color = Color(.systemBackground),
                autoDismiss: Bool = false,
                cardStyle: Bool = false,
                cornerRadius: CGFloat = 0,
                padding: EdgeInsets = EdgeInsets(),
                onTap: @escaping () -> Void,
                @ViewBuilder content: () -> Content) {
        self.id = id
        self.fadeDuration = fadeDuration
        self.pressedColor = pressedColor
        self.normalColor = normalColor
        self.autoDismiss = autoDismiss
        self.cardStyle = cardStyle
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.onTap = onTap
        self.content = content()
    }

    @ViewBuilder
    public var body: some View {
        let isHighlighted = store.highlightedId.map { $0 == id } ?? false
        let showGray = isPressing || isHighlighted

        if cardStyle {
            // 卡片模式：灰底在 content 的 background 上切换，listRowBackground 透明，padding 做间距
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(showGray ? pressedColor : normalColor)
                        .animation(FSCellFadeAnimation(response: fadeDuration), value: showGray)
                )
                .padding(padding)
                .listRowBackground(Color.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    store.highlight(id)
                    onTap()
                    if autoDismiss {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            withAnimation(FSCellFadeAnimation(response: fadeDuration)) {
                                store.highlightedId = nil
                            }
                        }
                    }
                }
                .onLongPressGesture(minimumDuration: 0.5, pressing: { isPressing = $0 }, perform: {})
        } else {
            // 铺满模式：listRowBackground 统一管理白色/灰底
            ZStack { content }
                .listRowBackground(
                    Rectangle()
                        .fill(showGray ? pressedColor : normalColor)
                        .animation(FSCellFadeAnimation(response: fadeDuration), value: showGray)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    store.highlight(id)
                    onTap()
                    if autoDismiss {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            withAnimation(FSCellFadeAnimation(response: fadeDuration)) {
                                store.highlightedId = nil
                            }
                        }
                    }
                }
                .onLongPressGesture(minimumDuration: 0.5, pressing: { isPressing = $0 }, perform: {})
        }
    }
}
