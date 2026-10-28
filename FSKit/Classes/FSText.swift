//
//  FSText.swift
//  FSKit
//
//  富文本拼装：以「段」为单位，Swift 原生 AttributedString 实现
//
//  设计要点：
//  1. 对外一律产出 Foundation 的 `AttributedString`（值类型 / Sendable / 写时复制），
//     需要喂 UIKit 时在**边界**显式写 `.fs_ns`，业务代码不再直接造 NSAttributedString；
//  2. 属性 scope 只在本文件里选（UIKit scope 显式下标）。业务代码不得直接读写 AttributedString 属性，
//     将来若要整体切 SwiftUI scope，只改本文件；
//  3. 禁止自定义 `NSAttributedString.Key` —— 过桥时静默丢失；要自定义语义请新建 AttributedStringKey 类型；
//  4. 颜色参数既能收 UIColor，也能收 SwiftUI 的 Color（见 FSTextColorConvertible）。
//

import UIKit
import SwiftUI

// MARK: - 颜色入参

/// 能被富文本接口接受的颜色来源。
///
/// 存在意义是让调用方不必手动转换：`FSColor` 里 `UIColor` 与 `Color` 混着定义，
/// 有了这层协议，两种都能直接往 `color:` 里塞。
///
/// ★ 2026-10-24：`nonisolated` —— 纯取值转换，无状态；后台执行器（首页年度数据的
/// `@concurrent` 计算）里要 `FSColor.wechatGreen.fs_color`。
public nonisolated protocol FSTextColorConvertible {
    var fs_color: UIColor { get }
}

extension UIColor: FSTextColorConvertible {
    public nonisolated var fs_color: UIColor { self }
}

extension Color: FSTextColorConvertible {
    public nonisolated var fs_color: UIColor { UIColor(self) }
}

// MARK: - UIKit 边界桥接

public extension AttributedString {

    /// 仅在 UIKit 边界使用（`UILabel.attributedText` / `UITextView` / `NSTextStorage`）。
    /// 出现它的地方就是「还没 SwiftUI 化」的待办点。
    var fs_ns: NSAttributedString { NSAttributedString(self) }
}

public extension Optional where Wrapped == AttributedString {

    var fs_ns: NSAttributedString {
        switch self {
        case .some(let value): return NSAttributedString(value)
        case .none: return NSAttributedString(string: "")
        }
    }
}

// MARK: - 段

/// 一段文本及其样式，多个段按数组顺序拼接成最终富文本。
///
/// ```swift
/// FSKit.attr([
///     FSTextSegment("原价 ", color: FSColor.textLight),
///     FSTextSegment("¥88", color: FSColor.red, font: .boldSystemFont(ofSize: 16), strikethrough: true),
/// ])
/// ```
public struct FSTextSegment {

    public var text: String
    /// 文字颜色；nil 表示继承外层（UILabel / Text 自身）的颜色。
    public var color: UIColor?
    /// 底色；nil 表示不设底色。
    public var background: UIColor?
    /// 字体；nil 表示继承外层字体。
    public var font: UIFont?
    /// 删除线
    public var strikethrough: Bool
    /// 下划线
    public var underline: Bool
    /// 逃生口：段结构装不下的属性（kern / paragraphStyle / baselineOffset / attachment 等）
    /// 直接塞进 AttributeContainer，注意必须是 UIKit scope 的 key。
    public var extra: AttributeContainer?

    /// - Parameter color: 可传 `UIColor`，也可直接传 SwiftUI 的 `Color`。
    ///   注意：写颜色字面量（如 `.red`）时会因重载而无法推断，请写成 `UIColor.red` / `Color.red`。
    public init(_ text: String,
                color: (any FSTextColorConvertible)? = nil,
                background: (any FSTextColorConvertible)? = nil,
                font: UIFont? = nil,
                strikethrough: Bool = false,
                underline: Bool = false,
                extra: AttributeContainer? = nil) {
        self.text = text
        self.color = color?.fs_color
        self.background = background?.fs_color
        self.font = font
        self.strikethrough = strikethrough
        self.underline = underline
        self.extra = extra
    }
}

