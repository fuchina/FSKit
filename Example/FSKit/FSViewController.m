//
//  FSViewController.m
//  FSKit
//
//  Created by topchuan on 06/17/2017.
//  Copyright (c) 2017 topchuan. All rights reserved.
//

#import "FSViewController.h"
#import "FSKit-umbrella.h"

@interface FSViewController ()

@end

@implementation FSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(10, 100, 300, 44);
    btn.backgroundColor = [UIColor redColor];
    [btn setTitle:@"Click" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)click{
    [FSKit alertInput:2 title:@"Title" message:@"Message" ok:@"OK" handler:^(UIAlertController *bAlert, UIAlertAction *action) {
        NSLog(@"OK");
    } cancel:@"Cancel" handler:^(UIAlertAction *action) {
        NSLog(@"Cancel");
    } textFieldConifg:^(UITextField *textField) {
        textField.placeholder = [[NSString alloc] initWithFormat:@"%@",@(textField.tag)];
    } completion:^{
        NSLog(@"Completion");
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
