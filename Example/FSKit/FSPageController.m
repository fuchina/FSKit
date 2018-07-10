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
    NSArray         *_list;
    NSInteger       _thePage;
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
    vc1.view.tag = 1;
    
    UIViewController *vc2 = [UIViewController new];
    vc2.view.backgroundColor = [UIColor yellowColor];
    vc2.view.tag = 2;
    
    UIViewController *vc3 = [UIViewController new];
    vc3.view.backgroundColor = [UIColor blueColor];
    vc3.view.tag = 3;

    
    _list = @[vc1,vc2,vc3];
    
    [self.page setViewControllers:@[vc1] direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:nil];
}

- (UIPageViewController *)page{
    if (!_page) {
        NSDictionary *option = @{UIPageViewControllerOptionInterPageSpacingKey:@1};
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
    NSInteger count = _list.count;
    if (viewController == _list.firstObject) {
        _selectedIndex = (_list.count -1);
    }else{
        NSInteger index = [_list indexOfObject:viewController];
        if (_list.count > (index - 1)) {
            _selectedIndex = index - 1;
        }
    }
    if (count > _selectedIndex) {
        return _list[_selectedIndex];
    }
    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController{
    NSInteger count = _list.count;
    if (viewController == _list.lastObject) {
        _selectedIndex = 0;
    }else{
        NSInteger index = [_list indexOfObject:viewController];
        if (_list.count > (index + 1)) {
            _selectedIndex = index + 1;
        }
    }
    if (count > _selectedIndex) {
        return _list[_selectedIndex];
    }
    return nil;
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

// Sent when a gesture-initiated transition begins.
- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers NS_AVAILABLE_IOS(6_0){
    
}

// Sent when a gesture-initiated transition ends. The 'finished' parameter indicates whether the animation finished, while the 'completed' parameter indicates whether the transition completed or bailed out (if the user let go early).
- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed{
    if (completed) {
     
        NSLog(@"didFinishAnimating:%@",@(_selectedIndex));
    }
}

// Delegate may specify a different spine location for after the interface orientation change. Only sent for transition style 'UIPageViewControllerTransitionStylePageCurl'.
// Delegate may set new view controllers or update double-sided state within this method's implementation as well.
//- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation __TVOS_PROHIBITED{
//    return <#expression#>
//}

//- (UIInterfaceOrientationMask)pageViewControllerSupportedInterfaceOrientations:(UIPageViewController *)pageViewController NS_AVAILABLE_IOS(7_0) __TVOS_PROHIBITED;
//- (UIInterfaceOrientation)pageViewControllerPreferredInterfaceOrientationForPresentation:(UIPageViewController *)pageViewController NS_AVAILABLE_IOS(7_0) __TVOS_PROHIBITED;


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
