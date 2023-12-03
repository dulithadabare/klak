//
//  PreviewExtensions.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-24.
//

import Foundation
import CoreData

extension PersistenceController {
    // A test configuration for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)

        //        SampleData.shared.loadChatListItems(with: controller.container.viewContext, count: 10)
        SampleData.shared.loadSampleChatIds(with: controller.container.viewContext)
        SampleData.shared.loadSampleAppUsers(with: controller.container.viewContext)
        SampleData.shared.loadSampleChatThread(with: controller.container.viewContext)
                SampleData.shared.loadThreadListItems(with: controller.container.viewContext, count: 10)
                SampleData.shared.loadChatListItemForCompletePreviewFlow(with: controller.container.viewContext, isChat: false, isThreadMessage: false)
        //        SampleData.shared.loadMessages(with: controller.container.viewContext, count: 30)
                SampleData.shared.loadMessagesForPagination(with: controller.container.viewContext)
        SampleData.shared.loadThreadMessagesForPagination(with: controller.container.viewContext)
        
        

        
        controller.save()

        return controller
    }()
}

extension ChatGroup {
    static var preview: ChatGroup = {
        let groupId = SampleData.shared.groupId
        let defaultChannel = ChatChannel(channelUid: SampleData.shared.channelId, title: "Chat Channel", group: groupId)
        return ChatGroup(group: groupId, groupName: "Chat Group", isChat: true, defaultChannel: defaultChannel)
    }()
}

final class SampleData {
    static let shared = SampleData()
    
    private init() {}
    
    let groupId = UUID().uuidString
    let channelId = UUID().uuidString
    let threadId = UUID().uuidString
    
    let system = MockUser(senderId: "000000", displayName: "System")
    let dulitha = MockUser(senderId: "+16505553434", displayName: "Nathan Tannar")
    let steven = MockUser(senderId: "+16505553535", displayName: "Steven Deutsch")
    let wu = MockUser(senderId: "+16505553636", displayName: "Wu Zhong")
    
    lazy var senders = [dulitha, steven, wu]
    lazy var receipts: [MessageStatus] = [.sent, .delivered, .read, .none]
    
    let normalMentionMessage: NSAttributedString = {
        let content = "Hello @+16505553434"
        let mention = Mention(range: NSMakeRange(6, 13), uid: UUID().uuidString, phoneNumber: "+16505553434")
        let message = HwMessage(content: content, mentions: [mention], links: [])
        return HwChatListItem.getAttributedString(from: message)!
    }()
    
    let longMentionMessage: NSAttributedString = {
        let content = "Hello @+16505553434  lllllllllllllllllllllllllllll lllllllllllllllllllllllllllll lllllllllllllllllllllllllllll llllllllllllll"
        let mention = Mention(range: NSMakeRange(6, 13), uid: UUID().uuidString, phoneNumber: "+16505553434")
        let message = HwMessage(content: content, mentions: [mention], links: [])
        return HwChatListItem.getAttributedString(from: message)!
    }()
    
    let message = "Filler text is text that shares some characteristics of a real written text, but is random or otherwise generated. It may be used to display a sample of fonts, generate text for testing, or to spoof an e-mail spam filter."
    
   let longMessageWithShortLastLine: NSAttributedString = {
        let content = "Filler text is text that shares some characteristics of a real written text, but is random or otherwise generated. It may be used to display a sample of fonts, generate text for testing, or to spoof an e-mail spam filter."
        let message = HwMessage(content: content, mentions: [], links: [])
        return HwChatListItem.getAttributedString(from: message)!
    }()
    
    lazy var messages = [normalMentionMessage, longMentionMessage, longMessageWithShortLastLine]
    
    
    var currentSender: MockUser {
        return dulitha
    }
    
    var now = Date()
    
    
    var fileName:String = ""
    var alphabets = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
    let numFiles = 9999


