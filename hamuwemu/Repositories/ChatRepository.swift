//
//  ChatRepository.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/15/21.
//

import Foundation
import Combine

import PromiseKit
import PMKFoundation

import FirebaseDatabase
import FirebaseAuth

class NetworkListenerQueue {
    
    typealias Task = () -> ()
    var tasks: [Task] = []
    
    static let shared = NetworkListenerQueue()
    
    private init() { }
    
    func perform() {
        for (i, task) in tasks.enumerated() {
            task()
            self.tasks.remove(at: i)
        }
    }
}

class ChatRepository {
    private static var ref = Database.root
    private var refHandle: DatabaseHandle?
    private var remoteRefHandle: DatabaseHandle?
    private let path = DatabaseHelper.pathUserChats
    private static let authenticationService: AuthenticationService = .shared
//    static let baseURLString = "https://api.hamuwemu.app/"
//    static let baseURLString = "http://localhost:8080/"
    static let encoder = JSONEncoder()
    private var cancellables: Set<AnyCancellable> = []

    static func addGroup( _ chat: ChatGroup) -> String? {
        guard let userID = authenticationService.user?.uid,
              let phoneNumber = authenticationService.user?.phoneNumber else { return nil }
        
        // add author
        var members = ["\(phoneNumber)": [
            "uid": userID,
            "phoneNumber": phoneNumber,
        ],
        ]
        
        for (_, contact) in chat.members {
            members["\(contact.phoneNumber)"] = [
                "uid": contact.uid,
                "phoneNumber": contact.phoneNumber,
            ]
        }
        
        let group: [String: Any] = ["uid": chat.group,
                                    "author": phoneNumber,
                                    "members": members,
                                    "isChat": chat.isChat,
                                    "defaultChannel": chat.defaultChannel.representation,
        ]
        ref.child(DatabaseHelper.pathGroups).child(chat.group).setValue(group)
        
        //Update local UI
        let uiRep: [String: Any] = [
            "sender": phoneNumber,
            "group": chat.group,
            "timestamp": Date().description,
            "isChat": chat.isChat,
            "groupName": chat.groupName,
            "defaultChannel": chat.defaultChannel.representation,
        ]

        ref.child(DatabaseHelper.pathUserChats).child(userID).child(chat.group).setValue(uiRep)
        
        // Update local ChatIds
        if chat.isChat,
           let contact = chat.members.values.first(where: {$0.phoneNumber != phoneNumber }) {
            ref.child(DatabaseHelper.pathUserChatIDs).child(userID)
                .child(contact.phoneNumber)
                .setValue(chat.group)
        }
        
        return chat.group
    }
    
    static func addThread(_ thread: ChatThread, channel: ChatChannel, chat: ChatGroup) {
        addThread(thread)
        if let firstMessage = thread.channelMessage {
            ChatRepository.updateThreadFirstMessage(messageUid: firstMessage.id, channel: channel, thread: thread)
            _ = ChatRepository.sendMessage(message: firstMessage.message, channel: channel.channelUid, channelName: channel.title, group: chat.group, groupName: chat.groupName, isChat: chat.isChat, thread: thread.threadUid, threadName: thread.title, isThreadOnly: false)
        }
        
        sendThreadCreatedSystemMessage(channel: thread.channel, channelName: channel.title  , group: thread.group, groupName: chat.groupName, isChat: false)
    }
    
    private static func addThread(_ thread: ChatThread) {
        guard let userId = authenticationService.user?.uid else {return}
        // Create channels
        
        var rep: [String: Any] = ["uid": thread.threadUid,
                                  "title": thread.title,
                                  "channel": thread.channel,
                                  "group": thread.group,
        ]
        
        if let channelMessage = thread.channelMessage {
            rep["channelMessage"] = channelMessage.representation
        }
        
        ref.child(DatabaseHelper.pathThreads).child(thread.channel).child(thread.threadUid).setValue(rep)
        
        //Update local ui
        var uiRep: [String: Any] = ["uid": thread.threadUid,
                                    "title": thread.title,
                                  "timestamp": Date().description,
                                  "channel": thread.channel,
                                  "group": thread.group
        ]
        
        if let channelMessage = thread.channelMessage {
            uiRep["channelMessage"] = channelMessage.representation
        }
        
        ref.child(DatabaseHelper.pathUserThreads).child(userId).child(thread.group).child(thread.threadUid).setValue(uiRep)
    }
    
