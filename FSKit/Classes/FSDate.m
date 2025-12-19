//
//  FSDate.m
//  FBRetainCycleDetector
//
//  Created by Fudongdong on 2018/4/3.
//

#import "FSDate.h"

@implementation FSDate

NSTimeInterval _fs_timeIntevalSince1970(void) {
    return [NSDate.date timeIntervalSince1970];
}

NSInteger _fs_integerTimeIntevalSince1970(void) {
    return (NSInteger)_fs_timeIntevalSince1970();
}

+ (BOOL)isLeapYear:(NSInteger)year {
    if ((year % 4  == 0 && year % 100 != 0)  || year % 400 == 0) {
        return YES;
    }
    
    return NO;
}

+ (NSInteger)daysForMonth:(NSInteger)month year:(NSInteger)year {
    NSInteger days = 0;
    BOOL isLeapYear = [self isLeapYear: year];
    BOOL isBigMonth = NO;
    if (month <= 7) {
        if (month % 2 == 1) {
            isBigMonth = YES;
        }
    } else {
        if (month % 2 == 0) {
            isBigMonth = YES;
        }
    }
    
    if (isLeapYear) {
        if (month == 2) {
            days = 29;
        } else if (isBigMonth) {
            days = 31;
        } else {
            days = 30;
        }
    } else {
        if (month == 2) {
            days = 28;
        } else if (isBigMonth) {
            days = 31;
        } else {
            days = 30;
        }
    }
    return days;
}

+ (NSDateComponents *)componentForDate:(NSDate *)date {
    
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier: NSCalendarIdentifierGregorian];  // UTC
    
    /**
     *  NSTimeZone.localTimeZone，即设备当前时区，可以不写，因为方法会隐含；写上是为了增加可读性。
     *  比如中国是UTC+8，所以在英国下午15点59分59秒（不考虑冬令时夏令时），中国已经23点59分59秒了，也就是下一秒中国就要跨天了。
     */
    calendar.timeZone = NSTimeZone.localTimeZone;
    
    NSDateComponents *components = [calendar components: NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekOfMonth | NSCalendarUnitWeekday | NSCalendarUnitWeekOfMonth | NSCalendarUnitWeekOfYear fromDate: date];
    
    return components;
}

+ (NSDate *)dateByString:(NSString *)str formatter:(NSString *)formatter {
    if (!([str isKindOfClass: NSString.class] && str.length)) {
        return nil;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: formatter ? : @"yyyy-MM-dd HH:mm:ss"];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier: @"en_US_POSIX"];  // GPT说这样才是靠谱的
//    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier: @"zh_CN"];  // 必须写，否则date会为nil
    NSDate *date = [dateFormatter dateFromString: str];
    
    if (date == nil) {
        NSAssert([date isKindOfClass: NSDate.class], @"date创建失败");
    }
    
    return date;
}

+ (NSString *)stringWithDate:(NSDate *)date formatter:(NSString *)formatter {
    if (![date isKindOfClass: NSDate.class]) {
        return nil;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: formatter ? : @"yyyy-MM-dd HH:mm:ss"];
    //  这里应该隐含了   dateFormatter.timeZone = NSTimeZone.localTimeZone;
    dateFormatter.timeZone = NSTimeZone.localTimeZone;
    
    return [dateFormatter stringFromDate: date];
}

+ (NSDateComponents *)chineseDate:(NSDate *)date {
    if (![date isKindOfClass: NSDate.class]) {
        return nil;
    }
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierChinese];
    // 同上，肯定隐含了     calendar.timeZone = NSTimeZone.localTimeZone;
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate: date];
    return components;
}

+ (NSArray<NSString *> *)chineseCalendarForDate:(NSDate *)date {
    if (![date isKindOfClass: NSDate.class]) {
        return nil;
    }
    NSDateComponents *components = [self chineseDate: date];
    return @[[self chineseCalendarYear: components.year - 1], [self chineseCalendarMonth: components.month - 1], [self chineseCalendarDay: components.day - 1]];
}

