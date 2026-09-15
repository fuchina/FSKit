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
    
    /// 屏幕截图（渲染 windowScene 内全部可见 window）
    public static func screenShot() -> UIImage? {
        if #available(iOS 13.0, *) {
            guard let windowScene = currentWindowScene else { return nil }
            
            let s = FSKit.currentWindowScene()?.screen ?? UIScreen()

            let screenSize = s.bounds.size
            UIGraphicsBeginImageContextWithOptions(screenSize, false, 0)
            defer { UIGraphicsEndImageContext() }
            
            guard let context = UIGraphicsGetCurrentContext() else { return nil }
            
            for window in windowScene.windows {
                if window.screen == s {
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