// MARK: - 关键词规则

/// 在整段文本里把命中的关键词改成指定样式。
public struct FSTextRule {

    /// 关键词，按字面量匹配。
    public var keyword: String
    /// 命中部分的颜色；nil 表示沿用基样式。
    public var color: UIColor?
    /// 命中部分的底色；nil 表示不设底色。
    public var background: UIColor?
    /// 命中部分的字体；nil 表示沿用基样式。
    public var font: UIFont?
    /// 是否命中全部出现位置。`false` 时只改第一处（与旧接口行为一致）。
    public var allMatches: Bool

    public init(_ keyword: String,
                color: (any FSTextColorConvertible)? = nil,
                font: UIFont? = nil,
                background: (any FSTextColorConvertible)? = nil,
                allMatches: Bool = true) {
        self.keyword = keyword
        self.color = color?.fs_color
        self.background = background?.fs_color
        self.font = font
        self.allMatches = allMatches
    }
}

// MARK: - 对外接口（AttributedString 版）

public extension FSKit {

    // MARK: 单段

    /// 单段富文本。这是绝大多数场景该用的入口 —— 给一段字上色 / 换字体 / 加删除线。
    ///
    /// `color` 传 `nil` 表示不加颜色（继承外层）；完全没有任何属性时等价 `AttributedString(text)`。
    static func attr(_ text: String,
                     color: (any FSTextColorConvertible)? = nil,
                     font: UIFont? = nil,
                     strikethrough: Bool = false,
                     underline: Bool = false) -> AttributedString {
        build(FSTextSegment(text,
                            color: color,
                            font: font,
                            strikethrough: strikethrough,
                            underline: underline))
    }

    /// 涨跌着色：`up == true` 红、否则绿（A 股 / 港股口径，唯一出处，别在业务里各写一份三目）。
    static func attr(_ text: String, up: Bool, font: UIFont? = nil) -> AttributedString {
        attr(text, color: up ? FSColor.red : FSColor.wechatGreen, font: font)
    }

    // MARK: 段数组

    /// 按数组顺序拼接各段文本，逐段套用各自的 color / font / 删除线 / 下划线。
    static func attr(_ segments: [FSTextSegment]) -> AttributedString {
        var result = AttributedString()
        for segment in segments {
            result.append(build(segment))
        }
        return result
    }

    // MARK: 关键词高亮
    //
    // ★ 2026-10-28 删除 `keywordRules(colorStrings:color:fontStrings:font:)`。
    //   它把「标签 + 值」这种**已知结构**也当成关键词搜索来做，只要值里出现相同数字/文字
    //   就被一起命中（典型症状：`60  2460.43` 里值中的「60」被缩成小字），而且命中位置不受控
    //   （标签串若在值里更早出现，样式就打到值上了）。
    //   现在只保留两种写法：
    //     1. 已知结构（标签+值 / 比例+金额）→ `FSKit.attr([FSTextSegment(…), …])` 分段；
    //     2. 真·在自由文本里找词（搜索高亮 / 长文案里标重点）→
    //        `FSKit.attr(text, rules: [FSTextRule(word, color:, font:, allMatches:)])`。

    /// 在整段文本中高亮命中的关键词；未命中的部分使用 `font` / `color`。
    /// - Parameter rules: 多个规则命中同一区间时，**数组中靠后的规则覆盖靠前的**。
    static func attr(_ text: String,
                     font: UIFont? = nil,
                     color: (any FSTextColorConvertible)? = nil,
                     rules: [FSTextRule]) -> AttributedString {
        attr(runs(in: text, baseFont: font, baseColor: color?.fs_color, rules: rules))
    }

    // MARK: 便捷

    /// 删除线文本
    static func strikethrough(_ text: String,
                              font: UIFont? = nil,
                              color: (any FSTextColorConvertible)? = nil) -> AttributedString {
        attr([FSTextSegment(text, color: color, font: font, strikethrough: true)])
    }

