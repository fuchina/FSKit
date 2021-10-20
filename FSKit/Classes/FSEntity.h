//
//  FSEntity.h
//  FSCompany
//
//  Created by 扶冬冬 on 2021/3/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FSEntity : NSObject

@property (nonatomic, readonly) NSDictionary    *meta; // 原数据

- (void)beforeInitWithDictionary;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

-(void)setAttributes:(NSDictionary *)dataDic;

- (void)afterSetAttributes;

+ (NSArray *)modelsFromDictionaries:(NSArray<NSDictionary *> *)dictionaries modelClass:(Class)CLS;

+ (id)modelWithDictionary:(NSDictionary *)m modelClass:(Class)CLS;

@end

NS_ASSUME_NONNULL_END
