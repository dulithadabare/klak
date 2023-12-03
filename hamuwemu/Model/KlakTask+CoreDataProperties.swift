//
//  KlakTask+CoreDataProperties.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-09-06.
//
//

import Foundation
import CoreData


extension KlakTask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<KlakTask> {
        return NSFetchRequest<KlakTask>(entityName: "KlakTask")
    }

    @NSManaged public var assignedBy: String?
    @NSManaged public var assignedTo: String?
    @NSManaged public var dueDate: Date?
    @NSManaged public var groupUid: String?
    @NSManaged public var isUrgent: Bool
    @NSManaged public var message: NSAttributedString?
    @NSManaged public var taskId: String?
    @NSManaged public var title: String?
    @NSManaged public var latestStatusRawValue: Int16
    @NSManaged public var unreadCount: Int16
    @NSManaged public var isMarkedToday: Bool
    @NSManaged public var logItems: NSSet?

}

// MARK: Generated accessors for logItems
extension KlakTask {

    @objc(addLogItemsObject:)
    @NSManaged public func addToLogItems(_ value: KlakTaskLogItem)

    @objc(removeLogItemsObject:)
    @NSManaged public func removeFromLogItems(_ value: KlakTaskLogItem)

    @objc(addLogItems:)
    @NSManaged public func addToLogItems(_ values: NSSet)

    @objc(removeLogItems:)
    @NSManaged public func removeFromLogItems(_ values: NSSet)

}

extension KlakTask : Identifiable {

}
