//
//  FSKit.h
//  Pods
//
//  Created by fudon on 2017/6/17.
//
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface FSKit : NSObject

extern  NSTimeInterval FSTimeIntevalSince1970(void);
extern NSInteger FSIntegerTimeIntevalSince1970(void);

//+ (void)presentViewController:(UIViewController *)pController completion:(void (^)(void))completion;

+ (void)userDefaultsKeepData:(id)instance  withKey:(NSString *)key;
+ (id)userDefaultsDataWithKey:(NSString *)key;
+ (id)objectFromJSonstring:(NSString *)jsonString;

+ (BOOL)popToController:(NSString *)className navigationController:(UINavigationController *)navigationController animated:(BOOL)animated;

// 根据action.title映射titles中的字段来判断点击事件   UIAlertActionStyleDefault
+ (void)alertOnCustomWindow:(UIAlertControllerStyle)style title:(NSString *)title message:(NSString *)message actionTitles:(NSArray<NSString *> *)titles styles:(NSArray<NSNumber *> *)styles handler:(void (^)(UIAlertAction *action))handler cancelTitle:(NSString *)cancelTitle cancel:(void (^)(UIAlertAction *action))cancel completion:(void (^)(void))completion;
+ (void)alert:(UIAlertControllerStyle)style controller:(UIViewController *)pController title:(NSString *)title message:(NSString *)message actionTitles:(NSArray<NSString *> *)titles styles:(NSArray<NSNumber *> *)styles handler:(void (^)(UIAlertAction *action))handler;
+ (void)alert:(UIAlertControllerStyle)style controller:(UIViewController *)pController title:(NSString *)title message:(NSString *)message actionTitles:(NSArray<NSString *> *)titles styles:(NSArray<NSNumber *> *)styles handler:(void (^)(UIAlertAction *action))handler cancelTitle:(NSString *)cancelTitle cancel:(void (^)(UIAlertAction *action))cancel completion:(void (^)(void))completion;

// 有输入框时，number为输入框数量，根据textField的tag【0、1、2...】来配置textField
+ (void)alertInput:(NSInteger)number controller:(UIViewController *)controller title:(NSString *)title message:(NSString *)message ok:(NSString *)okTitle handler:(void (^)(UIAlertController *bAlert,UIAlertAction *action))handler cancel:(NSString *)cancelTitle handler:(void (^)(UIAlertAction *action))cancelHandler textFieldConifg:(void (^)(UITextField *textField))configurationHandler completion:(void (^)(void))completion;
+ (void)alertInputOnCustomWindow:(NSInteger)number title:(NSString *)title message:(NSString *)message ok:(NSString *)okTitle handler:(void (^)(UIAlertController *bAlert,UIAlertAction *action))handler cancel:(NSString *)cancelTitle handler:(void (^)(UIAlertAction *action))cancelHandler textFieldConifg:(void (^)(UITextField *textField))configurationHandler completion:(void (^)(void))completion;

+ (void)pushToViewControllerWithClass:(NSString *)className navigationController:(UINavigationController *)navigationController param:(NSDictionary *)param configBlock:(void (^)(id vc))configBlockParam;
+ (void)presentToViewControllerWithClass:(NSString *)className controller:(UIViewController *)viewController param:(NSDictionary *)param configBlock:(void (^)(UIViewController *vc))configBlockParam presentCompletion:(void(^)(void))completion;
+ (void)copyToPasteboard:(NSString *)copyString;
+ (void)playSongs:(NSString *)songs type:(NSString *)fileType;
+ (void)xuanzhuanView:(UIView *)view;

+ (void)showFullScreenImage:(UIImageView *)avatarImageView;
+ (void)clearUserDefaults;
+ (void)letScreenLock:(BOOL)lock;                           // YES:让屏幕锁屏    NO：让屏幕不锁屏   【未测】
+ (void)gotoAppCentPageWithAppId:(NSString *)appID;         // 去App评分页
+ (void)setStatusBarBackgroundColor:(UIColor *)color;       // 设置状态栏颜色

+ (void)showMessage:(NSString *)message;
+ (void)showAlertWithMessageOnCustomWindow:(NSString *)message;
+ (void)showAlertWithMessageOnCustomWindow:(NSString *)message handler:(void (^)(UIAlertAction *action))handler;
+ (void)showAlertWithTitleOnCustomWindow:(NSString *)title message:(NSString *)message ok:(NSString *)ok handler:(void (^)(UIAlertAction *action))handler;
+ (void)showAlertWithMessage:(NSString *)message controller:(UIViewController *)controller;
+ (void)showAlertWithMessage:(NSString *)message controller:(UIViewController *)controller handler:(void (^)(UIAlertAction *action))handler;
+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message ok:(NSString *)ok controller:(UIViewController *)pController handler:(void (^)(UIAlertAction *action))handler;

