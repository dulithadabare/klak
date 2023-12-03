//
//  ChatThreadModel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-09.
//

import Foundation

class ChatThreadModel: Identifiable, ObservableObject {
    var id: String {
        threadUid
    }
    let threadUid: String
    let group: String
    var title: NSAttributedString
    let replyingTo: String?
    var isTemp: Bool = false
    var members: [String: AppUser]
    var chat: ChatGroup
    @Published var isFirstResponder: Bool = false
    
    init(threadUid: String, group: String, title: NSAttributedString, replyingTo: String?, isTemp: Bool = false, members: [String : AppUser], chat: ChatGroup) {
        self.threadUid = threadUid
        self.group = group
        self.title = title
        self.replyingTo = replyingTo
        self.isTemp = isTemp
        self.members = members
        self.chat = chat
    }
    
    init(from hwChatThread: HwChatThread) {

        self.threadUid = hwChatThread.threadId!
        self.group = hwChatThread.groupId!
        self.title = hwChatThread.titleText!
        self.replyingTo = hwChatThread.replyingTo
        self.isTemp = hwChatThread.isTemp
        self.members = [:]
        self.chat = ChatGroup(from: hwChatThread.group!)
    }
    
    func addMembers(appUsers: [AppUser]){
        for appUser in appUsers {
            self.members[appUser.uid] = appUser
        }
    }
}

extension ChatThreadModel {
    static var preview: ChatThreadModel = {
        let group = SampleData.shared.groupId
        let threadUid = SampleData.shared.threadId
        let title = attributedString(with: HwMessage(content: "Thread Name", mentions: [], links: []), contactRepository: ContactRepository.preview)
        return ChatThreadModel(threadUid: threadUid, group: group, title: title, replyingTo: nil, isTemp: false, members: [:], chat: ChatGroup.preview)
    }()
    
    static var temp: ChatThreadModel = {
        let group = UUID().uuidString
        let threadUid = UUID().uuidString
        let title = NSAttributedString(string: "TEMP")
        return ChatThreadModel(threadUid: threadUid, group: group, title: title, replyingTo: nil, isTemp: false, members: [:], chat: ChatGroup(group: group, groupName: "String", isChat: true, members: []))
    }()
}

extension ChatThreadModel: Hashable {
    static func == (lhs: ChatThreadModel, rhs: ChatThreadModel) -> Bool {
        lhs.threadUid == rhs.threadUid
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(threadUid)
//        hasher.combine(message)
    }
}
