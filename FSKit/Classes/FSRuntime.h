//
//  FSRuntime.h
//  FBRetainCycleDetector
//
//  Created by Guazi on 2018/3/13.
//

#import <Foundation/Foundation.h>

@interface FSRuntime : NSObject

// 获取类所有的属性
+ (NSArray<NSString *> *)propertiesForClass:(Class)className;

// 将字符串转化为Set方法，如将"name"转化为setName方法
+ (SEL)setterSELWithAttibuteName:(NSString*)attrName;

// 给对象的属性赋值
+ (void)setValue:(id)value forPropertyName:(NSString *)name ofObject:(id)object;

// 根据字典key-value给对象的同名属性赋值
+ (id)entity:(Class)Entity dic:(NSDictionary *)dic;

// 获取属性的值
+ (id)valueForGetSelectorWithPropertyName:(NSString *)name object:(id)instance;  // 获取实例的属性的值

// 将一个对象转换为字典
+ (NSDictionary *)dictionaryWithObject:(id)model;

// 获取类的类方法
+ (NSArray<NSString *> *)classMethodListOfClass:(Class)cls;

@end
