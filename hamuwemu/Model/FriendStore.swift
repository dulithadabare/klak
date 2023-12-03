//
//  FriendStore.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/18/21.
//

import Foundation

struct HwFriend: Identifiable {
    let id = UUID()
    let message: HwMessage
    var user: AddUserModel
}

class FriendStore: ObservableObject {
    @Published var messages: [HwFriend] = []
    
    init() {
        #if DEBUG
//        createDevData()
        #endif
    }
    
    
    
}
