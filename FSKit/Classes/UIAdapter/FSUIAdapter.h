//
//  FSUIAdapter.h
//  Pods
//
//  Created by 扶冬冬 on 2021/2/1.
//

#import <Foundation/Foundation.h>
#import "FSUIAdapterModel.h"
#import <UIKit/UIKit.h>

#define UIScreenLong                FSUIAdapter.sharedInstance.screenbiggerValue
#define UIScreenShort               FSUIAdapter.sharedInstance.screenSmallerValue
#define UIScreenHeight              [UIScreen mainScreen].bounds.size.height
#define UIScreenWidth               [UIScreen mainScreen].bounds.size.width

#define UIAdapterModel              FSUIAdapter.sharedInstance.model            // 全比例
#define UIAdapterModel1p8           FSUIAdapter.sharedInstance.model1p88        // 高高比例
#define UIAdapterModel1p7           FSUIAdapter.sharedInstance.model1p75        // 高比例
#define UIAdapterModel1p6           FSUIAdapter.sharedInstance.model1p6         // 大比例
#define UIAdapterModel1p3           FSUIAdapter.sharedInstance.model1p3         // 中比例
#define UIAdapterModel1p1           FSUIAdapter.sharedInstance.model1p1         // 小比例

#define UIAdapterIPadValue          FSUIAdapter.sharedInstance.iPadValue        // iPad上有值，iPhone上无值，采用大比例

#define UIAdapterSafeInsets         FSUIAdapter.sharedInstance.safeInsets

// 屏幕比例值 - 高(矮)
#define UIScreenHeight_05           FSUIAdapter.sharedInstance.height05
#define UIScreenHeight_10           FSUIAdapter.sharedInstance.height10
#define UIScreenHeight_15           FSUIAdapter.sharedInstance.height15
#define UIScreenHeight_20           FSUIAdapter.sharedInstance.height20
#define UIScreenHeight_25           FSUIAdapter.sharedInstance.height25
#define UIScreenHeight_30           FSUIAdapter.sharedInstance.height30
#define UIScreenHeight_35           FSUIAdapter.sharedInstance.height35
#define UIScreenHeight_40           FSUIAdapter.sharedInstance.height40
#define UIScreenHeight_45           FSUIAdapter.sharedInstance.height45
#define UIScreenHeight_50           FSUIAdapter.sharedInstance.height50
#define UIScreenHeight_55           FSUIAdapter.sharedInstance.height55
#define UIScreenHeight_60           FSUIAdapter.sharedInstance.height60
#define UIScreenHeight_65           FSUIAdapter.sharedInstance.height65
#define UIScreenHeight_70           FSUIAdapter.sharedInstance.height70
#define UIScreenHeight_75           FSUIAdapter.sharedInstance.height75
#define UIScreenHeight_80           FSUIAdapter.sharedInstance.height80
#define UIScreenHeight_85           FSUIAdapter.sharedInstance.height85
#define UIScreenHeight_90           FSUIAdapter.sharedInstance.height90
#define UIScreenHeight_95           FSUIAdapter.sharedInstance.height95

// 屏幕比例值 - 长(高)
#define UIScreenWidth_05            FSUIAdapter.sharedInstance.width05
#define UIScreenWidth_10            FSUIAdapter.sharedInstance.width10
#define UIScreenWidth_15            FSUIAdapter.sharedInstance.width15
#define UIScreenWidth_20            FSUIAdapter.sharedInstance.width20
#define UIScreenWidth_25            FSUIAdapter.sharedInstance.width25
#define UIScreenWidth_30            FSUIAdapter.sharedInstance.width30
#define UIScreenWidth_35            FSUIAdapter.sharedInstance.width35
#define UIScreenWidth_40            FSUIAdapter.sharedInstance.width40
#define UIScreenWidth_45            FSUIAdapter.sharedInstance.width45
#define UIScreenWidth_50            FSUIAdapter.sharedInstance.width50
#define UIScreenWidth_55            FSUIAdapter.sharedInstance.width55
#define UIScreenWidth_60            FSUIAdapter.sharedInstance.width60
#define UIScreenWidth_65            FSUIAdapter.sharedInstance.width65
#define UIScreenWidth_70            FSUIAdapter.sharedInstance.width70
#define UIScreenWidth_75            FSUIAdapter.sharedInstance.width75
#define UIScreenWidth_80            FSUIAdapter.sharedInstance.width80
#define UIScreenWidth_85            FSUIAdapter.sharedInstance.width85
#define UIScreenWidth_90            FSUIAdapter.sharedInstance.width90
#define UIScreenWidth_95            FSUIAdapter.sharedInstance.width95

