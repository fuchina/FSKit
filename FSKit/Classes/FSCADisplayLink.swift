//
//  FSCADisplayLink.swift
//  FSKit
//
//  Created by Dongdong Fu on 2026/10/11.

//  用法：
//      private var link: FSCADisplayLink?
//
//      link = FSCADisplayLink { [weak self] link in
//          self?.step(link.duration)
//      }
//      link?.add(to: .main, forMode: .common)
//
//      link?.invalidate()        // ⚠️ 不加到 RunLoop 不上报错，但不清掉会一直空转
//

import UIKit

/// 为什么是包装（组合）而不是继承：
/// CADisplayLink 唯一能配置 target 的入口 `init(target:selector:)` 在 Swift 里是
/// **convenience** 初始化器（由 `+displayLinkWithTarget:selector:` 导入），
/// 子类的 designated init 里写 `super.init(target:selector:)` 直接编译不过：
/// "must call a designated initializer of the superclass 'CADisplayLink'"。
/// 而 `target` / `selector` 都是只读、又没有 `addTarget`，所以子类没有别的路子
/// 给自己挂回调 —— 继承这条路走不通。
///
/// 为什么 target 用独立代理对象而不是 self：
/// CADisplayLink 会持有 target 直到 `invalidate()`（头文件原话：invalidate
/// "releases the 'target' object"），以 self 当 target 就是持有环。
/// 这里代理只**弱引用**回本对象，代理自身由 displayLink 持有，
/// 一旦 `invalidate()`，代理与闭包一起释放，环被断开。
open class FSCADisplayLink {

    public typealias Handler = (FSCADisplayLink) -> Void

    /// 每帧回调。可随时替换，下一帧生效。
    public var onTick: Handler?

    /// 底层 display link。本类没转发的属性 / 方法直接从这里取（如 frameInterval）。
    public let link: CADisplayLink

    public init(handler: Handler? = nil) {
        let proxy = _FSDisplayLinkProxy()
        let link = CADisplayLink(target: proxy, selector: #selector(_FSDisplayLinkProxy.tick(_:)))
        self.link = link
        self.onTick = handler
        proxy.owner = self   // 存储属性全部初始化完之后才能碰 self
    }

    deinit {
        // 只把引用丢掉的话，displayLink 会被 RunLoop 一直持有、每帧空转；
        // 这里显式停掉，顺带把代理与闭包一起释放。
        link.invalidate()
    }

    // MARK: - 常用接口转发

    /// 暂停 / 恢复，初始为 false。
    public var isPaused: Bool {
        get { link.isPaused }
        set { link.isPaused = newValue }
    }

    /// 期望回调帧率区间（iOS 15+）。
    public var preferredFrameRateRange: CAFrameRateRange {
        get { link.preferredFrameRateRange }
        set { link.preferredFrameRateRange = newValue }
    }

    /// 最近一帧的时间戳。
    public var timestamp: CFTimeInterval { link.timestamp }

    /// 最近一帧的帧时长。
    public var duration: CFTimeInterval { link.duration }

    /// 建议渲染对齐的下一个时间戳。
    public var targetTimestamp: CFTimeInterval { link.targetTimestamp }

    /// 加入 RunLoop 开始运行（通常 `.main` + `.common`）。
    public func add(to runloop: RunLoop, forMode mode: RunLoop.Mode) {
        link.add(to: runloop, forMode: mode)
    }

    /// 停止回调并释放 target，之后不再触发。
    public func invalidate() {
        link.remove(from: .current, forMode: .common)
        link.invalidate()
    }
}

/// displayLink 真正的 target：弱引用回 FSCADisplayLink，再把事件转给 onTick。
///
private final class _FSDisplayLinkProxy: NSObject {

    weak var owner: FSCADisplayLink?

    @objc func tick(_ sender: CADisplayLink) {
        guard let owner else { return }
        owner.onTick?(owner)
    }
}
