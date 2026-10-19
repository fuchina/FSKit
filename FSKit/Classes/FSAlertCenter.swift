//
//  FSAlertCenter.swift
//  FSKit
//
//  2026-10-15 全 SwiftUI 化：
//  调用方把内容塞进这里，由根视图（主 App 的 AppRootScreen）统一渲染。
//
//  ⇒ 全项目 343 处调用点**一行都不用改**（签名保留、`controller` 参数被忽略），
//
//  2026-10-17 自绘弹窗（第二轮）：
//  系统 `.alert` 有两个做不到的事：
//    ① 点遮罩关闭 —— 系统 alert 按设计不支持，原来靠 `UIAlertController.addTapEvent`
//       往 keyWindow 的 UITransitionView 挂手势，改造后弹窗落在 SwiftUI 的 overlay 里，
//       那条路径彻底失效（约 28 处「点空白区消失」全哑了，记账弹窗就退不出去）；
//    ② 输入框初始文本 —— `FSAlertInputSpec` 只带 placeholder，`tf.text = model.bz` 的预填丢失。
//  故 alert 改为**自绘**：`FSAlertDialog` 负责遮罩 / 面板 / 输入框 / 按钮，
//  `tapOutsideToDismiss` 由 `addTapEvent` 登记。actionSheet 继续用系统 `confirmationDialog`
//  （它原生支持点外关闭，也原生跟 iPad 的 popover 适配）。
//

import SwiftUI
import UIKit

/// 弹窗形态（原 `UIAlertController.Style`）
///
/// 2026-10-17：弹窗全程由 SwiftUI 自绘，UIKit 的这两个枚举只是被当值用，
/// 换成自有枚举后调用点的 `.alert` / `.actionSheet` 字面量写法完全不变。
public enum FSAlertStyle {
    case alert
    case actionSheet
}

/// 按钮样式（原 `UIAlertAction.Style`）
///
/// `.cancel` 在 actionSheet 里走系统的取消位；`.destructive` 显示红字。
public enum FSAlertActionStyle {
    case `default`
    case cancel
    case destructive
}

/// 输入框键盘类型
///
/// 2026-10-17：SwiftUI **没有**自己的键盘枚举 —— `View.keyboardType(_:)` 参数直接就是
/// `UIKeyboardType`。为了让 `FSAlertInputConfig` 不对外暴露 UIKit 类型，这里定义自有枚举，
/// 由 `FSAlertDialog` 渲染时映射回 `UIKeyboardType`。**内核仍是 UIKit，只是不再外泄**。
public enum FSAlertKeyboard {
    case `default`
    case asciiCapable
    case alphabet
    case numbersAndPunctuation
    case numberPad
    case decimalPad

    var uiKeyboardType: UIKeyboardType {
        switch self {
        case .default: return .default
        case .asciiCapable: return .asciiCapable
        case .alphabet: return .alphabet
        case .numbersAndPunctuation: return .numbersAndPunctuation
        case .numberPad: return .numberPad
        case .decimalPad: return .decimalPad
        }
    }
}

/// 一个弹窗按钮
public struct FSAlertActionSpec: Identifiable {

    public let id = UUID()
    public var title: String
    public var style: FSAlertActionStyle
    public var handler: (() -> Void)?

    public init(title: String, style: FSAlertActionStyle, handler: (() -> Void)?) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}

/// alert 里的一个输入框（原 `UIAlertController.addTextField`）
public struct FSAlertInputSpec: Identifiable {

    public let id = UUID()
    public var placeholder: String
    /// 键盘类型（自有枚举，见 `FSAlertKeyboard` 的说明）
    public var keyboardType: FSAlertKeyboard
    /// 初始文本（原 `UITextField.text`，改造时漏掉的预填，如记账弹窗的备注）
    public var text: String
    /// 有内容时右侧显示清除按钮
    public var showsClearButton: Bool
    /// 自动大写（SwiftUI 原生类型，直接透传给 `.textInputAutocapitalization`)
    public var autocapitalization: TextInputAutocapitalization?
    /// 关闭自动更正（拼音简写 / 代码类输入）
    public var autocorrectionDisabled: Bool
    /// 点按钮时把当前文本回写（原 `UITextField` 语义，供调用方从 `textFields` 取值）
    public var commit: (String) -> Void

