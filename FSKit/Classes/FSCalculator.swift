//
//  FSCalculator.swift
//  FSCalculator
//
//  Created by Fudongdong on 2018/4/3.
//  Translated to Swift
//

import UIKit
import CoreLocation

open class FSCalculator: NSObject {
    
    // MARK: - 等额本金计算
    /// 等额本金计算公式
    /// - Parameters:
    ///   - rate: 年利率，如4.9%，输入4.9
    ///   - month: 期数，也就是月数，如10年，输入120
    /// - Returns: 总还款除以贷款的倍数
    public static func debj(withYearRate rate: Double, monthes month: Int) -> Double {
        guard rate >= 0.01 else { return 1 }
        
        let money: Double = 1.0
        let r = rate / 1200.0
        
        var allInterest: CGFloat = 0
        let payMonth = money / Double(month)
        
        for x in 0..<month {
            let mI = (money - Double(x) * payMonth) * r
            allInterest += mI
        }
        
        return (money + allInterest) / money
    }
    
    // MARK: - 等额本息计算
    /// 等额本息计算公式
    /// - Parameters:
    ///   - rate: 年利率，如4.9%，输入4.9
    ///   - month: 期数，也就是月数，如10年，输入120
    /// - Returns: 总还款除以贷款的倍数
    public static func debx(withYearRate rate: CGFloat, monthes month: Int) -> CGFloat {
        guard rate >= 0.01 else { return 1 }
        
        let money: CGFloat = 1.0
        let r = rate / 1200.0
        
        let monthPay = (money * r * pow(1 + r, Double(month))) / (pow(1 + r, Double(month)) - 1)
        return monthPay * Double(month) / money
    }
    
    // MARK: - 价格涨幅计算
    /// 计算价格涨幅
    /// - Parameters:
    ///   - days: 周转天数，单位：天，即多少天后会卖出
    ///   - rate: 目标年化收益率，比如20%输入0.2
    /// - Returns: 价格倍数，比如输入90，0.3820,返回1.094129，即90天卖出应该定价为所投入资本的1.094129倍
    public static func priceRise(withDays days: Double, yearRate rate: Double) -> Double {
        let actualDays = max(days, 1)
        let actualRate = max(0, rate)
        let year: CGFloat = 365.2422
        let everyEarn = actualRate / year
        let allEarn = actualDays * everyEarn
        return allEarn + 1
    }
    
    // MARK: - 图片采样大小计算
    public static func computeSampleSize(_ image: UIImage, minSideLength: Int, maxNumOfPixels: Int) -> Int {
        let initialSize = computeInitialSampleSize(image, minSideLength: minSideLength, maxNumOfPixels: maxNumOfPixels)
        var roundedSize = 0
        
        if initialSize <= 8 {
            roundedSize = 1
            while roundedSize < initialSize {
                roundedSize <<= 1
            }
        } else {
            roundedSize = (initialSize + 7) / 8 * 8
        }
        
        return roundedSize
    }
    
    private static func computeInitialSampleSize(_ image: UIImage, minSideLength: Int, maxNumOfPixels: Int) -> Int {
        let w = Double(image.size.width)
        let h = Double(image.size.height)
        
        let lowerBound = (maxNumOfPixels == -1) ? 1 : Int(ceil(sqrt(w * h / Double(maxNumOfPixels))))
        let upperBound = (minSideLength == -1) ? 128 : Int(min(floor(w / Double(minSideLength)), floor(h / Double(minSideLength))))
        
        if upperBound < lowerBound {
            return lowerBound
        }
        if maxNumOfPixels == -1 && minSideLength == -1 {
            return 1
        } else if minSideLength == -1 {
            return lowerBound
        } else {
            return upperBound
        }
    }
    
