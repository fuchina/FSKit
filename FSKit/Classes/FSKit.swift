//
//  FSKitCore.swift
//  FSKit
//
//  Translated from Objective-C to Swift
//

import UIKit
import CommonCrypto

// MARK: - Constants
/// 一年的秒数
public let FSKitYearSeconds: CGFloat = 31556926.08

/// 支持小数点后5位，支持汇率（4位），必须是整数
public let FSFiveDecimalPlaces: Int = 100000
public let FSDoubleFiveDecimalPlaces: Double = 100000.0

// MARK: - FSKit
public class FSKit: NSObject {
    
    // MARK: - UserDefaults
    public static func userDefaultsSetObject(_ object: Any?, forKey key: String) {
        guard let object = object, isValidateString(key) else { return }
        let defaults = UserDefaults.standard
        defaults.set(object, forKey: key)
        defaults.synchronize()
    }
    
    public static func userDefaultsObject(forKey key: String) -> Any? {
        guard isValidateString(key) else { return nil }
        return UserDefaults.standard.object(forKey: key)
    }
    
    public static func clearUserDefaults() {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys {
            defaults.removeObject(forKey: key)
        }
    }
    
    // MARK: - JSON
    public static func object(fromJsonString jsonString: String?) -> Any? {
        guard let jsonString = jsonString, !jsonString.isEmpty else { return nil }
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
    }
    
