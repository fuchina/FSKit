//
//  FSLeakProbe.swift
//  FSKit
//
//  对象级内存泄漏探针（2026-10-21 新增）
//
//  与 `FSDeallocModifier` 的区别：
//  - `debugDealloc` 的探针挂在 View 的 `@State` 上，只能感知「视图存储有没有被回收」；
//    页面里的 `@Observable` store / model 因自循环、闭包捕获、未取消的 Task 而泄漏时，
//    视图照常回收，探针照常 deinit ⇒ **测不出来**。
//  - 本文件把探针下沉到业务对象本身：`weak` 盒子只旁观、不增加引用计数。
//
//  用法（页面 body 末尾，与 `.debugDealloc` 并存）：
//  ```
//  .debugDealloc("FSValueScreen")
//  .debugWatch("FSValueScreen") { [store] }
//  ```
//  pop / dismiss 后由 `FSLeakDetector.startCheck(for:depth:)` 或
//  `.fsLeakCheckOnDismiss(page, isPresented)` 触发检查：
//  +3s 首检（转场动画、异步回调已结束）→ 仍存活则标记疑似
//  +13s 复检（系统框架缓存、URLSession 复用等延迟释放已过）→ 仍存活才报
//
//  判定边界（重要）：
//  iOS 没有公开 API 能回答「谁在强引用我」，所以本探针只能报「该释放没释放」，
//  引用链必须人工用 Xcode Memory Graph 看。二次复检就是为了避开「延迟释放」造成的误报。
//

import Foundation
import Observation

// MARK: - 页面 store 宿主盒子

/// 页面 store 的宿主盒子：**重对象不要直接放 `@State`**。
///
/// 2026-10-23 实证（`FSPMView`）：经 `router.push` 进来的页面，它自己的 `@State` location
/// 会被某份视图副本长期吊住 —— 一个**只被 State 引用**、没有任何业务代码碰过的空标记类，
/// 13 秒后仍与页面 store 一起存活；而挂在另一个 modifier 上的 `debugDealloc` location 却按时释放。
/// 结论：**这个 location 会被吊住，放进 location 的东西一概不释放**，改初始化时机、把闭包改 weak
/// 都没用（那两轮都试过，`init` 1 次 / `deinit` 0 次照旧）。
///
/// 所以 State 里只放这个几十字节的盒子，重对象挂在 `store` 上，页面离场后主动置空：
/// ```swift
/// @State private var host = FSStoreHost<FSValueStore>()
///
/// if let store = host.store { content(store) }        // body
/// .onAppear {
///     host.keepAlive()
///     guard host.store == nil else { return }
///     host.store = FSValueStore(...)
/// }
/// .onDisappear {
///     host.store?.saveIfNeeded()
///     host.closeSoon()                                // 0.6s 后才置 nil
/// }
/// ```
@Observable
public final class FSStoreHost<Store: AnyObject> {

    public var store: Store?

    /// 本页在导航栈中的深度（`onAppear` 时由页面写入）。不参与观察，避免无谓重绘。
    @ObservationIgnored public var depth: Int = 0

    /// 清理令牌：`keepAlive()` / `closeSoon()` 都 +1，迟到的清理发现令牌变了就跳过
    /// （防止「刚 pop 又立刻回来」时把刚建好的页面清成空白）
    @ObservationIgnored private var closeToken = 0

    public init() {}

    /// 页面离场：等转场走完再放开重对象（默认 0.6s，pop 动画约 0.35s）。
    /// 只改类实例、不动 SwiftUI state ⇒ 不会触发 pop 期间那次空白重绘。
    public func closeSoon(after delay: TimeInterval = 0.6) {
        closeToken += 1
        let token = closeToken
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.closeToken == token else { return }
            self.store = nil
        }
    }

    /// 页面出现（含被上层页盖住后又回来）：撤销尚未执行的清理，并记下本页栈深度
    public func keepAlive(depth: Int? = nil) {
        closeToken += 1
        if let depth { self.depth = depth }
    }

    /// 页面离场：**只有真的被 pop 掉才放开重对象**。
    ///
    /// 自己 push 了子页时 `router.path` 反而更深，这时必须保留 store，
    /// 否则从子页返回后表单输入、筛选条件、展开状态会被重置。
    public func closeIfPopped(pathCount: Int) {
        guard pathCount < depth else { return }
        closeSoon()
    }
}

// MARK: - 弱引用盒子

/// 只用 `weak` 旁观对象，不改变引用计数。对象释放后 `obj` 自动变 nil。
final class FSWeakBox {

    weak var obj: AnyObject?

    /// 登记时的真实类型名（对象释放后仍能用于报告）
    let typeName: String

    init(_ obj: AnyObject) {
        self.obj = obj
        self.typeName = String(describing: type(of: obj))
    }

