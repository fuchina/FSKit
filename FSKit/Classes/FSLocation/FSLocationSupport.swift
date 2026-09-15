//
//  FSLocationSupport.swift
//  FSCalculator
//
//  Created by fudongdong on 2019/1/9.
//  Translated to Swift
//

import Foundation
import MapKit
import UIKit

/**
 * 经过测试，美团、百度、高德都是使用的这种算法，因此具有实用价值
 * 但腾讯不是使用这种算法，所以到底是哪边有问题还待确认
 */

public class FSLocationSupport: NSObject {
    
    private static let earthRadius: Double = 6378245.0
    private static let ee: Double = 0.00669342162296594323
    
    private static let mapApple = "苹果地图"
    private static let mapGaode = "高德地图"
    private static let mapBaidu = "百度地图"
    
    // MARK: - Coordinate Conversion
    
    /// GPS坐标转火星坐标 (从CLLocation)
    @objc(marsCoordinateFromLocation:)
    public static func marsCoordinate(from location: CLLocation) -> CLLocationCoordinate2D {
        return marsCoordinate(from: location.coordinate)
    }
    
    /// 火星坐标转GPS坐标
    public static func gpsCoordinate(from marsCoordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        // 参考自 http://blog.csdn.net/coolypf/article/details/8686588
        // GPS等于国测坐标正向偏移反推
        let gdiff = self.marsCoordinate(from: marsCoordinate)
        return CLLocationCoordinate2D(
            latitude: marsCoordinate.latitude * 2 - gdiff.latitude,
            longitude: marsCoordinate.longitude * 2 - gdiff.longitude
        )
    }
    
    /// GPS坐标转火星坐标
    public static func marsCoordinate(from gpsCoordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        if outOfChina(latitude: gpsCoordinate.latitude, longitude: gpsCoordinate.longitude) {
            return gpsCoordinate
        }
        
        let longitude = gpsCoordinate.longitude
        let latitude = gpsCoordinate.latitude
        var dLat = transformLatitude(x: longitude - 105.0, y: latitude - 35.0)
        var dLon = transformLongitude(x: longitude - 105.0, y: latitude - 35.0)
        let radLat = latitude / 180.0 * .pi
        var magic = sin(radLat)
        magic = 1 - ee * magic * magic
        let sqrtMagic = sqrt(magic)
        dLat = (dLat * 180.0) / ((earthRadius * (1 - ee)) / (magic * sqrtMagic) * .pi)
        dLon = (dLon * 180.0) / (earthRadius / sqrtMagic * cos(radLat) * .pi)
        let marsLatitude = latitude + dLat
        let marsLongitude = longitude + dLon
        return CLLocationCoordinate2D(latitude: marsLatitude, longitude: marsLongitude)
    }
    
    /// 是否在中国版图外，大概判断，边境不准
    public static func outOfChina(latitude: Double, longitude: Double) -> Bool {
        if longitude < 72.004 || longitude > 137.8347 {
            return true
        }
        if latitude < 0.8293 || latitude > 55.8271 {
            return true
        }
        return false
    }
    
    // MARK: - Private Transform Methods
    
    private static func transformLatitude(x: Double, y: Double) -> Double {
        var ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0
        ret += (20.0 * sin(y * .pi) + 40.0 * sin(y / 3.0 * .pi)) * 2.0 / 3.0
        ret += (160.0 * sin(y / 12.0 * .pi) + 320 * sin(y * .pi / 30.0)) * 2.0 / 3.0
        return ret
    }
    
    private static func transformLongitude(x: Double, y: Double) -> Double {
        var ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0
        ret += (20.0 * sin(x * .pi) + 40.0 * sin(x / 3.0 * .pi)) * 2.0 / 3.0
        ret += (150.0 * sin(x / 12.0 * .pi) + 300.0 * sin(x / 30.0 * .pi)) * 2.0 / 3.0
        return ret
    }
    
    // MARK: - Navigation
    
    /// 导航,coordinate为目的地
    public static func navigationToMaps(
        destination coordinate: CLLocationCoordinate2D,
        controller: UIViewController
    ) {
        var mapOptions: [String] = []
        
        if UIApplication.shared.canOpenURL(URL(string: "baidumap://")!) {
            mapOptions.append(mapBaidu)
        }
        if UIApplication.shared.canOpenURL(URL(string: "iosamap://")!) {
            mapOptions.append(mapGaode)
        }
        mapOptions.append(mapApple)
        
        let alertController = UIAlertController(
            title: "选择导航方式",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        for option in mapOptions {
            let action = UIAlertAction(title: option, style: .default) { _ in
                handleMapSelection(option, coordinate: coordinate)
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        alertController.addAction(cancelAction)
        
        controller.present(alertController, animated: true)
    }
    
    private static func handleMapSelection(_ mapName: String, coordinate: CLLocationCoordinate2D) {
        switch mapName {
        case mapApple:
            openAppleMaps(coordinate: coordinate)
        case mapBaidu:
            openBaiduMaps(coordinate: coordinate)
        case mapGaode:
            openGaodeMaps(coordinate: coordinate)
        default:
            break
        }
    }
    
    private static func openAppleMaps(coordinate: CLLocationCoordinate2D) {
        let currentLocation = MKMapItem.forCurrentLocation()
        let toLocation: MKMapItem
        if #available(iOS 26.0, *) {
            toLocation = MKMapItem(
                location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude),
                address: nil
            )
        } else {
            toLocation = legacyMapItem(coordinate: coordinate)
        }
        MKMapItem.openMaps(
            with: [currentLocation, toLocation],
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
                MKLaunchOptionsShowsTrafficKey: true
            ]
        )
    }
    
    /// iOS 26 以下：用 MKPlacemark 构造目的地
    ///
    /// - Note: `MKMapItem(placemark:)` 与 `MKPlacemark` 在 iOS 26 已被废弃，仅在 `#available` 的
    ///         旧系统分支调用；标注为同版本废弃以把编译期废弃告警收敛在此处，不再发散到调用方。
    @available(iOS, deprecated: 26.0, message: "内部兼容旧系统，iOS 26 起走 MKMapItem(location:address:)")
    private static func legacyMapItem(coordinate: CLLocationCoordinate2D) -> MKMapItem {
        return MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
    }
    
    private static func openBaiduMaps(coordinate: CLLocationCoordinate2D) {
        let urlString = "baidumap://map/direction?origin={{我的位置}}&destination=latlng:\(coordinate.latitude),\(coordinate.longitude)|name=目的地&mode=driving&coord_type=gcj02"
        guard let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedString) else { return }
        UIApplication.shared.open(url)
    }
    
    private static func openGaodeMaps(coordinate: CLLocationCoordinate2D) {
        let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? ""
        let urlScheme = "urlScheme"
        let urlString = "iosamap://navi?sourceApplication=\(appName)&backScheme=\(urlScheme)&lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&dev=0&style=1"
        guard let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedString) else { return }
        UIApplication.shared.open(url)
    }
}
