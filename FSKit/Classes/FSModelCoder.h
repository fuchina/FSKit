//
//  FSModelCoder.h
//  ModuleOxfordUtils
//
//  Created by 扶冬冬 on 2024/3/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FSTriBool) {
    FSTriBoolUnknown = -1,          // 未知
    FSTriBoolNO = 0,                // 否
    FSTriBoolYES = 1,               // 是
};

@interface FSModelCoder : NSObject <NSCoding, NSSecureCoding>

// 服务端下发数据，不能包含自定义model
@property (nonatomic, strong) NSDictionary                      *meta;
@property (nonatomic, strong) NSArray                           *list;
@property (nonatomic, assign) FSTriBool                         boolean;
@property (nonatomic, copy)   NSString                          *string;

/**
 *  只支持iOS12及以后
 */
+ (NSError *)saveBoolean:(FSTriBool)boolean forKey:(NSString *)key;
+ (NSError *)saveString:(NSString *)string forKey:(NSString *)key;
+ (NSError *)saveList:(NSArray *)list forKey:(NSString *)key;
+ (NSError *)saveDictionary:(NSDictionary *)dictionary forKey:(NSString *)key;
+ (NSError *)save:(NSDictionary * _Nullable)meta list:(NSArray * _Nullable)list boolean:(FSTriBool)boolean string:(NSString * _Nullable)string forKey:(NSString *)key;

+ (FSModelCoder *)fetch:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
