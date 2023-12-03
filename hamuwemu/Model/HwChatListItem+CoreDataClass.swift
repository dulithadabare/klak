//
//  HwChatListItem+CoreDataClass.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-04.
//
//

import Foundation
import CoreData

@objc(HwChatListItem)
public class HwChatListItem: NSManagedObject {
    static func getAttributedString(from message: HwMessage) -> NSAttributedString? {
        guard let content = message.content else {
            return nil
        }
        
            let attrString = NSMutableAttributedString(string: content)
            
            for mention in message.mentions {
                let context = ["uid": mention.uid,
                               "phoneNumber": mention.phoneNumber]
                attrString.addAttribute(.mention, value: URL(string: "mention:\(mention.uid)")!, range: mention.range)
                attrString.addAttribute(.mentionContext, value: context, range: mention.range)
            
            }
            
            return NSAttributedString(attributedString: attrString)
        }
}
