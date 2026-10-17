//
//  FSAlertCenter.swift
//  FSKit
//
//  2026-10-15 全 SwiftUI 化：
//  `FSUIKit.alert / alertInput / showAlertWithMessage` 原来是「构造 UIAlertController +
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

/// 一个弹窗按钮
public struct FSAlertActionSpec: Identifiable {

    public let id = UUID()
    public var title: String
    public var style: UIAlertAction.Style
    public var handler: (() -> Void)?

    public init(title: String, style: UIAlertAction.Style, handler: (() -> Void)?) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}

/// alert 里的一个输入框（原 `UIAlertController.addTextField`）
public struct FSAlertInputSpec: Identifiable {

    public let id = UUID()
    public var placeholder: String
    public var keyboardType: UIKeyboardType
    /// 初始文本（原 `UITextField.text`，改造时漏掉的预填，如记账弹窗的备注）
    public var text: String
    /// 点按钮时把当前文本回写（原 `UITextField` 语义，供调用方从 `textFields` 取值）
    public var commit: (String) -> Void

    public init(placeholder: String,
                keyboardType: UIKeyboardType = .default,
                text: String = "",
                commit: @escaping (String) -> Void) {
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.text = text
        self.commit = commit
    }
}

/// 一条弹窗（nil = 不显示）
///
/// Swift 6 语言模式：`spec` 会被送进 `@MainActor` 闭包，故声明 `@unchecked Sendable`
/// （纯数据载体；内含的 handler / commit 闭包由调用方在主线程执行）。
public struct FSAlertSpec: Identifiable, @unchecked Sendable {

    public let id = UUID()
    /// true = alert；false = actionSheet（iPad 上由上游强制转 alert）
    public var isAlert: Bool
    public var title: String
    public var message: String
    public var actions: [FSAlertActionSpec]
    /// 输入框（0 = 普通弹窗）
    public var inputs: [FSAlertInputSpec]
    /// 点遮罩是否关闭（原 `UIAlertController.addTapEvent` 的语义，默认不关）
    public var tapOutsideToDismiss: Bool

    public init(isAlert: Bool,
                title: String,
                message: String,
                actions: [FSAlertActionSpec],
                inputs: [FSAlertInputSpec] = [],
                tapOutsideToDismiss: Bool = false) {
        self.isAlert = isAlert
        self.title = title
        self.message = message
        self.actions = actions
        self.inputs = inputs
        self.tapOutsideToDismiss = tapOutsideToDismiss
    }
}

