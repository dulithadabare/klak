//
//  SwiftUIView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 9/28/21.
//

import SwiftUI

import Contacts
import Combine
import FirebaseDatabase
import CoreData
import PromiseKit

//struct ChatView: View {
//    @State private var selection: String? = nil
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                NavigationLink(destination: Text("View A"), tag: "A", selection: $selection) { EmptyView() }
//                NavigationLink(destination: Text("View B"), tag: "B", selection: $selection) { EmptyView() }
//
//                Button("Tap to show A") {
//                    selection = "A"
//                }
//
//                Button("Tap to show B") {
//                    selection = "B"
//                }
//            }
//            .onAppear{
//                print("Selection \(selection ?? "nil")")
//            }
//            .navigationTitle("Navigation")
//        }
//    }
//}

struct TestItem: Identifiable, Hashable {
    let id: String
    var content: String
    let channel: String? = nil
    var group: String? = nil
    var members: [AppContactListItem] = []
    
    static func == (lhs: TestItem, rhs: TestItem) -> Bool {
        lhs.id == rhs.id
//            && lhs.message == rhs.message
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
//        hasher.combine(message)
    }
}

//extension TestItem {
//    init(id: String, content: String) {
//        self.id = id
//        self.content = content
//    }
//}

struct ChatView: View {
    @EnvironmentObject var contactRepository: ContactRepository
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var notificationDelegate: NotificationDelegate
    @ObservedObject var model: Model
    @State var showAddChatView = false
    @State var selectedChat: String? = nil
    @State var tempChatGroup: ChatGroup? = nil
    @State var showTempChatGroup: Bool = false
    @State var showSettings = false
    
