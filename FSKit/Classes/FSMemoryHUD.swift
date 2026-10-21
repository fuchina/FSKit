//
//  FSMemoryHUD.swift
//  FSKit
//
//  运行时内存浮层（2026-10-21）
//
//  - 显示当前 footprint（与 Xcode Debug Navigator 同一个数）、会话峰值、相对启动的增量
//  - 真机上额外显示系统允许本进程继续申请的额度（模拟器返回 0 时自动隐藏该行）
//  - 可拖动，位置存 UserDefaults；**开关状态不在这里持久化** —— 落库字段是
//    `AppConfiger.debugSwitch`（沿用原「Debug日」那一行），由 `FSJZAPP` 读库后推进来
//
//  开关入口：设置页「内存浮层」（改的是落库字段），或代码里 `FSMemoryHUDState.shared.enabled = true`
//  挂载点：AppRootScreen 的 overlay（`FSMemoryHUD()` 内部自己判断开关，关着时什么都不渲染）
//

import SwiftUI

// MARK: - 状态

/// 浮层的开关与位置。位置存 UserDefaults；开关的持久化交给上层（`AppConfiger.debugSwitch`），
/// 因为 FSKit 是零依赖库、不能 import FSJZKit。
@MainActor
public final class FSMemoryHUDState: ObservableObject {

    public static let shared = FSMemoryHUDState()

    private static let offsetXKey = "fs_memory_hud_offset_x"
    private static let offsetYKey = "fs_memory_hud_offset_y"

    /// 是否显示浮层。初值恒为 false，`FSJZAPP` 初始化时会按落库的 `debug_switch` 覆盖。
    @Published public var enabled: Bool = false

    /// 相对默认位置的偏移（拖动累积）。拖动结束时才落盘，避免每帧写 UserDefaults。
    @Published public var offset: CGSize

    private init() {
        let x = UserDefaults.standard.double(forKey: Self.offsetXKey)
        let y = UserDefaults.standard.double(forKey: Self.offsetYKey)
        offset = CGSize(width: x, height: y)
    }

    /// 拖动结束后调用
    public func saveOffset() {
        UserDefaults.standard.set(Double(offset.width), forKey: Self.offsetXKey)
        UserDefaults.standard.set(Double(offset.height), forKey: Self.offsetYKey)
    }

    /// 回到默认位置
    public func resetOffset() {
        offset = .zero
        saveOffset()
    }
}

// MARK: - 浮层

public struct FSMemoryHUD: View {

    @ObservedObject private var state = FSMemoryHUDState.shared

    /// 当前 footprint（MB）
    @State private var current: Double = 0
    /// 本次显示期间的峰值（MB）
    @State private var peak: Double = 0
    /// 显示时的基线，用于算增量
    @State private var base: Double = 0
    /// 本进程还能申请多少（MB），模拟器可能为 0
    @State private var available: Double = 0
    /// 拖动起点
    @State private var dragStart: CGSize?

    public init() {}

    public var body: some View {
        if state.enabled {
            hud
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                // 默认落在状态栏下方的左上角，避开导航栏标题与右下角的浮动按钮
                .padding(.leading, 12)
                .padding(.top, 96)
                .offset(state.offset)
                .task { await sample() }
                .gesture(drag)
                .allowsHitTesting(true)
        }
    }

    // MARK: UI

    private var hud: some View {
        VStack(alignment: .leading, spacing: 2) {
            line("内存", text: mb(current), color: currentColor)
            line("峰值", text: mb(peak), color: .white)
            line("增量", text: deltaText, color: deltaColor)
            if available > 0 {
                line("剩余", text: mb(available), color: .white.opacity(0.7))
            }
        }
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(red: 73.0 / 255, green: 80.0 / 255, blue: 86.0 / 255).opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .allowsHitTesting(false)
    }

    private func line(_ title: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .foregroundColor(.white.opacity(0.7))
            Spacer(minLength: 0)
            Text(text)
                .foregroundColor(color)
                .monospacedDigit()
        }
        .frame(width: 96, alignment: .leading)
    }

    // MARK: 采样

    private func sample() async {
        base = FSKit.memoryFootprint()
        current = base
        peak = base

        while Task.isCancelled == false {
            let value = FSKit.memoryFootprint()
            current = value
            if value > peak { peak = value }
            available = FSKit.availableMemoryForApp()

            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                break   // 取消：浮层已关闭或视图销毁
            }
        }
    }

    // MARK: 拖动

    private var drag: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                if dragStart == nil { dragStart = state.offset }
                guard let start = dragStart else { return }
                state.offset = CGSize(width: start.width + value.translation.width,
                                      height: start.height + value.translation.height)
            }
            .onEnded { _ in
                dragStart = nil
                state.saveOffset()
            }
    }

    // MARK: 格式化与配色

    private func mb(_ value: Double) -> String {
        String(format: "%.1fMB", value)
    }

    /// 相对基线（即浮层打开时的占用），不看绝对值，只看涨了多少
    private var delta: Double { current - base }

    private var deltaText: String {
        let d = delta
        if d >= 0 { return String(format: "+%.1fMB", d) }
        return String(format: "%.1fMB", d)
    }

    /// 增量配色：涨 30MB 以上偏红，8MB 以上偏黄
    private var deltaColor: Color {
        if delta >= 30 { return Color(red: 0.94, green: 0.58, blue: 0.58) }
        if delta >= 8 { return Color(red: 0.98, green: 0.78, blue: 0.46) }
        return .white
    }

    /// 绝对值配色：仅作粗略参考（不同机型基线差异很大）
    private var currentColor: Color {
        if current >= 900 { return Color(red: 0.94, green: 0.58, blue: 0.58) }
        if current >= 500 { return Color(red: 0.98, green: 0.78, blue: 0.46) }
        return .white
    }
}
