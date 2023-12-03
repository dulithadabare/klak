//
//  HwAppContact+CoreDataProperties.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-30.
//
//

import Foundation
import CoreData


extension HwAppContact {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HwAppContact> {
        return NSFetchRequest<HwAppContact>(entityName: "HwAppContact")
    }

    @NSManaged public var phoneNumber: String?
    @NSManaged public var uid: String?
    @NSManaged public var publicKey: Data?

}

extension HwAppContact : Identifiable {

}
