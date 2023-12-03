//
//  ChatGroupModel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-09.
//

import Foundation

struct AddGroupModel {
    var author: String
    var group: String
    public var groupName: String
    let isChat: Bool
    var members: [String: AppUser] = [:]
    var defaultChannel: AddChannelModel
    var isTemp = false
    var unreadCount: UInt = 0
    
    public init(author: String, group: String, groupName: String, isChat: Bool, defaultChannel: AddChannelModel, members: [String: AppUser]) {
        self.author = author
        self.group = group
        self.groupName = groupName
        self.isChat = isChat
        self.defaultChannel = defaultChannel
        self.members = members
    }
    
    enum CodingKeys: CodingKey {
        case author, group, groupName, isChat, members, defaultChannel
    }
}

extension AddGroupModel: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        author = try values.decode(String.self, forKey: .author)
        group = try values.decode(String.self, forKey: .group)
        groupName = try values.decode(String.self, forKey: .groupName)
        isChat = try values.decode(Bool.self, forKey: .isChat)
        defaultChannel = try values.decode(AddChannelModel.self, forKey: .defaultChannel)
        members = try values.decode([String: AppUser].self, forKey: .members)
    }
}

extension AddGroupModel: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(author, forKey: .author)
        try container.encode(group, forKey: .group)
        try container.encode(groupName, forKey: .groupName)
        try container.encode(isChat, forKey: .isChat)
        try container.encode(defaultChannel, forKey: .defaultChannel)
        try container.encode(members, forKey: .members)
    }
}