NS_ASSUME_NONNULL_BEGIN

@interface FSUIAdapter : NSObject

+ (FSUIAdapter *)sharedInstance;

/**
 * 判断是否为iPad
 */
@property (nonatomic, readonly) BOOL    isIPad;

/**
 * 判断是否为iPhone
 */
@property (nonatomic, readonly) BOOL    isIPhone;


/**
 * 屏幕宽高中，较小的值
 */
@property (nonatomic, readonly) CGFloat screenSmallerValue;
@property (nonatomic, readonly) CGFloat screenbiggerValue;


/**
 * iPad和iPhone分别取不同的值，非iPad都返回iPhone
 */
CGFloat _differentValueForIPad(CGFloat iPad, CGFloat iPhone);

/**
 *  全比例：根据屏幕的高来比例缩放，手机以iPhone6的375为基数1，iPad以10.2英寸的810为基数1
 *  在设计的常用尺寸（手机414、iPad1024）上，倍数关系是：2.47；设计视觉尺寸（高度1242和2048）上，手机是iPad的60.64%，约为：60%。
 */
@property (nonatomic, strong) FSUIAdapterModel    *model;

/**
 *  高比例：根据屏幕的高来比例缩放，手机以iPhone6的375为基数1，iPad以10.2英寸的810为基数1
 *  在设计的常用尺寸（手机414、iPad1024）上，倍数关系是：2.15；设计视觉尺寸（高度1242和2048）上，手机是iPad的69.68%，约为：70%。
 */
@property (nonatomic, strong) FSUIAdapterModel    *model1p88;

/**
 *  高比例：根据屏幕的高来比例缩放，手机以iPhone6的375为基数1，iPad以10.2英寸的810为基数1
 *  在设计的常用尺寸（手机414、iPad1024）上，倍数关系是：2.00；设计视觉尺寸（高度1242和2048）上，手机是iPad的74.85%，约为：75%。
 */
@property (nonatomic, strong) FSUIAdapterModel    *model1p75;

/**
 *  大比例：根据屏幕的高来比例缩放，手机以iPhone6的375为基数1，iPad以10.2英寸的810为基数1
 *  在设计的常用尺寸（手机414、iPad1024）上，倍数关系是：1.83；设计视觉尺寸（高度1242和2048）上，手机是iPad的81.87%，约为：82%。
 */
@property (nonatomic, strong) FSUIAdapterModel    *model1p6;

/**
 * 中比例：iPad上乘以1.3，iPad上高度60的按钮，在手机上高度是46
 * 在设计的常用尺寸（手机414、iPad1024）上，倍数关系是：1.49；设计视觉尺寸（高度1242和2048）上，手机是iPad的100%，约为：100%。
 *
 */
@property (nonatomic, strong) FSUIAdapterModel    *model1p3;

/**
 * 小比例：iPad上乘以1.135，iPad上高度60的按钮，在手机上高度是55
 * 在设计的常用尺寸（手机414、iPad1024）上，倍数关系是：1.30；设计视觉尺寸（高度1242和2048）上，手机是iPad的115.34%，约为：115%。
 */
@property (nonatomic, strong) FSUIAdapterModel    *model1p1;

/**
 *  iPad上有值，iPhone上无值，采用大比例，参考model1p6
 */
@property (nonatomic, readonly) FSUIAdapterModel  *iPadValue;


/**
 * 宽（矮）的比例值
 */
