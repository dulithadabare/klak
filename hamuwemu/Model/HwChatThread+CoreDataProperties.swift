//
//  HwChatThread+CoreDataProperties.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-04-21.
//
//

import Foundation
import CoreData


extension HwChatThread {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HwChatThread> {
        return NSFetchRequest<HwChatThread>(entityName: "HwChatThread")
    }

    @NSManaged public var groupId: String?
    @NSManaged public var isReplyingTo: Bool
    @NSManaged public var isTemp: Bool
    @NSManaged public var replyingTo: String?
    @NSManaged public var threadId: String?
    @NSManaged public var titleText: NSAttributedString?
    @NSManaged public var timestamp: Date?
    @NSManaged public var group: HwChatGroup?
    @NSManaged public var threadListItem: HwThreadListItem?

}

extension HwChatThread : Identifiable {

}
