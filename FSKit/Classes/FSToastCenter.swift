//
//  FSToastCenter.swift
//  FSKit
//

import SwiftUI

// MARK: - 消息

public struct FSToastMessage: Identifiable, Equatable {

    /// 由 center 分配的自增序号，唯一标识一条 toast
    public let id: Int

    public var text: String

    public var duration: Double

    public init(id: Int, text: String, duration: Double) {
        self.id = id
        self.text = text
        self.duration = duration
    }

    /// 兼容旧写法：id 由 center 在 show 时分配，这里给 0
    public init(text: String, duration: Double) {
        self.init(id: 0, text: text, duration: duration)
    }
}

// MARK: - 飘飞

/// 已经离开布局、正在飘走的 toast 快照（2026-10-26）。
///
/// 为什么必须单独抽一层：`items` 里一移除，SwiftUI 就把条目从布局摘掉了；而 removal
/// transition 期间它仍然占着 VStack 的槽位。要让「让位」和「飘走」**同时**发生，
/// 唯一办法是把它转成脱离布局、绝对定位的独立图层 —— 也就是 `FSToastFly`。
/// 直接把 offset 写进 transition 会得到「人走了、座位还热着」的顿挫。
struct FSToastFly: Identifiable {

    let id: Int
    let text: String

    /// 起飞点（overlay 局部坐标系里的中心点）
    let anchor: CGPoint

    /// 横向总位移，带符号 —— 决定这颗往哪边歪
    let lateral: CGFloat

    /// 纵向总位移
    let rise: CGFloat

    /// 存活时长（已乘 `FSToastMotion.speed`）
    let life: Double

    /// 终点倾斜角（弧度）。在场恒为 0，靠 eased 从 0 渐变过去
    let tilt: CGFloat

    let birth: Date
}

// MARK: - 飘走参数

/// 飘飞层的全部可调参数。
/// 数值是 2026-10-26 在一版临时验证页上逐项对着观感调出来的（验证页已删除），
/// 所以没有可靠的离线预览手段 —— 要调就小步改、实机看，别一次动好几项。
enum FSToastMotion {

    /// 基准存活时长范围（秒）
    static let lifeRange: ClosedRange<Double> = 0.72...0.86

    /// 时长倍率。2026-10-26 从 2.0 收到 1.4 —— 原档实际存活 1.44~1.72s，用户反馈「消失时间有点长」。
    /// 现在 1.01~1.20s，约 1.1s 为主。
    static let speed: Double = 1.4

    /// 上浮距离范围（pt）。原 200~235 被反馈「距离有点大」，同比缩 30% 到 140~165。
    /// 缩距离必须同步缩时长（见 `speed`），否则速度变快、观感是「嗖」一下冲走。
    static let riseRange: ClosedRange<CGFloat> = 140...165

    /// 横向偏移的理论上限（pt）。约等于 165 × tan(14°)。
    /// 跟着 `riseRange` 同比缩，保持斜线角度不变；不缩的话角度会张到 20°，飘得更歪。
    static let maxLateral: CGFloat = 41

    /// 横向偏移取可用空间的比例范围。不取到 1.0，是给中途侧向鼓出留余量
    static let lateralRatio: ClosedRange<CGFloat> = 0.55...1.0

    /// 中途侧向鼓出的幅度（pt）。叠在斜线上，让路线不是一根死直线
    static let wobble: CGFloat = 4

    /// 终点倾斜角度范围（度，正负随机）。
    /// 停留期必须恒为 0°（文字要正着给人读），只在飘走那一段从 0 渐变到终值
    static let tiltRange: ClosedRange<CGFloat> = 1.5...4

    /// 飘到终点时的缩放
    static let shrink: CGFloat = 0.92

    /// 起飞后保持完全不透明的行程占比。
    /// 2026-10-26 从 0.30 改成 0：用户反馈「消失刚开始那一截 alpha 太慢」，
    /// 也就是起飞后前 0.45s 完全没变化、看着像卡了一下才开始淡。
    /// 现在第一帧就起淡，与「让位」同帧开始。
    static let holdOpacityRatio: Double = 0

    /// 坐标空间名。中心点回填与飘飞定位必须共用同一套坐标，否则整体会偏掉
    nonisolated static let space = "fsToastSpace"
}

// MARK: - 中心

/// 全局 toast 中心：允许**多条同时存在**，每条独立计时、独立消失。
/// 旧版只保留一个槽位（`current`），后来的 toast 会顶掉前一条 —— 已废弃该行为。
@Observable
public final class FSToastCenter: @unchecked Sendable {

    public static let shared = FSToastCenter()

