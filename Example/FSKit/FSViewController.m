//
//  FSViewController.m
//  FSKit
//
//  Created by fudongdong on 06/17/2017.
//  Copyright (c) 2017 fudongdong. All rights reserved.
//

#import "FSViewController.h"
#import "FSKit-umbrella.h"
#import "FSModel.h"
#import "FSSecondController.h"

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
}

- (void)click{
    FSSecondController *vc = [[FSSecondController alloc] init];
    [vc setText:@"我不会出现"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
