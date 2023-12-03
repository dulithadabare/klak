//
//  AddReadReceiptModel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-22.
//

import Foundation

struct ReadReceipt: Codable {
    let author: String
    let messageId: String
}

struct AddReadReceiptModel: Codable {
    let receipts: [ReadReceipt]
}
