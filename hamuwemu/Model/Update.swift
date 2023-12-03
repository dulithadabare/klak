//
//  Update.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/27/21.
//

import Foundation

enum UpdateType: String {
    case all, link, image, mention
}

struct Update: Identifiable {
    let id: String
    let group: String
    var groupName: String
    let channel: String
    let channelName: String
    let message: HwMessage
    let type: [UpdateType]
    let timestamp: Date
    let isChat: Bool
}

extension Update {
    init(groupName: String, channelName: String, message: HwMessage, sender: String, type: [UpdateType]){
        self.id = UUID().uuidString
        self.group = UUID().uuidString
        self.groupName = groupName
        self.channel = UUID().uuidString
        self.channelName = channelName
        self.message = message
        self.type = type
        self.timestamp = Date()
        self.isChat = false
    }
    
    init?(dict: [String: Any]) {
        guard let id = dict["messageUid"] as? String else { return nil }
        
        guard let group = dict["group"] as? String else { return nil }
        guard let groupName = dict["groupName"] as? String else { return nil }
        guard let channel = dict["channel"] as? String else { return nil }
        
        guard let channelName = dict["channelName"] as? String else {
            return nil
        }
        guard let message = dict["message"] as? [String: Any] else {
            return nil
        }
        guard let type = dict["type"] as? [String] else {
            return nil
        }
        
        guard let timestamp = dict["timestamp"] as? String else {
            return nil
        }
    
        guard let isChat = dict["isChat"] as? Bool else {
            return nil
        }
        
        self.id = id
        self.group = group
        self.groupName = groupName
        self.channel = channel
        self.channelName = channelName
        self.message = HwMessage(dict: message) ?? HwMessage(content: "No Message", sender: "phoneNumber")
        self.type = type.map({UpdateType(rawValue: $0) ?? UpdateType.all})
        self.timestamp = ISO8601DateFormatter().date(from: timestamp) ?? Date()
        self.isChat = isChat
    }
}
