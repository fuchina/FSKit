//
//  UIScrollView+PullupRefresh.h
//  FSKit_Example
//
//  Created by Guazi on 2018/2/28.
//  Copyright © 2018年 topchuan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIScrollView (PullupRefresh)

- (void)fs_pullupRefresh:(void(^)(void))pullup;

@end
