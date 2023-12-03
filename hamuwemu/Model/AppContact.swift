//
//  AppContact.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/4/21.
//

import Foundation

struct AppContactListItem: Identifiable, Codable, Hashable {
    let id: String
    var fullName: String
    let phoneNumber: String
    let groupId: String?
    let publicKey: String
}

//extension AppContact {
////    init(id: String, fullName: String, phoneNumber: String, groupId: String?) {
////        self.id = id
////        self.fullName = fullName
////        self.phoneNumber = phoneNumber
////        self.groupId = groupId
////    }
//    
//    init?(dict: [String: Any]) {
//        guard let uid = dict["uid"] as? String else { return nil }
//        guard let phoneNumber = dict["phoneNumber"] as? String else { return nil }
//        guard let groupId = dict["groupId"] as? String? else { return nil }
//        
//        self.id = uid
//        self.phoneNumber = phoneNumber
//        self.fullName = phoneNumber
//        self.groupId = groupId
//    }
//}
