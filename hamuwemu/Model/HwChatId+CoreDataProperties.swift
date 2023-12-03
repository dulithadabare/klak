//
//  HwChatId+CoreDataProperties.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-07.
//
//

import Foundation
import CoreData


extension HwChatId {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HwChatId> {
        return NSFetchRequest<HwChatId>(entityName: "HwChatId")
    }

    @NSManaged public var phoneNumber: String?
    @NSManaged public var groupId: String?

}

extension HwChatId : Identifiable {

}
