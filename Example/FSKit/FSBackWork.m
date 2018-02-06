//
//  FSBackWork.m
//  FSKit_Example
//
//  Created by Guazi on 2018/2/5.
//  Copyright © 2018年 topchuan. All rights reserved.
//

#import "FSBackWork.h"

@implementation FSBackWork

+ (void)backWorkEvent:(void(^)(void))event{
    __block UIBackgroundTaskIdentifier identifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (event) {
            event();
        }
        [[UIApplication sharedApplication] endBackgroundTask:identifier];
        identifier = UIBackgroundTaskInvalid;
    }];
}

@end