    static func addChannel(_ channel: ChatChannel){
        // Create channel
        
        let rep: [String: Any] = ["uid": channel.channelUid,
                                  "title": channel.title,
                                  "group": channel.group,
        ]
        ref.child(DatabaseHelper.pathChannels).child(channel.channelUid).setValue(rep)
        
        //Update local ui
        guard let userId = authenticationService.user?.uid else {return}
        
        let channelsUiRep: [String: Any] = ["uid": channel.channelUid,
                                            "title": channel.title,
                                  "timestamp": Date().description,
                                  "group": channel.group
        ]
        
        ref.child(DatabaseHelper.pathUserChannels).child(userId).child(channel.group).child(channel.channelUid).setValue(channelsUiRep)
    }
    
//    static func addChat(_ chat: ChatGroup) -> (group: String, channel: String)? {
//        guard let group = addGroup(chat),
//              let channel = addChannel("General", for: group ) else { return nil }
//
//        // add groupId to contacts
//        if chat.isChat, let contact = chat.members.first, let userID = authenticationService.user?.uid {
//            ref.child(DatabaseHelper.pathUserChatIDs).child(userID)
//                .child(contact.phoneNumber)
//                .setValue(group)
//        }
//
//        return (group, channel)
//    }
    
    static func sendThreadMessage(message: HwMessage, thread: ChatThread, channel: ChatChannel, chat: ChatGroup, replyMessage: ChatMessage?) {
        
        let chatMessage = sendMessage(message: message, channel: channel.channelUid, channelName: channel.title, group: chat.group, groupName: chat.groupName, isChat: chat.isChat, thread: thread.threadUid, threadName: thread.title, isThreadOnly: false, replyMessage: replyMessage)
        
        if let chatMessage = chatMessage, let channelMessage = thread.channelMessage {
            updateLatestReply(for: channelMessage, latestReply: chatMessage)
            updateReplyCount(for: channelMessage.id, channelUid: channel.channelUid)
            
        }
    }
    
    static func sendMessage(message: HwMessage, channel: String, channelName: String, group: String, groupName: String, isChat: Bool, replyMessage: ChatMessage? = nil) {
        guard let userId = authenticationService.userId,
              let phoneNumber = authenticationService.phoneNumber,
              let key = ref.child(DatabaseHelper.pathChannelMessages).childByAutoId().key else { return }
        
        let chatMessage = ChatMessage(id: key, message: message, author: userId, sender: phoneNumber, channel: channel, channelName: channelName, group: group, groupName: groupName, isChat: isChat, replyMessage: replyMessage)
        
        ref.child(DatabaseHelper.pathChannelMessages).child(key).setValue(chatMessage.representation)
        
        //TODO Update local chats, channels and threads
        ref.child(DatabaseHelper.pathUserChannelMessages).child(userId).child(channel).child(key).setValue(chatMessage.representation)
        
    }
    
//    static func sendMessageAsync(message: ChatMessage, completion: @escaping (Result<Int, Error>) -> Void) {
//        guard let userId = authenticationService.userId else {
//            completion(.failure(AuthError.userIdNil))
//            return
//        }
//
//        guard let uploadData = try? encoder.encode(message) else {
//            completion(.failure(ApiError.jsonEncodeError))
//            return
//        }
//
//        let urlComponents = URLComponents(
//          string: baseURLString + "groups/")!
//        var request = URLRequest(url: urlComponents.url!)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue(userId, forHTTPHeaderField: "User-Id")
//
//        let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
//            let result: Result<Int, Error>
//            if let error = error {
//                print ("error: \(error)")
//                completion(.failure(error))
//                return
//            }
//            guard let response = response as? HTTPURLResponse,
//                (200...299).contains(response.statusCode) else {
//                print ("server error")
//                    completion(.failure(ApiError.serverError))
//                return
//            }
//            if let mimeType = response.mimeType,
//                mimeType == "application/json",
//                let data = data,
//                let dataString = String(data: data, encoding: .utf8) {
//                print ("got data: \(dataString)")
//                completion(.success(dataString))
//            }
//        }
//        task.resume()
//    }
    
    static func sendMessage(message: HwMessage, channel: String, channelName: String, group: String, groupName: String, isChat: Bool, thread: String, threadName: String, isThreadOnly: Bool, replyMessage: ChatMessage? = nil) -> ChatMessage? {
        guard let userId = authenticationService.userId,
              let phoneNumber = authenticationService.phoneNumber,
              let key = ref.child(DatabaseHelper.pathThreadMessages).childByAutoId().key else { return nil }
        
        let chatMessage = ChatMessage(id: key, message: message, author: userId, sender: phoneNumber, channel: channel, channelName: channelName, group: group, groupName: groupName, isChat: isChat, thread: thread, threadName: threadName, replyMessage: replyMessage)
        
        ref.child(DatabaseHelper.pathThreadMessages).child(key).setValue(chatMessage.representation)
        
        //TODO Update local chats, channels and threads
        ref.child(DatabaseHelper.pathUserThreadMessages).child(userId).child(thread).child(key).setValue(chatMessage.representation)
        
        return chatMessage
    }
    
