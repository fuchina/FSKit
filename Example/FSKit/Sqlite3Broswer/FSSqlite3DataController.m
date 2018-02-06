//
//  FSSqlite3DataController.m
//  FSKit_Example
//
//  Created by Guazi on 2018/2/6.
//  Copyright © 2018年 topchuan. All rights reserved.
//

#import "FSSqlite3DataController.h"
#import "FSDBMaster.h"

@interface FSSqlite3DataController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) UITableView    *tableView;
@property (nonatomic,strong) NSDictionary   *data;

@end

@implementation FSSqlite3DataController{
@private NSArray    *_keys;
@private NSInteger  _index;
@private NSInteger  _count;
@private NSInteger  _bbiFrom;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CGFloat rgb = 240 / 255.0;
    self.view.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1];
    [self getCount];
    [self sqlite3DataHandleDatas];
}

- (void)getCount{
    FSDBMaster *master = [FSDBMaster sharedInstance];
    _count = [master countForTable:_table];
}

- (void)sqlite3DataHandleDatas{
    FSDBMaster *master = [FSDBMaster sharedInstance];
    NSString *sql = [[NSString alloc] initWithFormat:@"SELECT * FROM %@ limit %@,1;",_table,@(_index)];
    NSArray *list = [master querySQL:sql tableName:_table];
    if ([list isKindOfClass:[NSArray class]] && list.count) {
        self.data = list.firstObject;
        if (!_keys) {
            _keys = [self.data allKeys];
        }
        [self sqlite3DataDesignViews];
    }else{
        [FSKit showMessage:@"没有更多数据了"];
        if (_bbiFrom == 1) {
            _index ++;
        }else if (_bbiFrom == 2){
            _index --;
        }
    }
    if (_index < 0) {
        [FSKit showMessage:@"没有更多数据了"];
        _index = 0;
    }
    NSString *title = [[NSString alloc] initWithFormat:@"%@/%@",@(_index + 1),@(_count)];
    self.title = title;
}

- (void)sqlite3DataDesignViews{
    if (!_tableView) {
        UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithTitle:@"上一条" style:UIBarButtonItemStylePlain target:self action:@selector(upNext:)];
        UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithTitle:@"下一条" style:UIBarButtonItemStylePlain target:self action:@selector(upNext:)];
        right.tag = 1;
        self.navigationItem.rightBarButtonItems = @[right,left];

        CGSize size = [UIScreen mainScreen].bounds.size;
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, size.width, size.height - 64) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.tableFooterView = [UIView new];
        [self.view addSubview:_tableView];
    }else{
        [_tableView reloadData];
    }
}

- (void)upNext:(UIBarButtonItem *)bbi{
    if (bbi.tag) {
        _bbiFrom = 2;
        _index ++;
    }else{
        _bbiFrom = 1;
        _index --;
    }
    [self sqlite3DataHandleDatas];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _keys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }
    NSString *key = _keys[indexPath.row];
    cell.textLabel.text = key;
    cell.detailTextLabel.text = [[self.data objectForKey:key] description];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *key = _keys[indexPath.row];
    NSString *value = [[self.data objectForKey:key] description];
    [FSKit copyToPasteboard:value];
    [FSKit showMessage:@"已复制到粘贴板"];
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