    func getCharacter(counter c:Double) -> String {
        let totalAlphaBets = Double(alphabets.count)
        var chars:String
        var divisionResult = Int(c / totalAlphaBets)
        let modResult = Int(c.truncatingRemainder(dividingBy: totalAlphaBets))

        chars = getCharFromArr(index: modResult)

        if(divisionResult != 0){

            divisionResult -= 1

            if(divisionResult > alphabets.count-1){
                chars = getCharacter(counter: Double(divisionResult)) + chars
            }else{
                chars = getCharFromArr(index: divisionResult) + chars
            }
        }

        return chars
    }

    func getCharFromArr(index i:Int) -> String {
        if(i < alphabets.count){
            return alphabets[i]
        }else{
            print("wrong index")
            return ""
        }
    }
    
    func dateAddingRandomTime() -> Date {
        let randomNumber = Int(arc4random_uniform(UInt32(10)))
        if randomNumber % 2 == 0 {
            let date = Calendar.current.date(byAdding: .hour, value: randomNumber, to: now)!
            now = date
            return date
        } else {
            let randomMinute = Int(arc4random_uniform(UInt32(59)))
            let date = Calendar.current.date(byAdding: .minute, value: randomMinute, to: now)!
            now = date
            return date
        }
    }
    
    func  loadThreadListItem(with context: NSManagedObjectContext, threadId: String, groupId: String, isReplyingTo: Bool, titleText: NSAttributedString, messageText: NSAttributedString, sender: MockUser, status: Int16, undreadCount: Int16) -> HwThreadListItem {
        let item = HwThreadListItem(context: context)
        let thread = HwChatThread(context: context)
        thread.threadId = threadId
        thread.titleText = titleText
        thread.groupId = groupId
        thread.isReplyingTo = isReplyingTo
        thread.isTemp = false
        thread.threadListItem = item
        
        item.thread = thread
        item.threadId = threadId
        item.groupId = groupId
        item.lastMessageDate = Date()
        item.lastMessageText = messageText
        item.lastMessageSender = sender.senderId
        item.lastMessageSearchableText = messageText.string
        item.lastMessageStatusRawValue = status
        item.unreadCount = undreadCount
        
        for user in senders {
            let member = HwThreadMember(context: context)
            member.threadId = threadId
            member.uid = user.uid
            member.phoneNumber = user.senderId
        }
        
        return item
    }
    
    func loadSampleChatIds(with context: NSManagedObjectContext) {
        let item = HwChatId(context: context)
        item.phoneNumber = "+16505553535"
        item.groupId = groupId
    }

    func loadSampleAppUsers(with context: NSManagedObjectContext) {
        let item = HwAppContact(context: context)
        item.phoneNumber = "+16505553535"
        item.uid = UUID().uuidString
    }
    
    func loadSampleChatThread(with context: NSManagedObjectContext) {
        let item = HwChatThread(context: context)
        item.threadId = threadId
        item.titleText = normalMentionMessage
        item.replyingTo = nil
        item.groupId = groupId
        item.isTemp = false
    }
    
    func loadThreadListItems(with context: NSManagedObjectContext, count: Int){
        for i in 0..<count {
           _  = loadThreadListItem(with: context, threadId: UUID().uuidString, groupId: groupId, isReplyingTo: i.isMultiple(of: 2),titleText: normalMentionMessage, messageText: normalMentionMessage, sender: senders.randomElement()!, status: 1, undreadCount: 1)
        }
    }
    
