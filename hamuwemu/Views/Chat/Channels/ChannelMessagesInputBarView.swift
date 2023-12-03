//
//  ChannelMessagesInputBarView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-01-19.
//

import SwiftUI
import InputBarAccessoryView
import CoreData
import PromiseKit

struct ChannelMessagesInputBarView: UIViewRepresentable {
    @Binding
    var showAutocompleteView: Bool
    
    @Binding
    var size: CGSize
    
    var chat: ChatGroup
    @EnvironmentObject
    var contactRepository: ContactRepository
    @EnvironmentObject
    var authenticationService: AuthenticationService
    var persistenceController: PersistenceController
    var dataModel: AutocompleteDataModel
    
    @Binding
    var replyItem: ReplyItem?
    @Binding
    var sendMessageInThread: Bool
    @Binding
    var createdThreadId: String?
    @Binding
    var showCreatedThread: Bool
    @Binding
    var showImagePicker: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MessagesInputBar {
        let bar = MessagesInputBar()
//        bar.setContentHuggingPriority(.required, for: .vertical)
//        bar.setContentHuggingPriority(.defaultHigh, for: .vertical)
        bar.delegate = context.coordinator
        bar.messagesInputBarDelegate = context.coordinator
        
        DispatchQueue.main.async {
            bar.inputTextView.placeholderLabel.text = String()
        }
        return bar
    }
    
    func updateUIView(_ uiView: MessagesInputBar, context: Context) {
//        print("ChannelInputBarView: updating view \(replyMessage?.id ?? "nil")")
        context.coordinator.control = self
    }
    
    func onSendPerform(_ message: HwMessage) {
        sendMessage(message, withReplyTo: replyItem, sendInNewThread: sendMessageInThread)
        
        //hide replyview
        if replyItem != nil {
            replyItem = nil
        }
    }
    
    func sendMessage(_ message: HwMessage, withReplyTo replyItem: ReplyItem?, sendInNewThread: Bool = false){
        let isTempChatGroup = chat.isTemp
        let chatMessageId = PushIdGenerator.shared.generatePushID()
        var threadUid: String?
        var channelUid: String?
        
        // Api
        func handleError(_ error: Error) {
            print("ChannelMessagesView Error: \(error.localizedDescription)")
        }
        
        if isTempChatGroup {
            authenticationService.account.addGroup(chat) { _, error in
                if let error = error {
                    print("ChannelMessagesView Error: \(error)")
                }
            }
        }
        
        if let replyItem = replyItem, replyItem.isThreadReply {
            threadUid = PushIdGenerator.shared.generatePushID()
            authenticationService.account.addThreadInReply(threadUid: threadUid!, group: chat.group, replyingTo: replyItem.item, members: chat.members){ _, error in
                if let error = error {
                    print("ChannelMessagesView Error: \(error)")
                }
            }
        } else if sendInNewThread {
            threadUid = PushIdGenerator.shared.generatePushID()
            authenticationService.account.addThreadWithMessage(threadUid: threadUid!, group: chat.group, message: message, members: chat.members){ _, error in
                if let error = error {
                    print("ChannelMessagesView Error: \(error)")
                }
            }
        } else {
            channelUid = chat.defaultChannel.channelUid
        }
        
        // Core Data
        persistInCoreData(channelUid: channelUid, threadUid: threadUid, chatMessageId: chatMessageId, message: message, withReplyTo: replyItem, sendInNewThread: sendInNewThread)
        
        
//        let receiver = chat.groupName
//        
//        authenticationService.account.sendMessage(message, messageId: chatMessageId, group: chat.group, channel: channelUid, thread: threadUid, replyingTo: replyItem?.item.messageId, receiver: receiver){ _, error in
//            if let error = error {
//                print("ChannelMessagesView Error: \(error)")
//            }
//        }
    }
    
