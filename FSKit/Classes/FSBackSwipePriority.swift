//
//  FSBackSwipePriority.swift
//  FSKit
//
//  分页容器（`.tabViewStyle(.page)`）里「第 1 页往返回方向拉够距离 ⇒ 返回上一页」的**只读监听器**。
//
//  ── 问题 ───────────────────────────────────────────────────────────────
//  `.page` 样式 TabView 的底层是 UIPageViewController，内部含一个横向 paging 的 UIScrollView，
//  它的 panGestureRecognizer 铺满整屏，与 NavigationStack 的 interactive pop 手势在同一批触摸上竞争。
//  两者都要识别「水平拖动」⇒ 只有手指落点非常靠近屏幕最左边缘时，系统才给 pop 更高优先级，
//  于是表现为「着力点必须特别靠边才能返回」。
//  非分页页面整页只有一个竖向 List，横向拖动不落在任何横向 pan 上，pop 没有竞争对手 ⇒ 中间起手也能返回。
//
//  ── 为什么不是「接管手势」──────────────────────────────────────────────
//  2026-11-03 第一版把 `panGestureRecognizer.delegate` 换成代理（只叠加 shouldBegin 一条判断），
//  进入页面即崩溃。系统的 pan 与 NavigationStack 的 pop 都是内部实现，接管 delegate 属于侵入式改写，
//  崩因无法在不接调试器的情况下定位 ⇒ 放弃，改成本文件的只读方案：
//  **不动 delegate、不动 target，只给 pan 追加一个 target 观察它，并在满足条件时主动 pop。**
//  注意 UIGestureRecognizer 的 target 是 unretained ⇒ 观察者必须由 scrollview 通过关联对象强持有，
//  否则 scrollview 活得比观察者久时会向已释放对象发消息（野指针）。
//
//  ── 触发规则（按「当前页 + 手指方向」，不看屏幕几何位置）────────────────
//  ┌────────┬──────────────────────────────┬──────────────────────────┐
//  │ 当前页 │ 向右拖（内容右移 = 返回方向）│ 向左拖（内容左移 = 下一页）│
//  ├────────┼──────────────────────────────┼──────────────────────────┤
//  │ 第 1 页│ 松手位移 ≥ 60pt（或拖过 90pt)│ TabView 翻到第 2 页       │
//  │ 第 2 页│ TabView 翻回第 1 页          │ TabView 回弹（无下一页）  │
//  └────────┴──────────────────────────────┴──────────────────────────┘
//  （斜向拖同样适用：竖向分量 ≤ 水平分量的 2 倍即可，见 horizontalDominance）
//
//  ── 斜着拖（边右拖边往下）也必须能返回 ─────────────────────────────────
//  2026-11-03 实测反馈：左滑返回时手不自觉往下带，就 pop 不了。根因有三条，全部要治：
//  ① 旧判据 `abs(t.x) >= abs(t.y)` 要求**水平绝对大于竖向**，斜到 45° 以上即整条 return。
//     真人绕手腕画弧，斜角很轻易超过 45°。
//  ② 只评估松手那一刻：中途 dx 早就够了，手继续往下、松手时 ty 反超 tx ⇒ 被 ①拒掉。
//  ③ 最隐蔽：页面里是竖向 List，往下滑时 List 的竖向 pan 会抢胜负，
//     **分页器那个横向 pan 会进入 `.failed`，从此收不到 `.ended`** ⇒ 一次评估都没有。
//  对应改法：放宽方向（允许竖向到水平的 2 倍）、`.changed` 阶段超 1.5× 阈值即触发（不等松手，绕开 ③）。
//
//  ── 已知取舍 ───────────────────────────────────────────────────────────
//  ① **不是跟手转场**：拖动过程中页面本身不动（TabView 已在边界），松手才走系统 0.35s pop 动画。
//  ② 松手判定仍按 1× 阈值（60pt）：60~90 这段还能反悔拉回；超过 90pt 立即返回、不等松手。
//  ③ bounce 保持开启：拖动时有橡皮筋反馈，松手后弹回与 pop 转场并行。
//  ④ 阈值是手感旋钮：太小会误触（斜着拖列表也可能达到几十 pt），太大退化成「用力甩」。
//     方向容差（`horizontalDominance`）也是旋钮：0.5 = 允许竖向分量到水平的 2 倍（约 63°）。
//

