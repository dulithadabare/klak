//
//  SystemMessageCell.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/16/21.
//

import Foundation
import UIKit
import MessageKit

class SystemMessageCell: UICollectionViewCell {
    let label = UILabel()
    
//    lazy var messageText = Label()
//    .variant(.regular(.small))
//    .color(.gray)
//    .align(.center)
    
    public override init(frame: CGRect) {
            super.init(frame: frame)
            setupSubviews()
        }
    
    public required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            setupSubviews()
        }
    
    open func setupSubviews() {
        contentView.addSubview(label)
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        label.textColor = .gray
    }
        
    open override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = contentView.bounds
    }
        
    open func configure(with message: MessageKit.MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        // Do stuff
        switch message.kind {
        case .custom(let data):
            guard let systemMessage = data as? String else { return }
            label.text = systemMessage
        default:
            break
        }
    }

//  override func setupView() {
//    addSubview(messageText)
//  }
//
//  override func setupConstraints() {
//    messageText.snp.makeConstraints { $0.edges.equalToSuperview() }
//  }

//  override func update() {
//    guard let item = item else { return }
//    switch item.kind {
//    case .custom(let kind):
//      guard let kind = kind as? ChatMessageViewModel.Kind else { return }
//      switch kind {
//      case .system(let systemMessage):
//        messageText.text = systemMessage
//      }
//    default:
//      break
//    }
//  }
}
