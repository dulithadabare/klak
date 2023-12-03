//
//  ThreadMessagesInputBarView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-24.
//

import SwiftUI
import InputBarAccessoryView
import CoreData

struct ThreadMessagesInputBarView: UIViewRepresentable {
    @EnvironmentObject
    var contactRepository: ContactRepository
    @EnvironmentObject
    var authenticationService: AuthenticationService
    
    @Binding
    var showAutocompleteView: Bool
    @Binding
    var size: CGSize
    @Binding
    var members: [AppUser]
    var chat: ChatGroup
    var thread: ChatThreadModel
    var persistenceController: PersistenceController
    var dataModel: AutocompleteDataModel
    @Binding
    var replyItem: ReplyItem?
    @Binding public var isFirstResponder: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> ThreadMessagesInputBar {
        let bar = ThreadMessagesInputBar(contactRepository: contactRepository, dataModel: dataModel)
        bar.delegate = context.coordinator
        bar.channelInputBarDelegate = context.coordinator
        
        DispatchQueue.main.async {
            bar.inputTextView.placeholderLabel.text = String()
        }
        return bar
    }
    
    func updateUIView(_ uiView: ThreadMessagesInputBar, context: Context) {
        context.coordinator.control = self
        if isFirstResponder && !uiView.inputTextView.isFirstResponder {
            uiView.inputTextView.becomeFirstResponder()
        } else if !isFirstResponder && uiView.inputTextView.isFirstResponder {
            uiView.inputTextView.resignFirstResponder()
        }
//        DispatchQueue.main.async {
//            switch isFirstResponder {
//            case true: uiView.inputTextView.becomeFirstResponder()
//            case false: uiView.inputTextView.resignFirstResponder()
//            }
//        }
    }
    
    func onSendPerform(_ message: HwMessage) {
        sendMessage(message, withReplyTo: replyItem, sendInNewThread: false)
        
        //hide replyview
        if replyItem != nil {
            replyItem = nil
        }
    }
    
    func sendMessage(_ message: HwMessage, withReplyTo replyItem: ReplyItem?, sendInNewThread: Bool = false){
        let isTempChatGroup = chat.isTemp
        let isTempThread = thread.isTemp

        let chatMessageId = PushIdGenerator.shared.generatePushID()
        
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
        
        if isTempThread {
            var members = thread.members
            if thread.members.isEmpty, let threadMembers = loadGroupMembers(chat.group) {
                members = threadMembers
            }
            
            let model = AddThreadModel(author: authenticationService.account.userId!, threadUid: thread.threadUid, group: thread.group, title: getMessage(from: thread.title), replyingTo: nil, members: members)
            
            _ = persistenceController.insertThread(model)
            thread.isTemp = false
            
            authenticationService.account.addThread(threadUid: thread.threadUid, group: thread.group, title: thread.title, replyingTo: nil, members: members) { _, error in
                if let error = error {
                    print("ChannelMessagesView Error: \(error)")
                }
            }
        }
        
        
        // Core Data
        let addMessageModel = AddMessageModel(id: chatMessageId, author: authenticationService.account.userId!, sender: authenticationService.account.phoneNumber!, timestamp: Date(), channel: nil, group: chat.group, message: message, thread: nil, replyingInThreadTo: nil, senderPublicKey: authenticationService.account.getPublicKey()!.base64EncodedString(), isOutgoingMessage: true)
        _ = persistenceController.insertMessage(addMessageModel)
        
        
        
        
//        let receiver = chat.groupName
//
//        authenticationService.account.sendMessage(message, messageId: chatMessageId, group: thread.group, channel: nil, thread: threadUid, replyingTo: replyItem?.item.messageId, receiver: receiver) { _, error in
//            if let error = error {
//                print("ChannelMessagesView Error: \(error.localizedDescription)")
//            }
//        }
    }
    
