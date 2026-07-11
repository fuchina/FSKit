//
//  FSPageReturnHighlight.swift
//  FSKit
//
//  页面跳转型 cell 高亮（与 FSCellHighlight 解耦，互不影响）：
//  - 点击 cell 时点亮（变灰），随后 push 进编辑/详情页；
//    在 push 转场过程中原 cell 仍可见，灰底被「保留」下来
//  - 编辑页 pop 回来时，自动监听 UINavigationController 的 will/didShow 通知
//    （用字符串字面量取通知名，避免 UIKit 在部分 Swift 版本未桥出类型化成员而报错）：
//    以「点击时刻」做去抖——点击后极短时间内的 willShow 视为 push 转场而忽略，
//    超过阈值的 willShow 才视为返回，灰底延后一帧淡出，与 pop 动画并行；
//    完全不依赖 VC 实例比较、不依赖网络请求，也无需调用方挂任何生命周期
//
//  ★★ 真·无痕插拔（推荐用法）：用 FSPageReturnList 容器包住你的 List/ForEach，
//     容器内部用 @StateObject 托管共享 store 并经 environmentObject 自动下发给每个 row。
//     调用方 **零属性、零传参、零生命周期 override**，row 内部自检测返回并淡出：
//  ```
//  FSPageReturnList {                       // ← 容器托管 store，自动注入
//      List {
//          ForEach(items, id: \.id) { model in
//              FSPageReturnRow(id: model.aid, onTap: { pushEdit(model) }) {
//                  MyRow(model: model)      // ← row 从 @EnvironmentObject 拿 store，无需传
//              }
//          }
//      }
//  }
//  ```
//  ⚠️ 前提：承载这棵 SwiftUI 树的 UIHostingController **只建一次、靠数据驱动刷新**
//     （数据用 ObservableObject 的 @Published 驱动 List）。若宿主每次 reload 都销毁重建
//     整棵树，容器的 @StateObject 会随树一起新建 → store 被重置 → 灰底丢失、看不到淡出。
//     UIKit 宿主请务必「hosting 建一次 + 数据驱动」，不要在每次刷新里重建 rootView。
//
//  ⚠️ FSPageReturnRow 用 @EnvironmentObject 取共享 store，**必须**包在 FSPageReturnList
//     之内使用；脱离容器单独使用会因环境对象缺失而崩溃（@EnvironmentObject 无默认值）。
//
//  ★ content 铺满整行的注意事项：
//     FSPageReturnRow 的 content 需使用「主动撑满」的布局（如 HStack{...Spacer()}），
//     不要只用 frame(maxWidth: .infinity)——Button 在 List 里是紧凑布局，被动等约束撑不开。
//     参照 FSBirthRow 的写法：HStack{ content; Spacer() }。
//

import SwiftUI
import UIKit

/// 高亮状态容器（由 FSPageReturnList 用 @StateObject 托管，经 environment 共享给所有 row）：
/// 点击点亮某个 id（变灰）；当页面从下一级（编辑/详情）pop 回来、导航重新显示本页时
/// 自动熄灭并触发淡出。用「点击时刻」做去抖：点击后立即发生的 push 转场对应的
/// will/didShow 被忽略，仅处理稍后（用户返回）的通知，避免依赖 VC 实例比较、更稳健。
public final class FSPageReturnHighlight: ObservableObject {
    @Published public var highlightedId: AnyHashable?
    /// 最近一次点击（点亮）的时间戳，用于区分「push 转场」与「pop 返回」
    private var tapTime: TimeInterval = 0
    private var tokens: [NSObjectProtocol] = []

    public init() {
        let names = [
            "UINavigationControllerWillShowViewControllerNotification",
            "UINavigationControllerDidShowViewControllerNotification"
        ]
        for name in names {
            let t = NotificationCenter.default.addObserver(
                forName: Notification.Name(name),
                object: nil, queue: .main
            ) { [weak self] _ in
                self?.tryReset()
            }
            tokens.append(t)
        }
    }

    private func tryReset() {
        if Date().timeIntervalSince1970 - self.tapTime > 0.6 {
            DispatchQueue.main.async { [weak self] in
                self?.highlightedId = nil
            }
        }
    }

    deinit {
        for t in tokens {
            NotificationCenter.default.removeObserver(t)
        }
    }

    public func highlight(_ id: AnyHashable) {
        highlightedId = id
        tapTime = Date().timeIntervalSince1970
    }
}

/// 无痕容器：用 @StateObject 托管一份共享的 FSPageReturnHighlight，
/// 并通过 environmentObject 自动下发给内部所有 FSPageReturnRow。
public struct FSPageReturnList<Content: View>: View {
    @StateObject private var store = FSPageReturnHighlight()
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content.environmentObject(store)
    }
}

/// 点击高亮行：点击瞬间点亮灰底并触发 onTap（通常 push 下一页），
/// 灰底保持到「被盖住的页面 pop 回来」时由共享 store 自动复位淡出。
/// 长按（按住）期间也会变灰（ButtonStyle.isPressed 驱动），松手恢复，不导航。
/// store 由外层 FSPageReturnList 经 @EnvironmentObject 注入，无需调用方传入。
///
/// ⚠️ content 需用「主动撑满」的布局方式（HStack+Spacer），不要只用 frame(maxWidth: .infinity)——
/// Button 在 List 里是紧凑布局，被动等约束撑不开。参照 FSBirthRow：HStack{ content; Spacer() }。
public struct FSPageReturnRow<Content: View>: View {
    @EnvironmentObject private var store: FSPageReturnHighlight
    private let id: AnyHashable
    private let onTap: () -> Void
    private let content: Content
    private let fadeDuration: Double
    private let pressedColor: Color
    private let normalColor: Color

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
        let on = store.highlightedId.map { $0 == id } ?? false
        return Button {
            store.highlight(id)
            onTap()
        } label: {
            content
        }
        .buttonStyle(FSPageReturnPressStyle(
            pressedColor: pressedColor,
            normalColor: normalColor,
            isHighlighted: on,
            fadeDuration: fadeDuration
        ))
    }
}

/// FSPageReturnRow 专用按钮样式：合并「按压即时变灰（isPressed）」与「跨页保留灰底（isHighlighted）」。
///
/// - 长按：isPressed=true 变灰、松手恢复、不触发 action → 不导航。
/// - 点击：按下 isPressed 变灰 → 松手 action 触发 store.highlight(id) 置 on=true（灰底由 store 接管保留）+ onTap 导航；
///   返回时 store 置空 on=false → 淡出。
///
/// ★ 关键：ButtonStyle 的 background 加在 label 上，所以 label（content）必须撑满 Button 宽度，
///   灰底才能铺满整行。因此调用方的 content 需用「主动撑满」的布局（HStack+Spacer），
///   不要只用 frame(maxWidth: .infinity)——Button 紧凑布局下被动等约束撑不开。
private struct FSPageReturnPressStyle: ButtonStyle {
    private let pressedColor: Color
    private let normalColor: Color
    private let isHighlighted: Bool
    private let fadeDuration: Double

    init(pressedColor: Color, normalColor: Color, isHighlighted: Bool, fadeDuration: Double) {
        self.pressedColor = pressedColor
        self.normalColor = normalColor
        self.isHighlighted = isHighlighted
        self.fadeDuration = fadeDuration
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background((configuration.isPressed || isHighlighted) ? pressedColor : normalColor)
            .animation(FSCellFadeAnimation(response: fadeDuration), value: configuration.isPressed || isHighlighted)
    }
}
