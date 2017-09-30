//
//  FSAPP.m
//  FSKit
//
//  Created by Guazi on 2017/9/30.
//  Copyright © 2017年 topchuan. All rights reserved.
//

#import "FSAPP.h"

@implementation FSAPP

static NSString *_FSAPP_UserDefault_INCOMES = @"_FSAPP_UserDefault_INCOMES";
static NSString *_FSAPP_UserDefault_COSTS   = @"_FSAPP_UserDefault_COSTS";
+ (void)saveIncomesAndCosts:(NSDictionary *)value{
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSArray *keys = [value allKeys];
        if ([keys containsObject:_FSAPP_UserDefault_INCOMES] &&
            [keys containsObject:_FSAPP_UserDefault_COSTS]) {
            
        }
    }
}

+ (NSString *)keyForYearMonth:(NSString *)yearMonth{
    if ([yearMonth isKindOfClass:[NSString class]] && yearMonth.length == 6) {
        
    }
    return nil;
}

@end