    // Create 100 example messages.
    func loadMessagesForPagination(with managedObjectContext: NSManagedObjectContext){
        
        let groupName = "Chat Group"
        
        let channelName = "General"
        
        var counter = 20.0
        for i in 0..<21 {
            let item = HwChatMessage(context: managedObjectContext)
            let messageId = PushIdGenerator.shared.generatePushID()
            
            let sender = senders.randomElement()!
            item.groupUid = groupId
            item.groupName = groupName
            item.channelUid = channelId
            item.channelName = channelName
            if i.isMultiple(of: 2) {
                item.threadUid = UUID().uuidString
                item.threadName = "Chat Thread \(i)"
            }
            item.messageId = messageId
            counter -= 1
//            item.timestamp = dateAddingRandomTime()
            
            if i < 10 {
                let timestamp = Calendar.current.date(byAdding: .minute, value: -i, to: now)!
                item.timestamp = timestamp
            } else {
                let timestamp = Calendar.current.date(byAdding: .day, value: -1, to: now)!
                item.timestamp = Calendar.current.date(byAdding: .minute, value: -i, to: timestamp)!
            }
            item.author = sender.uid
            item.sender = sender.senderId
            item.statusRawValue = Int16(receipts.randomElement()!.rawValue)
            
            let content = "Hello \(i) \(messageId)"
//            let mention = Mention(range: NSMakeRange(6, 13), uid: UUID().uuidString, phoneNumber: "+16505553434")
            let message = HwMessage(content: content, mentions: [], links: [])
            item.text = longMessageWithShortLastLine
        }
    }
    
    func loadThreadMessagesForPagination(with managedObjectContext: NSManagedObjectContext){
        var counter = 20.0
        for i in 0..<21 {
            let item = HwChatMessage(context: managedObjectContext)
            let messageId = PushIdGenerator.shared.generatePushID()
            
            let sender = senders.randomElement()!
            item.groupUid = groupId
            item.threadUid = threadId
            item.messageId = messageId
            counter -= 1
//            item.timestamp = dateAddingRandomTime()
            
            if i < 10 {
                let timestamp = Calendar.current.date(byAdding: .minute, value: -i, to: now)!
                item.timestamp = timestamp
            } else {
                let timestamp = Calendar.current.date(byAdding: .day, value: -1, to: now)!
                item.timestamp = Calendar.current.date(byAdding: .minute, value: -i, to: timestamp)!
            }
            item.author = sender.uid
            item.sender = sender.senderId
            item.statusRawValue = Int16(receipts.randomElement()!.rawValue)
            
            let content = "Hello \(i) \(messageId)"
//            let mention = Mention(range: NSMakeRange(6, 13), uid: UUID().uuidString, phoneNumber: "+16505553434")
            let message = HwMessage(content: content, mentions: [], links: [])
            item.text = HwChatListItem.getAttributedString(from: message)
        }
    }
    
    func getHwChatGroup(with context: NSManagedObjectContext, isTemp: Bool = false) -> HwChatGroup {
        let group = HwChatGroup(context: context)
        group.groupId = groupId
        group.groupName = "Chat Group"
        group.createdAt = Date()
        group.isChat = true
        group.isTemp = isTemp
        
        let defaultChannel = HwChatChannel(context: context)
        defaultChannel.channelId = channelId
        defaultChannel.channelName = "Chat Channel"
        group.defaultChannel = defaultChannel
        
        return group
    }
    
    // Create 100 example messages.
    func loadMessages(with managedObjectContext: NSManagedObjectContext, count: Int){
        for i in 0..<count {
            let item = HwChatMessage(context: managedObjectContext)
            let groupId = UUID().uuidString
            let groupName = "Chat Group \(i)"
            let channelId = UUID().uuidString
            let channelName = "Chat Channel \(i)"
            let sender = senders.randomElement()!
            item.groupUid = groupId
            item.groupName = groupName
            item.channelUid = channelId
            item.channelName = channelName
            if i.isMultiple(of: 2) {
                item.threadUid = UUID().uuidString
                item.threadName = "Chat Thread \(i)"
            }
            item.messageId = UUID().uuidString
//            item.timestamp = dateAddingRandomTime()
            
            item.timestamp = Calendar.current.date(byAdding: i.isMultiple(of: 5) ? .day: .minute, value: -1, to: now)!
            item.sender = sender.senderId
            item.statusRawValue = Int16(receipts.randomElement()!.rawValue)
            
            let content = "Hello @+16505553434 \(i)"
            let mention = Mention(range: NSMakeRange(6, 13), uid: UUID().uuidString, phoneNumber: "+16505553434")
            let message = HwMessage(content: content, mentions: [mention], links: [])
            item.text = HwChatListItem.getAttributedString(from: message)
        }
    }
    
