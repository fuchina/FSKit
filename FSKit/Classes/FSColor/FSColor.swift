//
//  FSColor.swift
//  FSAppPublic
//
//  Created by FudonFuchina on 2019/10/20.
//  Translated to Swift
//

import UIKit
import SwiftUI

public nonisolated struct FSColor {
    
    /// app color
    public static let APPCOLOR = Color(red: 18 / 255.0, green: 152 / 255.0, blue: 233 / 255.0)
        
    /// 微信绿
    public static let wechatGreen = Color(red: 0x20 / 255.0, green: 0xbf / 255.0, blue: 0x66 / 255.0)
    
    /// 美团黄
    public static let meituanYellow = Color(red: 1, green: 195 / 255.0, blue: 0)
    
    /// Apple News 红
    public static let appleNewsRed = Color(red: 250 / 255.0, green: 80 / 255.0, blue: 100 / 255.0)
    
    /// 支付宝蓝
    public static let alipayBlue = Color(red: 18 / 255.0, green: 152 / 255.0, blue: 233 / 255.0)
    
    /// 微信朋友圈蓝
    public static let wechatFriendsBlue = Color(red: 0x58 / 255.0, green: 0x6c / 255.0, blue: 0x93 / 255.0)
    
    /// 微信朋友圈蓝（带透明度）
    public static let wechatFriendsBlueAlpha = Color(red: 0x58 / 255.0, green: 0x6c / 255.0, blue: 0x93 / 255.0)
    
    /// iOS 系统蓝
    public static let iosSystemBlue = Color(red: 0, green: 0x7A / 255.0, blue: 0xFF / 255.0)

    /// App Store 按钮背景色（淡蓝色）
    public static let appStoreButtonBackground = Color(red: 0xf0 / 255.0, green: 0xf0 / 255.0, blue: 0xf7 / 255.0)
    
    /// 红色
    public static let red = Color(red: 250 / 255.0, green: 49 / 255.0, blue: 105 / 255.0)
    
    /// 紫色（UIColor.purple #800080）
    public static let purple = Color(red: 0x80 / 255.0, green: 0, blue: 0x80 / 255.0)
    
    /// 黄色
    public static let yellow = Color(red: 253 / 255.0, green: 111 / 255.0, blue: 55 / 255.0)
    
    /// 灰色
    public static let gray = Color(red: 0x80 / 255.0, green: 0x80 / 255.0, blue: 0x80 / 255.0)
    
    /// 轻灰色 —— 复刻 `UIColor.lightGray`（灰度 2/3 = #AAAAAA，白底对比度 2.32:1）
    ///
    /// ★ 2026-10-31：改回 #AAAAAA。10-30 13:51 的 9bfe3d7 曾把它改成 #D3D3D3，
    ///   注释写的是「复刻 UIColor.lightGray」，但 #D3D3D3 是 CSS/网页的 lightgray，
    ///   iOS 的 lightGray 是灰度 2/3。那次误改让全 App 的浅灰小字（资产页分隔符、
    ///   「有」标记、仓位、禁用按钮等）对比度从 2.32:1 掉到 1.50:1，白底上 10pt 糊成一片。
    ///   要更淡的灰请另起常量，不要动这里。
    public static let lightGray = Color(red: 0xaa / 255.0, green: 0xaa / 255.0, blue: 0xaa / 255.0)
        
    /// 深色文字
    public static let textDark = Color(red: 16 / 255.0, green: 16 / 255.0, blue: 16 / 255.0)
    
    /// 普通文字
    public static let textNormal = Color(red: 88 / 255.0, green: 88 / 255.0, blue: 88 / 255.0)
    
    /// 浅色文字
    public static let textLight = Color(red: 169 / 255.0, green: 169 / 255.0, blue: 169 / 255.0)
        
    /// 页面背景颜色
    public static let backColor = Color(red: 0.95, green: 0.95, blue: 0.95)


    /// 封面 / 表头渐变终点色（米棕）
    public static let coverBrown = Color(red: 0xb2 / 255.0, green: 0x96 / 255.0, blue: 0x7e / 255.0)

    // MARK: - 系统语义色
    //
    // 与 `UIColor` 同名同值（`Color(uiColor:)` 包一层），视觉零变化。
    // 存在意义：SwiftUI 里不再出现 `Color(UIColor.xxx)` 这种两层包装。
    // ★ 与上面的品牌色区分：`red` / `yellow` 是自定义色板（#FA3169 / #FD6F37），
    //   系统色一律带 `system` 前缀，避免色值被悄悄换掉。

    public static let label = Color(uiColor: .label)
    public static let secondaryLabel = Color(uiColor: .secondaryLabel)
    public static let tertiaryLabel = Color(uiColor: .tertiaryLabel)
    public static let placeholderText = Color(uiColor: .placeholderText)

    public static let separator = Color(uiColor: .separator)
    public static let darkText = Color(uiColor: .darkText)
    public static let darkGray = Color(uiColor: .darkGray)

    public static let systemBackground = Color(uiColor: .systemBackground)
    public static let secondarySystemBackground = Color(uiColor: .secondarySystemBackground)
    public static let systemGroupedBackground = Color(uiColor: .systemGroupedBackground)

    public static let systemGray3 = Color(uiColor: .systemGray3)
    public static let systemGray4 = Color(uiColor: .systemGray4)
    public static let systemGray5 = Color(uiColor: .systemGray5)
    public static let systemGray6 = Color(uiColor: .systemGray6)

    public static let tintColor = Color(uiColor: .tintColor)

    public static let systemRed = Color(uiColor: .systemRed)
    public static let systemGreen = Color(uiColor: .systemGreen)
    public static let systemBlue = Color(uiColor: .systemBlue)
    public static let systemOrange = Color(uiColor: .systemOrange)
    public static let systemYellow = Color(uiColor: .systemYellow)

    public static let black = Color.black
    public static let white = Color.white
    public static let clear = Color.clear

    /// 表头 / 封面渐变：上→下，0.25 处纯蓝、0.75 处米棕（`alipayBlue` → `coverBrown`）
    ///
    /// 原本在 5 处各写一遍（旧版 `configGradientLayer` / `createTableHeaderView` 的复制品）：
    /// 记账首页封面、年度账单、账单详情、预期表头、贷款结果页表头。白字压在这层上。
    /// ★ 用计算属性而非 `static let`：`FSColor` 是 `nonisolated struct`，存储型静态属性在
    ///   Swift 6 下要求 Sendable，`LinearGradient` 是否满足不该在这里赌；这层重建成本可忽略。
    public static var headerGradient: LinearGradient {
        LinearGradient(stops: [
            .init(color: alipayBlue, location: 0.25),
            .init(color: coverBrown, location: 0.75)
        ], startPoint: .top, endPoint: .bottom)
    }

}
