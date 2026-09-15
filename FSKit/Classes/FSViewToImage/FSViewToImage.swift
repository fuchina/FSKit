//
//  FSViewToImage.swift
//  FSViewToImage
//
//  Created by FudonFuchina on 2018/11/22.
//  Copyright © 2018年 fudongdong. All rights reserved.
//

import UIKit

public class FSViewToImage {
    
    /// 将 UIView 转换为 UIImage
    public static func image(for view: UIView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        view.layer.render(in: context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 屏幕截图
    /// - Note: iOS 13+ 使用私有 API 获取状态栏可能会被拒审，建议使用 screenShotWithoutStatusBar()
    public static func screenShot() -> UIImage? {
        // 注意：通过 KVC 获取 _statusBar 在 iOS 13+ 已不可用
        // 这里提供一个兼容方案
        if #available(iOS 13.0, *) {
            guard let windowScene = currentWindowScene else { return nil }
            
            let screenSize = UIScreen.main.bounds.size
            UIGraphicsBeginImageContextWithOptions(screenSize, false, 0)
            defer { UIGraphicsEndImageContext() }
            
            guard let context = UIGraphicsGetCurrentContext() else { return nil }
            
            for window in windowScene.windows {
                if window.screen == UIScreen.main {
                    context.saveGState()
                    context.translateBy(x: window.center.x, y: window.center.y)
                    context.concatenate(window.transform)
                    context.translateBy(
                        x: -window.bounds.size.width * window.layer.anchorPoint.x,
                        y: -window.bounds.size.height * window.layer.anchorPoint.y
                    )
                    window.layer.render(in: context)
                    context.restoreGState()
                }
            }
            
            return UIGraphicsGetImageFromCurrentImageContext()
        }
        
        return nil
    }
    
    /// 屏幕截图（不包含状态栏的私有 API 访问）
    public static func screenShotApple() -> UIImage? {
        if #available(iOS 13.0, *) {
            guard let windowScene = currentWindowScene else { return nil }
            
            let imageSize = UIScreen.main.bounds.size
            UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
            defer { UIGraphicsEndImageContext() }
            
            guard let context = UIGraphicsGetCurrentContext() else { return nil }
            
            for window in windowScene.windows {
                if window.screen == UIScreen.main {
                    context.saveGState()
                    context.translateBy(x: window.center.x, y: window.center.y)
                    context.concatenate(window.transform)
                    context.translateBy(
                        x: -window.bounds.size.width * window.layer.anchorPoint.x,
                        y: -window.bounds.size.height * window.layer.anchorPoint.y
                    )
                    window.layer.render(in: context)
                    context.restoreGState()
                }
            }
            
            return UIGraphicsGetImageFromCurrentImageContext()
        }
        
        return nil
    }
    
    // MARK: - Private
    
    @available(iOS 13.0, *)
    private static var currentWindowScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }
}