    public init(placeholder: String,
                keyboardType: FSAlertKeyboard = .default,
                text: String = "",
                showsClearButton: Bool = false,
                autocapitalization: TextInputAutocapitalization? = nil,
                autocorrectionDisabled: Bool = false,
                commit: @escaping (String) -> Void) {
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.text = text
        self.showsClearButton = showsClearButton
        self.autocapitalization = autocapitalization
        self.autocorrectionDisabled = autocorrectionDisabled
        self.commit = commit
    }
}

/// 一条弹窗（nil = 不显示）
///
/// Swift 6 语言模式：`spec` 会被送进 `@MainActor` 闭包，故声明 `@unchecked Sendable`
/// （纯数据载体；内含的 handler / commit 闭包由调用方在主线程执行）。
public struct FSAlertSpec: Identifiable, @unchecked Sendable {

    public let id = UUID()
    /// alert 还是 actionSheet（iPad 上由上游强制转 alert）
    public var style: FSAlertStyle
    public var title: String
    public var message: String
    public var actions: [FSAlertActionSpec]
    /// 输入框（0 = 普通弹窗）
    public var inputs: [FSAlertInputSpec]
    /// 点遮罩是否关闭。**默认 true** —— 2026-10-19 用户要求「所有 alert 都支持点空白区关闭」。
    /// 需要「必须做出选择」的弹窗（危险操作确认）可显式传 false。
    public var tapOutsideToDismiss: Bool
    /// 点遮罩时的附加条件：返回 false = 这次不关（有内容就不关，原 `handleAlertClick` 的语义）
    public var tapOutsideCanDismiss: (([String]) -> Bool)?

    public init(style: FSAlertStyle,
                title: String,
                message: String,
                actions: [FSAlertActionSpec],
                inputs: [FSAlertInputSpec] = [],
                tapOutsideToDismiss: Bool = true,
                tapOutsideCanDismiss: (([String]) -> Bool)? = nil) {
        self.style = style
        self.title = title
        self.message = message
        self.actions = actions
        self.inputs = inputs
        self.tapOutsideToDismiss = tapOutsideToDismiss
        self.tapOutsideCanDismiss = tapOutsideCanDismiss
    }
}

/// 全局弹窗中心。**可从任意线程调用**（内部自行切主线程）。
///
/// 2026-10-19：`alert` 的后端从 SwiftUI 自绘（`FSAlertDialog`）换成原生 `UIAlertController`。
/// - 观感 / 材质 / 键盘避让 / 无障碍 / iPad 适配全部交还系统；
/// - 「点空白区关闭」由挂在 `presentationController.containerView` 上的手势补回
///   （系统 alert 没有这个能力；判据见 `FSAlertTapOutside`）；
/// - `actionSheet` 仍走 SwiftUI 的 `confirmationDialog`（它本来就是原生 action sheet）。
///
/// 自绘那套代码（`FSAlertDialog`）保留在本文件末尾，不再被引用。
public final class FSAlertCenter: ObservableObject, @unchecked Sendable {

    public static let shared = FSAlertCenter()

    public static let presentAnimation: Animation = .interpolatingSpring(stiffness: 1000, damping: 40)
    public static let textPresentAnimation: Animation = .interpolatingSpring(stiffness: 522.35, damping: 45.71)
    public static let dismissAnimation: Animation = .easeOut(duration: 0.18)

    static func presentAnimation(for spec: FSAlertSpec) -> Animation {
        spec.inputs.isEmpty ? textPresentAnimation : presentAnimation
    }

    /// 当前弹窗。
    /// - `.actionSheet`：这是**渲染源**，`FSAlertHost` 靠它出界面；
    /// - `.alert`：**只作状态标记**（SwiftUI 的 `.fsAlert` 靠它的 id 变化同步 `isPresented`），
    ///   界面由 UIKit 的 `UIAlertController` 呈现，不参与 SwiftUI 渲染。
    @Published public private(set) var current: FSAlertSpec?

    /// 输入框文本（与当前弹窗的 `inputs` 一一对应）
    @Published public var inputTexts: [String] = []

    // MARK: 内部状态

    /// 排队中的弹窗：`UIAlertController` 一次只能 present 一条，
    /// 正在显示时再 present 第二条会**静默失败**（无 completion、view.window == nil），必须排队。
    private var pending: [FSAlertSpec] = []
    private var activeAlert: UIAlertController?
    private var activeSpec: FSAlertSpec?
    private var tapProxy: FSAlertTapOutside?
    private var retryCount = 0

    private init() {}

    // MARK: 对外

