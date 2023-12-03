//
//  AppUser.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-04-15.
//

import Foundation

struct AppUser: Codable {
    let uid: String
    let phoneNumber: String
    var publicKey: String? = nil
}

// MARK: - DatabaseRepresentation
extension AppUser: DatabaseRepresentation {
    var representation: [String: Any] {
        let rep: [String: Any] = [
            "uid": uid,
            "phoneNumber": phoneNumber,
        ]
        
        return rep
    }
}

struct AppGroupMember: Decodable {
    let uid: String
    let phoneNumber: String
    let groupUid: String
}

struct GroupMember {
    let uid: String
    let phoneNumber: String
    let fullName: String
}
