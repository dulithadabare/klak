//
//  ThreadDetailView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/29/21.
//

import SwiftUI

import Combine

struct ThreadDetailView: View {
    @ObservedObject var model: Model
    
    var body: some View {
        VStack {
            ThreadView(contactRepository: model.contactRepository, chat: model.chat, thread: model.thread, channel: model.channel)
        }
        .navigationTitle(model.thread.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ThreadDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadDetailView(model: ThreadDetailView.Model(chat: ChatGroup(groupName: "TEST"), channel: ChatChannel(), thread: ChatThread(), contactRepository: ContactRepository.preview))
        
//        thread: .constant(ChatThread(title: "TEST")
    }
}

extension ThreadDetailView {
    class Model: ObservableObject {
        var contactRepository: ContactRepository
        var chat: ChatGroup
        var thread: ChatThread
        var channel: ChatChannel
        
        init(chat: ChatGroup, channel: ChatChannel, thread: ChatThread, contactRepository: ContactRepository){
            self.contactRepository =  contactRepository
            self.chat =      chat
            self.thread =      thread
            self.channel =      channel
        }
    }
}
