//
//  FSLocalNotificationCore.swift
//  FSKit
//
//  Translated from Objective-C to Swift
//

import UIKit
import UserNotifications

public class FSLocalNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    
    public static let shared = FSLocalNotificationManager()
    
    private override init() {
        super.init()
        preparatoryWork()
    }
    
    private func preparatoryWork() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    // MARK: - Get All Notifications
    public func allNotifications(completion: @escaping ([Any]) -> Void) {
        var list: [Any] = []
        let center = UNUserNotificationCenter.current()
        
        center.getDeliveredNotifications { notifications in
            list.append(contentsOf: notifications)
            
            center.getPendingNotificationRequests { requests in
                list.append(contentsOf: requests)
                
                DispatchQueue.main.async {
                    completion(list)
                }
            }
        }
    }
    
    // MARK: - Add Local Notification
    public func addLocalNotification(
        identifier: String,
        title: String?,
        subTitle: String?,
        body: String?,
        userInfo: [String: Any]?,
        date: Date,
        calendarUnit: Set<Calendar.Component>,
        repeats: Bool,
        success: ((Date?) -> Void)?,
        fail: ((Error?) -> Void)?
    ) {
        guard !identifier.isEmpty else {
            assertionFailure("LocalNotification's identifier has no length")
            return
        }
        
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        
        if let title = title, !title.isEmpty {
            content.title = title
        }
        if let subTitle = subTitle, !subTitle.isEmpty {
            content.subtitle = subTitle
        }
        if let body = body, !body.isEmpty {
            content.body = body
        }
        if let userInfo = userInfo, !userInfo.isEmpty {
            content.userInfo = userInfo
        }
        
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        guard let trigger = FSLocalNotificationManager.calendarNotificationTrigger(with: date, unit: calendarUnit, repeats: repeats) else {
            fail?(nil)
            return
        }
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    fail?(error)
                } else {
                    success?(trigger.nextTriggerDate())
                }
            }
        }
    }
    
    // MARK: - Remove Notification
    public func removeNotification(identifiers: [String], delivered: Bool, pending: Bool) {
        guard delivered || pending else { return }
        guard !identifiers.isEmpty else { return }
        
        let center = UNUserNotificationCenter.current()
        
        if delivered {
            center.removeDeliveredNotifications(withIdentifiers: identifiers)
        }
        if pending {
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
    
    // MARK: - Calendar Notification Trigger
    public static func calendarNotificationTrigger(with date: Date, unit: Set<Calendar.Component>, repeats: Bool) -> UNCalendarNotificationTrigger? {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(unit, from: date)
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
    }
    
    // MARK: - Cancel All
    public static func cancelAllLocalNotification() {
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        UIApplication.shared.applicationIconBadgeNumber += 1
        
        if #available(iOS 14.0, *) {
            completionHandler([.badge, .sound, .list, .banner])
        } else {
            completionHandler([.badge, .sound, .alert])
        }
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
