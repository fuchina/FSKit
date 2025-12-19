//
//  FSDate.h
//  FBRetainCycleDetector
//
//  Created by Fudongdong on 2018/4/3.
//

/**
 *  在地球的任何地方，UTC时间秒数都是一样的
 *  拿到UTC的时间秒数，在北京（+8）表达出来比伦敦（+0）要快8个小时，所以很多方法都隐含了本地时区
 */

#import <Foundation/Foundation.h>
#import "FSLunarDate.h"

@interface FSDate : NSObject

NSTimeInterval _fs_timeIntevalSince1970(void);
NSInteger _fs_integerTimeIntevalSince1970(void);

// 该月第一秒/最后一秒
+ (NSInteger)theFirstSecondOfMonth:(NSDate *)date;
+ (NSInteger)theLastSecondOfMonth:(NSDate *)date;
// 该天第一秒/最后一秒
+ (NSInteger)theFirstSecondOfDay:(NSDate *)date;
+ (NSInteger)theLastSecondOfDay:(NSDate *)date;

// 该年第一秒/最后一秒
+ (NSInteger)theFirstSecondOfYear:(NSInteger)year;
+ (NSInteger)theLastSecondOfYear:(NSInteger)year;

// 是否为闰年
+ (BOOL)isLeapYear:(NSInteger)year;

// 根据年月计算当月有多少天
+ (NSInteger)daysForMonth:(NSInteger)month year:(NSInteger)year;

+ (NSDateComponents *)componentForDate:(NSDate *)date;

+ (NSDate *)dateByString:(NSString *)str formatter:(NSString *)formatter;
+ (NSString *)stringWithDate:(NSDate *)date formatter:(NSString *)formatter;
+ (NSString *)ymdhsByTimeInterval:(NSTimeInterval)timeInterval;
+ (NSString *)ymdhsByTimeIntervalString:(NSString *)timeInterval;
+ (NSString *)ymdhsByTimeInterval:(NSTimeInterval)timeInterval formatter:(NSString *)formatter;

// 除了年不是当年数字，可能为60一甲子数组的索引+1，月日是当月日
+ (NSDateComponents *)chineseDate:(NSDate *)date;

// 获取农历日期，数组共三个元素，分别是农历的年月日
+ (NSArray<NSString *> *)chineseCalendarForDate:(NSDate *)date;

// 同一天
+ (BOOL)isTheSameDayA:(NSDate *)aDate b:(NSDate *)bDate;


/**
 *  1.先根据农历计算一个阳历，这样就比较相近
 *  2.阳历肯定比农历大，那就是往后找
 *  3.计算每个阳历的农历，如果农历的月跟日正好都对上，就是找到了
 *  4.在农历有闰月时，会得到2个日期，就返回最近的那个
 *
 * 农历转阳历，2021年1月16日设计，这个方法依赖 chineseDate： 方法的正确性
 * @param year 农历年
 * @param month 农历月
 * @param day 农历日
 * @return 返回阳历日期
 */
+ (NSArray<NSDate *> *)solarsForLunar:(NSInteger)year month:(NSInteger)month day:(NSInteger)day;
/**
 *  较近的阳历日期
 */
+ (NSDate *)usefulSolarForLunar:(NSInteger)year month:(NSInteger)month day:(NSInteger)day forDateTimestamp:(NSTimeInterval)timestamp;

/**
 *  1.先根据系统方法获取到农历的月日
 *  2.如果农历的月比阳历的月大，年就减1
 *
 * 阳历转农历，2021年1月16日设计，这个方法依赖 chineseDate： 方法的正确性
 * @param solar 阳历日期
 * @return 返回农历日期
 */
+ (FSLunarDate *)lunarDateForSolar:(NSDate *)solar;

/**
 * 参数为dateComponents的weekday
 */
+ (NSString *)ChineseWeek:(NSInteger)week;

/**
 *  获取日期
 */
+ (NSDate *)date;

/**
 *  前一年的这一天
 */
+ (NSDate *)theLastYearThisDay:(NSDateComponents *)components;

/**
 *  将数字转换为至少2位的字符
 */
+ (NSString *)twoChar:(NSInteger)value;

/**
 *  将秒换算为多少天
 */
+ (CGFloat)daysForSeconds:(CGFloat)seconds;

/**
 *  X年Y天
 */
+ (NSString *)yearDaysForSeconds:(CGFloat)seconds;

/**
 *  X年Y天Z时M分S秒
 */
+ (NSString *)formatTimeDuration:(NSTimeInterval)totalSeconds;

@end
