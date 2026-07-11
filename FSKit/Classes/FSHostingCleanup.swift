//
//  FSHostingCleanup.swift
//  FSKit
//
//  SwiftUI 控制器内存泄漏清理协议
//  用法：子类声明 FSHostingCleanup，在 viewDidDisappear 里调 cleanupHostingIfMovingFromParent()
//

import UIKit
import SwiftUI

public protocol FSHostingCleanup: AnyObject {
    var hostingController: UIHostingController<AnyView>? { get set }
}

extension FSHostingCleanup where Self: UIViewController {
    /// pop 时拆 hostingController，断开 SwiftUI View 闭包对 self 的强引用
    public func cleanupHostingIfMovingFromParent() {
        if isMovingFromParent {
            hostingController?.willMove(toParent: nil)
            hostingController?.view.removeFromSuperview()
            hostingController?.removeFromParent()
            hostingController = nil
        }
    }
}
