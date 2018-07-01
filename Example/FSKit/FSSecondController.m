//
//  FSSecondController.m
//  FSKit_Example
//
//  Created by Fudongdong on 2018/1/16.
//  Copyright © 2018年 fudongdong. All rights reserved.
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
#import <FSKit/FSHook.h>
#import <FSKit/FSLocalNotification.h>
#import "FSLocalNotificationController.h"
#import <FSKit/FSDBMaster.h>
#import "FSSQLite3Controller.h"
#import <FSKit/FSCalculator.h>

@interface FSSecondController ()

@property (nonatomic,assign) BOOL what;
@property (nonatomic,copy) NSString *str;

@end

@implementation FSSecondController{
    UIImageView     *_imageView;
    UILabel         *_label;
}

- (void)setText:(NSString *)text{
    self.label.text = text;
}

- (UILabel *)label{
    if (!_label) {
        _label = [[UILabel alloc] initWithFrame:CGRectMake(15, 200, WIDTHFC - 30, 30)];
        [self.view addSubview:_label];
    }
    return _label;
}

//+(void)load{
//    [super load];
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        _fs_hook_swizzle_class([self class],@selector(viewDidLoad),@selector(_fs_viewDidLoad));
//    });
//}

- (void)_fs_viewDidLoad{
    NSLog(@"走到hook(1)的方法里了");
    [self _fs_viewDidLoad];
}

- (void)_fs_viewDidLoad_hookAgain{
    NSLog(@"走到hook(2)的方法里了");
    [self _fs_viewDidLoad_hookAgain];
}

- (void)dealloc{
    NSLog(@"%s",__FUNCTION__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    btn.backgroundColor = [UIColor redColor];
    [btn setTitle:@"Click" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[btn]-15-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(btn)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-100-[btn(44)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(btn)]];
    
    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(30, 180, WIDTHFC - 60, 190)];
    [self.view addSubview:_imageView];
}

- (NSArray *)alphabets{
    static NSArray *as = nil;
    if (!as) {
        as = @[@"a",@"d",@"g",@"j",@"m",@"p",@"t",@"w"];
    }
    return as;
}

- (void)click{
    NSString *a = @"10.429";
    NSString *b = @"-5.23";
    NSString *add = _fs_highAccuracy_add(a, b);
    NSString *minus = _fs_highAccuracy_subtract(a, b);
    NSLog(@"%@-%@",add,minus);
}