    /// 下划线文本
    static func underline(_ text: String,
                          font: UIFont? = nil,
                          color: (any FSTextColorConvertible)? = nil) -> AttributedString {
        attr([FSTextSegment(text, color: color, font: font, underline: true)])
    }
}

// MARK: - 内部实现

private extension FSKit {

    /// 单段 → AttributedString。用显式的 attribute scope 下标，避免 UIKit / SwiftUI 两个 scope 的同名属性歧义。
    static func build(_ segment: FSTextSegment) -> AttributedString {
        var piece = AttributedString(segment.text)
        if let color = segment.color {
            piece[AttributeScopes.UIKitAttributes.ForegroundColorAttribute.self] = color
        }
        if let background = segment.background {
            piece[AttributeScopes.UIKitAttributes.BackgroundColorAttribute.self] = background
        }
        if let font = segment.font {
            piece[AttributeScopes.UIKitAttributes.FontAttribute.self] = font
        }
        if segment.strikethrough {
            piece[AttributeScopes.UIKitAttributes.StrikethroughStyleAttribute.self] = .single
        }
        if segment.underline {
            piece[AttributeScopes.UIKitAttributes.UnderlineStyleAttribute.self] = .single
        }
        if let extra = segment.extra {
            piece.mergeAttributes(extra)
        }
        return piece
    }

    /// 关键词 → 命中区间。
    /// 注意这里是**循环推进**地找，`NSString.range(of:)` 单次调用只返回第一处。
    static func runs(in text: String,
                     baseFont: UIFont?,
                     baseColor: UIColor?,
                     rules: [FSTextRule]) -> [FSTextSegment] {
        let full = text as NSString
        let length = full.length
        guard length > 0 else { return [] }

        var hits: [(range: NSRange, color: UIColor?, background: UIColor?, font: UIFont?)] = []
        for rule in rules where !rule.keyword.isEmpty {
            var searchFrom = 0
            while searchFrom < length {
                let found = full.range(of: rule.keyword,
                                       options: [],
                                       range: NSRange(location: searchFrom, length: length - searchFrom))
                guard found.location != NSNotFound, found.length > 0 else { break }
                hits.append((found, rule.color, rule.background, rule.font))
                guard rule.allMatches else { break }
                searchFrom = found.location + found.length
            }
        }
        return segments(in: full, baseFont: baseFont, baseColor: baseColor, hits: hits)
    }

    /// 把文本按所有命中区间的端点切开，逐片决定最终样式。
    /// 顺带把越界的 NSRange 夹到合法范围 —— 越界 range 交给 `addAttribute` 会抛 NSRangeException，直接崩。
    static func segments(in full: NSString,
                         baseFont: UIFont?,
                         baseColor: UIColor?,
                         hits: [(range: NSRange, color: UIColor?, background: UIColor?, font: UIFont?)]) -> [FSTextSegment] {
        let length = full.length

        func clamp(_ range: NSRange) -> NSRange {
            let start = min(max(0, range.location), length)
            let end = min(max(start, range.location + range.length), length)
            return NSRange(location: start, length: end - start)
        }

        let validHits = hits.map { (clamp($0.range), $0.color, $0.background, $0.font) }.filter { $0.0.length > 0 }

        var boundaries: Set<Int> = [0, length]
        for hit in validHits {
            boundaries.insert(hit.0.location)
            boundaries.insert(hit.0.location + hit.0.length)
        }
        let points = boundaries.sorted()

        var segments: [FSTextSegment] = []
        for index in 0 ..< max(0, points.count - 1) {
            let start = points[index]
            let end = points[index + 1]
            guard end > start else { continue }

            var color = baseColor
            var background: UIColor? = nil
            var font = baseFont
            for hit in validHits where hit.0.location <= start && end <= hit.0.location + hit.0.length {
                if let hitColor = hit.1 { color = hitColor }
                if let hitBackground = hit.2 { background = hitBackground }
                if let hitFont = hit.3 { font = hitFont }
            }

            let piece = full.substring(with: NSRange(location: start, length: end - start))
            segments.append(FSTextSegment(piece, color: color, background: background, font: font))
        }
        return segments
    }
}
