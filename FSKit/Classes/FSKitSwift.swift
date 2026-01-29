//
//  FSKitSwift.swift
//  FSKit
//
//  Created by pwrd on 2026/1/26.
//

import Foundation

open class FSKitSwift {
    
    public static func showByTenThousand(rest: Float, money: Bool) -> String {
        
        var _rest_show = ""
        if rest < 100000 {
            if money {
                _rest_show = self.bankStyleDataThree(data: rest) ?? "0"
            } else {
                _rest_show = String(rest)
            }
        } else if rest < 100000000 {
            _rest_show = String(format: ".2f万", rest / 10000.0)
        } else if rest < 10000000000 {
            _rest_show = String(format: ".2f亿", rest / 100000000.0)
        } else {
            _rest_show = String(format: ".2f亿", rest / 100000000.0)
        }
        
        return _rest_show
    }
    
    static func bankStyleDataThree(data: Float) -> String? {
        
        let numberFormatter = self.numberFormatter
    
        let number = NSNumber(value: data)
        let formattedNumberString = numberFormatter.string(from: number)
        
        return formattedNumberString
    }
        
    // 类属性，懒加载
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.positiveFormat = "###,##0.00;" // 100,000.00
        return formatter
    }()
    
    public static func currentWindowScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes
        for sc in scenes {
            if sc.activationState == .foregroundActive {
                return sc as? UIWindowScene
            }
        }
        
        if scenes.count > 0 {
            return scenes.first as? UIWindowScene
        }
        
        return nil
    }
    
    public static func fitScrollViewOperate(scrollView: UIScrollView, navigationController: UINavigationController) {
        
        let gestureArray = navigationController.view.gestureRecognizers
        if gestureArray == nil {
            return
        }
        
        for gr in gestureArray! {
            if gr is UIScreenEdgePanGestureRecognizer {
                scrollView.panGestureRecognizer.require(toFail: gr)
            }
        }
    }    
}