    func persistInCoreData(channelUid: String?, threadUid: String?, chatMessageId: String, message: HwMessage, withReplyTo replyItem: ReplyItem?, sendInNewThread: Bool = false) {
        
        
        // Core Data
        if chat.isTemp {
            insertGroup(chat: chat, message: message, messageId: chatMessageId)
            chat.isTemp = false
        }
        
        if let replyItem = replyItem, replyItem.isThreadReply {
            insertThread(with: message, replyingTo: replyItem.item, group: chat.group, thread: threadUid!, chatMessageId: chatMessageId, members: chat.members)
        } else if sendInNewThread {
            firstly {
                insertThread(with: message, replyingTo: nil, group: chat.group, thread: threadUid!, chatMessageId: chatMessageId, members: chat.members)
            } .done { _ in
                createdThreadId = threadUid
                showCreatedThread = true
            } .catch { error in
                print("ChannelMessagesView: Error while saving thread \(error)")
            }
        }
        
        insertMessage(message, withReplyTo: replyItem?.item, chatMessageId: chatMessageId, channel: channelUid, thread: threadUid)
        
        //Update group list only if message is sent in channel
        if let _ = channelUid {
            updateListItem(with: message, group: chat.group, messageId: chatMessageId)
        }
    }
    
    func insertMessage(_ message: HwMessage, withReplyTo replyToItem: HwChatMessage?, chatMessageId: String, channel: String?, thread: String?){
        let userId = authenticationService.userId!
        let phoneNumber = authenticationService.phoneNumber!
        let messageText = HwChatListItem.getAttributedString(from: message)
        let replyingToObjectId = replyToItem?.objectID
        let groupId = chat.group
        
        persistenceController.enqueue { context in
            let item = HwChatMessage(context: context)
            
            item.author = userId
            item.sender = phoneNumber
            item.groupUid = groupId
            item.channelUid = channel
            item.threadUid = thread
            item.isSystemMessage = false
            item.messageId = chatMessageId
            item.timestamp = Date()
            item.text = messageText
            item.isReadByMe = true
            item.statusRawValue = MessageStatus.none.rawValue
            
            if let replyingToObjectId = replyingToObjectId,
               let replyingToMessageItem = try? context.existingObject(with: replyingToObjectId),
            let replyingToMessage = replyingToMessageItem as? HwChatMessage {
                item.replyingTo = replyingToMessage
                replyingToMessage.addToReplies(item)
                replyingToMessage.replyCount += 1
                replyingToMessage.replyingThreadId = thread
            }
        }
    }
    
    func insertThread(with message: HwMessage, replyingTo: HwChatMessage?, group: String, thread: String, chatMessageId: String, members: [String: AppUser]) -> Promise<Void> {
//            let userId = authenticationService.userId!
        let phoneNumber = authenticationService.phoneNumber!
        let messageText = HwChatListItem.getAttributedString(from: message)
        let titleText = replyingTo?.text ?? messageText
        let isReplyingTo = replyingTo != nil
//            let replyingToObjectId = replyingTo.objectID
        
        return persistenceController.enqueue { context in
            //create thread
            let item = HwThreadListItem(context: context)
            let threadItem = HwChatThread(context: context)
            threadItem.threadId = thread
            threadItem.titleText = titleText
            threadItem.groupId = group
            threadItem.isReplyingTo = isReplyingTo
            threadItem.isTemp = false
            threadItem.threadListItem = item
            
            item.thread = threadItem
            item.threadId = thread
            item.groupId = group
            item.lastMessageDate = Date()
            item.lastMessageText = messageText
            item.lastMessageSender = phoneNumber
            item.lastMessageSearchableText = messageText?.string
            item.lastMessageStatusRawValue = 0
            item.unreadCount = 0
            
            //add thread memebers
            for (_, user) in members {
                let member = HwThreadMember(context: context)
                member.threadId = thread
                member.uid = user.uid
                member.phoneNumber = user.phoneNumber
            }
            
            let fetchRequest: NSFetchRequest<HwChatGroup> = HwChatGroup.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatGroup.groupId), group)
            
