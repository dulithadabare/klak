//
//  ContactModel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-29.
//

import Foundation

struct ImportedContact {
    let phoneNumber: String
    let displayName: String
    
    // The keys must have the same name as the attributes of the Quake entity.
    var dictionaryValue: [String: Any] {
        [
            "phoneNumber": phoneNumber,
            "displayName": displayName,
        ]
    }
}