    @FetchRequest(
        entity: HwChatListItem.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \HwChatListItem.lastMessageDate, ascending: false)
//            NSSortDescriptor(keyPath: \ProgrammingLanguage.creator, ascending: false)
        ]
    ) var items: FetchedResults<HwChatListItem>
    
    func addNewMessage(){
        
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { proxy in
                VStack {
                    if let tempChatGroup = tempChatGroup {
                        NavigationLink(destination: LazyDestination{
                            ChannelMessagesView(chat: tempChatGroup)
                                .onDisappear {
                                    //this is slower than onAppear on parent
                                    // tempGroup = nil
                                }
                            
                        }, isActive: $showTempChatGroup) { EmptyView() }
                    }
                    Group {
                        if model.items.count == 0 {
                            HStack {
                                Text("Tap the \(Image(systemName: "square.and.pencil")) icon to start a new chat.")
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
                        }
                        else {
                            List {
                                ForEach(model.items) { item in
                                    NavigationLink(destination: LazyDestination {
                //                        ChatDetailView(model: model.getViewModel(for: item.group!))
                                        ChannelMessagesView(inMemory: model.inMemory, chat: ChatGroup(from: item))
                                    },
                                                   tag: item.groupId!,
                                                   selection: $notificationDelegate.selectedChat){
                                        ChatListItemView(item: item, width: proxy.size.width)
                                            .padding(.bottom, 5)
                //                        VStack{
                //                        Text(item.groupId!)
                //
                //                        }
                                        
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange).receive(on: RunLoop.main), perform: { _ in
                model.load()
            })
            .onChange(of: selectedChat, perform: { value in
                print("selectedChat changed", value ?? "nil")
            })
            .onAppear{
//                model.load()
                tempChatGroup = nil
                model.clearTemp()
            }

            .navigationTitle(NSLocalizedString("Chats", comment: "title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    TitleView(title: "Chats")
                            }
                // .bottomToolBar caused messagesview to shift when resuming app
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddChatView.toggle()
                    }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                    
//                    Button(action: {
//                        showSettings.toggle()
//                    }) {
//                        Image(systemName: "gearshape")
//                    }
                }
            }
        
            .sheet(isPresented: $showAddChatView, content: {
                AddGroupView(inMemory: model.inMemory, selectedChat: $selectedChat, tempGroup: $tempChatGroup, showTempGroup: $showTempChatGroup)
                    .environmentObject(authenticationService)
                    .environmentObject(contactRepository)
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(model: ChatView.Model(inMemory: true, chatDataModel: ChatDataModel.shared))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AuthenticationService.preview)
            .environmentObject(ContactRepository.preview)
            .environmentObject(NotificationDelegate.shared)
    }
}

extension ChatView {
    class Model: ObservableObject {
        @Published var chats = [String: ChatListItem]()
        @Published var items: [HwChatListItem] = []
        var contactGroupID = [String: String]()
        @Published var testArray = []
        @Published var selectedChat: ChatListItem?
        var childViewModels: [String: ChatDetailView.Model] = [:]
        var contactRepository: ContactRepository
        var chatDataModel: ChatDataModel
        
        var authenticationService: AuthenticationService
        private var ref = Database.root
        private var groupsRef: DatabaseReference?
        private var threadsRef: DatabaseReference?
        private var chatIdRef: DatabaseReference?
        private var messageRef: DatabaseReference?
        var messageReceiptRef: DatabaseReference?
        private var remoteRefHandle: DatabaseHandle?
        var messagesRemoteInitialDataLoaded = false
        var groupsRemoteInitialDataLoaded = false
        var threadsRemoteInitialDataLoaded = false
        private var persistenceController: PersistenceController
        private var managedObjectContext: NSManagedObjectContext
        
        var inMemory: Bool
        
        private var cancellables: Set<AnyCancellable> = []
 
        init(inMemory: Bool = false, chatDataModel: ChatDataModel) {
            self.inMemory = inMemory
            if inMemory {
                self.chatDataModel = chatDataModel
                self.contactRepository = ContactRepository.preview
                persistenceController = PersistenceController.preview
                managedObjectContext = PersistenceController.preview.container.viewContext
                authenticationService = AuthenticationService.preview
            } else {
                self.chatDataModel = chatDataModel
                self.contactRepository = ContactRepository.shared
                persistenceController = PersistenceController.shared
                managedObjectContext = PersistenceController.shared.container.viewContext
                authenticationService = AuthenticationService.shared
                load()
    //            addListener()
//                addRemoteListener()
            }
            
            load()

            #if DEBUG
            createDevData()
            #endif
        }
        
        deinit {
            ref.removeAllObservers()
            print("ChatView Model deinit")
        }
        
        func getViewModel(for hwChat: HwChatGroup) -> ChatDetailView.Model {
            let chat = ChatGroup(from: hwChat)
            if let viewModel = childViewModels[chat.group] {
                return viewModel
            } else {
                let viewModel = ChatDetailView.Model(chat: chat, contactRepository: contactRepository)
                childViewModels[chat.group] = viewModel
                return viewModel
            }
        }
        
        func load() {
            let request: NSFetchRequest<HwChatListItem> = HwChatListItem.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(
                    keyPath: \HwChatListItem.lastMessageDate,
                    ascending: false)]
            if let results = try? managedObjectContext.fetch(request) {
                DispatchQueue.main.async {
                    self.items = results
                }
            }
        }
        
        func addListener(for userId: String) {
////                chatRef = ref.child(DatabaseHelper.pathUserChats).child(userId)
////                _ = chatRef?.observe( .value, with: { snapshot in
////                    var chats = [String: ChatGroup]()
////                    for child in snapshot.children {
////                        let snap = child as! DataSnapshot
////                        guard let value = snap.value as? [String: Any] else { continue }
////                        if let chat  = ChatGroup(dict: value) {
////                            // Chat items saved in the database will always have a group id
////                            chats[chat.group] = chat
////                        }
////                    }
////
////                    DispatchQueue.main.async {
////                        self.chatDataModel.updateChats(chats: chats)
////                    }
////
////                })
//
//            chatIdRef = ref.child(DatabaseHelper.pathUserChatIDs).child(userId)
//            _ = chatIdRef?.observe( .value, with: { snapshot in
//                guard let value = snapshot.value as? [String: String] else { return }
//
//                DispatchQueue.main.async {
//                    self.contactGroupID = value
//                }
//            })
//
//            // MARK: - Groups Listener
//
//            groupsRef = ref.child(DatabaseHelper.pathUserGroups).child(userId)
//
//            _ = groupsRef?.observe( .value, with: { [weak self] snapshot in
//                print("\(DatabaseHelper.pathUserGroups): value")
//                guard let self = self else { return }
//
//                self.groupsRemoteInitialDataLoaded = true
//            })
//
//            _ = groupsRef?.observe( .childAdded, with: { [weak self] snapshot in
//                guard let value = snapshot.value as? [String: Any],
//                      let group = ChatGroup(dict: value)
//                      else { return }
//
//                if let self = self
//                    , self.groupsRemoteInitialDataLoaded
//                {
//                    print("\(DatabaseHelper.pathUserGroups): childAdded \(group.groupName)")
//                    self.handleGroup(group, change: .childAdded)
//                }
//
//            })
//
//            _ = groupsRef?.observe( .childChanged, with: { [weak self] snapshot in
//                guard let value = snapshot.value as? [String: Any],
//                      let group = ChatGroup(dict: value)
//                      else { return }
//                print("\(DatabaseHelper.pathUserGroups): childChanged \(group.group)")
//                self?.handleGroup(group, change: .childChanged)
//            })
//
//            // MARK: - Threads Listener
//
//            threadsRef = ref.child(DatabaseHelper.pathUserThreads).child(userId)
//
//            _ = threadsRef?.observe( .value, with: { [weak self] snapshot in
//                print("\(DatabaseHelper.pathUserThreads): value")
//                guard let self = self else { return }
//
//                self.threadsRemoteInitialDataLoaded = true
//            })
//
//            _ = threadsRef?.observe( .childAdded, with: { [weak self] snapshot in
//                guard let value = snapshot.value as? [String: Any],
//                      let group = ChatThread(dict: value)
//                      else { return }
//
//                if let self = self
//                    , self.groupsRemoteInitialDataLoaded
//                {
//                    print("\(DatabaseHelper.pathUserThreads): childAdded \(group.title)")
//                    self.handleThread(group, change: .childAdded)
//                }
//
//            })
//
//            _ = threadsRef?.observe( .childChanged, with: { [weak self] snapshot in
//                guard let value = snapshot.value as? [String: Any],
//                      let group = ChatThread(dict: value)
//                      else { return }
//                print("\(DatabaseHelper.pathUserThreads): childChanged \(group.title)")
//                self?.handleThread(group, change: .childChanged)
//            })
//
//            // MARK: - Messages Listener
//
//            messageRef = ref.child(DatabaseHelper.pathUserMessages).child(userId)
//
//            _ = messageRef?.observe( .value, with: { [weak self] snapshot in
//                print("\(DatabaseHelper.pathUserMessages): value")
//                guard let self = self else { return }
//
//                self.messagesRemoteInitialDataLoaded = true
//            })
//
//            _ = messageRef?.observe( .childAdded, with: { [weak self] snapshot in
//                guard let value = snapshot.value as? [String: Any],
//                      let message = ChatMessage(dict: value)
//                      else { return }
//                // because method will get called with all children on server restart
//                // check to see if the child is new or not
//                // For all existing children .childAdded will be called before .value
//                // (https://stackoverflow.com/questions/27978078/how-to-separate-initial-data-load-from-incremental-children-with-firebase)
//
//                if let self = self
//                    , self.messagesRemoteInitialDataLoaded
//                {
//                    print("\(DatabaseHelper.pathUserMessages): childAdded \(message.message.content)")
//                    self.handleMessage(message, change: .childAdded)
//                    self.chatDataModel.updateUnreadCount(with: message)
//                    self.updateDeliveredReceipt(for: message)
//                }
//
//            })
//
//            _ = messageRef?.observe( .childChanged, with: { [weak self] snapshot in
//                guard let value = snapshot.value as? [String: Any],
//                      let message = ChatMessage(dict: value)
//                      else { return }
//                print("\(DatabaseHelper.pathUserMessages): childChanged \(message.id)")
//                self?.handleMessage(message, change: .childChanged)
//            })
        }
        
        func handleMessage(_ message: ChatMessage, change: DataEventType) {
            switch change {
            case .childAdded:
//                chatDataModel.addChatMessage(with: message)
//                chatDataModel.updateChatListItem(with: message)
                
                if message.isThreadMessage {
                    //update thread
                } else {
                    // update channel
                }
                
            case .childChanged:
                // update message
//                chatDataModel.updateChatMessage(with: message)
                // update current last message status
                if let item = chatDataModel.chatListItems[message.group],
                   let messageId = item.lastMessageId,
                   messageId == message.id,
                   let author = item.lastMessageAuthorUid,
                   author == AuthenticationService.shared.userId!
                {
                    let status: MessageStatus = message.isRead ? .read : message.isDelivered ? .delivered : message.isSent ? .sent : .none
//                    item.lastMessageStatusRawValue = status.rawValue
//                    PersistenceController.shared.save()
                }
            default:
                return
            }
        }
        
        func handleGroup(_ group: ChatGroup, change: DataEventType) {
            switch change {
            case .childAdded:
                addGroup(from: group)
            case .childChanged:
                addGroup(from: group)
            default:
                return
            }
        }
        
        func handleThread(_ thread: ChatThread, change: DataEventType) {
            switch change {
            case .childAdded:
                let item: HwChatThread = unimplemented()
//                addGroup(from: group)
            case .childChanged:
                let item: HwChatThread = unimplemented()
//                addGroup(from: group)
            default:
                return
            }
        }
        
        func addGroup(from chat: ChatGroup){
            let groupName = chat.isChat ? chat.members.values.filter({$0.phoneNumber != authenticationService.phoneNumber!}).first!.phoneNumber : chat.groupName
            let members = Array(chat.members.values)
            let taskContext = persistenceController.container.newBackgroundContext()
            taskContext.perform { [weak self] in
//                guard let self = self else {
//                    return
//                }
                
                let item = HwChatGroup(context: taskContext)
                item.groupId = chat.group
                item.groupName = groupName
                item.isChat = chat.isChat
                
                let defaultChannel = HwChatChannel(context: taskContext)
                defaultChannel.channelId = chat.defaultChannel.channelUid
                defaultChannel.channelName = chat.defaultChannel.title
                
                item.defaultChannel = defaultChannel
                
                for member in members {
                    let groupMember = HwGroupMember(context: taskContext)
                    groupMember.uid = member.uid
                    groupMember.phoneNumber = member.phoneNumber
                    groupMember.groupId = chat.group
                }
                
                do {
                    try taskContext.save()
                } catch {
                    fatalError("Failure to save context: \(error)")
                }
            }
        }
        
        func addMessage(){
            let taskContext = persistenceController.container.newBackgroundContext()
            taskContext.perform { [weak self] in
                guard let self = self else {
                    return
                }
                
                let message = SampleData.shared.getMessage(managedObjectContext: taskContext, text: "New Incoming Message")
                
                let fetchRequest: NSFetchRequest<HwChatListItem> = HwChatListItem.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "groupId = %@", SampleData.shared.groupId)
                
                guard let results = try? taskContext.fetch(fetchRequest),
                      let listItem = results.first else {
                          return
                      }
                
                listItem.lastMessageText =  message.text?.string
                listItem.lastMessageSender = message.sender
                listItem.lastMessageId = message.messageId
                listItem.lastMessageDate = message.timestamp
                listItem.lastMessageAttrText = message.text
                listItem.lastMessageAuthorUid = message.author
                
                if message.author == self.authenticationService.userId! {
                    listItem.lastMessageStatus = message.status
                }
                listItem.unreadCount += 1
                
                do {
                    try taskContext.save()
                } catch {
                    fatalError("Failure to save context: \(error)")
                }
            }
        }
        
        func addChannels(for chat: ChatGroup){
            ref.child(DatabaseHelper.pathUserChannels)
                .child(authenticationService.userId!)
                .child(chat.group)
                .observeSingleEvent(of: .value, with: { snapshot in
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
                        chat.updateChannels(channels: chats)
                    }
                })
            
        }
        
        func updateDeliveredReceipt(for message: ChatMessage){
            guard !message.isDeliveredToCurrUser else {
                return
            }
            ChatRepository.updateDeliveredReceipt(for: message)
        }
        
        func clearTemp() {
//            items = items.filter({!$0.group.isTemp})
//            chatDataModel.removeTempData()
//            print("Starting: Remove Temp Chat List Items")
//            let context = persistenceController.container.newBackgroundContext()
//            removeTempGroups(with: context)
//            removeTempListItems(with: context)
//
//            if context.hasChanges {
//                do {
//                    print("Attempting: Remove Temp Chat List Items")
//                        try context.save()
//                    } catch {
//                        fatalError("Failure to save context: \(error)")
//                    }
//            }

        }
        
        func removeTempListItems(with context: NSManagedObjectContext){
            let fetchRequest: NSFetchRequest<HwChatListItem> = HwChatListItem.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "isTemp = %d", true)
            if let results = try? context.fetch(fetchRequest) {

                for hwItem in results {
                    context.delete(hwItem)
                }
            }
        }
        
        func removeTempGroups(with context: NSManagedObjectContext){
            let fetchRequest: NSFetchRequest<HwChatGroup> = HwChatGroup.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "isTemp = %d", true)
            
            if let results = try? context.fetch(fetchRequest) {

                for hwItem in results {
                    context.delete(hwItem)
                }
                
            
            }
        }
        
        func getFullName(for phoneNumber: String)  -> String? {
            return contactRepository.getFullName(for: phoneNumber)
        }
        
        func clear(){
            ChatRepository.clear()
        }
        
        func changeArray(){
//            let content = UUID().uuidString
//            guard let chat = chatRepository?.array[0] else {return}
//            let item = Chat(id: chat.id, sender: chat.sender, timestamp: chat.timestamp, channel: chat.channel, channelName: chat.channelName, groupName: chat.groupName, message: UUID().uuidString, isChat: chat.isChat)
//            let item = TestItem(id: first.id, content: content)
//            chatRepository?.array[0] = item
            
            guard let key = chats.keys.first,
                  let chat = chats[key] else {return}

            let newChat = ChatListItem(id: chat.id, timestamp: chat.timestamp, channel: chat.channel, group: chat.group, channelName: chat.channelName, groupName: chat.groupName, message: ChatMessage(), isChat: chat.isChat, unreadCount: 0)

            chats[chat.id] = newChat
        }
        
        // MARK: - Remote
//        var groupsInitialDataLoaded = false
//        var channelMessagesInitialDataLoaded = false
//        var channelsInitialDataLoaded = false
//        var threadMessagesInitialDataLoaded = false
//        var threadsInitialDataLoaded = false
//        func addRemoteListener() {
//            // MARK: - Initial Data
//            _ = ref.child(DatabaseHelper.pathGroups).observe( .value, with: { [weak self] snapshot in
//                print("RemoteListener \(DatabaseHelper.pathChannelMessages) value")
//                guard let self = self else { return }
//                
//                self.groupsInitialDataLoaded = true
//            })
//            
//            _ = ref.child(DatabaseHelper.pathChannelMessages).observe( .value, with: { [weak self] snapshot in
//                print("RemoteListener \(DatabaseHelper.pathChannelMessages) value")
//                guard let self = self else { return }
//                
//                self.channelMessagesInitialDataLoaded = true
//            })
//            
//            _ = ref.child(DatabaseHelper.pathChannels).observe( .value, with: { [weak self] snapshot in
//                print("RemoteListener \(DatabaseHelper.pathChannels) value")
//                guard let self = self else { return }
//                
//                self.channelsInitialDataLoaded = true
//            })
//            
//            _ = ref.child(DatabaseHelper.pathThreadMessages).observe( .value, with: { [weak self] snapshot in
//                print("RemoteListener \(DatabaseHelper.pathThreadMessages) value")
//                guard let self = self else { return }
//                
//                self.threadMessagesInitialDataLoaded = true
//            })
//            
//            _ = ref.child(DatabaseHelper.pathThreads).observe( .value, with: { [weak self] snapshot in
//                print("RemoteListener \(DatabaseHelper.pathThreads) value")
//                guard let self = self else { return }
//                
//                self.threadsInitialDataLoaded = true
//            })
//            
//            // MARK: - Listeners
//            _ = ref.child(DatabaseHelper.pathChannelMessages).observe( .childAdded, with: { [weak self] snapshot in
//                print("RemoteListener \(DatabaseHelper.pathChannelMessages) childAdded")
//                guard let self = self,
//                    let value = snapshot.value as? [String: Any],
//                      let chatMessage = ChatMessage(dict: value ) else { return }
//                
//                //TODO because method will get called with all children on server restart
//                // check to see if the child is new or not
//                // For all existing children .childAdded will be called before .value
//                // (https://stackoverflow.com/questions/27978078/how-to-separate-initial-data-load-from-incremental-children-with-firebase)
//                
//                if self.channelMessagesInitialDataLoaded {
//                    ChatRepository.handleChannelMessage(chatMessage)
//                    if !chatMessage.isSystemMessage {
//                        ChatRepository.updateReceipts(chatMessage)
//                    }
//                }
//            })
//            
//            _ = ref.child(DatabaseHelper.pathChannelMessages).observe( .childChanged, with: { snapshot in
//                print("RemoteListener \(DatabaseHelper.pathChannelMessages) childChanged")
//                guard let value = snapshot.value as? [String: Any],
//                      let chatMessage = ChatMessage(dict: value ) else { return }
//                
//                ChatRepository.handleChannelMessage(chatMessage)
//            })
//            
//            _ = ref.child(DatabaseHelper.pathGroups).observe( .childAdded, with: { snapshot in
//                print("RemoteListener: \(DatabaseHelper.pathGroups) childAdded")
//                guard let value = snapshot.value as? [String: Any] else { return }
//                
//                guard let uid = value["uid"] as? String else { return }
//                guard let groupName = value["groupName"] as? String? else { return }
//                guard let author = value["author"] as? String else { return }
//                guard let membersDict = value["members"] as? [String: [String: Any]] else { return }
//                guard let isChat = value["isChat"] as? Bool else { return }
//                guard let defaultChannel = value["defaultChannel"] as? [String: Any] else { return }
//                
//                var members = [AppUser]()
//                for (_, childDict) in membersDict {
//                    let uid = childDict["uid"] as? String ?? ""
//                    let phoneNumber = childDict["phoneNumber"] as? String ?? ""
//                    let appUser = AppUser(uid: uid, phoneNumber: phoneNumber)
//                    members.append(appUser)
//                }
//                
//                guard let chat = ChatGroup(dict: value) else {return}
//                
//                if self.groupsInitialDataLoaded {
//                    ChatRepository.createChat(members, sender: author, group: uid, groupName: groupName, isChat: isChat, defaultChannel: defaultChannel)
//                    ChatRepository.createUserGroups(chat: chat, members: members, author: author)
//                }
//            })
//            
//            _ = ref.child(DatabaseHelper.pathGroups).observe( .childChanged, with: { snapshot in
//                print("RemoteListener: \(DatabaseHelper.pathGroups) childChanged")
//                guard let value = snapshot.value as? [String: Any] else { return }
////                guard let uid = value["uid"] as? String else { return }
////                guard let author = value["author"] as? String else { return }
////                guard let isChat = value["isChat"] as? Bool else { return }
////                guard let defaultChannel = value["defaultChannel"] as? [String: Any] else { return }
////                guard let groupName = value["groupName"] as? String? else { return }
//               
//                
//                guard let membersDict = value["members"] as? [String: [String: Any]] else { return }
//              
//                
//                var members = [AppUser]()
//                for (_, childDict) in membersDict {
//                    let uid = childDict["uid"] as? String ?? ""
//                    let phoneNumber = childDict["phoneNumber"] as? String ?? ""
//                    let appUser = AppUser(uid: uid, phoneNumber: phoneNumber)
//                    members.append(appUser)
//                }
//                guard let chat = ChatGroup(dict: value) else {return}
//                if self.groupsInitialDataLoaded {
//                    ChatRepository.updateUserGroups(chat, members: members)
//                }
//            })
//            
//            // When a channel is added to a new group.
//            _ = ref.child(DatabaseHelper.pathChannels).observe( .childAdded, with: { [weak self] snapshot in
//                print("RemoteListener: \(DatabaseHelper.pathChannels) childAdded")
//                guard let self = self,
//                      let value = snapshot.value as? [String: Any],
//                      let title = value["title"] as? String,
//                      let uid = value["uid"] as? String,
//                      let group = value["group"] as? String
//                else { return }
//                
//                if self.channelsInitialDataLoaded {
//                    ChatRepository.createUserChannel(group: group, channel: uid, channelName: title)
//                }
//            })
//            
//            // Will get called when a new thread is created
//            _ = ref.child(DatabaseHelper.pathThreads).observe( .childAdded, with: { [weak self] snapshot in
//                print("RemoteListener: \(DatabaseHelper.pathThreads) childAdded")
//                guard let self = self,
//                      let value = snapshot.value as? [String: Any],
//                      let title = value["title"] as? String,
//                      let uid = value["uid"] as? String,
//                      let group = value["group"] as? String,
//                      let channel = value["group"] as? String,
//                      let channelMessage = value["channelMessage"] as? [String: Any]?
//                else { return }
//                
//                if self.threadsInitialDataLoaded {
//                    let chatMessage = channelMessage != nil ? ChatMessage(dict: channelMessage!) : nil
//                    ChatRepository.createUserThreads(title: title, uid: uid, channel: channel, group: group, channelMessage: chatMessage)
//                }
//            })
//            
//            _ = ref.child(DatabaseHelper.pathThreadMessages).observe( .childAdded, with: { [weak self] snapshot in
//                print("RemoteListener \(DatabaseHelper.pathThreadMessages) childAdded")
//                guard let value = snapshot.value as? [String: Any],
//                      let self = self,
//                      let chatMessage = ChatMessage(dict: value ) else { return }
//                
//                if self.threadMessagesInitialDataLoaded {
//                    ChatRepository.handleChangeForAllMembers(chatMessage, change: .childAdded)
//                    if !chatMessage.isSystemMessage {
//                        ChatRepository.updateReceipts(chatMessage)
//                    }
//                }
//            })
//            
//            _ = ref.child(DatabaseHelper.pathThreadMessages).observe( .childChanged, with: { snapshot in
//                print("RemoteListener: \(DatabaseHelper.pathThreadMessages) childChanged")
//                
//                guard let value = snapshot.value as? [String: Any],
//                      let chatMessage = ChatMessage(dict: value ) else { return }
//                
//                ChatRepository.handleChangeForAllMembers(chatMessage, change: .childChanged)
//            })
//            
//            messageReceiptRef = ref.child(DatabaseHelper.pathMessageReceipts)
//            
//            _ = messageReceiptRef?.observe( .childAdded, with: { snapshot in
//                print("ChatView \(DatabaseHelper.pathMessageReceipts) childAdded called")
//                guard let value = snapshot.value as? [String: Any],
//                      let messageReceipt = MessageReceipt(dict: value)
//                      else {
//                    return
//                }
//                ChatRepository.updateMessage(messageReceipt)
//            })
//            
//            _ = messageReceiptRef?.observe( .childChanged, with: { snapshot in
//                print("ChatView \(DatabaseHelper.pathMessageReceipts) childChanged called")
//                
//                guard let value = snapshot.value as? [String: Any],
//                      let messageReceipt = MessageReceipt(dict: value)
//                      else {
//                    return
//                }
//                ChatRepository.updateMessage(messageReceipt)
//            })
//        }
    }
}