import SwiftUI
import UIKit

// MARK: - 公共 API

public extension View {

    /// 分页容器里「第 1 页朝返回方向拉够距离 ⇒ 返回」。
    ///
    /// 装在分页容器**每一页的内容**上（保证探针是横向 scrollview 的后代）。
    /// 探针 0 尺寸、不参与命中测试；只给 pan 追加观察者，不改手势本身的任何行为。
    ///
    /// 方向容差：竖向分量允许到水平的 2 倍（斜着往下带也认，见 `horizontalDominance`）。
    /// 触发时机：松手时位移 ≥ `threshold`；手势中途拖过 `threshold × 1.5` 则立即返回不等松手
    /// （竖向 List 抢走手势时分页 pan 会 `.failed`，永远等不到松手事件）。
    ///
    /// - Parameters:
    ///   - isAtFirstPage: 当前是否停在第一页。传闭包（不是快照值）⇒ 翻页后无需重装。
    ///   - threshold: 「拖到位」阈值，单位 pt，按**手指水平位移**计。默认 60。
    ///   - flickVelocity: 「轻扫」速度阈值，单位 pt/s，按松手瞬间速度计。默认 800。
    ///     轻扫判定同样要求最小位移（见 `FSBackSwipeConfig.flickMinDistance`），防止快速点按误触。
    ///   - onTrigger: 满足条件时执行（通常是 `router.pop()`）。
    func fsPagingBackSwipe(isAtFirstPage: @escaping () -> Bool,
                           threshold: CGFloat = 60,
                           flickVelocity: CGFloat = 800,
                           onTrigger: @escaping () -> Void) -> some View {
        background(FSBackSwipeProbe(config: FSBackSwipeConfig(isAtFirstPage: isAtFirstPage,
                                                              threshold: threshold,
                                                              flickVelocity: flickVelocity,
                                                              onTrigger: onTrigger))
            .frame(width: 0, height: 0))
    }

    /// 常用形态：命中后直接 `router.pop()`，阈值/速度用默认值。
    ///
    /// 调用点写法（挂在分页容器**每个 page 的内容**上，不能挂在 TabView 外层 ——
    /// 探针必须是被翻页 scrollview 的**后代**，否则祖先链找不到它）：
    /// ```
    /// TabView(selection: $store.segmentIndex) {
    ///     page(store.list)
    ///         .fsPagingBackSwipe(isAtFirstPage: { store.segmentIndex == 0 }, popOn: router)
    ///         .tag(0)
    ///     …
    /// }
    /// ```
    func fsPagingBackSwipe(isAtFirstPage: @escaping () -> Bool,
                           popOn router: FSNavRouter) -> some View {
        fsPagingBackSwipe(isAtFirstPage: isAtFirstPage) { [weak router] in
            router?.pop()
        }
    }
}

// MARK: - 配置

@MainActor
struct FSBackSwipeConfig {

    /// 轻扫判定所需的最小位移：只到"动了一下"就松手，不该算返回意图
    static let flickMinDistance: CGFloat = 20

    /// 方向容差：水平位移 ≥ 竖向位移 × 该系数 即算「向右拖」。
    /// 0.5 ⇒ 竖向分量最多到水平的 2 倍（约 63° 斜角）。真人边返回边往下带很常见，
    /// 旧值等效是 1.0（只有 45° 以内），实测斜一点就失效。
    static let horizontalDominance: CGFloat = 0.5

    /// `.changed` 阶段的提前触发倍率：拖过 `threshold × 1.5` 就返回，不等松手。
    /// 必要性：竖向 List 抢走手势时，分页 pan 会 `.failed`，`.ended` 永远不来。
    static let earlyTriggerRatio: CGFloat = 1.5

