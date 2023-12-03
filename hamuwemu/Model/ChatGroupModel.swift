//
//  ChatGroupModel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-11.
//

import Foundation

struct ChatGroupModel {
    var author: String
    var group: String
    var groupName: String
    let isChat: Bool
    var members: [String: AppUser] = [:]
    var defaultChannel: AddChannelModel
    var isTemp = false
}

extension ChatGroupModel {
    static var preview: ChatGroupModel = {
        let group = SampleData.shared.groupId
        let channelUid = SampleData.shared.channelId
        let defaultChannel = AddChannelModel(channelUid: channelUid, title: "General", group: group)
        return ChatGroupModel(author: UUID().uuidString, group: group, groupName: "+16505553535", isChat: true, defaultChannel: defaultChannel)
    }()
}