    static func sendSystemMessage(message: HwMessage, channel: String, channelName: String, group: String, groupName: String, isChat: Bool, thread: String? = nil, threadName: String? = nil) {
        let messagePath = thread == nil ? DatabaseHelper.pathChannelMessages : DatabaseHelper.pathThreadMessages
        guard let key = ref.child(messagePath).childByAutoId().key else { return }
        
        let chatMessage = ChatMessage(id: key, systemMessage: message, channel: channel, channelName: channelName, group: group, groupName: groupName, isChat: isChat, thread: thread, threadName: threadName)
        
        ref.child(messagePath).child(key).setValue(chatMessage.representation)
        
        //TODO Update local chats, channels and threads
        if let thread = thread {
            ref.child(DatabaseHelper.pathUserThreadMessages).child(authenticationService.userId!).child(thread).child(key).setValue(chatMessage.representation)
        } else {
            ref.child(DatabaseHelper.pathUserChannelMessages).child(authenticationService.userId!).child(channel).child(key).setValue(chatMessage.representation)
        }
    }
    
    static func sendThreadCreatedSystemMessage(channel: String, channelName: String, group: String, groupName: String, isChat: Bool){
        let phoneNumber = authenticationService.phoneNumber!
        let systemMessageText = "\(phoneNumber) created a new thread"
        let newRange = NSMakeRange(0, phoneNumber.count)
        let mention = Mention( range: newRange, uid: authenticationService.userId!, phoneNumber: phoneNumber)
        let mentions = [mention]
        let systemMessage = HwMessage(content: systemMessageText, mentions: mentions, links: [])
        ChatRepository.sendSystemMessage(message: systemMessage, channel: channel, channelName: channelName, group: group, groupName: groupName, isChat: isChat)
    }
    
    static func updateLatestReply(for message: ChatMessage, latestReply: ChatMessage){
        ref.child(DatabaseHelper.pathChannelMessages)
            .child(message.id)
            .child("latestReplyMessage")
            .setValue(latestReply.representation)
        
        //local
        
        ref.child(DatabaseHelper.pathUserChannelMessages)
            .child(authenticationService.userId!)
            .child(message.channel)
            .child(message.id)
            .child("latestReplyMessage")
            .setValue(latestReply.representation)
    }
    
    
    static func updateReplyCount(for messageUid: String, channelUid: String){
        ref.child(DatabaseHelper.pathChannelMessages)
            .child(messageUid)
            .child("replyCount")
            .setValue(ServerValue.increment(1))
        
        //local
        
        ref.child(DatabaseHelper.pathUserChannelMessages)
            .child(authenticationService.userId!)
            .child(channelUid)
            .child(messageUid)
            .child("replyCount")
            .setValue(ServerValue.increment(1))
    }
    
    static func updateThreadFirstMessage(messageUid: String, channel: ChatChannel, thread: ChatThread) {
        var childUpdates = [String: Any]()
        
        let remotePath = "/\(DatabaseHelper.pathChannelMessages)/\(messageUid)"
        
        childUpdates["\(remotePath)/thread"] = thread.threadUid
        childUpdates["\(remotePath)/threadName"] = thread.title
        
        //local
        let localPath = "/\(DatabaseHelper.pathUserChannelMessages)/\(authenticationService.userId!)/\(channel.channelUid)/\(messageUid)"
        
        childUpdates["\(localPath)/thread"] = thread.threadUid
        childUpdates["\(localPath)/threadName"] = thread.title
        
        ref.updateChildValues(childUpdates){
            (error:Error?, ref:DatabaseReference) in
            if let error = error {
                print("Message could not be updated: \(error).")
            } else {
                print("Message updated!")
            }
        }
    }
    