+ (BOOL)isValidateEmail:(NSString *)str;
+ (BOOL)isPureInt:(NSString *)string;
+ (BOOL)isPureFloat:(NSString*)string;
+ (BOOL)isLeapYear:(int)year;
+ (BOOL)isValidPassword:(NSString*)password;
+ (BOOL)keyedArchiverWithArray:(NSArray *)array toFilePath:(NSString *)fileName;
+ (BOOL)keyedArchiverWithData:(NSData *)data toFilePath:(NSString *)fileName;
+ (BOOL)keyedArchiverWithNumber:(NSNumber *)number toFilePath:(NSString *)fileName;
+ (BOOL)keyedArchiverWithString:(NSString *)string toFilePath:(NSString *)fileName;
+ (BOOL)keyedArchiverWithDictionary:(NSDictionary *)dic toFilePath:(NSString *)fileName;
+ (BOOL)createFile:(NSString *)fileName withContent:(NSString *)string;
+ (BOOL)moveFile:(NSString *)filePath toPath:(NSString *)newPath;
+ (BOOL)renameFile:(NSString *)filePath toPath:(NSString *)newPath;
+ (BOOL)copyFile:(NSString *)filePath toPath:(NSString *)newPath;
+ (BOOL)removeFile:(NSString *)filePath;
+ (BOOL)isChinese:(NSString *)string;
+ (BOOL)isValidateUserPasswd :(NSString *)str;
+ (BOOL)isChar:(NSString *)str;
+ (BOOL)isNumber:(NSString *)str;
+ (BOOL)isString:(NSString *)aString containString:(NSString *)bString;
+ (BOOL)isStringContainsStringAndNumber:(NSString *)sourceString;
+ (BOOL)isTheSameDayA:(NSDate *)aDate b:(NSDate *)bDate;
+ (BOOL)isURLString:(NSString *)sourceString;//0
// 判断字符串是否含有中文
+ (BOOL)isHaveChineseInString:(NSString *)string;
// 判断字符串是否全为数字
+ (BOOL)isAllNum:(NSString *)string;
+ (BOOL)isValidateString:(NSString *)string;
+ (BOOL)isValidateArray:(NSArray *)array;
+ (BOOL)isValidateDictionary:(NSDictionary *)dictionary;
+ (BOOL)floatEqual:(float)aNumber bNumber:(float)bNumber;
// 判断是否为中文语言环境
+ (BOOL)isChineseEnvironment;
// 五险一金后工资应缴税额
+ (CGFloat)taxForSalaryAfterSocialSecurity:(CGFloat)money;
// 根据税后推算税前
+ (NSArray *)taxRatesWithMoneyAfterTax:(CGFloat)money;
// 返回税率（index[0]）和速算扣除数(index[1])
+ (NSArray *)taxRateForMoney:(CGFloat)money;

+ (NSTimeInterval)mmSecondsSince1970;
+ (NSInteger)integerSecondsSince1970;
+ (NSInteger)weekdayStringFromDate:(NSDate *)inputDate;
// 根据年月计算当月有多少天
+ (NSInteger)daysForMonth:(NSInteger)month year:(NSInteger)year;

+ (double)forwardValue:(double)number afterPoint:(int)position;  // 只入不舍
+ (double)usedMemory;                                                               // 获得应用占用的内存，单位为M
+ (double)availableMemory;                                                          // 获得当前设备可用内存,单位为M
+ (float)folderSizeAtPath:(NSString*)folderPath extension:(NSString *)extension;    // 获取文件夹目录下的文件大小
+ (long long)fileSizeAtPath:(NSString*)filePath;                                    // 获取文件的大小
+ (CGFloat)textHeight:(NSString *)text
              fontInt:(NSInteger)fontInt                                            // 计算字符串放在label上需要的高度,font数字要和label的一样
           labelWidth:(CGFloat)labelWidth;                                          // label调用 sizeToFit 可以实现自适应
