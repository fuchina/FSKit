//
//  FSToastCenter.swift
//  FSKit
//

import SwiftUI

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

/// 全局 toast 中心：允许**多条同时存在**，每条独立计时、独立消失。
/// 旧版只保留一个槽位（`current`），后来的 toast 会顶掉前一条 —— 已废弃该行为。
public final class FSToastCenter: ObservableObject, @unchecked Sendable {

    public static let shared = FSToastCenter()

    /// 当前存活的全部 toast，按加入顺序排列（最旧的在前）
    @Published public private(set) var items: [FSToastMessage] = []

    /// 同时最多保留几条；超出时丢弃最旧的。
    /// 之所以要上限：debug 通知里有 `duration: 600` 的长驻 toast，不设上限会无限堆叠。
    public var maxVisible: Int = 6

    private var seq: Int = 0

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

    @MainActor
    private func showOnMain(_ text: String, duration: Double) {
        seq += 1
        let mine = seq

        var list = items
        list.append(FSToastMessage(id: mine, text: text, duration: duration))
        let limit = max(maxVisible, 1)
        if list.count > limit {
            list.removeFirst(list.count - limit)
        }

        withAnimation(.easeIn(duration: 0.1)) {
            items = list
        }

        // 每条 toast 自带计时器，只负责关掉自己；不会因为后来的 toast 被取消
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(max(duration, 0)))
            self.dismissOnMain(mine)
        }
    }

    @MainActor
    private func dismissOnMain(_ id: Int) {
        guard items.contains(where: { $0.id == id }) else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            items.removeAll { $0.id == id }
        }
    }

    @MainActor
    private func dismissAllOnMain() {
        guard !items.isEmpty else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            items.removeAll()
        }
    }
}

/// 浮层：把 `FSToastCenter.items` 竖直排列，多条并存时逐条往上让位
public struct FSToastOverlay: View {

    @ObservedObject private var center = FSToastCenter.shared

    private var maxWidth: CGFloat { WIDTHFC - 50 }

    public init() {}

    public var body: some View {
        VStack(spacing: 10) {
            ForEach(center.items) { msg in
                toastView(msg)
                    .transition(.opacity)
            }
        }
        .allowsHitTesting(false)
    }

    private func toastView(_ msg: FSToastMessage) -> some View {
        Text(msg.text)
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
