//
//  FSEntity.h
//  fusuhehua.com
//
//  Created by 扶冬冬 on 2021/3/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FSTriBool) {
    FSTriBoolUnknown = -1,          // 未知
    FSTriBoolNO = 0,                // 否
    FSTriBoolYES = 1,               // 是
};

@interface FSEntity : NSObject

/**
 *  元数据，还可以通过其判断dictionary是否为NSDictianry，判断属性是否已经被设置
 */
@property (nonatomic, readonly) NSDictionary    *meta;  // 原数据

/**
 *  比如一个映射的属性需要设置默认值，就可以调用这个方法
 */
- (void)beforeSetProperties;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary config:(nullable void(^)(id each_model))config;

- (void)setProperties:(NSDictionary *)dictionary;

- (void)afterSetProperties;

+ (id)modelWithDictionary:(NSDictionary *)m modelClass:(Class)CLS;
+ (id)modelWithDictionary:(NSDictionary *)m modelClass:(Class)CLS config:(nullable void(^)(id each_model))config;

+ (NSMutableArray *)modelsFromDictionaries:(NSArray<NSDictionary *> *)dictionaries modelClass:(Class)CLS;
+ (NSMutableArray *)modelsFromDictionaries:(NSArray<NSDictionary *> *)dictionaries modelClass:(Class)CLS config:(nullable void(^)(id model))config;

@end

NS_ASSUME_NONNULL_END
