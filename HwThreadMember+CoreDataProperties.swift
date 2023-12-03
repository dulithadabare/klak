//
//  HwThreadMember+CoreDataProperties.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-01-20.
//
//

import Foundation
import CoreData


extension HwThreadMember {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HwThreadMember> {
        return NSFetchRequest<HwThreadMember>(entityName: "HwThreadMember")
    }

    @NSManaged public var phoneNumber: String?
    @NSManaged public var threadId: String?
    @NSManaged public var uid: String?

}

extension HwThreadMember : Identifiable {

}
