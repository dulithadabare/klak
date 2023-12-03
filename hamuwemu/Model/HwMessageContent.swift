//
//  HwMessageContent.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/28/21.
//

import Foundation

class HwMessageContent: NSSecureCoding {
    static var supportsSecureCoding: Bool = true
    
    func encode(with coder: NSCoder) {
        coder.encode(sender, forKey: "sender")
        coder.encode(content, forKey: "content")
        coder.encode(mentions, forKey: "mentions")
        coder.encode(links, forKey: "links")
    }
    
    required init?(coder: NSCoder) {
        let allowedClasses = NSSet(objects: NSArray.classForCoder(), HwMention.self)
        guard
            let sender = coder.decodeObject(of: [NSString.self], forKey: "sender") as? String,
            let content = coder.decodeObject(of: [NSString.self], forKey: "content") as? String,
//            let mentions = coder.decodeObject(of: allowedClasses, forKey: "mentions") as? [HwMention],
        let links = coder.decodeObject(of: [NSString.self], forKey: "links") as? [String]
            
        else {
            return nil
        }
        
        self.sender = sender
        self.sender = content
//        self.mentions = mentions
        self.links = links
    }
    
    var sender: String = ""
    var content: String = ""
    var mentions: [HwMention] = []
    var links: [String] = []
    
    init(from message: HwMessage) {
        sender = "message.sender"
        content = message.content ?? ""
//        mentions = message.mentions
        links = message.links
    }
}
