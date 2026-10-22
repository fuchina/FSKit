//
//  FSDeallocModifier.swift
//  FSKit
//
//  - deinit 时发送 FS_BE_DEBUG_NOTIFICATION（释放通知）
//  - View 层泄漏检测由外部触发：FSLeakDetector.startCheck(for:depth:)（如 NavigationStack path 变短时）
//  - 对象层泄漏检测（2026-10-21 新增）：`.debugWatch("XxxScreen") { [store] }` 登记业务对象，
//    退出后 3s 首检 / 13s 复检，weak 仍非 nil 才报（实现见 FSLeakProbe.swift）
//  - tracker deinit 自动取消对应的 View 层泄漏检测定时器
//  用法：SomeView().debugDealloc("SomeView")
//        父视图 pop 时：fsLeakCheckOnPop 自动触发
//

import SwiftUI

// MARK: - FSLeakDetector

/// View 层泄漏检测器：外部触发（如 NavigationStack path 变短、sheet dismiss）启动 5 秒定时器，
/// tracker deinit 时取消定时器。若定时器触发 → 未释放 → 疑似泄漏。
public final class FSLeakDetector {

    /// key = "页面名#栈深度"，避免同名页面嵌套 push 时互相覆盖
    @MainActor private static var timers: [String: DispatchWorkItem] = [:]

    /// 挂过 `debugDealloc` 的页面名（进程内累计）；未登记的页面不检测，避免误报
    @MainActor private static var registered: Set<String> = []

    /// 存活表：key → 该层 tracker 的**弱引用**。
    ///
    /// 5 秒到点时以它为准，而不是「定时器有没有被 deinit 取消」——后者有两个漏洞：
    /// 1. `cancelCheck` 是 `deinit` 里 `DispatchQueue.main.async` 派发的，视图可能比
    ///    `onChange(of: routes)` 更早释放，`startCheck` 反而在取消之后才登记，定时器永远没人取消；
    /// 2. key 里的深度是 `onAppear` 时读的 `router.path.count`，若与出栈下标算出的深度不一致，
    ///    取消的是另一个 key ⇒ 必然误报。
    /// 用弱引用判定则只有一种结论：这一层的 tracker 还在 ⇒ 视图存储确实没释放。
    @MainActor private static var live: [String: FSWeakBox] = [:]

    /// 由 `debugDealloc` 在 onAppear 建好 tracker 后登记
    @MainActor
    static func track(_ tracker: _FSDeallocTracker) {
        live[tracker.key] = FSWeakBox(tracker)
    }

    /// 由 `debugDealloc` 在 onAppear 时调用
    @MainActor
    public static func register(_ viewName: String) {
        registered.insert(viewName)
    }

    /// 启动泄漏检测
    ///
    /// - View 层：5 秒后若对应 tracker 仍未 deinit → 发送 FS_BE_LEAK_NOTIFICATION
    /// - 对象层：同时驱动 `FSLeakProbe`，即使该页没挂 `debugDealloc`（只挂了 `debugWatch`）也会检查
    @MainActor
    public static func startCheck(for viewName: String, depth: Int) {
        FSLeakProbe.check(page: viewName, depth: depth)

        guard registered.contains(viewName) else { return }

        let key = FSLeakProbe.key(page: viewName, depth: depth)
        timers[key]?.cancel()

        let item = DispatchWorkItem {
            // 先确认「这一层真的还活着」。
            // 本 block 由 `main.asyncAfter` 派发，必然在主线程执行 ⇒ 同步读静态表是安全的。
            MainActor.assumeIsolated {
                let stillAlive = live[key]?.isAlive ?? false
                live.removeValue(forKey: key)
                timers.removeValue(forKey: key)
                guard stillAlive else { return }

                let msg = "疑似内存泄漏：\(viewName) 未释放（深度 \(depth)）"
                NotificationCenter.default.post(
                    name: NSNotification.Name(FS_BE_LEAK_NOTIFICATION),
                    object: msg
                )
                print("\(msg)")
            }
        }
        timers[key] = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: item)
    }

    /// 取消泄漏检测：tracker deinit 时调用（按页面名，清理该页所有深度）
    @MainActor
    public static func cancelCheck(for viewName: String) {
        let prefix = "\(viewName)#"
        for k in Array(timers.keys) where k.hasPrefix(prefix) {
            timers.removeValue(forKey: k)?.cancel()
        }
    }

    /// 取消泄漏检测：按精确 key（同名页面嵌套时只清自己那一层）
    @MainActor
    static func cancelCheck(key: String) {
        timers.removeValue(forKey: key)?.cancel()
    }
}

// MARK: - Tracker

/// 释放探针：SwiftUI View 被移出视图树且 @State 释放时，deinit 发送通知。
/// 同时取消 FSLeakDetector 中对应的外部泄漏检测定时器。
final class _FSDeallocTracker {

    let viewName: String

    /// 登记时的导航栈深度，用于精确取消本层定时器
    let key: String

