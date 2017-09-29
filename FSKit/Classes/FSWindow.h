//
//  FSWindow.h
//  Expand
//
//  Created by Fudongdong on 2017/9/29.
//  Copyright © 2017年 china. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SINGLE_ONCE(A)   \
+ (instancetype)allocWithZone:(struct _NSZone *)zone{ \
if(!_w){\
        static dispatch_once_t onceToken;\
        dispatch_once(&onceToken, ^{\
            A = [super allocWithZone:zone];\
        });\
    }\
    return A;\
}\
+ (id)copyWithZone:(struct _NSZone *)zone{\
    if(!_w){\
        static dispatch_once_t onceToken;\
        dispatch_once(&onceToken, ^{\
            A = [super copyWithZone:zone];\
        });\
    }\
    return A;\
}\
- (instancetype)init{\
    @synchronized(self) {\
        self = [super init];\
    }\
    return self;\
}\


@interface FSWindow : UIWindow

+ (instancetype)sharedInstance;

+ (void)showView:(UIView *)view;
+ (void)presentViewController:(UIViewController *)controller animated:(BOOL)animated completion:(void (^)(void))completion;
+ (void)dismiss;

@end
