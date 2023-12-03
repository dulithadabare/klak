//
//  ThreadView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/29/21.
//

import SwiftUI

import Combine
import FirebaseAuth

struct ThreadView: View {
    @State var size: CGSize = CGSize(width: 0, height: 50)
    @StateObject var model = Model()
    @StateObject var autocompleteDataModel = AutocompleteDataModel()
    @State var showAutocompleteView: Bool = false
    var contactRepository: ContactRepository
    var chat: ChatGroup
    var thread: ChatThread
    var channel: ChatChannel
    
    func onSendPerform(_ message: HwMessage){
        ChatRepository.sendThreadMessage(message: message, thread: thread, channel: channel, chat: chat, replyMessage: model.selectedReplyMessage)
        
        //hide replyview
        if model.selectedReplyMessage != nil {
            model.selectedReplyMessage = nil
        }
    }
    
    var body: some View {
        VStack(spacing: 0){
            ZStack{
                ThreadViewRepresentable(selectedReplyMessage: $model.selectedReplyMessage, thread: thread, chat: chat, channel: channel, contactRepository: contactRepository)
                VStack(spacing: 0){
                    Spacer()
                    if showAutocompleteView {
                        AutocompleteListView(dataModel: autocompleteDataModel)
                    }
                    if model.showReplyView {
                        MessageReplyView(selectedReplyMessage: $model.selectedReplyMessage, message: model.selectedReplyItem!)
                    }
                }
                
            }
            ThreadInputBarView(showAutocompleteView: $showAutocompleteView, size: $size, thread: thread, chat: chat, channel: channel, contactRepository: contactRepository, dataModel: autocompleteDataModel, onSendPerform: { (message) in
                onSendPerform(message)
            })
            .frame(height: size.height)
        }
        .onAppear{
            model.contactRepository = contactRepository
        }
    }
}

//struct ThreadView_Previews: PreviewProvider {
//    static var previews: some View {
//        ThreadView(model: ThreadView.Model(chat: ChatGroup(groupName: "TEST"), channel: ChatChannel(), thread: ChatThread(), contactRepository: ContactRepository()))
//    }
//}

extension ThreadView {
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