    let isAtFirstPage: () -> Bool
    /// 「拖到位」：手指水平位移阈值（pt）
    let threshold: CGFloat
    /// 「轻扫」：松手瞬间水平速度阈值（pt/s）
    let flickVelocity: CGFloat
    let onTrigger: () -> Void
}

// MARK: - 观察者

/// pan 的只读观察者。由 scrollview 通过关联对象强持有（target 本身不保留），
/// 与 scrollview 同生命周期；闭包由调用方在每次安装/刷新时覆盖。
@MainActor
private final class FSBackSwipeObserver: NSObject {

    private var config: FSBackSwipeConfig

    /// 本次手势是否已触发过（`.began` 复位）。`.changed` 提前触发后不再重复 pop。
    private var triggered = false

    init(config: FSBackSwipeConfig) {
        self.config = config
        super.init()
    }

    func configure(_ config: FSBackSwipeConfig) {
        self.config = config
    }

    @objc func handlePan(_ pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            triggered = false
        case .changed:
            // 拖过 1.5× 阈值就直接返回，不等松手：
            // 竖向 List 抢走手势时本 pan 会 `.failed`，`.ended` 根本不发（斜着拖的典型情况）。
            evaluate(pan, early: true)
        case .ended, .cancelled:
            evaluate(pan, early: false)
        default:
            break
        }
    }

    private func evaluate(_ pan: UIPanGestureRecognizer, early: Bool) {
        guard !triggered else { return }
        // 页面已从窗口摘掉（系统 pop 转场已开始、视图正在拆）⇒ 绝不能再 pop 一次，否则连退两页
        guard let view = pan.view, view.window != nil else { return }
        let space = view.window ?? view
        let t = pan.translation(in: space)   // 位移（pt）
        let v = pan.velocity(in: space)      // 松手瞬间速度（pt/s），与 scrollViewWillEndDragging 的 velocity 同源

        // 只认「向右」：向右拖 = 内容右移 = 返回方向。
        // 竖向只做“极窄排除”：允许竖向分量到水平的 2 倍（斜着往下带是常态），
        // 纯竖向滚列表的 dx 只有几 pt，达不到阈值，不会被误伤。
        guard t.x > 0, t.x >= abs(t.y) * FSBackSwipeConfig.horizontalDominance else { return }
        // 第 1 页才接管；第 2 页向右拖是 TabView 自己翻回第 1 页
        guard config.isAtFirstPage() else { return }

        // 两种成立条件（与原生返回手势一致：够远 或 够快）
        // ① 慢慢拖到位（`.changed` 阶段要求 1.5×，松手阶段仍是 1× —— 中间这段还能反悔拉回）
        let far = t.x >= config.threshold * (early ? FSBackSwipeConfig.earlyTriggerRatio : 1)
        // ② 短促一甩：速度够快 + 已拉动一小段（纯速度判定会把「快速点一下」也算进来）。
        //    只在松手时判 —— `.changed` 期间速度是瞬时值，容易尖峰误触。
        let flick = !early
            && v.x >= config.flickVelocity
            && v.x >= abs(v.y) * FSBackSwipeConfig.horizontalDominance
            && t.x >= FSBackSwipeConfig.flickMinDistance

        guard far || flick else { return }

        triggered = true

#if DEBUG
        print("[FSBackSwipe] dx=\(Int(t.x)) dy=\(Int(t.y)) vx=\(Int(v.x)) threshold=\(Int(config.threshold))"
              + " flickV=\(Int(config.flickVelocity)) ⇒ pop（\(far ? "拖到位" : "轻扫")\(early ? "·提前" : "")）")
#endif
        config.onTrigger()
    }
}

// MARK: - 探针

/// 0 尺寸探针：只负责找到祖先链里的横向 paging 容器，并把观察者挂到它的 pan 上。
@MainActor
private struct FSBackSwipeProbe: UIViewRepresentable {