- (void)clickClass{
    Class Class_VC = NSClassFromString(@"FSPageController");
    UIViewController *vc = [[Class_VC alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)aboutThreadOfQueue{
    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_sync(queue, ^{
        BOOL isMain = [NSThread isMainThread];
        NSLog(@"isMain:%@",@(isMain));
    });
    NSLog(@"back");
}

- (void)groupClear{
    [FSKit pushToViewControllerWithClass:@"FSSQLite3Controller" navigationController:self.navigationController param:nil configBlock:nil];
}

- (void)localNotification{
    FSLocalNotificationController *notification = [[FSLocalNotificationController alloc] init];
    [self.navigationController pushViewController:notification animated:YES];
}

- (void)url_12306{
//    // GET
//    static NSString *code = @"https://kyfw.12306.cn/otn/passcodeNew/getPassCodeNew.do?module=login&rand=sjrand&";   // 验证码
//    static NSString *people = @"https://kyfw.12306.cn/otn/passengers/init";// 联系人
//    static NSString *query = @"https://kyfw.12306.cn/otn/leftTicket/query?";// 查票
//    
//    // POST
//    
//    _imageView.image = nil;
//    [FSURLSession sessionGet:people success:^(id value) {
//        NSInteger type = 0;
//        if (type == 0) {
//            NSString *content = [[NSString alloc] initWithData:(NSData *)value encoding:NSUTF8StringEncoding];
//            if (content) {
//                NSLog(@"%@",content);
//            }
//        }else{
//            UIImage *image = [[UIImage alloc] initWithData:(NSData *)value];
//            if (image) {
//                self->_imageView.image = image;
//            }
//        }
//    } fail:^{
//        
//    }];
}

- (void)clickSync{
    dispatch_queue_t concurrentQueue = dispatch_queue_create("my.concurrent.queue", DISPATCH_QUEUE_SERIAL);
    NSLog(@"1");
    dispatch_async(concurrentQueue, ^(){
        NSLog(@"isMain:%@",@([NSThread isMainThread]));
        NSLog(@"2");
        [NSThread sleepForTimeInterval:3];
        NSLog(@"3");
    });
    NSLog(@"4");
}

- (void)asyncHZ{
    _fs_dispatch_global_queue_async(^{
        CGRect rect = CGRectMake(0, 0, 300, 300);
        UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        [[UIColor redColor] set];
        CGContextFillRect(context, rect);
        
        // 1.
        NSString *text = @"我是一段文字";
        [text drawInRect:CGRectMake(10, 10, 100, 44) withAttributes:nil];

        UIImage *temp = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        _fs_dispatch_main_queue_async(^{
            NSLog(@"image:(width:%f,height:%f)",temp.size.width,temp.size.height);
            
            UIImageView *imageview = [[UIImageView alloc] initWithFrame:CGRectMake(10, 238, 300, 300)];
            imageview.image = temp;
            [self.view addSubview:imageview];
            
        });
    });
}

- (void)clickBlock{
    __weak __block NSString *what = @(_fs_timeIntevalSince1970()).stringValue;
    NSLog(@"init:%@",what);
    _fs_dispatch_global_queue_sync(^{
        what = @(_fs_timeIntevalSince1970()).stringValue;
    });
    NSLog(@"blocked:%@",what);
}

- (void)clickThreads{
    for (int x = 0; x < 10; x ++) {
        _fs_dispatch_global_queue_async(^{
            NSThread *thread = [NSThread currentThread];
            if (!thread.name) {
                NSString *thread_name = [[NSString alloc] initWithFormat:@"TN_%@",@(x)];
                [thread setName:thread_name];
            }
            NSLog(@"Thread_name:%@",thread.name);
            sleep(1);
        });
    }
}

- (void)clickAutoreleasepool{
    NSString *str = nil;
    @autoreleasepool {
        str = [NSString stringWithFormat:@"sunnyxx"];
    }
    NSLog(@"%@", str); // Console: (null)
}

- (void)quickSortMethod{
    int array[] = {12,20,80,91,56,32,12,33,100,55,78,90,22};
    quickSort(array, 0, 12);
}

void quickSort(int array[],int left,int right){     // 快速排序，效率最高的排序
    if (left < right) {
        int i = left;
        int j = right;
        int x = array[left];
        while (i < j) {
            while (i < j && array[j] >= x) {
                j --;
            }
            array[i] = array[j];
            
            while (i < j && array[i] <= x) {
                i ++;
            }
            array[j] = array[i];
        }
        array[i] = x;
        quickSort(array, left, i --);
        quickSort(array, i + 1, right);
    }
}

- (void)selection:(NSArray<NSNumber *> *)array position:(NSInteger)position{  // 选择排序
    NSInteger count = array.count;
    static NSMutableArray *indexes = nil;
    if (!indexes) {
        indexes = [[NSMutableArray alloc] initWithArray:array];
    }
    if (count == position) {    // 结束
        NSLog(@"%@",indexes);
        return;
    }
    NSInteger index = NSNotFound;
    NSInteger origin = [indexes[position] integerValue];
    for (NSInteger x = position; x < count; x ++) {
        NSInteger e = [indexes[x] integerValue];
        if (e < origin) {
            index = x;
            origin = e;
        }
    }
    
    if (index != NSNotFound) {
        NSNumber *old = indexes[position];
        [indexes replaceObjectAtIndex:position withObject:indexes[index]];
        [indexes replaceObjectAtIndex:index withObject:old];
    }
    position ++;
    [self selection:array position:position];
}

- (void)KVC{
    [self setValue:@"abc" forKey:@"fuswift"];   // 该方法不存在，崩溃
}

- (void)stringDealloc{
    NSString *staticString = @"a";
    __unsafe_unretained NSString *other = staticString;
    NSString *str = [@"b" mutableCopy];
    __unsafe_unretained NSString *b = str;
    NSArray *array = @[@1];
    __unsafe_unretained NSArray *temp = array;
    @try{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"HHHHHHHHHHHHH");
            NSLog(@"%@",other); // 不崩溃 other为 NSCFConstantString，静态字符串不会释放
            NSLog(@"%@",b);     // 崩溃，b为NSString，此时已经释放
            NSLog(@"%@",temp);  // 崩溃
        });
    }@catch(NSException *e){
        
    }@finally{
        
    }
}

- (void)permutations{
    NSArray *abs = [self alphabets];
    [self permutationsForSource:abs position:0 count:6];
}

