//
//  ChatChannel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/30/21.
//

import Foundation

class ChatChannel {
    var channelUid: String
    var title: String
    var group: String
    var message: ChatMessage? = nil
    var timestamp = Date()
    var isTemp = false
    
    init(channelUid: String, title: String, group: String) {
        self.channelUid = channelUid
        self.title = title
        self.group = group
    }
    
    convenience init(title: String, group: String) {
        let uid = PushIdGenerator.shared.generatePushID()
        self.init(channelUid: uid, title: title, group: group)
        self.isTemp = true
    }
    
    //for previews
    convenience init() {
        self.init(channelUid: UUID().uuidString, title: "Preview Channel", group: UUID().uuidString)
    }
    
    init?(dict: [String: Any]) {
        guard let uid = dict["uid"] as? String else { return nil }
        guard let title = dict["title"] as? String else { return nil }
        guard let group = dict["group"] as? String else { return nil }
        guard let message = dict["message"] as? [String: Any]? else { return nil }
        
        channelUid = uid
        self.title = title
        self.group = group
        self.message =  message != nil ? ChatMessage(dict: message!) : nil
    }
}

extension ChatChannel: DatabaseRepresentation {
    var representation: [String : Any] {
        let rep: [String: Any] = ["uid": channelUid,
                                  "title": title,
                                  "group": group,
        ]
        
        return rep
    }
    
    
}
