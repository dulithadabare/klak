//
//  SendImageInputBarView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-17.
//

import SwiftUI
import InputBarAccessoryView
import CoreData
import PromiseKit

struct SendImageInputBarView: UIViewRepresentable {
    var chat: ChatGroup
    
    @Binding
    var size: CGSize
    var onSend: (HwMessage) -> Void
    
    @EnvironmentObject
    private var contactRepository: ContactRepository
    @EnvironmentObject
    private var authenticationService: AuthenticationService
    @EnvironmentObject
    private var persistenceController: PersistenceController
   

    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> InputBarAccessoryView {
        let bar = SendImageInputBar()
//        bar.setContentHuggingPriority(.required, for: .vertical)
//        bar.setContentHuggingPriority(.defaultHigh, for: .vertical)
        bar.delegate = context.coordinator
        bar.sendButton.isEnabled = true
        
        DispatchQueue.main.async {
            bar.inputTextView.placeholderLabel.text = "Type Caption"
        }
        return bar
    }
    
    func updateUIView(_ uiView: InputBarAccessoryView, context: Context) {
//        print("ChannelInputBarView: updating view \(replyMessage?.id ?? "nil")")
        
        context.coordinator.control = self
    }
    
    func onSendPerform(_ message: HwMessage) {
        onSend(message)
    }
    
    func sendMessage(_ message: HwMessage){
        let isTempChatGroup = chat.isTemp
        let chatMessageId = PushIdGenerator.shared.generatePushID()
        let channelUid = chat.defaultChannel.channelUid
        
        // Api
        func handleError(_ error: Error) {
            print("ChannelMessagesView Error: \(error.localizedDescription)")
        }
        
        if isTempChatGroup {
            let addGroupModel = AddGroupModel(author: authenticationService.account.userId!, group: chat.group, groupName: chat.groupName, isChat: true, defaultChannel: AddChannelModel(channelUid: chat.defaultChannel.channelUid, title: chat.defaultChannel.title, group: chat.defaultChannel.group), members: chat.members)
            _ = persistenceController.insertGroup(addGroupModel)
            chat.isTemp = false
            authenticationService.account.addGroup(chat) { _, error in
                if let error = error {
                    print("ChannelMessagesView Error: \(error)")
                }
            }
        }
        
        
        // Core Data
        let addMessageModel = AddMessageModel(id: chatMessageId, author: authenticationService.account.userId!, sender: authenticationService.account.phoneNumber!, timestamp: Date(), channel: channelUid, group: chat.group, message: message, thread: nil, replyingInThreadTo: nil, senderPublicKey: authenticationService.account.getPublicKey()!.base64EncodedString(), isOutgoingMessage: true)
        _ = persistenceController.insertMessage(addMessageModel)
    }
    
    
    class Coordinator {
        
        var control: SendImageInputBarView
        
        init(_ control: SendImageInputBarView) {
            self.control = control
        }
    }
}

extension SendImageInputBarView.Coordinator: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) {
        print("ChannelInputBar: Coordinator size changed \(size)")
        control.size = size
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let message = getMessage(from: inputBar.inputTextView.attributedText!, with: text)
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
        control.onSendPerform(message)
        inputBar.inputTextView.text = ""
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
        if text.isEmpty {
            inputBar.sendButton.isEnabled = true
        }
    }
}

struct SendImageInputBarView_Previews: PreviewProvider {
    static var previews: some View {
        SendImageInputBarView(chat: ChatGroup.preview, size: .constant(.zero), onSend: {_ in })
            .frame(width: .infinity, height: 40)
            .environmentObject(ContactRepository.preview)
            .environmentObject(AuthenticationService.preview)
    }
}
