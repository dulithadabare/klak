//
//  ChatMessageModel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-03.
//

import Foundation

struct AddMessageModel {
    var id: String
    let author: String
    let sender: String
    let timestamp: Date
    let channel: String?
    let group: String
    var message: HwMessage
    var thread: String?
    var replyingInThreadTo: String?
    let senderPublicKey: String
    var isOutgoingMessage: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, author, sender, timestamp, channel, group, message, thread, replyingInThreadTo, senderPublicKey
    }
}

extension AddMessageModel: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        author = try values.decode(String.self, forKey: .author)
        sender = try values.decode(String.self, forKey: .sender)
        
        let timestampString = try values.decode(String.self, forKey: .timestamp)
        timestamp = MessageDateFormatter.shared.getDateFrom(DateString8601: timestampString)!
        channel = try? values.decode(String.self, forKey: .channel)
        group = try values.decode(String.self, forKey: .group)
        message = try values.decode(HwMessage.self, forKey: .message)
        thread = try? values.decode(String.self, forKey: .thread)
        replyingInThreadTo = try? values.decode(String.self, forKey: .replyingInThreadTo)
        senderPublicKey = try values.decode(String.self, forKey: .senderPublicKey)
    }
}

extension AddMessageModel: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(author, forKey: .author)
        try container.encode(sender, forKey: .sender)
        let iso8601Timestamp = MessageDateFormatter.shared.iso8601FormatterWithMilliseconds.string(from: timestamp)
        
        try container.encode(iso8601Timestamp , forKey: .timestamp)
        try container.encode(channel   , forKey: .channel)
        try container.encode(group , forKey: .group)
        try container.encode(message   , forKey: .message)
        try container.encode(thread, forKey: .thread)
        try container.encode(replyingInThreadTo, forKey: .replyingInThreadTo)
        try container.encode(senderPublicKey, forKey: .senderPublicKey)
    }
}
