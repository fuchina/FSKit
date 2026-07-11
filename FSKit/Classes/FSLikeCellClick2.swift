//
//  FSLikeCellClick2.swift
//  FSKit
//
//  cell 点击动画容器 v2：
//  - 铺满整行
//  - 支持圆角（cornerRadius）和内边距（padding），圆角模式自动做白色卡片+透明间距
//  - 点击变灰（跨页保留或 autoDismiss 自动淡出）+ 长按变灰
//  - 灰底在 content 下面，不遮文字
//  - 复用 FSPageReturnHighlight store + FSCellFadeAnimation 曲线
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
    private let cornerRadius: CGFloat
    private let padding: EdgeInsets

    @State private var isPressing = false

    public init(id: AnyHashable,
                fadeDuration: Double = 0.6,
                pressedColor: Color = Color(UIColor.systemGray3),
                normalColor: Color = Color(.systemBackground),
                autoDismiss: Bool = false,
                cornerRadius: CGFloat = 0,
                padding: EdgeInsets = EdgeInsets(),
                onTap: @escaping () -> Void,
                @ViewBuilder content: () -> Content) {
        self.id = id
        self.fadeDuration = fadeDuration
        self.pressedColor = pressedColor
        self.normalColor = normalColor
        self.autoDismiss = autoDismiss
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.onTap = onTap
        self.content = content()
    }

    public var body: some View {
        let isHighlighted = store.highlightedId.map { $0 == id } ?? false
        let showGray = isPressing || isHighlighted

        ZStack {
            // 灰底层：在 content 下面，不遮文字，圆角跟随
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(showGray ? pressedColor : Color.clear)
                .padding(padding)
                .animation(FSCellFadeAnimation(response: fadeDuration), value: showGray)

            // 内容层：自带白色背景+圆角+内边距
            content
                .background(normalColor)
                .cornerRadius(cornerRadius)
                .padding(padding)
        }
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
    }
}
