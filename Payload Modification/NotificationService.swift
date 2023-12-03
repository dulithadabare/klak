//
//  NotificationService.swift
//  Payload Modification
//
//  Created by Dulitha Dabare on 2022-03-23.
//

import UserNotifications
import CoreData
import CCHDarwinNotificationCenter
import PromiseKit
import Firebase
import FirebaseAuth

// We keep a global `environment` singleton to ensure that our app context,
// database, logging, etc. are only ever setup once per *process*
let environment = Environment()

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        environment.setupIfNecessary()
        
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            
            if let increment = bestAttemptContent.badge as? Int {
              if increment == 0 {
                UserDefaults.extensions.badge = 0
                bestAttemptContent.badge = 0
              } else {
                let current = UserDefaults.extensions.badge
                let new = current + increment

                UserDefaults.extensions.badge = new
                bestAttemptContent.badge = NSNumber(value: new)
              }
            }
            
            guard let userId = environment.auth.currentUser?.uid else {
                bestAttemptContent.body = "Current user not set"
                contentHandler(bestAttemptContent)
                return
            }
            
            if let type = Int(bestAttemptContent.userInfo["type"] as! String),
               type == PushType.addMessage.rawValue,
//                let userId = UserDefaults.extensions.uid,
               let messageId = bestAttemptContent.userInfo["id"] as? String,
               let author = bestAttemptContent.userInfo["author"] as? String,
                let sender = bestAttemptContent.userInfo["sender"] as? String,
               let senderPublicKey = bestAttemptContent.userInfo["senderPublicKey"] as? String,
               let groupId = bestAttemptContent.userInfo["groupId"] as? String,
               let timestampString = bestAttemptContent.userInfo["timestamp"] as? String{
                
                var channelId: String? = nil
                var threadId: String? = nil
                
                if let value = bestAttemptContent.userInfo["channelId"] as? String,
                   !value.isEmpty {
                    channelId = value
                }
                
                if let value = bestAttemptContent.userInfo["threadId"] as? String,
                   !value.isEmpty {
                    threadId = value
                }
                
                bestAttemptContent.title = fetchFullName(phoneNumber: sender)
                
                if bestAttemptContent.body.isEmpty {
                    bestAttemptContent.body = "📸 Photo"
                } else {
                    bestAttemptContent.body = EncryptionService.shared.decrypt(content: bestAttemptContent.body, from: sender, senderPublicKey: senderPublicKey,  inGroup: groupId, userId: userId)
                }
                
                let timestamp = MessageDateFormatter.shared.getDateFrom(DateString8601: timestampString)!
                let content = HwMessage(content: bestAttemptContent.body, mentions: [], links: [])
                let message = AddMessageModel(id: messageId, author: author, sender: sender, timestamp: timestamp, channel: channelId, group: groupId, message: content, thread: threadId, replyingInThreadTo: nil, senderPublicKey: senderPublicKey)
                
                if let _ = channelId {
                    bestAttemptContent.subtitle = ""
                } else if let _ = threadId {
                
                }
                
                environment.askMainAppToHandleReceipt { [weak self] mainAppHandledReceipt in
                    guard !mainAppHandledReceipt else {
//                        bestAttemptContent.body = "Main app is active"
                        contentHandler(bestAttemptContent)
                        return
                    }
                    
                    self?.fetch(bestAttemptContent: bestAttemptContent)
//                    self?.process(message, bestAttemptContent: bestAttemptContent)
                
//                    bestAttemptContent.body = "Main app is not active"
//                    contentHandler(bestAttemptContent)
                }
                
            } else if let type = Int(bestAttemptContent.userInfo["type"] as! String),
                      type == PushType.addThread.rawValue {
                
            }

            
//            bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"
//            contentHandler(bestAttemptContent)
        
            
            
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    func fetch(bestAttemptContent: UNMutableNotificationContent) {
        let fetch = environment.messageFetcher.run()
        fetch.timeout(seconds: 20).then(on: .global()) {
            environment.messageFetcher.pendingAcksPromise()
        }.done(on: .global()) { _ in
            self.contentHandler?(bestAttemptContent)
        }.catch(on: .global()) { error in
            bestAttemptContent.body = "Message Fetch failed \(error)"
            self.contentHandler?(bestAttemptContent)
            print("Message Fetch failed \(error)")
        }
    }
    
    func fetchChatGroup(groupId: String) -> HwChatGroup? {
        let fetchRequest: NSFetchRequest<HwChatGroup> = HwChatGroup.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatGroup.groupId), groupId)
        if let results = try? environment.persistentController?.container.viewContext.fetch(fetchRequest),
           let item = results.first {
            return item
        }
        
        return nil
    }
    
    func fetchThread(threadId: String) -> HwChatThread? {
        let fetchRequest: NSFetchRequest<HwChatThread> = HwChatThread.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatThread.threadId), threadId)
        if let results = try? environment.persistentController?.container.viewContext.fetch(fetchRequest),
           let item = results.first {
            return item
        }
        
        return nil
    }
    
    func fetchFullName(phoneNumber: String) -> String {
        let fetchRequest: NSFetchRequest<HwImportedContact> = HwImportedContact.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwImportedContact.phoneNumber), phoneNumber)
        if let results = try? environment.persistentController?.container.viewContext.fetch(fetchRequest),
           let item = results.first {
            return item.displayName!
        }
        
        return phoneNumber
    }

}
