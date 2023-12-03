//
//  NotificationDelegate.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-23.
//

import UserNotifications
import FirebaseMessaging

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    @Published var isBeachViewActive = false
    @Published var selectedTab = 1
    @Published var selectedChat: String? = nil
    @Published var selectedThread: String? = nil
    @Published var currentView: String = ""
    
    static let shared = NotificationDelegate()
    
    private override init() {
        super.init()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        
        if let type = Int(userInfo["type"] as! String),
           type == PushType.addMessage.rawValue,
           let _ = userInfo["groupId"] as? String {
            
            
            if let channelId = userInfo["channelId"] as? String,
               !channelId.isEmpty {
                if currentView == channelId {
                    completionHandler([])
                    return
                }
            } else if let threadId = userInfo["threadId"] as? String,
                      !threadId.isEmpty {
                if currentView == threadId {
                    completionHandler([])
                    return
                }
            }
        }
        completionHandler([.banner])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }
        
        let userInfo = response.notification.request.content.userInfo
        
        let identity = response.notification.request.content.categoryIdentifier
        if identity == categoryIdentifier,
          let action = ActionIdentifier(rawValue: response.actionIdentifier) {
            print("You pressed \(response.actionIdentifier)")
        } else if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            print("You pressed \(response.actionIdentifier)")
            if let type = Int(userInfo["type"] as! String),
                 type == PushType.addMessage.rawValue,
                 let groupId = userInfo["groupId"] as? String {
                  
                  
                  if let channelId = userInfo["channelId"] as? String,
                     !channelId.isEmpty {
                      selectedTab = 1
                      selectedChat = groupId
                      selectedThread = nil
                  } else if let threadId = userInfo["threadId"] as? String,
                            !threadId.isEmpty {
//                    selectedTab = 2
                      selectedTab = 1
                      selectedChat = groupId
                      selectedThread = threadId
                  }
              }
        }
        
//        if response.notification.request.content.userInfo["beach"] != nil {
//          // In a real app you'd likely pull a URL from the beach data
//          // and use that image.
//          isBeachViewActive = true
//        }

    }
}

extension NotificationDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
      print("Firebase registration token: \(String(describing: fcmToken))")

        AuthenticationService.shared.saveToken()
    }

}
