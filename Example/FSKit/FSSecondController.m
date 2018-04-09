//
//  FSSecondController.m
//  FSKit_Example
//
//  Created by Guazi on 2018/1/16.
//  Copyright © 2018年 topchuan. All rights reserved.
//

#import "FSSecondController.h"
#import <FSKit/FSKit.h>
#import <FSKit/FSURLSession.h>
#import "FSBackWork.h"
#import "FSBankWork.h"
#import "FSModel.h"
#import <objc/runtime.h>
#import <FSKit/FSRuntime.h>
#import <FSKit/FuSoft.h>

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

- (NSArray *)alphabets{
    static NSArray *as = nil;
    if (!as) {
        as = @[@"a",@"d",@"g",@"j",@"m",@"p",@"t",@"w"];
        as = @[@"a",@"d",@"g",@"j",@"m",@"p",@"t",@"w"];
        as = @[@"a",@"d",@"g",@"j",@"m",@"p",@"t",@"w"];
        as = @[@"a",@"d",@"g",@"j",@"m",@"p",@"t",@"w"];
    }
    return as;
}

- (void)click{
    NSArray *source = [self alphabets];
    NSMutableArray *indexes = [[NSMutableArray alloc] init];
}

/*
 1.索引数组，取几个数，就几个索引的数组；每次循环，索引数组的每个位置都存入索引；遍历索引数组，取到值。~~~~~~ 为 1 次循环。
 2.如何给索引数组存入值？（）
 3.思路是：每位都从前往后遍历，
 */
- (void)source:(NSArray<NSString *> *)source position:(NSInteger)position count:(NSInteger)count hasMarked:(NSMutableArray<NSNumber *> *)indexes NUM:(NSInteger)NUM{
    for (int x = 0; x < source.count - indexes.count; x ++) {
        
    }
}

- (NSInteger)Fibonacci:(NSInteger)n{
    if (n == 1 || n == 2) {
        return 1;
    }
    return [self Fibonacci:n -1] + [self Fibonacci:n - 2];
}

- (void)clickA{
    int arr[] = {1, 2, 3, 4, 5, 6};
    int num = 4;
    int result[num];
    printf("分界线\n");
    combine_decrease(arr, sizeof(arr)/sizeof(int), result, num, num);
}

/*演绎：
 */

void combine_decrease(int *arr, int start, int* result, int count, const int NUM){
    for (int i = start; i >=count; i--){
        result[count - 1] = i - 1;
        if (count > 1){
            combine_decrease(arr, i - 1, result, count - 1, NUM);
        }else{
            int j;
            for (j = NUM - 1; j >=0; j--)
                printf("%d\t",arr[result[j]]);
            printf("\n");
        }
    }
}

void combine (int *arr,int start,int *result,int index,int n,int arr_len){
    int ct = 0;
    for(ct = start;ct < arr_len-index+1;ct++){
        result[index-1] = ct;
        if(index-1==0){
            int j;
            for(j = n-1;j>=0;j--)
                printf("%d\t",arr[result[j]]);
            printf("\n");
        }
        else
            combine(arr,ct+1,result,index-1,n,arr_len);
    }
}

- (void)CSBlock{
    FSModel *m = [[FSModel alloc] init];
    [FSRuntime setValue:@[] forIvarName:@"aid" ofObject:m];
    NSLog(@"aid:%@",m.aid);
//    NSArray *list = [FSRuntime ivarsForClass:[FSModel class]];
//    NSLog(@"%@",list);
}

- (void)metaClass{
    [FSKit spendTimeInDoingSomething:^{
        NSInteger x = 0;
        FSModel *m = [[FSModel alloc] init];
        while (x < 1000000) {
            [FSRuntime setValue:@[] forIvarName:@"aid" ofObject:m];
//            [FSRuntime setValue:@[] forPropertyName:@"aid" ofObject:m];
            x ++;
        }
    } time:^(double time) {
        NSLog(@"time:%lf",time);
    }];
}

- (void)sessionGet{
    [FSURLSession sessionGet:@"https://api.m.taobao.com/rest/api3.do?api=mtop.common.getTimestamp" success:^(id value) {
        NSDictionary *dic = [FSKit objectFromJSonstring:value];
        NSString *t = dic[@"data"][@"afd"];
        NSLog(@"%@",t);
        
    } fail:^{
        NSLog(@"网络请求失败");
    }];
}

- (void)blockTT{
    static NSString *v = nil;
    if (v == nil) {
        v = @"nil";
    }else{
        v = nil;
    }
    [self blockT:v];
}

- (void)blockT:(NSString *)value{
    static void (^block)(void);
    if (block == nil) {
        block = ^ {
            NSLog(@"v:%@",value);
        };
    }
    block();
}

- (void)seeDB{
    [FSKit pushToViewControllerWithClass:@"FSFastUploadController" navigationController:self.navigationController param:nil configBlock:nil];
}

- (void)backExec{
    [FSBackWork backWorkEvent:^{
        [self log:0];
    }];
}

- (void)log:(NSInteger)times{
    times ++;
    NSLog(@"我在后台执行%@次了",@(times));
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self log:times];
    });
}

- (void)request{
    NSString *url = @"https://qt.gtimg.cn/q=sz000858";
    [FSURLSession sessionGet:url success:^(id value) {
        NSLog(@"%@",value);
    } fail:^{
        
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
