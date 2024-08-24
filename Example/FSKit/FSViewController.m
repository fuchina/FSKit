//
//  FSViewController.m
//  FSKit
//
//  Created by fudongdong on 06/17/2017.
//  Copyright (c) 2017 fudongdong. All rights reserved.
//

#import "FSViewController.h"
#import "FSModel.h"
#import "FSSecondController.h"
#import <FSKit/FSDate.h>
#import <Lottie/Lottie-Swift.h>
#import <FSKit/FSKit-Swift.h>

typedef NS_ENUM(NSInteger, FSWeekdayIndex) {
    FSWeekdayIndexMonday = 1,
    FSWeekdayIndexTuesday = 2,
    FSWeekdayIndexWednesday = 3,
    FSWeekdayIndexThursday = 4,
    FSWeekdayIndexFriday = 5,
    FSWeekdayIndexSaturday = 6,
    FSWeekdayIndexSunday = 7,
};


@interface FSViewController ()

@end

@implementation FSViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    btn.backgroundColor = [UIColor redColor];
    [btn setTitle:@"Click" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[btn]-15-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(btn)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-100-[btn(44)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(btn)]];
    
    [self showLottieView];
}

- (void)click{    
//    FSSecondController *vc = [[FSSecondController alloc] init];
//    [vc setText:@"我不会出现"];
//    [self.navigationController pushViewController:vc animated:YES];
    
    NSDate *date = [FSDate dateByString:@"2018-12-02 23:00:00" formatter:nil];
    NSDateComponents *c = [FSDate componentForDate:date];
    NSLog(@"%@,%@",@(c.weekOfYear),@([self weekIndexForWeekday:c.weekday]));
}


/*
 Type:5
 
 Did:一个时间戳
 Expitime:一个数字，1，2，3，4，5，6，7分表表示周一到周日；
 
 判断到期：
 1.获取当前时间now,用“年+第几周”得到一个数字‘201820’，前四位为年数，后两位为本年第几周；did，也同样得到‘201820’。
    如果now跟did相等，不需要提示；否则，now比did大至少一周，判断now是星期几，如果now小于expitime,不提示；否则now比已经到达了该提示的时间。
    1）左边显示“每周A提醒”，A为expitime对应的值汉化；
    2）右边显示“已过期多少天”，天数由(now - did) * 7 + now.weekday - expitime + 1.
 
 2.未过期的显示：“将在下周三提醒”，“将在本周五提醒”，根据现在的是周几与expitime比较确定是下周还是本周。
 
 */
- (void)alertWeekly{
    
}

/*
    c.weekday中，周日是1，周一是2，周六是7；
 */
- (FSWeekdayIndex)weekIndexForWeekday:(NSInteger)weekday{
    NSAssert(weekday > 0 && weekday < 8, @"weekIndexForWeekday:出现不正常的参数");
    if (weekday > 0 && weekday < 8) { // 1~7
        if (weekday == 1) {
            return FSWeekdayIndexSunday;
        }
        return weekday - 1;
    }
    return FSWeekdayIndexSunday;
}

- (void)showLottieView {
    
//    LottieAnimationView *anView = [[LottieAnimationView alloc] initWithFrame: CGRectMake(200, 200, 100, 100)];
//    anView.backgroundColor = UIColor.yellowColor;
//    [self.view addSubview: anView];
    
    FSLottieView *lotView = [[FSLottieView alloc] initWithFrame: CGRectMake(20, 300, 310.5, 672) name: @"data" bundle: nil subdirectory: @"json12"];
    [self.view addSubview: lotView];
    lotView.lotView.backgroundColor = UIColor.yellowColor;
//    [lotView playWithCompletion: ^ (BOOL finished) {
//        NSLog(@"HELog here");
//    }];
    [lotView play];
    [lotView loop_modeWithLoop: YES];
    
//    [lotView playFromFrame: 0 toFrame: 90 completion:^(BOOL finished) {
//        NSLog(@"HELog here");
//    }];
    
    [lotView addTapWithEvent:^(CGPoint p) {
        NSLog(@"HELog tap %f, %f", p.x, p.y);
    }];
        
//    [lotView playFromProgress: 0 toProgress: 1 completion:^(BOOL finished) {
//            NSLog(@"HELog here");
//    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        lotView.frame = CGRectMake(20, 200, 372.6, 806.4);
        
        [lotView playFromFrame: 0 toFrame: 45 completion: nil];
    });
}


@end
