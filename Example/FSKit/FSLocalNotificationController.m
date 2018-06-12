//
//  FSLocalNotificationController.m
//  FSKit_Example
//
//  Created by Guazi on 2018/6/12.
//  Copyright © 2018年 topchuan. All rights reserved.
//

#import "FSLocalNotificationController.h"
#import <FSKit/FSLocalNotification.h>
#import <FSKit/FuSoft.h>
#import <FSKit/FSKit.h>

@interface FSLocalNotificationController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) NSArray        *list;
@property (nonatomic,strong) UITableView    *tableView;

@end

@implementation FSLocalNotificationController{
    Class _Class_Request;
    Class _Class_Notification;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _Class_Request = [UNNotificationRequest class];
    _Class_Notification = [UNNotification class];

    [self localNotificationHanldeDatas];
}

- (void)localNotificationHanldeDatas{
    FSLocalNotification *ln = [FSLocalNotification sharedInstance];
    [ln allNotications:^(NSArray *list) {
        self.list = list;
        [self localNotificationDesignViews];
    }];
}

- (void)localNotificationDesignViews{
    self.title = [[NSString alloc] initWithFormat:@"通知数（%@）",@(self.list.count)];
    if (!_tableView) {
        UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(bbiClick)];
        self.navigationItem.rightBarButtonItem = bbi;
        
        CGFloat rgb = 238/255.0;
        self.view.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1];
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, WIDTHFC, HEIGHTFC - 64) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.tableFooterView = [UIView new];
        [self.view addSubview:_tableView];
    }else{
        [_tableView reloadData];
    }
}

- (void)bbiClick{
    static NSInteger count = 0;
    FSLocalNotification *ln = [FSLocalNotification sharedInstance];
    [ln addLocalNotificationWithIdentifier:@(_fs_integerTimeIntevalSince1970()).stringValue title:@"title" subTitle:@(count ++).stringValue body:nil userInfo:nil date:[NSDate date] calendarUnit:NSCalendarUnitMinute repeats:YES success:^(NSDate *date) {
        [self localNotificationHanldeDatas];
    } fail:^(NSError *error) {
        NSAssert(error, @"出错");
    }];
}

#pragma mark Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.list.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"c";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }
    id object = [self.list objectAtIndex:indexPath.row];
    if ([object isKindOfClass:_Class_Notification]) {
        UNNotification *n = (UNNotification *)object;
        cell.textLabel.text = n.request.content.title;
        cell.detailTextLabel.text = @"已触发";
    }else if ([object isKindOfClass:_Class_Request]){
        UNNotificationRequest *r = (UNNotificationRequest *)object;
        UNNotificationContent *content = r.content;
        cell.textLabel.text = content.title;
        UNCalendarNotificationTrigger *trigger = (UNCalendarNotificationTrigger *)r.trigger;
        cell.detailTextLabel.text = trigger.nextTriggerDate.description;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"删除";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self deleteRow:indexPath table:tableView];
}

- (void)deleteRow:(NSIndexPath *)indexPath table:(UITableView *)tableView{
    NSMutableArray *list = [self.list mutableCopy];
    [list removeObjectAtIndex:indexPath.row];
    self.list = list;
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    UIApplication *app = [UIApplication sharedApplication];
    if (app.applicationIconBadgeNumber) {
        app.applicationIconBadgeNumber --;
    }
    FSLocalNotification *ln = [FSLocalNotification sharedInstance];
    [ln removeNotification:@[] delivered:YES pending:YES];
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
