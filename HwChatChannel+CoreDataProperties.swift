//
//  HwChatChannel+CoreDataProperties.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-01-20.
//
//

import Foundation
import CoreData


extension HwChatChannel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HwChatChannel> {
        return NSFetchRequest<HwChatChannel>(entityName: "HwChatChannel")
    }

    @NSManaged public var channelId: String?
    @NSManaged public var channelName: String?
    @NSManaged public var group: HwChatGroup?

}

extension HwChatChannel : Identifiable {

}