    static func updateMessage(_ messageReceipt: MessageReceipt) {
        ref.child(DatabaseHelper.pathGroups).child(messageReceipt.message.group).child("members").observeSingleEvent(of: .value, with: { snapshot in
            var members = [AppUser]()
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                guard let value = snap.value as? [String: Any] else { return }
                let uid = value["uid"] as? String ?? ""
                let phoneNumber = value["phoneNumber"] as? String ?? ""
                let appUser = AppUser(uid: uid, phoneNumber: phoneNumber)
                members.append(appUser)
            }
            
            let isSent = messageReceipt.isSent
            var isDelivered = false
            var isRead = false
     
            let recepients = members.filter({$0.uid != messageReceipt.message.author})
            
            if recepients.allSatisfy({ (recepient) -> Bool in
                messageReceipt.delivered.contains(where: {$0.uid == recepient.uid})
            }) {
                isDelivered = true
            }
            
            if recepients.contains(where: { (recepient) -> Bool in
                messageReceipt.read.contains(where: {$0.uid == recepient.uid})
            }) {
                isRead = true
            }
            
            var childUpdates = [String: Any]()
            
            let userMessagesPath = "/\(DatabaseHelper.pathUserMessages)/\(messageReceipt.message.author)/\(messageReceipt.message.id)"
            
            childUpdates["\(userMessagesPath)/isSent"] = isSent
            childUpdates["\(userMessagesPath)/isDelivered"] = isDelivered
            childUpdates["\(userMessagesPath)/isRead"] = isRead
            
            //if channel message
            
            if messageReceipt.message.isThreadMessage {
                let path = "/\(DatabaseHelper.pathUserThreadMessages)/\(messageReceipt.message.author)/\(messageReceipt.message.thread!)/\(messageReceipt.message.id)"
                
                childUpdates["\(path)/isSent"] = isSent
                childUpdates["\(path)/isDelivered"] = isDelivered
                childUpdates["\(path)/isRead"] = isRead
                
            } else {
                let path = "/\(DatabaseHelper.pathUserChannelMessages)/\(messageReceipt.message.author)/\(messageReceipt.message.channel)/\(messageReceipt.message.id)"
                
                childUpdates["\(path)/isSent"] = isSent
                childUpdates["\(path)/isDelivered"] = isDelivered
                childUpdates["\(path)/isRead"] = isRead
            }
            
            ref.updateChildValues(childUpdates){
                (error:Error?, ref:DatabaseReference) in
                if let error = error {
                    print("Message: \(messageReceipt.message.id) receipts update failed: \(error).")
                } else {
                    print("Message \(messageReceipt.message.id) receipts updated!")
                }
            }
            
            let transactionBlock = { (currentData: MutableData) -> TransactionResult in
                if var message = currentData.value as? [String: Any],
                   let messageUid = message["id"] as? String {
                  
                  if messageUid == messageReceipt.message.id {
                      message["isSent"] = isSent
                      message["isDelivered"] = isDelivered
                      message["isRead"] = isRead

                      // Set value and report transaction success
                      currentData.value = message

                      return TransactionResult.success(withValue: currentData)
                  } else {
                      return TransactionResult.abort()
                  }
                
                  
                }
                return TransactionResult.success(withValue: currentData)
              }
            
            ref.child(DatabaseHelper.pathUserChats)
                .child(messageReceipt.message.author)
                .child(messageReceipt.message.group)
                .child("message")
                .runTransactionBlock(transactionBlock) { error, committed, snapshot in
              if let error = error {
                print(error.localizedDescription)
              }
            }
            
            if messageReceipt.message.isThreadMessage {
                
                ref.child(DatabaseHelper.pathUserThreads)
                    .child(messageReceipt.message.author)
                    .child(messageReceipt.message.group)
                    .child(messageReceipt.message.thread!)
                    .child("message")
                    .runTransactionBlock(transactionBlock) { error, committed, snapshot in
                  if let error = error {
                    print(error.localizedDescription)
                  }
                }
            } else {
                
                ref.child(DatabaseHelper.pathUserChannels)
                    .child(messageReceipt.message.author)
                    .child(messageReceipt.message.group)
                    .child(messageReceipt.message.channel)
                    .child("message")
                    .runTransactionBlock(transactionBlock) { error, committed, snapshot in
                  if let error = error {
                    print(error.localizedDescription)
                  }
                }
            }

        }) { error in
            print(error.localizedDescription)
        }
    }
    
    static func clear(){
        let children = [DatabaseHelper.pathChannelMessages, DatabaseHelper.pathUserUpdates, DatabaseHelper.pathGroups, DatabaseHelper.pathUserChats, DatabaseHelper.pathUserChatIDs, DatabaseHelper.pathUserChannels, DatabaseHelper.pathChannels, DatabaseHelper.pathThreadMessages, DatabaseHelper.pathThreads, DatabaseHelper.pathUserThreads, DatabaseHelper.pathUserMessages, DatabaseHelper.pathMessageReceipts,
                        DatabaseHelper.pathUserChannelMessages, DatabaseHelper.pathUserThreadMessages]
        
        for child in children {
            ref.child(child).removeValue()
        }
    }
    
    static func updateReadReceipt(for message: ChatMessage, messagePath: String){
        guard let userId = authenticationService.userId,
              let phoneNumber = authenticationService.phoneNumber else {
            return
        }
        let appUser = AppUser(uid: userId, phoneNumber: phoneNumber)
        
        var childUpdates = [String: Any]()
        
        childUpdates["/\(DatabaseHelper.pathMessageReceipts)/\(message.id)/read/\(userId)"] = appUser.representation
        childUpdates["\(messagePath)/isReadByCurrUser"] = true
        childUpdates["/\(DatabaseHelper.pathUserMessages)/\(userId)/\(message.id)/isReadByCurrUser"] = true
        
        ref.updateChildValues(childUpdates){
            (error:Error?, ref:DatabaseReference) in
            if let error = error {
                print("Message: \(message.id) Read receipt update failed: \(error).")
            } else {
                print("Message: \(message.id) Read receipts updated!")
            }
        }
    }
    
    static func updateDeliveredReceipt(for message: ChatMessage){
        guard let userId = authenticationService.userId,
              let phoneNumber = authenticationService.phoneNumber else {
            return
        }
        let appUser = AppUser(uid: userId, phoneNumber: phoneNumber)
        
        var childUpdates = [String: Any]()
        
        childUpdates["/\(DatabaseHelper.pathMessageReceipts)/\(message.id)/delivered/\(userId)"] = appUser.representation
        childUpdates["\(DatabaseHelper.pathUserMessages)/\(userId)/\(message.id)/isDeliveredToCurrUser"] = true
        
        ref.updateChildValues(childUpdates){
            (error:Error?, ref:DatabaseReference) in
            if let error = error {
                print("Message: \(message.id) Read receipt update failed: \(error).")
            } else {
                print("Message: \(message.id) Read receipts updated!")
            }
        }
    }
    
    // MARK: - Remote
    static func createChat(_ members: [AppUser], sender: String, group: String, groupName: String?, isChat: Bool, defaultChannel: [String: Any]) {
        var childUpdates = [String: Any]()
        let chatContact = isChat ? members.first(where: {$0.phoneNumber != sender}) : nil
        
        for appUser in members {
            // if is chat, the group name is the sender
            var groupName = groupName
            if isChat {
                if sender != appUser.phoneNumber  {
                    groupName = sender
                } else if let chatPartner = chatContact {
                    groupName = chatPartner.phoneNumber
                }
            }
            
            guard groupName != nil else {continue}
            
            let rep: [String: Any] = [
                "sender": sender,
                "group": group,
                "timestamp": Date().description,
                "isChat": isChat,
                "groupName": groupName!,
                "defaultChannel": defaultChannel,
            ]

            childUpdates["/\(DatabaseHelper.pathUserChats)/\(appUser.uid)/\(group)"] = rep
        }
        
        ref.updateChildValues(childUpdates){
            (error:Error?, ref:DatabaseReference) in
            if let error = error {
                print("Data could not be saved: \(error).")
            } else {
                print("Data saved successfully!")
            }
        }
        
        // Update ChatIds
        if isChat, let receiver =  chatContact {
            ref.child(DatabaseHelper.pathUserChatIDs).child(receiver.uid)
                .child(sender)
                .setValue(group)
        }
    }
    
    static func updateUserGroups(_ chat: ChatGroup, members: [AppUser]) {
        var childUpdates = [String: Any]()
        
        var membersDict = [String: Any]()
        
        for contact in members {
            membersDict["\(contact.phoneNumber)"] = [
                "uid": contact.uid,
                "phoneNumber": contact.phoneNumber,
            ]
        }
        
        for appUser in members {
            childUpdates["/\(DatabaseHelper.pathUserGroups)/\(appUser.uid)/\(chat.group)/groupName"] = chat.groupName
            childUpdates["/\(DatabaseHelper.pathUserGroups)/\(appUser.uid)/\(chat.group)/members"] = membersDict
        }
        
        ref.updateChildValues(childUpdates){
            (error:Error?, ref:DatabaseReference) in
            if let error = error {
                print("Data could not be saved: \(error).")
            } else {
                print("Data saved successfully!")
            }
        }
    }
    
    static func updateUserChats(_ members: [AppUser], message: ChatMessage) {
        var childUpdates = [String: Any]()
        
        for appUser in members {
            childUpdates["/\(DatabaseHelper.pathUserChats)/\(appUser.uid)/\(message.group)/message"] = message.representation
        }
        
        ref.updateChildValues(childUpdates){
            (error:Error?, ref:DatabaseReference) in
            if let error = error {
                print("Data could not be saved: \(error).")
            } else {
                print("Data saved successfully!")
            }
        }
    }
    
    static func handleChannelMessage(_ chatMessage: ChatMessage) {
        ref.child(DatabaseHelper.pathGroups).child(chatMessage.group).child("members").observeSingleEvent(of: .value, with: { snapshot in
            var members = [AppUser]()
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                guard let value = snap.value as? [String: Any] else { return }
                let uid = value["uid"] as? String ?? ""
                let phoneNumber = value["phoneNumber"] as? String ?? ""
                let appUser = AppUser(uid: uid, phoneNumber: phoneNumber)
                members.append(appUser)
            }
            
            self.updateUserChannelMessages(members, message: chatMessage)
            
            if !chatMessage.isSystemMessage {
                self.updateUserChats(members, message: chatMessage)
                self.updateUserChannels(members, message: chatMessage)
                self.updateUserUpdates(members, message: chatMessage)
                self.updateUserMessages(members, message: chatMessage)
            }
        }) { error in
            print(error.localizedDescription)
        }
    }
    
    static func handleChangeForAllMembers(_ chatMessage: ChatMessage, change: DataEventType) {
        ref.child(DatabaseHelper.pathGroups).child(chatMessage.group).child("members").observeSingleEvent(of: .value, with: { snapshot in
            var members = [AppUser]()
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                guard let value = snap.value as? [String: Any] else { return }
                let uid = value["uid"] as? String ?? ""
                let phoneNumber = value["phoneNumber"] as? String ?? ""
                let appUser = AppUser(uid: uid, phoneNumber: phoneNumber)
                members.append(appUser)
            }
            ChatRepository.updateUserThreadMessages(members, message: chatMessage)
            if !chatMessage.isSystemMessage {
                ChatRepository.updateUserThreads(members, message: chatMessage)
                ChatRepository.updateUserMessages(members, message: chatMessage)
            }
        }) { error in
            print(error.localizedDescription)
        }
    }
    
    
    static func updateChats(_ chatMessage: ChatMessage) {
        ref.child(DatabaseHelper.pathGroups).child(chatMessage.group).child("members").observeSingleEvent(of: .value, with: { snapshot in
            var members = [AppUser]()
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                guard let value = snap.value as? [String: Any] else { return }
                let uid = value["uid"] as? String ?? ""
                let phoneNumber = value["phoneNumber"] as? String ?? ""
                let appUser = AppUser(uid: uid, phoneNumber: phoneNumber)
                members.append(appUser)
            }
            
            self.updateUserChats(members, message: chatMessage)
        }) { error in
            print(error.localizedDescription)
        }
    }
    
    static func createUserGroups(chat: ChatGroup, members: [AppUser], author: String) {
        var childUpdates = [String: Any]()
        
        var membersDict = [String: Any]()
        
        for contact in members {
            membersDict["\(contact.phoneNumber)"] = [
                "uid": contact.uid,
                "phoneNumber": contact.phoneNumber,
            ]
        }
        
        var groupName: String?
        
        if !chat.isChat {
            groupName = chat.groupName
        }
        
        var rep: [String: Any] = ["uid": chat.group,
                                  "author": author,
                                  "defaultChannel": chat.defaultChannel.representation,
                                  "members": membersDict,
                                  "isChat": chat.isChat
        ]
        
        if let groupName = groupName {
            rep["groupName"] = groupName
        }
        
        for appUser in members {
            childUpdates["/\(DatabaseHelper.pathUserGroups)/\(appUser.uid)/\(chat.group)"] = rep
        }
        
        ref.updateChildValues(childUpdates){
            (error:Error?, ref:DatabaseReference) in
            if let error = error {
                print("Data could not be saved: \(error).")
            } else {
                print("Data saved successfully!")
            }
        }
    }
    
    static func createUserChannel(_ members: [AppUser], group: String, channel: String, channelName: String) {
        var childUpdates = [String: Any]()
        
        let rep: [String: Any] = ["uid": channel,
                                  "title": channelName,
                                  "timestamp": Date().description,
                                  "group": group
        ]
        
        for appUser in members {
            childUpdates["/\(DatabaseHelper.pathUserChannels)/\(appUser.uid)/\(group)/\(channel)"] = rep
        }
        
        ref.updateChildValues(childUpdates){
            (error:Error?, ref:DatabaseReference) in
            if let error = error {
                print("Data could not be saved: \(error).")
            } else {
                print("Data saved successfully!")
            }
        }
    }
    
    static func createUserChannel(group: String, channel: String, channelName: String) {

        ref.child(DatabaseHelper.pathGroups).child(group).child("members").observeSingleEvent(of: .value, with: { snapshot in
            var members = [AppUser]()
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                guard let value = snap.value as? [String: Any] else { return }
                let uid = value["uid"] as? String ?? ""
                let phoneNumber = value["phoneNumber"] as? String ?? ""
                let appUser = AppUser(uid: uid, phoneNumber: phoneNumber)
                members.append(appUser)
            }
            
            self.createUserChannel(members, group: group, channel: channel, channelName: channelName)
        }) { error in
            print(error.localizedDescription)
        }
    }
    
    static func updateUserChannels(_ members: [AppUser], message: ChatMessage) {
        var childUpdates = [String: Any]()
        
        for appUser in members {
            childUpdates["/\(DatabaseHelper.pathUserChannels)/\(appUser.uid)/\(message.group)/\(message.channel)/message"] = message.representation
        }
        
        ref.updateChildValues(childUpdates){
            (error:Error?, ref:DatabaseReference) in
            if let error = error {
                print("Data could not be saved: \(error).")
            } else {
                print("Data saved successfully!")
            }
        }
    }
    
    static func updateChannels(_ chatMessage: ChatMessage) {
        ref.child(DatabaseHelper.pathGroups).child(chatMessage.group).child("members").observeSingleEvent(of: .value, with: { snapshot in
            var members = [AppUser]()
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                guard let value = snap.value as? [String: Any] else { return }
                let uid = value["uid"] as? String ?? ""
                let phoneNumber = value["phoneNumber"] as? String ?? ""
                let appUser = AppUser(uid: uid, phoneNumber: phoneNumber)
                members.append(appUser)
            }
            
            self.updateUserChannels(members, message: chatMessage)
        }) { error in
            print(error.localizedDescription)
        }
    }
    
    static func createUserThreads(title: String, uid: String, channel: String, group: String, channelMessage: ChatMessage?) {
        ref.child(DatabaseHelper.pathGroups).child(group).child("members").observeSingleEvent(of: .value, with: { snapshot in
            
            var members = [AppUser]()
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                guard let value = snap.value as? [String: Any] else { return }
                let uid = value["uid"] as? String ?? ""
                let phoneNumber = value["phoneNumber"] as? String ?? ""
                let appUser = AppUser(uid: uid, phoneNumber: phoneNumber)
                members.append(appUser)
            }
            
            var childUpdates = [String: Any]()
            
            for appUser in members {
                
                var rep: [String: Any] = [
                    "title": title,
                    "uid": uid,
                    "channel": channel,
                    "group": group
                ]
                
                if let channelMessage = channelMessage {
                    rep["channelMessage"] = channelMessage
                }

                childUpdates["/\(DatabaseHelper.pathUserThreads)/\(appUser.uid)/\(group)/\(uid)"] = rep
            }
            
            ref.updateChildValues(childUpdates){
                (error:Error?, ref:DatabaseReference) in
                if let error = error {
                    print("Data could not be saved: \(error).")
                } else {
                    print("Data saved successfully!")
                }
            }
        }) { error in
            print(error.localizedDescription)
        }
    }
    
    static func updateUserThreads(_ members: [AppUser], message: ChatMessage) {
        var childUpdates = [String: Any]()
        
        for appUser in members {
            guard let threadUid = message.thread else {continue}
       
            childUpdates["/\(DatabaseHelper.pathUserThreads)/\(appUser.uid)/\(message.group)/\(threadUid)/message"] = message.representation
        }
        
        ref.updateChildValues(childUpdates){
            (error:Error?, ref:DatabaseReference) in
            if let error = error {
                print("UserThreads: Data could not be saved: \(error).")
            } else {
                print("UserThreads: Data saved successfully!")
            }
        }
    }
    
    static func updateUserMessages(_ members: [AppUser], message: ChatMessage) {
        var childUpdates = [String: Any]()
        
        for appUser in members {
            childUpdates["/\(DatabaseHelper.pathUserMessages)/\(appUser.uid)/\(message.id)"] = message.representation
        }
        
        ref.updateChildValues(childUpdates){
            (error:Error?, ref:DatabaseReference) in
            if let error = error {
                print("\(DatabaseHelper.pathUserMessages) could not be saved: \(error).")
            } else {
                print("\(DatabaseHelper.pathUserMessages) saved successfully!")
            }
        }
    }
    
    static func updateUserChannelMessages(_ members: [AppUser], message: ChatMessage) {
        var childUpdates = [String: Any]()
        
        for appUser in members {
            childUpdates["/\(DatabaseHelper.pathUserChannelMessages)/\(appUser.uid)/\(message.channel)/\(message.id)"] = message.representation
        }
        
        ref.updateChildValues(childUpdates){
            (error:Error?, ref:DatabaseReference) in
            if let error = error {
                print("\(DatabaseHelper.pathUserChannelMessages): Data could not be saved: \(error).")
            } else {
                print("\(DatabaseHelper.pathUserChannelMessages): Data saved successfully!")
            }
        }
    }
    
    static func updateUserThreadMessages(_ members: [AppUser], message: ChatMessage) {
        var childUpdates = [String: Any]()
        
        for appUser in members {
            childUpdates["/\(DatabaseHelper.pathUserThreadMessages)/\(appUser.uid)/\(message.thread!)/\(message.id)"] = message.representation
        }
        
        ref.updateChildValues(childUpdates){
            (error:Error?, ref:DatabaseReference) in
            if let error = error {
                print("\(DatabaseHelper.pathUserThreadMessages): Data could not be saved: \(error).")
            } else {
                print("\(DatabaseHelper.pathUserThreadMessages): Data saved successfully!")
            }
        }
    }
    
    static func updateUpdates(_ chatMessage: ChatMessage) {
        ref.child(DatabaseHelper.pathGroups).child(chatMessage.group).child("members").observeSingleEvent(of: .value, with: { snapshot in
            var members = [AppUser]()
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                guard let value = snap.value as? [String: Any] else { return }
                let uid = value["uid"] as? String ?? ""
                let phoneNumber = value["phoneNumber"] as? String ?? ""
                let appUser = AppUser(uid: uid, phoneNumber: phoneNumber)
                members.append(appUser)
            }
            
            self.updateUserUpdates(members, message: chatMessage)
        }) { error in
            print(error.localizedDescription)
        }
    }
    
    static func updateUserUpdates(_ members: [AppUser], message: ChatMessage) {
        var childUpdates = [String: Any]()
        let chatContact = message.isChat ? members.first(where: {$0.phoneNumber != message.sender}) : nil
        
        for appUser in members {
            guard appUser.phoneNumber != message.sender else {continue}
            
            var rep: [String: Any] = [
                "group": message.group,
                "groupName": message.groupName,
                "channel": message.channel,
                "channelName": message.channelName,
                "message": message.message.representation,
                "timestamp": message.timestamp.description,
                "sender": message.sender,
                "isChat": message.isChat,
            ]
            
            //        if let sender = sender {
            //          rep["sender"] = sender
            //        }
            //
            //        if let message = message {
            //          rep["message"] = message
            //        }
            
            var type = [String]()
            type.append("all")
            
            if let _ = message.message.mentions.firstIndex(where: {$0.phoneNumber == appUser.phoneNumber}) {
                type.append("mention")
            }
            
//            let input = "This is a test with the URL https://www.hackingwithswift.com to be detected."
//            let content = message.message.content
//            if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
//                let matches = detector.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
//                if !matches.isEmpty {
//                    type.append("link")
//                }
//
//                for match in matches {
//                    guard let range = Range(match.range, in: content) else { continue }
//                    let url = content[range]
//                    print(url)
//                }
//            }
            
            rep["type"] = type
            
            if message.isChat {
                if message.sender != appUser.phoneNumber  {
                    rep["groupName"] = message.sender
                } else if let chatPartner = chatContact {
                    rep["groupName"] = chatPartner.phoneNumber
                }
            }
            
//            guard let key = ref.child(DatabaseHelper.pathMessages).child(appUser.uid).childByAutoId().key else {continue}
            let key = message.id
            rep["messageUid"] = key
            childUpdates["/\(DatabaseHelper.pathUserUpdates)/\(appUser.uid)/\(key)"] = rep
        }
        
        ref.updateChildValues(childUpdates){
            (error:Error?, ref:DatabaseReference) in
            if let error = error {
                print("Data could not be saved: \(error).")
            } else {
                print("Data saved successfully!")
            }
        }
    }
    
    static func updateReceipts(_ message: ChatMessage) {
        
        var childUpdates = [String: Any]()
        
        if !message.isSent {
            childUpdates["/\(DatabaseHelper.pathMessageReceipts)/\(message.id)/message"] = message.representation
            childUpdates["/\(DatabaseHelper.pathMessageReceipts)/\(message.id)/isSent"] = true
        }
        
        ref.updateChildValues(childUpdates){
            (error:Error?, ref:DatabaseReference) in
            if let error = error {
                print("\(DatabaseHelper.pathMessageReceipts) isSent could not be updated: \(error).")
            } else {
                print("\(DatabaseHelper.pathMessageReceipts) isSent updated!")
            }
        }
    }
}
