//
//  FSAlertAnchorCenter.swift
//  FSKit
//
//  2026-10-20 iOS 26 的 action sheet 锚点修复。
//
//  背景：iOS 18 以前 `.confirmationDialog` 在 iPhone 上是「从屏幕底部升起的 action sheet」，
//  位置与触发点无关；iOS 26 改成 **从挂载它的那个 view 旁边长出的 popover**
//  （Apple Liquid Glass 指南：An action sheet originates from the element that initiates the action,
//   instead of from the bottom edge of the display.）。
//
//  而 `FSAlertHost` 一直把 `.confirmationDialog` 挂在一个 0×0 的 `Color.clear` 上，那个视图在根
//  overlay 的 ZStack 里**居中** ⇒ 锚点恒等于屏幕正中 ⇒ 全 App 的 actionSheet 一律从屏幕中间冒出。
//
//  这里给出一条**零调用点改动**的修法：
//  在 window 上挂一条**被动**的触摸观察者（与 `FSCellTouchRecognizer` 同一套「永不 recognize」写法，
//  不抢手势、不延迟、不取消 touch），每次轻点记下落点；`FSAlertHost` 再把那个 0×0 的挂载视图
//  挪到落点上 ⇒ popover 的箭头就指着手指按下的位置。
//
//  取「落点」而不是「控件 frame」是刻意的：
//  - 全局 API（`FSUIKit.alert(...)`）是从 store / 闭包里发的，拿不到触发控件；
//  - 落点天然等于「用户认为他点的那个东西」，行高 44 还是 80、按钮还是整行，都不影响观感。
//

import SwiftUI
import UIKit

/// 最近一次轻点落点的登记处（窗口坐标）。
@Observable
@MainActor
public final class FSAlertAnchorCenter {

    public static let shared = FSAlertAnchorCenter()

    /// 最后一次轻点落点。nil = 本次启动还没点过。
    public private(set) var tapPoint: CGPoint?

    /// 落点有效期。
    /// 弹窗可能是异步回调里弹的（网络回来、定时器、数据库回写），那时手指早就离开了几秒钟，
    /// 拿一个旧落点当锚点还不如退到底部兜底位置，故超时即作废。
    public static let tapPointMaxAge: TimeInterval = 2.0

    @ObservationIgnored private var tapTime: Date = .distantPast

    private init() {}

    /// 记一次轻点（只由 `FSTapAnchorRecognizer` 在主线程调用）
    func recordTap(_ point: CGPoint) {
        // 同一落点不重复发布：避免根视图白重算一次、把锚点视图再"推"一下
        if tapPoint != point {
            tapPoint = point
        }
        tapTime = Date()
    }

    /// 当前可用的锚点矩形（窗口坐标）
    ///
    /// - 有新鲜落点 ⇒ 落点处 1×1 的小矩形，popover 箭头正指手指位置；
    /// - 否则 ⇒ 屏幕底部水平居中、home indicator 上方 8pt（近似原来的底部 action sheet 观感，
    ///   比「屏幕正中」合理得多）。
    func currentAnchorRect() -> CGRect {
        if let point = tapPoint, Date().timeIntervalSince(tapTime) <= Self.tapPointMaxAge {
            return CGRect(x: point.x, y: point.y, width: 1, height: 1)
        }
        return Self.bottomFallbackRect()
    }

    /// 无锚点时的兜底位置：底部中央
    static func bottomFallbackRect() -> CGRect {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        guard let window = scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first else {
            return CGRect(x: 0, y: 0, width: 1, height: 1)
        }
        let bounds = window.bounds
        let inset = window.safeAreaInsets.bottom
        return CGRect(x: bounds.midX, y: bounds.maxY - inset - 8, width: 1, height: 1)
    }

