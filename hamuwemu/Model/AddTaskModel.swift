//
//  AddTaskModel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-08-29.
//

import Foundation

struct AddTaskModel {
    let id: String
    let title: String
    let message: HwMessage
    let assignedTo: String
    let assignedBy: String
    let isUrgent: Bool
    let dueDate: Date?
    let groupUid: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, message, assignedTo, assignedBy, isUrgent, dueDate, groupUid
    }
}

extension AddTaskModel: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        title = try values.decode(String.self, forKey: .title)
        message = try values.decode(HwMessage.self, forKey: .message)
        
        let timestampString = try values.decode(String?.self, forKey: .dueDate)
        if let timestampString = timestampString {
            dueDate = MessageDateFormatter.shared.getDateFrom(DateString8601: timestampString)!
        } else {
            dueDate = nil
        }
        assignedBy = try values.decode(String.self, forKey: .assignedBy)
        assignedTo = try values.decode(String.self, forKey: .assignedTo)
        groupUid = try values.decode(String.self, forKey: .groupUid)
        isUrgent = try values.decode(Bool.self, forKey: .isUrgent)
    }
}

extension AddTaskModel: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(message, forKey: .message)
        if let dueDate = dueDate {
            let iso8601Timestamp = MessageDateFormatter.shared.iso8601FormatterWithMilliseconds.string(from: dueDate)
            
            try container.encode(iso8601Timestamp , forKey: .dueDate)
        }
        try container.encode(assignedBy   , forKey: .assignedBy)
        try container.encode(isUrgent , forKey: .isUrgent)
        try container.encode(assignedTo   , forKey: .assignedTo)
        try container.encode(groupUid, forKey: .groupUid)
    }
}

