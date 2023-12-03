//
//  ChannelListView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/28/21.
//

import SwiftUI

import Combine
import FirebaseDatabase
import FirebaseAuth

struct ChannelListView: View {
    @EnvironmentObject var contactRepository: ContactRepository
    @ObservedObject var model: Model
    
    let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 10)
    ]

    var body: some View {
        List{
            ForEach(model.items) { channel in
                NavigationLink( destination: ChannelView(model: model.getViewModel(for: channel.channel) ), tag: channel,
                                selection: $model.selected){
                    HStack {
                        Image(systemName: "number")
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
//                            Text(channel.id)
                            Text(channel.channel.title)
                            MessageContentView(message: channel.message, contactRepository: contactRepository)
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
            print("ChannelListView onDisappear")
            model.removeListeners()
        }
    }
}

struct ChannelListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChannelListView(model: ChannelListView.Model(chat: ChatGroup(groupName: "TEST"), contactRepository: ContactRepository.preview))
        }
    }
}

extension ChannelListView {
    class Model: ObservableObject {
        @Published var items: [ChannelListItem] = []
        @Published var channelListItems = [String: ChannelListItem]()
        @Published var alertMessage = ""
        @Published var alert = false
        @Published var selected: ChannelListItem?
        var chat: ChatGroup
        var contactRepository: ContactRepository
        private var ref = Database.root
        private var channelRef: DatabaseReference?
        private var refHandle: DatabaseHandle?
        private let path = "channels"
        private let authenticationService: AuthenticationService = .shared
        private var defaultDataInitialized = false
        private var cancellables: Set<AnyCancellable> = []
        
//        init(chat: ChatGroup, ChatRepository: ChatRepository, contactRepository: ContactRepository) {
//            authenticationService = AuthenticationService()
//            #if DEBUG
//            //            createDevData()
//            #endif
//        }
        
        init(chat: ChatGroup, contactRepository: ContactRepository){
            print("ChannelListView init")
            self.contactRepository = contactRepository
            self.chat = chat
            if chat.isTemp {
                chat.clearChannels()
                let defaultChannel = ChatChannel(title: "General", group: chat.group)
                chat.channels[defaultChannel.channelUid] = defaultChannel
            }
        }
        
        deinit {
            print("Deinit ChannelListView.Model")
        }
        
        func removeListeners(){
            print("ChannelListView remove listners")
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
            print("ChannelListView addSubscribers called")
//            chat.$channels
//                .map{ dict -> [ChannelListItem] in
//                    var items = [ChannelListItem]()
//                    
//                    for (_, channel) in dict {
//                        print("ChannelListView channel \(channel.message?.id ?? "nil")")
//                        items.append(ChannelListItem(from: channel))
//                    }
//                    
//                    return items.sorted(by: {  $0.timestamp < $1.timestamp })
//                }
//                .assign(to: &$items)
        }
        
        func getViewModel(for channel: ChatChannel) -> ChannelView.Model {
            return ChannelView.Model(chat: chat, channel: channel, contactRepository: contactRepository)
        }
        
        func addListener() {
            guard let userId = authenticationService.user?.uid
            else {
                return
            }
            
            print("ChannelListView addListener called")
            channelRef = ref.child(DatabaseHelper.pathUserChannels).child(userId).child(chat.group)
            refHandle = channelRef?.observe( .value, with: { snapshot in
                var chats = [String: ChatChannel]()
                
                for child in snapshot.children {
                    let snap = child as! DataSnapshot
                    guard let value = snap.value as? [String: Any] else { continue }
                    if let chat  = ChatChannel(dict: value) {
                        print("ChannelListView chat \(chat.message?.id ?? "nil")")
                        chats[chat.channelUid] = chat
                    }
                }
                
                DispatchQueue.main.async {
                    print("ChannelListView addListener value called")
                    self.chat.updateChannels(channels: chats)
                }
                
            })
        }
        
        func add(name: String) {
            if !chat.isTemp {
                
                let channel = ChatChannel(title: name, group: chat.group)
                ChatRepository.addChannel(channel)
                let item = ChannelListItem(from: channel)
                if channelListItems[item.id] == nil {
                    channelListItems[item.id] = item
                }
                selected = item
            } else if let group = ChatRepository.addGroup(chat),
                      let (_, defaultChannel) = chat.channels.first {
                
                ChatRepository.addChannel(defaultChannel)
                let channel = ChatChannel(title: name, group: group)
                ChatRepository.addChannel(channel)
                
//                chat.clearChannels()
                let item = ChannelListItem(from: channel)
                if channelListItems[item.id] == nil {
                    channelListItems[item.id] = item
                }
                selected = item
            }
        }
    }
}
