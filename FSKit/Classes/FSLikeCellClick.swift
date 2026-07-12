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
//  - 长按回调改用 UILongPressGestureRecognizer（iOS 18+ UIGestureRecognizerRepresentable）：
//    识别器 minimumPressDuration≈0（手指刚按下即 .began → 立即变灰）；是否算「长按」由 0.5s 计时器决定，
//    在 handleUIGestureRecognizerAction 中按状态分发：.ended 时满 0.5s→长按回调，未达→轻点回调，滚动/取消→仅淡出。
//  - cancelsTouchesInView = false，保证长按中列表仍可滚动；轻点与长按共用同一识别器状态机分发，
//    不再使用 SwiftUI .onTapGesture（其底层 UITapGestureRecognizer 会被 minDuration=0 的长按识别器认领而吞掉点击）。

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
    /// 长按阈值（秒）
    private let longPressDuration: Double = 0.5
    /// 长按中手指位移超过该值（pt）视为滚动，取消回调
    private let longPressScrollThreshold: CGFloat = 10

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
        // 长按与轻点统一由同一个长按识别器（minimumPressDuration≈0）的状态机分发：
        // 按下即灰；松手时按「是否满 0.5s / 是否滚动」分别触发长按回调或轻点回调。
        // 不再使用 SwiftUI .onTapGesture，避免其底层 UITapGestureRecognizer 被长按识别器认领而吞掉点击。
        let longPress = FSLongPressRepresentable(
            longPressDuration: longPressDuration,
            scrollThreshold: longPressScrollThreshold,
            onBegan: { longPressBegan() },
            onLongPress: { longPressEnded() },
            onTap: { triggerTap() },
            onCancel: { longPressCancelled() }
        )

        if cardStyle {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(showGray ? pressedColor : normalColor)
                )
                .padding(padding)
                .listRowBackground(Color.clear)
                .contentShape(Rectangle())
                .gesture(longPress)
                .onChange(of: store.highlightedId) { newValue in
                    handleStoreChange(newValue)
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
                .gesture(longPress)
                .onChange(of: store.highlightedId) { newValue in
                    handleStoreChange(newValue)
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

    private func triggerTap() {
        // 轻点回调：由长按状态机在「未达 0.5s 且未滚动」时分发，等价于原 .onTapGesture 行为
        store.highlight(id)
        onTap()
        if autoDismiss {
            DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
                store.highlightedId = nil
            }
        }
    }

    private func longPressBegan() {
        // 手指按下（触摸即灰，几乎无延迟）：立即变灰；是否算「长按」由 0.5s 计时器决定
        isFadingOut = false
        animatedGray = true
    }

    private func longPressEnded() {
        // 真松手（未滚动）：触发回调
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
    }

    private func longPressCancelled() {
        // 手势被取消（滚动抢走触摸）或滚动位移超阈值：不回调，仅淡出恢复
        let isHighlighted = store.highlightedId.map { $0 == id } ?? false
        if !isHighlighted {
            withAnimation(FSCellFadeAnimation(response: fadeDuration)) {
                isFadingOut = true
                animatedGray = false
            }
        }
    }
}

// MARK: - UIKit 长按识别（iOS 18+ UIGestureRecognizerRepresentable）

/// 长按识别器子类：仅用于在「一次手势生命周期内」保存可变状态（识别起点 / 是否已识别 / 是否已滚动）。
/// 不重写任何父类方法；回调闭包由 FSLongPressRepresentable 持有，在 handleUIGestureRecognizerAction 中调用。
private final class FSLongPressGestureRecognizer: UILongPressGestureRecognizer {
    var startLocation: CGPoint = .zero
    /// 是否已达到长按阈值（0.5s）：达到后松手才触发回调
    var recognized = false
    /// 长按中是否已发生明显位移（=列表在滚）：发生时取消回调
    var scrolled = false
    /// 0.5s 长按计时任务；达到阈值后置 recognized=true；手势结束/滚动/取消时撤销
    var workItem: DispatchWorkItem?
}

private struct FSLongPressRepresentable: UIGestureRecognizerRepresentable {
    /// 达到该时长才视为长按（决定回调时机），与「触摸即灰」无关
    var longPressDuration: Double
    var scrollThreshold: CGFloat
    var onBegan: () -> Void
    var onLongPress: () -> Void
    var onTap: () -> Void
    var onCancel: () -> Void

    /// 识别器的最小按下时长：设为 0，使 .began 在手指刚按下时立刻触发 → 立即变灰（无任何等待）。
    /// 真正的「长按 0.5s」判定由 longPressDuration 计时器负责，不依赖识别器的 minimumPressDuration。
    private let pressBeganDelay: Double = 0

    func makeUIGestureRecognizer(context: Context) -> FSLongPressGestureRecognizer {
        let gr = FSLongPressGestureRecognizer(target: nil, action: nil)
        gr.minimumPressDuration = pressBeganDelay
        // 放大多指定位移容差，避免识别器因手指移动而自行失败；
        // 是否「滚动」完全由下方 .changed 的 scrollThreshold 判定
        gr.allowableMovement = 10000
        gr.cancelsTouchesInView = false
        return gr
    }

    func updateUIGestureRecognizer(_ recognizer: FSLongPressGestureRecognizer, context: Context) {
        // minimumPressDuration 固定为 pressBeganDelay（触摸即灰），不随 longPressDuration 变化
    }

    func handleUIGestureRecognizerAction(_ recognizer: FSLongPressGestureRecognizer, context: Context) {
        let r = recognizer
        switch r.state {
        case .began:
            // 手指刚按下：记录起点、重置状态、立即变灰，并启动长按计时
            r.startLocation = r.location(in: r.view)
            r.recognized = false
            r.scrolled = false
            r.workItem?.cancel()
            let item = DispatchWorkItem { [weak r] in
                r?.recognized = true
            }
            r.workItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + longPressDuration, execute: item)
            onBegan()
        case .changed:
            // 已按下后若手指明显移动（=列表在滚），视为取消：撤销计时并淡出
            if !r.scrolled &&
                hypot(r.location(in: r.view).x - r.startLocation.x,
                       r.location(in: r.view).y - r.startLocation.y) > scrollThreshold {
                r.scrolled = true
                r.workItem?.cancel()
                onCancel()
            }
        case .ended:
            r.workItem?.cancel()
            if r.scrolled {
                onCancel()       // 已滚动 → 仅淡出，不回调
            } else if r.recognized {
                onLongPress()    // 真松手且达到 0.5s → 长按回调
            } else {
                onTap()          // 未达阈值（轻点）→ 点击回调
            }
            r.recognized = false
            r.scrolled = false
        case .cancelled, .failed:
            r.workItem?.cancel()
            r.recognized = false
            r.scrolled = false
            onCancel()
        default:
            break
        }
    }
}
