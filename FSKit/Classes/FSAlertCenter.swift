//
//  FSAlertCenter.swift
//  FSKit
//
//  2026-10-15 全 SwiftUI 化：
//  `controller.present(...)`」，必须有 UIViewController 宿主。现改为「状态 + 根视图渲染」：
//  调用方把内容塞进这里，由根视图（主 App 的 AppRootScreen）统一渲染。
//
//  ⇒ 全项目 343 处调用点**一行都不用改**（签名保留、`controller` 参数被忽略），
//  也不再需要 `UIApplication.fs_topVC` 当宿主 —— 那 247 处「给弹窗找宿主」的写法会随之作废。
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
    /// 点遮罩是否关闭（原 `UIAlertController.addTapEvent` 的语义，默认不关）
    public var tapOutsideToDismiss: Bool
    /// 点遮罩时的附加条件：返回 false = 这次不关（有内容就不关，原 `handleAlertClick` 的语义）
    public var tapOutsideCanDismiss: (([String]) -> Bool)?

    public init(style: FSAlertStyle,
                title: String,
                message: String,
                actions: [FSAlertActionSpec],
                inputs: [FSAlertInputSpec] = [],
                tapOutsideToDismiss: Bool = false,
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
/// Swift 6 语言模式：`show` / `dismiss` 会把 `self` 送进 `@MainActor` 闭包，
/// 需要显式声明可跨隔离域传递，故补 `@unchecked Sendable`
/// （可变状态已由 `MainActor.assumeIsolated` 保证只在主线程访问）。
public final class FSAlertCenter: ObservableObject, @unchecked Sendable {

    // 2026-10-17：Pod 与主 App 统一为 SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor 后，
    // 本类及 shared 都是主隔离的，nonisolated(unsafe) 反而报错，故移除。
    public static let shared = FSAlertCenter()

    /// 当前要显示的弹窗（nil = 不显示）
    @Published public private(set) var current: FSAlertSpec?

    /// 输入框文本（与 `current?.inputs` 一一对应）
    @Published public var inputTexts: [String] = []

    private init() {}

    public func show(_ spec: FSAlertSpec) {
        let apply: @MainActor () -> Void = { [weak self] in
            guard let self else { return }
            self.inputTexts = spec.inputs.map { $0.text }
            self.current = spec
        }
        if Thread.isMainThread {
            MainActor.assumeIsolated { apply() }
        } else {
            DispatchQueue.main.async { MainActor.assumeIsolated { apply() } }
        }
    }

    public func dismiss() {
        let apply: @MainActor () -> Void = { [weak self] in
            guard let self else { return }
            self.current = nil
        }
        if Thread.isMainThread {
            MainActor.assumeIsolated { apply() }
        } else {
            DispatchQueue.main.async { MainActor.assumeIsolated { apply() } }
        }
    }
}

// MARK: - 渲染器

/// 弹窗渲染器（由根视图挂载）。
///
/// alert 走自绘（`FSAlertDialog`），actionSheet 走系统 `confirmationDialog`。
public struct FSAlertHost: View {

    @ObservedObject private var center = FSAlertCenter.shared

    public init() {}

    public var body: some View {
        ZStack {
            if let spec = center.current, spec.style == .alert {
                FSAlertDialog(spec: spec, center: center)
                    // 换一条弹窗就重建（如「每日一温」的下一篇）：滚动位置归零、入场动画重播；
                    // 不重建则 ScrollView 沿用上一条的偏移，下一篇会直接停在底部。
                    .id(spec.id)
                    .transition(.opacity)
                    .zIndex(1)
            }

            // actionSheet 仍交给系统：它原生支持点外关闭，也自带 iPad popover 适配
            Color.clear
                .frame(width: 0, height: 0)
                .confirmationDialog(center.current?.title ?? "",
                                    isPresented: Binding(get: { center.current?.style == .actionSheet },
                                                         set: { if !$0 { center.dismiss() } }),
                                    presenting: center.current) { spec in
                    actionButtons(for: spec)
                } message: { spec in
                    if spec.message.isEmpty == false {
                        Text(spec.message)
                    }
                }
        }
        // 0.18s 太短 ⇒ 观感生硬；放长到 0.3s，面板内部再叠一层 0.94 → 1 的 spring 缩放
        .animation(.easeOut(duration: 0.3), value: center.current?.id)
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
/// 2026-10-17 按 F 给的 iOS 26 截图复刻：
/// 面板宽 320、圆角 28、`.regularMaterial` 玻璃底；标题/说明**左对齐**、17pt；
/// 多个输入框合成**一个**圆角块（行高 45、中间 0.5pt 分隔线、有内容时右侧清除按钮）；
/// 按钮是**独立圆角填充块**（高 48、圆角 14、间距 8、黑字，destructive 红字）。
/// 与系统唯一的行为差异是「点遮罩可以关闭」—— 但只在调用方显式登记过 `addTapEvent` 时生效，
/// 其余弹窗点遮罩依旧什么都不发生（与原系统 alert 一致）。
private struct FSAlertDialog: View {

    let spec: FSAlertSpec
    @ObservedObject var center: FSAlertCenter

    /// 当前聚焦的输入框（有输入框时弹出来就聚焦第 0 个 ⇒ 键盘直接弹起、面板上移）
    @FocusState private var focusedIndex: Int?

    /// 第一段键盘的高度（用来判断后面键盘变高了多少）
    @State private var baseKeyboardHeight: CGFloat = 0
    /// 补偿量：抵消「键盘变高时系统又顶了一次」，正数 = 往下
    @State private var keyboardShift: CGFloat = 0
    /// 入场缩放：首帧 0.94，随即弹到 1（原先只有 0.18s 纯淡入，太快且生硬）
    @State private var appeared = false
    /// 覆盖层高度：只用来算「内容滚动上限」，**不参与布局**
    @State private var hostHeight: CGFloat = 800

    var body: some View {
        // 注意：这里**不能**套 GeometryReader —— 它会换掉布局上下文，
        // 键盘弹出时面板不再跟着系统避让上移，输入类弹窗会被键盘盖住。
        ZStack {
            // 遮罩：系统 alert 的压暗程度
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .gesture(SpatialTapGesture().onEnded { _ in
                    guard spec.tapOutsideToDismiss else { return }
                    // 有内容就不关（原 `UIAlertController.handleAlertClick` 的语义）
                    if let can = spec.tapOutsideCanDismiss, !can(center.inputTexts) { return }
                    center.dismiss()
                })

            panel(maxTextHeight: max(150, hostHeight * 0.42))
                .scaleEffect(appeared ? 1 : 0.94)
        }
        // 只测量、不改布局（等价于背景里塞一个 GeometryReader，但不影响尺寸提议）
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { hostHeight = $0 }
        // 入场：停一帧再开（否则首帧就被布局压成 1，缩放看不出来）；随后聚焦第一个输入框
        .task(id: spec.id) {
            try? await Task.sleep(for: .milliseconds(12))
            withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                appeared = true
            }

            guard spec.inputs.isEmpty == false else { return }
            focusedIndex = 0
        }
        // 上移**只交给系统**（SwiftUI 键盘避让，一次性、带系统动画）——
        // 自己再算一次位移就会「先动一下、再动一下」。
        // 这里只做补偿：第一个框是数字键盘、第二个框是全键盘，键高不同 ⇒ 切换焦点时系统会再顶一次，
        // 用等量反向 offset（Δ/2）抵消掉，面板就钉在第一次的位置上。
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            guard let end = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

            // 键盘收起：补偿归零
            guard end.height > 1 else {
                baseKeyboardHeight = 0
                withAnimation(nil) { keyboardShift = 0 }
                return
            }

            // 第一次：系统自己把面板顶上去，不补偿
            guard baseKeyboardHeight > 1 else {
                baseKeyboardHeight = end.height
                return
            }

            let delta = end.height - baseKeyboardHeight
            guard abs(delta) > 0.5 else { return }

            let duration = (note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
            withAnimation(.easeOut(duration: max(duration, 0.2))) {
                keyboardShift += delta / 2
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
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, spec.inputs.isEmpty ? 0 : 18)

            // 输入框：多个输入框合成一个圆角块，中间一条分隔线（图里的样式）
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
                        .frame(height: 45)

                        if index < spec.inputs.count - 1 {
                            dividerH
                        }
                    }
                }
                .background(Color(uiColor: .secondarySystemFill).opacity(0.75),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
        .frame(width: 320)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .offset(y: keyboardShift)
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

    /// 图里的样式：每个按钮是一个独立的圆角填充块（不是居中分隔线那一套）
    @ViewBuilder
    private var buttons: some View {
        VStack(spacing: 8) {
            ForEach(spec.actions) { action in
                actionButton(action)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, spec.inputs.isEmpty ? 18 : 14)
        .padding(.bottom, 16)
    }

    private func actionButton(_ action: FSAlertActionSpec) -> some View {
        Button {
            run(action)
        } label: {
            Text(action.title)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(color(for: action.style))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color(uiColor: .tertiarySystemFill).opacity(0.9),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(FSAlertButtonStyle())
    }

    private var dividerH: some View {
        Rectangle()
            .fill(Color(uiColor: .separator))
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