+ (NSString *)chineseCalendarYear:(NSInteger)index {
    NSArray *chineseYears = @[@"甲子",  @"乙丑",  @"丙寅",  @"丁卯",  @"戊辰",  @"己巳",  @"庚午",  @"辛未",  @"壬申",  @"癸酉",
                              @"甲戌",   @"乙亥",  @"丙子",  @"丁丑",  @"戊寅",  @"己卯",  @"庚辰",  @"辛己",  @"壬午",  @"癸未",
                              @"甲申",   @"乙酉",  @"丙戌",  @"丁亥",  @"戊子",  @"己丑",  @"庚寅",  @"辛卯",  @"壬辰",  @"癸巳",
                              @"甲午",   @"乙未",  @"丙申",  @"丁酉",  @"戊戌",  @"己亥",  @"庚子",  @"辛丑",  @"壬寅",  @"癸丑",
                              @"甲辰",   @"乙巳",  @"丙午",  @"丁未",  @"戊申",  @"己酉",  @"庚戌",  @"辛亥",  @"壬子",  @"癸丑",
                              @"甲寅",   @"乙卯",  @"丙辰",  @"丁巳",  @"戊午",  @"己未",  @"庚申",  @"辛酉",  @"壬戌",  @"癸亥"];
    return chineseYears[index % chineseYears.count];
}

+ (NSString *)chineseCalendarMonth:(NSInteger)index {
    NSArray *chineseYears = @[@"正月", @"二月", @"三月", @"四月", @"五月", @"六月", @"七月", @"八月",@"九月", @"十月", @"冬月", @"腊月"];
    return chineseYears[index % chineseYears.count];
}

+ (NSString *)chineseCalendarDay:(NSInteger)index {
    NSArray *chineseYears = @[  @"初一", @"初二", @"初三", @"初四", @"初五", @"初六", @"初七", @"初八", @"初九", @"初十",
                                @"十一", @"十二", @"十三", @"十四", @"十五", @"十六", @"十七", @"十八", @"十九", @"二十",
                                @"廿一", @"廿二", @"廿三", @"廿四", @"廿五", @"廿六", @"廿七", @"廿八", @"廿九", @"三十"];
    return chineseYears[index % chineseYears.count];
}

+ (BOOL)isTheSameDayA:(NSDate *)aDate b:(NSDate *)bDate {
    if (!([aDate isKindOfClass: NSDate.class] && [bDate isKindOfClass: NSDate.class])) {
        return NO;
    }
    
    NSDateComponents *f = [self componentForDate: aDate];
    NSDateComponents *s = [self componentForDate: bDate];
    return (f.year == s.year) && (f.month == s.month) && (f.day == s.day);
}

+ (NSInteger)theFirstSecondOfMonth:(NSDate *)date {
    NSCalendar *calendar = NSCalendar.currentCalendar;
    calendar.timeZone = NSTimeZone.localTimeZone;
    
    NSDateComponents *com =  [self componentForDate: date];
    com.day = 1;
    com.hour = 0;
    com.minute = 0;
    com.second = 0;
    
    NSDate *endOfDay = [calendar dateFromComponents: com];
    NSInteger time = endOfDay.timeIntervalSince1970;
    
    return time;
}

+ (NSInteger)theLastSecondOfMonth:(NSDate *)date {
    NSCalendar *calendar = NSCalendar.currentCalendar;
    calendar.timeZone = NSTimeZone.localTimeZone;
    
    NSDateComponents *com =  [self componentForDate: date];
    NSInteger days = [self daysForMonth: com.month year: com.year];

    com.day = days;
    com.hour = 23;
    com.minute = 59;
    com.second = 59;
    
    NSDate *endOfDay = [calendar dateFromComponents: com];
    NSInteger time = endOfDay.timeIntervalSince1970;
    
    return time;
}

+ (NSInteger)theFirstSecondOfDay:(NSDate *)date {
    NSCalendar *calendar = NSCalendar.currentCalendar;
    calendar.timeZone = NSTimeZone.localTimeZone;
    
    NSDate *t = [calendar startOfDayForDate: date];
    NSInteger time = t.timeIntervalSince1970;
    return time;
}

