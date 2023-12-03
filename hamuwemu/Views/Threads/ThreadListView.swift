//
//  ThreadListView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/25/21.
//

import SwiftUI

import Combine
import FirebaseDatabase

struct ThreadListView: View {
    @EnvironmentObject var contactRepository: ContactRepository
    @ObservedObject var model: Model
    
    let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 10)
    ]

    var body: some View {
        List{
            ForEach(model.items) { item in
                NavigationLink( destination: ThreadDetailView(model: model.getViewModel(for: item.thread))){
                    HStack {
                        VStack(alignment: .leading) {
//                            Text(item.id)
                            if let channelMessage = item.thread.channelMessage {
                                Text(attributedString(with: channelMessage.message, contactRepository: contactRepository).string)
                                    .lineLimit(1)
                            } else {
                                Text(item.thread.title)
                                    .lineLimit(1)
                            }
                            MessageContentView(message: item.message, contactRepository: contactRepository)
                                .font(.footnote)
                                .foregroundColor(Color.gray)
                        }
                    }
                }
            }
        }
        .onAppear{
            model.addSubscribers()
            model.addListener()
        }
        .onDisappear{
//            print("ChannelListView onDisappear")
            model.removeListeners()
        }
    }
}

struct ThreadListView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListView(model: ThreadListView.Model(chat: ChatGroup(groupName: "Preview Group"), contactRepository: ContactRepository.preview))
    }
}

extension ThreadListView {
    class Model: ObservableObject {
        @Published var items: [ThreadListItem] = []
        @Published var channelListItems = [String: ThreadListItem]()
        @Published var alertMessage = ""
        @Published var alert = false
        var chat: ChatGroup
        var chatRepository = ChatRepository()
        var contactRepository: ContactRepository
        private var ref = Database.root
        private var channelRef: DatabaseReference?
        private var refHandle: DatabaseHandle?

        private let authenticationService: AuthenticationService = .shared
        private var defaultDataInitialized = false
        private var cancellables: Set<AnyCancellable> = []
        
//        init(chat: ChatGroup, chatRepository: ChatRepository, contactRepository: ContactRepository) {
//            authenticationService = AuthenticationService()
//            #if DEBUG
//            //            createDevData()
//            #endif
//        }
        
        init(chat: ChatGroup, contactRepository: ContactRepository){
            print("ThreadListView init")
            self.contactRepository = contactRepository
            self.chat = chat
        }
        
        deinit {
            print("Deinit ThreadListView.Model")
        }
        
        func removeListeners(){
            print("ThreadListView remove listners")
//            if let refHandle = refHandle {
//               ref.removeObserver(withHandle: refHandle)
//            }
//            ref.removeAllObservers()
            guard let channelRef = channelRef else {
                return
            }
            channelRef.removeAllObservers()
        }
        
        func addSubscribers() {
//            chat.$threads
////                .print("chats")
//                .map{ dict -> [ThreadListItem] in
//                    var items = [ThreadListItem]()
//                    
//                    for (_, thread) in dict {
//                        items.append(ThreadListItem(from: thread))
//                    }
//                    
//                    return items.sorted(by: {  $0.timestamp < $1.timestamp })
//                }
//                .assign(to: &$items)
        }
        
        func getViewModel(for thread: ChatThread) -> ThreadDetailView.Model {
            let channel = ChatChannel(channelUid: thread.channel, title: "ChannelTitle", group: thread.group)
            return ThreadDetailView.Model(chat: chat, channel: channel, thread: thread, contactRepository: contactRepository)
        }
        
        func addListener() {
            guard let userId = authenticationService.user?.uid
            else {
                return
            }
            
            print("ChannelListView addListener called")
            channelRef = ref.child(DatabaseHelper.pathUserThreads).child(userId).child(chat.group)
            _ = channelRef?.observe( .value, with: { snapshot in
                var chats = [String: ChatThread]()
                
                for child in snapshot.children {
                    let snap = child as! DataSnapshot
                    guard let value = snap.value as? [String: Any] else { continue }
                    if let chat  = ChatThread(dict: value) {
                        chats[chat.threadUid] = chat
                    }
                }
                
                DispatchQueue.main.async {
                    print("ChannelListView addListener value called")
                    self.chat.updateThreads(threads: chats)
                }
                
            })
        }
    }
}
