//
//  FSLocationManager.swift
//  FSBaseController
//
//  Created by FudonFuchina on 2019/4/27.
//  Translated to Swift
//

import Foundation
import CoreLocation

/*
 1.需要在工程plist文件中增加
 NSLocationAlwaysUsageDescription
 NSLocationWhenInUseUsageDescription
 NSLocationAlwaysAndWhenInUseUsageDescription
 字段
 
 2.TARGETS - Capabilities - Background Modes - Location updates 勾上
 */

public class FSLocationManager: NSObject {
    
    public var serialManager: CLLocationManager
    
    public var locationManagerDidChangeAuthorization: ((FSLocationManager) -> Void)?
    
    /// 回调结果
    public var callback: ((FSLocationManager, FSLocationResult) -> Void)?
    
    private var lastLocations: [CLLocation]?
    private let queue: DispatchQueue
    private var isSerialLocating: Bool = false
    
    public override init() {
        queue = DispatchQueue(label: "FSLocationManager.queue.sync")
        serialManager = FSLocation.makeLocationManager(distanceFilter: kCLDistanceFilterNone)
        super.init()
        serialManager.delegate = self
        serialManager.requestWhenInUseAuthorization()
    }
    
    /// 连续定位
    /// - Parameters:
    ///   - accuracy: 定位精度，默认kCLLocationAccuracyBest
    ///   - distanceFilter: 定位更新的距离，默认kCLDistanceFilterNone，即只要运动就会回调位置更新
    public func serialLocation(accuracy: FSLocationAccuracy, distanceFilter: CLLocationAccuracy) {
        let status = serialManager.authorizationStatus
        let isAuthorization = status == .authorizedAlways || status == .authorizedWhenInUse
        guard isAuthorization else { return }
        
        queue.async { [weak self] in
            guard let self else { return }
            
            let systemAccuracy = FSLocation.locationAccuracy(for: accuracy)
            self.serialManager.desiredAccuracy = systemAccuracy
            self.serialManager.distanceFilter = distanceFilter
            
            if self.isSerialLocating {
                self.successCallback(locations: self.lastLocations)
                return
            }
            
            self.isSerialLocating = true
            self.serialManager.startUpdatingLocation()
        }
    }
    
    /// 停止连续定位
    public func stopLocation() {
        queue.sync { [weak self] in
            guard let self else { return }
            self.serialManager.stopUpdatingLocation()
            self.isSerialLocating = false
        }
    }
    
    /// 最后定位的有效值，每次定位成功后会更新，在主线程返回
    public func fetchTheLastestLocations() -> [CLLocation]? {
        var values: [CLLocation]?
        queue.sync { [weak self] in
            values = self?.lastLocations
        }
        return values
    }
    
    private func successCallback(locations: [CLLocation]?) {
        queue.async { [weak self] in
            guard let self else { return }
            self.lastLocations = locations
            let result = FSLocationResult.result(
                locations: locations,
                lastLocation: locations?.last,
                sourceType: .serial,
                error: nil
            )
            DispatchQueue.main.async {
                self.callback?(self, result)
            }
        }
    }
    
    /// 根据location获取地址
    public static func address(
        with location: CLLocation,
        completionHandler: @escaping ([CLPlacemark]?, Error?) -> Void
    ) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            completionHandler(placemarks, error)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension FSLocationManager: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        successCallback(locations: locations)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        queue.async { [weak self] in
            guard let self else { return }
            
            let result = FSLocationResult.result(
                locations: nil,
                lastLocation: nil,
                sourceType: .serial,
                error: error
            )
            
            // 如果是权限问题，则停止定位
            let nsError = error as NSError
            if nsError.code == CLError.denied.rawValue ||
               nsError.code == CLError.regionMonitoringDenied.rawValue {
                self.stopLocation()
            }
            
            DispatchQueue.main.async {
                self.callback?(self, result)
            }
        }
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationManagerDidChangeAuthorization?(self)
    }
}