+ (NSInteger)theLastSecondOfDay:(NSDate *)date {
    
    NSDateComponents *com = [self componentForDate: date];
    
    [com setHour: 23];
    [com setMinute: 59];
    [com setSecond: 59];
    
    NSCalendar *calendar = NSCalendar.currentCalendar;
    calendar.timeZone = NSTimeZone.localTimeZone;
    
    NSDate *endOfDay = [calendar dateFromComponents: com];
    NSInteger time = endOfDay.timeIntervalSince1970;
    
    return time;
}

+ (NSInteger)theFirstSecondOfYear:(NSInteger)year {
    
    NSDateComponents *yearComponents = [[NSDateComponents alloc] init];
    yearComponents.year = year;
    yearComponents.month = 1;
    yearComponents.day = 1;
    yearComponents.hour = 0;
    yearComponents.minute = 0;
    yearComponents.second = 0;
    
    NSCalendar *calendar = NSCalendar.currentCalendar;
    calendar.timeZone = NSTimeZone.localTimeZone;

    NSDate *firstSecondOfYear = [calendar dateFromComponents: yearComponents];
    NSTimeInterval t = [firstSecondOfYear timeIntervalSince1970];
    return t;
}

+ (NSInteger)theLastSecondOfYear:(NSInteger)year {
    
    NSDateComponents *yearComponents = [[NSDateComponents alloc] init];
    yearComponents.year = year;
    yearComponents.month = 12;
    yearComponents.day = 31;
    yearComponents.hour = 23;
    yearComponents.minute = 59;
    yearComponents.second = 59;
    
    NSCalendar *calendar = NSCalendar.currentCalendar;
    calendar.timeZone = NSTimeZone.localTimeZone;

    NSDate *firstSecondOfYear = [calendar dateFromComponents: yearComponents];
    NSTimeInterval t = [firstSecondOfYear timeIntervalSince1970];
    return t;
}

+ (NSArray<NSDate *> *)solarsForLunar:(NSInteger)year month:(NSInteger)month day:(NSInteger)day {
    NSString *string = [[NSString alloc] initWithFormat: @"%ld-%@-%@ 23:59:59", year, [self twoChar: month], [self twoChar: day]];
    NSDate *date = [self dateByString: string formatter: nil];
    NSDateComponents *lunarComponents = [self chineseDate: date];
    BOOL found = (lunarComponents.month == month) && (lunarComponents.day == day);
    if (found == YES) {
        NSAssert(YES == NO, @"这种情况应该不会出现");
        return @[date];
    }
    
    // 农历日期会超过阳历日期吗？假设不会，那就往后找
    NSMutableArray *dates = [[NSMutableArray alloc] init];
    while (found == NO) {
        date = [NSDate dateWithTimeInterval: 86400 sinceDate: date];  //  后一天
        lunarComponents = [self chineseDate:date];
        found = (lunarComponents.month == month) && (lunarComponents.day == day);
        
        if (found) {  // 再往后找32天，处理农历闰月的情况
            [dates addObject: date];
            
            // 下一个月是不是闰月，农历每个月有30天或29天，取35天跳到下一个月
            NSInteger addDays = 35;
            if (day > 20) {
                addDays = 15;
            }
            NSDate *runDate = [NSDate dateWithTimeInterval: 86400 * addDays sinceDate: date];
            lunarComponents = [self chineseDate: runDate];
            if (lunarComponents.isLeapMonth) {  // 是闰月，需要找到该闰月日期下的阳历
                runDate = [NSDate dateWithTimeInterval: 86400 * (day - lunarComponents.day) sinceDate: runDate];
                
                [dates addObject: runDate];
            }
        }
    }
    
    return dates.copy;
}

+ (NSDate *)usefulSolarForLunar:(NSInteger)year month:(NSInteger)month day:(NSInteger)day forDateTimestamp:(NSTimeInterval)timestamp {
    NSArray *dates = [self solarsForLunar: year month: month day: day];
    if (dates.count == 1) {
        return dates.firstObject;
    }
    
    NSDate *first = dates.firstObject;
    NSInteger tf = [first timeIntervalSince1970];
    if (tf > timestamp) {
        return first;
    }
    NSDate *last = dates.lastObject;
    return last;
}