/// 全局弹窗中心。**可从任意线程调用**（内部自行切主线程）。
///
/// 不标 `@MainActor`（同 `FSToastCenter`）：`FSUIKit.alert` 是非隔离的 `static` 方法，
/// 343 处调用点未必都在主隔离域；标成 `@MainActor` 会让那些调用点编译报错。
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

    /// 当前弹窗的宿主容器（`UIAlertController` 数据容器）标识，供 `addTapEvent` 认领
    private var containerID: ObjectIdentifier?

    /// 点遮罩时调用方额外要做的动作（原 `addTapEvent` 的 clickDismiss 闭包）
    private var tapOutsideHandler: ((CGPoint) -> Void)?

    private init() {}

    /// - Parameter container: 本次弹窗的 `UIAlertController` 数据容器；
    ///   调用方随后在 `completion` 里对它调 `addTapEvent` 时，靠它认领「这是哪条弹窗」。
    public func show(_ spec: FSAlertSpec, container: AnyObject? = nil) {
        let apply: @MainActor () -> Void = { [weak self] in
            guard let self else { return }
            self.inputTexts = spec.inputs.map { $0.text }
            self.containerID = container.map { ObjectIdentifier($0) }
            self.tapOutsideHandler = nil
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
            self.tapOutsideHandler = nil
            self.containerID = nil
            self.current = nil
        }
        if Thread.isMainThread {
            MainActor.assumeIsolated { apply() }
        } else {
            DispatchQueue.main.async { MainActor.assumeIsolated { apply() } }
        }
    }

    /// `UIAlertController.addTapEvent` 的新落点：只对「当前正在显示的那条弹窗」生效。
    public func enableTapOutsideDismiss(for container: AnyObject,
                                       handler: ((CGPoint) -> Void)?) {
        let apply: @MainActor () -> Void = { [weak self] in
            guard let self,
                  let id = self.containerID,
                  id == ObjectIdentifier(container) else { return }
            self.tapOutsideHandler = handler
            self.current?.tapOutsideToDismiss = true
        }
        if Thread.isMainThread {
            MainActor.assumeIsolated { apply() }
        } else {
            DispatchQueue.main.async { MainActor.assumeIsolated { apply() } }
        }
    }

    /// 点遮罩：先关弹窗，再跑调用方回调（老代码里回调本身就是 dismiss，此时已是空操作）。
    /// 先关再回调，避免回调里又 show 一条新弹窗时被这里的 dismiss 顶掉。
    public func dismissByOutsideTap(at point: CGPoint) {
        let handler = tapOutsideHandler
        dismiss()
        handler?(point)
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
            if let spec = center.current, spec.isAlert {
                FSAlertDialog(spec: spec, center: center)
                    .transition(.opacity)
                    .zIndex(1)
            }

            // actionSheet 仍交给系统：它原生支持点外关闭，也自带 iPad popover 适配
            Color.clear
                .frame(width: 0, height: 0)
                .confirmationDialog(center.current?.title ?? "",
                                    isPresented: Binding(get: { center.current?.isAlert == false },
                                                         set: { if !$0 { center.dismiss() } }),
                                    presenting: center.current) { spec in
                    actionButtons(for: spec)
                } message: { spec in
                    if spec.message.isEmpty == false {
                        Text(spec.message)
                    }
                }
        }
        .animation(.easeOut(duration: 0.18), value: center.current?.id)
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

    private func role(for style: UIAlertAction.Style) -> ButtonRole? {
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
/// 刻意对齐 `UIAlertController`：面板宽 270、圆角 14、按钮高 44、分隔线 0.5pt、
/// 默认蓝字 / destructive 红字 / cancel 加粗，两个按钮横排、三个及以上竖排。
/// 与系统唯一的行为差异是「点遮罩可以关闭」—— 但只在调用方显式登记过 `addTapEvent` 时生效，
/// 其余弹窗点遮罩依旧什么都不发生（与原系统 alert 一致）。
private struct FSAlertDialog: View {

    let spec: FSAlertSpec
    @ObservedObject var center: FSAlertCenter

    /// 系统弹窗蓝（不受 App 全局 `.tint(.black)` 影响）
    private let tintColor = Color(uiColor: .systemBlue)

    var body: some View {
        ZStack {
            // 遮罩：系统 alert 的压暗程度
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .gesture(SpatialTapGesture().onEnded { value in
                    guard spec.tapOutsideToDismiss else { return }
                    center.dismissByOutsideTap(at: value.location)
                })

            panel
        }
    }

    // MARK: 面板

    private var panel: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                if spec.title.isEmpty == false {
                    Text(spec.title)
                        .font(.system(size: 17, weight: .semibold))
                        .multilineTextAlignment(.center)
                }

                if spec.message.isEmpty == false {
                    Text(spec.message)
                        .font(.system(size: 13))
                        .multilineTextAlignment(.center)
                }

                ForEach(Array(spec.inputs.enumerated()), id: \.offset) { index, input in
                    TextField(input.placeholder, text: binding(index))
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.center)
                        .keyboardType(input.keyboardType)
                        .font(.system(size: 14))
                        .padding(.horizontal, 8)
                        .frame(height: 30)
                        .background(Color(uiColor: .tertiarySystemFill),
                                    in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 18)

            buttons
        }
        .frame(width: 270)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: 按钮

    @ViewBuilder
    private var buttons: some View {
        if spec.actions.count == 2 {
            HStack(spacing: 0) {
                actionButton(spec.actions[0])
                dividerV
                actionButton(spec.actions[1])
            }
            .overlay(alignment: .top) { dividerH }
        } else {
            VStack(spacing: 0) {
                ForEach(Array(spec.actions.enumerated()), id: \.element.id) { index, action in
                    if index > 0 {
                        dividerH
                    }
                    actionButton(action)
                }
            }
        }
    }

    private func actionButton(_ action: FSAlertActionSpec) -> some View {
        Button {
            run(action)
        } label: {
            Text(action.title)
                .font(.system(size: 17, weight: action.style == .cancel ? .semibold : .regular))
                .foregroundColor(color(for: action.style))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(FSAlertButtonStyle())
    }

    private var dividerH: some View {
        Rectangle()
            .fill(Color(uiColor: .separator))
            .frame(height: 0.5)
    }

    private var dividerV: some View {
        Rectangle()
            .fill(Color(uiColor: .separator))
            .frame(width: 0.5)
            .frame(height: 44)
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

    private func color(for style: UIAlertAction.Style) -> Color {
        style == .destructive ? Color(uiColor: .systemRed) : tintColor
    }
}

/// 按下时轻微变淡（`.plain` 没有按压反馈，系统弹窗是有的）
private struct FSAlertButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.45 : 1.0)
    }
}
