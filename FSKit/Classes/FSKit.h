////
////  FSKit.h
////  Pods
////
////  Created by fudon on 2017/6/17.
////
////
//
//#import <UIKit/UIKit.h>
//#import "FSRuntime.h"
//#import "FSDate.h"
//
//// 一年的秒数
//static CGFloat FSKitYearSeconds = 31556926.08;
//
///**
// *  64位能表示的最大带符号整数是9223372036854775807，也就是约922 3372 0368 5477 5807，922亿亿，精确到小数点后5位，即能表示的最大数是922000 亿，92万亿
// *  现在已经有几十万亿市值的公司，所以精确到小数点后5位是有一定风险的；精确到小数点后4位，能表示的最大数是9220000 亿，920万亿，够用到2100年了吧
// */
//static NSInteger FSFiveDecimalPlaces = 100000;    // 支持小数点后5位，支持汇率（4位），必须是整数，有数据用其取余
//
//@interface FSKit : NSObject
//
//void _fs_userDefaults_setObjectForKey(id object,NSString *key);
//id _fs_userDefaults_objectForKey(NSString *key);
//void _fs_clearUserDefaults(void);
//
//+ (id)objectFromJSonstring:(NSString *)jsonString;
//
//+ (BOOL)popToController:(NSString *)className navigationController:(UINavigationController *)navigationController animated:(BOOL)animated;
//
//+ (void)pushToViewControllerWithClass:(NSString *)className navigationController:(UINavigationController *)navigationController param:(NSDictionary *)param configBlock:(void (^)(id vc))configBlockParam;
//+ (id)controllerWithClass:(NSString *)className param:(NSDictionary *)param configBlock:(void (^)(id vc))configBlockParam;
//
//+ (void)presentToViewControllerWithClass:(NSString *)className controller:(UIViewController *)viewController param:(NSDictionary *)param configBlock:(void (^)(UIViewController *vc))configBlockParam presentCompletion:(void(^)(void))completion;
//+ (void)copyToPasteboard:(NSString *)copyString;
//
//+ (void)letScreenLock:(BOOL)lock;                           // YES:让屏幕锁屏    NO：让屏幕不锁屏   【未测】
//+ (void)gotoAppCentPageWithAppId:(NSString *)appID;         // 去App评分页
//
//+ (BOOL)isValidateEmail:(NSString *)str;
//
//+ (BOOL)isChinese:(NSString *)string;
//+ (BOOL)isValidateUserPasswd :(NSString *)str;
//+ (BOOL)isChar:(NSString *)str;
//+ (BOOL)isNumber:(NSString *)str;
//+ (BOOL)isString:(NSString *)aString containString:(NSString *)bString;
//+ (BOOL)isStringContainsStringAndNumber:(NSString *)sourceString;
//+ (BOOL)isURLString:(NSString *)sourceString;//0
//// 判断字符串是否含有中文
//+ (BOOL)isHaveChineseInString:(NSString *)string;
//// 判断字符串是否全为数字
//+ (BOOL)isAllNum:(NSString *)string;
//
//BOOL _fs_isPureInt(NSString *string);
//BOOL _fs_isPureFloat(NSString *string);
//BOOL _fs_isValidateString(NSString *string);
//BOOL _fs_isValidateArray(NSArray *array);
//BOOL _fs_isValidateDictionary(NSDictionary *dictionary);
//BOOL _fs_floatEqual(CGFloat aNumber,CGFloat bNumber);
//
//// 判断是否为中文语言环境
//+ (BOOL)isChineseEnvironment;
//
//+ (double)forwardValue:(double)number afterPoint:(int)position;  // 只入不舍
//+ (double)usedMemory;                                                               // 获得应用占用的内存，单位为M
//+ (double)availableMemory;                                                          // 获得当前设备可用内存,单位为M
//+ (NSInteger)folderSizeAtPath:(NSString*)folderPath extension:(NSString *)extension;// 获取文件夹目录下的文件大小
//+ (NSInteger)fileSizeAtPath:(NSString*)filePath;                                    // 获取文件的大小
//
//// 获取磁盘大小（单位：Byte）
//+ (CGFloat)diskOfAllSizeBytes;
//// 磁盘可用空间
//+ (CGFloat)diskOfFreeSizeBytes;
////获取文件夹下所有文件的大小
//+ (long long)folderSizeAtPath:(NSString *)folderPath;
//// 手机可用内存
//+ (double)availableMemoryNew;
//// 当前app所占内存（RAM）
//+ (double)currentAppMemory;
//+ (CGSize)keyboardNotificationScroll:(NSNotification *)notification baseOn:(CGFloat)baseOn;
//
//+ (CGFloat)freeStoragePercentage;   // 可用内存占总内存的比例,eg  0.1;
//+ (NSInteger)getTotalDiskSize;   // 获取磁盘总量
//+ (NSInteger)getAvailableDiskSize;   // 获取磁盘可用量
//
//// 根据键盘通知获取键盘高度
//+ (CGSize)keyboardSizeFromNotification:(NSNotification *)notification;
//
//+ (NSString *)appVersionNumber;                                                     // 获得版本号
//+ (NSString *)appLongVersionNumber;                                                 // 获得版本号
//+ (NSString *)appName;  // App名字
//+ (NSString *)appBundleName; // 获得应用Bundle，如com.hope.myhome的myhome
//+ (NSString *)iPAddress;
//+ (NSString *)randomNumberWithDigit:(int)digit;
//+ (NSString *)blankInChars:(NSString *)string byCellNo:(int)num;
//+ (NSString *)jsonStringWithObject:(id)dic;
//
//+ (NSString *)homeDirectoryPath:(NSString *)fileName;
//+ (NSString *)documentsPath:(NSString *)fileName;
//+ (NSString *)temporaryDirectoryFile:(NSString *)fileName;
//
//NSString *_fs_md5(NSString *str);
//
//+ (NSString *)stringDeleteNewLineAndWhiteSpace:(NSString *)string;
//+ (NSString *)macaddress;
//+ (NSString *)asciiCodeWithString:(NSString *)string;
//+ (NSString *)stringFromASCIIString:(NSString *)string;
//+ (NSString *)DataToHex:(NSData *)data;                          // 将二进制转换为16进制再用字符串表示
//+ (NSString *)cleanString:(NSString *)str;
//
//+ (NSString *)bankStyleData:(CGFloat)data;
//+ (NSString *)bankStyleDataThree:(CGFloat)data;
//
//+ (NSNumberFormatter *)bankStyleFormatter;
//+ (NSString *)bankStyleDataThreeForCents:(NSInteger)cents;
//+ (NSString *)bankStyleDataThreeForCents:(NSInteger)cents formatter:(NSNumberFormatter *)formatter;
//
//+ (NSString *)fourNoFiveYes:(float)number afterPoint:(int)position;  // 四舍五入
//+ (NSString *)decimalNumberMutiplyWithString:(NSString *)multiplierValue  valueB:(NSString *)multiplicandValue;
//
//NSComparisonResult _fs_highAccuracy_compare(NSString *a, NSString *b);
//
//+ (NSString *)dayMonthYearForNumber:(CGFloat)number;
//
//// 计算增长率
//+ (CGFloat)growthRate:(CGFloat)number base:(CGFloat)base;
//
///**
// *  浮点数转整数，扩大100倍，如1.01变为 101；将以元为单位的字符串数字转化为以分为单位的整数
// */
//+ (NSInteger)numberStringToTwoDecimalPlaces:(NSString *)floatString;
//
///**
// *  浮点数转整数，扩大100000倍，如1.00001变为 100001
// */
//+ (NSInteger)numberStringToFiveDecimalPlaces:(NSString *)floatString;
//
///**
// *  高精度，浮点数转整数
// */
//+ (NSInteger)floatToInt:(NSString *)floatString;
//
///**
// *  记账的数字必须符合规范：只能是数字或小数点，小数点最多只能有1个，小数点后最多只能2位数
// */
//+ (BOOL)isFSAccountNumber:(NSString *)text;
//
//+ (NSString *)showBetterFor2DigitInteger:(NSInteger)value;
//+ (NSString *)showBetterFor3DigitInteger:(NSInteger)value;
//+ (NSString *)showBetterFor5DigitInteger:(NSInteger)value;
//
//+ (NSString *)showByTenThousand:(CGFloat)value money:(BOOL)money;
//
//+ (NSString *)base64StringForText:(NSString *)text;     // 将字符串转换为base64编码
//+ (NSString *)textFromBase64String:(NSString *)text;    // 将base64转换为字符串
//+ (NSString *)base64Code:(NSData *)data;                // 用来将图片转换为字符串
//+ (NSString *)sessionID:(NSURLResponse *)response;
//
//+ (NSString *)countOverTime:(NSTimeInterval)time;   // 把秒转换为天时分
//+ (NSString *)convertNumbers:(NSString *)string;    // SQLite3的表名不能是数字，所以可以用这方法转成拼音
//+ (NSString *)pinyinForHans:(NSString *)chinese;        // 获取汉字的拼音
//+ (NSString *)pinyinForHansClear:(NSString *)chinese;        // 获取汉字的拼音，没有空格
//+ (NSString*)reverseWordsInString:(NSString*)str;       // 字符串反转
//+ (NSString *)scanQRCode:(UIImage *)image;  // 解析二维码
//+ (NSString *)dataToHex:(NSData *)data;
//+ (NSData *)convertHexStrToData:(NSString *)str;
//
///*  NSAttributedString *connectAttributedString = [FuData attributedStringFor:connectString colorRange:@[[NSValue valueWithRange:connectRange]] color:GZS_RedColor textRange:@[[NSValue valueWithRange:connectRange]] font:FONTFC(25)];*/
//+ (NSAttributedString *)attributedStringFor:(NSString *)sourceString colorRange:(NSArray *)colorRanges color:(UIColor *)color textRange:(NSArray *)textRanges font:(UIFont *)font;
//+ (NSAttributedString *)attributedStringFor:(NSString *)sourceString strings:(NSArray *)colorStrings color:(UIColor *)color fontStrings:(NSArray *)fontStrings font:(UIFont *)font;
//
//+ (NSString *)firstCharacterWithString:(NSString *)string;
//+ (NSString *)forthCarNumber:(NSString *)text;
//
////     strikeLabel.attributedText = attribtStr;
//- (NSAttributedString *)middleLineForLabel:(NSString *)text;    // 中划线
//- (NSAttributedString *)underLineForLabel:(NSString *)text;     // 下划线
//
//+ (void)call:(NSString *)phone;
//+ (void)callPhoneWithNoNotice:(NSString *)phone;
//+ (void)openAppByURLString:(NSString *)str;
//
//+ (NSArray *)arrayFromArray:(NSArray *)array withString:(NSString *)string;
//+ (NSArray *)arrayByOneCharFromString:(NSString *)string;
//+ (NSArray *)arrayReverseWithArray:(NSArray *)array;
//+ (NSArray *)maxandMinNumberInArray:(NSArray *)array;                           // 找出数组中最大的数 First Max, Last Min
//+ (NSArray *)maopaoArray:(NSArray *)array;
//+ (NSArray *)addCookies:(NSArray *)nameArray value:(NSArray *)valueArray cookieDomain:(NSString *)cookName;
//+ (NSArray *)deviceInfos;
//
////压缩图片到指定文件大小
//+ (NSData *)compressOriginalImage:(UIImage *)image toMaxDataSizeKBytes:(CGFloat)size;
//
//+ (NSNumber *)fileSize:(NSString *)filePath;
//
//UIColor *_fs_randomColor(void);
//
//+ (UIColor *)colorWithHexString:(NSString *)color;               // 根据16进制字符串获得颜色类对象
//
//// 主要用于汉字倾斜,系统UIFont没有直接支持汉字倾斜。可以使字体倾斜rate角度，rate在0-180之间，取15较好；fontSize是字体大小。
//+ (UIFont *)angleFontWithRate:(CGFloat)rate fontSize:(NSInteger)fontSize;
//
//// 单位转换方法
//NSString* _fs_KMGUnit(NSInteger size);
//
//+ (NSURL *)convertTxtEncoding:(NSURL *)fileUrl;
//
//// 将文件拷贝到tmp目录
//+ (NSURL *)fileURLForBuggyWKWebView8:(NSURL *)fileURL;
//
//+ (id)storyboardInstantiateViewControllerWithStoryboardID:(NSString *)storybbordID;
//
//void _fs_spendTimeInDoSomething(void(^body)(void),void(^time)(double time));
//
//// userDefault只执行一次，即key对应的值不存在时，走event，存在，就不走
//void _fs_userDefaultsOnce(NSString *key,void (^event)(void));
//
//// GCD方法
//void _fs_dispatch_global_main_queue_async(dispatch_block_t _global_block,dispatch_block_t _main_block);
//void _fs_dispatch_main_queue_async(dispatch_block_t _main_block);
//void _fs_dispatch_main_queue_sync(dispatch_block_t _main_block);
//void _fs_dispatch_global_queue_async(dispatch_block_t _global_block);
//void _fs_dispatch_global_queue_sync(dispatch_block_t _global_block);
//
////void _fs_runloop_observer(void);
//void _fs_runloop_freeTime_event(void(^event)(void));
//
//// 高精度计算
//NSString *_fs_highAccuracy_add(NSString *a,NSString *b);        // 加
//NSString *_fs_highAccuracy_subtract(NSString *a,NSString *b);   // 减
//NSString *_fs_highAccuracy_multiply(NSString *a,NSString *b);   // 乘
//NSString *_fs_highAccuracy_divide(NSString *a,NSString *b);     // 除
//
//// 获取url中的参数
//+ (NSDictionary *)urlParametersFromUrl:(NSURL *)url;
//// 交换方法
//+ (void)method_Swizzle:(Class)cls origin:(SEL)oriSel swizzle:(SEL)swiSel;
//
//// 优化左滑手势与滑动视图的冲突
//+ (void)fitScrollViewOperate:(UIScrollView *)scrollView navigationController:(UINavigationController *)navigationController;
//
///**
// *  显示字符串的部分信息，其他用*代替，front、tail为前后显示的长度
// */
//+ (NSString *)showStringPart:(NSString *)string front:(NSInteger)front tail:(NSInteger)tail;
//+ (NSString *)showStringPart:(NSString *)string front:(NSInteger)front tail:(NSInteger)tail placeholder:(NSString *)placeholder;
//
///**
// *  当前的 Window Scene
// */
//+ (UIWindowScene *)currentWindowScene;
//
///**
// *  字符串中只保留数字部分
// */
//+ (NSString *)digitalOnlyString:(NSString *)inputString;
//
//+ (NSString *)bundleFile:(NSString *)bundle name:(NSString *)name ofType:(NSString *)type;
//
///**
// *  触感
// */
//+ (void)feedback:(UIImpactFeedbackStyle)style;
//
//+ (void)printMemoryUsage;
//
//+ (BOOL)isInt:(NSString *)string;
//+ (BOOL)isFloat:(NSString *)string;
//
//@end
