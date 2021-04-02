//
//  NotificationViewController.swift
//  MindboxContentExtension
//
//  Created by Petr Nikitin on 01.04.2021.
//

import UIKit
import UserNotifications
import UserNotificationsUI

@available(iOSApplicationExtension 12.0, *)
class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet var label: UILabel?
    
    private var attachmentUrl: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
        self.label?.text = notification.request.content.body
        createButtons(for: notification)
    }
    
    
    private func createButtons(for notification: UNNotification) {
        let request = notification.request
        guard let payload = parse(request: request) else {
            return
        }
        if let attachment = notification.request.content.attachments.first, attachment.url.startAccessingSecurityScopedResource() {
            attachmentUrl = attachment.url
            createImageView(with: payload)
        }
        createActions(with: payload, context: extensionContext)
    }
    
    private func createImageView(with payload: Payload) {
        guard let imageUrl = payload.imageUrl, let url = URL(string: imageUrl) else {
            return
        }
        guard let data = try? Data(contentsOf: url) else {
            return
        }
        let imageView = UIImageView(image: UIImage(data: data))
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor),
            imageView.leftAnchor.constraint(equalTo: view.leftAnchor),
            imageView.rightAnchor.constraint(equalTo: view.rightAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 300)
        ])
    }

    
    private func createActions(with payload: Payload, context: NSExtensionContext?) {
        guard let context = context, let buttons = payload.buttons else {
            return
        }
        let actions = buttons.map { button in
            UNNotificationAction(
                identifier: button.uniqueKey,
                title: button.text,
                options: [.foreground]
            )
        }
        context.notificationActions = []
        actions.forEach {
            context.notificationActions.append($0)
        }
    }

    
    private func parse(request: UNNotificationRequest) -> Payload? {
        guard let userInfo = getUserInfo(from: request) else {
            return nil
        }
        guard let data = try? JSONSerialization.data(withJSONObject: userInfo, options: .prettyPrinted) else {
            return nil
        }
        return try? JSONDecoder().decode(Payload.self, from: data)
    }
    
    private func getUserInfo(from request: UNNotificationRequest) -> [AnyHashable: Any]? {
        guard let userInfo = (request.content.mutableCopy() as? UNMutableNotificationContent)?.userInfo else {
            return nil
        }
        if userInfo.keys.count == 1, let innerUserInfo = userInfo["aps"] as? [AnyHashable: Any] {
            return innerUserInfo
        } else {
            return userInfo
        }
    }
    
    fileprivate struct Payload: Codable {
        
        struct Buttons: Codable {
            let text: String
            let uniqueKey: String
        }
        
        let uniqueKey: String
        
        let buttons: [Buttons]?
        
        let imageUrl: String?

        var debugDescription: String {
            "uniqueKey: \(uniqueKey)"
        }
        
    }
}
