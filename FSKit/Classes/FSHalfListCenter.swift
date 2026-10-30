//
//  FSHalfListCenter.swift
//  FSKit
//
//  2026-10-15 全 SwiftUI 化：
//  原 `FSHalfView` 是「遮罩 + 右侧滑入的 UITableView」的 UIView，需要 UIView 宿主，
//  且行内容要靠调用方拿 UIKit cell 去填（`configCell`）。现改为「状态 + 根视图渲染」：
//  调用方只提供行数据（标题/右侧说明）与选中回调。
//
//  外观逐值对齐原实现：遮罩黑 0.28；列表从右侧滑入、左边距 `leftWidth`；
//  行高 50、标题 14pt、右侧说明 12pt 灰、右侧 chevron（原 `.value1` + disclosureIndicator）。
//

import SwiftUI
import UIKit

// MARK: - 面板几何

/// 半屏面板的生效区（窗口坐标）
///
/// 2026-10-26 修复：点「移动」弹出的组列表不从导航栏下开始、顶部内容被状态栏与导航栏挡住。
/// 病根是旧实现给面板的 `ScrollView` 挂了 `.ignoresSafeArea(edges: .vertical)`：
/// 面板从屏幕最顶端（y = 0）铺到底，`ScrollView` 的 content 也跟着从 y = 0 起排
/// ⇒ 前两行（约 100pt）永久压在状态栏 + 导航栏后面；而滚动偏移不能越过 0，
/// 那几行**滚也滚不出来**（不是「一开始滚动位置不对」，是真的拿不到）。
///
/// 现在的语义：面板上沿对齐「状态栏 + 导航栏」下沿，下沿照旧铺到屏幕底边；
/// 只有**内容**让开 home indicator。几何值在 `show` 时取一次，`body` 只读字段
///（与「展示值算一次」的约定一致，也不在渲染路径上访问 UIWindow）。
///
/// `nonisolated`：本 Pod 默认主隔离，若不标注，`zero` 会变成主隔离常量、
/// 无法出现在存储属性初始化器里（默认值表达式是 nonisolated 上下文）。
nonisolated public struct FSHalfListInsets: Sendable {

    /// 面板上沿到屏幕顶端的距离（= 状态栏 + 导航栏）
    public var top: CGFloat
    /// 底部安全区（home indicator）
    public var bottom: CGFloat

    public init(top: CGFloat, bottom: CGFloat) {
        self.top = top
        self.bottom = bottom
    }

    public static let zero = FSHalfListInsets(top: 0, bottom: 0)
}

// MARK: - 几何取值

@MainActor
private enum FSHalfListMetrics {

    /// 取当前窗口下的面板几何。只在 `show` 里调一次。
    static func current() -> FSHalfListInsets {
        guard let window = keyWindow() else {
            return FSHalfListInsets(top: FSHalfListLayout.statusBarFallback, bottom: 0)
        }

        let safeTop = window.safeAreaInsets.top
        // 导航栏还在视图树里 ⇒ 用它自己的下沿（大标题、自定义高度都能跟对）；
        // 取不到（SwiftUI 换了实现 / 该页无导航栏）⇒ 按「状态栏 + 标准导航栏高」估。
        let measured = navBarBottom(in: window) ?? (safeTop + FSHalfListLayout.navBarHeight)
        return FSHalfListInsets(top: max(measured, safeTop), bottom: window.safeAreaInsets.bottom)
    }

    /// 取 key window（与 `FSAlertAnchorCenter` 同一套取法）
    private static func keyWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        return scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first
    }

    /// 当前可见导航栏的下沿（窗口坐标）。找不到返回 nil。
    ///
    /// SwiftUI 的 `NavigationStack` 内部仍是 `UINavigationBar`，但它不是公开 API 的一部分，
    /// 所以这里只做「有就用、没有就估」，任何异常形态都退回调用方的兜底值，绝不抛错。
    /// 多个导航栏并存（多 tab 各自一个栈）时取**最下面**那个：屏幕上方能同时命中的
    /// 只有当前页这一条，其余栈的栏要么不在树上、要么已被隐藏。
    private static func navBarBottom(in window: UIWindow) -> CGFloat? {
        guard let root = window.rootViewController?.view else { return nil }

        var bottom: CGFloat?
        var stack: [UIView] = [root]
        var visited = 0

        while let view = stack.popLast(), visited < 4_000 {
            visited += 1
            if let bar = view as? UINavigationBar, !bar.isHidden, bar.alpha > 0.01, bar.window === window {
                let rect = bar.convert(bar.bounds, to: window)
                // 只看「贴着屏幕顶部、且在窗口内」的那条；隐藏态的栏会被压成 0 高或留在屏幕外
                if rect.height > 8,
                   rect.minY >= 0,
                   rect.maxY <= window.safeAreaInsets.top + FSHalfListLayout.navBarSearchDepth {
                    bottom = max(bottom ?? 0, rect.maxY)
                }
            }
            stack.append(contentsOf: view.subviews)
        }
        return bottom
    }
}