    public func show(_ spec: FSAlertSpec) {
        onMain { [weak self] in
            guard let self else { return }

            if spec.style == .actionSheet {
                self.inputTexts = spec.inputs.map { $0.text }
                withAnimation(FSAlertCenter.presentAnimation(for: spec)) { self.current = spec }
                return
            }

            self.pending.append(spec)
            self.pump()
        }
    }

    public func dismiss() {
        onMain { [weak self] in
            guard let self else { return }

            if let cur = self.current, cur.style == .actionSheet {
                withAnimation(FSAlertCenter.dismissAnimation) { self.current = nil }
                return
            }

            guard let alert = self.activeAlert else {
                self.pending.removeAll()
                return
            }

            // 有输入框时先交还第一响应者，键盘立刻开始收起
            //（与原自绘版一致：否则键盘收起动画会叠到下一个页面）
            if alert.textFields?.isEmpty == false {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                to: nil, from: nil, for: nil)
            }
            self.inputTexts = alert.textFields?.map { $0.text ?? "" } ?? self.inputTexts

            let spec = self.activeSpec
            self.activeAlert = nil
            self.activeSpec = nil
            self.tapProxy = nil
            if let spec, self.current?.id == spec.id { self.current = nil }

            alert.dismiss(animated: true) { [weak self] in self?.pump() }
        }
    }

    // MARK: 呈现

    private func pump() {
        guard activeAlert == nil else { return }
        guard pending.isEmpty == false else { retryCount = 0; return }

        // 宿主还没空出来（上一条正在 dismiss、或 SwiftUI 有 sheet）就等一会儿再来
        guard let host = FSAlertCenter.topViewController(),
              host.presentedViewController == nil else {
            scheduleRetry()
            return
        }

        retryCount = 0
        let spec = pending.removeFirst()
        present(spec, on: host)
    }

    private func scheduleRetry() {
        guard retryCount < 100 else { retryCount = 0; return }   // 最多等 5 秒（50ms × 100）
        retryCount += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in self?.pump() }
    }

    private func present(_ spec: FSAlertSpec, on host: UIViewController) {
        let alert = UIAlertController(title: spec.title.isEmpty ? nil : spec.title,
                                      message: spec.message.isEmpty ? nil : spec.message,
                                      preferredStyle: .alert)

        for input in spec.inputs {
            alert.addTextField { field in
                field.placeholder = input.placeholder
                field.text = input.text
                field.keyboardType = input.keyboardType.uiKeyboardType
                field.autocorrectionType = input.autocorrectionDisabled ? .no : .default
                field.clearButtonMode = input.showsClearButton ? .whileEditing : .never
            }
        }

        for action in spec.actions {
            alert.addAction(UIAlertAction(title: action.title,
                                          style: action.style.uiAlertStyle) { [weak self] _ in
                guard let self else { return }
                self.finish(spec, alert: alert)
                action.handler?()
                // 此刻系统正在 dismiss，`pump` 里会检查宿主是否空出来，必要时自动重试
                self.pump()
            })
        }

        activeAlert = alert
        activeSpec = spec
        inputTexts = spec.inputs.map { $0.text }
        current = spec

        host.present(alert, animated: true) { [weak self] in
            self?.installTapOutside(spec, alert: alert)
        }
    }

    /// 按钮点击后收尾：回写文本、清状态、让 SwiftUI 的 `isPresented` 归 false
    private func finish(_ spec: FSAlertSpec, alert: UIAlertController) {
        if let fields = alert.textFields {
            inputTexts = fields.map { $0.text ?? "" }
            for (index, input) in spec.inputs.enumerated() where index < inputTexts.count {
                input.commit(inputTexts[index])
            }
        }
        activeAlert = nil
        activeSpec = nil
        tapProxy = nil
        if current?.id == spec.id { current = nil }
    }

    /// 点空白区关闭：系统 alert 不提供这个能力，只能往它所在的过渡容器上挂手势。
    ///
    /// 2026-10-19 实测（iPhone 17 Pro / iOS 26.5 与 iPhone 16 Pro / iOS 18.5 结论一致）：
    /// - `alert.view` 的 frame **就是面板矩形**，点面板外的事件根本投递不到它（hitTest 返回 nil）；
    /// - 面板与黑色 0.2 的遮罩是 `containerView`（全屏 `UITransitionView`）下的兄弟视图；
    /// - 所以手势挂 containerView，判据用「touch.view 是否在 alert.view 里面」：
    ///   不比坐标、不受入场动画影响、也不依赖任何私有类名。
    private func installTapOutside(_ spec: FSAlertSpec, alert: UIAlertController) {
        // `tapOutsideToDismiss` 是总开关，`tapOutsideCanDismiss` 只是附加条件
        //（与原自绘版 `FSAlertDialog` 的判定完全一致）
        guard spec.tapOutsideToDismiss else { return }
        guard let container = alert.presentationController?.containerView else { return }

        let proxy = FSAlertTapOutside()
        proxy.alert = alert
        proxy.onTap = { [weak self, weak alert] in
            guard let self, let alert else { return }
            // 输入框内容要先同步回来，`tapOutsideCanDismiss` 才拿得到最新文本
            let texts = alert.textFields?.map { $0.text ?? "" } ?? []
            self.inputTexts = texts
            if let can = spec.tapOutsideCanDismiss, !can(texts) { return }
            self.dismiss()
        }

        let tap = UITapGestureRecognizer(target: proxy, action: #selector(FSAlertTapOutside.handle(_:)))
        tap.cancelsTouchesInView = false
        tap.delegate = proxy
        container.addGestureRecognizer(tap)
        tapProxy = proxy
    }

    // MARK: 宿主

    /// 当前正在交互的 scene 里最上层的控制器（present 的落点）
    static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        let window = scene?.windows.first { $0.isKeyWindow } ?? scene?.windows.first
        guard var top = window?.rootViewController else { return nil }

        // 已经有一层弹窗在屏幕上时，不要在它上面再叠一层（会 present 失败），
        // 返回它的宿主，让 `pump` 的 `presentedViewController == nil` 判断去排队等。
        while let presented = top.presentedViewController {
            if presented is UIAlertController {
                return presented.presentingViewController ?? top
            }
            top = presented
        }
        while true {
            if let nav = top as? UINavigationController, let visible = nav.visibleViewController {
                top = visible; continue
            }
            if let tab = top as? UITabBarController, let selected = tab.selectedViewController {
                top = selected; continue
            }
            break
        }
        return top
    }

    // MARK: 线程

    private func onMain(_ block: @escaping @MainActor () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated { block() }
        } else {
            DispatchQueue.main.async { MainActor.assumeIsolated { block() } }
        }
    }
}

