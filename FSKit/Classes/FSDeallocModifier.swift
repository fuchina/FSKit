//
//  FSDeallocModifier.swift
//  FSKit
//
//  对齐 FSBaseController.deinit 行为：SwiftUI 视图释放时发送 FS_BE_DEBUG_NOTIFICATION
//  用法：SomeView().debugDealloc("SomeView")
//

import SwiftUI

/// 释放探针：SwiftUI View 被移出视图树且 @State 释放时，deinit 发送通知。
/// 与 FSBaseController.deinit 行为一致，App 层监听后可按需弹 toast。
private final class _FSDeallocTracker {
    let viewName: String
    init(viewName: String) {
        self.viewName = viewName
    }
    deinit {
        let message = "\(viewName) deinit"
        NotificationCenter.default.post(
            name: NSNotification.Name(FS_BE_DEBUG_NOTIFICATION),
            object: message
        )
    }
}

/// ViewModifier：在视图 body 内挂载一个探针，视图存活期间探针被 @State 持有，
/// 视图释放时探针随之释放，触发 deinit 通知。
private struct _FSDeallocViewModifier: ViewModifier {
    let viewName: String
    @State private var tracker: _FSDeallocTracker?

    func body(content: Content) -> some View {
        content
            .onAppear {
                if tracker == nil {
                    tracker = _FSDeallocTracker(viewName: viewName)
                }
            }
    }
}

extension View {
    /// 视图释放时发送 FS_BE_DEBUG_NOTIFICATION，对齐 FSBaseController.deinit 行为。
    /// 直接使用 String 字面量或 String(reflecting: type(of: self)) 传入视图名即可。
    public func debugDealloc(_ viewName: String) -> some View {
        modifier(_FSDeallocViewModifier(viewName: viewName))
    }
}
