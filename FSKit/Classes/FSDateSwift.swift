//
//  FSDateSwift.swift
//  FSKit
//
//  Created by pwrd on 2026/1/26.
//

import Foundation

public class FSDateSwift {
    
    public static func componentForDate(date: Date) -> DateComponents {
        
        var calendar = Calendar(identifier: .gregorian)     // UTC
        
        /**
         *  NSTimeZone.localTimeZone，即设备当前时区，可以不写，因为方法会隐含；写上是为了增加可读性。
         *  比如中国是UTC+8，所以在英国下午15点59分59秒（不考虑冬令时夏令时），中国已经23点59分59秒了，也就是下一秒中国就要跨天了。
         */
        calendar.timeZone = TimeZone.current
        
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .weekOfMonth, .weekday, .weekOfMonth, .weekOfYear], from: date)
                
        return components
    }
    
    public static func theFirstSecondOfDay(date: Date) -> Int {
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let t = calendar.startOfDay(for: date)
        let time = t.timeIntervalSince1970
        return Int(time)
    }
    
    public static func theLastSecondOfDay(date: Date) -> Int {
        
        var com = FSDateSwift.componentForDate(date: date)
        com.setValue(23, for: .hour)
        com.setValue(59, for: .minute)
        com.setValue(59, for: .second)
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let endOfDay = calendar.date(from: com)
        
        guard let time = endOfDay?.timeIntervalSince1970 else { return 0 }
        
        return Int(time)
    }
    
    public static func stringWithDate(date: Date?, formatter: String?) -> String {
        if date == nil {
            return ""
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatter ?? "yyyy-MM-dd HH:mm:ss"
        
        //  这里应该隐含了   dateFormatter.timeZone = NSTimeZone.localTimeZone;
        dateFormatter.timeZone = TimeZone.current
        let v = dateFormatter.string(from: date!)
        return v
    }
    
}