    // MARK: - 文本尺寸计算
    /// 计算文本宽度
    public static func textWidth(_ text: String?, font: UIFont?, labelHeight: CGFloat) -> CGFloat {
        guard let font = font, let text = text, !text.isEmpty else { return 0 }
        
        let size = text.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: labelHeight),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).size
        
        return ceil(size.width + 2)
    }
    
    /// 计算字符串放在label上需要的高度，font数字要和label的一样
    public static func textHeight(_ text: String?, font: UIFont?, labelWidth: CGFloat) -> CGFloat {
        guard let font = font, let text = text, !text.isEmpty else { return 0 }
        
        let attrStr = NSMutableAttributedString(string: text)
        let allRange = NSRange(location: 0, length: text.count)
        attrStr.addAttribute(.font, value: font, range: allRange)
        
        let rect = attrStr.boundingRect(
            with: CGSize(width: labelWidth, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        
        return ceil(rect.size.height + 2)
    }
    
    // MARK: - 距离计算
    /// 计算两个坐标之间的距离（单位：公里）
    public static func distance(between coordinateA: CLLocationCoordinate2D, toCoordinateB coordinateB: CLLocationCoordinate2D) -> Double {
        let earthRadius: Double = 6378.137 // 地球半径
        
        let lat1 = coordinateA.latitude
        let lng1 = coordinateA.longitude
        let lat2 = coordinateB.latitude
        let lng2 = coordinateB.longitude
        
        let radLat1 = rad(lat1)
        let radLat2 = rad(lat2)
        let a = radLat1 - radLat2
        let b = rad(lng1) - rad(lng2)
        
        var s = 2 * sin(sqrt(pow(sin(a / 2), 2) + cos(radLat1) * cos(radLat2) * pow(sin(b / 2), 2)))
        s = s * earthRadius
        s = round(s * 10000) / 10000
        
        return s
    }
    
    private static func rad(_ d: Double) -> Double {
        return d * Double.pi / 180.0
    }
    
    // MARK: - 个税计算
    /// 五险一金后工资应缴税额
    public static func taxForSalaryAfterSocialSecurity(_ money: CGFloat) -> CGFloat {
        let deltaMoney = money - 3500
        guard deltaMoney > 0 else { return 0 }
        
        let rateArray = taxRate(forMoney: deltaMoney)
        let taxRate = rateArray[0]
        let quickNumber = rateArray[1]
        
        return deltaMoney * taxRate - quickNumber
    }
    
    /// 根据税后推算税前
    public static func taxRates(withMoneyAfterTax money: CGFloat) -> [[CGFloat]]? {
        let rateArray: [[CGFloat]] = [
            [0.03, 0, 0, 1500],
            [0.1, 105, 1500, 4500],
            [0.2, 555, 4500, 9000],
            [0.25, 1005, 9000, 35000],
            [0.3, 2755, 35000, 55000],
            [0.35, 5505, 55000, 80000],
            [0.45, 13505, 8000000]
        ]
        
        var selectArrays: [[CGFloat]] = []
        
        for x in 0..<rateArray.count {
            let subRateArray = rateArray[x]
            let marginMin = subRateArray[2]
            let quickNumber = subRateArray[1]
            let taxRate = subRateArray[0]
            let salary = (money - quickNumber - 3500 * taxRate) / (1 - taxRate)
            
            if x == rateArray.count - 1 {
                if (salary - 3500) > marginMin {
                    selectArrays.append(subRateArray)
                }
            } else {
                let marginMax = subRateArray[3]
                if (salary - 3500) > marginMin && (salary - 3500) <= marginMax {
                    selectArrays.append(subRateArray)
                }
            }
        }
        
        return selectArrays.isEmpty ? nil : selectArrays
    }
    
    /// 返回税率（index[0]）和速算扣除数(index[1])
    public static func taxRate(forMoney money: CGFloat) -> [CGFloat] {
        if money <= 1500 {
            return [0.03, 0]
        } else if money <= 4500 {
            return [0.1, 105]
        } else if money <= 9000 {
            return [0.2, 555]
        } else if money <= 35000 {
            return [0.25, 1005]
        } else if money <= 55000 {
            return [0.3, 2755]
        } else if money <= 80000 {
            return [0.35, 5505]
        } else {
            return [0.45, 13505]
        }
    }
}
