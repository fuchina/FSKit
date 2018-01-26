//
//  FSLeakView.h
//  FSKit_Example
//
//  Created by Guazi on 2018/1/26.
//  Copyright © 2018年 topchuan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FSLeakView : UIView

@property (nonatomic,copy) void (^click)(FSLeakView *view);

@end
