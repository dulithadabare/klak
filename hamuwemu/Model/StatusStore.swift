//
//  StatusStore.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/18/21.
//

import Foundation

class StatusStore : ObservableObject {
//    @Published var current = HwMessage(content: "Hello")
//    @Published var suggested = HwMessage(content: "Hello")
    
    init() {
        #if DEBUG
//        createDevData()
        #endif
        getSuggestion()
    }
    
    func getSuggestion() {
//        suggested = HwMessage(content: "Hi")
    }
    
    func updateStatus(_ message: String) {
//        current = HwMessage(content: message)
    }
    
}
