//
//  SystemMessageSizeCalculator.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/16/21.
//

import Foundation
import MessageKit

class SystemMessageSizeCalculator: MessageSizeCalculator {
  override func messageContainerSize(for message: MessageKit.MessageType) -> CGSize {
    // Just return a fixed height.
    return CGSize(width: UIScreen.main.bounds.width, height: 20)
  }
}
