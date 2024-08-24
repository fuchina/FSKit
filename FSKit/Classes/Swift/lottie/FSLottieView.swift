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
    @objc public var mAnimationView = LottieAnimationView()
    
    ///名称--创建动画
    @objc public convenience init(frame: CGRect, name: String) {
        self.init(frame: frame)
        
        let animation = LottieAnimation.named(name, bundle: Bundle.main, subdirectory: "json12")
        mAnimationView.animation = animation
        mAnimationView.frame = self.bounds
        mAnimationView.loopMode = .loop
        self.addSubview(mAnimationView)
        mAnimationView.play()
      }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        mAnimationView.frame = self.bounds
    }
}
