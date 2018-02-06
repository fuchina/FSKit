//
//  FSLocalNotification.m
//  FBRetainCycleDetector
//
//  Created by Guazi on 2018/2/5.
//

#import "FSLocalNotification.h"
#import <UserNotifications/UserNotifications.h>


@interface FSLocalNotification()<UNUserNotificationCenterDelegate>

@end

@implementation FSLocalNotification

- (instancetype)init{
    self = [super init];
    if (self) {
        [self preparatoryWork];
    }
    return self;
}

- (void)preparatoryWork{
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound +UNAuthorizationOptionBadge)
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                  
                              }];
        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            
        }];
    }
}

+ (void)cancelAllLocalNotification{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

@end
