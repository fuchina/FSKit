//
//  FSApp.swift
//  FSApp
//
//  Created by FudonFuchina on 2019/12/1.
//

import UIKit

public class FSApp: NSObject {
    
    public static let shared = FSApp()
    
    public var width:  CGFloat = 0
    public var height: CGFloat = 0
    
    /// 屏幕方向，如：.portrait
    public var orientation: UIInterfaceOrientationMask = .portrait
    
    private override init() {
        super.init()
    }
}