    func getMessage(managedObjectContext: NSManagedObjectContext, text: String? = nil, isFromCurrentSender: Bool = false, isSystemMessage: Bool = false) -> HwChatMessage{
        let i = 100
        let item = HwChatMessage(context: managedObjectContext)
        let groupId = UUID().uuidString
        let groupName = "Chat Group"
        let channelId = UUID().uuidString
        let channelName = "Chat Channel"
        let sender = isFromCurrentSender ?  currentSender : isSystemMessage ? system : steven
        item.groupUid = groupId
        item.groupName = groupName
        item.channelUid = channelId
        item.channelName = channelName
        if i.isMultiple(of: 2) {
            item.threadUid = UUID().uuidString
            item.threadName = "Chat Thread"
        }
        item.messageId = UUID().uuidString
//            item.timestamp = dateAddingRandomTime()
        item.timestamp = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        item.sender = sender.senderId
        item.statusRawValue = MessageStatus.sent.rawValue
        item.isSystemMessage = isSystemMessage
        
        if let text = text {
            item.text = NSAttributedString(string: text)
        } else {
            let content = "Hello @+16505553434 loooooooooooong meesssssaaaagggggeeeee"
            let mention = Mention(range: NSMakeRange(6, 3), uid: UUID().uuidString, phoneNumber: "+16505553434")
            let message = HwMessage( content: content, mentions: [mention], links: [])
            item.text = HwChatListItem.getAttributedString(from: message)
        }
        
        
        return item
    }
    
    func getMessageForPreview(managedObjectContext: NSManagedObjectContext, text: NSAttributedString? = nil, isFromCurrentSender: Bool = false, isSystemMessage: Bool = false) -> HwChatMessage{
        let i = 100
        let item = HwChatMessage(context: managedObjectContext)
        let groupId = UUID().uuidString
        let groupName = "Chat Group"
        let channelId = UUID().uuidString
        let channelName = "Chat Channel"
        let sender = isFromCurrentSender ?  currentSender : isSystemMessage ? system : steven
        item.groupUid = groupId
        item.groupName = groupName
        item.channelUid = channelId
        item.channelName = channelName
        if i.isMultiple(of: 2) {
            item.threadUid = UUID().uuidString
            item.threadName = "Chat Thread"
        }
        item.messageId = UUID().uuidString
//            item.timestamp = dateAddingRandomTime()
        item.timestamp = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        item.sender = sender.senderId
        item.statusRawValue = MessageStatus.sent.rawValue
        item.isSystemMessage = isSystemMessage
        
        if let text = text {
            item.text = text
        } else {
            let content = "Hello @+16505553434 loooooooooooong meesssssaaaagggggeeeee"
            let mention = Mention(range: NSMakeRange(6, 3), uid: UUID().uuidString, phoneNumber: "+16505553434")
            let message = HwMessage( content: content, mentions: [mention], links: [])
            item.text = HwChatListItem.getAttributedString(from: message)
        }
        
        
        return item
    }
    
    func getMessageWithParent(managedObjectContext: NSManagedObjectContext, message: String? = nil) -> HwChatMessage{
        let message = message ?? "This is the original message"
        let item = getHwChatMessage(with: message, managedObjectContext: managedObjectContext, isThreadStart: true, dateCount: -6)
        let parent = getHwChatMessage(with: "This is the latest reply", managedObjectContext: managedObjectContext, isThreadStart: false, dateCount: -5)
        
        item.replyCount = 4
        item.replyingTo = parent
        return item
    }
    
