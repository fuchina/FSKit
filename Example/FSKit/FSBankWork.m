//
//  FSBankWork.m
//  FSKit_Example
//
//  Created by Guazi on 2018/3/8.
//  Copyright © 2018年 topchuan. All rights reserved.
//

#import "FSBankWork.h"

@implementation FSBankWork

/*
 减债方式降低负债率
 asset：当前总资产  cDAR:当前资产负债率 tDAR:目标资产负债率
 要达到目标资产负债率，应该还掉多少债
 */
+ (CGFloat)payDebtToLowerLeverageAsset:(CGFloat)asset currentDAR:(CGFloat)cDAR targetDAR:(CGFloat)tDAR{
    if (tDAR == 1) {
        return NSNotFound;
    }
    CGFloat debt = asset * cDAR;
    CGFloat delta = (tDAR *asset - debt) / (1 - tDAR);
#if DEBUG
    NSLog(@"asset:%f,debt:%f",asset + delta,debt + delta);
#endif
    return delta;
}

/*
 增资方式降低负债率
 asset：当前总资产  cDAR:当前资产负债率 tDAR:目标资产负债率
 负债不变，要达到目标资产负债率，应该增加多少资产
 */
+ (CGFloat)addAssetToLowerLeverageAsset:(CGFloat)asset currentDAR:(CGFloat)cDAR targetDAR:(CGFloat)tDAR{
    if (tDAR == 1) {
        return NSNotFound;
    }
    CGFloat debt = asset * cDAR;
    CGFloat delta = debt / tDAR - asset;
#if DEBUG
    NSLog(@"asset:%f,debt:%f",asset + delta,debt);
#endif
    return delta;
}

/*
 增资还债方式降低负债率
 asset：当前总资产  cDAR:当前资产负债率 tDAR:目标资产负债率
 要达到目标资产负债率，需要增加多少钱来还债
 */
+ (CGFloat)addAssetPayDebtToLowerLeverageAsset:(CGFloat)asset currentDAR:(CGFloat)cDAR targetDAR:(CGFloat)tDAR{
    if (tDAR == 1) {
        return NSNotFound;
    }
    CGFloat debt = asset * cDAR;
    CGFloat delta = debt - tDAR * asset;
#if DEBUG
    NSLog(@"asset:%f,debt:%f",asset,debt - delta);
#endif
    return delta;
}

@end
