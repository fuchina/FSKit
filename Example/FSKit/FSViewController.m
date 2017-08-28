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
    btn.frame = CGRectMake(10, 100, 300, 44);
    btn.backgroundColor = [UIColor redColor];
    [btn setTitle:@"Click" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)click{
    NSInteger type = 0;
    static NSString *tb = @"pass";
    FSDBMaster *master = [FSDBMaster sharedInstance];
    if (type == 0) {
        NSString *sql = [[NSString alloc] initWithFormat:@"INSERT INTO %@ (time,name,one,two,thr,four,five) VALUES (\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\");",tb,@(FSIntegerTimeIntevalSince1970()),@"小明",@"中华人民共和国",@"美利坚合众国",@"英吉利海峡",@"法兰西帝国",@"阿里巴巴"];
        CGFloat start = CFAbsoluteTimeGetCurrent();
        NSString *error = nil;
        for (int x = 0; x < 10; x ++) {
            error = [master insertSQL:sql class:[FSModel class] tableName:tb];
            if (error) {
                [FSKit showAlertWithMessage:error];
            }
        }
        CGFloat end = CFAbsoluteTimeGetCurrent();
        NSLog(@"\n\n\n\n%f\n\n\n\n",end - start);
    }else if (type == 1){
        NSString *sql = [[NSString alloc] initWithFormat:@"SELECT * FROM %@",tb];
        NSArray *list = [master querySQL:sql tableName:tb];
        NSLog(@"%@",list);
    }else if (type == 2){
        BOOL check = [master checkTableExist:@"pass"];
        NSLog(@"%@",@(check));
    }else if (type == 3){
        NSString *sql = @"select count(time) from pass";
        int count = [master countWithSQL:sql table:tb];
        NSLog(@"%@",@(count));
    }
    
    NSLog(@"\n\n\n\n%@\n\n\n\n",[master dbPath]);
    
  //  flag = !flag;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
