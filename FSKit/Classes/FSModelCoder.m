////
////  FSModelCoder.m
////  ModuleOxfordUtils
////
////  Created by 扶冬冬 on 2024/3/27.
////
//
//#import "FSModelCoder.h"
//
//@implementation FSModelCoder
//
//+ (BOOL)supportsSecureCoding {
//    return YES;
//}
//
//- (instancetype)initWithCoder:(NSCoder *)coder {
//    self = [self init];
//    if (self) {
//        self.dictionary = [coder decodeObjectForKey: @"dictionary"];
//        self.list = [coder decodeObjectForKey: @"list"];
//        self.boolean = [coder decodeIntegerForKey: @"boolean"];
//        self.string = [coder decodeObjectForKey: @"string"];
//    }
//    return self;
//}
//
//- (void)encodeWithCoder:(NSCoder *)coder {
//    [coder encodeObject: self.dictionary forKey: @"dictionary"];
//    [coder encodeObject: self.list forKey: @"list"];
//    [coder encodeInteger: self.boolean forKey: @"boolean"];
//    [coder encodeObject: self.string forKey: @"string"];
//}
//
//+ (NSError *)saveBoolean:(FSTriBool)boolean forKey:(NSString *)key {
//    return [self save: nil list: nil boolean: boolean string: nil forKey: key];
//}
//
//+ (NSError *)saveString:(NSString *)string forKey:(NSString *)key {
//    return [self save: nil list: nil boolean: FSTriBoolUnknown string: string forKey: key];
//}
//
//+ (NSError *)saveList:(NSArray *)list forKey:(NSString *)key {
//    return [self save: nil list: list boolean: FSTriBoolUnknown string: nil forKey: key];
//}
//
//+ (NSError *)saveDictionary:(NSDictionary *)dictionary forKey:(NSString *)key {
//    return [self save: dictionary list: nil boolean: FSTriBoolUnknown string: nil forKey: key];
//}
//
//+ (NSError *)save:(NSDictionary * _Nullable)dictionary list:(NSArray * _Nullable)list boolean:(FSTriBool)boolean string:(NSString * _Nullable)string forKey:(NSString *)key {
//    FSModelCoder *coder = [[FSModelCoder alloc] init];
//    coder.dictionary = dictionary;
//    coder.list = list;
//    coder.boolean = boolean;
//    coder.string = string;
//    
//    NSError *error = nil;
//    NSMutableData *data = nil;
//    if (@available(iOS 11.0, *)) {
//        data = (NSMutableData *)[NSKeyedArchiver archivedDataWithRootObject: coder requiringSecureCoding: YES error: &error];
//        NSAssert([data isKindOfClass:NSData.class], @"FSModelCoder：data创建失败: %@", error);
//        if (error) {
//            return error;
//        }
//    }
//    
//    NSString *path = [self filePath: key];
//    __unused BOOL succeed = [data writeToFile: path options: NSDataWritingAtomic error: &error];
//    NSAssert(succeed == YES, @"FSModelCoder：信息存入本地失败");
//    return error;
//}
//
//+ (FSModelCoder *)fetch:(NSString *)key {
//    NSString *filePath = [self filePath: key];
//    
//    NSFileManager *fm = NSFileManager.defaultManager;
//    BOOL fileExists = [fm fileExistsAtPath: filePath];
//    FSModelCoder *coder = nil;
//    if (fileExists) {
//        @try {
//            NSMutableData *data = [[NSMutableData alloc] initWithContentsOfFile: filePath];
//            if (@available(iOS 11.0, *)) {
//                NSError *error = nil;
//                NSSet *sets = [NSSet setWithObjects: FSModelCoder.class, NSDictionary.class, NSArray.class, NSNumber.class, NSString.class, nil];  // 有哪些类类型，就传入
//                coder = [NSKeyedUnarchiver unarchivedObjectOfClasses: sets fromData: data error: &error];
//                NSAssert(error == nil && coder, @"FSModelCoder：本地获取信息失败，可以通过查看error中的描述信息找出问题原因");
//            }
//        }
//        
//        @catch (NSException *exception) {
//
//        } @finally {
//            if (coder == nil) {
//                [fm removeItemAtPath: filePath error: nil];
//            }
//        }
//    }
//    
//    return coder;
//}
//
//+ (BOOL)remove:(NSString *)key error:(NSError *)error {
//    NSString *filePath = [self filePath: key];
//    NSFileManager *fm = NSFileManager.defaultManager;
//    BOOL fileExists = [fm fileExistsAtPath: filePath];
//    if (fileExists) {
//        return [fm removeItemAtPath: filePath error: &error];
//    }
//    return YES;
//}
//
//+ (NSString *)filePath:(NSString *)key {
//    BOOL checkKey = [key isKindOfClass: NSString.class] && key.length;
//    if (checkKey == NO) {
//        return nil;
//    }
//    
//    NSString *libraryDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
//    NSString *dir = [libraryDirectory stringByAppendingPathComponent: @"FSModelCoder"];
//    NSFileManager *fm = NSFileManager.defaultManager;
//    BOOL isDir = YES;
//    BOOL isDirectoryExist = [fm fileExistsAtPath: dir isDirectory: &isDir];
//    if (isDirectoryExist && isDir) {} else {
//        NSError *error = nil;
//        __unused BOOL su = [fm createDirectoryAtPath: dir withIntermediateDirectories: YES attributes: @{} error: &error];
//        NSAssert(su == YES && error == nil, @"FSModelCoder: createDirectoryAtPath fail - error %@", error);
//    }
//    
//    NSString *filePath = [dir stringByAppendingPathComponent: key];
//    return filePath;
//}
//
//@end
