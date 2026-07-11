//
//  FSPageReturnHighlight.swift
//  FSKit
//
//  页面跳转型 cell 高亮（与 FSCellHighlight 解耦，互不影响）：
//  - 点击 cell 时点亮（变灰），随后 push 进编辑/详情页；
//    在 push 横向转场动画过程中，原 cell 仍可见，灰底被「保留」下来
//  - 编辑页 pop 回来时，由 UIKit 控制器在 viewWillAppear 调 reset() 立即淡出
//    （放在 viewWillAppear 而非 viewDidAppear，是为了让淡出与 pop 转场并行，消除「停顿」感）
//  - 动画完全由控制器生命周期驱动，与网络请求 / 列表重建没有任何耦合
//
//  用法（UIKit 控制器持有 store，SwiftUI row 消费 store）：
//  ```
//  let tap = FSPageReturnHighlight()
//  // row：
//  FSPageReturnRow(store: tap, id: model.aid, onTap: { pushEdit(model) }) {
//      MyRow(model: model)
//  }
//  // 点击时：tap.highlight(model.aid); pushEdit(model)
//  // viewWillAppear：tap.reset()   // pop 转场一开始就淡出，不依赖网络
//  ```
//

import SwiftUI

/// 高亮状态容器：由 UIKit 控制器持有。
/// 点击点亮某个 id（变灰），返回页面时 reset() 熄灭并触发淡出。
public final class FSPageReturnHighlight: ObservableObject {
    @Published public var highlightedId: AnyHashable?
    public init() {}
    public func highlight(_ id: AnyHashable) { highlightedId = id }
    public func reset() { highlightedId = nil }
}

/// 点击高亮行：点击瞬间点亮灰底并触发 onTap（通常 push 下一页），
/// 灰底保持到控制器调用 store.reset()（编辑页返回时）才淡出消失。
public struct FSPageReturnRow<Content: View>: View {
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
        self.store = store
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
