//
//  FSSQLite3Controller.m
//  FSKit_Example
//
//  Created by Guazi on 2018/4/19.
//  Copyright © 2018年 topchuan. All rights reserved.
//

#import "FSSQLite3Controller.h"
#import "FSDBMaster.h"
#import <FSKit/FSKit.h>
#import "FSModel.h"

@interface FSSQLite3Controller ()

@end

static NSString *_table = @"apple";

@implementation FSSQLite3Controller

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
    FSDBMaster *master = [FSDBMaster sharedInstance];
    NSLog(@"%@",master.dbPath);
    [self addData];
}

- (void)addData{
    NSNumber *time = @(FSIntegerTimeIntevalSince1970());
    FSDBMaster *master = [FSDBMaster sharedInstance];
    [FSKit spendTimeInDoingSomething:^{
        for (int x = 0; x < 1000; x ++) {
            NSString *sql = [[NSString alloc] initWithFormat:@"INSERT INTO %@ (time,name,one,two,thr,four,five) VALUES ('%@','%@','%@','%@','%@','%@',\'%@\');",_table,time,@(x),@1,@2,@3,@4,@5];
            NSString *error = [master insertSQL:sql class:[FSModel class] tableName:_table];
            if (error) {
                NSLog(@"%@",error);
            }
        }
    } time:^(double time) {
        NSLog(@"spend time:%.2f s",time);
    }];
}

- (void)updateData{
    FSDBMaster *master = [FSDBMaster sharedInstance];
    [FSKit spendTimeInDoingSomething:^{
        for (int x = 0; x < 1000; x ++) {
            NSString *sql = [[NSString alloc] initWithFormat:@"UPDATE %@ SET four = '%@',five = '%@';",_table,@(x + 4),@(x + 5)];
            NSString *error = [master updateWithSQL:sql];
            if (error) {
                NSLog(@"%@",error);
            }
        }
    } time:^(double time) {
        NSLog(@"spend time:%.2f s",time);
    }];
}

- (void)deleteData{
    FSDBMaster *master = [FSDBMaster sharedInstance];
    [FSKit spendTimeInDoingSomething:^{
        for (int x = 0; x < 1000; x ++) {
            NSString *sql = [[NSString alloc] initWithFormat:@"DELETE FROM %@ WHERE name = '%@';",_table,@(x)];
            NSString *error = [master deleteSQL:sql];
            if (error) {
                NSLog(@"%@",error);
            }
        }
    } time:^(double time) {
        NSLog(@"spend time:%.2f s",time);
    }];
}

- (void)queryData{
    FSDBMaster *master = [FSDBMaster sharedInstance];
    NSString *sql = [[NSString alloc] initWithFormat:@"SELECT * FROM %@ WHERE name = '8' OR name = '9' and cast(time as INTEGER) BETWEEN 1500008800 AND 1524129828 order by cast(time as INTEGER) DESC limit 0,10;",_table];
    NSArray *list = [master querySQL:sql tableName:_table];
    NSLog(@"%@",list);
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
