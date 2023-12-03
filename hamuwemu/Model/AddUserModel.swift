//
//  HwUser.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/18/21.
//

import Foundation

struct AddUserModel: Codable {
    let uid: String
    let phoneNumber: String
    let displayName: String
    let publicKey: String
}
