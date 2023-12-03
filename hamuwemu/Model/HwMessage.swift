//
//  HwMessage.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/18/21.
//

import Foundation

struct HwMessage {
//    let sender: String
    var content: String?
    let mentions: [Mention]
    var taskMentions: [Mention] = []
    let links: [String]
    var imageDocumentUrl: String?
    var imageDownloadUrl: String?
    var imageBlurHash: String?
    
    enum CodingKeys: String, CodingKey {
        case content, mentions, links, imageDocumentUrl, imageDownloadUrl, imageBlurHash
    }
}

extension HwMessage: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(content, forKey: .content)
        try container.encode(mentions, forKey: .mentions)
        try container.encode(links, forKey: .links)
        try container.encode(imageDocumentUrl, forKey: .imageDocumentUrl)
        try container.encode(imageDownloadUrl, forKey: .imageDownloadUrl)
        try container.encode(imageBlurHash, forKey: .imageBlurHash)
    }
}

extension HwMessage: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        content = try? values.decode(String.self, forKey: .content)
        mentions = (try? values.decode([Mention].self, forKey: .mentions)) ?? []
        links = (try? values.decode([String].self, forKey: .links)) ?? []
        imageDocumentUrl = try? values.decode(String.self, forKey: .imageDocumentUrl)
        imageDownloadUrl = try? values.decode(String.self, forKey: .imageDownloadUrl)
        imageBlurHash = try? values.decode(String.self, forKey: .imageBlurHash)
    }
}


extension HwMessage {
    //Preview
    init(){
//        self.sender = "Sender"
        self.content = "Content"
        mentions = []
        links = []
    }
    init(content: String, sender: String) {
//        self.sender = sender
        self.content = content
        mentions = []
        links = []
    }
    
    init?(dict: [String: Any]) {
        if 
         let content = dict["content"] as? String,
         let mentions = dict["mentions"] as? [[String: Any]]?,
         let links = dict["links"] as? [String]? {
//            self.sender = sender
            self.content = content
            self.mentions = mentions?.compactMap{Mention(dict: $0)} ?? []
            self.links = links ?? []
        } else {
            return nil
        }
    }
}

// MARK: - DatabaseRepresentation
extension HwMessage: DatabaseRepresentation {
    var representation: [String: Any] {
        let rep: [String: Any] = [
//            "sender": sender,
            "content": content,
            "mentions": mentions.map{$0.representation},
            "links": links
        ]
        
//        if let channel = channel {
//          rep["channel"] = channel
//        }

        return rep
    }
}
