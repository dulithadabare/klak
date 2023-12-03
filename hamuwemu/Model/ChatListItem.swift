//
//  ChatListItem.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/28/21.
//

import Foundation

struct ChatListItem: Identifiable, Hashable {
    var id: String
    let timestamp: Date
    let channel: String?
    var group: ChatGroup
    let channelName: String?
    var groupName: String
    var message: ChatMessage?
    let isChat: Bool
    let unreadCount: UInt
    var lastMessageText: NSAttributedString?
    var lastMessageSender: String?
    var lastMessageStatus: MessageStatus?
    var lastMessageId: String?
    var lastMessageDate: Date?
    var lastMessageAuthorUid: String?
    
    
    static func == (lhs: ChatListItem, rhs: ChatListItem) -> Bool {
        lhs.id == rhs.id
//            && lhs.message == rhs.message
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
//        hasher.combine(message)
    }
}

extension ChatListItem {    
    init(from chat: ChatGroup) {
        self.id = chat.group
        self.timestamp = chat.message?.timestamp ?? chat.timestamp
        self.channel = chat.message?.channel
        self.group = chat
        self.channelName = chat.message?.channelName
        self.groupName = chat.groupName
        self.message = chat.message
        self.isChat = chat.isChat
        unreadCount = chat.unreadCount
        
    }
    
    init(from item: HwChatListItem, with contactRepository: ContactRepository) {
        self.id = item.groupId!
        self.timestamp = item.lastMessageDate!
        self.channel = item.channelId!
        self.group = ChatGroup(from: item.group!)
        self.channelName = item.channelName!
        self.groupName = item.groupName!
        
        self.lastMessageText =  nil
        
        self.lastMessageSender = item.lastMessageSender
        self.lastMessageAuthorUid = item.lastMessageAuthorUid
        self.lastMessageStatus = MessageStatus(rawValue: item.lastMessageStatusRawValue)
        self.lastMessageId = item.lastMessageId
        self.lastMessageDate = item.lastMessageDate
        
        self.isChat = item.isChat
        unreadCount = UInt(item.unreadCount)
    }
    
    init(from chat: ChatGroup, unreadCount: UInt) {
        self.id = chat.group
        self.timestamp = chat.message?.timestamp ?? chat.timestamp
        self.channel = chat.message?.channel
        self.group = chat
        self.channelName = chat.message?.channelName
        self.groupName = chat.groupName
        self.message = chat.message
        self.isChat = chat.isChat
        self.unreadCount = unreadCount
    }
}

