//
//  UIScrollView+PullupRefresh.m
//  FSKit_Example
//
//  Created by Guazi on 2018/2/28.
//  Copyright © 2018年 topchuan. All rights reserved.
//

#import "UIScrollView+PullupRefresh.h"
#import <objc/runtime.h>

static NSString *_FS_KVO_KEY_contentOffset = @"contentOffset";
static NSString *_FS_KVO_KEY_contentSize   = @"contentSize";

static char _kPullupRefreshKey;
static char _kPullupRefreshTimeKey;
@implementation UIScrollView (PullupRefresh)

- (void)fs_pullupRefresh:(void(^)(void))pullup{
    if (!self.userInteractionEnabled) {
        return;
    }
    NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld;
    [self addObserver:self forKeyPath:_FS_KVO_KEY_contentOffset options:options context:nil];
    [self addObserver:self forKeyPath:_FS_KVO_KEY_contentSize options:options context:nil];
    objc_setAssociatedObject(self, &_kPullupRefreshKey, pullup, OBJC_ASSOCIATION_COPY);
    objc_setAssociatedObject(self, &_kPullupRefreshTimeKey, @(YES), OBJC_ASSOCIATION_ASSIGN);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    BOOL tk = [objc_getAssociatedObject(self, &_kPullupRefreshTimeKey) boolValue];
    if (!tk) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            objc_setAssociatedObject(self, &_kPullupRefreshTimeKey, @(YES), OBJC_ASSOCIATION_ASSIGN);
        });
        return;
    }
    CGPoint old = [change[@"old"] CGPointValue];
    CGPoint new = [change[@"new"] CGPointValue];
    if (new.y <= old.y){
        return;
    }
    CGFloat height = self.frame.size.height;
    CGFloat offsetY = self.contentOffset.y;
    CGFloat contentH = self.contentSize.height;
    CGFloat distance = contentH - offsetY;
    if (distance < height) {
        objc_setAssociatedObject(self, &_kPullupRefreshTimeKey, @(NO), OBJC_ASSOCIATION_ASSIGN);
        void(^pullup)(void) = objc_getAssociatedObject(self, &_kPullupRefreshKey);
        if (pullup) {
            pullup();
        }
    }
}

@end
