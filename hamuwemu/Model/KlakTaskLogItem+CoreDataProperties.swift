//
//  KlakTaskLogItem+CoreDataProperties.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-08-30.
//
//

import Foundation
import CoreData


extension KlakTaskLogItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<KlakTaskLogItem> {
        return NSFetchRequest<KlakTaskLogItem>(entityName: "KlakTaskLogItem")
    }

    @NSManaged public var itemId: String?
    @NSManaged public var message: NSAttributedString?
    @NSManaged public var createdBy: String?
    @NSManaged public var taskStatusRawValue: Int16
    @NSManaged public var pendingDueDate: Date?
    @NSManaged public var timestamp: Date?
    @NSManaged public var task: KlakTask?

}

extension KlakTaskLogItem : Identifiable {

}
