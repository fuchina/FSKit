//
//  FSSecondController.m
//  FSKit_Example
//
//  Created by Guazi on 2018/1/16.
//  Copyright © 2018年 topchuan. All rights reserved.
//

#import "FSSecondController.h"
#import <FSKit/FSKit.h>
#import <FSKit/FSURLSession.h>
#import "FSBackWork.h"
#import "FSSqlite3BroswerController.h"
#import "FSBankWork.h"

@interface FSSecondController ()

@property (nonatomic,assign) BOOL what;
@property (nonatomic,copy) NSString *str;

@end

@implementation FSSecondController

- (void)dealloc{
    NSLog(@"%s",__FUNCTION__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    btn.backgroundColor = [UIColor redColor];
    [btn setTitle:@"Click" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[btn]-15-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(btn)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-100-[btn(44)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(btn)]];
}

- (void)click{
    [self blockTT];
}

- (void)blockTT{
    static NSString *v = nil;
    if (v == nil) {
        v = @"nil";
    }else{
        v = nil;
    }
    [self blockT:v];
}

- (void)blockT:(NSString *)value{
    static void (^block)(void);
    if (block == nil) {
        block = ^ {
            NSLog(@"v:%@",value);
        };
    }
    block();
}

/*
 1.formatt必须小于9999;
 2.formatt的各位数字加起来等于字符长度;
*/
- (NSString *)formattFunction:(NSString *)str formatt:(NSInteger)formatt place:(NSString *)place{
    if (formatt > 9999) {
        return str;
    }
    NSInteger one = formatt / 1000;
    NSInteger two = (formatt / 100) % 10;
    NSInteger thr = (formatt / 10) % 10;
    NSInteger fou = formatt % 10;
    NSInteger length = one + two + thr + fou;
    if (str.length != length) {
        return str;
    }
    NSString *subOne = @"";
    if (one) {
        subOne = [[NSString alloc] initWithFormat:@"%@%@",[str substringWithRange:NSMakeRange(0, one)],place];
    }
    NSString *subTwo = @"";
    if (two) {
        subTwo = [[NSString alloc] initWithFormat:@"%@%@",[str substringWithRange:NSMakeRange(one, two)],place];
    }
    NSString *subThr = @"";
    if (thr) {
        subThr = [[NSString alloc] initWithFormat:@"%@%@",[str substringWithRange:NSMakeRange(one + two, thr)],place];
    }
    NSString *subFou = @"";
    if (fou) {
        subFou = [str substringWithRange:NSMakeRange(one + two + thr, fou)];
    }
    NSString *value = [[NSString alloc] initWithFormat:@"%@%@%@%@",subOne,subTwo,subThr,subFou];
    return value;
}

- (void)seeDB{
    [FSKit pushToViewControllerWithClass:@"FSFastUploadController" navigationController:self.navigationController param:nil configBlock:nil];
}

- (void)backExec{
    [FSBackWork backWorkEvent:^{
        [self log:0];
    }];
}

- (void)log:(NSInteger)times{
    times ++;
    NSLog(@"我在后台执行%@次了",@(times));
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self log:times];
    });
}

- (void)request{
    NSString *url = @"http://qt.gtimg.cn/q=sz000858";
    [FSURLSession sessionGet:url];
}

- (void)memoryLeak{
    __weak typeof(self)this = self;
    [FSKit alertInput:1 controller:self title:@"Title" message:@"Message" ok:@"OK" handler:^(UIAlertController *bAlert, UIAlertAction *action) {
        UITextField *tf = bAlert.textFields.firstObject;
        NSLog(@"%@",tf.text);
        this.what = YES;
        self.str = @"what";
    } cancel:@"Cancel" handler:^(UIAlertAction *action) {
        NSLog(@"Cancel");
    } textFieldConifg:^(UITextField *textField) {
        textField.keyboardType = UIKeyboardTypeNumberPad;
    } completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
