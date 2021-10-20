//
//  HEBaseModel.m
//  OxfordLibrary
//
//  Created by 扶冬冬 on 2021/3/15.
//

#import "FSEntity.h"
#import <objc/runtime.h>

@implementation FSEntity

- (instancetype)initWithDictionary:(NSDictionary *)dictionary{
    self = [super init];
    if (self) {
        [self beforeInitWithDictionary];
        if ([dictionary isKindOfClass:NSDictionary.class]) {
            [self setAttributes:dictionary];
        }
    }
    return self;
}

- (void)beforeInitWithDictionary {}

-(NSDictionary*)attributeMapDictionary{
    return nil;
}

- (SEL)getSetterSelWithAttibuteName:(NSString*)attributeName{
    NSString *capital = [[attributeName substringToIndex:1] uppercaseString];
    NSString *setterSelStr = [NSString stringWithFormat:@"set%@%@:",capital,[attributeName substringFromIndex:1]];
    return NSSelectorFromString(setterSelStr);
}

- (NSString *)customDescription{
    return nil;
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
    return results;
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

- (NSString *)description{
    NSMutableString *attrsDesc = [NSMutableString stringWithCapacity:100];
    NSDictionary *attrMapDic = [self attributeMapDictionary];
    NSEnumerator *keyEnum = [attrMapDic keyEnumerator];
    id attributeName;
    
    while ((attributeName = [keyEnum nextObject])) {
        SEL getSel = NSSelectorFromString(attributeName);
        if ([self respondsToSelector:getSel]) {
            NSMethodSignature *signature = [self methodSignatureForSelector:getSel];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:self];
            [invocation setSelector:getSel];
            NSObject *valueObj = nil;
            [invocation invoke];
            [invocation getReturnValue:&valueObj];
            //            ITTDINFO(@"attributeName %@ value %@", attributeName, valueObj);
            if (valueObj) {
                [attrsDesc appendFormat:@" [%@=%@] ",attributeName, valueObj];
                //[valueObj release];
            }else {
                [attrsDesc appendFormat:@" [%@=nil] ",attributeName];
            }
            
        }
    }
    
    NSString *customDesc = [self customDescription];
    NSString *desc;
    
    if (customDesc && [customDesc length] > 0 ) {
        desc = [NSString stringWithFormat:@"%@:{%@,%@}",self.class,attrsDesc,customDesc];
    }else {
        desc = [NSString stringWithFormat:@"%@:{%@}",self.class,attrsDesc];
    }
    return desc;
}

- (void)setAttributes:(NSDictionary *)dataDic{
    _meta = dataDic;
    
    NSDictionary *attrMapDic = [self attributeMapDictionary];
    if (attrMapDic == nil) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:[dataDic count]];
        for (NSString *key in dataDic) {
            [dic setValue:key forKey:key];
        }
        attrMapDic = dic;
    }
    
    NSMutableArray *handleArray = [[NSMutableArray alloc] initWithArray:[self propertiesList]];
    NSEnumerator *keyEnum = [attrMapDic keyEnumerator];
    id attributeName;
    while ((attributeName = [keyEnum nextObject])) {
        SEL sel = [self getSetterSelWithAttibuteName:attributeName];
        if ([self respondsToSelector:sel]) {
            NSString *dataDicKey = [attrMapDic objectForKey:attributeName];
            NSObject *value = [dataDic objectForKey:dataDicKey];
            if ([value isKindOfClass:NSArray.class] || [value isKindOfClass:NSDictionary.class] || [value isKindOfClass:NSString.class]) {
            }else{
                if (value == nil || [value isEqual:NSNull.null]) {
//                     value = @"";
                    value = nil;
                }else{
                    value = value.description;// nil变量调用description仍然为nil
                }
            }
            id attributeValue = value;
            [self performSelector:sel onThread:NSThread.currentThread withObject:attributeValue waitUntilDone:YES];
            
            if ([handleArray containsObject:attributeName]) {
                [handleArray removeObject:attributeName];
            }
        }
    }
    
    // 没必要赋值nil
//    if (handleArray) { // 未赋值的参数赋值nil
//        for (int x = 0; x < handleArray.count; x ++) {
//            NSString *nameString = handleArray[x];
//            if (nameString) {
//                SEL sel = [self getSetterSelWithAttibuteName:nameString];
//                if ([self respondsToSelector:sel]) {
//                    [self performSelector:sel onThread:NSThread.currentThread
//                               withObject:nil   //类型不匹配，不会崩溃
//                            waitUntilDone:YES];
//                }
//            }
//        }
//    }
    
    [self afterSetAttributes];
}

- (void)afterSetAttributes {}

- (id)initWithCoder:(NSCoder *)decoder{
    if( self = [super init] ){
        NSDictionary *attrMapDic = [self attributeMapDictionary];
        if (attrMapDic == nil) {
            return self;
        }
        NSEnumerator *keyEnum = [attrMapDic keyEnumerator];
        id attributeName;
        while ((attributeName = [keyEnum nextObject])) {
            SEL sel = [self getSetterSelWithAttibuteName:attributeName];
            if ([self respondsToSelector:sel]) {
                id obj = [decoder decodeObjectForKey:attributeName];
                [self performSelector:sel onThread:NSThread.currentThread withObject:obj waitUntilDone:YES];
            }
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder{
    NSDictionary *attrMapDic = [self attributeMapDictionary];
    if (attrMapDic == nil) {
        return;
    }
    
    NSEnumerator *keyEnum = [attrMapDic keyEnumerator];
    id attributeName;
    while ((attributeName = [keyEnum nextObject])) {
        SEL getSel = NSSelectorFromString(attributeName);
        if ([self respondsToSelector:getSel]) {
            NSMethodSignature *signature = nil;
            signature = [self methodSignatureForSelector:getSel];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:self];
            [invocation setSelector:getSel];
            NSObject *valueObj = nil;
            [invocation invoke];
            [invocation getReturnValue:&valueObj];
            
            if (valueObj) {
                [encoder encodeObject:valueObj forKey:attributeName];
            }
        }
    }
}

- (NSData*)getArchivedData{
    return [NSKeyedArchiver archivedDataWithRootObject:self];
}

- (NSArray *)propertiesList{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(self.class, &propertyCount);
    
    for (unsigned int i = 0; i < propertyCount; ++i) {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);//获取属性名字
        
        NSString *nameToString = [[NSString alloc] initWithFormat:@"%s",name];
        [array addObject:nameToString];
    }
    return array;
}

@end
