//
//  FSEntity.m
//  fusuhehua.com
//
//  Created by 扶冬冬 on 2021/3/15.
//

#import "FSEntity.h"

@interface FSEntity ()

@property (nonatomic, weak) void (^config)(id self_object);

@end

@implementation FSEntity

- (void)beforeSetProperties {}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    return [self initWithDictionary:dictionary config:nil];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary config:(void(^)(id model))config {
    self = [super init];
    if (self) {
        [self beforeSetProperties];
        _config = config;
        [self setProperties:dictionary];
    }
    return self;
}

+ (NSMutableArray *)modelsFromDictionaries:(NSArray<NSDictionary *> *)dictionaries modelClass:(Class)CLS {
    return [self modelsFromDictionaries:dictionaries modelClass:CLS config:nil];
}

+ (NSMutableArray *)modelsFromDictionaries:(NSArray<NSDictionary *> *)dictionaries modelClass:(Class)CLS config:(nullable void(^)(id model))config {
    BOOL isArray = [dictionaries isKindOfClass:NSArray.class];
    NSMutableArray *results = nil;
    if (isArray) {
        results = [[NSMutableArray alloc] initWithCapacity:dictionaries.count];
        for (int x = 0; x < dictionaries.count; x ++) {
            NSDictionary *m = dictionaries[x];
            id model = [self modelWithDictionary:m modelClass:CLS config:config];
            [results addObject:model];
        }
    }
    return results;
}

+ (id)modelWithDictionary:(NSDictionary *)m modelClass:(Class)CLS {
    return [self modelWithDictionary:m modelClass:CLS config:nil];
}

+ (id)modelWithDictionary:(NSDictionary *)m modelClass:(Class)CLS config:(nullable void(^)(id model))config {
    id obj = nil;
    if ([m isKindOfClass:NSDictionary.class]) {
        obj = [[CLS alloc] init];
        if ([obj isKindOfClass:FSEntity.class]) {
            FSEntity *model = (FSEntity *)obj;
            model.config = config;
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
    
    if (_config) {
        _config(self);
    }
    
    NSArray *allKeys = [dataDic allKeys];
    for (NSString *key in allKeys) {
        NSObject *value = [dataDic objectForKey:key];
        [self setValue:value forKey:key];
    }
    
    [self afterSetProperties];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([value isKindOfClass:NSArray.class] || [value isKindOfClass:NSDictionary.class] || [value isKindOfClass:NSString.class]) {
        
    } else {
        if (value == nil || [value isEqual:NSNull.null]) {
            value = nil;
        } else {
            NSObject *obj = (NSObject *)value;
            value = obj.description;
        }
    }
    [super setValue:value forKey:key];
}

- (void)afterSetProperties {}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
#if DEBUG
    NSLog(@"FSEntity set UndefinedKey (%@ - %@)", key, value);
#endif
}

@end
