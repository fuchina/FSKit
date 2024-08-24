//
//  FSLottieView.swift
//  FSKit
//
//  Created by Dongdong Fu on 2024/8/24.
//

import Foundation
import Lottie

@objc
open class FSLottieView : UIView {
    @objc public var lotView = LottieAnimationView()
    
    ///名称--创建动画
    @objc public convenience init(frame: CGRect, name: String, bundle: String? = nil) {
        self.init(frame: frame)
        
        let bundle_obj = Bundle(path: bundle ?? "main") ?? Bundle.main
            
        lotView.frame = self.bounds
        lotView.loopMode = .loop
        self.addSubview(lotView)

        let animation = LottieAnimation.named(name, bundle: bundle_obj, subdirectory: "json12")
        lotView.animation = animation
        
        lotView.play()
      }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        lotView.frame = self.bounds
    }
}