    /// 锚点矩形换算到 `proxy` 所在视图的局部坐标系。
    ///
    /// 落点是窗口坐标，而挂载视图的坐标系原点未必在 (0,0)（根视图落在安全区内、
    /// 页面内容在导航栏之下），必须减掉该视图自己的全局原点。
    func localRect(in proxy: GeometryProxy, frozen: CGRect? = nil) -> CGRect {
        let target = frozen ?? currentAnchorRect()
        let origin = proxy.frame(in: .global).origin
        return target.offsetBy(dx: -origin.x, dy: -origin.y)
    }
}

// MARK: - 被动触摸观察

/// 只记落点，绝不参与手势竞争。
///
/// 与 `FSCellTouchRecognizer` 同一套语义：全程停留在 `.possible`，抬手后置 `.failed`，
/// `cancelsTouchesInView = false`、不延迟 touch ⇒ 对按钮、列表滚动、左滑返回零影响。
/// 手指移动超过 `movementLimit` 判为滚动，不记落点（否则「滑完列表紧接着弹窗」会把锚点定在滑动终点）。
private final class FSTapAnchorRecognizer: UIGestureRecognizer {

    private var startLocation: CGPoint = .zero
    private var moved = false
    private var tracking = false

    private let movementLimit: CGFloat = 10

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        if (event.allTouches?.count ?? 1) > 1 {
            tracking = false
            return
        }
        tracking = true
        moved = false
        startLocation = touches.first?.location(in: view) ?? .zero

        // 落点在**按下瞬间**就登记。锚点视图必须先就位：
        // 原实现只在 touchesEnded 记录，和按钮 action（show → present）几乎同帧，
        // 视图仍在移动时 iOS 26 的 popover 会丢弃这次呈现（2026-10-20 武器库「清理」首点不弹）。
        if let window = view?.window, let touch = touches.first {
            FSAlertAnchorCenter.shared.recordTap(touch.location(in: window))
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard tracking, !moved, let location = touches.first?.location(in: view) else { return }
        if hypot(location.x - startLocation.x, location.y - startLocation.y) > movementLimit {
            moved = true
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        defer {
            tracking = false
            if state == .possible { state = .failed }
        }
        guard tracking, !moved,
              let window = view?.window,
              let touch = touches.first else { return }
        FSAlertAnchorCenter.shared.recordTap(touch.location(in: window))
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        tracking = false
        if state == .possible { state = .failed }
    }

    override func reset() {
        super.reset()
        tracking = false
        moved = false
    }
}

/// 零尺寸探针：把观察者挂到 window 上。
///
/// 用 `didMoveToWindow` 而不是 `onAppear` —— 前者拿得到 window，后者在根 overlay 首次出现时
/// 可能还没有 window（SceneDelegate 建窗口与首帧的时序不保证）。
struct FSTapAnchorProbe: UIViewRepresentable {

    func makeUIView(context: Context) -> UIView {
        let view = ProbeView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    final class ProbeView: UIView {

        override func didMoveToWindow() {
            super.didMoveToWindow()
            install()
        }

        private func install() {
            guard let window else { return }
            let installed = window.gestureRecognizers?.contains { $0 is FSTapAnchorRecognizer } ?? false
            guard !installed else { return }

            let recognizer = FSTapAnchorRecognizer(target: nil, action: nil)
            recognizer.cancelsTouchesInView = false
            recognizer.delaysTouchesBegan = false
            recognizer.delaysTouchesEnded = false
            window.addGestureRecognizer(recognizer)
        }
    }
}

// MARK: - 修饰器版：锚在落点的 confirmationDialog

// 页内直接写 `.confirmationDialog` 的那批（2026-10-20 统计 14 处）挂在整页 body 上，
// 于是 popover 锚在「页面正中央」。这里给一个形状完全相同、只是把挂载视图挪到落点的替代品：
//
//     .confirmationDialog("选择图片", isPresented: $show, titleVisibility: .visible) { ... }
//     .fsTapAnchoredDialog("选择图片", isPresented: $show, titleVisibility: .visible) { ... }
//
// 参数名、顺序、尾随闭包全部对齐系统 API（`titleVisibility` 默认 `.automatic`），调用点只换名字。
// 系统 `presenting:` 那一族暂不需要，故未提供。

public extension View {

