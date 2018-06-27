//
//  FSBestUpdateController.m
//  FSKit_Example
//
//  Created by Guazi on 2018/6/27.
//  Copyright © 2018年 topchuan. All rights reserved.
//

#import "FSBestUpdateController.h"
#import <FSKit/FSTuple.h>

@interface FSBestUpdateController ()

@end

@implementation FSBestUpdateController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateHandleDatas];
}

- (void)updateHandleDatas{
    
    [self updateDesignViews];
}

- (void)updateDesignViews{
    CGFloat rgb = 238 / 255.0;
    self.view.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1];
    
    NSArray *values = @[
                        [Tuple2 v1:<#(id)#> v2:<#(id)#>];
                        ];
    
    for (int x = 0; x < 4; x ++) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        cell.backgroundColor = [UIColor whiteColor];
        cell.tag = x;
        cell.frame = CGRectMake(0, 74 + 51 * x, UIScreen.mainScreen.bounds.size.width, 50);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        [self.view addSubview:cell];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClick:)];
        [cell addGestureRecognizer:tap];
    }
}

- (void)tapClick:(UITapGestureRecognizer *)tap{
    NSLog(@"ddd:%@",@(tap.view.tag));
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
