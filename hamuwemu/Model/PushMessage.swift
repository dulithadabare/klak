//
//  PushMessage.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-01.
//

import Foundation

struct ServerPush {
    var id: String
    var type: PushType
    var data: Any
}

extension ServerPush: Decodable {
    enum CodingKeys: CodingKey {
        case id, type, data
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        let pushType = try values.decode(Int.self, forKey: .type)
        type = PushType(rawValue: pushType)!
        switch type {
        case .addGroup:
            data = try values.decode(AddGroupModel.self, forKey: .data)
            break
        case .addThread:
            data = try values.decode(AddThreadModel.self, forKey: .data)
        case .addMessage:
            data = try values.decode(AddMessageModel.self, forKey: .data)
        case .changeGroupName:
            // data will be new name
            data = try values.decode(AddGroupNameModel.self, forKey: .data)
        case .addGroupMember:
            data = try values.decode(AppGroupMember.self, forKey: .data)
        case .removeGroupMember:
            data = try values.decode(AppGroupMember.self, forKey: .data)
        case .systemMessage:
            data = try values.decode(AddSystemMessageModel.self, forKey: .data)
        case .receipt:
            data = try values.decode(MessageReceiptModel.self, forKey: .data)
        case .reply:
            data = try values.decode(ClientReplyModel.self, forKey: .data)
        case .chatId:
            data = try values.decode(ChatIdModel.self, forKey: .data)
        case .appContact:
            data = try values.decode(AppUser.self, forKey: .data)
        case .updateThreadTitle:
            data = try values.decode(UpdateThreadTitleModel.self, forKey: .data)
        }
    }
}
