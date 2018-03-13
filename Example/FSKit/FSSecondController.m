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
#import "FSBankWork.h"
#import "FSModel.h"
#import <objc/runtime.h>
#import <FSKit/FSRuntime.h>

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
    [self metaClass];
}

- (void)metaClass{
    NSArray *list = [FSRuntime classMethodListOfClass:[FSModel class]];
    NSLog(@"%@",list);
}

- (void)sessionGet{
    [FSURLSession sessionGet:@"https://api.m.taobao.com/rest/api3.do?api=mtop.common.getTimestamp" success:^(id value) {
        NSDictionary *dic = [FSKit objectFromJSonstring:value];
        NSString *t = dic[@"data"][@"afd"];
        NSLog(@"%@",t);
        
    } fail:^{
        NSLog(@"网络请求失败");
    }];
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
    NSString *url = @"https://qt.gtimg.cn/q=sz000858";
    [FSURLSession sessionGet:url success:^(id value) {
        NSLog(@"%@",value);
    } fail:^{
        
    }];
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
