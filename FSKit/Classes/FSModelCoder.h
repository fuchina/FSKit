//
//  FSModelCoder.h
//  ModuleOxfordUtils
//
//  Created by 扶冬冬 on 2024/3/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FSModelCoder : NSObject <NSCoding, NSSecureCoding>

// 服务端下发数据，不能是自定义model
@property (nonatomic, strong) NSDictionary                      *meta;
@property (nonatomic, strong) NSArray                           *list;

/**
 *  key是为了支持iOS12以前的系统，如果只支持iOS12及以后，key可以不传
 */
+ (NSError *)save:(NSDictionary * _Nullable)meta list:(NSArray * _Nullable)list filePath:(NSString *)filePath forKey:( NSString * _Nullable)key;

+ (FSModelCoder *)fetch:(NSString *)filePath key:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
