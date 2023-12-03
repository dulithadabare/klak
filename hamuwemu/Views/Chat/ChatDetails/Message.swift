//
//  Message.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/1/21.
//

import UIKit
import Firebase
import MessageKit

struct MockUser: SenderType, Equatable {
    var senderId: String
    var displayName: String
    var uid: String = UUID().uuidString
}

struct Message: MessageKit.MessageType {
    let id: String?
    var messageId: String {
        return id ?? UUID().uuidString
    }
    let sentDate: Date
    var sender: SenderType {
        return user
    }
    var kind: MessageKind
//    var kind: MessageKind {
//        if let image = image {
//            let mediaItem = ImageMediaItem(image: image)
//            return .photo(mediaItem)
//        } else {
//            return .text(content)
//        }
//    }
    
    var user: MockUser
    var chatMessage: ChatMessage?
    var isSent: Bool = false
    var isDelivered: Bool = false
    var isRead: Bool = false
    
    var image: UIImage?
    var downloadURL: URL?
    
    
    
    private init(kind: MessageKind, user: MockUser, messageId: String, date: Date, chatMessage: ChatMessage? = nil) {
        self.kind = kind
        self.user = user
        self.id = messageId
        self.sentDate = date
        self.chatMessage = chatMessage
    }
    
    init(custom: Any?, user: MockUser, messageId: String, date: Date, chatMessage: ChatMessage? = nil) {
        self.init(kind: .custom(custom), user: user, messageId: messageId, date: date, chatMessage: chatMessage)
        }
    
    init(text: String, user: MockUser, messageId: String, date: Date, chatMessage: ChatMessage) {
        self.init(kind: .text(text), user: user, messageId: messageId, date: date, chatMessage: chatMessage)
    }
    
    init(attributedText: NSAttributedString, user: MockUser, messageId: String, date: Date, chatMessage: ChatMessage) {
        self.init(kind: .attributedText(attributedText), user: user, messageId: messageId, date: date, chatMessage: chatMessage)
    }
    
    init(chatMessage: ChatMessage, contactRepository: ContactRepository) {
        let attributedText = attributedString(with: chatMessage.message, contactRepository: contactRepository)
        
        if chatMessage.isSystemMessage {
            let system = MockUser(senderId: "000000", displayName: "System")
            self.init(custom: attributedText.string, user: system, messageId: chatMessage.id, date: chatMessage.timestamp, chatMessage: chatMessage)
        } else {
            let phoneNumber = AuthenticationService.shared.phoneNumber!
            let displayName = chatMessage.sender == phoneNumber ? "You" : contactRepository.getFullName(for: chatMessage.sender) ?? chatMessage.sender
            let user = MockUser(senderId: chatMessage.sender, displayName: displayName)
            self.init(kind: .attributedText(attributedText), user: user, messageId: chatMessage.id, date: chatMessage.timestamp, chatMessage: chatMessage)
            self.isSent = chatMessage.isSent
            self.isDelivered = chatMessage.isDelivered
            self.isRead = chatMessage.isRead
        }
    }
    
    init(image: UIImage, user: MockUser, messageId: String, date: Date, chatMessage: ChatMessage) {
        let mediaItem = ImageMediaItem(image: image)
        self.init(kind: .photo(mediaItem), user: user, messageId: messageId, date: date, chatMessage: chatMessage)
    }
}

// MARK: - Comparable
extension Message: Comparable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func < (lhs: Message, rhs: Message) -> Bool {
        return lhs.sentDate < rhs.sentDate
    }
}
