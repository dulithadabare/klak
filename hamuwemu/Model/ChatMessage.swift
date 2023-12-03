//
//  ChatMessage.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/15/21.
//

import Foundation

class ChatMessage {
    var id: String
    let author: String
    let sender: String
    let timestamp: Date
    let channel: String
    let group: String
    let channelName: String
    let groupName: String
    let message: HwMessage
    let isChat: Bool
    var isSystemMessage = false
    // threads
    var thread: String? = nil
    var threadName: String? = nil
    let isThreadMessage: Bool
    var replyCount: Int
    var latestReplyMessage: ChatMessage? = nil
    //reply to message
    var replyOriginalMessage: ChatMessage? = nil
    
    var isSent: Bool = false
    var isDelivered: Bool = false
    var isRead: Bool = false
    var isReadByCurrUser: Bool = false
    var isDeliveredToCurrUser: Bool = false
    
    
    internal init(id: String, author: String, sender: String, timestamp: Date, channel: String, group: String, channelName: String, groupName: String, message: HwMessage, isChat: Bool, thread: String? = nil, threadName: String? = nil, replyCount: Int, isThreadMessage: Bool, isSent: Bool = false, isDelivered: Bool = false, isRead: Bool = false, isReadByCurrUser: Bool = false, isDeliveredToCurrUser: Bool = false, isSystemMessage: Bool = false, latestReplyMessage: ChatMessage? = nil, replyOriginalMessage: ChatMessage? = nil) {
        self.id = id
        self.author = author
        self.sender = sender
        self.timestamp = timestamp
        self.channel = channel
        self.group = group
        self.channelName = channelName
        self.groupName = groupName
        self.message = message
        self.isChat = isChat
        self.thread = thread
        self.threadName = threadName
        self.replyCount = replyCount
        self.isThreadMessage = isThreadMessage
        self.isSent = isSent
        self.isDelivered = isDelivered
        self.isRead = isRead
        self.isReadByCurrUser = isReadByCurrUser
        self.isDeliveredToCurrUser = isDeliveredToCurrUser
        self.isSystemMessage = isSystemMessage
        self.latestReplyMessage = latestReplyMessage
        self.replyOriginalMessage = replyOriginalMessage
    }
    
    init?(dict: [String: Any]) {
        guard let id = dict["id"] as? String else { return nil }
        guard let author = dict["author"] as? String else { return nil }
        
        guard let sender = dict["sender"] as? String? else { return nil }

        guard let channel = dict["channel"] as? String else { return nil }
        guard let group = dict["group"] as? String else { return nil }
        guard let timestamp = dict["timestamp"] as? String else { return nil }

        guard let channelName = dict["channelName"] as? String else {
            return nil
        }
        guard let groupName = dict["groupName"] as? String else {
            return nil
        }
        guard let message = dict["message"] as? [String: Any] else {
            return nil
        }

        guard let isChat = dict["isChat"] as? Bool else {
            return nil
        }

        guard let isSent = dict["isSent"] as? Bool? else {
            return nil
        }

        guard let isDelivered = dict["isDelivered"] as? Bool? else {
            return nil
        }

        guard let isRead = dict["isRead"] as? Bool? else {
            return nil
        }

        guard let isReadByCurrUser = dict["isReadByCurrUser"] as? Bool? else {
            return nil
        }

        guard let isDeliveredToCurrUser = dict["isDeliveredToCurrUser"] as? Bool? else {
            return nil
        }

        guard let isSystemMessage = dict["isSystemMessage"] as? Bool? else {
            return nil
        }
        
        guard let latestReplyMessage = dict["latestReplyMessage"] as? [String: Any]? else {
            return nil
        }
        
        guard let replyOriginalMessage = dict["replyOriginalMessage"] as? [String: Any]? else {
            return nil
        }

        let thread = dict["thread"] as? String ?? nil
        let threadName = dict["threadName"] as? String ?? nil
        let replyCount = dict["replyCount"] as? Int ?? 0
        let isThreadMessage = dict["isThreadMessage"] as? Bool ?? true

        self.id = id
        self.author = author
        self.sender = sender ?? message["sender"] as? String ?? "Old Message"
        self.timestamp = ISO8601DateFormatter().date(from: timestamp) ?? Date()
        self.channel = channel
        self.group = group
        self.channelName = channelName
        self.groupName = groupName
        self.message = HwMessage(dict: message)!
        self.isChat = isChat
        self.thread = thread
        self.threadName = threadName
        self.replyCount = replyCount
        self.isThreadMessage = isThreadMessage
        self.isSent = isSent ?? false
        self.isDelivered = isDelivered ?? false
        self.isRead = isRead ?? false
        self.isReadByCurrUser = isReadByCurrUser ?? false
        self.isDeliveredToCurrUser = isDeliveredToCurrUser ?? false
        self.isSystemMessage = isSystemMessage ?? false
        if let latestReplyMessage = latestReplyMessage {
            self.latestReplyMessage = ChatMessage(dict: latestReplyMessage)
        }
        if let replyOriginalMessage = replyOriginalMessage {
            self.replyOriginalMessage = ChatMessage(dict: replyOriginalMessage)
        }
    }
}