    public static func jsonString(_ object: Any) -> String? {
        guard JSONSerialization.isValidJSONObject(object) else { return nil }
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Navigation
    public static func popToController(_ className: String, navigationController: UINavigationController?, animated: Bool) -> Bool {
        guard let nav = navigationController else { return false }
        for controller in nav.viewControllers {
            if NSStringFromClass(type(of: controller)).contains(className) {
                nav.popToViewController(controller, animated: animated)
                return true
            }
        }
        return false
    }
    
    public static func pushToViewController(withClass className: String, navigationController: UINavigationController?, param: [String: Any]? = nil, configBlock: ((UIViewController) -> Void)? = nil) {
        guard let controller = controllerWithClass(className, param: param, configBlock: configBlock) else { return }
        navigationController?.pushViewController(controller, animated: true)
    }
    
    public static func controllerWithClass(_ className: String, param: [String: Any]? = nil, configBlock: ((UIViewController) -> Void)? = nil) -> UIViewController? {
        guard let controllerClass = NSClassFromString(className) as? UIViewController.Type else { return nil }
        let viewController = controllerClass.init()
        
        if let param = param {
            for (key, value) in param {
                viewController.setValue(value, forKey: key)
            }
        }
        
        configBlock?(viewController)
        return viewController
    }

    
    // MARK: - Pasteboard
    public static func copyToPasteboard(_ string: String?) {
        guard let string = string else { return }
        UIPasteboard.general.string = string
    }
    
    // MARK: - Screen Lock
    public static func letScreenLock(_ lock: Bool) {
        UIApplication.shared.isIdleTimerDisabled = !lock
    }
    
    // MARK: - App Store
    public static func gotoAppCenterPage(withAppId appID: String) {
        let urlString = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=\(appID)"
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    // MARK: - Validation
    public static func isValidateEmail(_ email: String) -> Bool {
        guard email.contains("@"), email.contains(".") else { return false }
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }
    
    public static func isChinese(_ string: String) -> Bool {
        let regex = "^[\\u4E00-\\u9FA5\\uF900-\\uFA2D]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: string)
    }
    
    public static func isValidateUserPasswd(_ str: String) -> Bool {
        let regex = "^[a-zA-Z0-9]{6,16}$"
        guard let regularExpression = try? NSRegularExpression(pattern: regex, options: .caseInsensitive) else { return false }
        return regularExpression.numberOfMatches(in: str, options: .reportProgress, range: NSRange(location: 0, length: str.count)) > 0
    }
    
    public static func isChar(_ str: String) -> Bool {
        let regex = "^[a-zA-Z]*$"
        guard let regularExpression = try? NSRegularExpression(pattern: regex, options: .caseInsensitive) else { return false }
        return regularExpression.numberOfMatches(in: str, options: .reportProgress, range: NSRange(location: 0, length: str.count)) > 0
    }
    
    public static func isNumber(_ str: String) -> Bool {
        let regex = "^[0-9]*$"
        guard let regularExpression = try? NSRegularExpression(pattern: regex, options: .caseInsensitive) else { return false }
        return regularExpression.numberOfMatches(in: str, options: .reportProgress, range: NSRange(location: 0, length: str.count)) > 0
    }
    
    public static func isString(_ aString: String, containString bString: String) -> Bool {
        return aString.contains(bString)
    }
    
    public static func isStringContainsStringAndNumber(_ sourceString: String) -> Bool {
        guard !sourceString.isEmpty else { return false }
        var containsNumber = false
        var containsChar = false
        for char in sourceString {
            if char.isNumber {
                containsNumber = true
            } else {
                containsChar = true
            }
        }
        return containsChar && containsNumber
    }
    
    public static func isURLString(_ sourceString: String) -> Bool {
        let regex = "((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: sourceString)
    }
    
    public static func isHaveChinese(in string: String) -> Bool {
        for scalar in string.unicodeScalars {
            if scalar.value > 0x4e00 && scalar.value < 0x9fff {
                return true
            }
        }
        return false
    }
    
    public static func isAllNum(_ string: String) -> Bool {
        return string.allSatisfy { $0.isNumber }
    }
    
    public static func isPureInt(_ string: String?) -> Bool {
        guard let string = string, !string.isEmpty else { return false }
        let scanner = Scanner(string: string)
        var value: Int = 0
        return scanner.scanInt(&value) && scanner.isAtEnd
    }
    
    public static func isPureFloat(_ string: String?) -> Bool {
        guard let string = string, !string.isEmpty else { return false }
        let scanner = Scanner(string: string)
        var value: Float = 0
        return scanner.scanFloat(&value) && scanner.isAtEnd
    }
    
    public static func isValidateString(_ string: String?) -> Bool {
        guard let string = string else { return false }
        return !string.isEmpty
    }
    
    public static func isValidateArray(_ array: [Any]?) -> Bool {
        guard let array = array else { return false }
        return !array.isEmpty
    }
    
    public static func isValidateDictionary(_ dictionary: [String: Any]?) -> Bool {
        guard let dictionary = dictionary else { return false }
        return !dictionary.isEmpty
    }
    
    public static func floatEqual(_ aNumber: CGFloat, _ bNumber: CGFloat) -> Bool {
        return abs(aNumber - bNumber) < .ulpOfOne
    }
    
    public static func isChineseEnvironment() -> Bool {
        guard let languages = UserDefaults.standard.object(forKey: "AppleLanguages") as? [String],
              let first = languages.first else { return false }
        return first == "zh-Hans-CN"
    }

    
    // MARK: - Memory & Disk
    public static func usedMemory() -> Double {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return Double(NSNotFound) }
        return Double(taskInfo.resident_size) / 1024.0 / 1024.0
    }
    
    public static func availableMemory() -> Double {
        var vmStats = vm_statistics_data_t()
        var infoCount = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) {
                host_statistics(mach_host_self(), HOST_VM_INFO, $0, &infoCount)
            }
        }
        guard result == KERN_SUCCESS else { return Double(NSNotFound) }
        return Double(vm_page_size) * Double(vmStats.free_count) / 1024.0 / 1024.0
    }
    
    public static func diskOfAllSizeBytes() -> CGFloat {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let size = attrs[.systemSize] as? NSNumber else { return 0 }
        return CGFloat(size.floatValue)
    }
    
    public static func diskOfFreeSizeBytes() -> CGFloat {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let size = attrs[.systemFreeSize] as? NSNumber else { return 0 }
        return CGFloat(size.floatValue)
    }
    
    public static func folderSize(atPath folderPath: String, extension ext: String? = nil) -> Int {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: folderPath) else { return 0 }
        
        guard let enumerator = fileManager.enumerator(atPath: folderPath) else { return 0 }
        var folderSize = 0
        
        while let fileName = enumerator.nextObject() as? String {
            let filePath = (folderPath as NSString).appendingPathComponent(fileName)
            if let ext = ext {
                if (filePath as NSString).pathExtension == ext {
                    folderSize += fileSize(atPath: filePath)
                }
            } else {
                folderSize += fileSize(atPath: filePath)
            }
        }
        return folderSize
    }
    
    public static func fileSize(atPath filePath: String) -> Int {
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: filePath, isDirectory: &isDir) else { return 0 }
        
        if isDir.boolValue {
            var size = 0
            if let enumerator = fileManager.enumerator(atPath: filePath) {
                while let subPath = enumerator.nextObject() as? String {
                    let fullPath = (filePath as NSString).appendingPathComponent(subPath)
                    if let attrs = try? fileManager.attributesOfItem(atPath: fullPath),
                       let fileSize = attrs[.size] as? Int {
                        size += fileSize
                    }
                }
            }
            return size
        } else {
            if let attrs = try? fileManager.attributesOfItem(atPath: filePath),
               let fileSize = attrs[.size] as? Int {
                return fileSize
            }
            return 0
        }
    }
    
    public static func freeStoragePercentage() -> CGFloat {
        let total = CGFloat(getTotalDiskSize())
        guard total > 1 else { return 0 }
        return CGFloat(getAvailableDiskSize()) / total
    }
    
    public static func getTotalDiskSize() -> Int {
        var stat = statfs()
        guard statfs("/var", &stat) >= 0 else { return -1 }
        return Int(stat.f_bsize) * Int(stat.f_blocks)
    }
    
    public static func getAvailableDiskSize() -> Int {
        var stat = statfs()
        guard statfs("/var", &stat) >= 0 else { return -1 }
        return Int(stat.f_bsize) * Int(stat.f_bavail)
    }
    
    // MARK: - App Info
    public static func appVersionNumber() -> String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    public static func appLongVersionNumber() -> String? {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    }
    
    public static func appName() -> String? {
        return Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
    }
    
    public static func appBundleName() -> String? {
        return Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String
    }

    
    // MARK: - IP Address
    public static func iPAddress() -> String {
        var address = "error"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return address }
        
        var ptr = firstAddr
        while true {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                               &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
            guard let next = interface.ifa_next else { break }
            ptr = next
        }
        freeifaddrs(ifaddr)
        return address
    }
    
    // MARK: - Path
    public static func homeDirectoryPath(_ fileName: String?) -> String? {
        guard let fileName = fileName, !fileName.isEmpty else { return nil }
        return (NSHomeDirectory() as NSString).appendingPathComponent(fileName)
    }
    
    public static func documentsPath(_ fileName: String?) -> String? {
        guard let fileName = fileName, !fileName.isEmpty else { return nil }
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last else { return nil }
        return (path as NSString).appendingPathComponent(fileName)
    }
    
    public static func temporaryDirectoryFile(_ fileName: String?) -> String? {
        guard let fileName = fileName, !fileName.isEmpty else { return nil }
        return (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
    }
    
    // MARK: - Random
    public static func randomNumber(withDigit digit: Int) -> String {
        var result = ""
        for _ in 0..<digit {
            result += String(Int.random(in: 0...9))
        }
        return result
    }
    
    // MARK: - String Utilities
    public static func blankInChars(_ string: String, byCellNo num: Int) -> String? {
        guard !string.isEmpty else { return nil }
        var result: [String] = []
        var temp: [Character] = []
        
        for char in string {
            temp.append(char)
            if temp.count == num {
                result.append(String(temp))
                temp.removeAll()
            }
        }
        if !temp.isEmpty {
            result.append(String(temp))
        }
        return result.joined(separator: " ")
    }
    
    public static func stringDeleteNewLineAndWhiteSpace(_ string: String) -> String {
        return string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public static func cleanString(_ str: String?) -> String {
        guard let str = str else { return "" }
        return str.replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
    
    public static func asciiCode(with string: String) -> String {
        var result = ""
        for char in string.unicodeScalars {
            result += String(char.value)
        }
        return result
    }
    
    public static func string(fromASCIIString string: String) -> String? {
        guard let asciiCode = UInt32(string) else { return nil }
        guard let scalar = Unicode.Scalar(asciiCode) else { return nil }
        return String(Character(scalar))
    }
    
    // MARK: - MD5
    public static func md5(_ str: String?) -> String? {
        guard let str = str, let data = str.data(using: .utf8) else { return nil }
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        _ = data.withUnsafeBytes {
            CC_MD5($0.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02X", $0) }.joined()
    }
    
    // MARK: - Color
    public static func randomColor() -> UIColor {
        let r = CGFloat(arc4random_uniform(256)) / 255.0
        let g = CGFloat(arc4random_uniform(256)) / 255.0
        let b = CGFloat(arc4random_uniform(256)) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }
    
    public static func color(withHexString color: String) -> UIColor {
        var cString = color.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard cString.count >= 6 else { return .clear }
        
        if cString.hasPrefix("0X") {
            cString = String(cString.dropFirst(2))
        }
        if cString.hasPrefix("#") {
            cString = String(cString.dropFirst())
        }
        guard cString.count == 6 else { return .clear }
        
        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }

    
    // MARK: - Font
    public static func angleFont(withRate rate: CGFloat, fontSize: Int) -> UIFont {
        let matrix = CGAffineTransform(a: 1, b: 0, c: tan(rate * .pi / 180), d: 1, tx: 0, ty: 0)
        let desc = UIFontDescriptor(name: UIFont.systemFont(ofSize: CGFloat(fontSize)).fontName, matrix: matrix)
        return UIFont(descriptor: desc, size: CGFloat(fontSize))
    }
    
    // MARK: - Unit Conversion
    public static func kmgUnit(_ size: Int) -> String {
        if size >= 1024 * 1024 * 1024 {
            return String(format: "%.2f G", Double(size) / Double(1024 * 1024 * 1024))
        } else if size >= 1024 * 1024 {
            return String(format: "%.2f M", Double(size) / Double(1024 * 1024))
        } else {
            return String(format: "%.2f K", Double(size) / 1024.0)
        }
    }
    
    // MARK: - Bank Style Formatting
    public static func bankStyleFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.positiveFormat = "###,##0.00;"
        return formatter
    }
    
    public static func bankStyleData(_ data: CGFloat) -> String {
        let formatter = NumberFormatter()
        formatter.positiveFormat = "0.00;"
        return formatter.string(from: NSNumber(value: Double(data))) ?? ""
    }
    
    public static func bankStyleDataThree(_ data: CGFloat) -> String {
        let formatter = bankStyleFormatter()
        return formatter.string(from: NSNumber(value: Double(data))) ?? ""
    }
    
    public static func bankStyleDataThreeForCents(_ cents: Int) -> String {
        let formatter = bankStyleFormatter()
        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? ""
    }
    
    // MARK: - Decimal Operations
    public static func fourNoFiveYes(_ number: Float, afterPoint position: Int) -> String {
        let handler = NSDecimalNumberHandler(
            roundingMode: .up,
            scale: Int16(position),
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )
        let decimal = NSDecimalNumber(value: number)
        let rounded = decimal.rounding(accordingToBehavior: handler)
        return rounded.stringValue
    }
    
    public static func forwardValue(_ number: Double, afterPoint position: Int) -> Double {
        let handler = NSDecimalNumberHandler(
            roundingMode: .up,
            scale: Int16(position),
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )
        let decimal = NSDecimalNumber(value: number)
        let rounded = decimal.rounding(accordingToBehavior: handler)
        return rounded.doubleValue
    }
    
    public static func decimalNumberMultiply(_ multiplierValue: String, valueB multiplicandValue: String) -> String {
        let multiplier = NSDecimalNumber(string: multiplierValue)
        let multiplicand = NSDecimalNumber(string: multiplicandValue)
        return multiplicand.multiplying(by: multiplier).stringValue
    }
    
    // MARK: - High Accuracy Math
    public static func highAccuracyAdd(_ a: String, _ b: String) -> String {
        let aNum = NSDecimalNumber(string: isPureFloat(a) ? a : "0")
        let bNum = NSDecimalNumber(string: isPureFloat(b) ? b : "0")
        return aNum.adding(bNum).stringValue
    }
    
    public static func highAccuracySubtract(_ a: String, _ b: String) -> String {
        let aNum = NSDecimalNumber(string: isPureFloat(a) ? a : "0")
        let bNum = NSDecimalNumber(string: isPureFloat(b) ? b : "0")
        return aNum.subtracting(bNum).stringValue
    }
    
    public static func highAccuracyMultiply(_ a: String, _ b: String) -> String {
        let aNum = NSDecimalNumber(string: isPureFloat(a) ? a : "0")
        let bNum = NSDecimalNumber(string: isPureFloat(b) ? b : "0")
        return aNum.multiplying(by: bNum).stringValue
    }
    
    public static func highAccuracyDivide(_ a: String, _ b: String) -> String {
        let aNum = NSDecimalNumber(string: isPureFloat(a) ? a : "0")
        let bNum = NSDecimalNumber(string: isPureFloat(b) ? b : "0")
        return aNum.dividing(by: bNum).stringValue
    }
    
    public static func highAccuracyCompare(_ a: String, _ b: String) -> ComparisonResult {
        let aNum = NSDecimalNumber(string: isPureFloat(a) ? a : "0")
        let bNum = NSDecimalNumber(string: isPureFloat(b) ? b : "0")
        return aNum.compare(bNum)
    }
    
    // MARK: - Number Conversion
    public static func numberStringToTwoDecimalPlaces(_ floatString: String) -> Int {
        let flt = Double(floatString) ?? 0
        let centFlt = round(flt * 100.0)
        return Int(centFlt)
    }
    
    public static func numberStringToFiveDecimalPlaces(_ floatString: String) -> Int {
        let flt = Double(floatString) ?? 0
        let centFlt = round(flt * Double(FSFiveDecimalPlaces))
        return Int(centFlt)
    }
    
    public static func floatToInt(_ floatString: String) -> Int {
        let decimal = NSDecimalNumber(string: floatString)
        return decimal.intValue
    }

    
    // MARK: - Account Number Validation
    public static func isFSAccountNumber(_ text: String) -> Bool {
        var pointNumber = 0
        var findPoint = false
        var afterPointNumber = 0
        let validChars = Set("0123456789.")
        
        for char in text {
            guard validChars.contains(char) else { return false }
            
            if char == "." {
                pointNumber += 1
                findPoint = true
            } else if findPoint {
                afterPointNumber += 1
            }
        }
        
        return pointNumber <= 1 && afterPointNumber <= 2
    }
    
    // MARK: - Growth Rate
    public static func growthRate(_ number: CGFloat, base: CGFloat) -> CGFloat {
        if base > 0 {
            return number / base - 1
        } else if base < 0 {
            return 1 - number / base
        }
        return 0
    }
    
    // MARK: - Base64
    public static func base64String(forText text: String?) -> String? {
        guard let text = text, let data = text.data(using: .utf8) else { return nil }
        return data.base64EncodedString(options: .lineLength64Characters)
    }
    
    public static func text(fromBase64String text: String?) -> String? {
        guard let text = text, let data = Data(base64Encoded: text, options: .ignoreUnknownCharacters) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    public static func base64Code(_ data: Data) -> String {
        return data.base64EncodedString()
    }
    
    // MARK: - Time Conversion
    public static func countOverTime(_ time: TimeInterval) -> String {
        let seconds = Int(time)
        var result = ""
        
        let day = seconds / (60 * 60 * 24)
        if day > 0 { result += "\(day)天" }
        
        let hour = (seconds - day * 60 * 60 * 24) / 3600
        if hour > 0 { result += "\(hour)小时" }
        
        let minute = (seconds - day * 60 * 60 * 24 - hour * 3600) / 60
        if minute > 0 { result += "\(minute)分钟" }
        
        return result
    }
    
    public static func dayMonthYear(forNumber number: CGFloat) -> String {
        if number > 365 {
            return String(format: "%.2f年", number / 365.0)
        } else if number > 30 {
            return String(format: "%.2f月", number / 30)
        } else {
            return String(format: "%.2f天", number)
        }
    }
    
    // MARK: - Pinyin
    public static func pinyin(forHans chinese: String) -> String {
        let mutableString = NSMutableString(string: chinese)
        CFStringTransform(mutableString, nil, kCFStringTransformMandarinLatin, false)
        CFStringTransform(mutableString, nil, kCFStringTransformStripCombiningMarks, false)
        return mutableString as String
    }
    
    public static func pinyinForHansClear(_ chinese: String) -> String {
        return cleanString(pinyin(forHans: chinese))
    }
    
    public static func convertNumbers(_ string: String) -> String? {
        guard isValidateString(string) else { return nil }
        
        let numbers = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        let chinese = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
        
        var result = ""
        for char in string {
            let charStr = String(char)
            if let index = numbers.firstIndex(of: charStr) {
                result += chinese[index]
            }
        }
        return pinyinForHansClear(result)
    }
    
    // MARK: - String Reverse
    public static func reverseWords(in str: String) -> String {
        return String(str.reversed())
    }
    
    // MARK: - QR Code
    public static func scanQRCode(_ image: UIImage) -> String? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        guard let features = detector?.features(in: ciImage) as? [CIQRCodeFeature] else { return nil }
        return features.first?.messageString
    }
    
    // MARK: - Data Conversion
    public static func dataToHex(_ data: Data) -> String {
        return data.map { String(format: "%02x", $0) }.joined()
    }
    
    public static func convertHexStrToData(_ str: String) -> Data? {
        guard !str.isEmpty else { return nil }
        var data = Data()
        var index = str.startIndex
        
        while index < str.endIndex {
            let nextIndex = str.index(index, offsetBy: 2, limitedBy: str.endIndex) ?? str.endIndex
            let hexStr = String(str[index..<nextIndex])
            if let byte = UInt8(hexStr, radix: 16) {
                data.append(byte)
            }
            index = nextIndex
        }
        return data
    }

    
    // MARK: - Attributed String
    public static func attributedString(for sourceString: String, colorRanges: [NSRange], color: UIColor, textRanges: [NSRange], font: UIFont) -> NSAttributedString {
        let attributedStr = NSMutableAttributedString(string: sourceString)
        for range in colorRanges {
            attributedStr.addAttribute(.foregroundColor, value: color, range: range)
        }
        for range in textRanges {
            attributedStr.addAttribute(.font, value: font, range: range)
        }
        return attributedStr
    }
    
    public static func attributedString(for sourceString: String, colorStrings: [String], color: UIColor, fontStrings: [String]?, font: UIFont?) -> NSAttributedString {
        var colorRanges: [NSRange] = []
        var textRanges: [NSRange] = []
        
        for colorStr in colorStrings {
            if let range = sourceString.range(of: colorStr) {
                colorRanges.append(NSRange(range, in: sourceString))
            }
        }
        
        if let fontStrings = fontStrings {
            for fontStr in fontStrings {
                if let range = sourceString.range(of: fontStr) {
                    textRanges.append(NSRange(range, in: sourceString))
                }
            }
        }
        
        return attributedString(for: sourceString, colorRanges: colorRanges, color: color, textRanges: textRanges, font: font ?? UIFont.systemFont(ofSize: 14))
    }
    
    public func middleLine(forLabel text: String) -> NSAttributedString {
        return NSAttributedString(string: text, attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue])
    }
    
    public func underLine(forLabel text: String) -> NSAttributedString {
        return NSAttributedString(string: text, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
    }
    
    // MARK: - First Character
    public static func firstCharacter(with string: String) -> String {
        let mutableString = NSMutableString(string: string)
        CFStringTransform(mutableString, nil, kCFStringTransformMandarinLatin, false)
        CFStringTransform(mutableString, nil, kCFStringTransformStripDiacritics, false)
        let pinyin = mutableString.capitalized
        return String(pinyin.prefix(1))
    }
    
    // MARK: - Bank Card Number
    public static func forthCarNumber(_ text: String?) -> String? {
        guard var text = text else { return nil }
        text = text.replacingOccurrences(of: " ", with: "")
        guard isValidateString(text) else { return nil }
        
        var result: [String] = []
        let length = text.count
        let numbers = length / 4
        let rest = length % 4
        
        for i in 0..<numbers {
            let start = text.index(text.startIndex, offsetBy: i * 4)
            let end = text.index(start, offsetBy: 4)
            result.append(String(text[start..<end]))
        }
        
        if rest > 0 {
            let start = text.index(text.startIndex, offsetBy: length - rest)
            result.append(String(text[start...]))
        }
        
        return result.joined(separator: " ")
    }
    
    // MARK: - Phone Call
    public static func call(_ phone: String?) {
        guard let phone = phone else { return }
        let numbers = stringsNumbersLeft(phone)
        guard let url = URL(string: "telprompt:\(numbers)") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    public static func callPhoneWithNoNotice(_ phone: String?) {
        guard let phone = phone else { return }
        let numbers = stringsNumbersLeft(phone)
        guard let url = URL(string: "tel:\(numbers)") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    private static func stringsNumbersLeft(_ text: String) -> String {
        return text.filter { $0.isNumber }
    }
    
    // MARK: - Open App
    public static func openApp(byURLString str: String) {
        guard let url = URL(string: "\(str)://://") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    // MARK: - Display Formatting
    public static func showBetterFor2DigitFloat(_ value: Float) -> String {
        let d = Int(value)
        return self.showBetterFor2DigitInteger(d)
    }

    public static func showBetterFor2DigitDouble(_ value: Double) -> String {
        let d = Int(value)
        return self.showBetterFor2DigitInteger(d)
    }

    public static func showBetterFor2DigitInteger(_ value: Int) -> String {
        guard value != 0 else { return "0" }
        
        if value % 100 == 0 {
            return "\(value / 100)"
        } else if value % 10 == 0 {
            return String(format: "%.1f", Double(value) / 100)
        } else {
            return String(format: "%.2f", Double(value) / 100)
        }
    }
    
    public static func showBetterFor3DigitInteger(_ value: Int) -> String {
        guard value != 0 else { return "0" }
        
        if value % 1000 == 0 {
            return "\(value / 1000)"
        } else if value % 100 == 0 {
            return String(format: "%.1f", Double(value) / 1000)
        } else if value % 10 == 0 {
            return String(format: "%.2f", Double(value) / 1000)
        } else {
            return String(format: "%.3f", Double(value) / 1000)
        }
    }
    
    public static func showByTenThousand(_ rest: CGFloat, money: Bool) -> String {
        if rest < 100000 {
            return money ? bankStyleDataThree(rest) : "\(Int(rest))"
        } else if rest < 1000000 {
            return String(format: "%.2f万", rest / 10000.0)
        } else if rest < 100000000 {
            return String(format: "%.0f万", rest / 10000.0)
        } else if rest < 10000000000 {
            return String(format: "%.2f亿", rest / 100000000.0)
        } else {
            return String(format: "%.0f亿", rest / 100000000.0)
        }
    }

    
    // MARK: - Array Utilities
    public static func maxAndMinNumber(in array: [Any]) -> [NSNumber]? {
        guard !array.isEmpty else { return nil }
        
        var maxVal = (array[0] as? NSNumber)?.doubleValue ?? 0
        var minVal = maxVal
        
        for item in array {
            let number = (item as? NSNumber)?.doubleValue ?? 0
            if number > maxVal { maxVal = number }
            if number < minVal { minVal = number }
        }
        
        return [NSNumber(value: maxVal), NSNumber(value: minVal)]
    }
    
    public static func maopaoArray(_ array: [Any]) -> [Any]? {
        guard !array.isEmpty else { return nil }
        
        var mArray = array.compactMap { ($0 as? NSNumber)?.doubleValue }
        
        for x in 0..<(mArray.count - 1) {
            for y in 0..<(mArray.count - 1 - x) {
                if mArray[y] > mArray[y + 1] {
                    mArray.swapAt(y, y + 1)
                }
            }
        }
        
        return mArray.map { NSNumber(value: $0) }
    }
    
    public static func arrayReverse(_ array: [Any]) -> [Any] {
        return array.reversed()
    }
    
    public static func arrayByOneChar(from string: String) -> [String]? {
        guard !string.isEmpty else { return nil }
        return string.map { String($0) }
    }
    
    // MARK: - URL Parameters
    public static func urlParameters(from url: URL?) -> [String: String]? {
        guard let url = url else { return nil }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        
        var params: [String: String] = [:]
        components.queryItems?.forEach { item in
            params[item.name] = item.value ?? ""
        }
        return params
    }
    
    // MARK: - Method Swizzle
    public static func methodSwizzle(_ cls: AnyClass, origin oriSel: Selector, swizzle swiSel: Selector) {
        guard let originMethod = class_getInstanceMethod(cls, oriSel),
              let swizzledMethod = class_getInstanceMethod(cls, swiSel) else { return }
        
        let hasMethod = class_addMethod(cls, oriSel, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        
        if hasMethod {
            class_replaceMethod(cls, swiSel, method_getImplementation(originMethod), method_getTypeEncoding(originMethod))
        } else {
            method_exchangeImplementations(originMethod, swizzledMethod)
        }
    }
    
    // MARK: - ScrollView Gesture
    public static func fitScrollViewOperate(_ scrollView: UIScrollView, navigationController: UINavigationController?) {
        guard let nav = navigationController else { return }
        for gesture in nav.view.gestureRecognizers ?? [] {
            if gesture is UIScreenEdgePanGestureRecognizer {
                scrollView.panGestureRecognizer.require(toFail: gesture)
            }
        }
    }
    
    // MARK: - String Part Display
    public static func showStringPart(_ string: String, front: Int, tail: Int, placeholder: String = "***") -> String {
        guard string.count > front, string.count > tail else { return string }
        
        let frontStr = String(string.prefix(front))
        let lastStr = String(string.suffix(tail))
        return "\(frontStr)\(placeholder)\(lastStr)"
    }
    
    // MARK: - Window Scene
    public static func currentWindowScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes
        for scene in scenes {
            if scene.activationState == .foregroundActive, let windowScene = scene as? UIWindowScene {
                return windowScene
            }
        }
        return scenes.first as? UIWindowScene
    }
    
    // MARK: - Digital Only String
    public static func digitalOnlyString(_ inputString: String?) -> String {
        guard let inputString = inputString, !inputString.isEmpty else { return "" }
        return inputString.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
    }
    
    // MARK: - Bundle File
    public static func bundleFile(_ bundle: String?, name: String, ofType type: String) -> String? {
        let bundleObj = self.bundle(withName: bundle)
        return bundleObj?.path(forResource: name, ofType: type)
    }
    
    private static func bundle(withName bundleName: String?) -> Bundle? {
        let name = bundleName ?? "main"
        guard let bundlePath = Bundle(for: FSKit.self).path(forResource: name, ofType: "bundle") else { return nil }
        return Bundle(path: bundlePath)
    }
    
    // MARK: - Haptic Feedback
    public static func feedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // MARK: - Keyboard
    public static func keyboardSize(from notification: Notification) -> CGSize {
        guard let name = notification.name as NSNotification.Name?,
              name == UIResponder.keyboardWillShowNotification ||
              name == UIResponder.keyboardWillChangeFrameNotification ||
              name == UIResponder.keyboardWillHideNotification else { return .zero }
        
        guard let info = notification.userInfo,
              let value = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return .zero }
        
        return value.cgRectValue.size
    }
    
    public static func keyboardNotificationScroll(_ notification: Notification, baseOn: CGFloat) -> CGSize {
        let keyboardSize = self.keyboardSize(from: notification)
        let screenSize = UIScreen.main.bounds.size
        
        if notification.name == UIResponder.keyboardWillShowNotification {
            return CGSize(width: screenSize.width, height: max(keyboardSize.height + baseOn, screenSize.height))
        } else if notification.name == UIResponder.keyboardWillHideNotification {
            return CGSize(width: screenSize.width, height: max(baseOn, screenSize.height))
        }
        return .zero
    }
    
    // MARK: - Device Info
    public static func deviceInfos() -> [[String: String]] {
        let device = UIDevice.current
        let screen = UIScreen.main
        let scale = screen.scale
        let width = screen.bounds.width * scale
        let height = screen.bounds.height * scale
        
        return [
            ["name": "我的设备", "value": device.name],
            ["name": "系统版本", "value": "\(device.systemName)\(device.systemVersion)"],
            ["name": "唯一标识符", "value": device.identifierForVendor?.uuidString ?? ""],
            ["name": "屏幕分辨率", "value": "\(Int(width)) x \(Int(height))"],
            ["name": "电池信息", "value": getBatteryState()],
            ["name": "电量", "value": "\(device.batteryLevel)"],
            ["name": "iP地址", "value": iPAddress()],
            ["name": "磁盘总量", "value": kmgUnit(getTotalDiskSize())],
            ["name": "磁盘可用空间", "value": kmgUnit(getAvailableDiskSize())]
        ]
    }
    
    private static func getBatteryState() -> String {
        switch UIDevice.current.batteryState {
        case .unknown: return "未知"
        case .unplugged: return "未充电"
        case .charging: return "充电"
        case .full: return "电量已满"
        @unknown default: return "未知"
        }
    }
    
    // MARK: - Image Compression
    public static func compressOriginalImage(_ image: UIImage, toMaxDataSizeKBytes size: CGFloat) -> Data? {
        var maxQuality: CGFloat = 0.9
        var data = image.jpegData(compressionQuality: 1.0)
        var dataKBytes = CGFloat(data?.count ?? 0) / 1000.0
        var lastData = dataKBytes
        
        while dataKBytes > size && maxQuality > 0.01 {
            maxQuality -= 0.01
            data = image.jpegData(compressionQuality: maxQuality)
            dataKBytes = CGFloat(data?.count ?? 0) / 1000.0
            if lastData == dataKBytes { break }
            lastData = dataKBytes
        }
        return data
    }
    
    public static func showBetterFor5DigitFloat(_ value: Float) -> String {
        let d = Int(value)
        return self.showBetterFor5DigitInteger(d)
    }
    
    public static func showBetterFor5DigitDouble(_ value: Double) -> String {
        let d = Int(value)
        return self.showBetterFor5DigitInteger(d)
    }
    
    public static func showBetterFor5DigitInteger(_ value: Int) -> String {
        if value == 0 {
            return "0"
        }
        
        var mode = value % FSFiveDecimalPlaces
        var ret: String = "0"
        if mode == 0 {
            ret = String(value / FSFiveDecimalPlaces)
        } else {
            mode = value % 10000
            if mode == 0 {
                ret = String(format: "%.1f", Double(value) / Double(FSFiveDecimalPlaces))
            } else {
                mode = value % 1000
                if mode == 0 {
                    ret = String(format: "%.2f", Double(value) / Double(FSFiveDecimalPlaces))
                } else {
                    mode = value % 100
                    if mode == 0 {
                        ret = String(format: "%.3f", Double(value) / Double(FSFiveDecimalPlaces))
                    } else {
                        mode = value % 10
                        if mode == 0 {
                            ret = String(format: "%.4f", Double(value) / Double(FSFiveDecimalPlaces))
                        } else {
                            ret = String(format: "%.5f", Double(value) / Double(FSFiveDecimalPlaces))
                        }
                    }
                }
            }
        }
        
        return ret
    }
}

// MARK: - GCD Helpers
public func fs_dispatch_global_main_queue_async(globalBlock: @escaping () -> Void, mainBlock: @escaping () -> Void) {
    DispatchQueue.global().async {
        globalBlock()
        DispatchQueue.main.async {
            mainBlock()
        }
    }
}

public func fs_dispatch_main_queue_async(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async { block() }
    }
}

public func fs_dispatch_main_queue_sync(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.sync { block() }
    }
}

public func fs_dispatch_global_queue_async(_ block: @escaping () -> Void) {
    DispatchQueue.global().async { block() }
}

public func fs_dispatch_global_queue_sync(_ block: @escaping () -> Void) {
    DispatchQueue.global().sync { block() }
}

// MARK: - Time Helpers
public func fs_timeIntervalSince1970() -> TimeInterval {
    return Date().timeIntervalSince1970
}

public func fs_integerTimeIntervalSince1970() -> Int {
    return Int(fs_timeIntervalSince1970())
}

public func fs_spendTimeInDoSomething(body: () -> Void, time: (Double) -> Void) {
    let t = fs_timeIntervalSince1970()
    body()
    time(fs_timeIntervalSince1970() - t)
}

public func fs_userDefaultsOnce(key: String, event: () -> Void) {
    guard FSKit.isValidateString(key) else { return }
    let ud = UserDefaults.standard
    if ud.object(forKey: key) == nil {
        event()
        ud.set(1, forKey: key)
    }
}
