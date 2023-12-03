//
//  HwGroupMember+CoreDataProperties.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-01-17.
//
//

import Foundation
import CoreData


extension HwGroupMember {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HwGroupMember> {
        return NSFetchRequest<HwGroupMember>(entityName: "HwGroupMember")
    }

    @NSManaged public var groupId: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var uid: String?

}

extension HwGroupMember : Identifiable {

}
