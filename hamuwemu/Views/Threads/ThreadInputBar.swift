//
//  ThreadInputBar.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/23/21.
//

import InputBarAccessoryView

protocol AutocompleteViewDelegate: AnyObject {
    func showAutocompleteView(_ value: Bool)
}

final class ThreadInputBar: InputBarAccessoryView {
    var chat: ChatGroup?
    var contactRepository: ContactRepository?
    var autocompleteDataModel: AutocompleteDataModel?
    weak var autocompleteViewDelegate: AutocompleteViewDelegate?
    
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
    
    init(chat: ChatGroup, contactRepository: ContactRepository, dataModel: AutocompleteDataModel) {
        self.chat = chat
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
        // Configure AutocompleteManager
        autocompleteManager.register(prefix: "@", with: mentionTextAttributes)
        autocompleteManager.maxSpaceCountDuringCompletion = 1 // Allow for autocompletes with a space
        
        // Set plugins
        self.inputPlugins = [autocompleteManager]
    }
}

extension ThreadInputBar: HwAutocompleteManagerDelegate, HwAutocompleteManagerDataSource {
    // MARK: - AutocompleteManagerDataSource
    
    func autocompleteManager(_ manager: HwAutocompleteManager, autocompleteSourceFor prefix: String) -> [AutocompleteCompletion] {
        if prefix == "@", let chat = chat {
            let autoCompletionArray: [AutocompleteCompletion] = chat.members.values
                .filter { $0.phoneNumber != AuthenticationService.shared.phoneNumber! }
                .map { user in
                    let fullName = contactRepository?.getFullName(for: user.phoneNumber) ?? user.phoneNumber
                    return AutocompleteCompletion(text: fullName,
                                                  context: ["uid": user.uid,
                                                            "phoneNumber": user.phoneNumber])
                }
    
            print("InputBar: autocomplete member count \(autoCompletionArray.count)")
            return autoCompletionArray
        }
        return []
    }
    
    func autocompleteManager(_ manager: HwAutocompleteManager, tableView: UITableView, cellForRowAt indexPath: IndexPath, for session: HwAutocompleteSession) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AutocompleteCell.reuseIdentifier, for: indexPath) as? AutocompleteCell else {
            fatalError("Oops, some unknown error occurred")
        }
        cell.textLabel?.attributedText = manager.attributedText(matching: session, fontSize: 15)
        return cell
    }
    
    // MARK: - AutocompleteManagerDelegate
    
    func autocompleteManager(_ manager: HwAutocompleteManager, shouldBecomeVisible: Bool) {
        autocompleteViewDelegate?.showAutocompleteView(shouldBecomeVisible)
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
}
