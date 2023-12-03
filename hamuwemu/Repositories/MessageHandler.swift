//
//  MessageProcessor.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-04-15.
//

import Foundation
import CoreData
import UIKit
import PromiseKit

class MessageHandler {
    lazy var persistenceController = PersistenceController.shared
    var userId: String
    var transactionAuthor: String?
    init(userId: String, transactionAuthor: String? = nil){
        self.userId = userId
        self.transactionAuthor = transactionAuthor
    }
    
    private var inFlightAcks = AtomicSet<String>()
    
    func process(_ message: ServerPush) -> Promise<Void> {
        guard !inFlightAcks.contains(message.id) else {
            return .value(Void())
        }
        
        inFlightAcks.insert(message.id)
        let promise = handle(message)
        return promise
    }
    
    private let pendingWrites = [Promise<Void>]()
    
    func pendingWritesPromise() -> Promise<Void> {
        when(fulfilled: pendingWrites)
    }
    
    @discardableResult
    private func handle(_ serverPush: ServerPush) -> Promise<Void> {
        switch serverPush.type {
        case .addGroup:
            let chatGroup = serverPush.data as! AddGroupModel
            return insertGroup(chatGroup)
        case .addThread:
            let thread = serverPush.data as! AddThreadModel
            return insertThread(thread)
        case .addMessage:
            let message = serverPush.data as! AddMessageModel
            return insertMessage(message)
        case .changeGroupName:
            let addGroupName = serverPush.data as! AddGroupNameModel
            return changeGroupName(addGroupName)
        case .addGroupMember:
            let appGroupUser = serverPush.data as! AppGroupMember
            return insertGroupMember(appGroupUser)
        case .removeGroupMember:
            let appGroupUser = serverPush.data as! AppGroupMember
            return removeGroupMember(appGroupUser)
        case .systemMessage:
            let systemMessage = serverPush.data as! AddSystemMessageModel
            return insertSystemMessage(systemMessage)
        case .receipt:
            let receipt = serverPush.data as! MessageReceiptModel
            return updateMessageStatus(receipt)
        case .reply:
            return .value(Void())
        case .chatId:
            let chatId = serverPush.data as! ChatIdModel
            return insertChatId(chatId)
        case .appContact:
            let appContact = serverPush.data as! AppUser
            return insertAppContact(appContact)
        case .updateThreadTitle:
            let model = serverPush.data as! UpdateThreadTitleModel
            return updateThreadTitle(model)
        }
    }
    
    func insertGroup(_ chat: AddGroupModel) -> Promise<Void> {
        persistenceController.insertGroup(chat, transactionAuthor: transactionAuthor)
        
    }
    
    func insertThread(_ thread: AddThreadModel) -> Promise<Void> {
        persistenceController.insertThread(thread, transactionAuthor: transactionAuthor)
    }
    