+ (FSLunarDate *)lunarDateForSolar:(NSDate *)solar {
    NSDateComponents *lunarComponents = [self chineseDate: solar];
    NSDateComponents *solarComponents = [self componentForDate: solar];
    NSInteger year = solarComponents.year;
    if (lunarComponents.month > solarComponents.month) {
        year = year - 1;
    }
    
    FSLunarDate *lunar = [FSLunarDate lunarWithYear: year month: lunarComponents.month day: lunarComponents.day hour: lunarComponents.hour minute: lunarComponents.minute second: lunarComponents.second];
    return lunar;
}

+ (NSString *)ChineseWeek:(NSInteger)week {
    static NSArray *weeks = nil;
    if (!weeks) {
        weeks = @[@"", @"星期日", @"星期一", @"星期二", @"星期三", @"星期四", @"星期五", @"星期六"];
    }
    return weeks[week];
}

+ (NSDate *)date {
    NSDate *date = NSDate.date;
    return date;
}

+ (NSDate *)theLastYearThisDay:(NSDateComponents *)components {
    NSInteger lastYearYear = components.year - 1;
    NSInteger lastYearMonth = components.month;
    NSInteger lastYearDay = components.day;
    if (components.month == 2 && components.day == 29) {
        BOOL isLeapYear = [FSDate isLeapYear: lastYearYear];
        if (!isLeapYear) {
            lastYearDay = 28;
        }
    }
    
    NSString *lastYearString = [[NSString alloc] initWithFormat: @"%ld-%@-%@", lastYearYear, [self twoChar: lastYearMonth], [self twoChar: lastYearDay]];
    NSDate *lastYearThisDay = [FSDate dateByString: lastYearString formatter: @"yyyy-MM-dd 00:00:00"];
    return lastYearThisDay;
}

+ (NSString *)twoChar:(NSInteger)value {
    if (value < 10) {
        return [[NSString alloc] initWithFormat: @"0%ld", value];
    }
    return [[NSString alloc] initWithFormat: @"%ld", value];
}

+ (CGFloat)daysForSeconds:(CGFloat)seconds {
    CGFloat daySecond = 86400.0f;
    return seconds / daySecond;
}

+ (NSString *)yearDaysForSeconds:(CGFloat)seconds {
    NSInteger days = ceil([self daysForSeconds: seconds]);
    NSInteger years = days / 365;
    NSInteger rest_days = days % 365;
    if (years > 0) {
        NSString *days_show = [[NSString alloc] initWithFormat: @"%ld年%ld天", years, rest_days];
        return days_show;
    } else {
        NSString *days_show = [[NSString alloc] initWithFormat: @"%ld天", rest_days];
        return days_show;
    }
}

+ (NSString *)formatTimeDuration:(NSTimeInterval)totalSeconds {
    if (totalSeconds < 0) {
        return @"-";
    }
    
    // 定义时间常量
    const NSInteger secondsPerMinute = 60;
    const NSInteger secondsPerHour = 60 * secondsPerMinute;   // 3600
    const NSInteger secondsPerDay = 24 * secondsPerHour;      // 86400
    const NSInteger secondsPerYear = 365 * secondsPerDay;     // 31536000
    
    // 计算各时间单位
    NSInteger years = totalSeconds / secondsPerYear;
    NSInteger days = ((NSInteger)totalSeconds % secondsPerYear) / secondsPerDay;
    NSInteger hours = ((NSInteger)totalSeconds % secondsPerDay) / secondsPerHour;
    NSInteger minutes = ((NSInteger)totalSeconds % secondsPerHour) / secondsPerMinute;
    NSInteger seconds = (NSInteger)totalSeconds % secondsPerMinute;
    
    // 使用可变字符串拼接结果
    NSMutableString *result = [NSMutableString string];
    
    if (years > 0) {
        [result appendFormat: @"%ld年", years];
    }
    if (days > 0) {
        [result appendFormat: @"%ld天", days];
    }
    if (hours > 0) {
        [result appendFormat: @"%ld时", hours];
    }
    if (minutes > 0) {
        [result appendFormat: @"%ld分", minutes];
    }
    if (seconds > 0 || result.length == 0) { // 确保即使所有单位都为0时，也至少显示"0秒"
        [result appendFormat: @"%ld秒", seconds];
    }
    
    return result.copy;
}

@end
