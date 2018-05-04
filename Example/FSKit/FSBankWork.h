//
//  FSBankWork.h
//  FSKit_Example
//
//  Created by Fudongdong on 2018/3/8.
//  Copyright © 2018年 fudongdong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FSBankWork : NSObject

/*
 减债方式降低负债率
 asset：当前总资产  cDAR:当前资产负债率 tDAR:目标资产负债率
 要达到目标资产负债率，应该还掉多少债
 */
+ (CGFloat)payDebtToLowerLeverageAsset:(CGFloat)asset currentDAR:(CGFloat)cDAR targetDAR:(CGFloat)tDAR;

/*
 增资方式降低负债率
 asset：当前总资产  cDAR:当前资产负债率 tDAR:目标资产负债率
 负债不变，要达到目标资产负债率，应该增加多少资产
 */
+ (CGFloat)addAssetToLowerLeverageAsset:(CGFloat)asset currentDAR:(CGFloat)cDAR targetDAR:(CGFloat)tDAR;

/*
 增资还债方式降低负债率
 asset：当前总资产  cDAR:当前资产负债率 tDAR:目标资产负债率
 要达到目标资产负债率，需要增加多少钱来还债
 */
+ (CGFloat)addAssetPayDebtToLowerLeverageAsset:(CGFloat)asset currentDAR:(CGFloat)cDAR targetDAR:(CGFloat)tDAR;

@end
