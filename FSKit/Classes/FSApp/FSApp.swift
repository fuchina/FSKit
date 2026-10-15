//
//  FSApp.swift
//  FSApp
//
//  Created by FudonFuchina on 2019/12/1.
//

import UIKit

public class FSApp: NSObject {
    
    // Swift 6 语言模式：存放屏幕宽高/方向，供全项目读取。
    // 标 @MainActor 会让调用点报错，故用 nonisolated(unsafe) 保持原语义。
    public nonisolated(unsafe) static let shared = FSApp()
    
    public var width:  CGFloat = 0
    public var height: CGFloat = 0
    
    /// 屏幕方向，如：.portrait
    public var orientation: UIInterfaceOrientationMask = .portrait
    
    private override init() {
        super.init()
    }
}
