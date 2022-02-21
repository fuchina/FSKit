//
//  FSEntity.m
//  fusuhehua.com
//
//  Created by 扶冬冬 on 2021/3/15.
//

#import "FSEntity.h"
#import <objc/runtime.h>

@implementation FSEntity

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        [self setAttributes:dictionary];
    }
    return self;
}

+ (NSArray *)modelsFromDictionaries:(NSArray<NSDictionary *> *)dictionaries modelClass:(Class)CLS {
    BOOL isArray = [dictionaries isKindOfClass:NSArray.class];
    if (isArray) {
        // 如果元素不是NSDictionary，直接返回
        BOOL isCLS = YES;
        for (NSDictionary *m in dictionaries) {
            if (![m isKindOfClass:CLS]) {
                isCLS = NO;
                break;
            }
        }
        if (isCLS) {
            return dictionaries;
        }
    }
    
    NSMutableArray *results = nil;
    if (isArray) {
        results = [[NSMutableArray alloc] initWithCapacity:dictionaries.count];
        for (int x = 0; x < dictionaries.count; x ++) {
            NSDictionary *m = dictionaries[x];
            id model = [self modelWithDictionary:m modelClass:CLS];
            [results addObject:model];
        }
    }
    return results.copy;
}

+ (id)modelWithDictionary:(NSDictionary *)m modelClass:(Class)CLS {
    id obj = nil;
    if ([m isKindOfClass:NSDictionary.class]) {
        obj = [[CLS alloc] init];
        if ([obj isKindOfClass:FSEntity.class]) {
            FSEntity *model = (FSEntity *)obj;
            [model setAttributes:m];
        }
    }
    return obj;
}

- (void)setAttributes:(NSDictionary *)dataDic {
    if (![dataDic isKindOfClass:NSDictionary.class]) {
        return;
    }
    _meta = dataDic;
        
    NSArray *allKeys = [dataDic allKeys];
    for (NSString *key in allKeys) {
        NSObject *value = [dataDic objectForKey:key];
        [self setValue:value forKey:key];
    }
    
    [self afterSetAttributes];
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

- (void)afterSetAttributes {}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
#if DEBUG
    NSLog(@"HEBaseModel set UndefinedKey (%@ - %@)", key, value);
#endif
}

@end