    func insertMessage(_ message: AddMessageModel)  -> Promise<Void> {
        var message = message
        if let text = message.message.content {
            let content = EncryptionService.shared.decrypt(content: text, from: message.sender, senderPublicKey: message.senderPublicKey, inGroup: message.group, userId: userId)
    //        let content = AuthenticationService.shared.account.decrypt(content: message.message.content, from: message.sender, senderPublicKey: message.senderPublicKey, inGroup: message.group)
            message.message.content = content
            
            
        }
        
        return persistenceController.insertMessage(message, transactionAuthor: transactionAuthor)
    }
    
    
    func changeGroupName(_ addGroupNameModel: AddGroupNameModel) -> Promise<Void> {
        persistenceController.enqueue(transactionAuthor: transactionAuthor) { context in
            let fetchRequest: NSFetchRequest<HwChatGroup> = HwChatGroup.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatGroup.groupId), addGroupNameModel.groupUid)
            if let results = try? context.fetch(fetchRequest),
               let item = results.first {
                item.groupName = addGroupNameModel.groupName
            }
        }
    }
    
    func insertGroupMember(_ appGroupMember: AppGroupMember) -> Promise<Void> {
        persistenceController.enqueue(transactionAuthor: transactionAuthor) { context in
            let groupMember = HwGroupMember(context: context)
            groupMember.uid = appGroupMember.uid
            groupMember.phoneNumber = appGroupMember.phoneNumber
            groupMember.groupId = appGroupMember.groupUid
        }
    }
    
    func removeGroupMember(_ appGroupMember: AppGroupMember) -> Promise<Void> {
        persistenceController.enqueue(transactionAuthor: transactionAuthor) { context in
            let fetchRequest: NSFetchRequest<HwGroupMember> = HwGroupMember.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K = %@ AND %K = %@", #keyPath(HwGroupMember.groupId), appGroupMember.groupUid,  #keyPath(HwGroupMember.uid), appGroupMember.uid)
            if let results = try? context.fetch(fetchRequest),
               let item = results.first {
                context.delete(item)
            }
        }
    }
    
    func insertSystemMessage(_ message: AddSystemMessageModel) -> Promise<Void> {
        let messageText = HwChatListItem.getAttributedString(from: message.message)
        
        return persistenceController.enqueue(transactionAuthor: transactionAuthor) { context in
            let item = HwChatMessage(context: context)
            
            item.author = "000000"
            item.sender = "000000"
            item.groupUid = message.group
            item.channelUid = message.channel
            item.threadUid = message.thread
            item.isSystemMessage = true
            item.messageId = message.id
            item.timestamp = message.timestamp
            item.text = messageText
            item.isReadByMe = false
            item.statusRawValue = MessageStatus.none.rawValue
            
            if let messageContext = message.context {
                if message.type == .addThread || message.type == .addThreadInReply,
                   let addThreadContext = messageContext as? AddThreadContext {
                    let threadContext = HwAddThreadMessageContext(context: context)
                    threadContext.messageId = message.id
                    threadContext.threadUid = addThreadContext.threadUid
                    threadContext.threadTitle = HwChatListItem.getAttributedString(from: addThreadContext.threadTitle)
                    //relationships
                    threadContext.message = item
                    item.context = threadContext
                }
                
            }
            
            if message.type == .addThread {
                let fetchRequest: NSFetchRequest<HwChatListItem> = HwChatListItem.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatListItem.groupId), message.group)
                
                if let results = try? context.fetch(fetchRequest),
                   let listItem = results.first {
                    listItem.lastMessageText =  messageText?.string ?? "Image"
                    listItem.lastMessageSender = "000000"
                    listItem.lastMessageId = message.id
                    listItem.lastMessageDate = message.timestamp
                    listItem.lastMessageAttrText = messageText
                    listItem.lastMessageAuthorUid = "000000"
                    listItem.lastMessageStatusRawValue = MessageStatus.none.rawValue
                }
            }
        }
    }
    
    //TODO Compare with recepients list before updaing delivered and read receipts
    func updateMessageStatus(_ receipt: MessageReceiptModel) -> Promise<Void> {
        updateChatListItemStatus(receipt)
        updateThreadListItemStatus(receipt)
        
        return persistenceController.enqueue(transactionAuthor: transactionAuthor) { context in
            let fetchRequest: NSFetchRequest<HwChatMessage> = HwChatMessage.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatMessage.messageId), receipt.messageId )
            
            if let results = try? context.fetch(fetchRequest),
               let item = results.first {
                switch receipt.type {
                case .sent:
                    //prevent overriding
                    if item.statusRawValue != MessageStatus.delivered.rawValue || item.statusRawValue != MessageStatus.read.rawValue {
                        item.statusRawValue = MessageStatus.sent.rawValue
                    }
                    
                case .delivered:
                    if item.statusRawValue != MessageStatus.read.rawValue {
                        item.statusRawValue = MessageStatus.delivered.rawValue
                    }
                    
                    let deliveredItem = HwMessageDelivered(context: context)
                    deliveredItem.messageId = receipt.messageId
                    deliveredItem.userUid = receipt.appUser?.uid
                    deliveredItem.phoneNumber = receipt.appUser?.phoneNumber
                case .read:
                    item.statusRawValue = MessageStatus.read.rawValue
                    let readItem = HwMessageRead(context: context)
                    readItem.messageId = receipt.messageId
                    readItem.userUid = receipt.appUser?.uid
                    readItem.phoneNumber = receipt.appUser?.phoneNumber
                }
            }
        }
    }
    
    func updateChatListItemStatus(_ receipt: MessageReceiptModel) {
        persistenceController.enqueue(transactionAuthor: transactionAuthor) { context in
            let fetchRequest: NSFetchRequest<HwChatListItem> = HwChatListItem.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatListItem.lastMessageId), receipt.messageId )
            
            if let results = try? context.fetch(fetchRequest),
               let item = results.first {
                switch receipt.type {
                case .sent:
                    if item.lastMessageStatusRawValue != MessageStatus.delivered.rawValue || item.lastMessageStatusRawValue != MessageStatus.read.rawValue {
                        item.lastMessageStatusRawValue = MessageStatus.sent.rawValue
                    }
                case .delivered:
                    if item.lastMessageStatusRawValue != MessageStatus.read.rawValue {
                        item.lastMessageStatusRawValue = MessageStatus.delivered.rawValue
                    }
                case .read:
                    item.lastMessageStatusRawValue = MessageStatus.read.rawValue
                }
            }
        }
    }
    
    func updateThreadListItemStatus(_ receipt: MessageReceiptModel) {
        persistenceController.enqueue(transactionAuthor: transactionAuthor) { context in
            let fetchRequest: NSFetchRequest<HwThreadListItem> = HwThreadListItem.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwThreadListItem.lastMessageId), receipt.messageId )
            
            if let results = try? context.fetch(fetchRequest),
               let item = results.first {
                switch receipt.type {
                case .sent:
                    if item.lastMessageStatusRawValue != MessageStatus.delivered.rawValue || item.lastMessageStatusRawValue != MessageStatus.read.rawValue {
                        item.lastMessageStatusRawValue = MessageStatus.sent.rawValue
                    }
                case .delivered:
                    if item.lastMessageStatusRawValue != MessageStatus.read.rawValue {
                        item.lastMessageStatusRawValue = MessageStatus.delivered.rawValue
                    }
                case .read:
                    item.lastMessageStatusRawValue = MessageStatus.read.rawValue
                }
            }
        }
    }
    
    func insertChatId(_ chatId: ChatIdModel) -> Promise<Void> {
        persistenceController.enqueue(transactionAuthor: transactionAuthor) { context in
            let chatIdItem = HwChatId(context: context)
            chatIdItem.groupId = chatId.groupId
            chatIdItem.phoneNumber = chatId.phoneNumber
        }
        
    }
    
    func insertAppContact(_ appContact: AppUser) -> Promise<Void> {
        persistenceController.enqueue(transactionAuthor: transactionAuthor) { context in
            guard let publicKeyData = appContact.publicKey,
                  !publicKeyData.isEmpty,
                  let publicKey = Data(base64Encoded: publicKeyData) else {
                      return
                  }
            
            let item = HwAppContact(context: context)
            item.phoneNumber = appContact.phoneNumber
            item.uid = appContact.uid
            item.publicKey = publicKey
        }
        
    }
    
    func updateThreadTitle(_ model: UpdateThreadTitleModel) -> Promise<Void> {
        persistenceController.enqueue(transactionAuthor: transactionAuthor) { context in
            let fetchRequest: NSFetchRequest<HwChatThread> = HwChatThread.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatThread.threadId), model.threadId)
            if let results = try? context.fetch(fetchRequest),
               let item = results.first {
                item.titleText = NSAttributedString(string: model.title)
            }
        }
    }
}
