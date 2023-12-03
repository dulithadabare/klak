//
//  SystemMessageModel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-04.
//

import Foundation


enum SystemMessageType: Int {
    case addThread = 1
    case addThreadInReply = 2
    case addGroupMember = 3
    case removeGroupMember = 4
    case changeGroupName = 5
    case changeThreadName = 6
}

struct AddSystemMessageModel {
    var id: String
    let type: SystemMessageType
    let channel: String?
    let group: String
    var thread: String?
    var message: HwMessage
    var context: Any?
    var timestamp: Date
    
    enum CodingKeys: CodingKey {
        case id, type, group, channel, thread, message, context, timestamp
    }
}

extension AddSystemMessageModel: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        channel = try? values.decode(String.self, forKey: .channel)
        group = try values.decode(String.self, forKey: .group)
        thread = try? values.decode(String.self, forKey: .thread)
        message = try values.decode(HwMessage.self, forKey: .message)
        let timestampString = try values.decode(String.self, forKey: .timestamp)
        timestamp = MessageDateFormatter.shared.getDateFrom(DateString8601: timestampString)!
        let pushType = try values.decode(Int.self, forKey: .type)
        type = SystemMessageType(rawValue: pushType)!
        switch type {
        case .addThread:
            context = try values.decode(AddThreadContext.self, forKey: .context)
        case .addThreadInReply:
            context = try values.decode(AddThreadContext.self, forKey: .context)
        default:
            context = nil
        }
    }
}

struct AddThreadContext: Decodable {
    let threadUid: String
    let threadTitle: HwMessage
}
