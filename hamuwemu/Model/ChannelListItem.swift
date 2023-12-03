//
//  Channel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/16/21.
//

import Foundation

struct ChannelListItem: Identifiable {
    var id: String
    let channel: ChatChannel
    let timestamp: Date
    let message: ChatMessage?
}

extension ChannelListItem {
    init(from channel: ChatChannel) {
        self.id = channel.channelUid
        self.channel = channel
        self.message = channel.message
        self.timestamp = channel.message?.timestamp ?? channel.timestamp
    }
}

// MARK: - Comparable
extension ChannelListItem: Hashable {
    static func == (lhs: ChannelListItem, rhs: ChannelListItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
