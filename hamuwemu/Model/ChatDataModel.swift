//
//  ChatDataModel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/30/21.
//

import Foundation
import Combine
import CoreData

class ChatDataModel: ObservableObject {
    static let shared = ChatDataModel()
    
    @Published public private(set) var chats = [String: ChatGroup]()
    @Published public private(set) var chatListItems = [String: HwChatListItem]()
    var unreadMessageIds: [String: Set<String>] = [:]
    var managedObjectContext: NSManagedObjectContext
    
    private init(inMemory: Bool = false) {
        if inMemory {
            managedObjectContext = PersistenceController.preview.container.viewContext
        } else {
            managedObjectContext = PersistenceController.shared.container.viewContext
        }
//        loadChatListItems()
    }
    
    func loadChatListItems() {
        var asyncFetchRequest: NSAsynchronousFetchRequest<HwChatListItem>?
        
        let fetchRequest: NSFetchRequest<HwChatListItem> = HwChatListItem.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \HwChatListItem.lastMessageDate, ascending: false)]
        
        asyncFetchRequest =
        NSAsynchronousFetchRequest<HwChatListItem>(
            fetchRequest: fetchRequest) {
                [unowned self] (result: NSAsynchronousFetchResult) in
                
                guard let hwItems = result.finalResult else {
                    return
                }
                
                var loadedChats = [String: HwChatListItem]()
                for hwItem in hwItems {
                    loadedChats[hwItem.groupId!] = hwItem
                }
                
                chatListItems = loadedChats
            }
        
        do {
            //                let hwItems = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
            
            guard let asyncFetchRequest = asyncFetchRequest else {
                return
            }
            try managedObjectContext.execute(asyncFetchRequest)
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
    }
    