+ (double)distanceBetweenCoordinate:(CLLocationCoordinate2D)coordinateA toCoordinateB:(CLLocationCoordinate2D)coordinateB;
// 获取磁盘大小（单位：Byte）
+ (CGFloat)diskOfAllSizeBytes;
// 磁盘可用空间
+ (CGFloat)diskOfFreeSizeBytes;
//获取文件夹下所有文件的大小
+ (long long)folderSizeAtPath:(NSString *)folderPath;
// 手机可用内存
+ (double)availableMemoryNew;
// 当前app所占内存（RAM）
+ (double)currentAppMemory;
+ (CGSize)keyboardNotificationScroll:(NSNotification *)notification baseOn:(CGFloat)baseOn;
+ (CGFloat)DEBJWithYearRate:(CGFloat)rate monthes:(NSInteger)month;
+ (CGFloat)DEBXWithYearRate:(CGFloat)rate monthes:(NSInteger)month;
+ (CGFloat)freeStoragePercentage;   // 可用内存占总内存的比例,eg  0.1;
+ (NSInteger)getTotalDiskSize;   // 获取磁盘总量
+ (NSInteger)getAvailableDiskSize;   // 获取磁盘可用量

// 根据键盘通知获取键盘高度
+ (CGSize)keyboardSizeFromNotification:(NSNotification *)notification;

+ (NSString *)appVersionNumber;                                                     // 获得版本号
+ (NSString *)appName;  // App名字
+ (NSString *)appBundleName; // 获得应用Bundle，如com.hope.myhome的myhome
+ (NSString *)iPAddress;
+ (NSString *)randomNumberWithDigit:(int)digit;
+ (NSString *)blankInChars:(NSString *)string byCellNo:(int)num;
+ (NSString *)jsonStringWithObject:(id)dic;
+ (NSString *)JSONString:(NSString *)aString;
+ (NSString *)dataToString:(NSData *)data withEncoding:(NSStringEncoding)encode;
+ (NSString *)homeDirectoryPath:(NSString *)fileName;
+ (NSString *)keyedUnarchiverWithString:(NSString *)fileName;
+ (NSString *)documentsPath:(NSString *)fileName;
+ (NSString *)temporaryDirectoryFile:(NSString *)fileName;
+ (NSString *)md5:(NSString *)str;
+ (NSString *)stringDeleteNewLineAndWhiteSpace:(NSString *)string;
+ (NSString *)macaddress;
+ (NSString *)identifierForVendorFromKeyChain;
+ (NSString *)asciiCodeWithString:(NSString *)string;
+ (NSString *)stringFromASCIIString:(NSString *)string;
+ (NSString *)DataToHex:(NSData *)data;                          // 将二进制转换为16进制再用字符串表示
+ (NSString *)cleanString:(NSString *)str;
+ (NSString *)stringByDate:(NSDate *)date;                       // 解决差8小时的问题
+ (NSString *)bankStyleData:(id)data;
+ (NSString *)bankStyleDataThree:(id)data;
+ (NSString *)fourNoFiveYes:(float)number afterPoint:(int)position;  // 四舍五入
+ (NSString *)decimalNumberMutiplyWithString:(NSString *)multiplierValue  valueB:(NSString *)multiplicandValue;
+ (NSString *)deviceModel;
+ (NSString *)easySeeTimesBySeconds:(NSInteger)seconds;
+ (NSString *)tenThousandNumber:(double)value;
+ (NSString *)tenThousandNumberString:(NSString *)value;
+ (NSString *)urlEncodedString:(NSString *)urlString;
+ (NSString *)urlDecodedString:(NSString *)urlString;
+ (NSString *)base64StringForText:(NSString *)text;     // 将字符串转换为base64编码
+ (NSString *)textFromBase64String:(NSString *)text;    // 将base64转换为字符串
+ (NSString *)base64Code:(NSData *)data;                // 用来将图片转换为字符串
+ (NSString *)sessionID:(NSURLResponse *)response;

+ (NSString *)ymdhsByTimeInterval:(NSTimeInterval)timeInterval;
+ (NSString *)ymdhsByTimeIntervalString:(NSString *)timeInterval;

