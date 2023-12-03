//
//  HwChatGroup+CoreDataProperties.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-07.
//
//

import Foundation
import CoreData


extension HwChatGroup {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HwChatGroup> {
        return NSFetchRequest<HwChatGroup>(entityName: "HwChatGroup")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var groupId: String?
    @NSManaged public var groupName: String?
    @NSManaged public var isChat: Bool
    @NSManaged public var isTemp: Bool
    @NSManaged public var lastMessageText: NSAttributedString?
    @NSManaged public var chatListItem: HwChatListItem?
    @NSManaged public var defaultChannel: HwChatChannel?
    @NSManaged public var threads: NSSet?

}

// MARK: Generated accessors for threads
extension HwChatGroup {

    @objc(addThreadsObject:)
    @NSManaged public func addToThreads(_ value: HwChatThread)

    @objc(removeThreadsObject:)
    @NSManaged public func removeFromThreads(_ value: HwChatThread)

    @objc(addThreads:)
    @NSManaged public func addToThreads(_ values: NSSet)

    @objc(removeThreads:)
    @NSManaged public func removeFromThreads(_ values: NSSet)

}

extension HwChatGroup : Identifiable {

}
