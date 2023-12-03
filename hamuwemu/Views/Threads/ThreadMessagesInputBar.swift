//
//  ThreadMessagesInputBar.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-24.
//

import Foundation

import InputBarAccessoryView

final class ThreadMessagesInputBar: InputBarAccessoryView {
    weak var channelInputBarDelegate: MessagesInputBarViewDelegate?
    
    var members: [AppUser] = []
    var contactRepository: ContactRepository?
    var autocompleteDataModel: AutocompleteDataModel?
    
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
    
    init(contactRepository: ContactRepository, dataModel: AutocompleteDataModel) {
        self.contactRepository = contactRepository
        self.autocompleteDataModel = dataModel
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
        print("ChannelInputBar: Configuring autocomplete")
        
        inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
        inputTextView.layer.borderColor = UIColor.systemGroupedBackground.cgColor
        inputTextView.layer.backgroundColor = UIColor.secondarySystemGroupedBackground.cgColor
        inputTextView.layer.borderWidth = 1.0
        inputTextView.layer.cornerRadius = 16.0
        inputTextView.layer.masksToBounds = true
        inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        // Configure AutocompleteManager
        autocompleteManager.register(prefix: "@", with: mentionTextAttributes)
        autocompleteManager.maxSpaceCountDuringCompletion = 1 // Allow for autocompletes with a space
        
        // Set plugins
        self.inputPlugins = [autocompleteManager]
    }
    
}

extension ThreadMessagesInputBar: HwAutocompleteManagerDelegate, HwAutocompleteManagerDataSource {
    
    // MARK: - AutocompleteManagerDataSource
    
    func autocompleteManager(_ manager: HwAutocompleteManager, autocompleteSourceFor prefix: String) -> [AutocompleteCompletion] {
        if prefix == "@" {
//            print("ChannelInputBar: Generating autocomplete member count \(chat.members.count)")
            let autoCompletionArray: [AutocompleteCompletion] = members
                .filter { $0.phoneNumber != AuthenticationService.shared.phoneNumber! }
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
