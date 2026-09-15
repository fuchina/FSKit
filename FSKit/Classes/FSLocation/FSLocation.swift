//
//  FSLocation.swift
//  FSBaseController
//
//  Created by FudonFuchina on 2016/12/15.
//  Translated to Swift
//

import MapKit
import CoreLocation

// MARK: - Enums

public enum FSLocationAccuracy: Int {
    case `default` = 0
    case bestForNavigation = 10
    case best
    case nearestTenMeters
    case hundredMeters
    case kilometer
    case threeKilometers
}

public enum FSLocationSourceType: Int {
    case unknown = 0
    case serial = 1     // 连续定位结果
    case single = 2     // 单点定位结果
}

public class FSLocation: NSObject {
    
    public static func makeLocationManager(distanceFilter: CLLocationDistance) -> CLLocationManager {
        let manager = CLLocationManager()
        manager.allowsBackgroundLocationUpdates = true
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = distanceFilter
        return manager
    }
    
    public static func locationAccuracy(for accuracy: FSLocationAccuracy) -> CLLocationAccuracy {
        switch accuracy {
        case .default, .best:
            return kCLLocationAccuracyBest
        case .bestForNavigation:
            return kCLLocationAccuracyBestForNavigation
        case .nearestTenMeters:
            return kCLLocationAccuracyNearestTenMeters
        case .hundredMeters:
            return kCLLocationAccuracyHundredMeters
        case .kilometer:
            return kCLLocationAccuracyKilometer
        case .threeKilometers:
            return kCLLocationAccuracyThreeKilometers
        }
    }
    
    /// 转换为中国习惯的地址顺序
    public static func chineseAddress(with placemark: CLPlacemark) -> String {
        return "\(placemark.subLocality ?? "")\(placemark.name ?? "")"
    }
    
    /// 两个CLLocation之间的距离
    public static func distance(from location: CLLocation, to another: CLLocation) -> CGFloat {
        return CGFloat(location.distance(from: another))
    }
    
    /// 两个GPS坐标点间的距离（米）
    public static func distance(between coordinateA: CLLocationCoordinate2D, and coordinateB: CLLocationCoordinate2D) -> CGFloat {
        guard CLLocationCoordinate2DIsValid(coordinateA),
              CLLocationCoordinate2DIsValid(coordinateB) else {
            return 0
        }
        let pa = MKMapPoint(coordinateA)
        let pb = MKMapPoint(coordinateB)
        return CGFloat(pa.distance(to: pb))
    }
}

public class FSLocationResult: NSObject {
    
    public var locations: [CLLocation]?
    public var lastLocation: CLLocation?
    public var error: Error?
    public var sourceType: FSLocationSourceType = .unknown
    
    public static func result(
        locations: [CLLocation]?,
        lastLocation: CLLocation?,
        sourceType: FSLocationSourceType,
        error: Error?
    ) -> FSLocationResult {
        let result = FSLocationResult()
        result.locations = locations
        result.lastLocation = lastLocation
        result.sourceType = sourceType
        result.error = error
        return result
    }
}
