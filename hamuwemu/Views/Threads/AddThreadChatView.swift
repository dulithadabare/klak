//
//  AddThreadView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/15/21.
//

import SwiftUI

import Combine

struct AddThreadChatView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var size: CGSize = CGSize(width: 0, height: 50)
    @StateObject var model = Model()
    @StateObject var autocompleteDataModel = AutocompleteDataModel()
    @State var showAutocompleteView: Bool = false
    @Binding var selectedThreadItem: ThreadItem?
    var thread: ChatThread
    var chat: ChatGroup
    var channel: ChatChannel
    var contactRepository: ContactRepository
    var onDismiss: () -> ()
    
    func onSendPerform(_ message: HwMessage){
        //In existing chat group, existing channel (default)
        if !chat.isTemp, !channel.isTemp {
            
            ChatRepository.addThread(thread, channel: channel, chat: chat)
            ChatRepository.sendThreadMessage(message: message, thread: thread, channel: channel, chat: chat, replyMessage: model.selectedReplyMessage)
        }
        //In a new chat group, new & unsaved channel (default), new thread
        else {
            
            ChatRepository.addGroup(chat)
            ChatRepository.addChannel(channel)
            ChatRepository.addThread(thread, channel: channel, chat: chat)
            ChatRepository.sendThreadMessage(message: message, thread: thread, channel: channel, chat: chat, replyMessage: model.selectedReplyMessage)
        }
        
        if thread.isTemp {
            thread.isTemp = false
        }
        
        //hide replyview
        if model.selectedReplyMessage != nil {
            model.selectedReplyMessage = nil
        }
        selectedThreadItem = ThreadItem(threadUid: thread.threadUid, title: thread.title, channel: thread.channel, group: thread.group, message: thread.channelMessage)
        onDismiss()
    }
    
    var body: some View {
        VStack(spacing: 0){
            ZStack{
                AddThreadViewRepresentable(thread: thread, chat: chat, channel: channel, contactRepository:contactRepository)
                VStack(spacing: 0){
                    Spacer()
                    if showAutocompleteView {
                        AutocompleteListView(dataModel: autocompleteDataModel)
                    }
                }
                
            }
            ThreadInputBarView(showAutocompleteView: $showAutocompleteView, size: $size, thread: thread, chat: chat, channel: channel, contactRepository: contactRepository, dataModel: autocompleteDataModel, onSendPerform: { (message) in
                onSendPerform(message)
            })
            .frame(height: size.height)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                        onDismiss()
                }) {
                    Text("Cancel")
                }
            }
        }
        .onAppear{
            model.contactRepository = contactRepository
        }
        
    }
}

//struct AddThreadView_Previews: PreviewProvider {
//    static var previews: some View {
//        AddThreadView(thread: ChatThread(), chat: ChatGroup(groupName: "Preview Group"), channel: ChatChannel(), contactRepository: ContactRepository())
//    }
//}

extension AddThreadChatView {
    class Model: ObservableObject {
        @Published var selectedReplyMessage: ChatMessage?
        @Published var showReplyView: Bool = false
        var selectedReplyItem: MessageReplyItem?
        var contactRepository : ContactRepository?
        
        private var cancellables: Set<AnyCancellable> = []
        
        init(){
            addSubscribers()
        }
        
        func addSubscribers(){
            $selectedReplyMessage
//                .compactMap{$0}
                .sink { (message) in
                    if let message = message, let contactRepository = self.contactRepository {
                        self.showReplyView = true
                        let senderFullName = contactRepository.getFullName(for: message.sender) ?? message.sender
                        let content = attributedString(with: message.message, contactRepository: contactRepository).string
                        self.selectedReplyItem = MessageReplyItem(senderName: senderFullName, content: content, chatMessage: message)
                    } else {
                        self.showReplyView = false
                    }
                    
                }
                .store(in: &cancellables)
        }
    }
}
