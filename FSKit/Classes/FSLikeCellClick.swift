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
//  - 长按仅做视觉（按下立即变灰、松手淡出），不触发回调；规避了 SwiftUI pressing 区分不了
//    「松手 vs 滚动取消」导致滚动误触发回调的问题。变灰由 pressing=true 立即触发。
//  - 点击改用 UIKit UITapGestureRecognizer 子类（iOS 18+ UIGestureRecognizerRepresentable）：
//    在 touchesMoved 中累计位移，超过 5pt 即判为滑动、置 .failed，不触发回调，
//    解决「上下滑动列表时误触发 cell 点击、悄悄改了数据」的问题。
//    tap 是 discrete 手势（抬手才判定、不持续追踪 touch），不会像 minDuration=0 的长按那样抢走滚动。
//    cancelsTouchesInView=false，保证列表滚动不受影响。

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
        // UIKit 严格 tap：touchesMoved 位移超 5pt 即 .failed，避免滑动误触发点击
        let tap = FSTapRepresentable { triggerTap() }

        if cardStyle {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(showGray ? pressedColor : normalColor)
                )
                .padding(padding)
                .listRowBackground(Color.clear)
                .contentShape(Rectangle())
                .gesture(tap)
                .onLongPressGesture(minimumDuration: 0.5,
                    pressing: { handlePressingChange($0) },
                    perform: {})
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
                .gesture(tap)
                .onLongPressGesture(minimumDuration: 0.5,
                    pressing: { handlePressingChange($0) },
                    perform: {})
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

    /// 轻点回调：由 UIKit tap 在「几乎不动的按下→抬起」时分发
    private func triggerTap() {
        store.highlight(id)
        onTap()
        if autoDismiss {
            DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
                store.highlightedId = nil
            }
        }
    }

    /// 长按按压状态变化：仅做视觉（变灰/淡出），不触发回调
    private func handlePressingChange(_ newValue: Bool) {
        if newValue {
            // 手指按下（pressing 立即 true）：立即变灰
            isFadingOut = false
            animatedGray = true
        } else {
            // 松手或手势被取消：不回调，仅淡出恢复（store 已接管时保持灰底）
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

// MARK: - UIKit 严格点击识别（iOS 18+ UIGestureRecognizerRepresentable）

/// 严格 tap：allowableMovement 收紧到 5pt，手指移动超过该值即 .failed，
/// 从而「滑动/滚动列表」时不触发点击，只有「几乎不动的按下→抬起」才算轻点。
/// tap 是 discrete 手势（抬手才判定、不持续追踪 touch），cancelsTouchesInView=false，
/// 不会抢走列表的滚动手势。
/// 严格 tap 识别器：在 touchesMoved 中累计手指位移，超过 movementLimit 即判为滑动、置 .failed，
/// 从而「滑动/滚动列表」时不触发点击。比 allowableMovement 更精确（移动即判，不必等抬手）。
private final class FSStrictTapGestureRecognizer: UITapGestureRecognizer {
    /// 位移超过该值（pt）即判为滑动、手势失败
    var movementLimit: CGFloat = 5
    private var startLocation: CGPoint = .zero

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        if let loc = touches.first?.location(in: view) {
            startLocation = loc
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard state == .possible, let loc = touches.first?.location(in: view) else { return }
        if hypot(loc.x - startLocation.x, loc.y - startLocation.y) > movementLimit {
            state = .failed
        }
    }
}

private struct FSTapRepresentable: UIGestureRecognizerRepresentable {
    var onTap: () -> Void

    func makeUIGestureRecognizer(context: Context) -> FSStrictTapGestureRecognizer {
        let gr = FSStrictTapGestureRecognizer(target: nil, action: nil)
        gr.movementLimit = 5
        gr.cancelsTouchesInView = false
        return gr
    }

    func handleUIGestureRecognizerAction(_ recognizer: FSStrictTapGestureRecognizer, context: Context) {
        if recognizer.state == .recognized {
            onTap()
        }
    }
}