+ (NSString *)countOverTime:(NSTimeInterval)time;   // 把秒转换为天时分
+ (NSString *)convertNumbers:(NSString *)string;    // SQLite3的表名不能是数字，所以可以用这方法转成拼音
+ (NSString *)pinyinForHans:(NSString *)chinese;        // 获取汉字的拼音
+ (NSString *)pinyinForHansClear:(NSString *)chinese;        // 获取汉字的拼音，没有空格
+ (NSString*)reverseWordsInString:(NSString*)str;       // 字符串反转
+ (NSString *)twoChar:(NSInteger)value;
+ (NSString *)scanQRCode:(UIImage *)image;  // 解析二维码
+ (NSString *)dataToHex:(NSData *)data;
+ (NSData *)convertHexStrToData:(NSString *)str;
+ (NSString *)stringWithDate:(NSDate *)date formatter:(NSString *)formatter;
+ (NSDate *)dateByString:(NSString *)str formatter:(NSString *)formatter;

/*  NSAttributedString *connectAttributedString = [FuData attributedStringFor:connectString colorRange:@[[NSValue valueWithRange:connectRange]] color:GZS_RedColor textRange:@[[NSValue valueWithRange:connectRange]] font:FONTFC(25)];*/
+ (NSAttributedString *)attributedStringFor:(NSString *)sourceString colorRange:(NSArray *)colorRanges color:(UIColor *)color textRange:(NSArray *)textRanges font:(UIFont *)font;
+ (NSAttributedString *)attributedStringFor:(NSString *)sourceString strings:(NSArray *)colorStrings color:(UIColor *)color fontStrings:(NSArray *)fontStrings font:(UIFont *)font;

+ (NSString *)firstCharacterWithString:(NSString *)string;
+ (NSString *)forthCarNumber:(NSString *)text;

//     strikeLabel.attributedText = attribtStr;
- (NSAttributedString *)middleLineForLabel:(NSString *)text;    // 中划线
- (NSAttributedString *)underLineForLabel:(NSString *)text;     // 下划线


/**
 *  计算上次日期距离现在多久
 *
 *  @param lastTime    上次日期(需要和格式对应)
 *  @param format1     上次日期格式
 *  @param currentTime 最近日期(需要和格式对应)
 *  @param format2     最近日期格式
 *
 *  @return xx分钟前、xx小时前、xx天前
 *  eg. NSLog(@"\n\nresult: %@", [Utilities timeIntervalFromLastTime:@"2015年12月8日 15:50"
 lastTimeFormat:@"yyyy年MM月dd日 HH:mm"
 ToCurrentTime:@"2015/12/08 16:12"
 currentTimeFormat:@"yyyy/MM/dd HH:mm"]);
 */
+ (NSString *)timeIntervalFromLastTime:(NSString *)lastTime
                        lastTimeFormat:(NSString *)format1
                         ToCurrentTime:(NSString *)currentTime
                     currentTimeFormat:(NSString *)format2;

// 高精度计算
+ (NSString *)highAdd:(NSString *)aValue add:(NSString *)bValue;
+ (NSString *)highSubtract:(NSString *)fontValue add:(NSString *)backValue;
+ (NSString *)highMultiply:(NSString *)aValue add:(NSString *)bValue;
+ (NSString *)highDivide:(NSString *)aValue add:(NSString *)bValue;

+ (void)call:(NSString *)phone;
+ (void)callPhoneWithNoNotice:(NSString *)phone;
+ (void)openAppByURLString:(NSString *)str;

// 操作闪光灯
+ (void)flashLampShow:(BOOL)show;

// 除了年不是当年数字，月日是当月日
+ (NSDateComponents *)chineseDate:(NSDate *)date;
// 获取农历日期，数组共三个元素，分别是农历的年月日
+ (NSArray<NSString *> *)chineseCalendarForDate:(NSDate *)date;
+ (NSArray *)arrayFromArray:(NSArray *)array withString:(NSString *)string;
+ (NSArray *)arrayByOneCharFromString:(NSString *)string;
+ (NSArray *)keyedUnarchiverWithArray:(NSString *)fileName;
+ (NSArray *)arrayReverseWithArray:(NSArray *)array;
+ (NSArray *)maxandMinNumberInArray:(NSArray *)array;                           // 找出数组中最大的数 First Max, Last Min
+ (NSArray *)maopaoArray:(NSArray *)array;
+ (NSArray *)addCookies:(NSArray *)nameArray value:(NSArray *)valueArray cookieDomain:(NSString *)cookName;
+ (NSArray *)deviceInfos;

