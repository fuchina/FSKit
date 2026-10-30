//
//  FuSoftCore.swift
//  FSKit
//
//  Translated from Objective-C to Swift
//

import UIKit

//public var WIDTHFC: CGFloat {
//    FSApp.shared.width
//}
//
//public var HEIGHTFC: CGFloat {
//    FSApp.shared.height
//}

// MARK: - Debug Log
//public func FSLog(_ format: String, file: String = #file, function: String = #function, line: Int = #line) {
//    #if DEBUG
//    print("\(function) - \(line)\n\(format)")
//    #endif
//}

// MARK: - System Helpers
//public func MININ<T: Comparable>(_ a: T, _ b: T) -> T {
//    return min(a, b)
//}

//public func IOSGE(_ version: Float) -> Bool {
//    return (UIDevice.current.systemVersion as NSString).floatValue >= version
//}

//public var isIPAD: Bool {
//    let isPad = UIDevice.current.userInterfaceIdiom == .pad
//    return isPad
//}
//
//public var isIPHONE: Bool {
//    let isPhone = UIDevice.current.userInterfaceIdiom == .phone
//    return isPhone
//}

//public func RGB16(_ rgbValue: Int) -> UIColor {
//    return UIColor(
//        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
//        green: CGFloat((rgbValue & 0xFF00) >> 8) / 255.0,
//        blue: CGFloat(rgbValue & 0xFF) / 255.0,
//        alpha: 1.0
//    )
//}

//public struct FSTag {
//    public static let view = 1000
//    public static let button = 1100
//    public static let tableView = 1200
//    public static let scrollView = 1300
//    public static let label = 1400
//    public static let imageView = 1500
//    public static let `switch` = 1600
//    public static let slider = 1700
//    public static let segment = 1800
//    public static let webView = 1900
//    public static let mapView = 2000
//    public static let textField = 2100
//    public static let textView = 2200
//    public static let progressView = 2300
//    public static let alert = 2400
//    public static let pickerView = 2500
//    public static let cell = 2900
//}

//// MARK: - WeakSelf Helper
//public func withWeakSelf<T: AnyObject>(_ object: T, _ closure: @escaping (T) -> Void) -> () -> Void {
//    return { [weak object] in
//        guard let object = object else { return }
//        closure(object)
//    }
//}
