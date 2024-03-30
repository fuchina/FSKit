//
//  FSEntity.m
//  fusuhehua.com
//
//  Created by 扶冬冬 on 2021/3/15.
//

#import "FSEntity.h"

@interface FSEntity ()

@property (nonatomic, weak) void (^base_model_xxx_config_before)(id self_object);
@property (nonatomic, weak) void (^base_model_xxx_config_after)(id self_object);

@end

@implementation FSEntity

- (void)beforeSetProperties {}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    return [self initWithDictionary:dictionary beforeSetProperties: nil afterSetProperties: nil];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary beforeSetProperties:(nullable void (^)(id _Nonnull))beforeSetProperties afterSetProperties:(nullable void (^)(id _Nonnull))afterSetProperties {
    self = [super init];
    if (self) {
        [self beforeSetProperties];
        _base_model_xxx_config_before = beforeSetProperties;
        _base_model_xxx_config_after = afterSetProperties;
        [self setProperties:dictionary];
    }
    return self;
}

+ (NSMutableArray *)modelsFromDictionaries:(NSArray<NSDictionary *> *)dictionaries modelClass:(Class)CLS {
    return [self modelsFromDictionaries:dictionaries modelClass:CLS beforeSetProperties: nil afterSetProperties: nil];
}

+ (NSMutableArray *)modelsFromDictionaries:(NSArray<NSDictionary *> *)dictionaries modelClass:(Class)CLS beforeSetProperties:(nullable void (^)(id _Nonnull))beforeSetProperties afterSetProperties:(nullable void (^)(id _Nonnull))afterSetProperties {
    BOOL isArray = [dictionaries isKindOfClass:NSArray.class];
    NSMutableArray *results = nil;
    if (isArray) {
        results = [[NSMutableArray alloc] initWithCapacity:dictionaries.count];
        for (int x = 0; x < dictionaries.count; x ++) {
            NSDictionary *m = dictionaries[x];
            id model = [self modelWithDictionary:m modelClass:CLS beforeSetProperties: beforeSetProperties afterSetProperties: afterSetProperties];
            [results addObject:model];
        }
    }
    return results;
}

+ (id)modelWithDictionary:(NSDictionary *)m modelClass:(Class)CLS {
    return [self modelWithDictionary:m modelClass:CLS beforeSetProperties: nil afterSetProperties: nil];
}

+ (id)modelWithDictionary:(NSDictionary *)m modelClass:(Class)CLS beforeSetProperties:(nullable void (^)(id _Nonnull))beforeSetProperties afterSetProperties:(nullable void (^)(id _Nonnull))afterSetProperties {
    id obj = nil;
    if ([m isKindOfClass:NSDictionary.class]) {
        obj = [[CLS alloc] init];
        if ([obj isKindOfClass:FSEntity.class]) {
            FSEntity *model = (FSEntity *)obj;
            model.base_model_xxx_config_before = beforeSetProperties;
            model.base_model_xxx_config_after = afterSetProperties;
            [model setProperties:m];
        }
    }
    return obj;
}

- (void)setProperties:(NSDictionary *)dataDic {
    if (![dataDic isKindOfClass:NSDictionary.class]) {
        return;
    }
    _meta = dataDic;
        
    NSArray *allKeys = [dataDic allKeys];
    for (NSString *key in allKeys) {
        NSObject *value = [dataDic objectForKey:key];
        [self setValue:value forKey:key];
    }
    
    if (_base_model_xxx_config_before) {
        _base_model_xxx_config_before(self);
    }
    
    [self afterSetProperties];
    
    if (_base_model_xxx_config_after) {
        _base_model_xxx_config_after(self);
    }
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([value isKindOfClass:NSArray.class] || [value isKindOfClass:NSDictionary.class] || [value isKindOfClass:NSString.class]) {
        
    } else {
        if ([value isEqual: NSNull.null]) {
            value = nil;
        }
//        else {
//            NSObject *obj = (NSObject *)value;
//            value = obj.description;
//        }
    }
    
    [super setValue: value forKey: key];
}

- (void)afterSetProperties {}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
#if DEBUG
    NSLog(@"%@ set UndefinedKey (%@ - %@)", self.class, key, value);
#endif
}

@end
