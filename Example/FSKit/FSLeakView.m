//
//  FSLeakView.m
//  FSKit_Example
//
//  Created by Guazi on 2018/1/26.
//  Copyright © 2018年 topchuan. All rights reserved.
//

#import "FSLeakView.h"

@implementation FSLeakView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self leakDesignViews];
    }
    return self;
}

- (void)leakDesignViews{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clck)];
    [self addGestureRecognizer:tap];
}

- (void)clck{
    if (self.click) {
        self.click(self);
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
