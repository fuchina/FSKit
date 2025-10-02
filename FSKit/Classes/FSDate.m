//
//  FSDate.m
//  FBRetainCycleDetector
//
//  Created by Fudongdong on 2018/4/3.
//

#import "FSDate.h"

@implementation FSDate

NSTimeInterval _fs_timeIntevalSince1970(void) {
    return [[NSDate date] timeIntervalSince1970];
}

NSInteger _fs_integerTimeIntevalSince1970(void) {
    return (NSInteger)_fs_timeIntevalSince1970();
}

+ (NSDate *)chinaDateByDate:(NSDate *)date {
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate:date];
    return [date dateByAddingTimeInterval: interval];
}

+ (NSInteger)daythOfYearForDate:(NSDate *)date {
    if (date == nil) {
        date = [NSDate date];
    }
    NSDateComponents *component = [self componentForDate:date];
    NSInteger year = component.year;
    NSInteger month = component.month;
    NSInteger day = component.day;
    int a[12]={31,28,31,30,31,30,31,31,30,31,30,31};
    int b[12]={31,29,31,30,31,30,31,31,30,31,30,31};
    int i,sum=0;
    if([self isLeapYear:(int)year])
        for(i=0;i<month-1;i++)
            sum+=b[i];
    else
        for(i=0;i<month-1;i++)
            sum+=a[i];
    sum+=day;
    return sum;
}

+ (BOOL)isLeapYear:(NSInteger)year {
    if ((year % 4  == 0 && year % 100 != 0)  || year % 400 == 0)
        return YES;
    else
        return NO;
}

+ (NSInteger)daysForMonth:(NSInteger)month year:(NSInteger)year {
    NSInteger days = 0;
    BOOL isLeapYear = [self isLeapYear:(int)year];
    BOOL isBigMonth = NO;
    if (month <=7) {
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
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekOfMonth | NSCalendarUnitWeekday | NSCalendarUnitWeekOfMonth | NSCalendarUnitWeekOfYear fromDate:date];
    return components;
}

+ (NSDate *)dateByString:(NSString *)str formatter:(NSString *)formatter {
    if (!([str isKindOfClass:NSString.class] && str.length)) {
        return nil;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:formatter ? : @"yyyy-MM-dd HH:mm:ss"];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];  // 必须写，否则date会为nil
    NSDate *date = [dateFormatter dateFromString:str];
    if (date == nil) {
        NSAssert([date isKindOfClass:NSDate.class], @"date创建失败");
    }
    return date;
}

+ (NSString *)stringWithDate:(NSDate *)date formatter:(NSString *)formatter {
    if (![date isKindOfClass:NSDate.class]) {
        return nil;
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:formatter?:@"yyyy-MM-dd HH:mm:ss"];
    return [dateFormatter stringFromDate:date];
}

+ (NSString *)ymdhsByTimeInterval:(NSTimeInterval)timeInterval {
    return [self ymdhsByTimeInterval: timeInterval formatter: nil];
}

+ (NSString *)ymdhsByTimeInterval:(NSTimeInterval)timeInterval formatter:(NSString *)formatter {
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970: timeInterval];
    NSString *time = [FSDate stringWithDate: date formatter: formatter];
    return time;
}

+ (NSString *)ymdhsByTimeIntervalString:(NSString *)timeInterval {
    NSTimeInterval t = [timeInterval doubleValue];
    return [self ymdhsByTimeInterval:t];
}

+ (NSDateComponents *)chineseDate:(NSDate *)date {
    if (![date isKindOfClass:NSDate.class]) {
        return nil;
    }
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierChinese];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:date];
    return components;
}

