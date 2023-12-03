//
//  ChannelInputBarView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/16/21.
//

import SwiftUI
import InputBarAccessoryView

final class ChannelInputBar: InputBarAccessoryView {
    weak var channelInputBarDelegate: MessagesInputBarViewDelegate?
    
    var chat: ChatGroup?
    var contactRepository: ContactRepository?
    var autocompleteDataModel: AutocompleteDataModel?
    var showAutocompleteView: Binding<Bool> = .constant(false)
    var sendMessageInThread: Bool = false
    
    private let mentionTextAttributes: [NSAttributedString.Key : Any] = [
        .font: UIFont.preferredFont(forTextStyle: .body),
        .foregroundColor: UIColor.systemBlue,
        .backgroundColor: UIColor.systemBlue.withAlphaComponent(0.1)
    ]
    
    lazy var autocompleteManager: HwAutocompleteManager = { [unowned self] in
        let manager = HwAutocompleteManager(for: self.inputTextView, with: autocompleteDataModel!)
        manager.delegate = self
        manager.dataSource = self
        return manager
    }()
    
    init(chat: ChatGroup, contactRepository: ContactRepository, dataModel: AutocompleteDataModel, showAutocompleteView: Binding<Bool> = .constant(true)) {
        self.chat = chat
        self.contactRepository = contactRepository
        self.autocompleteDataModel = dataModel
        self.showAutocompleteView = showAutocompleteView
        super.init(frame: .zero)
        configure()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        let button = InputBarButtonItem(type: .system)
        
        button.onSelected { item in
            self.channelInputBarDelegate?.showImagePicker()
        }
        
        button.setSize(CGSize(width: 60, height: 30), animated: false)
        button.setImage(UIImage(systemName: "plus.square")!.withRenderingMode(.alwaysTemplate), for: .normal)
//        button.imageView?.contentMode = .scaleToFill
//        button.tintColor = .systemBlue
//        button.isEnabled = false
        
        inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
        inputTextView.layer.borderColor = UIColor.systemGroupedBackground.cgColor
        inputTextView.layer.backgroundColor = UIColor.secondarySystemGroupedBackground.cgColor
        inputTextView.layer.borderWidth = 1.0
        inputTextView.layer.cornerRadius = 16.0
        inputTextView.layer.masksToBounds = true
        inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        leftStackView.alignment = .center
        setLeftStackViewWidthConstant(to: 50, animated: false)
        setStackViewItems([button], forStack: .left, animated: false)
//
//        shouldAnimateTextDidChangeLayout = true
        
        print("ChannelInputBar: Configuring autocomplete")
        
        // Configure AutocompleteManager
        autocompleteManager.register(prefix: "@", with: mentionTextAttributes)
        autocompleteManager.maxSpaceCountDuringCompletion = 1 // Allow for autocompletes with a space
        
        // Set plugins
        self.inputPlugins = [autocompleteManager]
    }
    
}

struct ChannelInputBarView: UIViewRepresentable {
    @Binding
    var showAutocompleteView: Bool
    
    @Binding
    var size: CGSize
    
    var chat: ChatGroup
    var channel: ChatChannel
    var contactRepository: ContactRepository
    var dataModel: AutocompleteDataModel
    
    @Binding
    var replyMessage: ChatMessage?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> InputBarAccessoryView {
        let bar = ChannelInputBar(chat: chat, contactRepository: contactRepository, dataModel: dataModel, showAutocompleteView: $showAutocompleteView)
//        bar.setContentHuggingPriority(.required, for: .vertical)
//        bar.setContentHuggingPriority(.defaultHigh, for: .vertical)
        bar.delegate = context.coordinator
        DispatchQueue.main.async {
            bar.inputTextView.placeholderLabel.text = String()
        }
        return bar
    }
    
    func updateUIView(_ uiView: InputBarAccessoryView, context: Context) {
        print("ChannelInputBarView: updating view \(replyMessage?.id ?? "nil")")
        context.coordinator.control = self
    }
    
