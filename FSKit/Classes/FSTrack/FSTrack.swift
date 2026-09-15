//
//  FSTrack.swift
//  FSTrackSample
//
//  Created by fudongdong on 2018/11/30.
//  Copyright © 2018年 fudongdong. All rights reserved.
//

import Foundation
// import UMMobClick

/// 友盟统计封装类
public final class FSTrack {
    
    // MARK: - 友盟统计配置
    
    /// 配置友盟统计
    /// - Parameters:
    ///   - appKey: 友盟 App Key
    ///   - channelId: 渠道 ID
    ///   - crashReportEnabled: 是否开启崩溃上报
    ///   - appVersion: App 版本号
    ///   - puid: 用户唯一标识
    public static func configUMeng(
        appKey: String,
        channelId: String,
        crashReportEnabled: Bool,
        appVersion: String,
        puid: String
    ) {
        // Release 模式下才统计
        #if !DEBUG && !targetEnvironment(simulator)
        /*
        let config = UMAnalyticsConfig.sharedInstance()
        config?.appKey = appKey
        config?.channelId = channelId
        MobClick.start(withConfigure: config)
        
        MobClick.setCrashReportEnabled(crashReportEnabled)
        MobClick.setAppVersion(appVersion)
        MobClick.profileSignIn(withPUID: puid)
        */
        #endif
    }
    
    // MARK: - 事件统计
    
    /// 记录事件
    /// - Parameter event: 事件名称
    public static func event(_ event: String) {
        #if !DEBUG && !targetEnvironment(simulator)
        // MobClick.event(event)
        #endif
    }
    
    // MARK: - 页面统计
    
    /// 页面开始
    /// - Parameter page: 页面名称
    public static func pageStart(_ page: String) {
        #if !DEBUG && !targetEnvironment(simulator)
        // MobClick.beginLogPageView(page)
        #endif
    }
    
    /// 页面结束
    /// - Parameter page: 页面名称
    public static func pageEnd(_ page: String) {
        #if !DEBUG && !targetEnvironment(simulator)
        // MobClick.endLogPageView(page)
        #endif
    }
}
