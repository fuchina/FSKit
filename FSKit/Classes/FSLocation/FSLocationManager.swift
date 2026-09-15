//
//  FSLocationManager.swift
//  FSBaseController
//
//  Created by FudonFuchina on 2019/4/27.
//  Translated to Swift
//

import Foundation
import CoreLocation
import MapKit

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
    ///
    /// - Note: iOS 26 起 `CLGeocoder` 已被废弃，内部改用 MapKit 的 `MKReverseGeocodingRequest`；
    ///         对外返回类型保持不变，调用方无需改动。
    public static func address(
        with location: CLLocation,
        completionHandler: @escaping ([CLPlacemark]?, Error?) -> Void
    ) {
        if #available(iOS 26.0, *) {
            reverseGeocodingMapItems(with: location) { mapItems, error in
                completionHandler(mapItemPlacemarks(from: mapItems), error)
            }
        } else {
            legacyAddress(with: location, completionHandler: completionHandler)
        }
    }
    
    // MARK: - Reverse Geocoding
    
    /// iOS 26+：MapKit 原生逆地理编码，回调在主线程
    @available(iOS 26.0, *)
    private static func reverseGeocodingMapItems(
        with location: CLLocation,
        completionHandler: @escaping ([MKMapItem]?, Error?) -> Void
    ) {
        Task { @MainActor in
            guard let request = MKReverseGeocodingRequest(location: location) else {
                completionHandler(nil, NSError(
                    domain: "FSLocationManager",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "逆地理编码请求创建失败"]
                ))
                return
            }
            
            do {
                completionHandler(try await request.mapItems, nil)
            } catch {
                completionHandler(nil, error)
            }
        }
    }
    
    /// iOS 26 以下：CLGeocoder
    ///
    /// - Note: 该方法内部使用了已废弃的 `CLGeocoder`，仅在 `#available` 的旧系统分支调用；
    ///         标注为同版本废弃以把编译期废弃告警收敛在此处，不再发散到调用方。
    @available(iOS, deprecated: 26.0, message: "内部兼容旧系统，iOS 26 起走 MKReverseGeocodingRequest")
    private static func legacyAddress(
        with location: CLLocation,
        completionHandler: @escaping ([CLPlacemark]?, Error?) -> Void
    ) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            completionHandler(placemarks, error)
        }
    }
    
    /// MKMapItem -> CLPlacemark
    ///
    /// - Note: iOS 26 起 `MKMapItem.placemark` 与 `MKPlacemark` 类被标记废弃，而 `CLPlacemark`
    ///         及其结构化字段（name/locality/subLocality/thoroughfare 等）尚未废弃。为在保持
    ///         对外接口不变的前提下消除编译期废弃告警，这里采用运行时取值；若将来 `placemark`
    ///         被移除，`responds(to:)` 会兜住并返回 nil。
    private static func mapItemPlacemarks(from mapItems: [MKMapItem]?) -> [CLPlacemark]? {
        guard let mapItems, !mapItems.isEmpty else { return nil }
        
        let selector = NSSelectorFromString("placemark")
        let placemarks = mapItems.compactMap { item -> CLPlacemark? in
            guard item.responds(to: selector) else { return nil }
            return item.value(forKey: "placemark") as? CLPlacemark
        }
        return placemarks.isEmpty ? nil : placemarks
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
