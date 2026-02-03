////
////  HEUIAdapter.m
////  Pods
////
////  Created by 扶冬冬 on 2021/2/1.
////
//
//#import "FSUIAdapter.h"
//
//@implementation FSUIAdapter {
//    CGFloat     _originRatioForIPhone;
//    CGFloat     _originRatioForIPad;
//}
//
//+ (FSUIAdapter *)sharedInstance {
//    static FSUIAdapter *_instance = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        _instance = [[FSUIAdapter alloc] init];
//    });
//    return _instance;
//}
//
//- (instancetype)init {
//    self = [super init];
//    if (self) {
//        _isIPad = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
//        _isIPhone = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
//        if (UIScreen.mainScreen.bounds.size.width > UIScreen.mainScreen.bounds.size.height) {
//            _screenSmallerValue = UIScreen.mainScreen.bounds.size.height;
//            _screenbiggerValue = UIScreen.mainScreen.bounds.size.width;
//        } else {
//            _screenSmallerValue = UIScreen.mainScreen.bounds.size.width;
//            _screenbiggerValue = UIScreen.mainScreen.bounds.size.height;
//        }
//        _originRatioForIPhone = _screenSmallerValue / 375.0;
//        _originRatioForIPad   = _screenSmallerValue / 810.0;
//        
//        _model1p6 = [self modelForRatio:1.6];
//        _model1p3 = [self modelForRatio:1.3];
//        
//        if (_isIPad) {
//            _iPadValue = _model1p6;
//        }
//
//        [self calculateScreenHeightRatios];
//    }
//    return self;
//}
//
//- (FSUIAdapterModel *)model {
//    if (!_model) {
//        _model = [self modelForRatio:2.16];
//    }
//    return _model;
//}
//
//- (FSUIAdapterModel *)model1p88 {
//    if (!_model1p88) {
//        _model1p88 = [self modelForRatio:1.88];
//    }
//    return _model1p88;
//}
//
//- (FSUIAdapterModel *)model1p75 {
//    if (!_model1p75) {
//        _model1p75 = [self modelForRatio:1.75];
//    }
//    return _model1p75;
//}
//
//- (FSUIAdapterModel *)model1p1 {
//    if (!_model1p1) {
//        _model1p1 = [self modelForRatio:1.135];
//    }
//    return _model1p1;
//}
//
//- (FSUIAdapterModel *)modelForRatio:(CGFloat)iPadToIPhone {
//    CGFloat ratio = _originRatioForIPhone;
//    if (_isIPad) {
//        ratio = _originRatioForIPad * iPadToIPhone;
//    }
//    FSUIAdapterModel *model = [[FSUIAdapterModel alloc] initWithRatio:ratio];
//    return model;
//}
//
//- (void)calculateScreenHeightRatios {
//    _height05 = ceil(_screenSmallerValue * .05);
//    _height10 = ceil(_screenSmallerValue * .10);
//    _height15 = ceil(_screenSmallerValue * .15);
//    _height20 = ceil(_screenSmallerValue * .20);
//    _height25 = ceil(_screenSmallerValue * .25);
//    _height30 = ceil(_screenSmallerValue * .30);
//    _height35 = ceil(_screenSmallerValue * .35);
//    _height40 = ceil(_screenSmallerValue * .40);
//    _height45 = ceil(_screenSmallerValue * .45);
//    _height50 = ceil(_screenSmallerValue * .50);
//    _height55 = ceil(_screenSmallerValue * .55);
//    _height60 = ceil(_screenSmallerValue * .60);
//    _height65 = ceil(_screenSmallerValue * .65);
//    _height70 = ceil(_screenSmallerValue * .70);
//    _height75 = ceil(_screenSmallerValue * .75);
//    _height80 = ceil(_screenSmallerValue * .80);
//    _height85 = ceil(_screenSmallerValue * .85);
//    _height90 = ceil(_screenSmallerValue * .90);
//    _height95 = ceil(_screenSmallerValue * .95);
//    
//    _width05 = ceil(_screenbiggerValue * .05);
//    _width10 = ceil(_screenbiggerValue * .10);
//    _width15 = ceil(_screenbiggerValue * .15);
//    _width20 = ceil(_screenbiggerValue * .20);
//    _width25 = ceil(_screenbiggerValue * .25);
//    _width30 = ceil(_screenbiggerValue * .30);
//    _width35 = ceil(_screenbiggerValue * .35);
//    _width40 = ceil(_screenbiggerValue * .40);
//    _width45 = ceil(_screenbiggerValue * .45);
//    _width50 = ceil(_screenbiggerValue * .50);
//    _width55 = ceil(_screenbiggerValue * .55);
//    _width60 = ceil(_screenbiggerValue * .60);
//    _width65 = ceil(_screenbiggerValue * .65);
//    _width70 = ceil(_screenbiggerValue * .70);
//    _width75 = ceil(_screenbiggerValue * .75);
//    _width80 = ceil(_screenbiggerValue * .80);
//    _width85 = ceil(_screenbiggerValue * .85);
//    _width90 = ceil(_screenbiggerValue * .90);
//    _width95 = ceil(_screenbiggerValue * .95);
//}
//
//CGFloat _differentValueForIPad(CGFloat iPad, CGFloat iPhone) {
//    if (FSUIAdapter.sharedInstance.isIPad == true) {
//        return iPad;
//    }
//    return iPhone;
//}
//
//- (void)setSafeInsets:(UIEdgeInsets)safeInsets {
//    _safeInsets = safeInsets;
//    
//    _safeWidth = UIScreenWidth - safeInsets.left - safeInsets.right;
//    _safeHeight = UIScreenHeight - safeInsets.top - safeInsets.bottom;
//}
//
//@end
//
//@implementation UIView (Util)
//
//- (CGFloat)height {
//    return self.frame.size.height;
//}
//
//- (void)setHeight: (CGFloat) newheight {
//    CGRect newframe = self.frame;
//    newframe.size.height = newheight;
//    self.frame = newframe;
//}
//
//- (CGFloat)width {
//    return self.frame.size.width;
//}
//
//- (void)setWidth:(CGFloat)newwidth {
//    CGRect newframe = self.frame;
//    newframe.size.width = newwidth;
//    self.frame = newframe;
//}
//
//- (CGFloat)top {
//    return self.frame.origin.y;
//}
//
//- (void)setTop:(CGFloat)newtop {
//    CGRect newframe = self.frame;
//    newframe.origin.y = newtop;
//    self.frame = newframe;
//}
//
//- (CGFloat)left {
//    return self.frame.origin.x;
//}
//
//- (void)setLeft:(CGFloat)newleft {
//    CGRect newframe = self.frame;
//    newframe.origin.x = newleft;
//    self.frame = newframe;
//}
//
//- (CGFloat)bottom {
//    return self.frame.origin.y + self.frame.size.height;
//}
//
//- (void)setBottom:(CGFloat)newbottom {
//    CGRect newframe = self.frame;
//    newframe.origin.y = newbottom - self.frame.size.height;
//    self.frame = newframe;
//}
//
//- (CGFloat)right {
//    return self.frame.origin.x + self.frame.size.width;
//}
//
//- (void)setRight:(CGFloat)newright {
//    CGFloat delta = newright - (self.frame.origin.x + self.frame.size.width);
//    CGRect newframe = self.frame;
//    newframe.origin.x += delta ;
//    self.frame = newframe;
//}
//
//- (void)radiusWithRadius:(CGFloat)radius corner:(UIRectCorner)corner {
//    if (@available(iOS 11.0, *)) {
//        self.layer.cornerRadius = radius;
//        self.layer.maskedCorners = (CACornerMask)corner;
//    } else {
//        UIBezierPath * path = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:corner cornerRadii:CGSizeMake(radius, radius)];
//        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
//        maskLayer.frame = self.bounds;
//        maskLayer.path = path.CGPath;
//        self.layer.mask = maskLayer;
//    }
//}
//
//- (void)shadowColor:(UIColor *)shadowColor shadowOffset:(CGSize)size opacity:(CGFloat)opacity {
//    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:self.bounds];
//    self.layer.masksToBounds = NO;
//    if ([shadowColor isKindOfClass:UIColor.class]) {
//        self.layer.shadowColor = shadowColor.CGColor;
//    }
//    self.layer.shadowOffset = size;
//    self.layer.shadowOpacity = opacity;
//    self.layer.shadowRadius = self.layer.cornerRadius;
//    self.layer.shadowPath = shadowPath.CGPath;
//}
//
//- (void)cornerWithLeftTop:(CGFloat)leftTop
//                 rightTop:(CGFloat)rigtTop
//               bottomLeft:(CGFloat)bottemLeft
//              bottomRight:(CGFloat)bottemRight
//                    frame:(CGRect)frame {
//    
//    CGFloat width = frame.size.width;
//    CGFloat height = frame.size.height;
//    
//    UIBezierPath *maskPath = [UIBezierPath bezierPath];
//    maskPath.lineWidth = 1.0;
//    maskPath.lineCapStyle = kCGLineCapRound;
//    maskPath.lineJoinStyle = kCGLineJoinRound;
//    [maskPath moveToPoint:CGPointMake(bottemRight, height)]; //左下角
//    [maskPath addLineToPoint:CGPointMake(width - bottemRight, height)];
//    
//    [maskPath addQuadCurveToPoint:CGPointMake(width, height- bottemRight) controlPoint:CGPointMake(width, height)]; //右下角的圆弧
//    [maskPath addLineToPoint:CGPointMake(width, rigtTop)]; //右边直线
//    
//    [maskPath addQuadCurveToPoint:CGPointMake(width - rigtTop, 0) controlPoint:CGPointMake(width, 0)]; //右上角圆弧
//    [maskPath addLineToPoint:CGPointMake(leftTop, 0)]; //顶部直线
//    
//    [maskPath addQuadCurveToPoint:CGPointMake(0, leftTop) controlPoint:CGPointMake(0, 0)]; //左上角圆弧
//    [maskPath addLineToPoint:CGPointMake(0, height - bottemLeft)]; //左边直线
//    [maskPath addQuadCurveToPoint:CGPointMake(bottemLeft, height) controlPoint:CGPointMake(0, height)]; //左下角圆弧
//
//    CAShapeLayer *maskLayer = [CAShapeLayer layer];
//    maskLayer.frame = frame;
//    maskLayer.path = maskPath.CGPath;
//    maskLayer.frame = frame;
//    maskLayer.path = maskPath.CGPath;
//    self.layer.mask = maskLayer;
//}
//
//+ (CAGradientLayer *)gradientView:(UIView *)view frame:(CGRect)frame startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint colors:(NSArray *)colors locations:(NSArray *)locations {
//    CAGradientLayer *gl = [CAGradientLayer layer];
//    gl.frame = frame;
//    gl.startPoint = startPoint;
//    gl.endPoint = endPoint;
//    gl.colors = colors;
//    gl.locations = locations;
////    [view.layer addSublayer:gl];
//    [view.layer insertSublayer:gl atIndex:0];
//    return gl;
//}
//
////- (UIEdgeInsets)safeAreaInsets {
////    if (@available(iOS 11.0, *)) {
////        return self.safeAreaInsets;
////    } else {
////        return UIEdgeInsetsZero;
////    }
////}
//
//@end
