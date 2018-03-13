//
//  FSRuntime.m
//  FBRetainCycleDetector
//
//  Created by Guazi on 2018/3/13.
//

#import "FSRuntime.h"
#import <objc/runtime.h>

@implementation FSRuntime

// 获取类所有的属性
+ (NSArray<NSString *> *)propertiesForClass:(Class)className{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(className, &propertyCount);
    for (unsigned int i = 0; i < propertyCount; ++i) {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);//获取属性名字
        NSString *nameToString = [[NSString alloc] initWithFormat:@"%s",name];
        [array addObject:nameToString];
    }
    free(properties);
    return array;
}

+ (SEL)setterSELWithAttibuteName:(NSString*)attrName{
    BOOL check = [attrName isKindOfClass:[NSString class]] && attrName.length;
    if (!check) {
        return nil;
    }
    NSString *capital = [[attrName substringToIndex:1] uppercaseString];
    NSString *setterSelStr = [NSString stringWithFormat:@"set%@%@:",capital,[attrName substringFromIndex:1]];
    return NSSelectorFromString(setterSelStr);
}

+ (void)setValue:(id)value forPropertyName:(NSString *)name ofObject:(id)object{
    BOOL check = [name isKindOfClass:[NSString class]] && name.length;
    if (!check) {
        return;
    }
    SEL setterSelector = [self setterSELWithAttibuteName:name];
    if ([object respondsToSelector:setterSelector]) {
        [object performSelector:setterSelector onThread:[NSThread currentThread] withObject:value waitUntilDone:YES];
    }
}

+ (id)entity:(Class)Entity dic:(NSDictionary *)dic{
    if (Entity == nil) {
        return nil;
    }
    id instance = [[Entity alloc] init];
    BOOL check = [dic isKindOfClass:[NSDictionary class]] && dic.count;
    if (check) {
        NSArray *keys = [dic allKeys];
        for (NSString *key in keys) {
            id value = dic[key];
            [self setValue:value forPropertyName:key ofObject:instance];
        }
    }
    return instance;
}

+ (id)valueForGetSelectorWithPropertyName:(NSString *)name object:(id)instance{
    if (!([name isKindOfClass:[NSString class]]) && name.length) {
        return nil;
    }
    return [instance valueForKey:name];
}

+ (NSDictionary *)dictionaryWithObject:(id)model{
    NSArray<NSString *> *ps = [self propertiesForClass:[model class]];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithCapacity:ps.count];
    for (NSString *p in ps) {
        NSString *value = [self valueForGetSelectorWithPropertyName:p object:model];
        if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]) {
            [dic setObject:value forKey:p];
        }else{
            [dic setObject:@"" forKey:p];
        }
    }
    return [dic copy];
}

+ (NSArray<NSString *> *)classMethodListOfClass:(Class)cls{
    if (cls == nil) {
        return nil;
    }
    BOOL isMeta = class_isMetaClass(cls);
    Class meta = cls;
    if (!isMeta) {
        const char *ccls = [NSStringFromClass(cls) UTF8String];
        meta = objc_getMetaClass(ccls);
        isMeta = class_isMetaClass(meta);
    }
    if (isMeta) {
        unsigned int methCount = 0;
        Method *meths = class_copyMethodList(meta, &methCount);
        NSMutableArray *list = [[NSMutableArray alloc] init];
        for (int x = 0; x < methCount; x ++) {
            Method meth = meths[x];
            SEL sel = method_getName(meth);
            NSString *n = NSStringFromSelector(sel);
            if (n) {
                [list addObject:n];
            }
//            const char *n = sel_getName(sel);
        }
        free(meths);
        if (list.count) {
            return [list copy];            
        }
    }
    return nil;
}

@end
