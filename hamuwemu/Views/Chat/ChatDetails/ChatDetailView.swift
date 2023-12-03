//
//  ChatDetailView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/27/21.
//

import SwiftUI

import FirebaseDatabase

enum ChatDetailState {
    case channels, threads
}

struct ChatDetailView: View {
    @ObservedObject var model: Model
    @State var showAddChatView = false
    @State var selectedList = ChatDetailState.channels
    
    var body: some View {
        ChannelView(model: model.channelViewModel)
        .onAppear{
            model.addGroupMemberListener()
        }
        .onDisappear{
            model.removeListeners()
        }
    }
}

struct ChatDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ChatDetailView(model: ChatDetailView.Model(chat: ChatGroup(groupName: "TEST"), contactRepository: ContactRepository.preview))
    }
}

extension ChatDetailView {
    class Model: ObservableObject {
        var chat: ChatGroup
        var contactRepository: ContactRepository
        var channelListModel: ChannelListView.Model
        var channelViewModel: ChannelView.Model
        private var ref = Database.root
        private var membersRef: DatabaseReference?
        
        var groupName: String {
            return chat.isChat ? contactRepository.getFullName(for: chat.groupName) ?? chat.groupName : chat.groupName
        }
        
        init(chat: ChatGroup, contactRepository: ContactRepository) {
            print("ChatDetailView init")
            self.chat = chat
            self.contactRepository = contactRepository
            self.channelListModel = ChannelListView.Model(chat: chat, contactRepository: contactRepository)
            self.channelViewModel = ChannelView.Model(chat: chat, channel: chat.defaultChannel, contactRepository: contactRepository)
        }
        
        func removeListeners(){
            membersRef?.removeAllObservers()
        }
        
        func addGroupMemberListener() {
            print("ChatView addGroupMemberListener called")
            membersRef = ref.child(DatabaseHelper.pathGroups).child(chat.group).child("members")
            _ = membersRef?.observe( .childAdded, with: { snapshot in
                guard let value = snapshot.value as? [String: Any] else { return }
                let uid = value["uid"] as? String ?? ""
                let phoneNumber = value["phoneNumber"] as? String ?? ""
                let appUser = AppUser(uid: uid, phoneNumber: phoneNumber)
                
                DispatchQueue.main.async {
                    self.chat.addMembers(appUsers: [appUser])
                }
            })
        }
    }
}
