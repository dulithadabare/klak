//
//  ChatViewController.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/9/21.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import FirebaseDatabase
import Combine
import CoreData

class ChatViewController: MessagesViewController, NSFetchedResultsControllerDelegate {
    weak var messageTappedDelegate: MessageTappedDelegate?
    
    var members: [GroupMember] = []
    lazy var messageList: [Message] = []
    var messages: [String: Message] = [:]
    let phoneNumber = AuthenticationService.shared.phoneNumber!
    var authenticationService: AuthenticationService = .shared
    var initialized = false
    
    var chat: ChatGroup
    var channel: ChatChannel
    var contactRepository: ContactRepository
    
    var ref = Database.root
    var messagesRef: DatabaseReference?
    var latestMessageRef: DatabaseQuery?
    var messageReceiptRef: DatabaseReference?
    var membersRef: DatabaseReference?
    var lastIndex: String?
    let initialLoadLimit: UInt = 20
    
    var fetchedResultsController: NSFetchedResultsController<HwChatMessage>!
    
    private var cancellables: Set<AnyCancellable> = []
    
    private(set) lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(loadMoreMessages), for: .valueChanged)
        return control
    }()
    
    private let mentionTextAttributes: [NSAttributedString.Key : Any] = [
        .font: UIFont.preferredFont(forTextStyle: .body),
        .foregroundColor: UIColor.systemBlue,
        .backgroundColor: UIColor.systemBlue.withAlphaComponent(0.1)
    ]
    
    /// The object that manages autocomplete
    lazy var autocompleteManager: AutocompleteManager = { [unowned self] in
        let manager = AutocompleteManager(for: self.messageInputBar.inputTextView)
        manager.delegate = self
        manager.dataSource = self
        return manager
    }()
    
    // MARK: - Private properties
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        //            formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    
    init(chat: ChatGroup, channel: ChatChannel, contactRepository: ContactRepository) {
        self.chat = chat
        self.channel = channel
        self.contactRepository = contactRepository
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        //        ref.removeAllObservers()
    }
    
    override func viewDidLoad() {
        print("ChatViewController viewDidLoad")
        messagesCollectionView = MessagesCollectionView(frame: .zero, collectionViewLayout: SystemMessageFlowLayout())
        super.viewDidLoad()
        //        navigationItem.largeTitleDisplayMode = .never
        messagesCollectionView.register(SystemMessageCell.self)
        setUpMessageView()
        setupDatabaseReferences()
        removeMessageAvatars()
        registerSubscribers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("ChatViewController viewDidAppear")
        super.viewDidAppear(animated)
        addMessageListener()
        //        becomeFirstResponder()
        
        if !self.initialized {
            print("ChatViewController Scrolling without animation")
            messagesCollectionView.scrollToLastItem(animated: false)
            self.initialized = true
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeListeners()
        //            MockSocket.shared.disconnect()
        //            audioController.stopAnyOngoingPlaying()
    }
    
    func loadFirstMessages() {
//        if fetchedResultsController == nil {
//                let request = HwChatMessage.fetchRequest()
//            let sort = NSSortDescriptor(keyPath: \HwChatMessage.timestamp, ascending: false)
//                request.sortDescriptors = [sort]
//                request.fetchBatchSize = 20
//
//                fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
//                fetchedResultsController.delegate = self
//            }
//
//            do {
//                try fetchedResultsController.performFetch()
//                tableView.reloadData()
//            } catch {
//                print("Fetch failed")
//            }
        
        self.messagesRef?
            .queryOrderedByKey()
            .queryLimited(toLast: initialLoadLimit + 1)
            .observeSingleEvent(of: .value, with: { [weak self] snapshot in
                DispatchQueue.global(qos: .userInitiated).async {
                    guard let self = self else {return}
                    var loadedMessages = [Message]()
                    for child in snapshot.children {
                        let snap = child as! DataSnapshot
                        guard let value = snap.value as? [String: Any],
                              let chatMessage = ChatMessage(dict: value ) else { return }
                        let message = Message(chatMessage: chatMessage, contactRepository: self.contactRepository)
                        loadedMessages.append(message)
                    }
                    //                    self.lastIndex = messages.first?.chatMessage.id
                    //                    if messages.count > 3 {
                    //                        messages.removeFirst()
                    //                    }
                    
                    var lastIndex: String?
                    var disableRefresh = false
                    if loadedMessages.count > self.initialLoadLimit {
                        lastIndex = loadedMessages.first?.chatMessage?.id
                        loadedMessages.removeFirst()
                    } else if loadedMessages.count <= self.initialLoadLimit {
                        disableRefresh = true
                    }
                    
                    DispatchQueue.main.async {
                        self.updateMessageList(with: loadedMessages) {
                            self.lastIndex = lastIndex
                            self.messageList = loadedMessages
                            print("ChatViewController: lastIndex \(lastIndex ?? "nil")")
                            print("ChatViewController: loaded Data count \(loadedMessages.count)")
                            self.messagesCollectionView.reloadData()
                            if !self.initialized {
                                print("ChatViewController Scrolling")
                                self.messagesCollectionView.scrollToLastItem(animated: self.initialized)
                                self.initialized = true
                            }
                            
                            if disableRefresh {
                                print("ChatViewController disabling refresh")
                                self.messagesCollectionView.refreshControl = nil
                            }
                        }
                    }
                }
            })
    }
    
    @objc func loadMoreMessages() {
        self.messagesRef?
            .queryOrderedByKey()
            .queryEnding(atValue: self.lastIndex)
            .queryLimited(toLast: initialLoadLimit + 1)
            .observeSingleEvent(of: .value, with: { [weak self] snapshot in
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1) {
                    guard let self = self else {return}
                    var loadedMessages = [Message]()
                    for child in snapshot.children {
                        let snap = child as! DataSnapshot
                        guard let value = snap.value as? [String: Any],
                              let chatMessage = ChatMessage(dict: value ) else { return }
                        let message = Message(chatMessage: chatMessage, contactRepository: self.contactRepository)
                        loadedMessages.append(message)
                    }
                    var lastIndex: String?
                    var disableRefresh = false
                    print("ChatViewController: loaded Data count \(loadedMessages.count)")
                    if loadedMessages.count > self.initialLoadLimit {
                        lastIndex = loadedMessages.first!.chatMessage!.id
                        loadedMessages.removeFirst()
                    } else if loadedMessages.count <= self.initialLoadLimit {
                        disableRefresh = true
                    }
                    
                    DispatchQueue.main.async {
                        self.updateMessageList(with: loadedMessages) {
                            self.lastIndex = lastIndex
                            self.messageList.insert(contentsOf: loadedMessages, at: 0)
                            print("ChatViewController Reloading Data after refresh")
                            print("ChatViewController: lastIndex \(lastIndex)")
                            
                            self.messagesCollectionView.reloadDataAndKeepOffset()
                            self.refreshControl.endRefreshing()
                            if disableRefresh {
                                print("ChatViewController: disabling refresh")
                                self.messagesCollectionView.refreshControl = nil
                            }
                        }
                    }
                }
            })
    }
    
    func registerSubscribers() {
        chat.$members
            .map { (dict) -> [GroupMember] in
                Array(dict.values).map { (appUser) -> GroupMember in
                    let fullName = self.contactRepository.getFullName(for: appUser.phoneNumber) ?? appUser.phoneNumber
                    return GroupMember(uid: appUser.uid, phoneNumber: appUser.phoneNumber, fullName: fullName)
                }
            }
            .assign(to: \.members, on: self)
            .store(in: &cancellables)
    }
    
    func setupDatabaseReferences(){
        messagesRef = ref.child(DatabaseHelper.pathUserChannelMessages).child(authenticationService.userId!).child(channel.channelUid)
    }
    
    func addMessageListener() {
        print("ChatViewController addMessageListener called")
        latestMessageRef = messagesRef?.queryOrderedByKey().queryLimited(toLast: 1)
        
        _ = latestMessageRef?.observe( .childAdded, with: { snapshot in
            guard let value = snapshot.value as? [String: Any],
                  let chatMessage = ChatMessage(dict: value ) else {
                //                    self.navigationController?.popViewController(animated: true)
                return
            }
            
            print("ChatViewController addMessageListener childAdded called")
            
            self.handleDocumentChange(chatMessage, change: .childAdded)
            self.updateReadReceipt(for: chatMessage)
        })
        
        _ = messagesRef?.observe( .childChanged, with: { snapshot in
            guard let value = snapshot.value as? [String: Any],
                  let chatMessage = ChatMessage(dict: value ) else {
                //                    self.navigationController?.popViewController(animated: true)
                return
            }
            
            print("ChatViewController addMessageListener childChanged called")
            
            self.handleDocumentChange(chatMessage, change: .childChanged)
        })
    }
    
    func removeListeners(){
        latestMessageRef?.removeAllObservers()
        messagesRef?.removeAllObservers()
    }
    
    @objc func addItems(){
        
    }
    
    func setUpMessageView() {
        //        scrollsToLastItemOnKeyboardBeginsEditing = true
        maintainPositionOnKeyboardFrameChanged = true
        //        messageInputBar.inputTextView.tintColor = .primary
        //        messageInputBar.sendButton.setTitleColor(.primary, for: .normal)
        messageInputBar.delegate = self
        
        // Configure AutocompleteManager
        autocompleteManager.register(prefix: "@", with: mentionTextAttributes)
        autocompleteManager.maxSpaceCountDuringCompletion = 1 // Allow for autocompletes with a space
        
        // Set plugins
        messageInputBar.inputPlugins = [autocompleteManager]
        
        //
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        //        messagesCollectionView.messageCellDelegate = self
        
        messagesCollectionView.refreshControl = refreshControl
        
    }
    
    // MARK: - Custom Cell
    
    override open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
            fatalError("Ouch. nil data source for messages")
        }
        
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        if case .custom = message.kind {
            let cell = messagesCollectionView.dequeueReusableCell(SystemMessageCell.self, for: indexPath)
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            return cell
        }
        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }
    
    private func removeMessageAvatars() {
        guard
            let layout = messagesCollectionView.collectionViewLayout
                as? MessagesCollectionViewFlowLayout
        else {
            return
        }
        layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
        layout.textMessageSizeCalculator.incomingAvatarSize = .zero
        layout.setMessageIncomingAvatarSize(.zero)
        layout.setMessageOutgoingAvatarSize(.zero)
        let incomingLabelAlignment = LabelAlignment(
            textAlignment: .left,
            textInsets: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0))
        layout.setMessageIncomingMessageTopLabelAlignment(incomingLabelAlignment)
        let outgoingLabelAlignment = LabelAlignment(
            textAlignment: .right,
            textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15))
        layout.setMessageOutgoingMessageTopLabelAlignment(outgoingLabelAlignment)
    }
    
    // MARK: - Helpers
    func isTimeLabelVisible(at indexPath: IndexPath) -> Bool {
        return indexPath.section % 3 == 0 && !isPreviousMessageSameSender(at: indexPath)
    }
    
    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        return messageList[indexPath.section].user == messageList[indexPath.section - 1].user
    }
    
    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section + 1 < messageList.count else { return false }
        return messageList[indexPath.section].user == messageList[indexPath.section + 1].user
    }
    
    func save(_ message: HwMessage) {
        if !chat.isTemp, !channel.isTemp {
            
            ChatRepository.sendMessage(message: message, channel: channel.channelUid, channelName: channel.title, group: chat.group, groupName: chat.groupName, isChat: chat.isChat)
        } else if let group = ChatRepository.addGroup(chat){
            
            ChatRepository.addChannel(channel)
            ChatRepository.sendMessage(message: message, channel: channel.channelUid, channelName: channel.title, group: group, groupName: chat.groupName, isChat: chat.isChat)
            
        }
    }
    
    func insertMessage(_ message: Message) {
        guard messages[message.messageId] == nil else {return}
        messages[message.messageId] = message
        messageList.append(message)
        print("ChatViewController Reloading Data after insert")
        // Reload last section to update header/footer labels and insert a new one
        messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections([messageList.count - 1])
            if messageList.count >= 2 {
                messagesCollectionView.reloadSections([messageList.count - 2])
            }
        }, completion: { [weak self] _ in
            if self?.isLastSectionVisible() == true {
                print("ChatViewController Scrolling after insert")
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
        })
    }
    
    func updateMessageList(with messages: [Message], completion: () -> ()){
        messages.forEach{
            self.messages[$0.messageId] = $0
            if let chatMessage =  $0.chatMessage, !chatMessage.isSystemMessage {
                self.updateReadReceipt(for: chatMessage)
            }
        }
        completion()
    }
    
    private func updateMessage(_ message: Message) {
        messages[message.messageId] = message
        if let row = messageList.firstIndex(where: {$0.id == message.id}) {
            messageList[row] = message
            print("ChatViewController Reloading Data after update")
            messagesCollectionView.reloadSections([row])
        }
    }
    
    func updateReadReceipt(for message: ChatMessage){
        guard message.author != authenticationService.userId!,
              !message.isReadByCurrUser else {
            return
        }
        
        ChatRepository.updateReadReceipt(for: message, messagePath: "/\(DatabaseHelper.pathUserChannelMessages)/\(authenticationService.userId!)/\(message.channel)/\(message.id)")
    }
    
    private func handleDocumentChange(_ chatMessage: ChatMessage, change: DataEventType) {
        let message = Message(chatMessage: chatMessage, contactRepository: contactRepository)
        switch change {
        case .childAdded:
            insertMessage(message)
        case .childChanged:
            updateMessage(message)
        default:
            break
        }
    }
    
    func isLastSectionVisible() -> Bool {
        
        guard !messageList.isEmpty else { return false }
        
        let lastIndexPath = IndexPath(item: 0, section: messageList.count - 1)
        
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
    
    func getFullName(for phoneNumber: String)  -> String? {
        return contactRepository.getFullName(for: phoneNumber)
    }
}

