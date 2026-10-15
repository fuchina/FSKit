//
//  FSHostingCleanup.swift
//  FSKit
//
//  2026-10-15 退役（全 SwiftUI 化收尾）：
//  原 `public protocol FSHostingCleanup`（声明 `hostingController` 属性，
//  在 `viewDidDisappear` 里调 `cleanupHostingIfMovingFromParent()` 拆除 UIHostingController，
//  断开 SwiftUI View 闭包对 self 的强引用）。
//
//  它是为「UIKit 壳页内嵌 UIHostingController」这种半迁移形态准备的；页面全部转成
//  Screen 之后不再有壳页，唯一曾实现它的 `FSMoneyController` 也在 2026-10-15 重写时移除。
// 全量 grep 确认已无任何实现者。
//
//  SwiftUI 等价物：`.debugDealloc("XxxScreen")` + `FSPageRoute` 持有页面
//  （pop 后自然释放），不再需要手动拆 hosting。
//

import Foundation