    func onSendPerform(_ message: HwMessage) {
        if !chat.isTemp, !channel.isTemp {
            ChatRepository.sendMessage(message: message, channel: channel.channelUid, channelName: channel.title, group: chat.group, groupName: chat.groupName, isChat: chat.isChat, replyMessage: replyMessage)
            
        } else if let group = ChatRepository.addGroup(chat){

            ChatRepository.addChannel(channel)
            ChatRepository.sendMessage(message: message, channel: channel.channelUid, channelName: channel.title, group: group, groupName: chat.groupName, isChat: chat.isChat, replyMessage: replyMessage)
        }
        
        //hide replyview
        if replyMessage != nil {
            replyMessage = nil
        }
    }
    
    class Coordinator {
        
        var control: ChannelInputBarView
        
        init(_ control: ChannelInputBarView) {
            self.control = control
        }
    }
}

extension ChannelInputBarView.Coordinator: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) {
        print("ChannelInputBar: Coordinator size changed \(size)")
        control.size = size
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let message = getMessage(from: inputBar.inputTextView.attributedText!, with: text)
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
        print("ChannelInputBarView: \(control.replyMessage?.id ?? "nil" )")
        control.onSendPerform(message)
        inputBar.inputTextView.text = ""
    }
}

extension ChannelInputBar: HwAutocompleteManagerDelegate, HwAutocompleteManagerDataSource {
    
    // MARK: - AutocompleteManagerDataSource
    
    func autocompleteManager(_ manager: HwAutocompleteManager, autocompleteSourceFor prefix: String) -> [AutocompleteCompletion] {
        if prefix == "@", let chat = chat {
//            print("ChannelInputBar: Generating autocomplete member count \(chat.members.count)")
            let autoCompletionArray: [AutocompleteCompletion] = chat.members.values
//                .filter { $0.phoneNumber != AuthenticationService.shared.phoneNumber! }
                .map { user in
                    let fullName = contactRepository?.getFullName(for: user.phoneNumber) ?? user.phoneNumber
                    return AutocompleteCompletion(text: fullName,
                                                  context: ["uid": user.uid,
                                                            "phoneNumber": user.phoneNumber])
                }
    
            print("ChannelInputBar: autocomplete member count \(autoCompletionArray.count)")
            return autoCompletionArray
        }
        return []
    }
    
    func autocompleteManager(_ manager: HwAutocompleteManager, tableView: UITableView, cellForRowAt indexPath: IndexPath, for session: HwAutocompleteSession) -> UITableViewCell {
        
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
    
    func autocompleteManager(_ manager: HwAutocompleteManager, shouldBecomeVisible: Bool) {
        showAutocompleteView.wrappedValue = shouldBecomeVisible
        channelInputBarDelegate?.showAutocompleteView(shouldBecomeVisible)
        self.invalidateIntrinsicContentSize()
    }
    
    // Optional
    func autocompleteManager(_ manager: HwAutocompleteManager, shouldRegister prefix: String, at range: NSRange) -> Bool {
        return true
    }
    
    // Optional
    func autocompleteManager(_ manager: HwAutocompleteManager, shouldUnregister prefix: String) -> Bool {
        return true
    }
    
    // Optional
    func autocompleteManager(_ manager: HwAutocompleteManager, shouldComplete prefix: String, with text: String) -> Bool {
        return true
    }
    
    // MARK: - AutocompleteManagerDelegate Helper
    
    func setAutocompleteManager(active: Bool) {
        print("AutocompleteManagerDelegate autocompleteManager.tableView height \(autocompleteManager.tableView.frame.height)")
        let topStackView = self.topStackView
        if active && !topStackView.arrangedSubviews.contains(autocompleteManager.tableView) {
            topStackView.insertArrangedSubview(autocompleteManager.tableView, at: topStackView.arrangedSubviews.count)
            topStackView.layoutIfNeeded()
            
        } else if !active && topStackView.arrangedSubviews.contains(autocompleteManager.tableView) {
            topStackView.removeArrangedSubview(autocompleteManager.tableView)
            topStackView.layoutIfNeeded()
        }
        self.invalidateIntrinsicContentSize()
    }
}