    func getMessageWithChild(managedObjectContext: NSManagedObjectContext, message: String? = nil) -> HwChatMessage{
        let message = message ?? "This is the original message"
        let item = getHwChatMessage(with: message, managedObjectContext: managedObjectContext, isThreadStart: true, dateCount: -6)
        let reply = getHwChatMessage(with: "This is the latest reply", managedObjectContext: managedObjectContext, isThreadStart: false, dateCount: -5)
        
        item.replyCount = 4
        item.addToReplies(reply)
        return item
    }
    
    func getMessageWithThreadReply(managedObjectContext: NSManagedObjectContext, message: String? = nil) -> HwChatMessage{
        let message = message ?? "This is the start of a thread. This is the start of a thread. This is the start of a thread"
        let parent = getHwChatMessage(with: "This is the original message", managedObjectContext: managedObjectContext, isThreadStart: false, dateCount: -7)
        let item = getHwChatMessage(with: message, managedObjectContext: managedObjectContext, isThreadStart: true, dateCount: -6)
        let reply = getHwChatMessage(with: "This is the latest reply", managedObjectContext: managedObjectContext, isThreadStart: true, dateCount: -5)
        
        item.replyingTo = parent
        item.replyCount = 4
        item.replyingThreadId = threadId
        item.addToReplies(reply)
        return item
    }
    
    private func getHwChatMessage(with text: String?, managedObjectContext: NSManagedObjectContext, isThreadStart: Bool, dateCount: Int) -> HwChatMessage{
        let item = HwChatMessage(context: managedObjectContext)
        let groupId = UUID().uuidString
        let groupName = "Chat Group"
        let channelId = UUID().uuidString
        let channelName = "Chat Channel"
        let sender = senders.randomElement()!
        item.groupUid = groupId
        item.groupName = groupName
        item.channelUid = channelId
        item.channelName = channelName
        if isThreadStart {
            item.threadUid = threadId
            item.threadName = "Chat Thread"
        }
        item.messageId = UUID().uuidString
//            item.timestamp = dateAddingRandomTime()
        item.timestamp = Calendar.current.date(byAdding: .day, value: dateCount, to: now)!
        item.sender = sender.senderId
        
        if let text = text {
            item.text = NSAttributedString(string: text)
        } else {
            let content = "Hello @+16505553434 loooooooooooong meesssssaaaagggggeeeee"
            let mention = Mention(range: NSMakeRange(6, 3), uid: UUID().uuidString, phoneNumber: "+16505553434")
            let message = HwMessage(content: content, mentions: [mention], links: [])
            item.text = HwChatListItem.getAttributedString(from: message)
        }
        
        
        return item
    }
    
    func loadChatListItems(with managedObjectContext: NSManagedObjectContext, count: Int){
        // Create 10 example programming languages.
        for i in 0..<count {
            
            let item = HwChatListItem(context: managedObjectContext)
            let groupId = UUID().uuidString
            let groupName = "Chat Group \(i)"
            let channelId = UUID().uuidString
            let channelName = "Chat Channel \(i)"
            let sender = senders.randomElement()!
            item.groupId = groupId
            item.groupName = groupName
            item.channelId = channelId
            item.channelName = channelName
            if i.isMultiple(of: 2) {
                item.threadId = UUID().uuidString
                item.threadName = "Chat Thread \(i)"
            }
            item.lastMessageId = UUID().uuidString
            item.lastMessageDate = Date().advanced(by: TimeInterval(i))
            item.lastMessageSender = sender.senderId
            item.unreadCount = Int16(i)
            
            let content = "Hello @+16505553434 \(i)"
            let mention = Mention(range: NSMakeRange(6, 13), uid: UUID().uuidString, phoneNumber: "+16505553434")
            let message = HwMessage(content: content, mentions: [mention], links: [])
            let attrString = HwChatListItem.getAttributedString(from: message)
            item.lastMessageText = attrString!.string
            item.lastMessageAttrText = attrString
            
            let group = HwChatGroup(context: managedObjectContext)
            group.groupId = groupId
            group.groupName = groupName
            group.createdAt = Date()
            group.isChat = true
            
            let defaultChannel = HwChatChannel(context: managedObjectContext)
            defaultChannel.channelId = channelId
            defaultChannel.channelName = channelName
            group.defaultChannel = defaultChannel
            
            item.group = group
        }
    }
    