    /// 当前存活的全部 toast，按加入顺序排列（最旧的在前）
    public private(set) var items: [FSToastMessage] = []

    /// 正在飘走的飘飞。不参与 `items` 的 `maxVisible` 计数，也不进布局
    private(set) var fly: [FSToastFly] = []

    /// 同时最多保留几条；超出时丢弃最旧的。
    /// 之所以要上限：debug 通知里有 `duration: 600` 的长驻 toast，不设上限会无限堆叠。
    @ObservationIgnored public var maxVisible: Int = 6

    @ObservationIgnored private var seq: Int = 0

    /// 待插入队列。`show()` 只往这里入队，由 `drainPending()` 逐条落到 `items` 上。
    /// 之所以要排队：SwiftUI 会把「同一帧内的所有状态变更」合并成一次更新，
    /// 一次回调里连打多条日志时直接 append 会让它们同帧出现，既没有淡入也没有「上方让位」动画。
    @ObservationIgnored private var pending: [FSToastMessage] = []

    /// 是否已有排空任务在跑（避免并发起多个 drain 循环）
    @ObservationIgnored private var isDraining = false

    /// 每条 toast 当前在屏幕上的矩形。飘走时拿它算起飞点，也用它的宽度算可用横向空间
    @ObservationIgnored private var rects: [Int: CGRect] = [:]

    /// 连续多条时的入队间隔（秒）。必须大于一帧，否则又会被合并；0.14s ≈ 8 帧 @60Hz。
    private let insertInterval: Double = 0.14

    /// 插入 / 上方让位的动画时长。
    /// 视图层 `.animation(_:value:)` 也要用同一个值，故设为 static（实例方法里引用须写 `Self.`）。
    public static let overlayAnimationDuration: Double = 0.24

    /// `dismissAll` 的统一淡出时长。单条自然超时不再走这里 —— 它交给飘飞层飘走
    private let removeDuration: Double = 0.25

    private init() {}

    /// 兼容旧接口：最后加入的那条
    public var current: FSToastMessage? { items.last }

    public func show(_ text: String, duration: Double) {
        guard !text.isEmpty else { return }
        if Thread.isMainThread {
            MainActor.assumeIsolated { self.showOnMain(text, duration: duration) }
        } else {
            DispatchQueue.main.async {
                MainActor.assumeIsolated { self.showOnMain(text, duration: duration) }
            }
        }
    }

    /// 主动收掉某一条（id 来自 show 时分配）
    public func dismiss(_ id: Int) {
        if Thread.isMainThread {
            MainActor.assumeIsolated { self.dismissOnMain(id) }
        } else {
            DispatchQueue.main.async {
                MainActor.assumeIsolated { self.dismissOnMain(id) }
            }
        }
    }

    /// 一次清空
    public func dismissAll() {
        if Thread.isMainThread {
            MainActor.assumeIsolated { self.dismissAllOnMain() }
        } else {
            DispatchQueue.main.async {
                MainActor.assumeIsolated { self.dismissAllOnMain() }
            }
        }
    }

    /// 回填某条 toast 当前的位置。由 `FSToastOverlay` 的 `onGeometryChange` 调用
    func record(_ rect: CGRect, id: Int) {
        rects[id] = rect
    }

    // MARK: 插入

    @MainActor
    private func showOnMain(_ text: String, duration: Double) {
        seq += 1
        // 注意：这里**不直接**改 items，只入队。真正的插入在 drainPending 里按间隔逐条进行，
        // 这样每一条都能独占一帧，插入 + 已有条目上移的动画一定看得见。
        pending.append(FSToastMessage(id: seq, text: text, duration: duration))

        // 队列同样设上限：日志刷屏时若入队几十条，逐条 0.14s 会把屏幕占满好几秒，
        // 直接丢掉最旧的排队项，只保留最新的 maxVisible 条。
        let limit = max(maxVisible, 1)
        if pending.count > limit {
            pending.removeFirst(pending.count - limit)
        }

        drainPending()
    }

    /// 逐条把 `pending` 落进 `items`，两条之间隔 `insertInterval`。
    @MainActor
    private func drainPending() {
        guard !isDraining else { return }
        isDraining = true

        Task { @MainActor in
            while !self.pending.isEmpty {
                let next = self.pending.removeFirst()
                self.insertOnMain(next)

                // 后面还有排队的话，让本条动画先跑出去一帧再插下一条
                if !self.pending.isEmpty {
                    try? await Task.sleep(for: .seconds(self.insertInterval))
                }
            }
            // 本循环内没有 await 跨越，这里置回 false 不会被别的 show 抢跑
            self.isDraining = false
        }
    }

