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
      @objc public convenience init(name: String) {
          self.init()
          let animation = LottieAnimation.named(name, bundle: Bundle.main, subdirectory: "json12")
           mAnimationView.animation = animation
          mAnimationView.frame = CGRect(x: 0,y: 0,width: 310.5,height: 672)
          mAnimationView.loopMode = .loop
           self.addSubview(mAnimationView)
           mAnimationView.play()
      }
}
