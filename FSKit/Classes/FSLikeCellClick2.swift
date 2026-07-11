//
//  FSLikeCellClick2.swift
//  FSKit
//
//  cell 点击动画容器 v2：
//  - 铺满模式（默认）：listRowBackground 统一管理白色/灰底，铺满整行
//  - 卡片模式（cardStyle=true）：灰底在 content 的 background 上切换，白色卡片+圆角+间距
//  - 点击变灰 + 长按变灰 + 返回淡出（通过 FSPageReturnHighlight store）
//  - 变灰瞬时、淡出 0.6s spring：用 animatedGray 状态机 + onChange 监听 store 变化
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
    /// 动画状态机：变灰时立刻 true，淡出时 withAnimation(false)
    @State private var animatedGray = false

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
        let showGray = animatedGray

        if cardStyle {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(showGray ? pressedColor : normalColor)
                )
                .padding(padding)
                .listRowBackground(Color.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    store.highlight(id)
                    onTap()
                    if autoDismiss {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            store.highlightedId = nil
                        }
                    }
                }
                .onLongPressGesture(minimumDuration: 0.5,
                    pressing: { isPressing = $0 },
                    perform: {})
                .onChange(of: store.highlightedId) { newValue in
                    handleStoreChange(newValue)
                }
                .onChange(of: isPressing) { newValue in
                    animatedGray = newValue
                }
        } else {
            ZStack { content }
                .listRowBackground(
                    Rectangle()
                        .fill(showGray ? pressedColor : normalColor)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    store.highlight(id)
                    onTap()
                    if autoDismiss {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            store.highlightedId = nil
                        }
                    }
                }
                .onLongPressGesture(minimumDuration: 0.5,
                    pressing: { isPressing = $0 },
                    perform: {})
                .onChange(of: store.highlightedId) { newValue in
                    handleStoreChange(newValue)
                }
                .onChange(of: isPressing) { newValue in
                    animatedGray = newValue
                }
        }
    }

    private func handleStoreChange(_ newValue: AnyHashable??) {
        let match = newValue.map { $0 == id } ?? false
        if match {
            animatedGray = true   // 点击立刻变灰
        } else if animatedGray {
            // 返回或 autoDismiss 清除 → 淡出
            withAnimation(FSCellFadeAnimation(response: fadeDuration)) {
                animatedGray = false
            }
        }
    }
}