    @MainActor
    private func insertOnMain(_ msg: FSToastMessage) {
        var list = items
        list.append(msg)
        let limit = max(maxVisible, 1)
        if list.count > limit {
            // 被挤掉的最旧一条**直接消失，不飘**。
            // 取舍：这只会在刷屏（debug 日志）时发生，那种情况下再叠 6 个飘飞反而更乱。
            list.removeFirst(list.count - limit)
        }

        withAnimation(.easeOut(duration: Self.overlayAnimationDuration)) {
            items = list
        }

        // 停留计时从「真正出现在屏幕上」开始算，排队等待的时间不计入，
        // 否则多条同时来时，后面的会还没露脸就被收掉。
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(max(msg.duration, 0)))
            self.dismissOnMain(msg.id)
        }
    }

    // MARK: 移除

    @MainActor
    private func dismissOnMain(_ id: Int) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let msg = items[index]

        // 兜底：正常情况下 rects 一定有值（每条至少显示 duration 秒）
        let rect = rects[id] ?? CGRect(x: 0, y: HEIGHTFC / 2 - 20, width: WIDTHFC, height: 40)
        let anchor = CGPoint(x: rect.midX, y: rect.midY)

        // 先摘掉：下方条目在同一笔动画里上移让位
        withAnimation(.easeOut(duration: Self.overlayAnimationDuration)) {
            _ = items.remove(at: index)
        }

        // 再交给飘飞层接着飘。视图层的 removal transition 是 `.identity`，两者同帧交接
        let sign: CGFloat = Bool.random() ? 1 : -1
        let lateral = lateralOffset(for: rect, sign: sign)
        let rise = CGFloat.random(in: FSToastMotion.riseRange)
        // 倍率在起飞那一刻定死：已经飞着的不能被中途变速，否则会跳帧
        let life = Double.random(in: FSToastMotion.lifeRange) * FSToastMotion.speed
        // 倾斜方向跟横向漂移同号：往右飘就往右歪，像被同一股气流带走
        let tilt = CGFloat.random(in: FSToastMotion.tiltRange) * .pi / 180 * sign

        fly.append(
            FSToastFly(
                id: msg.id,
                text: msg.text,
                anchor: anchor,
                lateral: lateral,
                rise: rise,
                life: life,
                tilt: tilt,
                birth: Date()
            )
        )

        let flyID = msg.id
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(life))
            self.fly.removeAll { $0.id == flyID }
        }
    }

    @MainActor
    private func dismissAllOnMain() {
        // 排队的也一并丢掉，否则清空后它们还会一条条冒出来
        pending.removeAll()

        // 正在飘的必须硬清。否则「清空 + 立刻 push 新页面」时，飘飞会浮在新页面上
        // 继续飘 1.7 秒 —— 也就是上一个页面的提示飘过下一个页面。
        fly.removeAll()

        guard !items.isEmpty else { return }
        withAnimation(.easeOut(duration: removeDuration)) {
            items.removeAll()
        }
    }

    /// 算这一颗的横向偏移。
    ///
    /// 不能给死值：长文本 toast 宽度接近 `WIDTHFC - 50`，两侧只剩十来 pt 余量，
    /// 硬歪 58pt 会有一大块文字被屏幕边缘切掉（是切边，不是淡出）。所以按「这颗实际
    /// 能往那边走多远」动态收敛 —— 短文本照满 58pt（约 16°），长文本自动压到几 pt。
    /// 观感上正好是长句飘得稳，符合直觉。
    private func lateralOffset(for rect: CGRect, sign: CGFloat) -> CGFloat {
        // 留 8pt 给中途的侧向鼓出，保证末端不正好顶到屏幕边
        let roomOnSide = sign > 0
            ? WIDTHFC - rect.maxX - 8
            : rect.minX - 8

        let budget = min(max(roomOnSide, 0), FSToastMotion.maxLateral)
        return budget * CGFloat.random(in: FSToastMotion.lateralRatio) * sign
    }
}

// MARK: - 浮层

/// 浮层：把 `FSToastCenter.items` 竖直排列，多条并存时逐条往上让位；
/// 飘走中的条目转由 `flyLayer` 在布局外绝对定位渲染。
public struct FSToastOverlay: View {

    private let center = FSToastCenter.shared

    private var maxWidth: CGFloat { WIDTHFC - 50 }

    public init() {}

