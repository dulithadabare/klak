//
//  HwThreadListItem+CoreDataProperties.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-24.
//
//

import Foundation
import CoreData


extension HwThreadListItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HwThreadListItem> {
        return NSFetchRequest<HwThreadListItem>(entityName: "HwThreadListItem")
    }

    @NSManaged public var groupId: String?
    @NSManaged public var lastMessageAuthorUid: String?
    @NSManaged public var lastMessageDate: Date?
    @NSManaged public var lastMessageId: String?
    @NSManaged public var lastMessageSearchableText: String?
    @NSManaged public var lastMessageSender: String?
    @NSManaged public var lastMessageStatusRawValue: Int16
    @NSManaged public var lastMessageText: NSAttributedString?
    @NSManaged public var threadId: String?
    @NSManaged public var unreadCount: Int16
    @NSManaged public var lastMessageType: Int16
    @NSManaged public var thread: HwChatThread?

}

extension HwThreadListItem : Identifiable {

}
