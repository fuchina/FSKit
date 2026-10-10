//
//  FSClosureTapGestureRecognizer.swift
//  FSKit
//

import UIKit

public final class FSClosureTapGestureRecognizer: UITapGestureRecognizer {

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
