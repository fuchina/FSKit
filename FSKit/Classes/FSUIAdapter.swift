//
//  FSUIAdapterCore.swift
//  FSKit
//
//  Translated from Objective-C to Swift
//

import UIKit

// MARK: - Convenience Accessors
public var UIScreenLong: CGFloat { FSUIAdapter.shared.screenBiggerValue }
public var UIScreenShort: CGFloat { FSUIAdapter.shared.screenSmallerValue }
public var UIScreenHeight: CGFloat { UIScreen.main.bounds.height }
public var UIScreenWidth: CGFloat { UIScreen.main.bounds.width }

// MARK: - FSUIAdapterModel
public class FSUIAdapterModel: NSObject {
    
    public let value0p5: CGFloat
    public let value1: CGFloat
    public let value2: CGFloat
    public let value3: CGFloat
    public let value4: CGFloat
    public let value5: CGFloat
    public let value6: CGFloat
    public let value7: CGFloat
    public let value7p5: CGFloat
    public let value8: CGFloat
    public let value9: CGFloat
    public let value10: CGFloat
    public let value11: CGFloat
    public let value12: CGFloat
    public let value13: CGFloat
    public let value14: CGFloat
    public let value15: CGFloat
    public let value16: CGFloat
    public let value17: CGFloat
    public let value18: CGFloat
    public let value19: CGFloat
    public let value20: CGFloat
    public let value22: CGFloat
    public let value25: CGFloat
    public let value26: CGFloat
    public let value30: CGFloat
    public let value36: CGFloat
    public let value38: CGFloat
    public let value40: CGFloat
    public let value45: CGFloat
    public let value46: CGFloat
    public let value47: CGFloat
    public let value50: CGFloat
    public let value55: CGFloat
    public let value60: CGFloat
    public let value65: CGFloat
    public let value70: CGFloat
    public let value75: CGFloat
    public let value80: CGFloat
    public let value85: CGFloat
    public let value90: CGFloat
    public let value95: CGFloat
    public let value100: CGFloat
    public let value105: CGFloat
    public let value110: CGFloat
    public let value120: CGFloat
    public let value125: CGFloat
    public let value130: CGFloat
    public let value135: CGFloat
    public let value140: CGFloat
    public let value145: CGFloat
    public let value150: CGFloat
    public let value160: CGFloat
    public let value165: CGFloat
    public let value170: CGFloat
    public let value180: CGFloat
    public let value190: CGFloat
    public let value200: CGFloat
    public let value210: CGFloat
    public let value230: CGFloat
    public let value250: CGFloat
    public let value260: CGFloat
    public let value270: CGFloat
    public let value280: CGFloat
    public let value290: CGFloat
    public let value300: CGFloat
    public let value310: CGFloat
    public let value320: CGFloat
    public let value330: CGFloat
    public let value340: CGFloat
    public let value350: CGFloat
    public let value375: CGFloat
    public let value400: CGFloat
    public let value500: CGFloat
    public let value650: CGFloat
    
