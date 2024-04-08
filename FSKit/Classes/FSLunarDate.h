//
//  FSLunarDate.h
//  FSKit
//
//  Created by 扶冬冬 on 2024/4/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FSLunarDate : NSObject

@property (nonatomic, assign) NSInteger         year;
@property (nonatomic, assign) NSInteger         month;
@property (nonatomic, assign) NSInteger         day;

@property (nonatomic, assign) NSInteger         hour;
@property (nonatomic, assign) NSInteger         minute;
@property (nonatomic, assign) NSInteger         second;

+ (FSLunarDate *)lunarWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day;
+ (FSLunarDate *)lunarWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day hour:(NSInteger)hour minute:(NSInteger)minute second:(NSInteger)second;

@end

NS_ASSUME_NONNULL_END
