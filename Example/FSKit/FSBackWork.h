//
//  FSBackWork.h
//  FSKit_Example
//
//  Created by Guazi on 2018/2/5.
//  Copyright © 2018年 fudongdong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FSBackWork : NSObject

+ (void)backWorkEvent:(void(^)(void))event;

@end
