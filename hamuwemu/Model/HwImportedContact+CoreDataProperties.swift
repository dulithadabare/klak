//
//  HwImportedContact+CoreDataProperties.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-30.
//
//

import Foundation
import CoreData


extension HwImportedContact {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HwImportedContact> {
        return NSFetchRequest<HwImportedContact>(entityName: "HwImportedContact")
    }

    @NSManaged public var phoneNumber: String?
    @NSManaged public var displayName: String?

}

extension HwImportedContact : Identifiable {

}
