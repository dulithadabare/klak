//
//  ClientPushModel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-09.
//

import Foundation

public enum ClientPushType: Int {
    case addGroup = 1
    case addThread = 2
    case addMessage = 3
    case ack = 4
    case ping = 5
    case addReadReceipts = 6
    case addTaskLogItem = 7
}

public struct ClientPushModel {
    public  var id: UInt32 = 0
    public var type: ClientPushType
    public var data: Any
}

extension ClientPushModel: Decodable {
    enum CodingKeys: CodingKey {
        case id, type, data
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UInt32.self, forKey: .id)
        let pushType = try values.decode(Int.self, forKey: .type)
        type = ClientPushType(rawValue: pushType)!
        switch type {
        case .addGroup:
            data = try values.decode(AddGroupModel.self, forKey: .data)
            break
        case .addThread:
            data = try values.decode(AddThreadModel.self, forKey: .data)
        case .addMessage:
            data = try values.decode(AddMessageModel.self, forKey: .data)
        case .ack:
            data = try values.decode(String.self, forKey: .data)
        case .ping:
            data = Data()
        case .addReadReceipts:
            data = try values.decode(AddReadReceiptModel.self, forKey: .data)
        case .addTaskLogItem:
            data = try values.decode(AddTaskLogItemModel.self, forKey: .data)
        }
    }
}

extension ClientPushModel: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(type.rawValue, forKey: .type)
        
        switch type {
        case .addMessage:
            let message = data as! AddMessageModel
            try container.encode(message, forKey: .data)
        case .addGroup:
            let group = data as! AddGroupModel
            try container.encode(group, forKey: .data)
        case .addThread:
            let thread = data as! AddThreadModel
            try container.encode(thread, forKey: .data)
        case .ack:
            let messageId = data as! String
            try container.encode(messageId, forKey: .data)
        case .addReadReceipts:
            let receipts = data as! AddReadReceiptModel
            try container.encode(receipts, forKey: .data)
        case .ping:
            try container.encode(Data(), forKey: .data)
        case .addTaskLogItem:
            let task = data as! AddTaskLogItemModel
            try container.encode(task, forKey: .data)
        }
    }
}
