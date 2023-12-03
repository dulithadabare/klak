//
//  HwChatMessage+CoreDataProperties.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-18.
//
//

import Foundation
import CoreData


extension HwChatMessage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HwChatMessage> {
        return NSFetchRequest<HwChatMessage>(entityName: "HwChatMessage")
    }

    @NSManaged public var author: String?
    @NSManaged public var channelName: String?
    @NSManaged public var channelUid: String?
    @NSManaged public var groupName: String?
    @NSManaged public var groupUid: String?
    @NSManaged public var imageDocumentUrl: String?
    @NSManaged public var imageDownloadUrl: String?
    @NSManaged public var imageThumbnailBase64: String?
    @NSManaged public var isChat: Bool
    @NSManaged public var isReadByMe: Bool
    @NSManaged public var isSystemMessage: Bool
    @NSManaged public var isThreadMessage: Bool
    @NSManaged public var messageId: String?
    @NSManaged public var replyCount: Int16
    @NSManaged public var replyingThreadId: String?
    @NSManaged public var searchableText: String?
    @NSManaged public var sender: String?
    @NSManaged public var status: String?
    @NSManaged public var statusRawValue: Int16
    @NSManaged public var systemMessageType: Int16
    @NSManaged public var text: NSAttributedString?
    @NSManaged public var threadName: String?
    @NSManaged public var threadUid: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var senderPublicKey: String?
    @NSManaged public var context: HwMessageContext?
    @NSManaged public var replies: NSOrderedSet?
    @NSManaged public var replyingTo: HwChatMessage?

}

// MARK: Generated accessors for replies
extension HwChatMessage {

    @objc(insertObject:inRepliesAtIndex:)
    @NSManaged public func insertIntoReplies(_ value: HwChatMessage, at idx: Int)

    @objc(removeObjectFromRepliesAtIndex:)
    @NSManaged public func removeFromReplies(at idx: Int)

    @objc(insertReplies:atIndexes:)
    @NSManaged public func insertIntoReplies(_ values: [HwChatMessage], at indexes: NSIndexSet)

    @objc(removeRepliesAtIndexes:)
    @NSManaged public func removeFromReplies(at indexes: NSIndexSet)

    @objc(replaceObjectInRepliesAtIndex:withObject:)
    @NSManaged public func replaceReplies(at idx: Int, with value: HwChatMessage)

    @objc(replaceRepliesAtIndexes:withReplies:)
    @NSManaged public func replaceReplies(at indexes: NSIndexSet, with values: [HwChatMessage])

    @objc(addRepliesObject:)
    @NSManaged public func addToReplies(_ value: HwChatMessage)

    @objc(removeRepliesObject:)
    @NSManaged public func removeFromReplies(_ value: HwChatMessage)

    @objc(addReplies:)
    @NSManaged public func addToReplies(_ values: NSOrderedSet)

    @objc(removeReplies:)
    @NSManaged public func removeFromReplies(_ values: NSOrderedSet)

}

extension HwChatMessage : Identifiable {

}
