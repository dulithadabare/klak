//
//  AddThreadViewRepresentable.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/23/21.
//

import SwiftUI

struct AddThreadViewRepresentable: UIViewControllerRepresentable {
    var thread: ChatThread
    var chat: ChatGroup
    var channel: ChatChannel
    var contactRepository: ContactRepository
    
    func makeUIViewController(context: Context)
    -> ThreadViewController {
        let controller = AddThreadViewController(thread: thread, chat: chat, channel: channel, contactRepository: contactRepository)
        return controller
    }
    
    func updateUIViewController(
        _ uiViewController: ThreadViewController,
        context: Context
    ) {
        print("AddThreadViewController: Updating VC")
    }
}
