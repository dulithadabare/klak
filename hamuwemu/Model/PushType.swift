//
//  PushType.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-31.
//

import Foundation

public enum PushType: Int {
    case addGroup
    case addThread
    case addMessage
    case receipt
//    case deliveredReceipt = 4
//    case readReceipt = 5
//    case sentReceipt = 6
    case changeGroupName
    case addGroupMember
    case removeGroupMember
    case systemMessage
    case reply
    case chatId
    case appContact
    case updateThreadTitle
//    case threadReplyToChannelMessage = 11
}
