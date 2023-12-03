//
//  ThreadMessagesView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-01-19.
//

import SwiftUI
import FirebaseAnalytics

struct ThreadMessagesView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var notificationDelegate: NotificationDelegate
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var persistenceController: PersistenceController
    @EnvironmentObject var contactRespository: ContactRepository
    
    var inMemory: Bool = false
    var chat: ChatGroup
    @ObservedObject var thread: ChatThreadModel
    
    @State var size: CGSize = CGSize(width: 0, height: 50)
    @StateObject var autocompleteDataModel = AutocompleteDataModel()
    @State var showAutocompleteView: Bool = false
    @State var showReplyView: Bool = false
    @State var selectedReplyItem: ReplyItem?
    @StateObject private var model = Model()
    @State var showChangeThreadTitle: Bool = false
    @State var showImagePicker: Bool = false
    
    var body: some View {
        VStack(spacing: 0){
//            Text("\(chat.group) \(thread.threadUid)")
            ZStack(alignment: Alignment(horizontal: .leading, vertical: .bottom)) {
                TestMessagesView(chat: chat, threadId: thread.threadUid)
                if model.channelNotificationCount > 0 {
                    Button {
                        dismiss()
                        model.resetChannelNotificationCount()
                        
        //                            model.scrollTo = .bottonWithAnimation
                    } label: {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 26))
                            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                            .frame(width: 46, height: 46)
                            .background(RoundedRectangle(cornerRadius: 5).fill(Color(UIColor.secondarySystemBackground)))
                    }
                    .overlay(Badge(count: model.channelNotificationCount))
                    .alignmentGuide(.bottom) { d in
                        d[.bottom] + 10
                    }
                }
            }
//            TextField("Input", text: .constant(""))
            MessagesInputBarView(size: $size, isFirstResponder: .constant(false), showImagePicker: $showImagePicker, send: send(_:))
                .frame(height: size.height)
        }
        .onChange(of: notificationDelegate.selectedThread, perform: { newValue in
            print("ThreadMessagesView: notificationDelegate selectedThread changed \(String(describing: newValue))")
            if let threadId = newValue, threadId != thread.threadUid {
                dismiss()
            }
        })
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            model.performOnceOnAppear(inMemory: inMemory, chat: chat, thread: thread)
            model.markAllAsRead()
            model.resetUnreadCount()
            model.markAsRecent()
            
            notificationDelegate.currentView = thread.threadUid
        }
        .onDisappear {
            model.resetUnreadCount()
            
            notificationDelegate.currentView = ""
            if let currentThreadId = notificationDelegate.selectedThread,
               currentThreadId == thread.threadUid {
                notificationDelegate.selectedThread = nil
            }
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(thread.title.string)
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)
                    Text("Tap here change name")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .onTapGesture {
                    showChangeThreadTitle = true
                }
            }
            
//            ToolbarItem(placement: .navigationBarTrailing) {
//                                Button(action: {
//
//                                }) {
//                                    Text("Mute")
//                                }
//
//            }
        }
        .sheet(isPresented: $showChangeThreadTitle, content: {
            ChangeThreadTitleView(thread: thread)
        })
        .fullScreenCover(isPresented: $showImagePicker) {
            SendImageView(chat: chat, completion: send(_:))
            
        }
    }
}

extension ThreadMessagesView {
    func send(_ message: HwMessage) {
        let isTempChatGroup = chat.isTemp
        let isTempThread = thread.isTemp

        let chatMessageId = PushIdGenerator.shared.generatePushID()
        
        // Api
        func handleError(_ error: Error) {
            print("ChannelMessagesView Error: \(error.localizedDescription)")
        }
        
        if isTempChatGroup {
            let addGroupModel = AddGroupModel(author: authenticationService.account.userId!, group: chat.group, groupName: chat.groupName, isChat: true, defaultChannel: AddChannelModel(channelUid: chat.defaultChannel.channelUid, title: chat.defaultChannel.title, group: chat.defaultChannel.group), members: chat.members)
            _ = persistenceController.insertGroup(addGroupModel)
            chat.isTemp = false
            authenticationService.account.addGroup(chat) { _, error in
                if let error = error {
                    print("ChannelMessagesView Error: \(error)")
                }
            }
            
            FirebaseAnalytics.Analytics.logEvent("add_group", parameters: nil)
        }
        
        if isTempThread {
            var members = thread.members
            if thread.members.isEmpty, let threadMembers = persistenceController.loadGroupMembers(chat.group) {
                members = threadMembers
            }
            
            let model = AddThreadModel(author: authenticationService.account.userId!, threadUid: thread.threadUid, group: thread.group, title: getMessage(from: thread.title), replyingTo: nil, members: members)
            
            _ = persistenceController.insertThread(model)
            thread.isTemp = false
            
            authenticationService.account.addThread(threadUid: thread.threadUid, group: thread.group, title: thread.title, replyingTo: nil, members: members) { _, error in
                if let error = error {
                    print("ChannelMessagesView Error: \(error)")
                }
            }
            
            FirebaseAnalytics.Analytics.logEvent("add_thread", parameters: nil)
        }
        
        
        // Core Data
        let addMessageModel = AddMessageModel(id: chatMessageId, author: authenticationService.account.userId!, sender: authenticationService.account.phoneNumber!, timestamp: Date(), channel: nil, group: chat.group, message: message, thread: thread.threadUid, replyingInThreadTo: nil, senderPublicKey: authenticationService.account.getPublicKey()!.base64EncodedString(), isOutgoingMessage: true)
        _ = persistenceController.insertMessage(addMessageModel)
        
        FirebaseAnalytics.Analytics.logEvent("send_thread_message", parameters: nil)
    }
}

