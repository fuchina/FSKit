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
    // 2026-10-17：deinit 是 nonisolated，读被主隔离化的属性会报错；本属性仅在
    // init 里写入、deinit 里遍历移除，改 nonisolated(unsafe) 不改变任何逻辑。
    nonisolated(unsafe) private var tokens: [NSObjectProtocol] = []

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
                // 2026-10-17：观察者挂在 queue: .main 上，必定在主隔离域执行。
                MainActor.assumeIsolated { self?.resetIfReturning() }
            }
            tokens.append(t)
        }
    }

    /// 幂等复位：距最近一次点击超过 0.6s（即「不是 push 转场，而是用户返回」）则清空高亮。
    /// 可被任意多个来源并发调用（UIKit 导航通知 / SwiftUI onAppear / 生命周期探针）；
    /// 重复调用、以及本就为 nil 时的调用都是**无副作用 no-op** ⇒ 多源冗余是安全的。
    public func resetIfReturning() {
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
        content
            .environmentObject(store)
            // 全 SwiftUI 化后 UINavigationController 通知不再可靠：
            // 三路冗余触发同一个**幂等**复位（谁先到都行，重复调用无副作用）
            .onAppear { store.resetIfReturning() }
            .background(FSPageReturnLifecycleProbe { store.resetIfReturning() })
    }
}

/// 零尺寸生命周期探针：把「所在页面被重新显示（pop 回来）」翻译成一次复位调用。
/// 依赖 `UIViewController.viewWillAppear` —— 与旧版 UINavigationController 通知同源，
/// 但**范围限定在本页**，不会像全局通知那样误伤其它页。
private struct FSPageReturnLifecycleProbe: UIViewControllerRepresentable {

    let onReturn: () -> Void

    func makeUIViewController(context: Context) -> Probe {
        Probe(onReturn: onReturn)
    }

    func updateUIViewController(_ uiViewController: Probe, context: Context) {
        uiViewController.onReturn = onReturn
    }

    final class Probe: UIViewController {
        var onReturn: () -> Void

        init(onReturn: @escaping () -> Void) {
            self.onReturn = onReturn
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            onReturn()
        }
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

// MARK: - 全 SwiftUI 导航栈（替代 UINavigationController）

/// 一次 push 的目标页：用闭包持有页面视图（及其 store）。
/// 该闭包被 `FSNavRouter.path` 持有 ⇒ 被 push 期间 store 不会释放；pop 后随之释放。
public struct FSPageRoute: Hashable, Identifiable {

    public let uid: UUID
    /// 页面名（用于 popTo(_:) 定位、泄漏检测打点）
    public let name: String
    private let content: () -> AnyView

    public var id: UUID { uid }

    public init<V: View>(_ name: String, @ViewBuilder content: @escaping () -> V) {
        self.uid = UUID()
        self.name = name
        self.content = { AnyView(content()) }
    }

    public func makeView() -> AnyView { content() }

    public static func == (lhs: FSPageRoute, rhs: FSPageRoute) -> Bool { lhs.uid == rhs.uid }
    public func hash(into hasher: inout Hasher) { hasher.combine(uid) }
}

/// 导航路由器：**每个 NavigationStack 一个实例**（每个 tab 一个；模态里另开栈则另建）。
/// 对齐原 UINavigationController 的 push / pop / popTo / popToRoot 语义。
public final class FSNavRouter: ObservableObject {

    @Published public var path: [FSPageRoute] = []

    public init() {}

    public var depth: Int { path.count }
    public var topName: String? { path.last?.name }
    public var isAtRoot: Bool { path.isEmpty }

    /// 等价 `pushViewController(_:animated:)`
    public func push<V: View>(_ name: String, @ViewBuilder _ content: @escaping () -> V) {
        path.append(FSPageRoute(name, content: content))
    }

    /// 等价 `popViewController(animated:)`
    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// 等价 `popToViewController(_:animated:)`（回退到名为 name 的页，该页保留）
    public func popTo(_ name: String) {
        guard let idx = path.lastIndex(where: { $0.name == name }) else { return }
        path.removeLast(path.count - idx - 1)
    }

    /// 等价 `popToRootViewController(animated:)`
    public func popToRoot() { path.removeAll() }