/// 点空白区关闭的手势代理。
///
/// 只做一件事：认出「落在面板外」的 tap。`shouldReceive` 用视图层级而不是坐标判断，
/// 入场动画、旋转、动态字体调整都不会误判。
final class FSAlertTapOutside: NSObject, UIGestureRecognizerDelegate {

    weak var alert: UIAlertController?
    var onTap: (() -> Void)?

    @objc func handle(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        onTap?()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        guard let alert else { return false }
        return !(touch.view?.isDescendant(of: alert.view) ?? false)
    }
}

extension FSAlertActionStyle {

    var uiAlertStyle: UIAlertAction.Style {
        switch self {
        case .default: return .default
        case .cancel: return .cancel
        case .destructive: return .destructive
        }
    }
}

// MARK: - 渲染器

/// 弹窗渲染器（由根视图挂载）。
///
/// 2026-10-19 起只剩 actionSheet：alert 已交给 `UIAlertController` 直接 present。
public struct FSAlertHost: View {

    @ObservedObject private var center = FSAlertCenter.shared

    public init() {}

    public var body: some View {
        // alert 已改由 UIKit 的 `UIAlertController` 直接 present（见 `FSAlertCenter`），
        // 这里只保留 actionSheet 这一条路径 —— 系统 `confirmationDialog` 原生支持点外关闭，
        // 也自带 iPad popover 适配。
        Color.clear
            .frame(width: 0, height: 0)
            .confirmationDialog(center.current?.title ?? "",
                                isPresented: Binding(get: { center.current?.style == .actionSheet },
                                                     set: { if !$0, center.current?.style == .actionSheet { center.dismiss() } }),
                                presenting: center.current) { spec in
                actionButtons(for: spec)
            } message: { spec in
                if spec.message.isEmpty == false {
                    Text(spec.message)
                }
            }
    }

    /// actionSheet 的按钮（系统渲染，TextField 不支持，与改造前一致）
    @ViewBuilder
    private func actionButtons(for spec: FSAlertSpec) -> some View {
        ForEach(spec.actions) { action in
            Button(action.title, role: role(for: action.style)) {
                for (i, input) in spec.inputs.enumerated() where i < center.inputTexts.count {
                    input.commit(center.inputTexts[i])
                }
                action.handler?()
            }
        }
    }

