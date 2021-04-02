//
//  NotificationService.swift
//  MindboxNotificationServiceExtension
//
//  Created by Petr Nikitin on 01.04.2021.
//

import UserNotifications
import Mindbox

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        
       
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        print(bestAttemptContent ?? "No Content in Push")
        if let bestAttemptContent = bestAttemptContent {
            // Передача данных о полученном пуше в Mindbox
            
            print(bestAttemptContent.title)
            if Mindbox.shared.pushDelivered(request: request) {
                bestAttemptContent.categoryIdentifier = "MindBoxCategoryIdentifier"
                bestAttemptContent.title = "\(bestAttemptContent.title) [Send status success]"
            } else {
                bestAttemptContent.title = "\(bestAttemptContent.title) [Send status failed]"
            }
            
            contentHandler(bestAttemptContent)
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
