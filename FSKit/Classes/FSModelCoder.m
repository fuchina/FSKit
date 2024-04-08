//
//  FSModelCoder.m
//  ModuleOxfordUtils
//
//  Created by 扶冬冬 on 2024/3/27.
//

#import "FSModelCoder.h"

@implementation FSModelCoder

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [self init];
    if (self) {
        self.meta = [coder decodeObjectForKey: @"meta"];
        self.list = [coder decodeObjectForKey: @"list"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject: self.meta forKey: @"meta"];
    [coder encodeObject: self.list forKey: @"list"];
}

+ (NSError *)save:(NSDictionary * _Nullable)meta list:(NSArray * _Nullable)list filePath:(NSString *)filePath forKey:( NSString * _Nullable)key {
    HEModelCoder *coder = [[FSModelCoder alloc] init];
    coder.meta = meta;
    coder.list = list;
    
    NSError *error = nil;
    NSMutableData *data = nil;
    if (@available(iOS 12.0, *)) {
        data = (NSMutableData *)[NSKeyedArchiver archivedDataWithRootObject: coder requiringSecureCoding: YES error: &error];
        NSAssert([data isKindOfClass:NSData.class], @"HEModelCoder：用户信息data创建失败: %@", error);
        if (error) {
            return error;
        }
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        data = [[NSMutableData alloc] init];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
        [archiver encodeObject: coder forKey: key];
        [archiver finishEncoding];
#pragma clang diagnostic pop
    }
    
    __unused BOOL succeed = [data writeToFile: filePath options: NSDataWritingAtomic error: &error];
    NSAssert(succeed == YES, @"HEModelCoder：用户登录信息存入本地失败");
    return error;
}

+ (FSModelCoder *)fetch:(NSString *)filePath key:(NSString *)key {
    NSFileManager *fm = NSFileManager.defaultManager;
    BOOL fileExists = [fm fileExistsAtPath: filePath];
    FSModelCoder *coder = nil;
    if (fileExists) {
        @try {
            NSMutableData *data = [[NSMutableData alloc] initWithContentsOfFile: filePath];
            if (@available(iOS 12.0, *)) {
                NSError *error = nil;
                NSSet *sets = [NSSet setWithObjects: FSModelCoder.class, NSDictionary.class, NSArray.class, NSNumber.class, NSString.class, nil];  // 有哪些类类型，就传入
                coder = [NSKeyedUnarchiver unarchivedObjectOfClasses: sets fromData: data error: &error];
                NSAssert(error == nil && coder, @"HEModelCoder：本地获取登录信息失败，可以通过查看error中的描述信息找出问题原因");
            } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData: data];
                coder = [unarchiver decodeObjectForKey: key];
                [unarchiver finishDecoding];
#pragma clang diagnostic pop
            }
        }
        
        @catch (NSException *exception) {

        } @finally {
            if (coder == nil) {
                [fm removeItemAtPath: filePath error: nil];
            }
        }
    }
    
    return coder;
}

@end
