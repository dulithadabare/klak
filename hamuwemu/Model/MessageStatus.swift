//
//  MessageStatus.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-04-12.
//

import Foundation

enum MessageStatus: Int16 {
    case none, sent, delivered, read
    case errorSendingMessage = -1
    case errorSendingMessageWithGroup = -2
    case errorSendingMessageWithGroupAndThread = -3
    case errorSendingMessageWithThread = -4
}