@property (nonatomic, readonly) CGFloat             height05;    // 高度的5%
@property (nonatomic, readonly) CGFloat             height10;    // 高度的10%
@property (nonatomic, readonly) CGFloat             height15;    // 高度的15%
@property (nonatomic, readonly) CGFloat             height20;    // 高度的20%
@property (nonatomic, readonly) CGFloat             height25;    // 高度的25%
@property (nonatomic, readonly) CGFloat             height30;    // 高度的30%
@property (nonatomic, readonly) CGFloat             height35;    // 高度的35%
@property (nonatomic, readonly) CGFloat             height40;    // 高度的40%
@property (nonatomic, readonly) CGFloat             height45;    // 高度的45%
@property (nonatomic, readonly) CGFloat             height50;    // 高度的50%
@property (nonatomic, readonly) CGFloat             height55;    // 高度的55%
@property (nonatomic, readonly) CGFloat             height60;    // 高度的60%
@property (nonatomic, readonly) CGFloat             height65;    // 高度的65%
@property (nonatomic, readonly) CGFloat             height70;    // 高度的70%
@property (nonatomic, readonly) CGFloat             height75;    // 高度的75%
@property (nonatomic, readonly) CGFloat             height80;    // 高度的80%
@property (nonatomic, readonly) CGFloat             height85;    // 高度的85%
@property (nonatomic, readonly) CGFloat             height90;    // 高度的90%
@property (nonatomic, readonly) CGFloat             height95;    // 高度的95%

/**
 * 长（高）的比例值
 */
@property (nonatomic, readonly) CGFloat             width05;     // 长度的5%
@property (nonatomic, readonly) CGFloat             width10;     // 长度的10%
@property (nonatomic, readonly) CGFloat             width15;     // 长度的15%
@property (nonatomic, readonly) CGFloat             width20;     // 长度的20%
@property (nonatomic, readonly) CGFloat             width25;     // 长度的25%
@property (nonatomic, readonly) CGFloat             width30;     // 长度的30%
@property (nonatomic, readonly) CGFloat             width35;     // 长度的35%
@property (nonatomic, readonly) CGFloat             width40;     // 长度的40%
@property (nonatomic, readonly) CGFloat             width45;     // 长度的45%
@property (nonatomic, readonly) CGFloat             width50;     // 长度的50%
@property (nonatomic, readonly) CGFloat             width55;     // 长度的55%
@property (nonatomic, readonly) CGFloat             width60;     // 长度的60%
@property (nonatomic, readonly) CGFloat             width65;     // 长度的65%
@property (nonatomic, readonly) CGFloat             width70;     // 长度的70%
@property (nonatomic, readonly) CGFloat             width75;     // 长度的75%
@property (nonatomic, readonly) CGFloat             width80;     // 长度的80%
@property (nonatomic, readonly) CGFloat             width85;     // 长度的85%
@property (nonatomic, readonly) CGFloat             width90;     // 长度的90%
@property (nonatomic, readonly) CGFloat             width95;     // 长度的95%

/**
 * 安全区，需要外部赋值
 */
@property (nonatomic, assign) UIEdgeInsets          safeInsets;
@property (nonatomic, assign) CGFloat               safeWidth;
@property (nonatomic, assign) CGFloat               safeHeight;

@end

@interface UIView (Util)

@property CGFloat height;
@property CGFloat width;

@property CGFloat top;
@property CGFloat left;
@property CGFloat bottom;
@property CGFloat right;


/**
 * 圆角
 * 使用自动布局，需要在layoutsubviews 中使用
 * @param radius 圆角尺寸
 * @param corner 圆角位置
 */
- (void)radiusWithRadius:(CGFloat)radius corner:(UIRectCorner)corner;
- (void)cornerWithLeftTop:(CGFloat)leftTop
                 rightTop:(CGFloat)rigtTop
               bottomLeft:(CGFloat)bottemLeft
              bottomRight:(CGFloat)bottemRight
                    frame:(CGRect)frame;

/**
 * 给视图添加阴影
 */
- (void)shadowColor:(UIColor *)shadowColor
       shadowOffset:(CGSize)size
            opacity:(CGFloat)opacity;

/**
 * 视图添加渐变色
 */
+ (CAGradientLayer *)gradientView:(UIView *)view frame:(CGRect)frame startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint colors:(NSArray *)colors locations:(NSArray *)locations;

- (UIEdgeInsets)safeAreaInsets_fs;

@end


NS_ASSUME_NONNULL_END
