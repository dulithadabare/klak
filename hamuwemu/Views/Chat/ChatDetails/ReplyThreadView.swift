//
//  ReplyThreadView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/15/21.
//

import SwiftUI

struct ReplyThreadView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedThreadItem: ThreadItem?
    var thread: ChatThread
    var chat: ChatGroup
    var channel: ChatChannel
    var contactRepository: ContactRepository
    
    func onDismiss(){
        presentationMode.wrappedValue.dismiss()
    }
    
    var body: some View {
        NavigationView {
            AddThreadChatView(selectedThreadItem: $selectedThreadItem, thread: thread, chat: chat, channel: channel, contactRepository: contactRepository, onDismiss: {onDismiss()})
            .navigationTitle("New Thread")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                            presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                    }
                }
            }
        }
    }
}

//struct ReplyThreadView_Previews: PreviewProvider {
//    static var previews: some View {
//        ReplyThreadView(chat: ChatGroup(groupName: "Preview Group"), channel: ChatChannel(), thread: ChatThread(), contactRepository: ContactRepository())
//    }
//}