    public init(ratio: CGFloat) {
        value0p5 = 0.5 * ratio
        value1 = 1 * ratio
        value2 = 2 * ratio
        value3 = 3 * ratio
        value4 = 4 * ratio
        value5 = 5 * ratio
        value6 = 6 * ratio
        value7 = 7 * ratio
        value7p5 = 7.5 * ratio
        value8 = 8 * ratio
        value9 = 9 * ratio
        value10 = ceil(10 * ratio)
        value11 = ceil(11 * ratio)
        value12 = ceil(12 * ratio)
        value13 = ceil(13 * ratio)
        value14 = ceil(14 * ratio)
        value15 = ceil(15 * ratio)
        value16 = ceil(16 * ratio)
        value17 = ceil(17 * ratio)
        value18 = ceil(18 * ratio)
        value19 = ceil(19 * ratio)
        value20 = ceil(20 * ratio)
        value22 = ceil(22 * ratio)
        value25 = ceil(25 * ratio)
        value26 = ceil(26 * ratio)
        value30 = ceil(30 * ratio)
        value36 = ceil(36 * ratio)
        value38 = ceil(38 * ratio)
        value40 = ceil(40 * ratio)
        value45 = ceil(45 * ratio)
        value46 = ceil(46 * ratio)
        value47 = ceil(47 * ratio)
        value50 = ceil(50 * ratio)
        value55 = ceil(55 * ratio)
        value60 = ceil(60 * ratio)
        value65 = ceil(65 * ratio)
        value70 = ceil(70 * ratio)
        value75 = ceil(75 * ratio)
        value80 = ceil(80 * ratio)
        value85 = ceil(85 * ratio)
        value90 = ceil(90 * ratio)
        value95 = ceil(95 * ratio)
        value100 = ceil(100 * ratio)
        value105 = ceil(105 * ratio)
        value110 = ceil(110 * ratio)
        value120 = ceil(120 * ratio)
        value125 = ceil(125 * ratio)
        value130 = ceil(130 * ratio)
        value135 = ceil(135 * ratio)
        value140 = ceil(140 * ratio)
        value145 = ceil(145 * ratio)
        value150 = ceil(150 * ratio)
        value160 = ceil(160 * ratio)
        value165 = ceil(165 * ratio)
        value170 = ceil(170 * ratio)
        value180 = ceil(180 * ratio)
        value190 = ceil(190 * ratio)
        value200 = ceil(200 * ratio)
        value210 = ceil(210 * ratio)
        value230 = ceil(230 * ratio)
        value250 = ceil(250 * ratio)
        value260 = ceil(260 * ratio)
        value270 = ceil(270 * ratio)
        value280 = ceil(280 * ratio)
        value290 = ceil(290 * ratio)
        value300 = ceil(300 * ratio)
        value310 = ceil(310 * ratio)
        value320 = ceil(320 * ratio)
        value330 = ceil(330 * ratio)
        value340 = ceil(340 * ratio)
        value350 = ceil(350 * ratio)
        value375 = ceil(375 * ratio)
        value400 = ceil(400 * ratio)
        value500 = ceil(500 * ratio)
        value650 = ceil(650 * ratio)
        super.init()
    }
}


// MARK: - FSUIAdapterManager
public class FSUIAdapter: NSObject {
    
    public static let shared = FSUIAdapter()
    
    public let isIPad: Bool
    public let isIPhone: Bool
    public let screenSmallerValue: CGFloat
    public let screenBiggerValue: CGFloat
    
    private let originRatioForIPhone: CGFloat
    private let originRatioForIPad: CGFloat
    
    public private(set) lazy var model: FSUIAdapterModel = modelForRatio(2.16)
    public private(set) lazy var model1p88: FSUIAdapterModel = modelForRatio(1.88)
    public private(set) lazy var model1p75: FSUIAdapterModel = modelForRatio(1.75)
    public private(set) lazy var model1p6: FSUIAdapterModel = modelForRatio(1.6)
    public private(set) lazy var model1p3: FSUIAdapterModel = modelForRatio(1.3)
    public private(set) lazy var model1p1: FSUIAdapterModel = modelForRatio(1.135)
    
    public var iPadValue: FSUIAdapterModel? {
        return isIPad ? model1p6 : nil
    }
    
    // Screen Height Ratios
    public private(set) var height05: CGFloat = 0
    public private(set) var height10: CGFloat = 0
    public private(set) var height15: CGFloat = 0
    public private(set) var height20: CGFloat = 0
    public private(set) var height25: CGFloat = 0
    public private(set) var height30: CGFloat = 0
    public private(set) var height35: CGFloat = 0
    public private(set) var height40: CGFloat = 0
    public private(set) var height45: CGFloat = 0
    public private(set) var height50: CGFloat = 0
    public private(set) var height55: CGFloat = 0
    public private(set) var height60: CGFloat = 0
    public private(set) var height65: CGFloat = 0
    public private(set) var height70: CGFloat = 0
    public private(set) var height75: CGFloat = 0
    public private(set) var height80: CGFloat = 0
    public private(set) var height85: CGFloat = 0
    public private(set) var height90: CGFloat = 0
    public private(set) var height95: CGFloat = 0
    
