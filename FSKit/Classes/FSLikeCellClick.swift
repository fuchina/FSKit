//
//  FSLikeCellClick.swift
//  FSKit
//
//  cell 点击动画容器：尽可能 1:1 复刻 UITableViewCell 的原生选中手感。
//  - 铺满模式（默认）：listRowBackground 统一管理白色/灰底，铺满整行
//  - 卡片模式（cardStyle=true）：灰底在 content 的 background 上切换，白色卡片+圆角+间距
//  - 点击变灰 + 按住变灰 + 返回淡出（跨页保留由 FSPageReturnHighlight store 驱动）
//
//  ★ 核心：不再用 SwiftUI 的 .onLongPressGesture + UITapGestureRecognizer 两套手势拼凑，
//    而是用单个自定义 UIGestureRecognizer（FSCellTouchRecognizer）直接追踪原始 touch，
//    完整复刻 UITableViewCell 的三段语义：
//    1) delaysContentTouches：落指后延迟 highlightDelay 秒才点亮；这段窗口内一旦手指
//       移动超过 movementLimit（滑动列表 / 左滑 pop）立刻作废，绝不闪灰；
//    2) 点亮后继续拖动（滚动开始）→ 立即熄灭（瞬时，无淡出，贴合原生滚动即消）；
//    3) 抬手且整段位移未超阈值 → 视为轻点，触发 onTap（无论按了多久，贴合原生
//       didSelectRow 在 touch-up 触发）。被 contextMenu / 系统打断则收到 touchesCancelled，
//       瞬时熄灭且不回调。
//  - cancelsTouchesInView=false，识别器全程被动（不进入 recognized，不抢列表滚动）；
//    滚动手势夺权时 UIKit 会给本识别器发 touchesCancelled，正是熄灭灰底的信号。
//  - 变灰/滚动熄灭都是瞬时（无动画，贴合原生）；只有「点击后 push → 返回」这一路
//    由 store 驱动走 spring 淡出（FSCellFadeAnimation）。
//  - fill 模式 listRowBackground 不响应 withAnimation，靠隐式 .animation(value:) 驱动淡出。

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
    /// 落指后延迟多久才点亮（秒），复刻 UITableView 的 delaysContentTouches（原生约 0.15s）。
    /// 这段窗口内一旦手指移动超过 movementLimit（滑动 / 左滑 pop）就作废，绝不闪灰。
    private let pressHighlightDelay: Double
    /// 手指位移超过该值（pt）即判为滚动：撤销待点亮、熄灭已点亮、抬手不再算轻点。
    private let movementLimit: CGFloat

    @State private var animatedGray = false
    /// 淡出标志：区分「瞬时变灰/熄灭」与「返回时 spring 淡出」
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
                pressHighlightDelay: Double = 0.15,
                movementLimit: CGFloat = 10,
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
        self.pressHighlightDelay = pressHighlightDelay
        self.movementLimit = movementLimit
        self.onTap = onTap
        self.content = content()
    }

    @ViewBuilder
    public var body: some View {
        let showGray = animatedGray
        // 单一自定义识别器：原始 touch 追踪，复刻 UITableViewCell 选中语义
        let touch = FSCellTouchRepresentable(
            highlightDelay: pressHighlightDelay,
            movementLimit: movementLimit,
            onHighlightChange: { setHighlight($0) },
            onTap: { triggerTap() }
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
                .gesture(touch)
                .onChange(of: store.highlightedId) { _, newValue in
                    handleStoreChange(newValue)
                }
        } else {
            // 铺满模式：listRowBackground 做背景，隐式 .animation(value:) 驱动返回淡出
            ZStack { content }
                .listRowBackground(
                    Rectangle()
                        .fill(showGray ? pressedColor : normalColor)
                        // 仅「返回淡出」走 spring；变灰 / 滚动熄灭为瞬时（isFadingOut=false → animation nil）
                        .animation(isFadingOut ? FSCellFadeAnimation(response: fadeDuration) : nil, value: animatedGray)
                )
                .contentShape(Rectangle())
                .gesture(touch)
                .onChange(of: store.highlightedId) { _, newValue in
                    handleStoreChange(newValue)
                }
        }
    }

    // MARK: - 状态驱动

    private func handleStoreChange(_ newValue: AnyHashable?) {
        let match: Bool = {
            guard let v = newValue else { return false }
            return v == id
        }()
        if match {
            // 变灰：瞬时（对齐原生 flash，无动画）
            isFadingOut = false
            animatedGray = true
        } else if animatedGray {
            // 淡出：显式 withAnimation（对齐原生返回时 deselectRow(animated:) 的淡出）
            withAnimation(FSCellFadeAnimation(response: fadeDuration)) {
                isFadingOut = true
                animatedGray = false
            }
        }
    }

    /// 识别器驱动的高亮开关（点亮 / 滚动熄灭），均为瞬时，贴合原生。
    private func setHighlight(_ on: Bool) {
        if on {
            // 落指延迟后点亮：瞬时
            isFadingOut = false
            animatedGray = true
        } else {
            // 滚动 / 取消导致熄灭：瞬时（store 已接管则保持灰底等返回淡出）
            let taken = store.highlightedId.map { $0 == id } ?? false
            if !taken {
                isFadingOut = false
                animatedGray = false
            }
        }
    }

    /// 轻点回调：由识别器在「抬手且整段位移未超阈值」时分发（无论按了多久）。
    private func triggerTap() {
        store.highlight(id)
        onTap()
        if autoDismiss {
            DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
                store.highlightedId = nil
            }
        }
    }
}

