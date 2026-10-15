//
//  FSText.swift
//  FSKit
//
//  富文本拼装：以「段」为单位，Swift 原生 AttributedString 实现
//
//  设计要点：
//  1. 主入口是段数组 —— 调用方把文本切成若干段，每段自带 color / font，按顺序拼接；
//  2. 实现走 Foundation 的 AttributedString（Swift 值类型）逐段 append，
//     最后一次性桥接成 NSAttributedString，不再用 NSMutableAttributedString 逐条 addAttribute；
//  3. 颜色参数既能收 UIColor，也能收 SwiftUI 的 Color（见 FSTextColorConvertible）。
//

import UIKit
import SwiftUI

// MARK: - 颜色入参

/// 能被富文本接口接受的颜色来源。
///
/// 存在意义是让调用方不必手动转换：`FSColor` 里 `UIColor` 与 `Color` 混着定义，
/// 有了这层协议，两种都能直接往 `color:` 里塞。
public protocol FSTextColorConvertible {
    var fs_color: UIColor { get }
}

extension UIColor: FSTextColorConvertible {
    public var fs_color: UIColor { self }
}

extension Color: FSTextColorConvertible {
    public var fs_color: UIColor { UIColor(self) }
}

// MARK: - 段

/// 一段文本及其样式，多个段按数组顺序拼接成最终富文本。
///
/// ```swift
/// FSKit.attributed([
///     FSTextSegment("原价 ", color: FSColor.textLight),
///     FSTextSegment("¥88", color: FSColor.red, font: .boldSystemFont(ofSize: 16), strikethrough: true),
/// ])
/// ```
public struct FSTextSegment {

    public var text: String
    /// 文字颜色；nil 表示继承外层（UILabel / Text 自身）的颜色。
    public var color: UIColor?
    /// 字体；nil 表示继承外层字体。
    public var font: UIFont?
    /// 删除线
    public var strikethrough: Bool
    /// 下划线
    public var underline: Bool

    /// - Parameter color: 可传 `UIColor`，也可直接传 SwiftUI 的 `Color`。
    ///   注意：写颜色字面量（如 `.red`）时会因重载而无法推断，请写成 `UIColor.red` / `Color.red`。
    public init(_ text: String,
                color: (any FSTextColorConvertible)? = nil,
                font: UIFont? = nil,
                strikethrough: Bool = false,
                underline: Bool = false) {
        self.text = text
        self.color = color?.fs_color
        self.font = font
        self.strikethrough = strikethrough
        self.underline = underline
    }
}

// MARK: - 关键词规则

/// 在整段文本里把命中的关键词改成指定样式。
public struct FSTextRule {

    /// 关键词，按字面量匹配。
    public var keyword: String
    /// 命中部分的颜色；nil 表示沿用基样式。
    public var color: UIColor?
    /// 命中部分的字体；nil 表示沿用基样式。
    public var font: UIFont?
    /// 是否命中全部出现位置。`false` 时只改第一处（与旧接口行为一致）。
    public var allMatches: Bool

    public init(_ keyword: String,
                color: (any FSTextColorConvertible)? = nil,
                font: UIFont? = nil,
                allMatches: Bool = true) {
        self.keyword = keyword
        self.color = color?.fs_color
        self.font = font
        self.allMatches = allMatches
    }
}

// MARK: - 对外接口

public extension FSKit {

    // MARK: 段数组

    /// 按数组顺序拼接各段文本，逐段套用各自的 color / font / 删除线 / 下划线。
    static func attributed(_ segments: [FSTextSegment]) -> NSAttributedString {
        NSAttributedString(richString(segments))
    }

    /// 与 `attributed(_:)` 同源，直接产出 SwiftUI 的 `AttributedString`，可写作 `Text(FSKit.richString(...))`。
    static func richString(_ segments: [FSTextSegment]) -> AttributedString {
        var result = AttributedString()
        for segment in segments {
            result.append(richString(segment))
        }
        return result
    }

    // MARK: 关键词高亮

    /// 在整段文本中高亮命中的关键词；未命中的部分使用 `font` / `color`。
    /// - Parameter rules: 多个规则命中同一区间时，**数组中靠后的规则覆盖靠前的**。
    static func attributed(_ text: String,
                           font: UIFont? = nil,
                           color: (any FSTextColorConvertible)? = nil,
                           rules: [FSTextRule]) -> NSAttributedString {
        NSAttributedString(richString(text, font: font, color: color, rules: rules))
    }

