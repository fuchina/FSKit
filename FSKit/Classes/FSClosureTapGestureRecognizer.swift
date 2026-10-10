//
//  FSClosureTapGestureRecognizer.swift
//  FSKit
//
//  闭包版单击手势：把 UITapGestureRecognizer 必需的 target/action 桥接收拢到 FSKit 这一处，
//  使用方不再需要为自己的处理方法写 @objc，也不必再写 addTarget(_:action:)。
//
//  ★ 为什么不自己重写 touchesEnded 把 @objc 彻底去掉：
//    UITapGestureRecognizer 的原生语义不好复刻 —— allowableMovement（默认约 10pt）容差、
//    与滚动/其它手势的仲裁、delaysTouchesEnded、cancelsTouchesInView、识别失败与取消的时序，
//    漏掉任何一条都会在真机上偏离原生手感，且只能靠手点验收。
//    所以这里选择「原生行为 100% 不变 + 只桥接一次」：全工程 @objc 只此一处。
//
//  ★ target 用 self 是安全的：UIGestureRecognizer 不持有 target（target-action 的一贯约定），
//    识别器由 view 持有、识别器指向自己，不构成环。闭包按常规写 [weak self] 即可。
//
//  ★ 重写的是「指定初始化器」init(target:action:)，因此 target/action 的挂载对任何构造路径
//    都成立（含从 XIB/storyboard 解码 —— UIGestureRecognizer 的 init(coder:) 是 convenience，
//    Swift 子类无法转发 coder，只能靠这条路径覆盖）。
//
//  ★ 本类不自动持有/移除识别器，加挂与移除仍由使用方按原生方式处理：
//      let tap = FSClosureTapGestureRecognizer { [weak self] gr in
//          guard let self, let v = gr.view else { return }
//          self.doSomething(at: gr.location(in: v))
//      }
//      view.addGestureRecognizer(tap)
//

import UIKit

public final class FSClosureTapGestureRecognizer: UITapGestureRecognizer {

    /// 识别成功（抬手，且整段位移在 allowableMovement 容差内）时回调。
    /// 参数是识别器自身：需要触点位置时用 `gr.location(in: gr.view)`。
    public var onTap: ((FSClosureTapGestureRecognizer) -> Void)?

    public override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        addTarget(self, action: #selector(fsHandleTap))
    }

    /// 便捷构造：直接给闭包
    public init(onTap: ((FSClosureTapGestureRecognizer) -> Void)?) {
        super.init(target: nil, action: nil)
        self.onTap = onTap
        addTarget(self, action: #selector(fsHandleTap))
    }

    /// target/action 入口：UIKit 识别成功时回调到这里，再转给闭包。
    @objc private func fsHandleTap() {
        onTap?(self)
    }
}
