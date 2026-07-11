//
//  FSLikeCellClick.swift
//  FSKit
//
//  cell 点击动画容器 v2：
//  - 铺满模式（默认）：listRowBackground 统一管理白色/灰底，铺满整行
//  - 卡片模式（cardStyle=true）：灰底在 content 的 background 上切换，白色卡片+圆角+间距
//  - 点击变灰 + 长按变灰 + 返回淡出（通过 FSPageReturnHighlight store）
//  - 变灰瞬时、淡出显式 withAnimation(spring 0.6)：animatedGray 状态机 + onChange 监听 store 变化
//  - fill 模式 listRowBackground 不响应 withAnimation，仍靠隐式 .animation(value:) 驱动（已验证）
//

import SwiftUI
import UIKit

public struct FSLikeCellClick<Content: View>: View {
    @EnvironmentObject private var store: FSPageReturnHighlight
    private let id: AnyHashable
    private let onTap: () -> Void
    private let content: Content
    private let fadeDuration: Double
    private let pressedColor: Color
    private let normalColor: Color
    private let autoDismiss: Bool
    private let autoDismissDelay: Double
    private let cardStyle: Bool
    private let cornerRadius: CGFloat
    private let padding: EdgeInsets

    @State private var isPressing = false
    /// 动画状态机：变灰时立刻 true，淡出时 withAnimation(false)
    @State private var animatedGray = false
    /// 淡出标志：区分变灰（瞬时）和淡出（spring）
    @State private var isFadingOut = false

    public init(id: AnyHashable,
                fadeDuration: Double = 0.6,
                pressedColor: Color = Color(UIColor.systemGray3),
                normalColor: Color = Color(.systemBackground),
                autoDismiss: Bool = false,
                autoDismissDelay: Double = 0.1,
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
        self.autoDismissDelay = autoDismissDelay
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
                            store.highlightedId = nil
                        }
                    }
                }
                .onLongPressGesture(minimumDuration: 0.5,
                    pressing: { isPressing = $0 },
                    perform: {
                        store.highlight(id)
                        onTap()
                        if autoDismiss {
                            DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
                                store.highlightedId = nil
                            }
                        }
                    })
                .onChange(of: store.highlightedId) { newValue in
                    handleStoreChange(newValue)
                }
                .onChange(of: isPressing) { newValue in
                    handlePressingChange(newValue)
                }
        } else {
            // 铺满模式：ZStack Rectangle 做背景（和卡片模式一致，withAnimation 可响应）
            ZStack { content }
                .listRowBackground(
                    Rectangle()
                        .fill(showGray ? pressedColor : normalColor)
                        // 长按时变灰瞬时，返回淡出走 spring
                        .animation(isFadingOut ? FSCellFadeAnimation(response: fadeDuration) : nil, value: animatedGray)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    store.highlight(id)
                    onTap()
                    if autoDismiss {
                        DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
                            store.highlightedId = nil
                        }
                    }
                }
                .onLongPressGesture(minimumDuration: 0.5,
                    pressing: { isPressing = $0 },
                    perform: {
                        store.highlight(id)
                        onTap()
                        if autoDismiss {
                            DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
                                store.highlightedId = nil
                            }
                        }
                    })
                .onChange(of: store.highlightedId) { newValue in
                    handleStoreChange(newValue)
                }
                .onChange(of: isPressing) { newValue in
                    handlePressingChange(newValue)
                }
        }
    }

    private func handleStoreChange(_ newValue: AnyHashable?) {
        let match: Bool = {
            guard let v = newValue else { return false }
            return v == id
        }()
        if match {
            // 变灰：瞬时（对齐 HighlightRow flash=true，无动画）
            isFadingOut = false
            animatedGray = true
        } else if animatedGray {
            // 淡出：显式 withAnimation（对齐 HighlightRow withAnimation{flash=false}）
            withAnimation(FSCellFadeAnimation(response: fadeDuration)) {
                isFadingOut = true
                animatedGray = false
            }
        }
    }

    private func handlePressingChange(_ newValue: Bool) {
        if newValue {
            isFadingOut = false
            animatedGray = true
        } else {
            // 松手：若 store 已接管（导航中），保持灰底等返回淡出；否则快速松开 → 淡出恢复
            let isHighlighted = store.highlightedId.map { $0 == id } ?? false
            if !isHighlighted {
                withAnimation(FSCellFadeAnimation(response: fadeDuration)) {
                    isFadingOut = true
                    animatedGray = false
                }
            }
        }
    }
}