struct ThreadMessagesView_Previews: PreviewProvider {
    static var previews: some View {
//        ThreadMessagesView(model: ThreadMessagesView.Model(inMemory: true, hwThread: ChatThreadModel(threadUid: SampleData.shared.threadId, group: SampleData.shared.groupId, title: HwMessage(content: "Thread Title", mentions: [], links: []), replyingTo: nil, isTemp: false)))
        ThreadMessagesView(inMemory: true, chat: ChatGroup.preview, thread: ChatThreadModel.preview)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AuthenticationService.preview)
        .environmentObject(ContactRepository.preview)
        .environmentObject(NotificationDelegate.shared)
        .environmentObject(PersistenceController.preview)
    }
}

import CoreData
import Combine
import PromiseKit

extension ThreadMessagesView {
    class Model: ObservableObject {
        @Published var members: [AppUser] = []
        @Published var derivedName: String = ""
        @Published var channelNotificationCount: Int16 = 0
        
        //init params
        var threadId: String!
        var inMemory: Bool
        var thread: ChatThreadModel!
        var chat: ChatGroup!
        
        private var contactRepository: ContactRepository
        private var authenticationService: AuthenticationService
        var persistenceController: PersistenceController
        private var managedObjectContext: NSManagedObjectContext
        private var fetchedResultsController: NSFetchedResultsController<HwThreadMember>!
        private var groupChannelNotificationController: GroupChannelNotificationController!
        private var initialized: Bool = false
        
        private var cancellables: Set<AnyCancellable> = []
        
        //For temp threads
        init(inMemory: Bool = false){
            print("ThreadMessagesView: init")
            self.inMemory = inMemory
            
            if inMemory {
                contactRepository = ContactRepository.preview
                persistenceController = PersistenceController.preview
                managedObjectContext = PersistenceController.preview.container.viewContext
                authenticationService = AuthenticationService.preview
            } else {
                contactRepository = ContactRepository.shared
                persistenceController = PersistenceController.shared
                managedObjectContext = PersistenceController.shared.container.viewContext
                authenticationService = AuthenticationService.shared
            }
            
            
        }
        
        func performOnceOnAppear(inMemory: Bool = false, chat: ChatGroup, thread: ChatThreadModel){
            guard !initialized else {
                return
            }
            
            self.chat = chat
            self.thread = thread
            self.threadId = thread.threadUid
            
            if !thread.isTemp {
                fetchGroupMembers()
            }
            
            groupChannelNotificationController = GroupChannelNotificationController(channelId: chat.defaultChannel.channelUid, authenticationService: authenticationService, managedObjectContext: managedObjectContext)
            addSubscribers()
//            fetchThread()
//            fetchGroupMembers()
            loadDerivedName()
            initialized = true
        }
        
        func addSubscribers() {
            groupChannelNotificationController.$count.assign(to: &$channelNotificationCount)
        }
        
        func resetChannelNotificationCount() {
            groupChannelNotificationController.resetCount()
        }
        
        func loadDerivedName(){
            let title = thread.title
            DispatchQueue.global(qos: .userInitiated).async {
                let derivedName = modifiedAttributedString(from: title, contactRepository: self.contactRepository).string
                DispatchQueue.main.async {
                    self.derivedName = derivedName
                }
            }
        }
        
