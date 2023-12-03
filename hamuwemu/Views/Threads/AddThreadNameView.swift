//
//  AddThreadNameView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-04-06.
//

import SwiftUI

struct AddThreadNameView: View {
    var chat: ChatGroup
    
    @Binding var tempThread: ChatThreadModel?
    @Binding var showTempThread: Bool
    var dismiss: () -> Void
    
    @EnvironmentObject private var contactRepository: ContactRepository
    @StateObject private var model = Model()
    @State private var text: String = ""
    
    
    func validate() -> Bool {
        if text.isEmpty {
            return false
        }
        
        //check if length < 30
        if text.utf16.count > 30 {
            return false
        }
        
        return true
    }
    
    func prompt() -> String {
        if text.utf16.count > 30 {
            return "Enter a name under 30 characters (Yours has \(text.utf16.count))."
        }
        
        return ""
    }
    
    func groupName() -> String {
        return chat.isChat ? contactRepository.getFullName(for: chat.groupName) : chat.groupName
    }
    
    func add() {
        let threadUid = PushIdGenerator.shared.generatePushID()
        let title =  attributedString(with: HwMessage(content: text, mentions: [], links: []), contactRepository: contactRepository)
        let thread = ChatThreadModel(threadUid: threadUid, group: chat.group, title: title, replyingTo: nil, isTemp: true, members: chat.members, chat: chat)
        tempThread = thread
        showTempThread = true
        dismiss()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Thread Name")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Start a new thread \(chat.isChat ? "with" : "in" ) \(groupName())")
                        .font(.subheadline)

            }
            .padding()
            Form {
                Section(footer: Text(prompt()).foregroundColor(.red)) {
                    TextField("Thread Name", text: $text)
                        .disableAutocorrection(true)
//                        .disabled(model.isLoading)
                }
            }
        }
        .toolbar {
//            ToolbarItem(placement: .principal) {
//                Text("Add Thread")
//            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {add()}) {
                    Text("Done")
                }
                .disabled(!validate())
            }
        }
    }
}

struct AddThreadNameView_Previews: PreviewProvider {
    static var previews: some View {
        AddThreadNameView(chat: ChatGroup.preview, tempThread: .constant(nil), showTempThread: .constant(false), dismiss: { })
            .environmentObject(ContactRepository.preview)
    }
}
