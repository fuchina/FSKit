//
//  FSEntity.swift
//  FSKit
//
//  Created by Dongdong Fu on 2026/1/25.
//

import Foundation

// MARK: - 字段声明
//
// 一条字段映射 = **属性（KeyPath）+ 解析器**，配对由编译器校验。
//
// 与旧的 `FSEntity.map("k") { (obj: T, v: Double) in obj.k = FSSafe.double(v) }` 相比：
// - 没有 `(FSEntity, Any) -> Void` 这种把 `Self` 擦除成基类的签名 ⇒ 不存在 `as? T` 回转型；
// - 表写成 `static let`，**进程内只构建一次**（旧实现每次 `keyMapper()` 都要重建字典 + 每字段一个闭包）；
// - `\.freq`（Int）配不上 `FSSafe.double`，写错直接编译失败。
//
// `inout Model` 让同一份字段表对 class 与 struct 都成立（类经由引用生效，结构体就地写入）。

/// ★ 2026-10-24：`nonisolated` —— 只构造闭包、不执行任何写入，`nonisolated` 类的 `fieldMap`
/// （如 `FSAppConfigModel`、`FSAccountDataModel`）在非主隔离上下文里要引用它。
public nonisolated func fsField<Model, T>(_ keyPath: WritableKeyPath<Model, T>,
                              _ parse: @escaping (Any) -> T) -> (inout Model, Any) -> Void {
    { model, raw in
        model[keyPath: keyPath] = parse(raw)
    }
}

// 标准解析器：字段类型由 KeyPath 决定，声明处不写类型标注
public nonisolated func fsField<Model>(_ keyPath: WritableKeyPath<Model, Int>) -> (inout Model, Any) -> Void {
    fsField(keyPath) { FSSafe.int($0) }
}

public nonisolated func fsField<Model>(_ keyPath: WritableKeyPath<Model, Double>) -> (inout Model, Any) -> Void {
    fsField(keyPath) { FSSafe.double($0) }
}

public nonisolated func fsField<Model>(_ keyPath: WritableKeyPath<Model, String>) -> (inout Model, Any) -> Void {
    fsField(keyPath) { FSSafe.string($0) }
}

public nonisolated func fsField<Model>(_ keyPath: WritableKeyPath<Model, Bool>) -> (inout Model, Any) -> Void {
    fsField(keyPath) { FSSafe.bool($0) }
}

// MARK: - FSEntity
//
// 【2026-10-23 现代化改造：从基类改为协议】
//
// 旧形态是 `open class FSEntity: NSObject` + 每个子类 override
// `keyMapper() -> [String: (FSEntity, Any) -> Void]`。那个返回类型把 `Self` 擦除成基类，
// 父类要 `merging` 子类字段就只能用这个签名，**类型安全与类继承不可兼得**：
// 子类想写 `KeyPath<Self, T>` 必然被迫 `as? Self` 转回来。
// 改成协议后每个类型自己声明全部字段（含 `aid`），`merging` 一并消失；
// 协议对 class / struct 一视同仁，后续 struct 化不必再改一次架构。
//
// 【为什么是 `applyFields(to:from:)` 而不是 `static var fieldMap` 要求】
// `Self` 在协议要求里只允许出现在**纯参数**位置：非 final 类无法满足
// `[String: (inout Self, Any) -> Void]` 这种「泛型实参里的 Self」（不变量位置），
// 而本工程有多个可被继承的模型（FSWeaponModel / FSMoneyModel / FSABBaseModel …）。
// 于是字段表留作各类型自己的 `private static let`，协议只暴露一个传值参数的方法。
//
// 【`AnyObject` 约束是迁移期产物】
// 现在 `applyFields(to:)` 传值 + 表里 `inout` ⇒ 类语义正确、结构体不可用。
// 等模型改 struct 时，这里换成 `applyFields(to: inout Self, from:)`，
// 字段表**一行都不用改**（表本来就是 `inout` 的）。
/// ★ 2026-10-24：`nonisolated` —— 让 `FSEntity` 的默认实现（`fill`/`tom`/`toms`）可以从后台执行器调用。
/// 为什么必须动协议：`toms(from:)` 里要 `Self.init()` + `Self.applyFields`，若协议继承 Pod 默认的主隔离，
/// 整个方法就是 @MainActor 的，后台查库建模用不了。
/// 已验证：**主隔离类型满足 nonisolated 协议要求是合法的**（编译器生成 nonisolated witness），
/// 所以全库 58 个 `: FSEntity` 实现一个都不用改；只有确实要在后台用的那几个类型自己标 `nonisolated`。
public nonisolated protocol FSEntity: AnyObject, Equatable {

    init()

    /// 把一行原始值写进模型。实现方持有自己的字段表。
    static func applyFields(to model: Self, from row: [String: Any])

    func beforeSetProperties()
    func afterSetProperties()
}

/// ★ 2026-10-24：extension 也必须 `nonisolated` —— 否则 `beforeSetProperties` / `afterSetProperties`
/// 的**默认实现**是主隔离的，`nonisolated` 类型（如 `FSAppConfigModel`）一旦采用就被判
/// `#ConformanceIsolation: conformance crosses into main actor-isolated code`。
public nonisolated extension FSEntity {

    /// 身份相等。旧基类经 `NSObject` 白送的就是这个语义，改协议后必须显式补上：
    /// 全库有 5 处 `[Model].firstIndex(of:)` / `[Model].contains(_:)` 依赖它。
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs === rhs
    }

    func beforeSetProperties() {}
    func afterSetProperties() {}

    /// 单行填充
    func fill(from row: [String: Any]) {
        beforeSetProperties()
        Self.applyFields(to: self, from: row)
        afterSetProperties()
    }

    /// 单行建模
    static func tom(from row: [String: Any]) -> Self {
        let model = Self.init()
        model.fill(from: row)
        return model
    }

    /// 批量建模（`[String: Any]` 行）
    static func toms(from rows: [[String: Any]]) -> [Self] {
        toms(from: rows, before: nil, after: nil)
    }

    /// 批量建模（带前后钩子）
    static func toms(from rows: [[String: Any]],
                     before: ((Self) -> Void)?,
                     after: ((Self) -> Void)?) -> [Self] {
        if rows.isEmpty {
            return []
        }

        return rows.map { row in
            let model = Self.init()

            model.beforeSetProperties()
            before?(model)
            Self.applyFields(to: model, from: row)
            model.afterSetProperties()
            after?(model)

            return model
        }
    }

    /// 批量建模（`[String: String]` 行）：后台取行、主线程建模时可省掉一次装箱
    static func toms(from rows: [[String: String]]) -> [Self] {
        if rows.isEmpty {
            return []
        }

        return rows.map { row in
            let model = Self.init()
            model.fill(from: row)
            return model
        }
    }
}