    /// 同系统的 `.confirmationDialog(_:isPresented:titleVisibility:actions:)`，
    /// 但弹窗锚定在**最后一次轻点落点**上（见 `FSAlertAnchorCenter`）。
    func fsTapAnchoredDialog<Actions: View>(_ title: String,
                                            isPresented: Binding<Bool>,
                                            titleVisibility: Visibility = .automatic,
                                            @ViewBuilder actions: @escaping () -> Actions) -> some View {
        modifier(FSTapAnchoredDialog(title: title,
                                     isPresented: isPresented,
                                     titleVisibility: titleVisibility,
                                     actions: actions))
    }

    /// 带 `message` 的重载，形状对齐系统的
    /// `.confirmationDialog(_:isPresented:titleVisibility:actions:message:)`。
    func fsTapAnchoredDialog<Actions: View, Message: View>(_ title: String,
                                                           isPresented: Binding<Bool>,
                                                           titleVisibility: Visibility = .automatic,
                                                           @ViewBuilder actions: @escaping () -> Actions,
                                                           @ViewBuilder message: @escaping () -> Message) -> some View {
        modifier(FSTapAnchoredMessageDialog(title: title,
                                            isPresented: isPresented,
                                            titleVisibility: titleVisibility,
                                            actions: actions,
                                            message: message))
    }
}

/// 锚在落点的挂载点：一个 1×1 的透明矩形，位置跟着最后一次轻点走。
///
/// - 用 `.overlay` 而不是改内容本身：overlay 不参与布局，对页面零影响；
/// - `allowsHitTesting(false)`：它可能正好压在列表某一行上，绝不能吃触摸；
/// - 弹窗在屏时用 `frozen` 快照：否则「点空白处关闭」那一下会先把挂载视图挪走、
///   让 popover 抖一帧再消失。
private struct FSTapAnchorSlot<Dialog: View>: View {

    private let frozen: CGRect?
    private let dialog: Dialog

    private let anchor = FSAlertAnchorCenter.shared

    init(frozen: CGRect?, @ViewBuilder dialog: () -> Dialog) {
        self.frozen = frozen
        self.dialog = dialog()
    }

    var body: some View {
        GeometryReader { proxy in
            let rect = anchor.localRect(in: proxy, frozen: frozen)
            dialog
                .frame(width: 1, height: 1)
                .position(x: rect.midX, y: rect.midY)
                .allowsHitTesting(false)
        }
    }
}

/// `.fsTapAnchoredDialog(_:isPresented:titleVisibility:actions:)` 的实现
private struct FSTapAnchoredDialog<Actions: View>: ViewModifier {

    let title: String
    @Binding var isPresented: Bool
    let titleVisibility: Visibility
    let actions: () -> Actions

    @State private var frozen: CGRect?

    func body(content: Content) -> some View {
        content
            .overlay {
                FSTapAnchorSlot(frozen: frozen) {
                    Color.clear
                        .confirmationDialog(title,
                                            isPresented: $isPresented,
                                            titleVisibility: titleVisibility,
                                            actions: actions)
                }
            }
            .onChange(of: isPresented) { _, presented in
                frozen = presented ? FSAlertAnchorCenter.shared.currentAnchorRect() : nil
            }
    }
}

/// 带 `message` 的那一版
private struct FSTapAnchoredMessageDialog<Actions: View, Message: View>: ViewModifier {

    let title: String
    @Binding var isPresented: Bool
    let titleVisibility: Visibility
    let actions: () -> Actions
    let message: () -> Message

    @State private var frozen: CGRect?

    func body(content: Content) -> some View {
        content
            .overlay {
                FSTapAnchorSlot(frozen: frozen) {
                    Color.clear
                        .confirmationDialog(title,
                                            isPresented: $isPresented,
                                            titleVisibility: titleVisibility,
                                            actions: actions,
                                            message: message)
                }
            }
            .onChange(of: isPresented) { _, presented in
                frozen = presented ? FSAlertAnchorCenter.shared.currentAnchorRect() : nil
            }
    }
}