    // Screen Width Ratios
    public private(set) var width05: CGFloat = 0
    public private(set) var width10: CGFloat = 0
    public private(set) var width15: CGFloat = 0
    public private(set) var width20: CGFloat = 0
    public private(set) var width25: CGFloat = 0
    public private(set) var width30: CGFloat = 0
    public private(set) var width35: CGFloat = 0
    public private(set) var width40: CGFloat = 0
    public private(set) var width45: CGFloat = 0
    public private(set) var width50: CGFloat = 0
    public private(set) var width55: CGFloat = 0
    public private(set) var width60: CGFloat = 0
    public private(set) var width65: CGFloat = 0
    public private(set) var width70: CGFloat = 0
    public private(set) var width75: CGFloat = 0
    public private(set) var width80: CGFloat = 0
    public private(set) var width85: CGFloat = 0
    public private(set) var width90: CGFloat = 0
    public private(set) var width95: CGFloat = 0
    
    // Safe Area
    public var safeInsets: UIEdgeInsets = .zero {
        didSet {
            safeWidth = UIScreenWidth - safeInsets.left - safeInsets.right
            safeHeight = UIScreenHeight - safeInsets.top - safeInsets.bottom
        }
    }
    public private(set) var safeWidth: CGFloat = 0
    public private(set) var safeHeight: CGFloat = 0
    
    private override init() {
        isIPad = UIDevice.current.userInterfaceIdiom == .pad
        isIPhone = UIDevice.current.userInterfaceIdiom == .phone
        
        let screenBounds = UIScreen.main.bounds
        if screenBounds.width > screenBounds.height {
            screenSmallerValue = screenBounds.height
            screenBiggerValue = screenBounds.width
        } else {
            screenSmallerValue = screenBounds.width
            screenBiggerValue = screenBounds.height
        }
        
        originRatioForIPhone = screenSmallerValue / 375.0
        originRatioForIPad = screenSmallerValue / 810.0
        
        super.init()
        calculateScreenHeightRatios()
    }
    
    private func modelForRatio(_ iPadToIPhone: CGFloat) -> FSUIAdapterModel {
        var ratio = originRatioForIPhone
        if isIPad {
            ratio = originRatioForIPad * iPadToIPhone
        }
        return FSUIAdapterModel(ratio: ratio)
    }
    
    private func calculateScreenHeightRatios() {
        height05 = ceil(screenSmallerValue * 0.05)
        height10 = ceil(screenSmallerValue * 0.10)
        height15 = ceil(screenSmallerValue * 0.15)
        height20 = ceil(screenSmallerValue * 0.20)
        height25 = ceil(screenSmallerValue * 0.25)
        height30 = ceil(screenSmallerValue * 0.30)
        height35 = ceil(screenSmallerValue * 0.35)
        height40 = ceil(screenSmallerValue * 0.40)
        height45 = ceil(screenSmallerValue * 0.45)
        height50 = ceil(screenSmallerValue * 0.50)
        height55 = ceil(screenSmallerValue * 0.55)
        height60 = ceil(screenSmallerValue * 0.60)
        height65 = ceil(screenSmallerValue * 0.65)
        height70 = ceil(screenSmallerValue * 0.70)
        height75 = ceil(screenSmallerValue * 0.75)
        height80 = ceil(screenSmallerValue * 0.80)
        height85 = ceil(screenSmallerValue * 0.85)
        height90 = ceil(screenSmallerValue * 0.90)
        height95 = ceil(screenSmallerValue * 0.95)
        
        width05 = ceil(screenBiggerValue * 0.05)
        width10 = ceil(screenBiggerValue * 0.10)
        width15 = ceil(screenBiggerValue * 0.15)
        width20 = ceil(screenBiggerValue * 0.20)
        width25 = ceil(screenBiggerValue * 0.25)
        width30 = ceil(screenBiggerValue * 0.30)
        width35 = ceil(screenBiggerValue * 0.35)
        width40 = ceil(screenBiggerValue * 0.40)
        width45 = ceil(screenBiggerValue * 0.45)
        width50 = ceil(screenBiggerValue * 0.50)
        width55 = ceil(screenBiggerValue * 0.55)
        width60 = ceil(screenBiggerValue * 0.60)
        width65 = ceil(screenBiggerValue * 0.65)
        width70 = ceil(screenBiggerValue * 0.70)
        width75 = ceil(screenBiggerValue * 0.75)
        width80 = ceil(screenBiggerValue * 0.80)
        width85 = ceil(screenBiggerValue * 0.85)
        width90 = ceil(screenBiggerValue * 0.90)
        width95 = ceil(screenBiggerValue * 0.95)
    }
}

