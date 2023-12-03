//
//  AddThreadModel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-03.
//

import Foundation

struct AddThreadModel: Codable {
    let author: String
    let threadUid: String
    let group: String
    let title: HwMessage
    let replyingTo: String?
    let members: [String: AppUser]
}