    let config: FSBackSwipeConfig

    func makeUIView(context: Context) -> FSBackSwipeProbeView {
        let v = FSBackSwipeProbeView()
        v.isUserInteractionEnabled = false
        v.backgroundColor = .clear
        v.isOpaque = false
        v.config = config
        return v
    }

    func updateUIView(_ uiView: FSBackSwipeProbeView, context: Context) {
        uiView.config = config
        uiView.installIfNeeded()
    }
}

@MainActor
private final class FSBackSwipeProbeView: UIView {

    var config = FSBackSwipeConfig(isAtFirstPage: { false },
                                   threshold: 60,
                                   flickVelocity: 800,
                                   onTrigger: {})

    /// 未命中时的重试次数（分页容器可能在 push 转场过程中才建好）
    private var retries = 0

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        // didMoveToWindow 这一刻 SwiftUI 还没排完版（contentSize 仍为 0），延后一帧再装
        DispatchQueue.main.async { [weak self] in self?.installIfNeeded() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 转场/翻页期间会多次布局：既当兜底，也让「先建好容器、后建数据」的时序自愈
        installIfNeeded()
    }

    func installIfNeeded() {
        guard window != nil else { return }

        let pagers = horizontalPagersInAncestors()
        guard !pagers.isEmpty else {
            // 容器还没建出来：短延时重试（覆盖 push 转场约 0.35s + 首帧延迟）；
            // 仍找不到就静默放弃（退回改动前的行为，不崩）
            guard retries < 12 else { return }
            retries += 1
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(0.05))
                self?.installIfNeeded()
            }
            return
        }

        for sv in pagers {
            FSBackSwipeObserver.install(on: sv, config: config)
        }
    }

    /// 沿祖先链收集「横向 paging」容器。
    /// 探针挂在页面内容里 ⇒ 分页 scrollview 必为祖先，作用域天然限制在本页，
    /// 不会碰到同窗口的其他横向滚动视图。
    private func horizontalPagersInAncestors() -> [UIScrollView] {
        var out: [UIScrollView] = []
        var v: UIView? = superview
        var depth = 0

        while let cur = v, depth < 64 {
            if let sv = cur as? UIScrollView, Self.isHorizontalPager(sv) {
                out.append(sv)
            }
            v = cur.superview
            depth += 1
        }
        return out
    }

    /// 横向分页容器的判据：
    /// ① 宽度上有富余（contentSize.width > bounds.width）—— List / 竖向 scrollview 不满足；
    /// ② 高度上不富余 —— 排除「双向都能滚」的容器，只看纯横向分页。
    private static func isHorizontalPager(_ sv: UIScrollView) -> Bool {
        let w = sv.bounds.width
        let h = sv.bounds.height
        guard w > 1, h > 1, sv.window != nil else { return false }
        guard sv.contentSize.width > w + 1 else { return false }
        return sv.contentSize.height <= h + 1
    }
}

// MARK: - 安装（幂等）

private enum FSBackSwipeKey {
    /// 关联对象 key（只做地址用，不参与读写）
    nonisolated(unsafe) static var key: UInt8 = 0
}

private extension FSBackSwipeObserver {

    /// 同一个 scrollview 只挂一个观察者、只 addTarget 一次；
    /// 重复安装（每页各一个探针）只覆盖闭包，不会造成重复触发。
    static func install(on sv: UIScrollView, config: FSBackSwipeConfig) {
        let pan = sv.panGestureRecognizer

        if let existing = objc_getAssociatedObject(sv, &FSBackSwipeKey.key) as? FSBackSwipeObserver {
            existing.configure(config)
            return
        }

        let observer = FSBackSwipeObserver(config: config)
        // target 不被保留 ⇒ 必须由 scrollview 强持观察者，随 scrollview 一起释放
        objc_setAssociatedObject(sv, &FSBackSwipeKey.key, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        pan.addTarget(observer, action: #selector(FSBackSwipeObserver.handlePan(_:)))
    }
}
