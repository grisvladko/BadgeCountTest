//
//  NotificationService.swift
//  BadgeExtension
//
//  Created by vladislav grisko on 17/10/2021.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    let observed = MyObjectToObserve()
    var observer : MyObserver?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        self.bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let bestAttemptContent = self.bestAttemptContent else { return }
        // Modify the notification content here...
        
        bestAttemptContent.title = "\(bestAttemptContent.title) [Modified]"
        // Save notification data to UserDefaults
        let data = bestAttemptContent.userInfo as NSDictionary
        let pref = UserDefaults.init(suiteName: "group.id.gits.notifserviceextension")
        pref?.set(data, forKey: "NOTIF_DATA")
        pref?.synchronize()

        if observer == nil { observer = MyObserver(object: observed) }
        
        // The observer is not necessery
        
        UNUserNotificationCenter.current().getDeliveredNotifications { nots in
        
            DispatchQueue.main.async { [weak self] in
                self?.observed.badgeCountUpdate({ num in
                    bestAttemptContent.categoryIdentifier = "Dismiss"
                    bestAttemptContent.badge = num
                    
                    contentHandler(bestAttemptContent)
                })
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
    
            contentHandler(bestAttemptContent)
        }
    }
}


class MyObjectToObserve: NSObject {
    @objc dynamic var badgeCount = 0
    
    func badgeCountUpdate(_ completion: @escaping (NSNumber) -> ()) {
        UNUserNotificationCenter.current().getDeliveredNotifications { nots in
            return completion(NSNumber(value: nots.count + 1))
        }
    }
}

class MyObserver: NSObject {
    @objc var objectToObserve: MyObjectToObserve
    var observation: NSKeyValueObservation?
    
    init(object: MyObjectToObserve) {
        objectToObserve = object
        super.init()
        
        observation = observe(
            \.objectToObserve.badgeCount,
            options: [.old, .new]
        ) { object, change in
            print("myDate changed from: \(change.oldValue!), updated to: \(change.newValue!)")
        }
    }
}
