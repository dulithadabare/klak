//
//  HwMention.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/28/21.
//

import Foundation

class HwMention: NSSecureCoding {
    static var supportsSecureCoding: Bool = true
    
    func encode(with coder: NSCoder) {
        coder.encode(id, forKey: "id")
//        coder.encode(range, forKey: "range")
        coder.encode(uid, forKey: "uid")
        coder.encode(phoneNumber, forKey: "phoneNumber")
    }
    
    required init?(coder: NSCoder) {
        guard
            let id = coder.decodeObject(of: [NSString.self], forKey: "id") as? String,
            let uid = coder.decodeObject(of: [NSString.self], forKey: "uid") as? String,
//            let range = coder.decodeObject(of: [NSRange.self], forKey: "range"),
            let phoneNumber = coder.decodeObject(of: [NSString.self], forKey: "phoneNumber") as? String
            
        else {
            return nil
        }
        
        self.id = id
//        self.range = range
        self.uid = uid
        self.phoneNumber = phoneNumber
    }
    
    var id: String
//    var range: NSRange
    var uid: String
    var phoneNumber: String
}
