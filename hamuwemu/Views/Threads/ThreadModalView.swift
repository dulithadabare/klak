//
//  ThreadModalView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/7/21.
//

import SwiftUI

struct ThreadModalView: View {
//    @Environment(\.presentationMode) var presentationMode
    @State private var firstName: String = ""
    @Binding var selectedThreadItem: ThreadItem?
    @ObservedObject var model: Model
//    @State private var showThreadView = false
    
    var body: some View {
        if model.thread.channelMessage != nil {
            ReplyThreadView(selectedThreadItem: $selectedThreadItem, thread: model.thread, chat: model.chat, channel: model.channel, contactRepository: model.contactRepository)
        } else {
            AddThreadWithNameView(selectedThreadItem: $selectedThreadItem, thread: model.thread, chat: model.chat, channel: model.channel, contactRepository: model.contactRepository)
        }
    }
}

//struct ThreadModalView_Previews: PreviewProvider {
//    static var previews: some View {
//        ThreadModalView(item: ThreadItem(), chat: ChatGroup(groupName: "Preview Group"), channel: ChatChannel(), contactRepository: ContactRepository())
//    }
//}

extension ThreadModalView {
    class Model: ObservableObject {
        var chat: ChatGroup
        var channel: ChatChannel
        var thread: ChatThread
        var item: ThreadItem
        var contactRepository: ContactRepository
        
        init(chat: ChatGroup,  channel: ChatChannel, item: ThreadItem, contactRepository: ContactRepository) {
            self.chat = chat
            self.channel = channel
            self.item = item
            self.contactRepository = contactRepository
            self.thread = ChatThread(title: item.title, group: chat.group, channel: channel.channelUid, channelMessage: item.message)
        }
    }
}
