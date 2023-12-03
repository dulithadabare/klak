//
//  HwAddThreadMessageContext+CoreDataProperties.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-10.
//
//

import Foundation
import CoreData


extension HwAddThreadMessageContext {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HwAddThreadMessageContext> {
        return NSFetchRequest<HwAddThreadMessageContext>(entityName: "HwAddThreadMessageContext")
    }

    @NSManaged public var threadUid: String?
    @NSManaged public var threadTitle: NSAttributedString?

}
