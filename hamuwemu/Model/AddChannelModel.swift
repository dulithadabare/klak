//
//  ChatChannelModel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-09.
//

import Foundation

public class AddChannelModel: Codable {
    var channelUid: String
    var title: String
    var group: String
    
    var timestamp = Date()
    var isTemp = false
    
    enum CodingKeys: String, CodingKey {
        case channelUid = "uid"
        case title, group
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        channelUid = try values.decode(String.self, forKey: .channelUid)
        group = try values.decode(String.self, forKey: .group)
        title = try values.decode(String.self, forKey: .title)
    }
    
    public init(channelUid: String, title: String, group: String) {
        self.channelUid = channelUid
        self.title = title
        self.group = group
    }
}
