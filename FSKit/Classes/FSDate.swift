//
//  FSDateCore.swift
//  FSKit
//
//  Translated from Objective-C to Swift
//

import Foundation
import UIKit

// MARK: - FSLunarDate
public class FSLunarDate: NSObject {
    public var year: Int = 0
    public var month: Int = 0
    public var day: Int = 0
    public var hour: Int = 0
    public var minute: Int = 0
    public var second: Int = 0
    
    public static func lunar(year: Int, month: Int, day: Int) -> FSLunarDate {
        return lunar(year: year, month: month, day: day, hour: 0, minute: 0, second: 0)
    }
    
    public static func lunar(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) -> FSLunarDate {
        let lunar = FSLunarDate()
        lunar.year = year
        lunar.month = month
        lunar.day = day
        lunar.hour = hour
        lunar.minute = minute
        lunar.second = second
        return lunar
    }
}

// MARK: - FSDate
public class FSDate: NSObject {
    
    // MARK: - Leap Year
    public static func isLeapYear(_ year: Int) -> Bool {
        return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }
    
    // MARK: - Days in Month
    public static func daysForMonth(_ month: Int, year: Int) -> Int {
        let isLeapYear = self.isLeapYear(year)
        let isBigMonth: Bool
        
        if month <= 7 {
            isBigMonth = month % 2 == 1
        } else {
            isBigMonth = month % 2 == 0
        }
        
        if month == 2 {
            return isLeapYear ? 29 : 28
        } else if isBigMonth {
            return 31
        } else {
            return 30
        }
    }
    