    public var body: some View {
        ZStack {
            VStack(spacing: 10) {
                ForEach(center.items) { msg in
                    toastBody(msg.text)
                        .transition(
                            .asymmetric(
                                // 从下方 12pt 浮入：和飘走的朝上方向接得住，读起来像一颗
                                // 气泡从下面冒出来、待一会儿、又飘走
                                insertion: .offset(y: 12)
                                    .combined(with: .scale(scale: 0.96))
                                    .combined(with: .opacity),
                                // 移除不做过渡：立刻消失，由飘飞层同帧接手
                                removal: .identity
                            )
                        )
                        .onGeometryChange(for: CGRect.self) { proxy in
                            proxy.frame(in: .named(FSToastMotion.space))
                        } action: { rect in
                            center.record(rect, id: msg.id)
                        }
                }
            }
            // 视图层再声明一次动画：模型层的 `withAnimation` 依赖事务传递，
            // 若 show 恰好发生在某次视图更新中途，事务会被吞掉（表现为「有时候没有动画」）。
            // 这里按 id 列表变化兜底，保证插入 / 让位一定走动画。
            // 移除不需要兜底 —— 它走 `.identity`，动画由飘飞层自己驱动。
            .animation(.easeOut(duration: FSToastCenter.overlayAnimationDuration),
                       value: center.items.map(\.id))

            flyLayer
        }
        // 必须显式撑满，不能靠子视图把 ZStack 撑开。
        //
        // 没有 fly 时 `flyLayer` 是 EmptyView，ZStack 就只剩 VStack，尺寸等于一条 toast 的
        // 内容尺寸；等 fly 出现、GeometryReader 进来，ZStack 才变成全屏 —— 命名坐标空间的
        // 原点会跟着从「VStack 左上角」跳到「屏幕左上角」。
        // 结果就是 `onGeometryChange` 存下的 anchor 在新坐标里落到页面左上角，
        // 表现为「停留结束突然崩到顶部再飘走」。（2026-10-26 实机踩到）
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .coordinateSpace(.named(FSToastMotion.space))
        .allowsHitTesting(false)
    }

    // MARK: 飘走图层

    /// 布局之外的独立图层。
    ///
    /// 用 `.position` 绝对定位，不占用 VStack 的任何槽位，所以「让位」和「飘走」
    /// 可以同时发生。每次只跑 `life` 那么久，跑完自己从 `fly` 里删掉。
    @ViewBuilder
    private var flyLayer: some View {
        if !center.fly.isEmpty {
            GeometryReader { _ in
                TimelineView(.animation) { timeline in
                    ZStack(alignment: .topLeading) {
                        ForEach(center.fly) { item in
                            let phase = progressFraction(item, at: timeline.date)
                            let eased = easeFraction(phase)
                            // 侧向鼓出始终朝这颗歪的方向，中途最鼓、两端归零
                            let away: CGFloat = item.lateral >= 0 ? 1 : -1
                            let bulge = sin(CGFloat(phase) * .pi) * FSToastMotion.wobble * away

                            toastBody(item.text)
                                // 从 0° 渐变到终值：起飞瞬间不跳，越飘越歪
                                .rotationEffect(.radians(item.tilt * eased))
                                .scaleEffect(1 - (1 - FSToastMotion.shrink) * eased)
                                .opacity(fadeFraction(phase))
                                .position(
                                    x: item.anchor.x + item.lateral * eased + bulge,
                                    y: item.anchor.y - item.rise * eased
                                )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            // 每帧由 TimelineView 驱动，不能让外层隐式动画再插一层
            .transaction { $0.animation = nil }
        }
    }

    // MARK: 曲线

    private func progressFraction(_ fly: FSToastFly, at date: Date) -> Double {
        let raw = date.timeIntervalSince(fly.birth) / fly.life
        return min(max(raw, 0), 1)
    }

    /// 上浮位移：先冲后缓
    private func easeFraction(_ progress: Double) -> CGFloat {
        CGFloat(1 - pow(1 - progress, 2.2))
    }

    /// 透明度：从起飞第一帧就开始淡出（`holdOpacityRatio` 为 0，没有保持期）。
    /// 曲线取 `(1 - progress)^1.25` —— 开头比线性更果断一点（起步就有可见变化），
    /// 末期由 `pow` 收缓，配合 shrink 看起来是「散掉」，不是「被切掉」。
    private func fadeFraction(_ progress: Double) -> Double {
        if progress <= FSToastMotion.holdOpacityRatio { return 1 }
        let tail = (progress - FSToastMotion.holdOpacityRatio) / (1 - FSToastMotion.holdOpacityRatio)
        return pow(max(0, 1 - tail), 1.25)
    }

    // MARK: 外观

    private func toastBody(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 10)
            .frame(minHeight: 40)
            .fixedSize(horizontal: false, vertical: true)
            .background(Color(red: 73.0 / 255, green: 80.0 / 255, blue: 86.0 / 255).opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            .frame(maxWidth: maxWidth)
    }
}
