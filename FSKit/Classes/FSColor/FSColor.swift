//
//  FSColor.swift
//  FSAppPublic
//
//  Created by FudonFuchina on 2019/10/20.
//  Translated to Swift
//

import UIKit
import SwiftUI

/// 用于处理颜色
///
/// ★ 2026-10-24：`nonisolated` —— 全静态色值（`Color` 是 Sendable 的值类型），
/// 首页年度数据在后台执行器上算（`FSAccountDataModel.businessGlobal`），要读 `wechatGreen`。
public nonisolated struct FSColor {
        
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
    
    // MARK: - 基础色
    
    /// 红色
    public static let red = Color(red: 250 / 255.0, green: 49 / 255.0, blue: 105 / 255.0)
    
    /// 紫色（UIColor.purple #800080）
    public static let purple = Color(red: 0x80 / 255.0, green: 0, blue: 0x80 / 255.0)
    
    /// 黄色
    public static let yellow = Color(red: 253 / 255.0, green: 111 / 255.0, blue: 55 / 255.0)
    
    // MARK: - 文字颜色
    
    /// 深色文字
    public static let textDark = Color(red: 16 / 255.0, green: 16 / 255.0, blue: 16 / 255.0)
    
    /// 普通文字
    public static let textNormal = Color(red: 88 / 255.0, green: 88 / 255.0, blue: 88 / 255.0)
    
    /// 浅色文字
    public static let textLight = Color(red: 169 / 255.0, green: 169 / 255.0, blue: 169 / 255.0)
    
    // MARK: - 其他
    
    /// 页面背景颜色
    public static let backColor = Color(red: 0.95, green: 0.95, blue: 0.95)

}