+ (NSArray<NSString *> *)chineseCalendarForDate:(NSDate *)date {
    if (![date isKindOfClass:NSDate.class]) {
        return nil;
    }
    NSDateComponents *components = [self chineseDate:date];
    return @[[self chineseCalendarYear:components.year - 1],[self chineseCalendarMonth:components.month - 1],[self chineseCalendarDay:components.day - 1]];
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

/**
 *  计算上次日期距离现在多久
 *
 *  @param lastTime    上次日期(需要和格式对应)
 *  @param format1     上次日期格式
 *  @param currentTime 最近日期(需要和格式对应)
 *  @param format2     最近日期格式
 *
 *  @return xx分钟前、xx小时前、xx天前
 */
+ (NSString *)timeIntervalFromLastTime:(NSString *)lastTime
                        lastTimeFormat:(NSString *)format1
                         ToCurrentTime:(NSString *)currentTime
                     currentTimeFormat:(NSString *)format2 {
    //上次时间
    NSDateFormatter *dateFormatter1 = [[NSDateFormatter alloc] init];
    dateFormatter1.dateFormat = format1;
    NSDate *lastDate = [dateFormatter1 dateFromString:lastTime];
    //当前时间
    NSDateFormatter *dateFormatter2 = [[NSDateFormatter alloc]init];
    dateFormatter2.dateFormat = format2;
    NSDate *currentDate = [dateFormatter2 dateFromString:currentTime];
    return [self timeIntervalFromLastTime:lastDate ToCurrentTime:currentDate];
}

+ (NSString *)timeIntervalFromLastTime:(NSDate *)lastTime ToCurrentTime:(NSDate *)currentTime {
    NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
    //上次时间
    NSDate *lastDate = [lastTime dateByAddingTimeInterval:[timeZone secondsFromGMTForDate:lastTime]];
    //当前时间
    NSDate *currentDate = [currentTime dateByAddingTimeInterval:[timeZone secondsFromGMTForDate:currentTime]];
    //时间间隔
    NSInteger intevalTime = [currentDate timeIntervalSinceReferenceDate] - [lastDate timeIntervalSinceReferenceDate];
    
    //秒、分、小时、天、月、年
    NSInteger minutes = intevalTime / 60;
    NSInteger hours = intevalTime / 60 / 60;
    NSInteger day = intevalTime / 60 / 60 / 24;
    NSInteger month = intevalTime / 60 / 60 / 24 / 30;
    NSInteger yers = intevalTime / 60 / 60 / 24 / 365;
    
    if (minutes <= 10) {
        return  @"刚刚";
    } else if (minutes < 60) {
        return [NSString stringWithFormat: @"%ld分钟前",(long)minutes];
    } else if (hours < 24) {
        return [NSString stringWithFormat: @"%ld小时前",(long)hours];
    } else if (day < 30) {
        return [NSString stringWithFormat: @"%ld天前",(long)day];
    } else if (month < 12) {
        NSDateFormatter * df =[[NSDateFormatter alloc] init];
        df.dateFormat = @"M月d日";
        NSString * time = [df stringFromDate:lastDate];
        return time;
    } else if (yers >= 1) {
        NSDateFormatter * df =[[NSDateFormatter alloc] init];
        df.dateFormat = @"yyyy年M月d日";
        NSString * time = [df stringFromDate:lastDate];
        return time;
    }
    return @"";
}

+ (BOOL)isTheSameDayA:(NSDate *)aDate b:(NSDate *)bDate {
    if (!([aDate isKindOfClass:NSDate.class] && [bDate isKindOfClass:NSDate.class])) {
        return NO;
    }
    NSDateComponents *f = [self componentForDate:aDate];
    NSDateComponents *s = [self componentForDate:bDate];
    return (f.year == s.year) && (f.month == s.month) && (f.day == s.day);
}

+ (NSInteger)theFirstSecondOfMonth:(NSDate *)date {
    return [self publicFunction:date str:^NSString *(NSDateComponents *c) {
        NSString *str = [[NSString alloc] initWithFormat:@"%d-%@-01 00:00:00",(int)c.year, [self twoChar:c.month]];
        return str;
    }];
}

+ (NSInteger)theLastSecondOfMonth:(NSDate *)date {
    return [self publicFunction:date str:^NSString *(NSDateComponents *c) {
        NSInteger days = [self daysForMonth:c.month year:c.year];
        NSString *str = [[NSString alloc] initWithFormat:@"%d-%@-%d 23:59:59",(int)c.year, [self twoChar:c.month],(int)days];
        return str;
    }];
}

+ (NSInteger)theFirstSecondOfDay:(NSDate *)date {
    return [self publicFunction:date str:^NSString *(NSDateComponents *c) {
        NSString *str = [[NSString alloc] initWithFormat:@"%d-%@-%@ 00:00:00",(int)c.year, [self twoChar:c.month], [self twoChar:c.day]];
        return str;
    }];
}

+ (NSInteger)theLastSecondOfDay:(NSDate *)date {
    return [self publicFunction:date str:^NSString *(NSDateComponents *c) {
        NSString *str = [[NSString alloc] initWithFormat:@"%d-%@-%@ 23:59:59",(int)c.year, [self twoChar:c.month], [self twoChar:c.day]];
        return str;
    }];
}

+ (NSInteger)theFirstSecondOfYear:(NSInteger)year {
    NSString *str = [[NSString alloc] initWithFormat:@"%@-01-01 00:00:00",@(year)];
    NSDate *result = [self dateByString:str formatter:nil];
    NSTimeInterval t = (NSInteger)[result timeIntervalSince1970];
    return t;
}

+ (NSInteger)theLastSecondOfYear:(NSInteger)year {
    NSString *str = [[NSString alloc] initWithFormat:@"%@-12-31 23:59:59",@(year)];
    NSDate *result = [self dateByString:str formatter:nil];
    NSTimeInterval t = (NSInteger)[result timeIntervalSince1970];
    return t;
}

+ (void)theFirstAndLastSecondOfYear:(NSInteger)year first:(NSInteger *)firstSecond last:(NSInteger *)lastSecond {
    NSString *first = [[NSString alloc] initWithFormat:@"%ld-01-01 00:00:00", year];
    NSString *last = [[NSString alloc] initWithFormat:@"%ld-12-31 23:59:59", year];
    NSDate *firstDate = [self dateByString:first formatter:nil];
    NSDate *lastDate = [self dateByString:last formatter:nil];
    *firstSecond = (NSInteger)[firstDate timeIntervalSince1970];
    *lastSecond = (NSInteger)[lastDate timeIntervalSince1970];
}

+ (NSInteger)publicFunction:(NSDate *)date str:(NSString *(^)(NSDateComponents *c))callback {
    if (![date isKindOfClass:NSDate.class]) {
        return 0;
    }
    NSDateComponents *c = [self componentForDate:date];
    NSString *str = callback(c);
    return [self secondsForComponents:c dateString:str];
}

+ (NSInteger)secondsForComponents:(NSDateComponents *)c dateString:(NSString *)dateString {
    if (![c isKindOfClass:NSDateComponents.class]) {
        return 0;
    }
    NSDate *result = [self dateByString:dateString formatter:nil];
    NSTimeInterval t = (NSInteger)[result timeIntervalSince1970];
    return t;
}

+ (NSArray<NSDate *> *)solarsForLunar:(NSInteger)year month:(NSInteger)month day:(NSInteger)day {
    NSString *string = [[NSString alloc] initWithFormat:@"%ld-%@-%@ 23:59:59", year, [self twoChar:month], [self twoChar:day]];
    NSDate *date = [self dateByString:string formatter:nil];
    NSDateComponents *lunarComponents = [self chineseDate:date];
    BOOL found = (lunarComponents.month == month) && (lunarComponents.day == day);
    if (found == YES) {
        NSAssert(YES == NO, @"这种情况应该不会出现");
        return @[date];
    }
    
    // 农历日期会超过阳历日期吗？假设不会，那就往后找
    NSMutableArray *dates = [[NSMutableArray alloc] init];
    while (found == NO) {
        date = [NSDate dateWithTimeInterval:86400 sinceDate:date];  //  后一天
        lunarComponents = [self chineseDate:date];
        found = (lunarComponents.month == month) && (lunarComponents.day == day);
        
        if (found) {  // 再往后找32天，处理农历闰月的情况
            [dates addObject:date];
            
            // 下一个月是不是闰月，农历每个月有30天或29天，取35天跳到下一个月
            NSInteger addDays = 35;
            if (day > 20) {
                addDays = 15;
            }
            NSDate *runDate = [NSDate dateWithTimeInterval:86400 * addDays sinceDate:date];
            lunarComponents = [self chineseDate:runDate];
            if (lunarComponents.isLeapMonth) {  // 是闰月，需要找到该闰月日期下的阳历
                runDate = [NSDate dateWithTimeInterval: 86400 * (day - lunarComponents.day) sinceDate: runDate];
                
                [dates addObject:runDate];
            }
        }
    }
    
    return dates.copy;
}

+ (NSDate *)usefulSolarForLunar:(NSInteger)year month:(NSInteger)month day:(NSInteger)day forDateTimestamp:(NSTimeInterval)timestamp {
    NSArray *dates = [self solarsForLunar:year month:month day:day];
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
    NSDateComponents *lunarComponents = [self chineseDate:solar];
    NSDateComponents *solarComponents = [self componentForDate:solar];
    NSInteger year = solarComponents.year;
    if (lunarComponents.month > solarComponents.month) {
        year = year - 1;
    }
    
    FSLunarDate *lunar = [FSLunarDate lunarWithYear: year month: lunarComponents.month day: lunarComponents.day hour: lunarComponents.hour minute: lunarComponents.minute second: lunarComponents.second];
    return lunar;
    
//    NSString *string = [[NSString alloc] initWithFormat:@"%ld-%@-%@ 12:00:00",year, [self twoChar:lunarComponents.month], [self twoChar:lunarComponents.day]];
//    NSDate *date = [FSDate dateByString:string formatter:nil];
//    return date;
}

+ (NSString *)ChineseWeek:(NSInteger)week {
    static NSArray *weeks = nil;
    if (!weeks) {
        weeks = @[@"",@"星期日",@"星期一",@"星期二",@"星期三",@"星期四",@"星期五",@"星期六"];;
    }
    return weeks[week];
}

+ (NSDate *)date {
    NSDate *date = [NSDate date];
    return date;
}

+ (NSDate *)theLastYearThisDay:(NSDateComponents *)components {
    NSInteger lastYearYear = components.year - 1;
    NSInteger lastYearMonth = components.month;
    NSInteger lastYearDay = components.day;
    if (components.month == 2 && components.day == 29) {
        BOOL isLeapYear = [FSDate isLeapYear:lastYearYear];
        if (!isLeapYear) {
            lastYearDay = 28;
        }
    }
    NSString *lastYearString = [[NSString alloc] initWithFormat:@"%ld-%@-%@", lastYearYear, [self twoChar:lastYearMonth], [self twoChar:lastYearDay]];
    NSDate *lastYearThisDay = [FSDate dateByString:lastYearString formatter:@"yyyy-MM-dd 00:00:00"];
    return lastYearThisDay;
}

+ (NSString *)twoChar:(NSInteger)value {
    if (value < 10) {
        return [[NSString alloc] initWithFormat:@"0%ld", value];
    }
    return [[NSString alloc] initWithFormat:@"%ld", value];
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
        [result appendFormat: @"%ld年", (long)years];
    }
    if (days > 0) {
        [result appendFormat: @"%ld天", (long)days];
    }
    if (hours > 0) {
        [result appendFormat: @"%ld时", (long)hours];
    }
    if (minutes > 0) {
        [result appendFormat: @"%ld分", (long)minutes];
    }
    if (seconds > 0 || result.length == 0) { // 确保即使所有单位都为0时，也至少显示"0秒"
        [result appendFormat: @"%ld秒", (long)seconds];
    }
    
    return [result copy];
}

@end