    private func role(for style: FSAlertActionStyle) -> ButtonRole? {
        switch style {
        case .destructive: return .destructive
        case .cancel: return .cancel
        default: return nil
        }
    }
}

// MARK: - 自绘 alert

/// 自绘 alert：遮罩 + 居中面板 + 输入框 + 按钮。
///
/// 2026-10-18 按**实测数据**重排（探针 App 在 iPhone 17 Pro / iOS 26.5 上逐帧采样系统 alert）：
/// - 面板 320 宽、**圆角 34**；背景纯 `thinMaterial`（不压黑，浅底上约 227，比系统 201 亮）；
///   内侧一圈 12pt 柔和高光模拟 Liquid Glass 的边缘折射（系统有，材质 API 给不了）。
/// - 标题左对齐 17pt / 说明 15pt，左右边距 **16**；说明到输入块 16。
/// - 输入块行高 **48**、圆角 16、底与按钮同灰（浅色 black 8% ≈ 208），行间分隔线为**实色**（浅色 150）。
/// - 按钮 **两个时横排**（各 140×48、间距 8、圆角 24 胶囊，实测坐标 57/205），
///   三个及以上竖排；高 48、黑字、destructive 红字。
/// - 垂直位置不用管：`ZStack` 本身就在**安全区内**居中，实测系统 y=319、自绘 320。
/// - 入场**不做透明度过渡**：面板以满不透明度直接出现，只靠缩放收口（淡入会把缩放糊掉）。
///   遮罩是唯一例外，留 0.15s 压暗，避免整屏硬闪。
/// - 入场分两种（见 `FSAlertCenter.presentAnimation(for:)` 与 `entranceStart`）：
///   **输入框模式** 0.96 → 1.0 + 高刚度快曲线（劲道来自键盘那 137pt 上移）；
///   **纯文字模式** 1.05 → 1.0 + 系统原始曲线（从稍大缩回正常，慢一点才看得出动作）。
///   ⚠️ 系统 alert 的 transform 实测恒为 1.0、曲线是 ζ=1 的临界阻尼。两处缩放都是有意偏离系统。
/// - 退场：单独的 `dismissAnimation`（0.18s easeOut），比入场快，键盘收起不会拖到下一个页面。
///
/// 与系统唯一的行为差异是「点遮罩可以关闭」—— 但只在调用方显式登记过 `addTapEvent` 时生效，
/// 其余弹窗点遮罩依旧什么都不发生（与原系统 alert 一致）。
private struct FSAlertDialog: View {

    let spec: FSAlertSpec
    @ObservedObject var center: FSAlertCenter

    /// 深浅色要分开取值：实测的 rgb(236) 是**浅色**下的输入块，深色下同样用白 60% 会变成刺眼的白块
    @Environment(\.colorScheme) private var colorScheme

    /// 当前聚焦的输入框（有输入框时弹出来就聚焦第 0 个 ⇒ 键盘直接弹起、面板上移）
    @FocusState private var focusedIndex: Int?

    /// 键盘弹出后的一次性上移量（负数 = 往上）。**算出一次就锁死**，之后键盘再怎么变都不动。
    @State private var keyboardLift: CGFloat = 0
    /// 是否已经算过位置
    @State private var liftDone = false
    /// 覆盖层高度：只用来算「内容滚动上限」，**不参与布局**
    @State private var hostHeight: CGFloat = 800
    /// 入场进度 0 → 1，只驱动面板的缩放（0.92 → 1.0）。
    /// 不放在 `transition` 上：那会把全屏遮罩一起缩放，边缘会露出底下一层。
    @State private var entrance: CGFloat = 0

    /// 遮罩压暗进度 0 → 1。
    /// 面板本身已经不渐显了，但**整屏遮罩必须留一点过渡**：0.2 的黑如果一帧砸下来，
    /// 整块屏幕会"闪"一下，比淡入更难看。
    @State private var scrimAlpha: CGFloat = 0

    /// 实测值：系统 iPhone 竖屏 alert 面板 320 宽、圆角 34
    private let panelWidth: CGFloat = 320
    private let panelShape = RoundedRectangle(cornerRadius: 34, style: .continuous)

