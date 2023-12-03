//
//  ChatViewController.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/1/21.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import FirebaseDatabase
import Combine

final class ChannelViewController: ChatViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        loadFirstMessages()
    }
    
    override func setUpMessageView() {
            super.setUpMessageView()
            messagesCollectionView.messageCellDelegate = self
        }
    
    override func save(_ message: HwMessage) {
        if !chat.isTemp, !channel.isTemp {
            
            ChatRepository.sendMessage(message: message, channel: channel.channelUid, channelName: channel.title, group: chat.group, groupName: chat.groupName, isChat: chat.isChat)
        } else if let group = ChatRepository.addGroup(chat){
            
            ChatRepository.addChannel(channel)
            ChatRepository.sendMessage(message: message, channel: channel.channelUid, channelName: channel.title, group: group, groupName: chat.groupName, isChat: chat.isChat)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil,
                                              previewProvider: nil,
                                              actionProvider: {
                    suggestedActions in
                let inspectAction =
                    UIAction(title: NSLocalizedString("Reply", comment: ""),
                             image: UIImage(systemName: "arrowshape.turn.up.left")) { action in
                        self.performReply(toItemAt: indexPath)
                    }
                    
                let duplicateAction =
                    UIAction(title: NSLocalizedString("Forward", comment: ""),
                             image: UIImage(systemName: "arrowshape.turn.up.forward")) { action in
//                        self.performDuplicate()
                    }
                    
                let deleteAction =
                    UIAction(title: NSLocalizedString("Delete", comment: ""),
                             image: UIImage(systemName: "trash"),
                             attributes: .destructive) { action in
//                        self.performDelete()
                    }
                                                
                return UIMenu(title: "", children: [inspectAction, duplicateAction, deleteAction])
            })
    }
    
    func performReply(toItemAt indexPath: IndexPath) {
        guard let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) as? Message else {
                       print("ChannelViewController: Failed to identify message on reply action")
                       return
               }
        
        if let chatMessage = message.chatMessage {
            print("ChannelViewController: Replying to message \(chatMessage.id)")
            messageTappedDelegate?.replyToMessage(chatMessage)
        }
    }
}

// MARK: - MessageCellDelegate
extension ChannelViewController: MessageCellDelegate {
    func didSelectURL(_ url: URL) {
        print("ChannelViewController: URL Selected: \(url)")
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
                   let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) as? Message else {
                       print("ChannelViewController: Failed to identify message when cell receive tap gesture")
                       return
               }
        
        guard let chatMessage = message.chatMessage,
              !chatMessage.isSystemMessage else {
            print("ChannelViewController: Tap gesture on system message")
            return
        }
        
        if let threadUid = chatMessage.thread,
           let threadTitle = chatMessage.threadName {
            let item = ThreadItem(threadUid: threadUid, title: threadTitle, channel: chatMessage.channel, group: chatMessage.group, message: chatMessage)
            messageTappedDelegate?.messageTapped(with: item)
        } else {
            if case let .attributedText(attrText) = message.kind {
                let item = ThreadItem(title: attrText.string, message: chatMessage, channel: chatMessage.channel, group: chatMessage.group)
                messageTappedDelegate?.messageTapped(with: item)
            }
        }
        
        print("Message tapped \(message.sender)")
    }
}
