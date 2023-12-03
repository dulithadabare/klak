//
//  ChatGroup.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/26/21.
//

import Foundation

class ChatGroup: ObservableObject {
    var author: String? = nil
    var group: String
    var groupName: String
    let isChat: Bool
    @Published public private(set) var members: [String: AppUser] = [:]
    var channels = [String: ChatChannel]()
    var threads = [String: ChatThread]()
    // properties related to chat ui
    var message: ChatMessage? = nil
    // used to determine sort order when message is nil
    var timestamp = Date()
    var isTemp = false
    var defaultChannel: ChatChannel
    var unreadCount: UInt = 0
    var hwListItem: HwChatListItem?
    
    init(group: String, groupName: String, isChat: Bool, defaultChannel: ChatChannel? = nil) {
        self.group = group
        self.groupName = groupName
        self.isChat = isChat
        self.defaultChannel = defaultChannel ?? ChatChannel(title: "General", group: group)
    }
    
    convenience init(groupName: String){
        self.init(group: UUID().uuidString, groupName: groupName, isChat: false)
        self.members = [:]
    }
    
    convenience init(groupName: String, isChat: Bool, members: [AppUser]){
        let group = PushIdGenerator.shared.generatePushID()
        self.init(group: group, groupName: groupName, isChat: isChat)
        self.addMembers(appUsers: members)
        self.isTemp = true
    }
    
    //preview
    convenience init(group: String, groupName: String, isChat: Bool, members: [AppUser]){
        self.init(group: group, groupName: groupName, isChat: isChat)
        self.addMembers(appUsers: members)
        self.isTemp = true
    }
    
    init?(dict: [String: Any]) {
        guard let groupId = dict["group"] as? String else { return nil }
        guard let groupName = dict["groupName"] as? String else {
            return nil
        }
        
        guard let message = dict["message"] as? [String: Any]? else {
            return nil
        }
        
        guard let defaultChannel = dict["defaultChannel"] as? [String: Any] else {
            return nil
        }
        
        guard let isChat = dict["isChat"] as? Bool else {
            return nil
        }
        var chatMessage: ChatMessage?
        if let message = message {
            chatMessage = ChatMessage(dict: message)
        }
        
        guard let membersDict = dict["members"] as? [String: [String: Any]] else { return  nil}
      
        
        var members = [String: AppUser]()
        for (_, childDict) in membersDict {
            let uid = childDict["uid"] as? String ?? ""
            let phoneNumber = childDict["phoneNumber"] as? String ?? ""
            let appUser = AppUser(uid: uid, phoneNumber: phoneNumber)
            members[appUser.uid] = appUser
        }
        
        self.group = groupId
        self.groupName = groupName
        self.message = chatMessage
        self.isChat = isChat
        self.defaultChannel = ChatChannel(dict: defaultChannel)!
        self.members = members
//        if let chatMessage = chatMessage {
//            self.unreadCount = chatMessage.isReadByCurrUser ? 0 : 1
//        }
    }
    
    init(from message: ChatMessage) {

        self.group = message.group
        self.groupName = message.groupName
        self.message = message
        self.isChat = message.isChat
        self.defaultChannel = ChatChannel(channelUid: message.channel, title: message.channelName, group: message.group)
    }
    
    init(from hwChatGroup: HwChatGroup) {

        self.group = hwChatGroup.groupId!
        self.groupName = hwChatGroup.groupName!
        self.isChat = hwChatGroup.isChat
        self.defaultChannel = ChatChannel(channelUid: hwChatGroup.defaultChannel!.channelId!, title: hwChatGroup.defaultChannel!.channelName!, group: hwChatGroup.groupId!)
    }
    
    init(from hwChatListItem: HwChatListItem) {
        self.hwListItem = hwChatListItem
        let hwChatGroup = hwChatListItem.group!
        self.group = hwChatGroup.groupId!
        self.groupName = hwChatGroup.groupName!
        self.isChat = hwChatGroup.isChat
        self.defaultChannel = ChatChannel(channelUid: hwChatGroup.defaultChannel!.channelId!, title: hwChatGroup.defaultChannel!.channelName!, group: hwChatGroup.groupId!)
    }
    
    func updateChannels(channels: [String: ChatChannel]){
        //merge
        for (key, newChannel) in channels {
            if let channel = self.channels[key] {
                channel.title = newChannel.title
                channel.message = newChannel.message
                channel.isTemp = false
                self.channels[key] = channel
            } else {
                self.channels[key] = newChannel
            }
        }
    }
    
    func updateThreads(threads: [String: ChatThread]){
        //merge
        for (key, newThread) in threads {
            if let thread = self.threads[key] {
                thread.message = newThread.message
                thread.isTemp = false
                self.threads[key] = thread
            } else {
                self.threads[key] = newThread
            }
        }
    }
    
    func clearChannels(){
        channels = [:]
    }
    
    func addMembers(appUsers: [AppUser]){
        for appUser in appUsers {
            self.members[appUser.uid] = appUser
        }
    }
}

extension ChatGroup: Encodable {
    enum CodingKeys: CodingKey {
        case author, group, groupName, isChat, members, defaultChannel
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(author, forKey: .author)
        try container.encode(group, forKey: .group)
        try container.encode(groupName, forKey: .groupName)
        try container.encode(isChat, forKey: .isChat)
//        try container.encode(defaultChannel, forKey: .defaultChannel)
        try container.encode(members, forKey: .members)
    }
}