    func loadChatListItemForCompletePreviewFlow(with managedObjectContext: NSManagedObjectContext, isChat: Bool = false, isThreadMessage: Bool = false){
        // Create 1 example programming languages.
        let item = HwChatListItem(context: managedObjectContext)
        let groupId = groupId
        let groupName = "Chat Group"
        let channelId = channelId
        let channelName = "Chat Channel"
        let sender = senders.randomElement()!
        item.groupId = groupId
        item.groupName = groupName
        item.channelId = channelId
        item.channelName = channelName
        if isThreadMessage {
            item.threadId = UUID().uuidString
            item.threadName = "Chat Thread"
        }
        item.lastMessageId = UUID().uuidString
        item.lastMessageDate = Date().advanced(by: TimeInterval(-Int(2.0)))
        item.lastMessageSender = sender.senderId
        item.lastMessageStatusRawValue = MessageStatus.delivered.rawValue
        item.unreadCount = Int16(20)
        
        let content = "Hello @+16505553434"
        let mention = Mention(range: NSMakeRange(6, 13), uid: UUID().uuidString, phoneNumber: "+16505553434")
        let message = HwMessage(content: content, mentions: [mention], links: [])
        let attrString = HwChatListItem.getAttributedString(from: message)
        item.lastMessageText = attrString!.string
        item.lastMessageAttrText = attrString
        
        let group = HwChatGroup(context: managedObjectContext)
        group.groupId = groupId
        group.groupName = groupName
        group.createdAt = Date()
        group.isChat = true
        
        let defaultChannel = HwChatChannel(context: managedObjectContext)
        defaultChannel.channelId = channelId
        defaultChannel.channelName = channelName
        group.defaultChannel = defaultChannel
        
        item.group = group
        
        for i in 0..<2 {
            let member = HwGroupMember(context: managedObjectContext)
            member.groupId = groupId
            member.uid = senders[i].uid
            member.phoneNumber = senders[i].senderId
        }
    }
    
    func getChatListItem(with managedObjectContext: NSManagedObjectContext, sender: String, author: String, status: MessageStatus) -> HwChatListItem {
        // Create 1 example programming languages.
        let item = HwChatListItem(context: managedObjectContext)
        let groupId = groupId
        let groupName = "Chat Group"
        let channelId = channelId
        let channelName = "Chat Channel"
        item.groupId = groupId
        item.groupName = groupName
        item.channelId = channelId
        item.channelName = channelName
        item.lastMessageId = UUID().uuidString
        item.lastMessageDate = Date().advanced(by: TimeInterval(-Int(2.0)))
        item.lastMessageSender = sender
        item.lastMessageStatusRawValue = status.rawValue
        item.unreadCount = Int16(20)
        item.threadUnreadCount = Int16(20)
        
        let content = "Hello @+16505553434"
        let mention = Mention(range: NSMakeRange(6, 13), uid: UUID().uuidString, phoneNumber: "+16505553434")
        let message = HwMessage(content: content, mentions: [mention], links: [])
        let attrString = HwChatListItem.getAttributedString(from: message)
        item.lastMessageText = attrString!.string
        item.lastMessageAttrText = attrString
        
        let group = HwChatGroup(context: managedObjectContext)
        group.groupId = groupId
        group.groupName = groupName
        group.createdAt = Date()
        group.isChat = true
        
        let defaultChannel = HwChatChannel(context: managedObjectContext)
        defaultChannel.channelId = channelId
        defaultChannel.channelName = channelName
        group.defaultChannel = defaultChannel
        
        item.group = group
        
        for i in 0..<2 {
            let member = HwGroupMember(context: managedObjectContext)
            member.groupId = groupId
            member.uid = senders[i].uid
            member.phoneNumber = senders[i].senderId
        }
        
        return item
    }
}
