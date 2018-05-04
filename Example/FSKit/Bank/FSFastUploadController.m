//
//  FSFastUploadController.m
//  FSKit_Example
//
//  Created by Fudongdong on 2018/2/28.
//  Copyright © 2018年 fudongdong. All rights reserved.
//

#import "FSFastUploadController.h"
#import "UIScrollView+PullupRefresh.h"

@interface FSFastUploadController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,assign) NSInteger      index;
@property (nonatomic,strong) UITableView    *tableView;

@end

@implementation FSFastUploadController{
    NSInteger   _index;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _index = 10;
    [self fastUploadDesignViews];
}

- (void)fastUploadDesignViews{
    CGFloat rgb = 238 / 255.0;
    self.view.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 568) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [UIView new];
    _tableView.rowHeight = 190;
    _tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_tableView];
    __weak typeof(self)this = self;
    [_tableView fs_pullupRefresh:^{
        NSLog(@"执行了");
        this.index += 15;
        [this.tableView reloadData];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _index;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.textLabel.text = @(indexPath.row).stringValue;
    return cell;
}

//- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
//    CGFloat height = scrollView.frame.size.height;
//    CGFloat contentYoffset = scrollView.contentOffset.y;
//    CGFloat distanceFromBottom = scrollView.contentSize.height - contentYoffset;
//    if (distanceFromBottom < height) {
//        NSLog(@"end of table");
//        _index += 10;
//        UITableView *tb = (UITableView *)scrollView;
//        [tb reloadData];
//    }
//}

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