// MARK: - MessagesDisplayDelegate
extension ChatViewController: MessagesDisplayDelegate {
    // 1
    func backgroundColor(
        for message: MessageKit.MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> UIColor {
        return isFromCurrentSender(message: message) ? .systemGreen : .secondarySystemGroupedBackground
        //        return UIColor.clear
    }
    
    // 2
    func shouldDisplayHeader(
        for message: MessageKit.MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> Bool {
        return false
    }
    
    // 3
    func configureAvatarView(
        _ avatarView: AvatarView,
        for message: MessageKit.MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) {
        avatarView.isHidden = true
    }
    
    // 4
    func messageStyle(
        for message: MessageKit.MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> MessageStyle {
        var corners: UIRectCorner = []
        
        if isFromCurrentSender(message: message) {
            corners.formUnion(.topLeft)
            corners.formUnion(.bottomLeft)
            corners.formUnion(.topRight)
            if isNextMessageSameSender(at: indexPath) {
                corners.formUnion(.bottomRight)
            }
        } else {
            corners.formUnion(.topRight)
            corners.formUnion(.bottomRight)
            corners.formUnion(.topLeft)
            if isNextMessageSameSender(at: indexPath) {
                corners.formUnion(.bottomLeft)
            }
        }
        //        let corner: MessageStyle.TailCorner =
        //                    isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        
        
        return .custom { view in
            let radius: CGFloat = 8
            let path = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            view.layer.mask = mask
        }
    }
    
    func detectorAttributes(for detector: DetectorType, and message: MessageKit.MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
        switch detector {
        //            case .hashtag, .mention: return [.foregroundColor: UIColor.link]
        case .url: return [.foregroundColor: UIColor.link]
        default: return CustomMessageLabel.defaultAttributes
        }
    }
    
    func enabledDetectors(for message: MessageKit.MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .date, .transitInformation,]
    }
}

// MARK: - MessagesLayoutDelegate
extension ChatViewController: MessagesLayoutDelegate {
    // 1
    func footerViewSize(
        for message: MessageKit.MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> CGSize {
        return CGSize(width: 0, height: 8)
    }
    
    // 2
    func messageTopLabelHeight(
        for message: MessageKit.MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> CGFloat {
        if isFromCurrentSender(message: message) {
            return !isPreviousMessageSameSender(at: indexPath) ? 20 : 0
        } else {
            return !isPreviousMessageSameSender(at: indexPath) ? (20) : 0
        }
        //        return 20
    }
    
    func cellBottomLabelHeight(for message: MessageKit.MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 0
    }
    
    func cellTopLabelHeight(for message: MessageKit.MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if isTimeLabelVisible(at: indexPath) {
            return 18
        }
        return 0
    }
    
    func messageBottomLabelHeight(for message: MessageKit.MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return (!isNextMessageSameSender(at: indexPath) && isFromCurrentSender(message: message)) ? 16 : 0
    }
}

extension ChatViewController: MessageLabelDelegate {
    func didSelectAddress(_ addressComponents: [String: String]) {
        print("Address Selected: \(addressComponents)")
    }
    
    func didSelectDate(_ date: Date) {
        print("Date Selected: \(date)")
    }
    
    func didSelectPhoneNumber(_ phoneNumber: String) {
        print("Phone Number Selected: \(phoneNumber)")
    }
    //
    //    func didSelectURL(_ url: URL) {
    //        print("URL Selected: \(url)")
    //    }
    
    func didSelectTransitInformation(_ transitInformation: [String: String]) {
        print("TransitInformation Selected: \(transitInformation)")
    }
    
    func didSelectHashtag(_ hashtag: String) {
        print("Hashtag selected: \(hashtag)")
    }
    
    func didSelectMention(_ mention: String) {
        print("Mention selected: \(mention)")
    }
    
    func didSelectCustom(_ pattern: String, match: String?) {
        print("Custom data detector patter selected: \(pattern)")
    }
}


// MARK: - MessagesDataSource
extension ChatViewController: MessagesDataSource {
    // 1
    func numberOfSections(
        in messagesCollectionView: MessagesCollectionView
    ) -> Int {
        return messageList.count
    }
    
    // 2
    func currentSender() -> SenderType {
        let phoneNumber = AuthenticationService.shared.phoneNumber
        let displayName = AuthenticationService.shared.displayName
        return Sender(senderId: phoneNumber!, displayName: displayName ?? "You")
    }
    
    // 3
    func messageForItem(
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> MessageKit.MessageType {
        return messageList[indexPath.section]
    }
    
    // 4
    func messageTopLabelAttributedText(
        for message: MessageKit.MessageType,
        at indexPath: IndexPath
    ) -> NSAttributedString? {
        //        let name = message.sender.displayName
        //        return NSAttributedString(
        //            string: name,
        //            attributes: [
        //                .font: UIFont.preferredFont(forTextStyle: .caption1),
        //                .foregroundColor: UIColor(white: 0.3, alpha: 1)
        //            ])
        
        if !isPreviousMessageSameSender(at: indexPath) {
            let name = message.sender.displayName
            return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
        }
        return nil
    }
    
    func messageBottomLabelAttributedText(for message: MessageKit.MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        //        if !isNextMessageSameSender(at: indexPath) && isFromCurrentSender(message: message) {
        //                    return NSAttributedString(string: "Delivered", attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
        //                }
        //                return nil
        
        guard let message = message as? Message else {return nil}
        
        guard let chatMessage = message.chatMessage, !chatMessage.isSystemMessage else {return nil}
        
        let dateString = formatter.string(from: message.sentDate)
        var label = ""
        if isFromCurrentSender(message: message) {
            label = message.isRead ? " Read" : message.isDelivered ? " Delivered": message.isSent ? " Sent" : " "
        }
        
        if chatMessage.replyCount > 0 {
            label = " \(chatMessage.replyCount) replies"
        }
        
        if let replyMessage = chatMessage.replyOriginalMessage {
            label = " In reply to \(replyMessage.author)"
        }
        
        let timestamp =  NSAttributedString(string: dateString, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
        let sentReceipt = NSAttributedString(string: label, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        
        let result = NSMutableAttributedString()
        result.append(timestamp)
        result.append(sentReceipt)
        
        return result
    }
    
    func cellTopLabelAttributedText(for message: MessageKit.MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 3 == 0 {
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
        return nil
    }
    
    func cellBottomLabelAttributedText(for message: MessageKit.MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        guard let message = message as? Message else {return nil}
        guard let chatMessage = message.chatMessage, !chatMessage.isSystemMessage else {return nil}
        
        var label = ""
        if isFromCurrentSender(message: message) {
            label = message.isRead ? "Read" : message.isDelivered ? "Delivered": message.isSent ? "Sent" : ""
        }
        
        if chatMessage.replyCount > 0 {
            label = " \(chatMessage.replyCount) replies"
        }
        
        return NSAttributedString(string: label, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
    }
}


// MARK: - InputBarAccessoryViewDelegate
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(
        _ inputBar: InputBarAccessoryView,
        didPressSendButtonWith text: String
    ) {
        var content = text
        // Here we can parse for which substrings were autocompleted
        let attributedText = inputBar.inputTextView.attributedText!
        let range = NSRange(location: 0, length: attributedText.length)
        var mentions = [Mention]()
        attributedText.enumerateAttribute(.autocompleted, in: range, options: []) { (attributes, range, stop) in
            
            let substring = attributedText.attributedSubstring(from: range)
            
            if substring.string.hasPrefix("@") {
                let context = substring.attribute(.autocompletedContext, at: 0, effectiveRange: nil) as! [String: String]
                if !context.isEmpty {
                    
                    if let subrange = Range(range, in: content) {
                        let uid = context["uid"]!
                        let phoneNumber = context["phoneNumber"]!
                        let replacement = "@\(phoneNumber)"
                        content.replaceSubrange(subrange, with: replacement)
                        let newRange = NSMakeRange(range.location, replacement.count)
                        
                        //                        content.replaceSubrange(Range(newRange, in: content)!, with: newRange.description)
                        
                        let mention = Mention( range: newRange, uid: uid, phoneNumber: phoneNumber)
                        mentions.append(mention)
                    }
                    print("Autocompleted: `", substring, "` with context: ", context)
                }
            }
            
        }
        
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
        
        var links:[String] = []
        
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let matches = detector.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
            
            for match in matches {
                guard let range = Range(match.range, in: content) else { continue }
                let url = content[range]
                links.append(url.description)
                print(url)
            }
        }
        
        // 1
        let message = HwMessage(content: content, mentions: mentions, links: links)
        
        // 2
        save(message)
        
        // 3
        inputBar.inputTextView.text = ""
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) {
        // Adjust content insets
        print(size)
        messagesCollectionView.contentInset.bottom = size.height + 300 // keyboard size estimate
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {}

extension ChatViewController: AutocompleteManagerDelegate, AutocompleteManagerDataSource {
    
    // MARK: - AutocompleteManagerDataSource
    
    func autocompleteManager(_ manager: AutocompleteManager, autocompleteSourceFor prefix: String) -> [AutocompleteCompletion] {
        
        if prefix == "@" {
            var autocompletes:[AutocompleteCompletion] = members
                //                .filter { $0.phoneNumber != phoneNumber }
                .map { user in
                    return AutocompleteCompletion(text: user.fullName,
                                                  context: ["uid": user.uid,
                                                            "phoneNumber": user.phoneNumber])
                }
            autocompletes.append(contentsOf: autocompletes)
            autocompletes.append(contentsOf: autocompletes)
            return autocompletes
        }
        return []
    }
    
    func autocompleteManager(_ manager: AutocompleteManager, tableView: UITableView, cellForRowAt indexPath: IndexPath, for session: AutocompleteSession) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AutocompleteCell.reuseIdentifier, for: indexPath) as? AutocompleteCell else {
            fatalError("Oops, some unknown error occurred")
        }
        //        let users = SampleData.shared.users
        //        let name = session.completion?.text ?? ""
        //        let user = users.filter { return $0.name == name }.first
        //        cell.imageView?.image = user?.image
        cell.textLabel?.attributedText = manager.attributedText(matching: session, fontSize: 15)
        return cell
    }
    
    // MARK: - AutocompleteManagerDelegate
    
    func autocompleteManager(_ manager: AutocompleteManager, shouldBecomeVisible: Bool) {
        setAutocompleteManager(active: shouldBecomeVisible)
    }
    
    // Optional
    func autocompleteManager(_ manager: AutocompleteManager, shouldRegister prefix: String, at range: NSRange) -> Bool {
        return true
    }
    
    // Optional
    func autocompleteManager(_ manager: AutocompleteManager, shouldUnregister prefix: String) -> Bool {
        return true
    }
    
    // Optional
    func autocompleteManager(_ manager: AutocompleteManager, shouldComplete prefix: String, with text: String) -> Bool {
        return true
    }
    
    // MARK: - AutocompleteManagerDelegate Helper
    
    func setAutocompleteManager(active: Bool) {
        let topStackView = messageInputBar.topStackView
        if active && !topStackView.arrangedSubviews.contains(autocompleteManager.tableView) {
            print("AutocompleteManagerDelegate autocompleteManager.tableView height")
            topStackView.insertArrangedSubview(autocompleteManager.tableView, at: topStackView.arrangedSubviews.count)
            topStackView.layoutIfNeeded()
        } else if !active && topStackView.arrangedSubviews.contains(autocompleteManager.tableView) {
            topStackView.removeArrangedSubview(autocompleteManager.tableView)
            topStackView.layoutIfNeeded()
        }
        messageInputBar.invalidateIntrinsicContentSize()
    }
}

