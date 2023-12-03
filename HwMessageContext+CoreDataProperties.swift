//
//  HwMessageContext+CoreDataProperties.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-10.
//
//

import Foundation
import CoreData


extension HwMessageContext {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HwMessageContext> {
        return NSFetchRequest<HwMessageContext>(entityName: "HwMessageContext")
    }

    @NSManaged public var messageId: String?
    @NSManaged public var message: HwChatMessage?

}

extension HwMessageContext : Identifiable {

}
