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
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        lotView.frame = self.bounds
    }
    
    ///名称--创建动画
    @objc public convenience init(frame: CGRect, name: String, bundle: String? = nil, subdirectory: String? = nil) {
        self.init(frame: frame)
        
        let bundle_obj = Bundle(path: bundle ?? "main") ?? Bundle.main
            
        lotView.frame = self.bounds
        self.addSubview(lotView)

        let animation = LottieAnimation.named(name, bundle: bundle_obj, subdirectory: subdirectory)
        lotView.animation = animation
      }
    
    @objc public func loop_mode(loop: Bool) {
        if loop == true {
            lotView.loopMode = LottieLoopMode.loop
        }
    }
    
    @objc public func play() {
        lotView.play()
    }
    
    @objc public func play(completion: LottieCompletionBlock? = nil) {
        lotView.play { completed in
            if (completion != nil) {
                completion!(completed)
            }
        }
    }
    
    @objc public func play(fromFrame: CGFloat, toFrame: CGFloat, completion: LottieCompletionBlock? = nil) {
        
            let from_start = Double(fromFrame) / Double(lotView.animation?.framerate ?? 0)
            let to_frame = Double(toFrame) / Double(lotView.animation?.framerate ?? 0)

            lotView.play(fromFrame: from_start, toFrame: to_frame) { completed in
                if (completion != nil) {
                    completion!(completed)
                }
            }
        }
    
    @objc public func play(fromProgress: CGFloat, toProgress: CGFloat, completion: LottieCompletionBlock? = nil) {
        lotView.play(fromProgress: fromProgress, toProgress: toProgress) { completed in
            if (completion != nil) {
                completion!(completed)
            }
        }
    }
}
