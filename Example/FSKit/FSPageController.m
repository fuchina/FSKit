//
//  FSPageController.m
//  FSKit_Example
//
//  Created by Guazi on 2018/6/21.
//  Copyright © 2018年 topchuan. All rights reserved.
//

#import "FSPageController.h"

@interface FSPageController ()<UIPageViewControllerDelegate,UIPageViewControllerDataSource>

@property (nonatomic,strong) UIPageViewController   *page;

@end

@implementation FSPageController{
    NSArray *_list;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self pageDesignViews];
}

- (void)pageDesignViews{
    CGFloat rgb = 238/255.0;
    self.view.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1];
    
    UIViewController *vc1 = [UIViewController new];
    vc1.view.backgroundColor = [UIColor redColor];
    
    UIViewController *vc2 = [UIViewController new];
    vc2.view.backgroundColor = [UIColor yellowColor];
    
    _list = @[vc1,vc2];
    
    [self.page setViewControllers:@[vc1] direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:nil];
}

- (UIPageViewController *)page{
    if (!_page) {
        NSDictionary *option = @{UIPageViewControllerOptionInterPageSpacingKey:@10};
        _page = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:option];
        _page.delegate = self;
        _page.dataSource = self;
        [self addChildViewController:_page];
        [self.view addSubview:_page.view];
    }
    return _page;
}

#pragma mark
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController{
    if (viewController == _list.firstObject) {
        return nil;
    }
    return _list.firstObject;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController{
    if (viewController == _list.lastObject) {
        return nil;
    }
    return _list.lastObject;
}

- (void)setSelectedIndex:(NSInteger)selectedIndex{
    if (selectedIndex < 0) {
        selectedIndex = 0;
    }
    if (_selectedIndex == selectedIndex) {
        return;
    }
    _selectedIndex = selectedIndex;
    if ([_list isKindOfClass:NSArray.class] && _list.count > selectedIndex) {
        UIViewController *vc = [_list objectAtIndex:selectedIndex];
        if ([vc isKindOfClass:UIViewController.class]) {
            [_page setViewControllers:@[vc] direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:nil];
        }
    }
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    NSLog(@"didFinishAnimating");
    if (completed) {
//        self.segmentView.selectedIndex = ld_currentIndex ;
    }
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
