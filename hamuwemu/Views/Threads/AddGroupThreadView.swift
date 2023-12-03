//
//  AddGroupThreadView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-11.
//

import SwiftUI

struct AddGroupThreadView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var contactRepository: ContactRepository
    var chat: ChatGroup
    @Binding var tempThread: ChatThreadModel?
    @Binding var showTempThread: Bool
    @StateObject var model = Model()
    @State var text: String = ""
    
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
        presentationMode.wrappedValue.dismiss()
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text("Add Thread")
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
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {presentationMode.wrappedValue.dismiss()}) {
                        Text("Cancel")
                    }
                }
            }
        }
    }
}

struct AddGroupThreadView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddGroupThreadView(chat: ChatGroup.preview, tempThread: .constant(nil), showTempThread: .constant(false))
                .environmentObject(ContactRepository.preview)
        }
    }
}

extension AddGroupThreadView {
    class Model: ObservableObject {
        @Published var prompt: String = ""
        @Published var alertMessage = ""
        @Published var alert = false
        
        init(){
            
        }
        
        private func showAlertMessage(message: String) {
            alertMessage = message
            alert.toggle()
        }
    }
}
