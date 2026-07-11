//
//  FSPageReturnHighlight.swift
//  FSKit
//
//  页面跳转型 cell 高亮（与 FSCellHighlight 解耦，互不影响）：
//  - 点击 cell 时点亮（变灰），随后 push 进编辑/详情页；
//    在 push 转场过程中原 cell 仍可见，灰底被「保留」下来
//  - 编辑页 pop 回来时，自动监听 UINavigationController.willShowViewControllerNotification：
//    当被盖住的 VC 即将重新显示（pop 转场一开始）即 reset()，灰底立即淡出，
//    与 pop 动画并行，消除「停顿」感；且完全与网络请求 / 列表重建解耦
//
//  ★ 无痕插拔：调用方无需创建变量、无需挂生命周期、无需手动 highlight/reset，
//    直接一行即可，row 内部自持有 store、自检测返回：
//  ```
//  FSPageReturnRow(id: model.aid, onTap: { pushEdit(model) }) {
//      MyRow(model: model)
//  }
//  ```
//

import SwiftUI
import UIKit

/// 高亮状态容器：由 row 内部自持有（@StateObject）。
/// 点击点亮某个 id（变灰）；当「被盖住的 VC」即将重新显示（pop 返回）时自动熄灭并触发淡出。
public final class FSPageReturnHighlight: ObservableObject {
    @Published public var highlightedId: AnyHashable?
    /// 点击时记下当前顶层 VC（即「即将被编辑页盖住、pop 回来要复位」的页面）
    private var coveredVC: UIViewController?
    private var token: NSObjectProtocol?

    public init() {
        // 监听 nav 即将显示某 VC：pop 回来时该通知在转场一开始即触发，
        // 与 pop 动画并行；push 编辑页时也会触发，但显示的不是 coveredVC，不会误复位。
        token = NotificationCenter.default.addObserver(
            forName: UINavigationController.willShowViewControllerNotification,
            object: nil, queue: .main
        ) { [weak self] note in
            guard let self = self, let covered = self.coveredVC else { return }
            let shown = note.userInfo?[UINavigationControllerViewControllerKey] as? UIViewController
            if shown === covered {
                self.highlightedId = nil
            }
        }
    }

    deinit {
        if let token = token {
            NotificationCenter.default.removeObserver(token)
        }
    }

    /// 点亮并记下当前顶层 VC（点击时由 row 内部调用）
    public func highlight(_ id: AnyHashable) {
        highlightedId = id
        coveredVC = fsTopViewController()
    }
}

/// 点击高亮行：点击瞬间点亮灰底并触发 onTap（通常 push 下一页），
/// 灰底保持到「被盖住的页面 pop 回来」时由内部自动复位淡出。完全自包含，调用方零依赖。
public struct FSPageReturnRow<Content: View>: View {
    private let id: AnyHashable
    private let onTap: () -> Void
    private let content: Content
    private let fadeDuration: Double
    private let pressedColor: Color
    private let normalColor: Color

    /// row 内部自持有高亮状态（含返回自动复位），调用方无需创建 / 传递任何变量
    @StateObject private var store = FSPageReturnHighlight()

    public init(id: AnyHashable,
                fadeDuration: Double = 0.6,
                pressedColor: Color = Color(UIColor.systemGray3),
                normalColor: Color = Color(UIColor.systemBackground),
                onTap: @escaping () -> Void,
                @ViewBuilder content: () -> Content) {
        self.id = id
        self.fadeDuration = fadeDuration
        self.pressedColor = pressedColor
        self.normalColor = normalColor
        self.onTap = onTap
        self.content = content()
    }

    public var body: some View {
        // 单行算出是否高亮（Optional<AnyHashable> 与 AnyHashable 比较）
        let on = store.highlightedId.map { $0 == id } ?? false
        return Button {
            store.highlight(id)
            onTap()
        } label: {
            // 淡出复用共享的 FSCellFadeAnimation（与 HighlightRow 点击淡出同一 spring 曲线 / 阻尼），
            // 仅 response = fadeDuration 由本 row 自带时长决定；曲线调一处全局生效。
            content
                .background(on ? pressedColor : normalColor)
                .animation(FSCellFadeAnimation(response: fadeDuration), value: on)
        }
    }
}

/// 取当前最顶层可见 VC（用于点击时记录「被盖住的页面」）。
/// 遍历 rootViewController → presented / nav.top / tab.selected，纯层级遍历，无 swizzle。
private func fsTopViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
    let window = scenes
        .first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive })?
        .windows
        .first(where: { $0.isKeyWindow })
        ?? scenes.first?.windows.first
    guard let vc = window?.rootViewController else { return nil }
    var current = vc
    while true {
        if let presented = current.presentedViewController, !(presented is UIAlertController) {
            current = presented
        } else if let nav = current as? UINavigationController, let top = nav.topViewController {
            current = top
        } else if let tab = current as? UITabBarController, let sel = tab.selectedViewController {
            current = sel
        } else {
            break
        }
    }
    return current
}