    var isAlive: Bool { obj != nil }
}

// MARK: - 对象级探针

/// 登记需要观察的业务对象，在页面退出后检查它们是否真的被释放。
public enum FSLeakProbe {

    /// key = "页面名#栈深度"。
    /// 带深度是为了区分「同名页面嵌套 push」：只用页面名会互相覆盖，导致误报或漏报。
    private static var boxes: [String: [FSWeakBox]] = [:]

    private static var pending: [String: DispatchWorkItem] = [:]

    /// 首检延时。转场动画约 0.35s，一般异步回调节点也在这个量级内。
    private static let firstDelay: TimeInterval = 3.0

    /// 复检延时。留给系统框架缓存、URLSession 连接复用、图片解码等延迟释放。
    private static let secondDelay: TimeInterval = 10.0

    /// 统一的 key 生成规则，`FSLeakDetector` 也用它。
    public static func key(page: String, depth: Int) -> String {
        "\(page)#\(depth)"
    }

    /// 页面 `onAppear` 时登记业务对象（store / model / manager）。
    ///
    /// 同一页被重新 push、或从子页 pop 回来再次 onAppear 时，会覆盖同一个 key：
    /// 必须先取消上一轮尚未跑完的检查，否则 13 秒窗口内会被「新实例」的存活状态顶替，
    /// 产生「明明没漏却报泄漏」的误报（pop 后立刻再进同一页就会踩到）。
    public static func watch<T: AnyObject>(_ objects: [T], page: String, depth: Int) {
        guard objects.isEmpty == false else { return }

        let k = key(page: page, depth: depth)
        pending[k]?.cancel()
        pending.removeValue(forKey: k)
        boxes[k] = objects.map { FSWeakBox($0) }
    }

    /// 页面退出（pop / dismiss）时启动检查。
    ///
    /// - Parameters:
    ///   - page: 页面名
    ///   - depth: 该页在导航栈中的深度（从 1 开始）。sheet / fullScreenCover 传 0，
    ///            精确匹配不到时回退为「按页面名前缀匹配」，兼容模态页拿到的是宿主栈深度。
    public static func check(page: String, depth: Int) {
        for k in matchKeys(page: page, depth: depth) {
            scheduleFirst(key: k, page: page)
        }
    }

    // MARK: 内部

    private static func matchKeys(page: String, depth: Int) -> [String] {
        let exact = key(page: page, depth: depth)
        if boxes[exact] != nil { return [exact] }

        // 模态页：登记时读到的是宿主的栈深度，退出时没有深度信息 ⇒ 按页面名兜底
        let prefix = "\(page)#"
        return boxes.keys.filter { $0.hasPrefix(prefix) }
    }

    private static func scheduleFirst(key k: String, page: String) {
        pending[k]?.cancel()

        let item = DispatchWorkItem { [k, page] in
            // 本 block 由 `main.asyncAfter` 派发，必然在主线程执行
            MainActor.assumeIsolated {
                firstCheck(key: k, page: page)
            }
        }
        pending[k] = item
        DispatchQueue.main.asyncAfter(deadline: .now() + firstDelay, execute: item)
    }

    private static func firstCheck(key k: String, page: String) {
        guard let list = boxes[k] else { return }

        // 全部已释放：正常，静默通过（绝大多数页面走这条）
        if list.contains(where: { $0.isAlive }) == false {
            boxes.removeValue(forKey: k)
            pending.removeValue(forKey: k)
            return
        }

        // 仍有存活：可能是延迟释放，先不报，进入复检
        pending[k]?.cancel()

        let item = DispatchWorkItem { [k, page] in
            MainActor.assumeIsolated {
                secondCheck(key: k, page: page)
            }
        }
        pending[k] = item
        DispatchQueue.main.asyncAfter(deadline: .now() + secondDelay, execute: item)
    }

    private static func secondCheck(key k: String, page: String) {
        let alive = (boxes[k] ?? []).filter { $0.isAlive }

        boxes.removeValue(forKey: k)
        pending.removeValue(forKey: k)

        guard alive.isEmpty == false else { return }

        let types = Set(alive.map(\.typeName)).sorted().joined(separator: "、")
        let delay = Int(firstDelay + secondDelay)
        // 附上当前 footprint：单个页面的泄漏通常只有几百 KB，但若已到几十 MB 量级，
        // 说明是同一条引用链上吊住了一整片对象（store 之间是父子持有关系，会级联）。
        report("疑似内存泄漏：\(page) 的 \(alive.count) 个对象在 \(delay) 秒后仍未释放（\(types)），当前占用 \(FSKit.memoryFootprintText())")
    }

    private static func report(_ msg: String) {
        print(msg)
        NotificationCenter.default.post(
            name: NSNotification.Name(FS_BE_LEAK_NOTIFICATION),
            object: msg
        )
    }
}