        func fetchThread(){
            let fetchRequest: NSFetchRequest<HwChatThread> = HwChatThread.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatThread.threadId), self.threadId)
            if let results = try? managedObjectContext.fetch(fetchRequest),
               let item = results.first {
                let thread = ChatThreadModel(threadUid: item.threadId!, group: item.groupId!, title: item.titleText!, replyingTo: item.replyingTo, isTemp: false, members: [:], chat: chat)
                self.thread = thread
                loadDerivedName()
            }
        }
        
        func fetchGroupMembers(){
            persistenceController.container.performBackgroundTask { context in
                let fetchRequest: NSFetchRequest<HwThreadMember> = HwThreadMember.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwThreadMember.threadId), self.threadId)
                if let results = try? context.fetch(fetchRequest) {
                    var members = [AppUser]()
                    for hwItem in results {
                        let uid = hwItem.uid!
                        let phoneNumber = hwItem.phoneNumber!
                        let member = AppUser(uid: uid, phoneNumber: phoneNumber)
                        members.append(member)
                    }
                    
                    DispatchQueue.main.async {
                        self.members = members
                    }
                }
            }
        }
        
        func markAsRecent(){
            guard let threadId = threadId else {
                return
            }
        
            persistenceController.enqueue { context in
                let fetchRequest: NSFetchRequest<HwChatThread> = HwChatThread.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatThread.threadId), threadId)
                
                if let results = try? context.fetch(fetchRequest),
                   let item = results.first {
                    item.timestamp = Date()
                }
            }
        }
        
        func resetUnreadCount(){
            guard let threadId = threadId else {
                return
            }
            
            let groupId = chat.group
            
            //update list item unread count
            persistenceController.enqueue { context in
                let fetchRequest: NSFetchRequest<HwThreadListItem> = HwThreadListItem.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwThreadListItem.threadId), threadId)
                
                var currentCount: Int16 = 0
                if let results = try? context.fetch(fetchRequest),
                   let item = results.first {
                    currentCount = item.unreadCount
                    item.unreadCount = 0
                }
                
                let request: NSFetchRequest<HwChatListItem> = HwChatListItem.fetchRequest()
                request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatListItem.groupId),groupId)
                
                if let results = try? context.fetch(request),
                   let item = results.first {
                    if currentCount > item.threadUnreadCount {
                        item.threadUnreadCount = 0
                    } else {
                        item.threadUnreadCount -= currentCount
                    }
                }
            }
        }
        
        func markAllAsRead(){
            if !inMemory {
                firstly {
                    fetchUnreadMessages()
                }.then { receipts in
                    AuthenticationService.shared.account.addReadReceipts(receipts: receipts)
                }.done { receipts in
                    let messageIdArray = receipts.map({ $0.messageId })
                    PersistenceController.shared.enqueue { context in
                        let fetchRequest: NSFetchRequest<HwChatMessage> = HwChatMessage.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "%K IN %@",#keyPath(HwChatMessage.messageId), messageIdArray)

                        guard let results = try? context.fetch(fetchRequest) else {
                            return
                        }

                        for item in results {
                            item.isReadByMe = true
                        }
                    }
                }.catch { error in
                    print("Error occured while marking read")
                }
            }
        }
        
        func fetchUnreadMessages() -> Promise<[ReadReceipt]>  {
            return Promise { seal in
                let fetchRequest: NSFetchRequest<HwChatMessage> = HwChatMessage.fetchRequest()
                
                fetchRequest.predicate = NSPredicate(format: "%K = %@ AND %K = FALSE AND %K != %@", #keyPath(HwChatMessage.threadUid), threadId, #keyPath(HwChatMessage.isReadByMe),#keyPath(HwChatMessage.author), authenticationService.account.userId!)
                
                let asyncFetchRequest =
                NSAsynchronousFetchRequest<HwChatMessage>(
                    fetchRequest: fetchRequest) { (result: NSAsynchronousFetchResult) in
                        
                        guard let hwItems = result.finalResult else {
                            return
                        }
                        
                        var receipts: [ReadReceipt] = []
                        for item in hwItems {
                            let read = ReadReceipt(author: item.author!, messageId: item.messageId!)
                            receipts.append(read)
                        }
                        
                        seal.fulfill(receipts)
                        
                    }
                
                do {
                    try managedObjectContext.execute(asyncFetchRequest)
                } catch let error as NSError {
                    print("Could not fetch \(error), \(error.userInfo)")
                    seal.reject(error)
                }
            }
        }
    }
}
