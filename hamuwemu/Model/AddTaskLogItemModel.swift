//
//  AddTaskLogItemModel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-08-29.
//

import Foundation

struct AddTaskLogItemModel {
    let id: String
    let task: AddTaskModel
    let message: HwMessage
    let createdBy: String
    let status: TaskStatus
    let pendingDueDate: Date?
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id, task, message, createdBy, status, pendingDueDate, timestamp
    }
}

extension AddTaskLogItemModel: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        task = try values.decode(AddTaskModel.self, forKey: .task)
        message = try values.decode(HwMessage.self, forKey: .message)
        createdBy = try values.decode(String.self, forKey: .createdBy)
        status = try values.decode(TaskStatus.self, forKey: .status)
        let timestampString = try values.decode(String.self, forKey: .timestamp)
        timestamp = MessageDateFormatter.shared.getDateFrom(DateString8601: timestampString)!
        let pendingDueDateString = try values.decode(String?.self, forKey: .pendingDueDate)
        if let pendingDueDateString = pendingDueDateString {
            pendingDueDate = MessageDateFormatter.shared.getDateFrom(DateString8601: pendingDueDateString)!
        } else {
            pendingDueDate = nil
        }
    }
}

extension AddTaskLogItemModel: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(task, forKey: .task)
        try container.encode(message, forKey: .message)
        try container.encode(createdBy   , forKey: .createdBy)
        try container.encode(status , forKey: .status)
        let iso8601Timestamp = MessageDateFormatter.shared.iso8601FormatterWithMilliseconds.string(from: timestamp)
        try container.encode(iso8601Timestamp, forKey: .timestamp)
        if let pendingDueDate = pendingDueDate {
            let iso8601PendingDueDate = MessageDateFormatter.shared.iso8601FormatterWithMilliseconds.string(from: pendingDueDate)
            
            try container.encode(iso8601PendingDueDate , forKey: .pendingDueDate)
        }
    }
}
