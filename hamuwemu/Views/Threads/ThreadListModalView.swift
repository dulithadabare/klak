//
//  ThreadListModalView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/15/21.
//

import SwiftUI

enum ThreadType {
    case active, archived
}


struct ThreadListModalView: View {
    @State private var firstName: String = ""
    @State private var selectedThreadType = ThreadType.active
    @ObservedObject var model: Model
    
    var body: some View {
        VStack {
            Picker(selection: $selectedThreadType, label: Text("")) {
                Text("Active")
                    .tag(ThreadType.active)
                Text("Archived")
                    .tag(ThreadType.archived)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 200)
            Group{
                switch selectedThreadType {
                case .active:
                    ThreadListView(model: ThreadListView.Model(chat: model.chat, contactRepository: model.contactRepository))
                case .archived:
                    ThreadListView(model: ThreadListView.Model(chat: model.chat, contactRepository: model.contactRepository))
                }
            }
        }
        .navigationTitle("Threads")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                        
                }) {
                    Text("New Thread")
                }
            }
        }
    }
}

struct ThreadListModalView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListModalView(model: ThreadListModalView.Model(chat: ChatGroup(groupName: "Preview Group"), channel: ChatChannel(), contactRepository: ContactRepository.preview))
    }
}

extension ThreadListModalView {
    class Model: ObservableObject {
        var chat: ChatGroup
        var channel: ChatChannel
        var contactRepository: ContactRepository
        
        init(chat: ChatGroup,  channel: ChatChannel, contactRepository: ContactRepository) {
            self.chat = chat
            self.channel = channel
            self.contactRepository = contactRepository
        }
    }
}

