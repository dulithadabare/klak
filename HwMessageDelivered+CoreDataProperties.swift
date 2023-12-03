//
//  HwMessageDelivered+CoreDataProperties.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-10.
//
//

import Foundation
import CoreData


extension HwMessageDelivered {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HwMessageDelivered> {
        return NSFetchRequest<HwMessageDelivered>(entityName: "HwMessageDelivered")
    }

    @NSManaged public var messageId: String?
    @NSManaged public var userUid: String?
    @NSManaged public var phoneNumber: String?

}

extension HwMessageDelivered : Identifiable {

}