// MARK: - 原生级触摸追踪识别器（iOS 18+ UIGestureRecognizerRepresentable）

/// 直接追踪原始 touch，复刻 UITableViewCell 的选中语义。全程停留在 .possible（被动，
/// 不进入 recognized），因此绝不与列表滚动手势争夺；cancelsTouchesInView=false。
/// - touchesBegan：记录起点，安排「延迟点亮」任务（delaysContentTouches）。
/// - touchesMoved：位移超阈值 → 判为滚动：撤销待点亮、熄灭已点亮、作废本次轻点。
/// - touchesEnded：未作废 → 抬手轻点（触发 onTap）；否则忽略。
/// - touchesCancelled：被滚动 / contextMenu / 系统打断 → 瞬时熄灭、作废轻点。
private final class FSCellTouchRecognizer: UIGestureRecognizer {
    var highlightDelay: Double = 0.15
    var movementLimit: CGFloat = 10
    /// 高亮开关（true=点亮，false=熄灭），由 SwiftUI 侧做瞬时变灰/熄灭
    var onHighlightChange: ((Bool) -> Void)?
    /// 轻点回调（抬手判定）
    var onTapAction: (() -> Void)?

    private var startLocation: CGPoint = .zero
    private var tracking = false          // 是否正在追踪单指
    private var invalidated = false       // 已判为滚动/取消 → 抬手不再算轻点
    private var highlighted = false       // 灰底是否已点亮
    private var pendingHighlight: DispatchWorkItem?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        // 多指：直接作废（原生 cell 忽略多指选中）
        if tracking || touches.count > 1 || (event.allTouches?.count ?? 1) > 1 {
            invalidate(clearHighlight: true)
            return
        }
        tracking = true
        invalidated = false
        highlighted = false
        startLocation = touches.first?.location(in: view) ?? .zero
        scheduleHighlight()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard tracking, !invalidated, let loc = touches.first?.location(in: view) else { return }
        if hypot(loc.x - startLocation.x, loc.y - startLocation.y) > movementLimit {
            // 判为滚动：撤销待点亮 + 瞬时熄灭 + 作废轻点
            invalidate(clearHighlight: true)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        let shouldTap = tracking && !invalidated
        cancelPending()
        if shouldTap {
            // 抬手且没大幅移动 → 轻点（原生：无论按多久都算选中，在 touch-up 触发）
            onTapAction?()
        }
        finish()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        invalidate(clearHighlight: true)
        finish()
    }

    // MARK: 内部

    private func scheduleHighlight() {
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.tracking, !self.invalidated else { return }
            self.highlighted = true
            self.onHighlightChange?(true)
        }
        pendingHighlight = work
        DispatchQueue.main.asyncAfter(deadline: .now() + highlightDelay, execute: work)
    }

    private func cancelPending() {
        pendingHighlight?.cancel()
        pendingHighlight = nil
    }

    private func invalidate(clearHighlight: Bool) {
        invalidated = true
        cancelPending()
        if clearHighlight && highlighted {
            highlighted = false
            onHighlightChange?(false)
        }
    }

    /// 触摸序列结束：复位内部状态，并把识别器置 .failed（从未真正 recognize，
    /// 让 UIKit 干净复位，绝不消费或取消其它手势的 touch）。
    private func finish() {
        cancelPending()
        tracking = false
        highlighted = false
        if state == .possible {
            state = .failed
        }
    }

    override func reset() {
        super.reset()
        tracking = false
        invalidated = false
        highlighted = false
        cancelPending()
    }
}

private struct FSCellTouchRepresentable: UIGestureRecognizerRepresentable {
    var highlightDelay: Double
    var movementLimit: CGFloat
    var onHighlightChange: (Bool) -> Void
    var onTap: () -> Void

    func makeUIGestureRecognizer(context: Context) -> FSCellTouchRecognizer {
        let gr = FSCellTouchRecognizer(target: nil, action: nil)
        gr.highlightDelay = highlightDelay
        gr.movementLimit = movementLimit
        gr.cancelsTouchesInView = false
        gr.delaysTouchesBegan = false
        gr.delaysTouchesEnded = false
        gr.onHighlightChange = onHighlightChange
        gr.onTapAction = onTap
        return gr
    }

    func updateUIGestureRecognizer(_ recognizer: FSCellTouchRecognizer, context: Context) {
        // body 每次重建都刷新闭包与参数，避免闭包捕获旧 @State
        recognizer.highlightDelay = highlightDelay
        recognizer.movementLimit = movementLimit
        recognizer.onHighlightChange = onHighlightChange
        recognizer.onTapAction = onTap
    }

    func handleUIGestureRecognizerAction(_ recognizer: FSCellTouchRecognizer, context: Context) {
        // 逻辑全部在识别器内部通过闭包分发，此处无需处理
    }
}