    /// 关键词高亮的 SwiftUI 版本。
    static func richString(_ text: String,
                           font: UIFont? = nil,
                           color: (any FSTextColorConvertible)? = nil,
                           rules: [FSTextRule]) -> AttributedString {
        richString(runs(in: text, baseFont: font, baseColor: color?.fs_color, rules: rules))
    }

    // MARK: 便捷

    /// 删除线文本
    static func strikethrough(_ text: String,
                              font: UIFont? = nil,
                              color: (any FSTextColorConvertible)? = nil) -> NSAttributedString {
        attributed([FSTextSegment(text, color: color, font: font, strikethrough: true)])
    }

    /// 下划线文本
    static func underline(_ text: String,
                          font: UIFont? = nil,
                          color: (any FSTextColorConvertible)? = nil) -> NSAttributedString {
        attributed([FSTextSegment(text, color: color, font: font, underline: true)])
    }
}

// MARK: - 内部实现

private extension FSKit {

    /// 单段 → AttributedString。用显式的 attribute scope 下标，避免 UIKit / SwiftUI 两个 scope 的同名属性歧义。
    static func richString(_ segment: FSTextSegment) -> AttributedString {
        var piece = AttributedString(segment.text)
        if let color = segment.color {
            piece[AttributeScopes.UIKitAttributes.ForegroundColorAttribute.self] = color
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

        var hits: [(range: NSRange, color: UIColor?, font: UIFont?)] = []
        for rule in rules where !rule.keyword.isEmpty {
            var searchFrom = 0
            while searchFrom < length {
                let found = full.range(of: rule.keyword,
                                       options: [],
                                       range: NSRange(location: searchFrom, length: length - searchFrom))
                guard found.location != NSNotFound, found.length > 0 else { break }
                hits.append((found, rule.color, rule.font))
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
                         hits: [(range: NSRange, color: UIColor?, font: UIFont?)]) -> [FSTextSegment] {
        let length = full.length

        func clamp(_ range: NSRange) -> NSRange {
            let start = min(max(0, range.location), length)
            let end = min(max(start, range.location + range.length), length)
            return NSRange(location: start, length: end - start)
        }

        let validHits = hits.map { (clamp($0.range), $0.color, $0.font) }.filter { $0.0.length > 0 }

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
            var font = baseFont
            for hit in validHits where hit.0.location <= start && end <= hit.0.location + hit.0.length {
                if let hitColor = hit.1 { color = hitColor }
                if let hitFont = hit.2 { font = hitFont }
            }

            let piece = full.substring(with: NSRange(location: start, length: end - start))
            segments.append(FSTextSegment(piece, color: color, font: font))
        }
        return segments
    }
}

// MARK: - 兼容层（下游迁移完成后可整段删除）

public extension FSKit {

    @available(*, deprecated, message: "改用 attributed(_ segments:)，颜色与字体由 FSTextSegment 描述")
    static func attributedString(for sourceString: String,
                                 colorRanges: [NSRange],
                                 color: UIColor,
                                 textRanges: [NSRange],
                                 font: UIFont) -> NSAttributedString {
        let hits = colorRanges.map { (range: $0, color: Optional(color), font: Optional<UIFont>.none) }
            + textRanges.map { (range: $0, color: Optional<UIColor>.none, font: Optional(font)) }
        let segments = Self.segments(in: sourceString as NSString,
                                     baseFont: nil,
                                     baseColor: nil,
                                     hits: hits)
        return NSAttributedString(Self.richString(segments))
    }

    @available(*, deprecated, message: "改用 attributed(_:font:color:rules:)，关键词由 FSTextRule 描述")
    static func attributedString(for sourceString: String,
                                 colorStrings: [String],
                                 color: Color,
                                 fontStrings: [String]?,
                                 font: UIFont?) -> NSAttributedString {
        var rules = colorStrings.map { FSTextRule($0, color: color, allMatches: false) }
        if let fontStrings = fontStrings {
            let resolvedFont = font ?? UIFont.systemFont(ofSize: 14)
            rules += fontStrings.map { FSTextRule($0, font: resolvedFont, allMatches: false) }
        }
        return attributed(sourceString, font: nil, color: nil, rules: rules)
    }

    @available(*, deprecated, message: "已改为静态方法，请用 strikethrough(_:font:color:)")
    func middleLine(forLabel text: String) -> NSAttributedString {
        FSKit.strikethrough(text)
    }

    @available(*, deprecated, message: "已改为静态方法，请用 underline(_:font:color:)")
    func underLine(forLabel text: String) -> NSAttributedString {
        FSKit.underline(text)
    }
}
