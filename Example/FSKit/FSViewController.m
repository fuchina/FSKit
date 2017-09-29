//
//  FSViewController.m
//  FSKit
//
//  Created by topchuan on 06/17/2017.
//  Copyright (c) 2017 topchuan. All rights reserved.
//

#import "FSViewController.h"
#import "FSKit-umbrella.h"
#import "FSModel.h"

@interface FSViewController ()

@end

@implementation FSViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
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
    
    NSMutableArray *array = [NSMutableArray new];
    for (int x = 0; x < 1; x ++) {
        NSDictionary *dic = @{@"expirtimekey":@"expirtimekey",@"expirtimekey":@"expirtimekey",@"expirtimekey":@"expirtimekey",@"expirtimekey":@"expirtimekey",@"expirtimekey":@"expirtimekey",@"expirtimekey":@"expirtimekey",@"expirtimekey":@"expirtimekey",@"expirtimekey":@"expirtimekey",@"expirtimekey":@"expirtimekey",@"expirtimekey":@"expirtimekey",@"expirtimekey":@"expirtimekey",@"expirtimekey":@"expirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekeyexpirtimekey"};
        [array addObject:dic];
    }
    NSString *json = [FSKit jsonStringWithObject:array];
    NSArray *value = [FSKit objectFromJSonstring:json];
    
    NSLog(@"object:%@",value);
    
    
    
    
//    [FSKit alertInput:1 title:@"Title" message:@"Message" ok:@"ok" handler:^(UIAlertController *bAlert, UIAlertAction *action) {
//        NSLog(@"%@",bAlert.textFields);
//    } cancel:@"cancel" handler:^(UIAlertAction *action) {
//        NSLog(@"%@",action.title);
//    } textFieldConifg:^(UITextField *textField) {
//        textField.placeholder = @"Here";
//    } completion:^{
//        NSLog(@"AAA");
//    }];
    
//    [FSKit alert:UIAlertControllerStyleAlert title:@"Title" message:@"Message" actionTitles:@[@"ok"] styles:@[@(UIAlertActionStyleDefault)] handler:^(UIAlertAction *action) {
//        
//    } cancelTitle:@"cancel" cancel:nil completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