    // MARK: - Date Components
    public static func components(_ date: Date) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .weekOfMonth, .weekday, .weekOfYear], from: date)
    }
    
    // MARK: - Date Formatting
    public static func date(byString str: String?, formatter: String? = nil) -> Date? {
        guard let str = str, !str.isEmpty else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatter ?? "yyyy-MM-dd HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.date(from: str)
    }
    
    public static func string(with date: Date?, formatter: String? = nil) -> String {
        guard let date = date else { return "" }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatter ?? "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = .current
        return dateFormatter.string(from: date)
    }
    
    // MARK: - Chinese Calendar
    public static func chineseDate(_ date: Date?) -> DateComponents? {
        guard let date = date else { return nil }
        let calendar = Calendar(identifier: .chinese)
        return calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    }
    
    public static func chineseCalendar(for date: Date?) -> [String]? {
        guard let date = date, let components = chineseDate(date) else { return nil }
        return [
            chineseCalendarYear(components.year! - 1),
            chineseCalendarMonth(components.month! - 1),
            chineseCalendarDay(components.day! - 1)
        ]
    }
    
    private static func chineseCalendarYear(_ index: Int) -> String {
        let chineseYears = [
            "甲子", "乙丑", "丙寅", "丁卯", "戊辰", "己巳", "庚午", "辛未", "壬申", "癸酉",
            "甲戌", "乙亥", "丙子", "丁丑", "戊寅", "己卯", "庚辰", "辛己", "壬午", "癸未",
            "甲申", "乙酉", "丙戌", "丁亥", "戊子", "己丑", "庚寅", "辛卯", "壬辰", "癸巳",
            "甲午", "乙未", "丙申", "丁酉", "戊戌", "己亥", "庚子", "辛丑", "壬寅", "癸丑",
            "甲辰", "乙巳", "丙午", "丁未", "戊申", "己酉", "庚戌", "辛亥", "壬子", "癸丑",
            "甲寅", "乙卯", "丙辰", "丁巳", "戊午", "己未", "庚申", "辛酉", "壬戌", "癸亥"
        ]
        return chineseYears[index % chineseYears.count]
    }
    
    private static func chineseCalendarMonth(_ index: Int) -> String {
        let months = ["正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "冬月", "腊月"]
        return months[index % months.count]
    }
    
    private static func chineseCalendarDay(_ index: Int) -> String {
        let days = [
            "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
            "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
            "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
        ]
        return days[index % days.count]
    }
    
    // MARK: - Same Day Check
    public static func isTheSameDay(_ aDate: Date?, _ bDate: Date?) -> Bool {
        guard let aDate = aDate, let bDate = bDate else { return false }
        let f = components(aDate)
        let s = components(bDate)
        return f.year == s.year && f.month == s.month && f.day == s.day
    }

    
    // MARK: - First/Last Second of Month
    public static func theFirstSecondOfMonth(_ date: Date) -> Int {
        var calendar = Calendar.current
        calendar.timeZone = .current
        
        var com = components(date)
        com.day = 1
        com.hour = 0
        com.minute = 0
        com.second = 0
        
        guard let endOfDay = calendar.date(from: com) else { return 0 }
        return Int(endOfDay.timeIntervalSince1970)
    }
    
    public static func theLastSecondOfMonth(_ date: Date) -> Int {
        var calendar = Calendar.current
        calendar.timeZone = .current
        
        var com = components(date)
        let days = daysForMonth(com.month!, year: com.year!)
        
        com.day = days
        com.hour = 23
        com.minute = 59
        com.second = 59
        
        guard let endOfDay = calendar.date(from: com) else { return 0 }
        return Int(endOfDay.timeIntervalSince1970)
    }
    
    // MARK: - First/Last Second of Day
    public static func theFirstSecondOfDay(_ date: Date) -> Int {
        var calendar = Calendar.current
        calendar.timeZone = .current
        let startOfDay = calendar.startOfDay(for: date)
        return Int(startOfDay.timeIntervalSince1970)
    }
    
    public static func theLastSecondOfDay(_ date: Date) -> Int {
        var calendar = Calendar.current
        calendar.timeZone = .current
        
        var com = components(date)
        com.hour = 23
        com.minute = 59
        com.second = 59
        
        guard let endOfDay = calendar.date(from: com) else { return 0 }
        return Int(endOfDay.timeIntervalSince1970)
    }
    
    // MARK: - First/Last Second of Year
    public static func theFirstSecondOfYear(_ year: Int) -> Int {
        var calendar = Calendar.current
        calendar.timeZone = .current
        
        var components = DateComponents()
        components.year = year
        components.month = 1
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        guard let date = calendar.date(from: components) else { return 0 }
        return Int(date.timeIntervalSince1970)
    }
    
    public static func theLastSecondOfYear(_ year: Int) -> Int {
        var calendar = Calendar.current
        calendar.timeZone = .current
        
        var components = DateComponents()
        components.year = year
        components.month = 12
        components.day = 31
        components.hour = 23
        components.minute = 59
        components.second = 59
        
        guard let date = calendar.date(from: components) else { return 0 }
        return Int(date.timeIntervalSince1970)
    }
    
    // MARK: - Lunar/Solar Conversion
    public static func solars(forLunar year: Int, month: Int, day: Int) -> [Date] {
        
        let string = "\(year)-\(twoChar(month))-\(twoChar(day)) 23:59:59"
        guard var date = date(byString: string, formatter: nil) else { return [] }
        
        guard let lunarComponents = chineseDate(date) else { return [] }
        var found = (lunarComponents.month == month) && (lunarComponents.day == day)
        
        var dates: [Date] = []
        while !found {
            date = date.addingTimeInterval(86400)
            guard let newLunarComponents = chineseDate(date) else { break }
            found = (newLunarComponents.month == month) && (newLunarComponents.day == day)
            
            if found {
                dates.append(date)
                
                let addDays = day > 20 ? 15 : 35
                var runDate = date.addingTimeInterval(Double(86400 * addDays))
                guard let runLunarComponents = chineseDate(runDate) else { break }
                
                if runLunarComponents.isLeapMonth == true {
                    runDate = runDate.addingTimeInterval(Double(86400 * (day - (runLunarComponents.day ?? 0))))
                    dates.append(runDate)
                }
            }
        }
        
        return dates
    }
    
    public static func usefulSolar(forLunar year: Int, month: Int, day: Int, forDateTimestamp timestamp: TimeInterval) -> Date? {
        let dates = solars(forLunar: year, month: month, day: day)
        guard !dates.isEmpty else { return nil }
        
        if dates.count == 1 { return dates.first }
        
        if let first = dates.first, first.timeIntervalSince1970 > timestamp {
            return first
        }
        return dates.last
    }
    
    public static func lunarDate(forSolar solar: Date) -> FSLunarDate? {
        guard let lunarComponents = chineseDate(solar) else { return nil }
        let solarComponents = components(solar)
        
        var year = solarComponents.year ?? 0
        if (lunarComponents.month ?? 0) > (solarComponents.month ?? 0) {
            year -= 1
        }
        
        return FSLunarDate.lunar(
            year: year,
            month: lunarComponents.month ?? 0,
            day: lunarComponents.day ?? 0,
            hour: lunarComponents.hour ?? 0,
            minute: lunarComponents.minute ?? 0,
            second: lunarComponents.second ?? 0
        )
    }
    
    // MARK: - Chinese Week
    public static func chineseWeek(_ week: Int) -> String {
        let weeks = ["", "星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"]
        guard week >= 0 && week < weeks.count else { return "" }
        return weeks[week]
    }
    
    // MARK: - Current Date
    public static func date() -> Date {
        return Date()
    }
    
    // MARK: - Last Year This Day
    public static func theLastYearThisDay(_ components: DateComponents) -> Date? {
        
        guard let year = components.year,
              let month = components.month,
              var day = components.day else {
            
            return nil
        }
        
        var lastYear = year - 1
        
        if month == 2 && day == 29 {
            if !isLeapYear(lastYear) {
                day = 28
            }
        }
        
        let lastYearString = "\(lastYear)-\(twoChar(month))-\(twoChar(day))"
        return date(byString: lastYearString, formatter: "yyyy-MM-dd 00:00:00")
    }
    
    // MARK: - Two Char
    public static func twoChar(_ value: Int) -> String {
        return value < 10 ? "0\(value)" : "\(value)"
    }
    
    // MARK: - Days for Seconds
    public static func daysForSeconds(_ seconds: CGFloat) -> CGFloat {
        return seconds / 86400.0
    }
    
    public static func yearDaysForSeconds(_ seconds: CGFloat) -> String {
        let days = Int(ceil(daysForSeconds(seconds)))
        let years = days / 365
        let restDays = days % 365
        
        if years > 0 {
            return "\(years)年\(restDays)天"
        } else {
            return "\(restDays)天"
        }
    }
    
    // MARK: - Format Time Duration
    public static func formatTimeDuration(_ totalSeconds: TimeInterval) -> String {
        guard totalSeconds >= 0 else { return "-" }
        
        let secondsPerMinute = 60
        let secondsPerHour = 3600
        let secondsPerDay = 86400
        let secondsPerYear = 31536000
        
        let total = Int(totalSeconds)
        let years = total / secondsPerYear
        let days = (total % secondsPerYear) / secondsPerDay
        let hours = (total % secondsPerDay) / secondsPerHour
        let minutes = (total % secondsPerHour) / secondsPerMinute
        let seconds = total % secondsPerMinute
        
        var result = ""
        if years > 0 { result += "\(years)年" }
        if days > 0 { result += "\(days)天" }
        if hours > 0 { result += "\(hours)时" }
        if minutes > 0 { result += "\(minutes)分" }
        if seconds > 0 || result.isEmpty { result += "\(seconds)秒" }
        
        return result
    }
    
    // MARK: - China Date
    public static func chinaDateByDate(_ date: Date) -> Date {
        let zone = TimeZone.current
        let interval = zone.secondsFromGMT(for: date)
        return date.addingTimeInterval(TimeInterval(interval))
    }
    
    // MARK: - Day of Year
    public static func daythOfYearForDate(_ date: Date?) -> Int {
        let date = date ?? Date()
        let component = component(for: date)
        guard let year = component.year, let month = component.month, let day = component.day else { return 0 }
        
        let a = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        let b = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        var sum = 0
        
        if isLeapYear(year) {
            for i in 0..<(month-1) {
                sum += b[i]
            }
        } else {
            for i in 0..<(month-1) {
                sum += a[i]
            }
        }
        sum += day
        return sum
    }
    
    // MARK: - Time Interval
    public static func timeIntervalFromLastTime(_ lastTime: String, lastTimeFormat format1: String, ToCurrentTime currentTime: String, currentTimeFormat format2: String) -> String {
        // 上次时间
        let dateFormatter1 = DateFormatter()
        dateFormatter1.dateFormat = format1
        guard let lastDate = dateFormatter1.date(from: lastTime) else { return "" }
        
        // 当前时间
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = format2
        guard let currentDate = dateFormatter2.date(from: currentTime) else { return "" }
        
        return timeIntervalFromLastTime(lastDate, ToCurrentTime: currentDate)
    }
    
    public static func timeIntervalFromLastTime(_ lastTime: Date, ToCurrentTime currentTime: Date) -> String {
        let timeZone = TimeZone.current
        // 上次时间
        let lastDate = lastTime.addingTimeInterval(TimeInterval(timeZone.secondsFromGMT(for: lastTime)))
        // 当前时间
        let currentDate = currentTime.addingTimeInterval(TimeInterval(timeZone.secondsFromGMT(for: currentTime)))
        // 时间间隔
        let intevalTime = Int(currentDate.timeIntervalSinceReferenceDate - lastDate.timeIntervalSinceReferenceDate)
        
        // 秒、分、小时、天、月、年
        let minutes = intevalTime / 60
        let hours = intevalTime / 60 / 60
        let day = intevalTime / 60 / 60 / 24
        let month = intevalTime / 60 / 60 / 24 / 30
        let yers = intevalTime / 60 / 60 / 24 / 365
        
        if minutes <= 10 {
            return "刚刚"
        } else if minutes < 60 {
            return "\(minutes)分钟前"
        } else if hours < 24 {
            return "\(hours)小时前"
        } else if day < 30 {
            return "\(day)天前"
        } else if month < 12 {
            let df = DateFormatter()
            df.dateFormat = "M月d日"
            let time = df.string(from: lastDate)
            return time
        } else if yers >= 1 {
            let df = DateFormatter()
            df.dateFormat = "yyyy年M月d日"
            let time = df.string(from: lastDate)
            return time
        }
        return ""
    }
    
    // MARK: - Public Function
    private static func publicFunction(_ date: Date, str callback: (DateComponents) -> String) -> Int {
        let c = component(for: date)
        let str = callback(c)
        
        let result = FSDate.date(byString: str)
        guard result != nil else {
            return 0
        }
                
        let t = Int(result!.timeIntervalSince1970)
        return t
    }
    
}