extension ChatMessage {
    //Preview
    convenience init(){
        self.init(id:  "",
                  author:  "",
                  sender: SampleData.shared.currentSender.senderId,
                  timestamp:  Date(),
                  channel:  UUID().uuidString,
                  group:  UUID().uuidString,
                  channelName:  "Preview channel name",
                  groupName:  "Preview group name",
                  message:  HwMessage(),
                  isChat:  false,
                  thread:  nil,
                  threadName:  "Preview thread name",
                  replyCount:  0,
                  isThreadMessage:  true)
        
    }
    
    // system message
    convenience init(id: String, systemMessage: HwMessage, channel: String, channelName: String, group: String, groupName: String, isChat: Bool, thread: String?, threadName: String?) {
        self.init(id: id
            ,author: "system",
                  sender: SampleData.shared.system.senderId
            ,timestamp: Date()
            ,channel: channel
            ,group: group
            ,channelName: channelName
            ,groupName: groupName
            ,message: systemMessage
            ,isChat: isChat
            ,thread: thread
            ,threadName: threadName
            ,replyCount: 0
            ,isThreadMessage: thread != nil
            ,isSystemMessage: true)
    }

    convenience init(id: String, message: HwMessage, author: String, sender: String, channel: String, channelName: String, group: String, groupName: String, isChat: Bool, thread: String? = nil, threadName: String? = nil, replyMessage: ChatMessage? = nil) {
        self.init(
            id: id,
            author: author,
            sender: sender,
            timestamp: Date(),
            channel: channel,
            group: group,
            channelName: channelName,
            groupName: groupName,
            message: message,
            isChat: isChat,
            thread: thread,
            threadName: threadName,
            replyCount: 0,
            isThreadMessage: thread != nil,
            isSent: false,
            replyOriginalMessage: replyMessage
        )
    }
    
    // removeReplies flag is used to prevent ChatMessages from nesting
    // firebase only allows 15 levels of nesting
    convenience init(from item: HwChatMessage, removeReplies: Bool = false){
        let status = MessageStatus(rawValue: item.statusRawValue)
        var latestReply: ChatMessage?
        if !removeReplies, let lastReplyItem = item.replies?.lastObject as? HwChatMessage{
            latestReply = ChatMessage(from: lastReplyItem, removeReplies: true)
        }
        
        let replyingTo = !removeReplies && item.replyingTo != nil ?  ChatMessage(from: item.replyingTo!, removeReplies: true) : nil
        let message =  getMessage(from: item.text!)
        self.init(id: item.messageId!, author: item.author!, sender: item.sender!, timestamp: item.timestamp!, channel: item.channelUid!, group: item.groupUid!, channelName: item.channelName!, groupName: item.groupName!, message: message, isChat: item.isChat, thread: item.threadUid, threadName: item.threadName, replyCount: Int(item.replyCount), isThreadMessage: item.isThreadMessage, isSent: status == .sent, isDelivered: status == .delivered, isRead: status == .read, isReadByCurrUser: item.isReadByMe, isDeliveredToCurrUser: true, isSystemMessage: item.isSystemMessage, latestReplyMessage: latestReply, replyOriginalMessage: replyingTo)
    }
}

// MARK: - DatabaseRepresentation
extension ChatMessage: DatabaseRepresentation {
    var representation: [String: Any] {
        var rep: [String: Any] = [
            //uid will be set with key from childByAutoId
            "id": id,
            "author": author,
            "timestamp": ISO8601DateFormatter().string(from: timestamp),
            "channel": channel,
            "group": group,
            "channelName": channelName,
            "groupName": groupName,
            "message": message.representation,
            "isChat": isChat,
            "isThreadMessage": isThreadMessage,
            "replyCount": replyCount,
            "isSystemMessage": isSystemMessage,
        ]
        
        if let thread = thread {
            rep["thread"] = thread
        }
        
        if let threadName = threadName {
            rep["threadName"] = threadName
        }
        
        if let latestReplyMessage = latestReplyMessage {
            latestReplyMessage.latestReplyMessage = nil
            rep["latestReplyMessage"] = latestReplyMessage.representation
        }
        
        if let replyOriginalMessage = replyOriginalMessage {
            replyOriginalMessage.replyOriginalMessage = nil
            rep["replyOriginalMessage"] = replyOriginalMessage.representation
        }
        
        return rep
    }
}
