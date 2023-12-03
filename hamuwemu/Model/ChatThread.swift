//
//  ChatThread.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/29/21.
//

import Foundation

class ChatThread: ObservableObject {
    var threadUid: String
    var title: String
    let channel: String
    let group: String
    let timestamp = Date()
    var message: ChatMessage? = nil
    var isActive: Bool = true
    var isTemp = false
    // uid of the first message from channel. It is null if thread wasn't created from an existing message
    let channelMessage: ChatMessage?
    
    init?(dict: [String: Any]) {
        guard let uid = dict["uid"] as? String else { return nil }
        guard let title = dict["title"] as? String else { return nil }
        guard let group = dict["group"] as? String else { return nil }
        guard let channel = dict["channel"] as? String else { return nil }
        guard let message = dict["message"] as? [String: Any]? else { return nil }
        guard let channelMessage = dict["channelMessage"] as? [String: Any]? else { return nil }
        
        threadUid = uid
        self.title = title
        self.group = group
        self.channel = channel
        self.message =  message != nil ? ChatMessage(dict: message!) : nil
        self.channelMessage = channelMessage != nil ? ChatMessage(dict: channelMessage!) : nil
    }
    
    init(title: String, threadUid: String, channel: String, group: String, channelMessage: ChatMessage?, isTemp: Bool) {
        self.title = title
        self.threadUid = threadUid
        self.channel = channel
        self.group = group
        self.channelMessage = channelMessage
        self.isTemp = isTemp
    }
    
    // New thread
    convenience init(title: String, group: String, channel: String, channelMessage: ChatMessage?) {
        let key = PushIdGenerator.shared.generatePushID()
        self.init(title: title, threadUid: key, channel: channel, group: group, channelMessage: channelMessage, isTemp: true)
    }
    
    //Preview
    convenience init() {
        self.init(title: "Preview Thread", threadUid: UUID().uuidString, channel: UUID().uuidString, group: UUID().uuidString, channelMessage: nil, isTemp: true)
    }
}
