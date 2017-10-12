
//
//  FSWindow.m
//  Expand
//
//  Created by Fudongdong on 2017/9/29.
//  Copyright © 2017年 china. All rights reserved.
//

#import "FSWindow.h"
#import "FuSoft.h"

@implementation FSWindow{
    UIView              *_view;
    UIViewController    *_viewController;
}

SINGLE_ONCE_SAFE(_w);
static FSWindow *_w = nil;
+ (instancetype)sharedInstance{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _w = [[FSWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    });
    return _w;
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        UIView *view = [[UIView alloc] init];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:view];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[view]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(view)]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(view)]];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
        [view addGestureRecognizer:tap];
        
        self.windowLevel = UIWindowLevelAlert;
    }
    return self;
}

- (void)tapAction{
    [self dismiss];
}

- (void)display:(UIView *)view{
    _view = view;
    self.hidden = NO;
    [self makeKeyAndVisible];
}

- (void)presentViewController:(UIViewController *)controller animated:(BOOL)animated completion:(void (^)(void))completion{
    _viewController = controller;
    self.hidden = NO;
    [self makeKeyAndVisible];

    if (!self.rootViewController) {
        UIViewController *vc = [[UIViewController alloc] init];
        self.rootViewController = vc;
    }
    
    UIViewController *vc = self.rootViewController;
    while (vc.presentedViewController) {
        vc = vc.presentedViewController;
    }
    [vc presentViewController:controller animated:animated completion:completion];
}

- (void)dismiss{
    if (_view) {
        [_view removeFromSuperview];
        _view = nil;
    }
    if (_viewController) {
        _viewController = nil;
    }
    self.hidden = YES;
    [self resignKeyWindow];
}

+ (void)showView:(UIView *)view{
    [[FSWindow sharedInstance] addSubview:view];
    [[FSWindow sharedInstance] display:view];
}

+ (void)presentViewController:(UIViewController *)controller animated:(BOOL)animated completion:(void (^)(void))completion{
    if (![controller isKindOfClass:[UIViewController class]]) {
        return;
    }
    [[FSWindow sharedInstance] presentViewController:controller animated:animated completion:completion];
}

+ (void)dismiss{
    [[FSWindow sharedInstance] dismiss];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
