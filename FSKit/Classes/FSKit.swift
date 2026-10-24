//
//  FSKitCore.swift
//  FSKit
//
//  Translated from Objective-C to Swift
//

import UIKit
import CryptoKit

public nonisolated let FS_BE_DEBUG_NOTIFICATION  =   "FS_BE_DEBUG_NOTIFICATION"

/// 疑似内存泄漏通知：基类检测到页面 pop/dismiss 后仍未释放时投递，object 为提示文案（String）。
/// 由 App 层监听并按需（如 FSJZAPP.Fudon()）弹 toast，避免基类反向依赖上层。
public nonisolated let FS_BE_LEAK_NOTIFICATION   =   "FS_BE_LEAK_NOTIFICATION"

/// 一年的秒数
public nonisolated let FSKitYearSeconds: Double = 31556926.08

/// 支持小数点后5位，支持汇率（4位），必须是整数，目的是解决Double运算精度损失的问题，目前这是一个好的方案
public nonisolated let FSFiveDecimalPlaces: Int = 100000
public nonisolated let FSDoubleFiveDecimalPlaces: Double = 100000.0

/// 支持小数点后3位，支持价格，必须是整数，目的是解决Double运算精度损失的问题，目前这是一个好的方案
public nonisolated let FSThreeDecimalPlaces: Int = 1000
public nonisolated let FSDoubleThreeDecimalPlaces: Double = 1000.0

// MARK: - FSKit
public enum FSKit {
    
    public static func printArrayFirstJSON(_ list: [[String: Any]]) {
        
        let js = FSKit.jsonString(list.first ?? [])
        print("FSKit js = \(js)")
    
    }
    
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
    /// nonisolated：无状态纯函数，需供网络回调等非隔离上下文调用
    public nonisolated static func object(fromJsonString jsonString: String?) -> Any? {
        guard let jsonString = jsonString, !jsonString.isEmpty else { return nil }
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
    }
    
    /// ★ 2026-10-24：`nonisolated` —— 纯 `JSONSerialization`，无共享可变状态，
    /// 后台执行器上的建模（`FSAAModel` 等）需要它。
    public nonisolated static func jsonString(_ object: Any) -> String {
        guard JSONSerialization.isValidJSONObject(object) else { return "" }
        
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    public static func copyToPasteboard(_ string: String?) {
        guard let string = string else { return }
        UIPasteboard.general.string = string
    }
    
    public static func letScreenLock(_ lock: Bool) {
        UIApplication.shared.isIdleTimerDisabled = !lock
    }
    
    public static func gotoAppCenterPage(withAppId appID: String) {
        let urlString = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=\(appID)"
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
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
        if #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) {
            let scanner = Scanner(string: string)
            return scanner.scanInt() != nil && scanner.isAtEnd
        }
        
        return Int(string.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }
    
    public static func isPureFloat(_ string: String?) -> Bool {
        guard let string = string, !string.isEmpty else { return false }
        if #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) {
            let scanner = Scanner(string: string)
            return scanner.scanFloat() != nil && scanner.isAtEnd
        }
        
        return Float(string.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }
    
    /// ★ 2026-10-24：`nonisolated` —— 纯字符串判空，无状态，供后台执行器调用。
    public nonisolated static func isValidateString(_ string: String?) -> Bool {
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
    
    public static func floatEqual(_ aNumber: Double, _ bNumber: Double) -> Bool {
        return abs(aNumber - bNumber) < .ulpOfOne
    }
    
    public static func isChineseEnvironment() -> Bool {
        guard let languages = UserDefaults.standard.object(forKey: "AppleLanguages") as? [String],
              let first = languages.first else { return false }
        return first == "zh-Hans-CN"
    }

    
    // MARK: - Memory & Disk

    /// 当前进程物理占用（footprint，字节）。
    ///
    /// 这与 Xcode Debug Navigator / Instruments 里显示的 Memory 是同一个数，也是系统 jetsam
    /// （内存不足杀进程）的判定依据。**不要用 `MACH_TASK_BASIC_INFO.resident_size`**：
    /// 那是 RSS，含可回收的 clean pages，通常比 Xcode 显示值大很多。
    public static func memoryFootprintBytes() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), rebound, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        return info.phys_footprint
    }

