//
//  FSPageReturnHighlight.swift
//  FSKit
//
//  页面跳转型 cell 高亮（与 FSCellHighlight 解耦，互不影响）：
//  - 点击 cell 时点亮（变灰），随后 push 进编辑/详情页；
//    在 push 转场过程中原 cell 仍可见，灰底被「保留」下来
//  - 编辑页 pop 回来时，自动监听 UINavigationController.willShowViewControllerNotification
//    （用字符串字面量取通知名，避免 UIKit 在部分 Swift 版本未桥出类型化成员而报错）：
//    以「点击时刻」做去抖——点击后极短时间内的 willShow 视为 push 转场而忽略，
//    超过阈值的 willShow 才视为返回，灰底立即淡出，与 pop 动画并行，消除「停顿」感；
//    完全不依赖 VC 实例比较，也不依赖网络请求 / 列表重建
//
//  ★ 近无痕插拔：调用方只需在「列表层」建一份 store 并传给每个 row（无需类属性、
//    无需挂生命周期、无需手动 highlight/reset），row 内部自检测返回并淡出：
//  ```
//  let store = FSPageReturnHighlight()          // 列表级建一份，所有 row 共用
//  FSPageReturnRow(store: store, id: model.aid, onTap: { pushEdit(model) }) {
//      MyRow(model: model)
//  }
//  ```
//

import SwiftUI
import UIKit

/// 高亮状态容器（列表级共享一份，所有 row 共用）：
/// 点击点亮某个 id（变灰）；当页面从下一级（编辑/详情）pop 回来、
/// 导航重新显示本页时自动熄灭并触发淡出。
/// 用「点击时刻」做去抖：点击后立即发生的 push 转场对应的 willShow/didShow 被忽略，
/// 仅处理稍后（用户返回）的通知，从而避免依赖 VC 实例比较、更稳健。
/// ⚠️ 必须由调用方（列表层）创建并传给各 row，不能在每个 row 内用 @StateObject
/// （List 行回收重建会导致灰底丢失、无法淡出）。
public final class FSPageReturnHighlight: ObservableObject {
    @Published public var highlightedId: AnyHashable?
    /// 最近一次点击（点亮）的时间戳，用于区分「push 转场」与「pop 返回」
    private var tapTime: TimeInterval = 0
    private var tokens: [NSObjectProtocol] = []

    public init() {
        // 同时监听 willShow 与 didShow（双保险）：两者任一触发即可复位，
        // 任一因环境不触发也不影响。push 编辑页时两者都会触发，但发生在点击后极短时间内，
        // 由 tapTime 阈值过滤掉，不会误复位。用字符串字面量取通知名（避免桥接成员缺失报错）。
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
        // 点击后 0.6s 内发生的通知视为「push 转场」→ 忽略；
        // 超过阈值（用户在编辑页停留后返回）才复位淡出。
        // ⚠️ 必须延后到下一帧再置空：willShow/didShow 在 pop 转场「开始前」触发，
        // 若此刻同步置空，灰底会被「吞掉」（视图以 false 态直接出现，看不到淡出）。
        // 延到下一个 runloop（视图已上屏）再改状态 → 真·淡出动画可见。
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

    /// 点亮并记录点击时刻（点击时由 row 内部调用）
    public func highlight(_ id: AnyHashable) {
        highlightedId = id
        tapTime = Date().timeIntervalSince1970
    }

    /// 立即熄灭高亮（仅在确有高亮时改变状态，重复调用幂等）。
    /// 用于调用方在「确定返回」的时机（如 viewWillAppear）主动触发淡出，
    /// 与导航通知互为备份：即便通知因环境未收到，返回淡出也必定发生。
    public func clearHighlight() {
        highlightedId = nil
    }
}

/// 点击高亮行：点击瞬间点亮灰底并触发 onTap（通常 push 下一页），
/// 灰底保持到「被盖住的页面 pop 回来」时由共享 store 自动复位淡出。
/// ⚠️ store 必须由调用方（列表层）创建并传入、所有 row 共享同一份：
/// 不能用每行的 @StateObject —— List/ForEach 在 push-pop 重建时会回收重建 row，
/// 导致灰底丢失、无法淡出。共享 store 活在 hosting 层，跨 row 回收持久。
public struct FSPageReturnRow<Content: View>: View {
    /// ⚠️ 必须是 @ObservedObject：store 由列表层创建并传入（共享一份），
    /// 去掉包装会让 SwiftUI 不监听 @Published 的 highlightedId 变化，
    /// 导致点击/返回时灰底不出现、淡出也不触发（两个动画一起消失）。
    @ObservedObject private var store: FSPageReturnHighlight
    private let id: AnyHashable
    private let onTap: () -> Void
    private let content: Content
    private let fadeDuration: Double
    private let pressedColor: Color
    private let normalColor: Color

    public init(store: FSPageReturnHighlight,
                id: AnyHashable,
                fadeDuration: Double = 0.6,
                pressedColor: Color = Color(UIColor.systemGray3),
                normalColor: Color = Color(UIColor.systemBackground),
                onTap: @escaping () -> Void,
                @ViewBuilder content: () -> Content) {
        self._store = ObservedObject(wrappedValue: store)
        self.id = id
        self.fadeDuration = fadeDuration
        self.pressedColor = pressedColor
        self.normalColor = normalColor
        self.onTap = onTap
        self.content = content()
    }

    public var body: some View {
        // 单行算出是否高亮（Optional<AnyHashable> 与 AnyHashable 比较；共享 store 跨 row 共用）
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

