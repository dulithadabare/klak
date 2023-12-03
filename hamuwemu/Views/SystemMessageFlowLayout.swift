//
//  SystemMessageFlowLayout.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/16/21.
//

import Foundation
import MessageKit

class SystemMessageFlowLayout: MessagesCollectionViewFlowLayout {
  lazy open var sizeCalculator = SystemMessageSizeCalculator(layout: self)

  override open func cellSizeCalculatorForItem(at indexPath: IndexPath) -> CellSizeCalculator {
    let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
    if case .custom = message.kind {
      return sizeCalculator
    }
    return super.cellSizeCalculatorForItem(at: indexPath);
  }
}
