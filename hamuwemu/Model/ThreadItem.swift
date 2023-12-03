//
//  ThreadItem.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/23/21.
//

import Foundation

// Used to pass data from the Message to ThreadDetailView
struct ThreadItem: Identifiable {
    
    var id: String {
        threadUid ?? message?.id ?? UUID().uuidString
    }
    let threadUid: String?
    var title: String
    let channel: String
    let group: String
    let message: ChatMessage?
}

extension ThreadItem {
    // preview
    init(){
        self.threadUid = nil
        self.title = "Preview Thread"
        self.channel = UUID().uuidString
        self.group = UUID().uuidString
        self.message = ChatMessage()
    }
    
    // New thread
    init(title: String, channel: String, group: String){
        self.threadUid = nil
        self.title = title
        self.message = nil
        self.channel = channel
        self.group = group
    }
    
    // New thread in reply to a message
    init(title: String, message: ChatMessage, channel: String, group: String){
        self.threadUid = nil
        self.title = title
        self.message = message
        self.channel = channel
        self.group = group
    }
}

extension ThreadItem: Equatable {
    static func == (lhs: ThreadItem, rhs: ThreadItem) -> Bool {
        return lhs.id == rhs.id
    }
}
