//
//  FSCellFade.swift
//  FSKit
//
//  共享的「高亮淡出」动画：抽出供 HighlightRow（点击）与 FSPageReturnRow（跳转返回）共用，
//  曲线 / 阻尼一致；各 row 仅以 response（时长，秒）传入自身的 fadeDuration。
//  抽出来后两处淡出不再分叉，调一处即全局生效。
//

import SwiftUI

/// 高亮淡出动画（spring）。
/// - response：淡出时长（秒），由各调用方传入自身 fadeDuration。
/// - damping：近临界阻尼 0.96，尾部干净收住、无拖影 / 回弹。
/// - blendDuration：0，去掉起步时旧 / 新曲线交叉混合造成的残影。
public func FSCellFadeAnimation(response: Double = 0.6, damping: Double = 0.96) -> Animation {
    .spring(response: response, dampingFraction: damping, blendDuration: 0)
}
