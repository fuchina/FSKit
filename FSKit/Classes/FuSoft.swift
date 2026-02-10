//
//  FuSoftCore.swift
//  FSKit
//
//  Translated from Objective-C to Swift
//

import UIKit

public let WIDTHFC: CGFloat = UIScreen.main.bounds.width
public let HEIGHTFC: CGFloat = UIScreen.main.bounds.height

// MARK: - Colors
public let FSAPPCOLOR = UIColor(red: 18/255.0, green: 152/255.0, blue: 233/255.0, alpha: 1)

// MARK: - Debug Log
public func FSLog(_ format: String, file: String = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
    print("\(function) - \(line)\n\(format)")
    #endif
}

// MARK: - System Helpers
public func MININ<T: Comparable>(_ a: T, _ b: T) -> T {
    return min(a, b)
}

public func IOSGE(_ version: Float) -> Bool {
    return (UIDevice.current.systemVersion as NSString).floatValue >= version
}

public var isIPAD: Bool {
    let isPad = UIDevice.current.userInterfaceIdiom == .pad
    return isPad
}

public var isIPHONE: Bool {
    let isPhone = UIDevice.current.userInterfaceIdiom == .phone
    return isPhone
}

// MARK: - Color Helpers
public func RGBCOLOR(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1.0) -> UIColor {
    return UIColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
}

public func RGB16(_ rgbValue: Int) -> UIColor {
    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0xFF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0xFF) / 255.0,
        alpha: 1.0
    )
}

// MARK: - Font Helpers
public func FONTFC(_ size: CGFloat) -> UIFont {
    return UIFont.systemFont(ofSize: size)
}

public func FONTBOLD(_ size: CGFloat) -> UIFont {
    return UIFont(name: "Helvetica-Bold", size: size) ?? UIFont.boldSystemFont(ofSize: size)
}

public func FONTOBLIQUE(_ size: CGFloat) -> UIFont {
    return UIFont(name: "Helvetica-BoldOblique", size: size) ?? UIFont.systemFont(ofSize: size)
}

public func FONTLIQUE(_ size: CGFloat) -> UIFont {
    return UIFont(name: "Helvetica-Oblique", size: size) ?? UIFont.italicSystemFont(ofSize: size)
}

// MARK: - Localization
public func FSLocalString(_ key: String) -> String {
    return NSLocalizedString(key, comment: "")
}

// MARK: - String Format
public func FSSTRING(_ format: String, _ args: CVarArg...) -> String {
    return String(format: format, arguments: args)
}

// MARK: - FSBool (Tri-state Boolean)
public enum FSBool: Int {
    case undefined = -1  // NSNotFound equivalent
    case no = 0
    case yes = 1
}

// MARK: - Tag Constants
public struct FSTag {
    public static let view = 1000
    public static let button = 1100
    public static let tableView = 1200
    public static let scrollView = 1300
    public static let label = 1400
    public static let imageView = 1500
    public static let `switch` = 1600
    public static let slider = 1700
    public static let segment = 1800
    public static let webView = 1900
    public static let mapView = 2000
    public static let textField = 2100
    public static let textView = 2200
    public static let progressView = 2300
    public static let alert = 2400
    public static let pickerView = 2500
    public static let cell = 2900
}

// MARK: - WeakSelf Helper
public func withWeakSelf<T: AnyObject>(_ object: T, _ closure: @escaping (T) -> Void) -> () -> Void {
    return { [weak object] in
        guard let object = object else { return }
        closure(object)
    }
}
