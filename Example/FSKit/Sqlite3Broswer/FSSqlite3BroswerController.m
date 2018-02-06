//
//  FSSqlite3BroswerController.m
//  FSKit_Example
//
//  Created by Guazi on 2018/2/6.
//  Copyright © 2018年 topchuan. All rights reserved.
//

#import "FSSqlite3BroswerController.h"
#import <FSKit/FSKit.h>
#import "FSDBMaster.h"
#import "FSSqlite3DataController.h"

@interface FSSqlite3BroswerController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) UITableView    *tableView;

@end

@implementation FSSqlite3BroswerController{
@private    NSArray *_tables;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CGFloat rgb = 240 / 255.0;
    self.view.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1];
    [self sqlite3HandleDatas];
}

- (void)sqlite3HandleDatas{
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL fileExist = [manager fileExistsAtPath:_path];
    if (!fileExist) {
        [FSKit showAlertWithMessage:@"文件不存在" controller:self];
        return;
    }
    NSString *lastComponent = [self.path lastPathComponent];
    self.title = lastComponent;
    
    FSDBMaster *master = [FSDBMaster sharedInstance];
    BOOL open = [master openSqlite3DatabaseAtPath:_path];
    if (!open) {
        [FSKit showAlertWithMessage:@"文件打开失败" controller:self];
        return;
    }
    _tables = [master allTables];
    [self sqlite3DesignViews];
}

- (void)sqlite3DesignViews{
    if (!_tableView) {
        CGSize size = [UIScreen mainScreen].bounds.size;
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, size.width, size.height - 64) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.tableFooterView = [UIView new];
        [self.view addSubview:_tableView];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _tables.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    NSString *table = [_tables objectAtIndex:indexPath.row];
    cell.textLabel.text = table;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *table = [_tables objectAtIndex:indexPath.row];
    FSSqlite3DataController *data = [[FSSqlite3DataController alloc] init];
    data.table = table;
    [self.navigationController pushViewController:data animated:YES];
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
