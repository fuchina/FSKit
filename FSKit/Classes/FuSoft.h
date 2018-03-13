//
//  FuSoft.h
//  Pods
//
//  Created by fudon on 2017/6/17.
//
//
/*
有时在FSKit目录中增加了文件出现编译不过的问题，记录一下
操作说明
1.在Development Pods/FSKit下增加类文件；
 2.跳到物理目录下看看新建的类文件是否在Development Pods/FSKit下；
 3.pod install 一下 Podfile文件，系统自动会将新增的文件import到FSKit-umbrella.h文件中。
 
 */

#ifndef FuSoft_h
#define FuSoft_h

#ifdef DEBUG
//# define FSLog(format, ...) NSLog((@"\nFSLog:%s" "%s" "- %d\n" format), __FILE__, __FUNCTION__, __LINE__, ##__VA_ARGS__);
# define FSLog(format, ...) NSLog((@"%s" "- %d\n" format), __FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
# define FSLog(...);
#endif

/******************单例安全模式*********************/
#define SINGLE_ONCE_SAFE(A)   \
+ (instancetype)allocWithZone:(struct _NSZone *)zone{ \
if(!_w){\
static dispatch_once_t onceToken;\
dispatch_once(&onceToken, ^{\
A = [super allocWithZone:zone];\
});\
}\
return A;\
}\
+ (id)copyWithZone:(struct _NSZone *)zone{\
if(!_w){\
static dispatch_once_t onceToken;\
dispatch_once(&onceToken, ^{\
A = [super copyWithZone:zone];\
});\
}\
return A;\
}\
- (instancetype)init{\
@synchronized(self) {\
self = [super init];\
}\
return self;\
}\

/******************__system__*********************/
#define MININ(A,B)                  ({ __typeof__(A) __a = (A); __typeof__(B) __b = (B); __a < __b ? __a : __b; })
#define WEAKSELF(A)                 __weak typeof(*&self)A = self

#define HEIGHTFC                    ([UIScreen mainScreen].bounds.size.height)
#define WIDTHFC                     ([UIScreen mainScreen].bounds.size.width)
#define IOSGE(A)                    (([[UIDevice currentDevice].systemVersion floatValue] >= A)?YES:NO)
#define isIPAD                      (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define isIPHONE                    (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

#define RGBCOLOR(R, G, B, A)        ([UIColor colorWithRed:R/255.0 green:G/255.0 blue:B/255.0 alpha:A])
#define RGB16(rgbValue)             [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define IMAGENAMED(A)               [UIImage imageNamed:A]
#define ROUNDIMAGE(A,B)             ([FSKit circleImage:IMAGENAMED(A) withParam:B]) // B default is 0.
#define FONTFC(A)                   ([UIFont systemFontOfSize:A])
#define FONTBOLD(A)                 ([UIFont fontWithName:@"Helvetica-Bold" size:A])
#define FONTOBLIQUE(A)              ([UIFont fontWithName:@"Helvetica-BoldOblique" size:A])
#define FONTLIQUE(A)                ([UIFont fontWithName:@"Helvetica-Oblique" size:A])

#define FSValidateString(A)         [FSKit isValidateString:A]
#define FSValidateArray(A)          [FSKit isValidateArray:A]
#define FSValidateDictionary(A)     [FSKit isValidateDictionary:A]
#define FSLocalString(A)            NSLocalizedString(A, nil)

// 字符串格式化宏
#define FSFORMATSTRING(...)         [[NSString alloc] initWithFormat:__VA_ARGS__]

/******************__tag__**********************/
#define   TAG_VIEW               1000
#define   TAG_BUTTON             1100
#define   TAG_TABLEVIEW          1200
#define   TAG_SCROLLVIEW         1300
#define   TAG_LABEL              1400
#define   TAG_IMAGEVIEW          1500
#define   TAG_SWITCH             1600
#define   TAG_SLIDER             1700
#define   TAG_SEGMENT            1800
#define   TAG_WEBVIEW            1900
#define   TAG_MAPVIEW            2000
#define   TAG_TEXTFIELD          2100
#define   TAG_TEXTVIEW           2200
#define   TAG_PROGRESSVIEW       2300
#define   TAG_ALERT              2400
#define   TAG_PICKERVIEW         2500
#define   TAG_CELL               2900

#endif /* FuSoft_h */