int _visited[100]={0};
- (void)permutationsForSource:(NSArray *)source position:(NSInteger)num count:(NSInteger)k{
    static NSMutableArray *indexes = nil;
    if (!indexes) {
        indexes = [[NSMutableArray alloc] init];
    }
    
    if(k == num){
        NSMutableArray *need = [[NSMutableArray alloc] initWithCapacity:k];
        for(int i = 0;i < num; i++){
            NSInteger indexI = [indexes[i] integerValue];
            NSString *e = source[indexI];
            [need addObject:e];
        }
        static NSString *p = @"a";
        NSString *value = [[NSString alloc] initWithFormat:@"%@%@%@%@%@%@",need[0],p,need[1],p,need[2],p];
        NSLog(@"%@",value);
        return;
    }
    
    for(int i = 0;i < source.count; i++){
        if(_visited[i] == 0){
            [indexes addObject:@(i)];
            _visited[i] = 1;
            num ++;
            [self permutationsForSource:source position:num count:k];
            [indexes removeLastObject];
            num --;
            _visited[i] = 0;
        }
    }
}

/*
    对任何一个位置的取值进行递归，他的取值是已取值剩下的可取数
 */

- (NSInteger)indexOfPosition:(NSInteger)position hasMarked:(NSMutableArray<NSString *> *)marks source:(NSArray *)source{
    
    NSMutableArray *list = [[NSMutableArray alloc] initWithArray:source];
    [list removeObjectsInArray:marks];
    for (int x = 0; x < list.count; x ++) {   // 每个都有 souce.count - position 种选择
        NSString *e = list[x];
        
        [marks addObject:e];
    }
    
    return NSNotFound;
}

/*
 1.索引数组，取几个数，就几个索引的数组；每次循环，索引数组的每个位置都存入索引；遍历索引数组，取到值。~~~~~~ 为 1 次循环。
 2.如何给索引数组存入值？（）
 3.思路是：每位都从前往后遍历，
 */
- (void)source:(NSArray<NSString *> *)source position:(NSInteger)position count:(NSInteger)count hasMarked:(NSMutableArray<NSNumber *> *)indexes NUM:(NSInteger)NUM{
    for (int x = 0; x < source.count - indexes.count; x ++) {
        
    }
    if (indexes.count == NUM) {
        for (int x = 0; x < NUM; x ++) {
            NSInteger i = [indexes[x] integerValue];
            NSLog(@"%@",source[i]);
        }
        NSLog(@"\n\n");
        [indexes removeAllObjects];
    }else{
        [self source:source position:position + 1 count:count hasMarked:indexes NUM:NUM];
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
    int a = 1;
    int b = 2;
    [self swap:&a b:&b];
    NSLog(@"%d,%d",a,b);
}

- (void)swap:(int*)a b:(int*)b{
    *a = *a ^ *b;
    *b = *b ^ *a;
    *a = *a ^ *b;
}

- (void)aboutCopyString{
    NSString *a = @"china";
    NSString *b = [a copy];
    NSMutableString *m = [a mutableCopy];
    NSMutableString *o = [a mutableCopy];
    [m appendString:@" win"];
    NSLog(@"m:%@\no:%@\nb:%@",m,o,b);
}

- (void)aboutCopy{
    NSMutableArray *element = [NSMutableArray arrayWithObject:@1];
    NSMutableArray *array = [NSMutableArray arrayWithObject:element];
    NSMutableArray *mutableCopyArray = [array mutableCopy];
    [mutableCopyArray[0] addObject:@2];
    NSLog(@"%@\n\n",array[0]);
    
    NSArray *deepCopyArray = [[NSArray alloc] initWithArray:array copyItems:YES];
    NSLog(@"%@\n\n",deepCopyArray);
    
    NSLog(@"after:%@\n\n",array[0]);
}

- (void)metaClass{
    _fs_spendTimeInDoSomething(^{
        NSInteger x = 0;
        FSModel *m = [[FSModel alloc] init];
        while (x < 1000000) {
            [FSRuntime setValue:@[] forIvarName:@"aid" ofObject:m];
            //            [FSRuntime setValue:@[] forPropertyName:@"aid" ofObject:m];
            x ++;
        }
    }, ^(double time) {
        NSLog(@"time:%lf",time);
    });
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

/*
 for (int x = 0; x < 10; x ++) {
 _fs_dispatch_global_queue_async(^{
 NSThread *thread = [NSThread currentThread];
 if (!thread.name) {
 thread.name = [[NSString alloc] initWithFormat:@"WhatsThread_%d",x];
 }
 NSLog(@"Thread name:%@",thread.name);
 });
 }
 
 */

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
