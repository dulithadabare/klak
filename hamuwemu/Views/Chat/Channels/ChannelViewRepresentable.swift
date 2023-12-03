//
//  ChannelViewRepresentable.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/17/21.
//

import SwiftUI
import MessageKit
import InputBarAccessoryView

protocol MessageTappedDelegate: AnyObject {
    func messageTapped(with item: ThreadItem)
    func replyToMessage(_ message: ChatMessage)
}

struct InputBarUI: UIViewRepresentable {
    let view: InputBarAccessoryView

    func makeUIView(context: Context) -> some UIView {
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
    }
}

var built: ChannelViewController?

struct ChannelViewRepresentable: UIViewControllerRepresentable {
    @State var initialized = false
    var chat: ChatGroup
    var channel: ChatChannel
    var contactRepository: ContactRepository
    @Binding var selectedReplyMessage: ChatMessage?
    @Binding var selectedThreadItem: ThreadItem?
    @ObservedObject var model: Model
    
    var inputBar: InputBarAccessoryView {
        if built == nil {
                built = ChannelViewController(chat: chat, channel: channel, contactRepository: contactRepository)
        }
        return built!.messageInputBar
    }
    
    func makeUIViewController(context: Context)
    -> ChannelViewController {
        let controller = ChannelViewController(chat: chat, channel: channel, contactRepository: contactRepository)
        controller.messageTappedDelegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(
        _ channelViewController: ChannelViewController,
        context: Context
    ) {
        print("ChannelViewController Updating VC")
    }
    
    private func scrollToBottom(_ uiViewController: ChannelViewController, isLatestMessage: Bool) {
        DispatchQueue.main.async {
            // Do not scroll if the user is in the middle of the scroll view. For example, reading old messages.
            let shouldScrollToBottom =
                uiViewController.messagesCollectionView.isAtBottom && isLatestMessage || !self.initialized
            
            // The initialized state variable allows us to start at the bottom with the initial messages without seeing the initial scroll flash by
            if shouldScrollToBottom {
                uiViewController.messagesCollectionView.scrollToLastItem(animated: self.initialized)
                self.initialized = true
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    final class Coordinator {
        var control: ChannelViewRepresentable
        
        init(_ control: ChannelViewRepresentable) {
            self.control = control
        }
    }
}

//struct ChannelViewRepresentable_Previews: PreviewProvider {
//    static var previews: some View {
//        ChannelViewRepresentable(model: ChannelView.Model())
//    }
//}
extension ChannelViewRepresentable {
    class Model: ObservableObject {
        var threadDetailViewModel: ThreadDetailView.Model?
    }
}

// MARK: - MessageTappedDelegate
extension ChannelViewRepresentable.Coordinator: MessageTappedDelegate {
    func messageTapped(with item: ThreadItem) {
        control.selectedThreadItem = item
    }
    
    func replyToMessage(_ message: ChatMessage) {
        control.selectedReplyMessage = message
    }
}

//// MARK: - MessagesDisplayDelegate
//extension ChannelViewRepresentable.Coordinator: MessagesDisplayDelegate {
//    // MARK: - Text Messages
//
//   func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
//       return isFromCurrentSender(message: message) ? .white : .darkText
//   }
//
//    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
//            switch detector {
////            case .hashtag, .mention: return [.foregroundColor: UIColor.link]
//            case .url: return [.foregroundColor: UIColor.link]
//            default: return MessageLabel.defaultAttributes
//            }
//        }
//
//    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
//            return [.url, .address, .date, .transitInformation,]
//        }
//
//    // 1
//    func backgroundColor(
//        for message: MessageType,
//        at indexPath: IndexPath,
//        in messagesCollectionView: MessagesCollectionView
//    ) -> UIColor {
//        return isFromCurrentSender(message: message) ? .primary : .incomingMessage
////        return UIColor.clear
//    }
//
//    // 2
//    func shouldDisplayHeader(
//        for message: MessageType,
//        at indexPath: IndexPath,
//        in messagesCollectionView: MessagesCollectionView
//    ) -> Bool {
//        return false
//    }
//
//    // 3
//    func configureAvatarView(
//        _ avatarView: AvatarView,
//        for message: MessageType,
//        at indexPath: IndexPath,
//        in messagesCollectionView: MessagesCollectionView
//    ) {
//        avatarView.isHidden = true
//    }
//
//    // 4
//    func messageStyle(
//        for message: MessageType,
//        at indexPath: IndexPath,
//        in messagesCollectionView: MessagesCollectionView
//    ) -> MessageStyle {
//        let corner: MessageStyle.TailCorner =
//            isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
//        return .bubbleTail(corner, .curved)
//    }
//}
//
//// MARK: - MessagesLayoutDelegate
//extension ChannelViewRepresentable.Coordinator: MessagesLayoutDelegate {
//    // 1
//    func footerViewSize(
//        for message: MessageType,
//        at indexPath: IndexPath,
//        in messagesCollectionView: MessagesCollectionView
//    ) -> CGSize {
//        return CGSize(width: 0, height: 8)
//    }
//
//    // 2
//    func messageTopLabelHeight(
//        for message: MessageType,
//        at indexPath: IndexPath,
//        in messagesCollectionView: MessagesCollectionView
//    ) -> CGFloat {
//        return 20
//    }
//
//    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
//        return 17
//    }
//}
//
//// MARK: - MessageCellDelegate
//extension ChannelViewRepresentable.Coordinator: MessageCellDelegate {
//    func didSelectURL(_ url: URL) {
//        print("URL Selected: \(url)")
//    }
//
//    func didTapMessage(in cell: MessageCollectionViewCell) {
//        guard let messagesCollectionView = messagesCollectionView,
//            let indexPath = messagesCollectionView.indexPath(for: cell),
//                   let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) as? Message else {
//                       print("Failed to identify message when cell receive tap gesture")
//                       return
//               }
//
//        if let threadUid = message.chatMessage.thread,
//           let threadTitle = message.chatMessage.threadName {
//            let item = ThreadItem(threadUid: threadUid, title: threadTitle, message: message.chatMessage)
//            selectedMessage.wrappedValue = item
//        } else {
//            if case let .attributedText(attrText) = message.kind {
//                let item = ThreadItem(threadUid: nil, title: attrText.string, message: message.chatMessage)
//                selectedMessage.wrappedValue = item
//            }
//        }
//
//        print("Message tapped \(message.sender)")
//    }
//}
//
//// MARK: - MessagesDataSource
//extension ChannelViewRepresentable.Coordinator: MessagesDataSource {
//    // 1
//    func numberOfSections(
//        in messagesCollectionView: MessagesCollectionView
//    ) -> Int {
//        return messages.wrappedValue.count
//    }
//
//    // 2
//    func currentSender() -> SenderType {
//
//        return Sender(senderId: phoneNumber, displayName: "Dulitha")
//    }
//
//    // 3
//    func messageForItem(
//        at indexPath: IndexPath,
//        in messagesCollectionView: MessagesCollectionView
//    ) -> MessageType {
//        return messages.wrappedValue[indexPath.section]
//    }
//
//    // 4
//    func messageTopLabelAttributedText(
//        for message: MessageType,
//        at indexPath: IndexPath
//    ) -> NSAttributedString? {
//        let name = message.sender.displayName
//        return NSAttributedString(
//            string: name,
//            attributes: [
//                .font: UIFont.preferredFont(forTextStyle: .caption1),
//                .foregroundColor: UIColor(white: 0.3, alpha: 1)
//            ])
//    }
//
//    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
//        guard let message = message as? Message else {return nil}
//
//        var label = ""
//        if isFromCurrentSender(message: message) {
//            label = message.isRead ? "Read" : message.isDelivered ? "Delivered": message.isSent ? "Sent" : ""
//        }
//
//        if message.chatMessage.replyCount > 0 {
//            label = " \(message.chatMessage.replyCount) replies"
//        }
//
//        return NSAttributedString(string: label, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
//    }
//}
