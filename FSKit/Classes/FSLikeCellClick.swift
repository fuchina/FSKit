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
//  - 长按「松手才回调」：onLongPressGesture 的 perform 置空，回调改在 pressing 回落（松手）时触发，
//    用 0.5s 计时器（longPressFired）判断是否达到长按阈值；未达阈值（轻点）不回调仅淡出。
//  - 变灰时机：pressing=true 在手指按下时立即触发 → 立刻变灰（不依赖 minimumDuration）。
//  - 已知限制：SwiftUI 的 pressing 在「手指真抬起」与「手势被滚动取消」时都会回落 false，二者无法区分；
//    若按住满 0.5s 后再滚动，仍会误触发回调。彻底区分「滚动取消」需在 List 层接入滚动信号下传（待后续）。

import SwiftUI

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
    /// 长按阈值（秒）：达到后才视为长按，松手时据此决定是否回调
    private let longPressDuration: Double = 0.5

    @State private var animatedGray = false
    /// 淡出标志：区分变灰（瞬时）和淡出（spring）
    @State private var isFadingOut = false
    /// 是否正在按压（onLongPressGesture 的 pressing）
    @State private var isPressing = false
    /// 长按计时任务：达到阈值后置 longPressFired=true，松开时据此决定是否触发回调
    @State private var longPressWorkItem: DispatchWorkItem?
    /// 是否已达到长按阈值（0.5s）：达到后松手才触发回调
    @State private var longPressFired = false

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
                .onTapGesture { triggerTap() }
                .onLongPressGesture(minimumDuration: longPressDuration,
                    pressing: { isPressing = $0 },
                    perform: {})
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
                .onTapGesture { triggerTap() }
                .onLongPressGesture(minimumDuration: longPressDuration,
                    pressing: { isPressing = $0 },
                    perform: {})
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

    /// 轻点回调：等价于原 .onTapGesture 行为
    private func triggerTap() {
        store.highlight(id)
        onTap()
        if autoDismiss {
            DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
                store.highlightedId = nil
            }
        }
    }

    private func handlePressingChange(_ newValue: Bool) {
        if newValue {
            // 手指按下（pressing 立即 true）：立即变灰，并启动长按计时
            isFadingOut = false
            animatedGray = true
            longPressFired = false
            longPressWorkItem?.cancel()
            let item = DispatchWorkItem { longPressFired = true }
            longPressWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + longPressDuration, execute: item)
        } else {
            // 松手或手势被取消：只有达到长按阈值才回调
            longPressWorkItem?.cancel()
            if longPressFired {
                // 长按松手 → 触发回调
                store.highlight(id)
                onTap()
                if autoDismiss {
                    DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
                        store.highlightedId = nil
                    }
                }
                // 若 store 已接管（导航中）保持灰底等返回淡出；否则淡出恢复
                let isHighlighted = store.highlightedId.map { $0 == id } ?? false
                if !isHighlighted {
                    withAnimation(FSCellFadeAnimation(response: fadeDuration)) {
                        isFadingOut = true
                        animatedGray = false
                    }
                }
            } else {
                // 未达阈值（轻点或滚动取消）：不回调，仅淡出恢复
                let isHighlighted = store.highlightedId.map { $0 == id } ?? false
                if !isHighlighted {
                    withAnimation(FSCellFadeAnimation(response: fadeDuration)) {
                        isFadingOut = true
                        animatedGray = false
                    }
                }
            }
            longPressFired = false
        }
    }
}