    /// 入场缩放的**起点**（`entrance` 走到 1 时收口到 1.0）。
    /// - 有输入框：0.96 → 1.0，**从小到大**。这段缩放只是为了给键盘那 137pt 上移收个口，
    ///   配合快曲线才有"弹上来一把按住"的劲。
    /// - 纯文字：1.05 → 1.0，**从稍大缩回正常**。没有键盘位移兜底，纯文字弹窗要的就是这个过程本身
    ///   （用户 2026-10-18：「系统效果好像是从一个稍大的变到正常大小」）。
    private var entranceStart: CGFloat {
        spec.inputs.isEmpty ? 1.05 : 0.96
    }

    /// 面板相对「安全区内居中」的**起始**偏移。
    /// 2026-10-18 用户：「输入模式时，弹窗的初始位置太矮了，往上移 50」——
    /// 纯文字弹窗居中刚好，输入弹窗看起来偏低，所以只给输入模式抬高 50pt。
    ///
    /// ⚠️ 只抬**起点**，**终点不动**：键盘弹出后落点仍等于系统的避让位置（居中再 -(键盘高-安全区)/2）。
    /// 所以 `keyboardLift` 里要把这 50 减掉（见 `onReceive` 那段），否则终点会跟着一起上移 50。
    private var baseOffset: CGFloat {
        spec.inputs.isEmpty ? 0 : -50
    }

