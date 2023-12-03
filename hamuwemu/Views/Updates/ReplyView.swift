//
//  ReplyView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/22/21.
//

import SwiftUI

import Combine

struct ReplyView: View {
    @Environment(\.presentationMode) var presentationMode
    var update: Update
    @State private var firstName: String = ""
    @StateObject var model = Model()
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section{
                        TextField("Channel Name", text: $firstName)
                    }
                }
            }
            .navigationTitle("Send Reply")
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
                        model.send(message: firstName, mentions: [String: AppUser]())
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Done")
                    }
                    .disabled({firstName.isEmpty}())
                }
            }
            .onAppear{
                model.update = update
            }
        }
    }
}

struct ReplyView_Previews: PreviewProvider {
    static var previews: some View {
        ReplyView(update: Update(groupName: "", channelName: "", message: HwMessage(content: "", sender: "phoneNumber"), sender: "", type: []))
    }
}

extension ReplyView {
    class Model: ObservableObject {
        @Published var items: [ChannelListItem] = []
        var channelListModel: ChannelListView.Model?
        @Published var alertMessage = ""
        @Published var alert = false
        var update: Update?
        
        private var cancellables: Set<AnyCancellable> = []
        
        init() {
            #if DEBUG
            //            createDevData()
            #endif
        }
        
        func send(message: String, mentions: [String: AppUser]){
            guard let update = update,
                  let phoneNumber = AuthenticationService.shared.phoneNumber else {
                return
            }
            
            ChatRepository.sendMessage(message: HwMessage(content: message, sender: phoneNumber), channel: update.channel, channelName: update.channelName, group: update.group, groupName: update.groupName, isChat: update.isChat)
        }
    }
}
