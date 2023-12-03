//
//  AddThreadWithNameView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/23/21.
//

import SwiftUI

struct AddThreadWithNameView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showThreadView = false
    @State private var firstName: String = ""
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
            VStack {
                NavigationLink(destination: LazyDestination{ AddThreadChatView(selectedThreadItem: $selectedThreadItem, thread: thread, chat: chat, channel: channel, contactRepository: contactRepository, onDismiss: {onDismiss()}) }, isActive: $showThreadView) {
                    EmptyView()
                }
                Form {
                    Section(footer: Text("The thread will automatically archive after 24 hours of inactivity")) {
                        TextField("Thread Name", text: $firstName)
                    }
                }
            }
            .navigationTitle("Add Thread")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                            presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        thread.title = firstName
                            showThreadView = true
                    }) {
                        Text(firstName.isEmpty ? "Skip" : "Next")
                    }
                    .disabled(firstName.isEmpty)
                }
            }
        }
    }
}

//struct AddThreadWithNameView_Previews: PreviewProvider {
//    static var previews: some View {
//        AddThreadWithNameView(thread: ChatThread(), chat: ChatGroup(groupName: "Preview Group"), channel: ChatChannel(), contactRepository: ContactRepository())
//    }
//}