/// 面板布局常量
private enum FSHalfListLayout {

    /// 标准导航栏高度：让系统自己报（不写死 44，系统调整高度时能跟上），最低 44 兜底
    static let navBarHeight: CGFloat = {
        let bar = UINavigationBar()
        // 必须写全 `CGFloat.greatestFiniteMagnitude`：CGSize 里 CGFloat / Double 两个候选会二义
        let size = bar.sizeThatFits(CGSize(width: 390, height: CGFloat.greatestFiniteMagnitude))
        return max(size.height, 44)
    }()

    /// 连状态栏高度都拿不到时的兜底上沿（老机型 20 + 44，新机型会多留一点空隙，属可接受误差）
    static let statusBarFallback: CGFloat = 64

    /// 认「顶部导航栏」的纵向范围：状态栏之下再放宽 120（足够覆盖大标题）
    static let navBarSearchDepth: CGFloat = 120
}

/// 半屏列表的一行
public struct FSHalfListRow: Identifiable {

    public let id = UUID()
    public var title: String
    /// 右侧说明（原 `detailTextLabel`，如「已是此组」）
    public var detail: String

    public init(title: String, detail: String = "") {
        self.title = title
        self.detail = detail
    }
}

/// 一条半屏列表请求
///
/// Swift 6 语言模式：spec 会被送进 `@MainActor` 闭包，故声明 `@unchecked Sendable`
/// （纯数据载体；内含的 onSelect 闭包由调用方在主线程执行）。
public struct FSHalfListSpec: Identifiable, @unchecked Sendable {

    public let id = UUID()
    public var leftWidth: CGFloat
    public var rows: [FSHalfListRow]
    /// 面板生效区（见 `FSHalfListInsets`）。由 `show` 在弹出瞬间取一次。
    ///
    /// 直接构造 spec 的调用方拿不到窗口几何，留 `zero` 兜底；
    /// 正常入口 `FSHalfListCenter.show(leftWidth:rows:onSelect:)` 一定会填好。
    public var insets: FSHalfListInsets = .zero
    public var onSelect: (Int) -> Void

    public init(leftWidth: CGFloat, rows: [FSHalfListRow], onSelect: @escaping (Int) -> Void) {
        self.leftWidth = leftWidth
        self.rows = rows
        self.onSelect = onSelect
    }

    /// 带上生效区几何的副本。
    ///
    /// 用「返回值副本」而不是就地赋值：`show` 要把本值送进 `@MainActor` 闭包
    ///（该闭包被推断为 `@Sendable`），在那里改捕获到的 `var` 会报
    /// `mutation of captured var in concurrently-executing code`。
    func withInsets(_ insets: FSHalfListInsets) -> FSHalfListSpec {
        var copy = self
        copy.insets = insets
        return copy
    }
}

/// 全局半屏列表中心。**可从任意线程调用**。
///
/// Swift 6 语言模式：`show` / `dismiss` 会把 `self` 送进 `@MainActor` 闭包，
/// 故补 `@unchecked Sendable`（可变状态已由 `MainActor.assumeIsolated` 保证只在主线程访问）。
@Observable
public final class FSHalfListCenter: @unchecked Sendable {

    // 2026-10-17：Pod 与主 App 统一为默认主隔离后，nonisolated(unsafe) 反而报错，故移除。
    public static let shared = FSHalfListCenter()

    public private(set) var current: FSHalfListSpec?

    private init() {}