// MARK: - Helper Function
public func differentValueForIPad(_ iPad: CGFloat, _ iPhone: CGFloat) -> CGFloat {
    return FSUIAdapter.shared.isIPad ? iPad : iPhone
}

// MARK: - UIView Extension
public extension UIView {
    
    var fs_height: CGFloat {
        get { frame.size.height }
        set {
            var newFrame = frame
            newFrame.size.height = newValue
            frame = newFrame
        }
    }
    
    var fs_width: CGFloat {
        get { frame.size.width }
        set {
            var newFrame = frame
            newFrame.size.width = newValue
            frame = newFrame
        }
    }
    
    var fs_top: CGFloat {
        get { frame.origin.y }
        set {
            var newFrame = frame
            newFrame.origin.y = newValue
            frame = newFrame
        }
    }
    
    var fs_left: CGFloat {
        get { frame.origin.x }
        set {
            var newFrame = frame
            newFrame.origin.x = newValue
            frame = newFrame
        }
    }
    
    var fs_bottom: CGFloat {
        get { frame.origin.y + frame.size.height }
        set {
            var newFrame = frame
            newFrame.origin.y = newValue - frame.size.height
            frame = newFrame
        }
    }
    
    var fs_right: CGFloat {
        get { frame.origin.x + frame.size.width }
        set {
            let delta = newValue - (frame.origin.x + frame.size.width)
            var newFrame = frame
            newFrame.origin.x += delta
            frame = newFrame
        }
    }
    
    func fs_radius(radius: CGFloat, corner: UIRectCorner) {
        if #available(iOS 11.0, *) {
            layer.cornerRadius = radius
            layer.maskedCorners = CACornerMask(rawValue: corner.rawValue)
        } else {
            let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corner, cornerRadii: CGSize(width: radius, height: radius))
            let maskLayer = CAShapeLayer()
            maskLayer.frame = bounds
            maskLayer.path = path.cgPath
            layer.mask = maskLayer
        }
    }
    
    func fs_shadow(color: UIColor?, offset: CGSize, opacity: Float) {
        let shadowPath = UIBezierPath(rect: bounds)
        layer.masksToBounds = false
        if let color = color {
            layer.shadowColor = color.cgColor
        }
        layer.shadowOffset = offset
        layer.shadowOpacity = opacity
        layer.shadowRadius = layer.cornerRadius
        layer.shadowPath = shadowPath.cgPath
    }
    
    func fs_corner(leftTop: CGFloat, rightTop: CGFloat, bottomLeft: CGFloat, bottomRight: CGFloat, frame: CGRect) {
        let width = frame.size.width
        let height = frame.size.height
        
        let maskPath = UIBezierPath()
        maskPath.lineWidth = 1.0
        maskPath.lineCapStyle = .round
        maskPath.lineJoinStyle = .round
        
        maskPath.move(to: CGPoint(x: bottomRight, y: height))
        maskPath.addLine(to: CGPoint(x: width - bottomRight, y: height))
        maskPath.addQuadCurve(to: CGPoint(x: width, y: height - bottomRight), controlPoint: CGPoint(x: width, y: height))
        maskPath.addLine(to: CGPoint(x: width, y: rightTop))
        maskPath.addQuadCurve(to: CGPoint(x: width - rightTop, y: 0), controlPoint: CGPoint(x: width, y: 0))
        maskPath.addLine(to: CGPoint(x: leftTop, y: 0))
        maskPath.addQuadCurve(to: CGPoint(x: 0, y: leftTop), controlPoint: .zero)
        maskPath.addLine(to: CGPoint(x: 0, y: height - bottomLeft))
        maskPath.addQuadCurve(to: CGPoint(x: bottomLeft, y: height), controlPoint: CGPoint(x: 0, y: height))
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = frame
        maskLayer.path = maskPath.cgPath
        layer.mask = maskLayer
    }
    
    @discardableResult
    static func fs_gradient(view: UIView, frame: CGRect, startPoint: CGPoint, endPoint: CGPoint, colors: [Any], locations: [NSNumber]) -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = frame
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.colors = colors
        gradientLayer.locations = locations
        view.layer.insertSublayer(gradientLayer, at: 0)
        return gradientLayer
    }
}
