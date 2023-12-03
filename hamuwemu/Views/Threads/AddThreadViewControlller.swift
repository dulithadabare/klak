//
//  AddThreadViewControlller.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/23/21.
//

import MessageKit
import FirebaseDatabase

final class AddThreadViewController: ThreadViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        if ( thread.channelMessage == nil ) {
            let system = MockUser(senderId: "000000", displayName: "System")
            let systemMessage = Message(custom: "Send a message to start a new thread", user: system, messageId: UUID().uuidString, date: Date())
            self.messageList = [systemMessage]
            self.messagesCollectionView.refreshControl = nil
        } else {
            let channelMessage = thread.channelMessage!
            let disaplyName = contactRepository.getFullName(for: channelMessage.sender) ?? channelMessage.sender
            let system = MockUser(senderId: "000000", displayName: "System")
            let systemMessage = Message(custom: "Send a message to start a new thread in in reply to \(disaplyName)", user: system, messageId: UUID().uuidString, date: Date())
            let firstMessage = Message(chatMessage: thread.channelMessage!, contactRepository: contactRepository)
            self.messages[firstMessage.messageId] = firstMessage
            self.messageList = [systemMessage, firstMessage]
            self.messagesCollectionView.refreshControl = nil
        }
    }
}