    func loadGroupMembers(_ groupId: String) -> [String: AppUser]? {
        let request: NSFetchRequest<HwGroupMember> = HwGroupMember.fetchRequest()
        request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwGroupMember.groupId), groupId)
        request.sortDescriptors = [
            NSSortDescriptor(
                keyPath: \HwGroupMember.uid,
                ascending: false)]
        
        do {
            let results = try persistenceController.container.viewContext.fetch(request)
            var appUserMap: [String: AppUser] = [:]
            for hwItem in results {
                let appUser = AppUser(uid: hwItem.uid!, phoneNumber: hwItem.phoneNumber!)
                appUserMap[hwItem.uid!] = appUser
            }
            
            return appUserMap
        } catch {
            print("Error fetching \(error)")
        }
        
        return nil
    }
    
    func persistInCoreData(_ message: HwMessage, withReplyTo replyItem: ReplyItem?, sendInNewThread: Bool = false) -> (messageId: String, threadUid: String?) {
        let chatMessageId = PushIdGenerator.shared.generatePushID()
        
        if chat.isTemp {
            insertGroup(chat: chat)
            chat.isTemp = false
        }
        
        if thread.isTemp {
            insertThread(with: thread.title, replyingTo: nil, group: thread.group, thread: thread.threadUid, chatMessageId: chatMessageId, members: thread.members)
            thread.isTemp = false
        }
        
        insertMessage(message, chatMessageId: chatMessageId)
        
        return (chatMessageId, thread.threadUid)
    }
    
    func insertMessage(_ message: HwMessage, chatMessageId: String){
        let userId = authenticationService.userId!
        let phoneNumber = authenticationService.phoneNumber!
        let messageText = HwChatListItem.getAttributedString(from: message)
        let groupId = thread.group
        let threadUid = thread.threadUid
        let replyingTo = thread.replyingTo
        
        persistenceController.enqueue { context in
            let item = HwChatMessage(context: context)
            
            item.author = userId
            item.sender = phoneNumber
            item.groupUid = groupId
            item.threadUid = threadUid
            item.isSystemMessage = false
            item.messageId = chatMessageId
            item.timestamp = Date()
            item.text = messageText
            item.isReadByMe = true
            item.statusRawValue = MessageStatus.none.rawValue
            
            if let replyingTo =  replyingTo{
                let fetchRequest: NSFetchRequest<HwChatMessage> = HwChatMessage.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatMessage.messageId), replyingTo)
                if let results = try? context.fetch(fetchRequest),
                   let replyingToMessage = results.first {
                    replyingToMessage.addToReplies(item)
                    replyingToMessage.replyCount += 1
                }
            }
        }
        
        updateListItem(with: message, messageId: chatMessageId)
    }
    
    func insertThread(with title: NSAttributedString, replyingTo: HwChatMessage?, group: String, thread: String, chatMessageId: String, members: [String: AppUser]){
        let userId = authenticationService.account.userId!
        let phoneNumber = authenticationService.phoneNumber!
        let messageText = HwChatListItem.getAttributedString(from: HwMessage(content: "New thread", mentions: [], links: []))
        let isReplyingTo = replyingTo != nil
//            let replyingToObjectId = replyingTo.objectID
        
        persistenceController.enqueue { context in
            //create thread
            let item = HwThreadListItem(context: context)
            let threadItem = HwChatThread(context: context)
            threadItem.threadId = thread
            threadItem.titleText = title
            threadItem.groupId = group
            threadItem.isReplyingTo = isReplyingTo
            threadItem.isTemp = false
            threadItem.threadListItem = item
            
            item.thread = threadItem
            item.threadId = thread
            item.groupId = group
            item.lastMessageId = chatMessageId
            item.lastMessageDate = Date()
            item.lastMessageText = messageText
            item.lastMessageSender = phoneNumber
            item.lastMessageSearchableText = messageText?.string
            item.lastMessageStatusRawValue = 0
            item.unreadCount = 0
            item.lastMessageAuthorUid = userId
            
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
    
    func insertGroup(chat: ChatGroup){
//            let groupId = self.groupId
//            let groupName = self.groupName
//            let channelId = self.channelName
//            let channelName = self.channelName
//            let isChat = self.isChat
//
        let phoneNumber = authenticationService.phoneNumber!
        
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
            item.unreadCount = 0
            item.group = group
            
            for (_, member) in chat.members {
                let groupMember = HwGroupMember(context: context)
                groupMember.uid = member.uid
                groupMember.phoneNumber = member.phoneNumber
                groupMember.groupId = chat.group
            }
        }
        
    }
    
    func updateListItem(with message: HwMessage, messageId: String){
        let userId = authenticationService.userId!
        let phoneNumber = authenticationService.phoneNumber!
        let messageText = HwChatListItem.getAttributedString(from: message)
        persistenceController.enqueue { context in
            let fetchRequest: NSFetchRequest<HwThreadListItem> = HwThreadListItem.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwThreadListItem.threadId), thread.threadUid)
            
            if let results = try? context.fetch(fetchRequest),
               let listItem = results.first {
                listItem.lastMessageId = messageId
                listItem.lastMessageAuthorUid = userId
                listItem.lastMessageText =  messageText
                listItem.lastMessageSender = phoneNumber
                listItem.lastMessageDate = Date()
                listItem.lastMessageStatusRawValue = MessageStatus.none.rawValue
            }
            
            let request: NSFetchRequest<HwChatListItem> = HwChatListItem.fetchRequest()
            request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatListItem.groupId), chat.group)
            
            if let results = try? context.fetch(request),
               let listItem = results.first {
                listItem.lastMessageText =  messageText?.string
                listItem.lastMessageSender = phoneNumber
                listItem.lastMessageId = messageId
                listItem.lastMessageDate = Date()
                listItem.lastMessageAttrText = messageText
                listItem.lastMessageAuthorUid = userId
                listItem.lastMessageStatusRawValue = MessageStatus.none.rawValue
                listItem.threadId = thread.threadUid
                listItem.unreadCount += 1
            }
        }
    }
    
    class Coordinator: NSObject {
        
        var control: ThreadMessagesInputBarView
        
        init(_ control: ThreadMessagesInputBarView) {
            self.control = control
            super.init()
        }
    }
}

extension ThreadMessagesInputBarView.Coordinator: InputBarAccessoryViewDelegate {
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

extension ThreadMessagesInputBarView.Coordinator: MessagesInputBarViewDelegate {
    func showImagePicker() {
//        control.showImagePicker = true
    }
    
    func sendModeChanged(_ value: Bool) {
        print("Send Mode Changed")
    }
    
    func showAutocompleteView(_ value: Bool) {
        control.showAutocompleteView = value
    }
}

extension ThreadMessagesInputBarView.Coordinator: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        print("textViewDidBeginEditing")
//        control.isFirstResponder = true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        print("textViewDidEndEditing")
    }

}

//struct ThreadMessagesInputBarView_Previews: PreviewProvider {
//    static var previews: some View {
//        ThreadMessagesInputBarView()
//    }
//}