//    func addChatMessage(with message: ChatMessage) {
//        let _ = HwChatMessage.createFromMessage(message, with: managedObjectContext)
//        PersistenceController.shared.save()
//    }
//
//
//
//    func updateChatListItem(with message: ChatMessage){
//        if let item = chatListItems[message.group] {
//            item.lastMessageAttrText = HwChatListItem.getAttributedString(from: message.message)
//            item.lastMessageText = message.message.content
//            item.lastMessageSender = message.sender
//            item.lastMessageAuthorUid = message.author
//            item.lastMessageDate = message.timestamp
//            item.lastMessageId = message.id
//            if message.author == AuthenticationService.shared.userId! {
//                let status: MessageStatus = message.isRead ? .read : message.isDelivered ? .delivered : message.isSent ? .sent : .none
//                item.lastMessageStatus = status.rawValue
//            }
//            item.threadId = message.thread
//            item.threadName = message.threadName
//            print("updateChatListItem: HwChatListItem unread count \(item.unreadCount)")
//            item.unreadCount += 1
//
//
//
////                    chat.message = message
////                    chatDataModel.updateChat(with: chat)
//            // save chat
////                    chats[chat.group] = ChatListItem(from: chat)
//        } else {
//            let item = HwChatListItem(context: PersistenceController.shared.container.viewContext)
//            let groupId = message.group
//            let groupName = message.groupName
//            let channelId = message.channel
//            let channelName = message.channelName
//            item.groupId = groupId
//            item.groupName = groupName
//            item.channelId = channelId
//            item.channelName = channelName
//            item.threadId = message.thread
//            item.threadName = message.threadName
//            item.isChat = message.isChat
//
//            item.lastMessageAttrText = HwChatListItem.getAttributedString(from: message.message)
//            item.lastMessageText = message.message.content
//            item.lastMessageSender = message.sender
//            item.lastMessageAuthorUid = message.author
//            item.lastMessageDate = message.timestamp
//            item.lastMessageId = message.id
//            if message.author == AuthenticationService.shared.userId! {
//                let status: MessageStatus = message.isRead ? .read : message.isDelivered ? .delivered : message.isSent ? .sent : .none
//                item.lastMessageStatus = status.rawValue
//            }
//            item.unreadCount = 1
//
//            let group = HwChatGroup(context: PersistenceController.shared.container.viewContext)
//            group.groupId = groupId
//            group.groupName = groupName
//            group.createdAt = Date()
//            group.isChat = true
//
//            let defaultChannel = HwChatChannel(context: PersistenceController.shared.container.viewContext)
//            defaultChannel.channelId = channelId
//            defaultChannel.channelName = channelName
//            group.defaultChannel = defaultChannel
//
//            item.group = group
//
////                    chatDataModel.add(chat)
//            // save chat
////                    chats[chat.group] = ChatListItem(from: chat)
//            chatListItems[item.groupId!] = item
//        }
//
//        PersistenceController.shared.save()
//    }
//
//    func addTempChatListItem(from chat: ChatGroup){
//        let item = HwChatListItem(context: PersistenceController.shared.container.viewContext)
//        let groupId = chat.group
//        let groupName = chat.groupName
//        let channelId = chat.defaultChannel.channelUid
//        let channelName = chat.defaultChannel.title
//        item.groupId = groupId
//        item.groupName = groupName
//        item.channelId = channelId
//        item.channelName = channelName
//        item.isChat = chat.isChat
//        item.unreadCount = 0
//
//        let group = HwChatGroup(context: PersistenceController.shared.container.viewContext)
//        group.groupId = groupId
//        group.groupName = groupName
//        group.createdAt = Date()
//        group.isChat = true
//        group.isTemp = true
//
//        let defaultChannel = HwChatChannel(context: PersistenceController.shared.container.viewContext)
//        defaultChannel.channelId = channelId
//        defaultChannel.channelName = channelName
//        group.defaultChannel = defaultChannel
//
//        item.group = group
//        item.isTemp = true
//
//        PersistenceController.shared.save()
//    }
//
//    func removeTempListItems() {
//        var asyncFetchRequest: NSAsynchronousFetchRequest<HwChatListItem>?
//
//        let fetchRequest: NSFetchRequest<HwChatListItem> = HwChatListItem.fetchRequest()
//        fetchRequest.predicate = NSPredicate(format: "isTemp = %d", true)
//
//        asyncFetchRequest =
//        NSAsynchronousFetchRequest<HwChatListItem>(
//            fetchRequest: fetchRequest) {
//                [unowned self] (result: NSAsynchronousFetchResult) in
//
//                guard let hwItems = result.finalResult else {
//                    return
//                }
//
//                for hwItem in hwItems {
//                    managedObjectContext.delete(hwItem)
//                }
//
//                PersistenceController.shared.save()
//            }
//
//        do {
//
//            guard let asyncFetchRequest = asyncFetchRequest else {
//                return
//            }
//            try managedObjectContext.execute(asyncFetchRequest)
//        } catch let error as NSError {
//            print("Could not delete temp items \(error), \(error.userInfo)")
//        }
//    }
//
//    fileprivate func removeTempGroups() {
//        var asyncFetchRequest: NSAsynchronousFetchRequest<HwChatGroup>?
//
//        let fetchRequest: NSFetchRequest<HwChatGroup> = HwChatGroup.fetchRequest()
//        fetchRequest.predicate = NSPredicate(format: "isTemp = %d", true)
//
//        asyncFetchRequest =
//        NSAsynchronousFetchRequest<HwChatGroup>(
//            fetchRequest: fetchRequest) {
//                [unowned self] (result: NSAsynchronousFetchResult) in
//
//                guard let hwItems = result.finalResult else {
//                    return
//                }
//
//                for hwItem in hwItems {
//                    managedObjectContext.delete(hwItem)
//                }
//
//                PersistenceController.shared.save()
//            }
//
//        do {
//
//            guard let asyncFetchRequest = asyncFetchRequest else {
//                return
//            }
//            try managedObjectContext.execute(asyncFetchRequest)
//        } catch let error as NSError {
//            print("Could not delete temp items \(error), \(error.userInfo)")
//        }
//    }
//
//    func removeTempData(){
//        // remove group members
//        // remove channel
//        // remove group
//        // remove list item
//        removeTempGroups()
//        removeTempListItems()
//    }
    
    func updateChats(chats: [String: ChatGroup]){
//        self.chats = chats
        for (key, newChat) in chats {
            if let chat = self.chats[key] {
                chat.groupName = newChat.groupName
                chat.message = newChat.message
                chat.isTemp = false
                self.chats[key] = chat
            } else {
//                let unreadCount = unreadCounts[key] ?? 0
//                newChat.unreadCount = unreadCount
                self.chats[key] = newChat
            }
        }
        
        //update temp chats
        
    }
    
    func add(_ chat: ChatGroup){
        self.chats[chat.group] = chat
    }
    
    func updateUnreadCount(with chatMessage: ChatMessage){
        if !chatMessage.isReadByCurrUser, AuthenticationService.shared.userId! != chatMessage.author {
//            print("Updating unread count")
            unreadMessageIds.merge([chatMessage.group : [chatMessage.id]]){ $0.union($1) }
            
            if let chat = chats[chatMessage.group],
               let unreadCount = unreadMessageIds[chatMessage.group]?.count {
                chat.unreadCount = UInt(unreadCount)
                self.chats[chatMessage.group] = chat
            }
           
        }
    }
    
    func clearUnreadCount(for group: String){
        if let chat = chats[group] {
            chat.unreadCount = 0
            self.chats[group] = chat
        }
    }
    
    func getChat(from chatID: String) -> ChatGroup? {
        if let chat = chats[chatID] {
            return chat
        }
        
        return nil
    }
    
    func updateChat(with chat: ChatGroup){
        chats[chat.group] = chat
    }
}
