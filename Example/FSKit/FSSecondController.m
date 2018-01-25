//
//  FSSecondController.m
//  FSKit_Example
//
//  Created by Guazi on 2018/1/16.
//  Copyright © 2018年 topchuan. All rights reserved.
//

#import "FSSecondController.h"
#import <FSKit/FSKit.h>

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
    __weak typeof(self)this = self;
    [FSKit alertInput:1 controller:self title:@"Title" message:@"Message" ok:@"OK" handler:^(UIAlertController *bAlert, UIAlertAction *action) {
        UITextField *tf = bAlert.textFields.firstObject;
        NSLog(@"%@",tf.text);
        this.what = YES;
        this.str = @"what";
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
