//
//  Mention.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/23/21.
//

import Foundation

struct Mention {
    var id = UUID().uuidString
    var range: NSRange
    let uid: String
    let phoneNumber: String
    var taskTitle: String? = nil
    
    enum CodingKeys: String, CodingKey {
        case id, range, uid, phoneNumber, taskTitle
    }
}

extension Mention: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(uid, forKey: .uid)
        try container.encode(phoneNumber, forKey: .phoneNumber)
        try container.encode(taskTitle, forKey: .taskTitle)
        let rangeArray = [range.location, range.length]
        try container.encode(rangeArray, forKey: .range)
    }
}

extension Mention: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        uid = try values.decode(String.self, forKey: .uid)
        phoneNumber = try values.decode(String.self, forKey: .phoneNumber)
        taskTitle = try values.decode(String?.self, forKey: .taskTitle)
        let rangeArray = try values.decode([Int].self, forKey: .range)
        range = NSMakeRange(rangeArray[0], rangeArray[1])
    }
}

extension Mention {
    init?(dict: [String: Any]) {
        guard let id = dict["id"] as? String else { return nil }
        guard let uid = dict["uid"] as? String else { return nil }
        
        guard let phoneNumber = dict["phoneNumber"] as? String else { return nil }
        guard let range = dict["range"] as? [Int] else { return nil }
        
        self.id = id
        self.uid = uid
        self.phoneNumber = phoneNumber
        self.taskTitle = nil
        self.range = NSMakeRange(range[0], range[1])
    }
}

// MARK: - DatabaseRepresentation
extension Mention: DatabaseRepresentation {
    var representation: [String: Any] {
        let mentionArray = [range.location, range.length]
        let rep: [String: Any] = [
            "id": id,
            "uid": uid,
            "phoneNumber": phoneNumber,
            "range": mentionArray,
        ]
        
//        if let channel = channel {
//          rep["channel"] = channel
//        }

        return rep
    }
}
