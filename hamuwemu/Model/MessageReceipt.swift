//
//  MessageReceipt.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/10/21.
//

import Foundation

struct MessageReceipt {
    let message: ChatMessage
    let isSent: Bool
    let delivered: [AppUser]
    let read: [AppUser]
}

extension MessageReceipt {
    init?(dict: [String: Any]){
        guard let message = dict["message"] as? [String: Any],
              let isSent = dict["isSent"] as? Bool,
              let delivered = dict["delivered"] as? [String: Any]?,
              let read = dict["read"] as? [String: Any]?
              else {

            return nil
        }
        var deliveredArray = [AppUser]()
        if let delivered = delivered {
            for (_, child) in delivered {
                guard let dict = child as? [String: Any],
                      let uid = dict["uid"] as? String,
                      let phoneNumber = dict["phoneNumber"] as? String  else {continue}
                let appUser = AppUser(uid: uid, phoneNumber: phoneNumber)
                deliveredArray.append(appUser)
            }
        }
        
        var readArray = [AppUser]()
        if let read = read {
            for (_, child) in read {
                guard let dict = child as? [String: Any],
                      let uid = dict["uid"] as? String,
                      let phoneNumber = dict["phoneNumber"] as? String  else {continue}
                let appUser = AppUser(uid: uid, phoneNumber: phoneNumber)
                readArray.append(appUser)
            }
        }
        
        self.message = ChatMessage(dict: message)!
        self.isSent = isSent
        self.delivered = deliveredArray
        self.read = readArray
    }
}
