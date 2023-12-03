//
//  ThreadViewController.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/29/21.
//

import MessageKit
import FirebaseDatabase

class ThreadViewController: ChatViewController {
    var thread: ChatThread
    
    init(thread: ChatThread, chat: ChatGroup, channel: ChatChannel, contactRepository: ContactRepository) {
        self.thread = thread
        super.init(chat: chat, channel: channel, contactRepository: contactRepository)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !thread.isTemp {
            loadFirstMessages()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        becomeFirstResponder()
    }
    
    override func setupDatabaseReferences(){
        print("ThreadViewController setupDatabaseReferences")
        messagesRef = ref
            .child(DatabaseHelper.pathUserThreadMessages)
            .child(authenticationService.userId!)
            .child(thread.threadUid)
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