+ (NSArray<NSString *> *)propertiesForClass:(Class)className;   // 获取类的所有属性
+ (SEL)setterSELWithAttibuteName:(NSString*)attributeName;      // 将字符串转化为Set方法，如将"name"转化为setName方法
+ (void)setValue:(id)value forPropertyName:(NSString *)name ofObject:(id)object;    // 给对象的属性赋值
+ (id)entity:(Class)instance dic:(NSDictionary *)dic;           
+ (id)valueForGetSelectorWithPropertyName:(NSString *)name object:(id)instance;  // 获取实例的属性的值

+ (NSDictionary *)keyedUnarchiverWithDictionary:(NSString *)fileName;

+ (NSData *)keyedUnarchiverWithData:(NSString *)fileName;
+ (NSData*)rsaEncryptString:(SecKeyRef)key data:(NSString*) data;
//压缩图片到指定文件大小
+ (NSData *)compressOriginalImage:(UIImage *)image toMaxDataSizeKBytes:(CGFloat)size;

+ (NSNumber *)keyedUnarchiverWithNumber:(NSString *)fileName;
+ (NSNumber *)fileSize:(NSString *)filePath;
+ (UIColor *)randomColor;
+ (UIColor *)colorWithHexString:(NSString *)color;               // 根据16进制字符串获得颜色类对象

// 主要用于汉字倾斜,系统UIFont没有直接支持汉字倾斜。可以使字体倾斜rate角度，rate在0-180之间，取15较好；fontSize是字体大小。
+ (UIFont *)angleFontWithRate:(CGFloat)rate fontSize:(NSInteger)fontSize;

// 解决差8小时问题
+ (NSDate *)chinaDateByDate:(NSDate *)date;
//
+ (NSDateComponents *)componentForDate:(NSDate *)date;
// 获取日期是当年的第几天
+ (NSInteger)daythOfYearForDate:(NSDate *)date;

// 绘制虚线
+ (UIView *)createDashedLineWithFrame:(CGRect)lineFrame
                           lineLength:(int)length
                          lineSpacing:(int)spacing
                            lineColor:(UIColor *)color;
+ (UIImage *)QRImageFromString:(NSString *)string;
+ (UIImage *)imageFromColor:(UIColor *)color;
+ (UIImage *)imageFromColor:(UIColor *)color size:(CGSize)size;
+ (UIImage*)circleImage:(UIImage*)image withParam:(CGFloat)inset;
+ (UIImage *)imageCompressForWidth:(UIImage *)sourceImage targetWidth:(CGFloat)defineWidth; // 将图片大小设置为目标大小，用于压缩图片
+ (UIImage *)compressImage:(UIImage *)sourceImage targetWidth:(CGFloat)targetWidth;
#pragma mark - 对图片进行滤镜处理
+ (UIImage *)filterWithOriginalImage:(UIImage *)image filterName:(NSString *)name;
#pragma mark -  对图片进行模糊处理
+ (UIImage *)blurWithOriginalImage:(UIImage *)image blurName:(NSString *)name radius:(NSInteger)radius;
// 调整图片饱和度、亮度、对比度
+ (UIImage *)colorControlsWithOriginalImage:(UIImage *)image
                                 saturation:(CGFloat)saturation
                                 brightness:(CGFloat)brightness
                                   contrast:(CGFloat)contrast;
// 创建一张实时模糊效果 View (毛玻璃效果)
+ (UIVisualEffectView *)effectViewWithFrame:(CGRect)frame;
// 全屏截图
+ (UIImage *)shotFullScreen;
//截取view中某个区域生成一张图片
+ (UIImage *)shotWithView:(UIView *)view scope:(CGRect)scope;
//截取view生成一张图片
+ (UIImage *)shotWithView:(UIView *)view;
+ (UIImage *)captureScrollView:(UIScrollView *)scrollView;

// 压缩图片
+ (UIImage *)compressImageData:(NSData *)imageData;
+ (UIImage *)compressImage:(UIImage *)imageData;
+ (UIImage *)compressImage:(UIImage *)image width:(NSInteger)minWidth minHeight:(NSInteger)minHeight;

+ (UIImage *)compressImage:(UIImage *)image width:(NSInteger)width;
+ (UIImage*)imageForUIView:(UIView *)view;

// 单位转换方法
+ (NSString *)KMGUnit:(NSInteger)size;

+ (NSURL *)convertTxtEncoding:(NSURL *)fileUrl;

// 将文件拷贝到tmp目录
+ (NSURL *)fileURLForBuggyWKWebView8:(NSURL *)fileURL;

+ (id)storyboardInstantiateViewControllerWithStoryboardID:(NSString *)storybbordID;

@end
