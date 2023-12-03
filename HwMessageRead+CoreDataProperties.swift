//
//  HwMessageRead+CoreDataProperties.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-10.
//
//

import Foundation
import CoreData


extension HwMessageRead {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HwMessageRead> {
        return NSFetchRequest<HwMessageRead>(entityName: "HwMessageRead")
    }

    @NSManaged public var messageId: String?
    @NSManaged public var userUid: String?
    @NSManaged public var phoneNumber: String?

}

extension HwMessageRead : Identifiable {

}
