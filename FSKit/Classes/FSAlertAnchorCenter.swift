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
//  - 全局 API（`FSUIKit.alert(style: .actionSheet, ...)`）是从 store / 闭包里发的，拿不到触发控件；
//  - 落点天然等于「用户认为他点的那个东西」，行高 44 还是 80、按钮还是整行，都不影响观感。
//

import SwiftUI
import UIKit

/// 最近一次轻点落点的登记处（窗口坐标）。
@MainActor
public final class FSAlertAnchorCenter: ObservableObject {

    public static let shared = FSAlertAnchorCenter()

    /// 最后一次轻点落点。nil = 本次启动还没点过。
    @Published public private(set) var tapPoint: CGPoint?

    /// 落点有效期。
    /// 弹窗可能是异步回调里弹的（网络回来、定时器、数据库回写），那时手指早就离开了几秒钟，
    /// 拿一个旧落点当锚点还不如退到底部兜底位置，故超时即作废。
    public static let tapPointMaxAge: TimeInterval = 2.0

    private var tapTime: Date = .distantPast

    private init() {}

    /// 记一次轻点（只由 `FSTapAnchorRecognizer` 在主线程调用）
    func recordTap(_ point: CGPoint) {
        tapPoint = point
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