    init(viewName: String, depth: Int) {
        self.viewName = viewName
        self.key = FSLeakProbe.key(page: viewName, depth: depth)
    }

    deinit {
        let name = viewName
        let k = key
        DispatchQueue.main.async {
            FSLeakDetector.cancelCheck(key: k)
        }
        NotificationCenter.default.post(
            name: NSNotification.Name(FS_BE_DEBUG_NOTIFICATION),
            object: "\(name) deinit"
        )
    }
}

// MARK: - ViewModifier

private struct _FSDeallocViewModifier: ViewModifier {

    let viewName: String

    @State private var tracker: _FSDeallocTracker?

    @Environment(\.fsNavRouter) private var router

    func body(content: Content) -> some View {
        content.onAppear {
            // push 完成时 path 已包含本页，故 count 即本页深度（从 1 开始；根页为 0）
            let depth = router.path.count
            FSLeakDetector.register(viewName)
            if tracker == nil {
                let newTracker = _FSDeallocTracker(viewName: viewName, depth: depth)
                tracker = newTracker
                // 登记弱引用：5 秒到点时以「它还在不在」为判据（见 FSLeakDetector.live）
                FSLeakDetector.track(newTracker)
            }
        }
    }
}

// MARK: - 对象级探针修饰器

private struct FSLeakWatchModifier<T: AnyObject>: ViewModifier {

    let page: String

    /// 延迟求值：onAppear 时才取 store 引用
    let objects: () -> [T]

    @Environment(\.fsNavRouter) private var router

    func body(content: Content) -> some View {
        content.onAppear {
            let depth = router.path.count
            FSLeakProbe.watch(objects(), page: page, depth: depth)
        }
    }
}

// MARK: - pop 时自动启动检测

/// 挂在导航栈上：路径变短时，对刚被弹出的页面启动泄漏检测。
/// View 层只对登记过的（即挂过 `debugDealloc` 的）页面生效，其余静默跳过；
/// 对象层只要挂过 `debugWatch` 就会检查。
struct FSLeakCheckOnPopModifier: ViewModifier {

    let routes: [FSPageRoute]

    func body(content: Content) -> some View {
        content.onChange(of: routes) { old, new in
            let kept = Set(new.map(\.uid))
            let removed = old.enumerated().filter { kept.contains($0.element.uid) == false }
            guard removed.isEmpty == false else { return }
            // onChange 在主线程回调；assumeIsolated 让编译器认可 MainActor 隔离
            MainActor.assumeIsolated {
                for (index, route) in removed {
                    // route 在 old 数组中的下标 + 1 = 它当时在栈中的深度
                    FSLeakDetector.startCheck(for: route.name, depth: index + 1)
                }
            }
        }
    }
}

/// 模态页（sheet / fullScreenCover）退出时启动检查。
/// 没有导航栈可观察，只能靠宿主视图的 isPresented 翻转来判断。
private struct FSLeakCheckOnDismissModifier: ViewModifier {

    let page: String
    let isPresented: Bool

    func body(content: Content) -> some View {
        content.onChange(of: isPresented) { old, new in
            guard old, new == false else { return }
            // 只驱动对象层：模态页的 View 层 tracker 记的是宿主栈深度，这里没有深度信息
            MainActor.assumeIsolated {
                FSLeakProbe.check(page: page, depth: 0)
            }
        }
    }
}

extension View {

    /// 导航栈专用：栈路径变化时自动为被弹出的页面打点
    func fsLeakCheckOnPop(_ routes: [FSPageRoute]) -> some View {
        modifier(FSLeakCheckOnPopModifier(routes: routes))
    }

    /// 模态页专用：`isPresented` 由 true 变 false 时，对 `page` 登记过的对象做泄漏检查
    ///
    /// ```
    /// .sheet(isPresented: $show) { FooScreen() }
    /// .fsLeakCheckOnDismiss("FooScreen", show)
    /// ```
    public func fsLeakCheckOnDismiss(_ page: String, _ isPresented: Bool) -> some View {
        modifier(FSLeakCheckOnDismissModifier(page: page, isPresented: isPresented))
    }
}

extension View {

    /// 泄漏检测由外部触发：在视图被 pop/dismiss 时调用 `FSLeakDetector.startCheck(for:depth:)`，
    /// tracker deinit 会自动取消检测。5 秒未释放则发送 FS_BE_LEAK_NOTIFICATION。
    public func debugDealloc(_ viewName: String) -> some View {
        modifier(_FSDeallocViewModifier(viewName: viewName))
    }

    /// 对象级泄漏探针：把页面里的 store / model 交给 `FSLeakProbe` 弱引用观察。
    ///
    /// ```
    /// .debugDealloc("FSValueScreen")
    /// .debugWatch("FSValueScreen") { [store] }
    /// ```
    ///
    /// 只有 pop / dismiss 后 3s + 13s 两次检查都不为空才报，避免延迟释放误报。
    public func debugWatch<T: AnyObject>(_ page: String, _ objects: @escaping () -> [T]) -> some View {
        modifier(FSLeakWatchModifier(page: page, objects: objects))
    }
}