    var body: some View {
        // 注意：这里**不能**套 GeometryReader —— 它会换掉布局上下文，
        // 键盘弹出时面板不再跟着系统避让上移，输入类弹窗会被键盘盖住。
        ZStack {
            // 遮罩：系统 alert 的压暗程度。
            // 面板不渐显了，遮罩还留 0.15s 过渡 —— 否则整屏亮度会硬切。
            Color.black.opacity(0.2)
                .opacity(scrimAlpha)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .gesture(SpatialTapGesture().onEnded { _ in
                    guard spec.tapOutsideToDismiss else { return }
                    // 有内容就不关（原 `UIAlertController.handleAlertClick` 的语义）
                    if let can = spec.tapOutsideCanDismiss, !can(center.inputTexts) { return }
                    center.dismiss()
                })

            panel(maxTextHeight: max(150, hostHeight * 0.42))
                // 幅度刻意做小（4%）：用户「幅度不用大，但是劲道要大」。
                // 缩放负责"收口"，劲道交给曲线本身的速度（stiffness 1000）。
                .scaleEffect(entranceStart + (1 - entranceStart) * entrance)
                // baseOffset 是**静态**位置（输入模式整体上移 50），keyboardLift 是键盘那一下。
                // 两者相加，所以入场动画是从"已经抬高的位置"开始的，不是先出现在低处再被顶上去。
                .offset(y: baseOffset + keyboardLift)
        }
        // 2026-10-18：**关掉系统的键盘避让**。原来的做法是让系统避让、再用 `+= delta/2`
        // 去补偿，但切换输入框时键盘高度一变（数字键盘 ↔ 全键盘），系统会重新居中，
        // 补偿量又是累加的 ⇒ 面板跟着上下跳。
        // 现在位置由我们自己定：键盘第一次弹出时上移一次 `(键盘高 - 底部安全区) / 2`
        // （实测系统避让量正是这个值：308 / 34 → 137），之后**再也不动**。
        .ignoresSafeArea(.keyboard)
        // 只测量、不改布局（等价于背景里塞一个 GeometryReader，但不影响尺寸提议）
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { hostHeight = $0 }
        // 入场动画由外层 transition + presentAnimation 统一驱动，
        // 这里补一下面板自身的缩放：没有它，弹窗只是"淡出来"，一点劲都没有。
        .onAppear {
            withAnimation(FSAlertCenter.presentAnimation(for: spec)) { entrance = 1 }
            // 遮罩单独走一条短曲线（不跟面板的 spring，否则 0.29s 才暗到位会显得拖）
            withAnimation(.easeOut(duration: 0.15)) { scrimAlpha = 1 }
        }
        .task(id: spec.id) {
            try? await Task.sleep(for: .milliseconds(12))
            guard spec.inputs.isEmpty == false else { return }
            focusedIndex = 0
        }
        // 键盘第一次弹出时算一次位置，然后**锁死**：
        // 之后切到哪个输入框、键盘变高变矮（数字键盘 ↔ 全键盘）面板都纹丝不动。
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            guard let end = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            guard end.height > 1 else { return }        // 收起：保持当前位置，不回弹
            guard liftDone == false else { return }     // 只认第一次
            liftDone = true

            let safeBottom = (UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .first?.safeAreaInsets.bottom) ?? 0

            // 上移也必须带弹性：输入弹窗的「入场」观感几乎全被这 137pt 平移吃掉，
            // 原来用 easeOut（均速收尾）看起来就是"纯平移、没有劲道"。
            //
            // 2026-10-18 用户二次要求：「弹上去的时间大一点，不要回弹」——
            // 上一版 ζ≈0.64 会过冲 7%（137pt × 7% ≈ 9.6pt），观感是"弹上去又缩回来一点"。
            // 现在刚度降到 450、阻尼提到 46 ⇒ **ζ≈1.08，轻微过阻尼，数学上不过冲**：
            //   90% 到位 0.20s、99% 到位 0.35s（原来 0.09s / 0.11s），慢一倍多，且一路单调到顶。
            // ⚠️ damping 必须 ≥ 2√stiffness（此处 42.43）才不过冲，改刚度时记得同步。
            // 终点**固定**在系统避让位置（居中再 -(键盘高-安全区)/2 = -137），
            // 起点已经被 baseOffset 抬高了 50，所以这里要减掉它 —— 否则终点也一起上移 50。
            // 结果：面板只走 137-50 = 87pt，但落点和原来一模一样。
            withAnimation(.interpolatingSpring(stiffness: 450, damping: 46)) {
                keyboardLift = -(end.height - safeBottom) / 2 - baseOffset
            }
        }
    }

    // MARK: 面板

    private func panel(maxTextHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            // 标题 / 说明：iOS 26 弹窗是左对齐；标题 17 半粗，说明降一档（15）+ 次要灰
            VStack(alignment: .leading, spacing: 6) {
                if spec.title.isEmpty == false {
                    Text(spec.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                }

                if spec.message.isEmpty == false {
                    // 短内容由 fixedSize 贴合自然高度，超长才滚动（如「每日一温」）。
                    // ⚠️ 别用 ViewThatFits：未入选的 ScrollView 照样参与尺寸计算，
                    // 会把容器顶到上限、入选的 Text 被垂直居中 —— 就是「上面大片空白」。
                    ScrollView(.vertical) {
                        messageText
                    }
                    .frame(maxHeight: maxTextHeight)
                    .fixedSize(horizontal: false, vertical: true)
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 22)
            .padding(.bottom, spec.inputs.isEmpty ? 0 : 16)

            // 输入框：多个输入框合成一个圆角块，中间一条分隔线（实测行高 48、圆角 16）
            if spec.inputs.isEmpty == false {
                VStack(spacing: 0) {
                    ForEach(Array(spec.inputs.enumerated()), id: \.offset) { index, input in
                        HStack(spacing: 8) {
                            TextField(input.placeholder, text: binding(index))
                                .textFieldStyle(.plain)
                                .keyboardType(input.keyboardType.uiKeyboardType)
                                .textInputAutocapitalization(input.autocapitalization)
                                .autocorrectionDisabled(input.autocorrectionDisabled)
                                .font(.system(size: 17))
                                .focused($focusedIndex, equals: index)

                            if input.showsClearButton, binding(index).wrappedValue.isEmpty == false {
                                Button {
                                    binding(index).wrappedValue = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 48)

                        if index < spec.inputs.count - 1 {
                            dividerH
                        }
                    }
                }
                // 底色跟按钮统一用灰（用户 2026-10-18 要求：原来是白 60%，和按钮一亮一暗太割裂）
                .background(colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 16)
            }

            // 无按钮的纯提示弹窗（如 FSAccount 的「欠债提示」2 秒自动关）不画按钮区，
            // 否则会留 34pt 空白
            if spec.actions.isEmpty == false {
                buttons
            } else {
                Color.clear.frame(height: 16)
            }
        }
        .frame(width: panelWidth)
        // 面板底：thinMaterial 打底，再**叠一层 25% 白**（用户 2026-10-18「面板再变白点」）。
        // 实测量级：纯材质 ≈227，叠白 a 后 = 227 + a×(255−227)，所以 0.25 → ≈234。
        // ⚠️ 叠白会削弱材质的通透和模糊层次（越白越像实色块），0.25 是"明显变白但还看得出材质"的上限附近；
        // 再往上（≥0.4）就基本是一张白纸了，那时候不如直接用 Color(.secondarySystemBackground)。
        // 深色模式不叠白：深色面板本来就该暗，叠白会糊成一片。
        .background {
            panelShape
                .fill(.thinMaterial)
                .overlay(panelShape.fill(Color.white.opacity(colorScheme == .dark ? 0 : 0.25)))
        }
        .overlay(edgeHighlight)
    }

    /// Liquid Glass 的边缘折射：系统面板内侧有一圈约 19pt 的高光带（rgb 228 对面板 201）。
    /// 材质 API 给不了真正的折射，用「宽而淡的内发光 + 细亮描边」近似。
    private var edgeHighlight: some View {
        ZStack {
            panelShape
                .strokeBorder(Color.white.opacity(0.20), lineWidth: 12)
                .blur(radius: 8)
            panelShape
                .strokeBorder(Color.white.opacity(0.40), lineWidth: 1.2)
                .blur(radius: 1.5)
        }
        .clipShape(panelShape)
        .allowsHitTesting(false)
    }

    /// 说明文字：有标题时比标题小一号 + 次要灰；没有标题时它就是主体，保持 17 号主色
    private var messageText: some View {
        Text(spec.message)
            .font(.system(size: spec.title.isEmpty ? 17 : 15))
            .foregroundColor(spec.title.isEmpty ? Color.primary : Color(uiColor: .secondaryLabel))
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 按钮

    /// 系统的排布规则：**两个按钮并排**（各 140 × 48、间距 8、左右边距 16），
    /// 三个及以上才转竖排。`.cancel` 在并排时固定占左位（系统把它当「次要动作」放左边）。
    private var orderedActions: [FSAlertActionSpec] {
        var items = spec.actions
        if items.count == 2,
           items[0].style != .cancel,
           items[1].style == .cancel {
            items.swapAt(0, 1)
        }
        return items
    }

    @ViewBuilder
    private var buttons: some View {
        Group {
            if spec.actions.count == 2 {
                HStack(spacing: 8) {
                    ForEach(orderedActions) { action in
                        actionButton(action)
                    }
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(orderedActions) { action in
                        actionButton(action)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, spec.inputs.isEmpty ? 18 : 20)
        .padding(.bottom, 16)
    }

    private func actionButton(_ action: FSAlertActionSpec) -> some View {
        Button {
            run(action)
        } label: {
            Text(action.title)
                .font(.system(size: 17))
                .foregroundColor(color(for: action.style))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                // 按钮改成**比面板暗的灰**（用户 2026-10-18 要求：白色块太抢、和面板拉不开）。
                // 浅色 black 8% ⇒ 实测 rgb(188)，对面板 208；深色仍用白 10%（深色下按钮该略亮）。
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5))
                }
                .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(FSAlertButtonStyle())
    }

    /// 输入行之间的分隔线。
    /// 用**实色**而不是 `.separator`：后者自带 alpha（浅色 #3C3C43 @29%），叠在 8% 灰的被
    /// 输入块上渲染成 ~151，换底色就跟着变，还会透出后面的内容。这里的色值就是按「叠在灰底上
    /// 的 .separator」反算出来的等效实色（浅色 150/150/155、深色 76/76/80），所见即所得。
    private var dividerH: some View {
        Rectangle()
            .fill(colorScheme == .dark
                  ? Color(red: 76 / 255, green: 76 / 255, blue: 80 / 255)
                  : Color(red: 150 / 255, green: 150 / 255, blue: 155 / 255))
            .frame(height: 0.5)
    }

    // MARK: 行为

    private func binding(_ index: Int) -> Binding<String> {
        Binding(get: { index < center.inputTexts.count ? center.inputTexts[index] : "" },
                set: { newValue in
                    if index < center.inputTexts.count { center.inputTexts[index] = newValue }
                })
    }

    private func run(_ action: FSAlertActionSpec) {
        // 先把用户输入回写到各自的 commit（原 textFields 语义）
        for (i, input) in spec.inputs.enumerated() where i < center.inputTexts.count {
            input.commit(center.inputTexts[i])
        }
        // 与 UIKit 一致：先收起弹窗，再跑 handler（handler 里可能弹出下一条）
        center.dismiss()
        action.handler?()
    }

    /// 图里默认按钮是黑字（iOS 26 的样式），只有 destructive 才是红字
    private func color(for style: FSAlertActionStyle) -> Color {
        style == .destructive ? Color(uiColor: .systemRed) : Color.primary
    }
}

/// 按下时轻微变淡（`.plain` 没有按压反馈，系统弹窗是有的）
private struct FSAlertButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.45 : 1.0)
    }
}