            if let results = try? context.fetch(fetchRequest),
               let groupItem = results.first {
                groupItem.addToThreads(threadItem)
                threadItem.group = groupItem
            }
        }
    }
    
    func insertGroup(chat: ChatGroup, message: HwMessage, messageId: String){
//            let groupId = self.groupId
//            let groupName = self.groupName
//            let channelId = self.channelName
//            let channelName = self.channelName
//            let isChat = self.isChat
//
        let phoneNumber = authenticationService.phoneNumber!
        let messageText = HwChatListItem.getAttributedString(from: message)
        
        persistenceController.enqueue { context in
            let group = HwChatGroup(context: context)
            group.groupId = chat.group
            group.groupName = chat.groupName
            group.createdAt = Date()
            group.isChat = chat.isChat
            group.isTemp = false
            
            let defaultChannel = HwChatChannel(context: context)
            defaultChannel.channelId = chat.defaultChannel.channelUid
            defaultChannel.channelName = chat.defaultChannel.title
            group.defaultChannel = defaultChannel
            
            let item = HwChatListItem(context: context)
            item.groupId = chat.group
            item.groupName = chat.groupName
            item.channelId = chat.defaultChannel.channelUid
            item.channelName = chat.defaultChannel.title
            item.lastMessageId = messageId
            item.lastMessageDate = Date()
            item.lastMessageSender = phoneNumber
            item.unreadCount = 0
            item.lastMessageText = messageText?.string
            item.lastMessageAttrText = messageText
            item.group = group
            
            for (_, member) in chat.members {
                let groupMember = HwGroupMember(context: context)
                groupMember.uid = member.uid
                groupMember.phoneNumber = member.phoneNumber
                groupMember.groupId = chat.group
            }
        }
        
    }
    
    func updateListItem(with message: HwMessage, group: String, messageId: String){
        let userId = authenticationService.userId!
        let phoneNumber = authenticationService.phoneNumber!
        let messageText = HwChatListItem.getAttributedString(from: message)
        persistenceController.enqueue { context in
            let fetchRequest: NSFetchRequest<HwChatListItem> = HwChatListItem.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatListItem.groupId), group)
            
            if let results = try? context.fetch(fetchRequest),
               let listItem = results.first {
                listItem.lastMessageText =  messageText?.string
                listItem.lastMessageSender = phoneNumber
                listItem.lastMessageId = messageId
                listItem.lastMessageDate = Date()
                listItem.lastMessageAttrText = messageText
                listItem.lastMessageAuthorUid = userId
                listItem.lastMessageStatusRawValue = MessageStatus.none.rawValue
                listItem.threadId = nil
            }
        }
    }
    
    class Coordinator {
        
        var control: ChannelMessagesInputBarView
        
        init(_ control: ChannelMessagesInputBarView) {
            self.control = control
        }
    }
}

extension ChannelMessagesInputBarView.Coordinator: InputBarAccessoryViewDelegate {
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
}

extension ChannelMessagesInputBarView.Coordinator: MessagesInputBarViewDelegate {
    func showImagePicker() {
        control.showImagePicker = true
    }
    
    func sendModeChanged(_ value: Bool) {
        control.sendMessageInThread = value
    }
    
    func showAutocompleteView(_ value: Bool) {
        control.showAutocompleteView = value
    }
}

struct ChannelMessagesInputBarView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelMessagesInputBarView(showAutocompleteView: .constant(false), size: .constant(.zero), chat: ChatGroup(groupName: "Chat Group"), persistenceController: PersistenceController.preview, dataModel: AutocompleteDataModel(), replyItem: .constant(nil), sendMessageInThread: .constant(true), createdThreadId: .constant(nil), showCreatedThread: .constant(false), showImagePicker: .constant(false))
            .frame(width: .infinity, height: 40)
            .environmentObject(ContactRepository.preview)
            .environmentObject(AuthenticationService.preview)
    }
}
