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

import SwiftUI

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
    /// 点按钮时把当前文本回写（原 `UITextField` 语义，供调用方从 `textFields` 取值）
    public var commit: (String) -> Void

    public init(placeholder: String, keyboardType: UIKeyboardType = .default, commit: @escaping (String) -> Void) {
        self.placeholder = placeholder
        self.keyboardType = keyboardType
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

    public init(isAlert: Bool,
                title: String,
                message: String,
                actions: [FSAlertActionSpec],
                inputs: [FSAlertInputSpec] = []) {
        self.isAlert = isAlert
        self.title = title
        self.message = message
        self.actions = actions
        self.inputs = inputs
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

    private init() {}

    public func show(_ spec: FSAlertSpec) {
        let apply: @MainActor () -> Void = { [weak self] in
            guard let self else { return }
            self.inputTexts = spec.inputs.map { _ in "" }
            self.current = spec
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

/// 弹窗渲染器（由根视图挂载）。
///
/// alert 与 actionSheet 由同一个 `current` 驱动，按 `isAlert` 二选一渲染。
public struct FSAlertHost: View {

    @ObservedObject private var center = FSAlertCenter.shared

    public init() {}

    private var isPresented: Binding<Bool> {
        Binding(get: { center.current != nil },
                set: { if !$0 { center.dismiss() } })
    }

    public var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .alert(center.current?.title ?? "",
                   isPresented: Binding(get: { center.current?.isAlert == true },
                                        set: { if !$0 { center.dismiss() } }),
                   presenting: center.current) { spec in
                actions(for: spec)
            } message: { spec in
                if spec.message.isEmpty == false {
                    Text(spec.message)
                }
            }
            .confirmationDialog(center.current?.title ?? "",
                                isPresented: Binding(get: { center.current?.isAlert == false },
                                                     set: { if !$0 { center.dismiss() } }),
                                presenting: center.current) { spec in
                actions(for: spec)
            } message: { spec in
                if spec.message.isEmpty == false {
                    Text(spec.message)
                }
            }
    }

    /// 输入框 + 按钮（alert 的 actions builder 支持 ForEach）
    @ViewBuilder
    private func actions(for spec: FSAlertSpec) -> some View {
        ForEach(Array(spec.inputs.enumerated()), id: \.offset) { index, input in
            TextField(input.placeholder, text: Binding(
                get: { index < center.inputTexts.count ? center.inputTexts[index] : "" },
                set: { newValue in
                    if index < center.inputTexts.count { center.inputTexts[index] = newValue }
                }))
        }

        ForEach(spec.actions) { action in
            Button(action.title, role: role(for: action.style)) {
                // 先把用户输入回写到各自的 commit（原 textFields 语义）
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