    /// 连续弹掉 n 层
    public func pop(_ count: Int) {
        guard count > 0, !path.isEmpty else { return }
        path.removeLast(min(count, path.count))
    }
}

// MARK: - 环境注入

private struct FSNavRouterKey: EnvironmentKey {
    // Swift 6 语言模式（2026-10-15）：EnvironmentKey 的默认值会被任意隔离域读取，
    // 而 FSNavRouter 的定义即在本文件内 —— 外部扩展补 `@unchecked Sendable`
    // 不足以通过该检查，故只能就地声明。
    // 仅此一行，不涉及分页返回高亮的任何逻辑。
    static let defaultValue = FSNavRouter()
}

public extension EnvironmentValues {
    /// 当前 NavigationStack 的路由器。未在 `FSPushStack` 内时为兜底空栈（push 无效但不崩）。
    var fsNavRouter: FSNavRouter {
        get { self[FSNavRouterKey.self] }
        set { self[FSNavRouterKey.self] = newValue }
    }
}

// MARK: - 栈容器

/// 一个 tab / 一个模态的根：NavigationStack + 路由器注入 + 目标页解析。
/// ```
/// FSPushStack {
///     MyRootScreen()          // 内部用 @Environment(\.fsNavRouter) 拿 router
/// }
/// ```
public struct FSPushStack<Content: View>: View {

    @StateObject private var router = FSNavRouter()
    private let tabIndex: Int
    private let content: Content

    /// - Parameter tabIndex: 本栈在根 TabView 中的下标；用于向 `FSStackRegistry` 登记（跨 tab 的屏幕锁需要）
    public init(tabIndex: Int = 0, @ViewBuilder content: () -> Content) {
        self.tabIndex = tabIndex
        self.content = content()
    }

    public var body: some View {
        NavigationStack(path: $router.path) {
            content
                .navigationDestination(for: FSPageRoute.self) { route in
                    route.makeView()
                }
        }
        // 二级页隐藏 tab bar（对齐原 FSNavigationController 的 `hidesBottomBarWhenPushed` 行为）。
        //
        // 2026-10-15 修复：显隐原来写在 `navigationDestination` 的内容上，pop 回一级页要等目标页
        // 视图被移除后才恢复 tab bar ⇒ tab bar 在转场动画结束后才「跳」出来，很生硬。
        // 现改为**绑在 `router.path` 上、挂在 NavigationStack 外层**，push / pop 的同一帧内
        // tab bar 就随转场一起滑入滑出。
        .toolbar(router.path.isEmpty ? .visible : .hidden, for: .tabBar)
        .environment(\.fsNavRouter, router)
        .onAppear { FSStackRegistry.shared.register(router, at: tabIndex) }
        // pop 时自动对「挂过 debugDealloc 的页面」启动泄漏检测（见 FSDeallocModifier.swift）
        .fsLeakCheckOnPop(router.path)
    }
}

// MARK: - 跨 tab 栈注册表

/// 全 SwiftUI 后每个 tab 各有一个 `FSNavRouter`。
/// 屏幕锁（任一栈非根就要验手势；用户左滑时把所有栈弹回根）与剪切板角标这类**跨 tab** 逻辑，
/// 原来靠遍历 `UITabBarController` 下的 `UINavigationController` 实现；
/// 现在改为由 `FSPushStack` 向本注册表登记自己的 router。
@MainActor
public final class FSStackRegistry: ObservableObject {

    public static let shared = FSStackRegistry()

    /// 各 tab 的栈 router（下标 = tab 下标）。视图不读它，故不参与观察。
    public private(set) var routers: [FSNavRouter] = []

    /// 剪切板是否有内容（原 `tabBarItem.badgeValue = "1"`，清空时置 nil）——由根 TabView 的 `.badge` 呈现
    @Published public var pasteboardHasContent = false

    public init() {}

    /// `FSPushStack` 在 `.onAppear` 时登记自己（tab 重建时覆盖同一下标）
    public func register(_ router: FSNavRouter, at index: Int) {
        while routers.count <= index { routers.append(FSNavRouter()) }
        routers[index] = router
    }

    /// 原 `v.viewControllers.count > 1`
    public var anyPushed: Bool { routers.contains { $0.path.isEmpty == false } }

    /// 原 `for v in viewControllers { v.popToRootViewController(animated: true) }`
    public func popAllToRoot() { routers.forEach { $0.popToRoot() } }
}

public struct FSPageBackground: ViewModifier {
    public init() {}
    public func body(content: Content) -> some View {
        content.background(FSColor.backColor.ignoresSafeArea())
    }
}

public extension View {
    func fsPageBackground() -> some View { modifier(FSPageBackground()) }
}

// MARK: - 顶层视图 / 控制器（替代 tabBarController / navigationController 取宿主）

public extension UIApplication {
    /// 当前 key window 的最上层控制器（UIKit 弹窗 / toast 宿主；不再依赖 nav 栈）
    static var fs_topVC: UIViewController {
        guard let scene = shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first,
              let root = window.rootViewController else {
            return UIViewController()
        }
        return fs_topMost(from: root)
    }

    static var fs_topView: UIView { fs_topVC.view }

    private static func fs_topMost(from vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController { return fs_topMost(from: presented) }
        if let nav = vc as? UINavigationController, let top = nav.visibleViewController, top != vc {
            return fs_topMost(from: top)
        }
        if let tab = vc as? UITabBarController, let sel = tab.selectedViewController { return fs_topMost(from: sel) }
        return vc
    }
}

