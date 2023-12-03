//
//  MessageReceiptModel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-10.
//

import Foundation

enum MessageReceiptType: Int, Decodable {
    case sent, delivered, read
}

struct MessageReceiptModel: Decodable {
    let type: MessageReceiptType
    let appUser: AppUser?
    let messageId: String
}
