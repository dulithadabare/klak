//
//  HwChatListItem+CoreDataProperties.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-24.
//
//

import Foundation
import CoreData


extension HwChatListItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HwChatListItem> {
        return NSFetchRequest<HwChatListItem>(entityName: "HwChatListItem")
    }

    @NSManaged public var channelId: String?
    @NSManaged public var channelName: String?
    @NSManaged public var groupId: String?
    @NSManaged public var groupName: String?
    @NSManaged public var isChat: Bool
    @NSManaged public var isTemp: Bool
    @NSManaged public var lastMessageAttrText: NSAttributedString?
    @NSManaged public var lastMessageAuthorUid: String?
    @NSManaged public var lastMessageDate: Date?
    @NSManaged public var lastMessageId: String?
    @NSManaged public var lastMessageSender: String?
    @NSManaged public var lastMessageStatus: String?
    @NSManaged public var lastMessageStatusRawValue: Int16
    @NSManaged public var lastMessageText: String?
    @NSManaged public var threadId: String?
    @NSManaged public var threadName: String?
    @NSManaged public var threadUnreadCount: Int16
    @NSManaged public var unreadCount: Int16
    @NSManaged public var userPhoto: Data?
    @NSManaged public var lastMessageType: Int16
    @NSManaged public var group: HwChatGroup?
    @NSManaged public var thread: HwChatThread?

}

extension HwChatListItem : Identifiable {

}