    /// 当前进程占用（MB），与 Xcode 显示一致
    public static func memoryFootprint() -> Double {
        Double(memoryFootprintBytes()) / 1024.0 / 1024.0
    }

    /// 本进程还能申请多少（MB，iOS 13+）。
    ///
    /// 这是「离被系统杀掉还有多远」的直接指标，比整机空闲内存更有参考价值。
    /// 模拟器上可能返回 0。
    public static func availableMemoryForApp() -> Double {
        Double(os_proc_available_memory()) / 1024.0 / 1024.0
    }

    /// 形如 "128.4MB"，便于日志与 toast（内部先造字符串，避免多处重复 format）
    public static func memoryFootprintText() -> String {
        String(format: "%.1fMB", memoryFootprint())
    }

    /// resident_size（RSS，MB）。
    ///
    /// 与 Xcode 显示值不一致，仅保留用于和旧日志比对；新代码请用 `memoryFootprint()`。
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
    
    /// 整机空闲内存（MB）。
    ///
    /// 注意：这是**设备全局**的空闲页，不是本 App 的可用额度；线上表现与它关系不大。
    /// 要看本进程还能吃多少，用 `availableMemoryForApp()`。
    public static func availableMemory() -> Double {
        var vmStats = vm_statistics_data_t()
        var infoCount = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) {
                host_statistics(mach_host_self(), HOST_VM_INFO, $0, &infoCount)
            }
        }
        guard result == KERN_SUCCESS else { return Double(NSNotFound) }
        // Swift 6：`vm_page_size` 是 C 全局变量，被判为并发不安全的共享可变状态；
        // `sysconf(_SC_PAGESIZE)` 是等价的 POSIX 调用，不受此限制。
        let pageSize = Double(sysconf(_SC_PAGESIZE))
        return pageSize * Double(vmStats.free_count) / 1024.0 / 1024.0
    }
    
    public static func diskOfAllSizeBytes() -> Double {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let size = attrs[.systemSize] as? NSNumber else { return 0 }
        return Double(size.floatValue)
    }
    
    public static func diskOfFreeSizeBytes() -> Double {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let size = attrs[.systemFreeSize] as? NSNumber else { return 0 }
        return Double(size.floatValue)
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
    
    public static func freeStoragePercentage() -> Double {
        let total = Double(getTotalDiskSize())
        guard total > 1 else { return 0 }
        return Double(getAvailableDiskSize()) / total
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
    
    public static func appName() -> String {
        let name = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
        if let name {
            return name
        }
        return ""
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
                    // 2026-10-17：String(cString:) 在 iOS 26 SDK 已弃用，按其提示改为显式解码。
                address = String(decoding: hostname.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
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
        
    public static func md5(_ str: String?) -> String? {
          guard let str = str, let data = str.data(using: .utf8) else { return nil }
          
          // 使用 CryptoKit 计算 MD5 摘要（iOS 13+ 推荐方式）
          let digest = Insecure.MD5.hash(data: data)
          
          // 转为大写 16 进制字符串（和你原代码输出格式完全一致）
          return digest.map { String(format: "%02X", $0) }.joined()
      }
      
      /// 可选：小写输出版本（按需使用）
      public static func md5Lowercase(_ str: String?) -> String? {
          guard let upperCase = md5(str) else { return nil }
          return upperCase.lowercased()
      }
    
    // MARK: - Color
    public static func randomColor() -> UIColor {
        let r = Double(arc4random_uniform(256)) / 255.0
        let g = Double(arc4random_uniform(256)) / 255.0
        let b = Double(arc4random_uniform(256)) / 255.0
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
            red: Double((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgbValue & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }

    
    // MARK: - Font
    public static func angleFont(withRate rate: Double, fontSize: Int) -> UIFont {
        let matrix = CGAffineTransform(a: 1, b: 0, c: tan(rate * .pi / 180), d: 1, tx: 0, ty: 0)
        let desc = UIFontDescriptor(name: UIFont.systemFont(ofSize: Double(fontSize)).fontName, matrix: matrix)
        return UIFont(descriptor: desc, size: Double(fontSize))
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
    public nonisolated static func bankStyleFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.positiveFormat = "###,##0.00;"
        return formatter
    }

    /// 银行风格金额的共享 formatter。
    ///
    /// ★ 2026-10-24：`bankStyleDataThree` / `bankStyleDataThreeForCents` 原来每次调用都新建一个
    /// `NumberFormatter` 并重设 `positiveFormat`（实测 48.8µs/次，复用同一实例仅 1.06µs，**46×**）。
    /// 这两个函数在列表 cell 的 `body` 里被反复调用，等于每帧白烧几十微秒。
    /// （`bankStyleFormatter()` 本体保持原样：仍返回新实例，供需要独立配置的调用方使用。）
    ///
    /// ★ 2026-10-24（二）：**不再依赖「默认主隔离」这个隐式约束**。首页年度数据已改到并发执行器上算
    /// （`FSAccountDataModel.businessGlobal` 的 `@concurrent`），会在后台线程调用这两个函数，而
    /// `NumberFormatter.string(from:)` 不是线程安全的 ⇒ 共享实例必须自己加锁：
    /// `nonisolated(unsafe)` + `bankStyleLock`。加锁约 20ns，相对 1.06µs 的格式化开销可忽略。
    nonisolated(unsafe) private static let bankStyleSharedFormatter: NumberFormatter = bankStyleFormatter()
    nonisolated(unsafe) private static let bankStyleLock = NSLock()
    
    public static func bankStyleData(_ data: Double) -> String {
        let formatter = NumberFormatter()
        formatter.positiveFormat = "0.00;"
        return formatter.string(from: NSNumber(value: Double(data))) ?? ""
    }
    
    public nonisolated static func bankStyleDataThree(_ data: Double) -> String {
        bankStyleLock.lock()
        defer { bankStyleLock.unlock() }
        return bankStyleSharedFormatter.string(from: NSNumber(value: Double(data))) ?? ""
    }
    
    /// 分（整数）转银行风格金额。**可能被后台线程调用**（见 `bankStyleSharedFormatter` 的注释）。
    public nonisolated static func bankStyleDataThreeForCents(_ cents: Int) -> String {
        bankStyleLock.lock()
        defer { bankStyleLock.unlock() }
        return bankStyleSharedFormatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? ""
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
    /// 数值解析错误
    public enum FSNumberParseError: Error, CustomStringConvertible {
        case empty
        case invalidFormat
        case overflow

        public var description: String {
            switch self {
            case .empty:
                return "输入不能为空"
            case .invalidFormat:
                return "金额格式不正确"
            case .overflow:
                return "金额超出可表示范围"
            }
        }
    }

    /// 允许的格式：可选正负号 + 数字，兼容 ".5" 和 "3." 两种简写。
    /// 刻意拒绝：科学计数法("1e5")、inf、nan、千分位逗号("1,234.56")、全角数字、首尾以外的空格。
    ///
    /// 数字用显式 `[0-9]` 而不是 `\d`：`\d` 在 NSRegularExpression 里会匹配全角数字（"１２３"），
    /// 而 `Decimal(string:)` 解析不了全角数字，会导致校验放行、解析却失败的行为不一致。
    private static let fsNumberPattern = try! NSRegularExpression(pattern: "^[+-]?([0-9]+(\\.[0-9]*)?|\\.[0-9]+)$")

    /// 严格解析字符串 → 整数最小单位。
    ///
    /// 用 Decimal（十进制精确运算）解析，先乘 scale 再显式舍入，避免二进制浮点漂移。
    /// 例如 `try FSKit.numberStringToMinorUnits("8.165", scale: 100)` → 817；
    /// 同样输入走 Double 路线 `Int(round(8.165 * 100))` 只会得到 816，少 1 分。
    ///
    /// - Parameters:
    ///   - text: 待解析字符串，如 "3.4"
    ///   - scale: 最小单位倍数，按 ISO 4217 取。人民币 100（分）、日元 1、科威特第纳尔 1000
    /// - Throws: FSNumberParseError
    /// - Returns: 以最小单位为单位的整数
    public static func numberStringToMinorUnits(_ text: String?, scale: Int) throws -> Int {
        guard scale > 0 else { throw FSNumberParseError.invalidFormat }

        // 1. 规范化：trim 首尾空白
        let trimmed = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw FSNumberParseError.empty }

        // 2. 严格校验。必须做 —— Decimal(string:) 对 "1,234.56" 会「部分解析」成 1，而不是返回 nil
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        guard fsNumberPattern.firstMatch(in: trimmed, range: range) != nil else {
            throw FSNumberParseError.invalidFormat
        }

        // 3. 用 Decimal 解析，不用 Double
        guard var decimal = Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX")),
              decimal.isFinite else {
            throw FSNumberParseError.invalidFormat
        }

        // 4. 乘 scale：十进制精确运算，不漂移
        decimal *= Decimal(scale)

        // 5. 显式舍入到整数最小单位（.plain 四舍五入；.bankers 银行家舍入）
        var rounded = Decimal()
        NSDecimalRound(&rounded, &decimal, 0, .plain)

        // 6. 范围检查，避免超出 Int 表示范围
        guard rounded <= Decimal(Int.max), rounded >= Decimal(Int.min) else {
            throw FSNumberParseError.overflow
        }

        return NSDecimalNumber(decimal: rounded).intValue
    }

    /// 严格解析金额字符串 → 分。等价于 `numberStringToMinorUnits(text, scale: 100)`。
    public static func numberStringToCents(_ text: String?) throws -> Int {
        try numberStringToMinorUnits(text, scale: 100)
    }

    /// 字符串 → 分。解析失败返回 0（保持历史契约，调用方需自行判断结果是否为 0）。
    /// 内部已升级为 Decimal 精确运算，不会再出现 8.165 → 816 这类少 1 分的问题。
    public static func numberStringToTwoDecimalPlaces(_ floatString: String) -> Int {
        (try? numberStringToMinorUnits(floatString, scale: 100)) ?? 0
    }
    
    /// 字符串 → 小数点后 5 位整数（汇率场景）。解析失败返回 0。
    public static func numberStringToFiveDecimalPlaces(_ floatString: String) -> Int {
        (try? numberStringToMinorUnits(floatString, scale: FSFiveDecimalPlaces)) ?? 0
    }
    
    public static func floatToInt(_ floatString: String) -> Int {
        let decimal = NSDecimalNumber(string: floatString)
        return decimal.intValue
    }

    
    // MARK: - Account Number Validation
    /// 校验金额输入格式：只允许数字和一个小数点，小数点后最多 2 位。
    ///
    /// 注意：**空串返回 true**。空串表示"用户没有填写金额"，由调用方回退到默认金额
    /// （FSAccountManager / FSTracksController 依赖 `je > 0 ? je : 默认值` 这个行为），不要改成 false。
    public static func isFSAccountNumber(_ text: String) -> Bool {
        if text.isEmpty { return true }
        
        var pointNumber = 0
        var findPoint = false
        var afterPointNumber = 0
        var digitNumber = 0
        let validChars = Set("0123456789.")
        
        for char in text {
            guard validChars.contains(char) else { return false }
            
            if char == "." {
                pointNumber += 1
                findPoint = true
            } else {
                digitNumber += 1
                if findPoint {
                    afterPointNumber += 1
                }
            }
        }
        
        return digitNumber > 0 && pointNumber <= 1 && afterPointNumber <= 2
    }
    
    // MARK: - Growth Rate
    public nonisolated static func growthRate(_ number: Double, base: Double) -> Double {
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
    
    public static func dayMonthYear(forNumber number: Double) -> String {
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
            return String(format: "%.0f", Double(value) / 100)
        } else if value % 10 == 0 {
            return String(format: "%.1f", Double(value) / 100)
        } else {
            return String(format: "%.2f", Double(value) / 100)
        }
    }
    
    public static func showBetterFor3DigitInteger(_ value: Int) -> String {
        guard value != 0 else { return "0" }
        
        if value % 1000 == 0 {
            return String(format: "%.0f", Double(value) / 1000)
        } else if value % 100 == 0 {
            return String(format: "%.1f", Double(value) / 1000)
        } else if value % 10 == 0 {
            return String(format: "%.2f", Double(value) / 1000)
        } else {
            return String(format: "%.3f", Double(value) / 1000)
        }
    }
    
    public static func showByTenThousand(_ rest: Double, money: Bool) -> String {
        let absRest = abs(rest)
        if absRest < 100000 {
            return money ? bankStyleDataThree(rest) : "\(Int(ceil(rest)))"
        } else if absRest < 1000000 {
            return String(format: "%.2f万", rest / 10000.0)
        } else if absRest < 100000000 {
            return String(format: "%.0f万", rest / 10000.0)
        } else if absRest < 10000000000 {
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
        
    // MARK: - String Part Display
    public static func showStringPart(_ string: String, front: Int, tail: Int, placeholder: String = "***") -> String {
        guard string.count > front, string.count > tail else { return string }
        
        let frontStr = String(string.prefix(front))
        let lastStr = String(string.suffix(tail))
        return "\(frontStr)\(placeholder)\(lastStr)"
    }
    
    // MARK: - Window Scene
    public static func currentScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes
        for scene in scenes {
            if scene.activationState == .foregroundActive, let windowScene = scene as? UIWindowScene {
                return windowScene
            }
        }
        return scenes.first as? UIWindowScene
    }
        
    public static func screenOf(_ view: UIView) -> UIScreen {
        let screen = view.window?.windowScene?.screen
        if let screen {
            return screen
        }
        
        return UIScreen()
    }
    
    public static func digitalOnlyString(_ inputString: String?) -> String {
        guard let inputString = inputString, !inputString.isEmpty else { return "" }
        return inputString.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
    }
    
    public static func bundleFile(_ bundle: String?, name: String, ofType type: String) -> String? {
        let bundleObj = self.bundle(withName: bundle)
        return bundleObj?.path(forResource: name, ofType: type)
    }
    
    private static func bundle(withName bundleName: String?) -> Bundle? {
        let name = bundleName ?? "main"
        // `Bundle(for:)` 要一个 ObjC 类；`FSKit` 已是 enum，故用一个空类当锚点
        guard let bundlePath = Bundle(for: FSKitBundleToken.self).path(forResource: name, ofType: "bundle") else { return nil }
        return Bundle(path: bundlePath)
    }
    
    public static func feedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
            
    public static func deviceInfos() -> [[String: String]] {
        let device = UIDevice.current
        let screen = FSKit.currentScene()?.screen ?? UIScreen()
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
    public static func compressOriginalImage(_ image: UIImage, toMaxDataSizeKBytes size: Double) -> Data? {
        var maxQuality: Double = 0.9
        var data = image.jpegData(compressionQuality: 1.0)
        var dataKBytes = Double(data?.count ?? 0) / 1000.0
        var lastData = dataKBytes
        
        while dataKBytes > size && maxQuality > 0.01 {
            maxQuality -= 0.01
            data = image.jpegData(compressionQuality: maxQuality)
            dataKBytes = Double(data?.count ?? 0) / 1000.0
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
        guard value.isFinite else { return "0" }
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
                ret = String(format: "%.1f", Double(value) / FSDoubleFiveDecimalPlaces)
            } else {
                mode = value % 1000
                if mode == 0 {
                    ret = String(format: "%.2f", Double(value) / FSDoubleFiveDecimalPlaces)
                } else {
                    mode = value % 100
                    if mode == 0 {
                        ret = String(format: "%.3f", Double(value) / FSDoubleFiveDecimalPlaces)
                    } else {
                        mode = value % 10
                        if mode == 0 {
                            ret = String(format: "%.4f", Double(value) / FSDoubleFiveDecimalPlaces)
                        } else {
                            ret = String(format: "%.5f", Double(value) / FSDoubleFiveDecimalPlaces)
                        }
                    }
                }
            }
        }
        
        return ret
    }
    
}

// MARK: - GCD Helpers
//
// ★★ 2026-10-17：**凡在后台队列上执行的闭包参数，必须显式标 `@Sendable`。**
//
// 默认主隔离（`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`）下，非 Sendable 的
// `@escaping () -> Void` 参数会**继承调用方的隔离**（= 主隔离）。于是调用方在闭包体里
// 调用主隔离 API 是「编译期完全合法」的 —— 但该闭包实际被丢到 `DispatchQueue.global()`
// 上执行，运行期触发隔离断言：
//     `_dispatch_assert_queue_fail` ← `_swift_task_checkIsolatedSwift`
// **这类错误不产生任何编译警告**，只在运行期炸。
// 2026-10-17 启动崩溃即此：`FSAlertAPI.todoAlertsCount` → `todoDictionaries` → `FSDBMaster.querySQL`。
//
// 标 `@Sendable` 后编译器会强制这些闭包只碰 nonisolated API，把隐患一次性暴露为编译错误。
// 对照：`fs_dispatch_main_queue_async/sync` 的闭包都在主队列执行，保持非 Sendable 即可。
//
// 另：`FSUncheckedSendable` 包装保留 —— 让公共签名对外仍是 `@Sendable` 闭包，
// GCD 闭包直接捕获即可（`sending` 检查通过）。

/// 后台执行 `globalBlock`，随后回主队列执行 `mainBlock`。
/// `globalBlock` 只能使用 nonisolated API；需要触碰主隔离 API 的代码请挪进 `mainBlock`。
public func fs_dispatch_global_main_queue_async(globalBlock: @escaping @Sendable () -> Void,
                                                mainBlock: @escaping () -> Void) {
    let global = FSUncheckedSendable(globalBlock)
    let main = FSUncheckedSendable(mainBlock)
    DispatchQueue.global().async {
        global.value()
        DispatchQueue.main.async {
            main.value()
        }
    }
}

public func fs_dispatch_main_queue_async(_ block: @escaping () -> Void) {
    let box = FSUncheckedSendable(block)
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async { box.value() }
    }
}

public func fs_dispatch_main_queue_sync(_ block: @escaping () -> Void) {
    let box = FSUncheckedSendable(block)
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.sync { box.value() }
    }
}

/// 后台异步执行。闭包只能使用 nonisolated API（见本节顶部说明）。
public func fs_dispatch_global_queue_async(_ block: @escaping @Sendable () -> Void) {
    let box = FSUncheckedSendable(block)
    DispatchQueue.global().async { box.value() }
}

/// 后台同步执行。闭包只能使用 nonisolated API（见本节顶部说明）。
public func fs_dispatch_global_queue_sync(_ block: @escaping @Sendable () -> Void) {
    let box = FSUncheckedSendable(block)
    DispatchQueue.global().sync { box.value() }
}

// MARK: - Time Helpers
public nonisolated func fs_timeIntervalSince1970() -> TimeInterval {
    return Date().timeIntervalSince1970
}

public nonisolated func fs_integerTimeIntervalSince1970() -> Int {
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

/// `Bundle(for:)` 的锚点类
///
/// 2026-10-17：`FSKit` 从 `class : NSObject` 改成 `enum` 后不再满足 `AnyClass`，
/// 而 `bundle(withName:)` 要用 `Bundle(for:)` 定位资源包，故用这个空类当锚点。
private final class FSKitBundleToken {}
