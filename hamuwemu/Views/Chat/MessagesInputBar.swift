//
//  MessagesInputBar.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-17.
//

import Foundation
import InputBarAccessoryView

protocol MessagesInputBarViewDelegate: AnyObject {
    func sendModeChanged(_ value: Bool)
    func showAutocompleteView(_ value: Bool)
    func showImagePicker()
}

final class MessagesInputBar: InputBarAccessoryView {
    weak var messagesInputBarDelegate: MessagesInputBarViewDelegate?
    
    init() {
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
            self.messagesInputBarDelegate?.showImagePicker()
        }
        
        button.setSize(CGSize(width: 60, height: 30), animated: false)
        button.setImage(UIImage(systemName: "plus.square")!.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleToFill
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
        
        
        backgroundView.backgroundColor = UIColor.tertiarySystemGroupedBackground
    }
    
}