    public func show(leftWidth: CGFloat, rows: [FSHalfListRow], onSelect: @escaping (Int) -> Void) {
        let spec = FSHalfListSpec(leftWidth: leftWidth, rows: rows, onSelect: onSelect)
        let apply: @MainActor () -> Void = { [weak self] in
            // 窗口几何只能在主线程读。放进主隔离闭包里取，正好满足「弹出这一刻、
            // 页面已入栈、导航栏已就位」的时序要求；本方法被后台线程调用时也仍然正确。
            self?.current = spec.withInsets(FSHalfListMetrics.current())
        }
        if Thread.isMainThread {
            MainActor.assumeIsolated { apply() }
        } else {
            DispatchQueue.main.async { MainActor.assumeIsolated { apply() } }
        }
    }

    public func dismiss() {
        let apply: @MainActor () -> Void = { [weak self] in self?.current = nil }
        if Thread.isMainThread {
            MainActor.assumeIsolated { apply() }
        } else {
            DispatchQueue.main.async { MainActor.assumeIsolated { apply() } }
        }
    }
}

/// 半屏列表浮层（由根视图挂载）
public struct FSHalfListOverlay: View {

    private let center = FSHalfListCenter.shared

    public init() {}

    public var body: some View {
        ZStack(alignment: .trailing) {
            if let spec = center.current {
                // 遮罩（原 _tapView: 黑 0.28，点空白关闭）
                Color.black.opacity(0.28)
                    .ignoresSafeArea()
                    .onTapGesture { center.dismiss() }

                FSHalfListPanel(spec: spec)
                    .frame(width: max(WIDTHFC - spec.leftWidth, 0))
                    // 上沿让到导航栏之下（几何见 `FSHalfListInsets`）。
                    // 注意：**不能**再给面板挂 `.ignoresSafeArea(edges: .vertical)`，
                    // 那正是「列表从屏幕顶端外开始、前几行被挡住」的成因。
                    .padding(.top, spec.insets.top)
                    .transition(.move(edge: .trailing))
            }
        }
        // 画布扩到全屏：面板底边照旧铺到屏幕底（原实现如此），
        // 只有内容让开 home indicator（见 FSHalfListPanel）。
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.3), value: center.current?.id)
    }
}

// MARK: - 面板

/// 面板本体：白底 + 可滚动的行列表。
///
/// 拆成独立子视图：`center.current` 变化（弹出 / 关闭）时只重建这一块，
/// 遮罩与动画留在外层。
private struct FSHalfListPanel: View {

    let spec: FSHalfListSpec

    /// 面板外形：**只圆左上角**。
    /// 右缘贴着屏幕右边、下沿贴着屏幕底，圆其余三个角会在贴边处露出缝隙（底下是被压暗的页面）。
    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 12,
                               bottomLeadingRadius: 0,
                               bottomTrailingRadius: 0,
                               topTrailingRadius: 0,
                               style: .continuous)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(spec.rows.enumerated()), id: \.element.id) { index, row in
                    Button {
                        spec.onSelect(index)
                        FSHalfListCenter.shared.dismiss()
                    } label: {
                        rowLabel(row)
                    }
                    .buttonStyle(.plain)
                }
            }
            // 末尾留出底部安全区：最后一行能滚到 home indicator 之上，点击不被系统手势抢
            .padding(.bottom, spec.insets.bottom)
        }
        // 内容也裁到圆角内，否则第一行会从左上角方角处冒出去
        .clipShape(shape)
        .background {
            // 阴影挂在**静态形状层**上，不要挂在滚动的 ScrollView 上：
            // 带 shadow 的滚动视图每帧都要离屏合成，组多的时候滚动会掉帧。
            // 行下方的空白同样由这层铺白（旧实现面板透明，会透出被压暗的页面）。
            shape
                .fill(Color.white)
                .shadow(color: .black.opacity(0.22), radius: 12, x: -4, y: 0)
        }
    }

    private func rowLabel(_ row: FSHalfListRow) -> some View {
        HStack(spacing: 8) {
            Text(row.title)
                .font(.system(size: 14))
                .foregroundColor(FSColor.label)
            Spacer(minLength: 8)
            if row.detail.isEmpty == false {
                Text(row.detail)
                    .font(.system(size: 12))
                    .foregroundColor(FSColor.secondaryLabel)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(FSColor.tertiaryLabel)
        }
        .padding(.horizontal, 15)
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(FSColor.separator)
                .frame(height: 0.5)
        }
    }
}
