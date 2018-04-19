//
//  FSModel.h
//  FSKit
//
//  Created by Guazi on 2017/8/25.
//  Copyright © 2017年 fudongdong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FSModel : NSObject

@property (nonatomic,strong) NSNumber   *aid;
@property (nonatomic,copy)   NSString   *time;
@property (nonatomic,copy)   NSString   *name;
@property (nonatomic,copy)   NSString   *one;
@property (nonatomic,copy)   NSString   *two;
@property (nonatomic,copy)   NSString   *thr;
@property (nonatomic,copy)   NSString   *four;
@property (nonatomic,copy)   NSString   *five;

- (void)fs_instanceMethod;

+ (void)fs_classMethod;
+ (void)fs_classMethod1:(NSString *)name;

@end
