//
//  ChannelMessagesView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-01-17.
//

import SwiftUI
import Introspect
import BottomSheet
import FirebaseAnalytics
import Sentry

struct ReplyItem {
    let item: HwChatMessage
    var isThreadReply: Bool = false
}

struct ChannelMessagesView: View {
    @Environment(\.isPresented) var isPresented
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var notificationDelegate: NotificationDelegate
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var contactRespository: ContactRepository
    @EnvironmentObject private var persistenceController: PersistenceController
    
    var inMemory: Bool = false
    var chat: ChatGroup
    
    @State var size: CGSize = CGSize(width: 0, height: 50)
    @StateObject var autocompleteDataModel = AutocompleteDataModel()
    @State var showAutocompleteView: Bool = false
    @State var showReplyView: Bool = false
    @State var selectedReplyItem: ReplyItem?
    @State var sendMessageInThread: Bool = false
    @State var showSendMode: Bool = true
    @State var showThreads: Bool = false
    @State var showUserInfo: Bool = false
    @State var showCreatedThread: Bool = false
    @State var createdThreadId: String? = nil
    @State var text: String = ""
    @State var tempThread: ChatThreadModel? = ChatThreadModel.temp
    @State var showTempThread: Bool = false
    @State var initialized: Bool = false
    @State var showLatestThread: Bool = false
    @State var showThreadList: Bool = false
    @State var bottomSheetPosition: BottomSheetPosition = .hidden
    @State var showImagePicker: Bool = false
    @State var selectedImage: UIImage? = nil
    
    @StateObject private var model = Model()
    
    func toggleReplyMode(){
        self.selectedReplyItem?.isThreadReply.toggle()
    }
    
    func onSendPerform(){
//        let content = "Hello @+16505553535 loooooooooooong meesssssaaaagggggeeeee"
//        let mention = Mention(range: NSMakeRange(6, 13), uid: UUID().uuidString, phoneNumber: "+16505553434")
//        let message = HwMessage(content: content, mentions: [mention], links: [])
//        if model.inMemory {
//            let _ = model.persistInCoreData(message, withReplyTo: selectedReplyItem)
//        } else {
//            model.sendMessage(message, withReplyTo: selectedReplyItem)
//        }
//
        selectedReplyItem = nil
    }
    
    func getFullName() -> String {
        return contactRespository.getFullName(for: chat.groupName)
    }
    
    var body: some View {
        VStack(spacing: 0){
//            Text("\(chat.group) \(chat.defaultChannel.channelUid)")
//            if let createdThreadId = createdThreadId {
//                NavigationLink(destination: LazyDestination {
//                    ThreadMessagesView(model: ThreadMessagesView.Model(chat: chat, threadId: createdThreadId))
//                }, isActive: $showCreatedThread){
//                    EmptyView()
//                }
//            }
            NavigationLink(destination: LazyDestination{
                ThreadMessagesView(chat: model.chat, thread: model.fetchLatestThread()! )
                    
//                    .onDisappear {
//                        //this is slower than onAppear on parent
//                        // tempGroup = nil
//                    }
                
            }, isActive: $showLatestThread) { EmptyView() }
           
            
            ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom)) {
                TestMessagesView(inMemory: inMemory, chat: chat, channelId: chat.defaultChannel.channelUid)
                
//                if chat.isTemp {
//                    Text("Tap the \(Image(systemName: "square.and.pencil")) icon to start a new chat.")
//                        .multilineTextAlignment(.center)
//                }
                
                VStack(alignment: .trailing) {
                    FloatingActionButton(hint: "Start Topic", icon: "plus.bubble") {
                        let threadUid = PushIdGenerator.shared.generatePushID()
                        let title =  attributedString(with: HwMessage(content: "New Topic", mentions: [], links: []), contactRepository: contactRespository)
                        let thread = ChatThreadModel(threadUid: threadUid, group: chat.group, title: title, replyingTo: nil, isTemp: true, members: chat.members, chat: chat)
                        tempThread = thread
                        showTempThread = true
                    }
                    
                    FloatingActionButton(hint: "Topics", icon: "list.bullet") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        showThreadList = true
                        bottomSheetPosition = .middle
                    }
                    .overlay(Badge(count: model.threadNotificationCount).offset(x: -10, y: 0))
                    
                    if let thread = model.mostRecentThread, model.recentThreadNotificationsCount > 0 {
                        FloatingActionButton(hint: "Show latest topic", icon: "chevron.right") {
                            tempThread = thread
                            showTempThread = true
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .overlay(Badge(count: model.recentThreadNotificationsCount).offset(x: -10, y: 0))
                    }
                    
                    
                    
                }
                .alignmentGuide(.bottom, computeValue: {d in d[.bottom] + 60})
                
                VStack(spacing: 0){
                    Spacer()
                    if showAutocompleteView {
                        AutocompleteListView(dataModel: autocompleteDataModel)
                    }
                    
                    
                    if let replyItem = selectedReplyItem {
                        VStack {
                            HStack {
                                ReplyingToLineShape()
                                    .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                                    .frame(width: 30, height: 40 )
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(contactRespository.getFullName(for: replyItem.item.sender!))
                                            .font(.body)
                                            .fontWeight(.bold)
                                        Text(modifiedAttributedString(from: replyItem.item.text!, contactRepository: contactRespository, authenticationService: authenticationService).string)
                                            .font(.footnote)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    VStack {
                                        Button(action: {self.selectedReplyItem = nil}, label: {
                                            Image(systemName: "xmark.circle")
                                        })
                                        
                                    }
                                }
                                .padding(7)
                                .background(RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(UIColor.secondarySystemBackground)))
                            }
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 50, idealHeight: 50, maxHeight: 50)
                        .background(colorScheme == .dark ? Color.gray : Color(UIColor.systemGray6))
                        }
                    }
                }
            }
//            .border(Color.red, width: 4)
                
                
//                Button {
//                    onSendPerform()
//                } label: {
//                    Text("Send")
//                }
//                TextField("Input", text: .constant(""))
                MessagesInputBarView(size: $size, isFirstResponder: .constant(false), showImagePicker: $showImagePicker, send: send(_:))
                .frame(height: size.height)
//            .border(Color.red, width: 4)
//            ForEach(model.members, id: \.uid){ item in
//                Text(item.fullName)
//            }
        }
        .background(
            Group {
                if let tempThread = tempThread {
                    NavigationLink(destination: LazyDestination{
                        ThreadMessagesView(chat: model.chat, thread: tempThread )
                            .onDisappear {
                                //this is slower than onAppear on parent
                                // tempGroup = nil
                            }
                        
                    }, isActive: $showTempThread) { EmptyView() }
                    .onAppear{
                        print("ChannelMessagesView: NavigationLink onAppear")
                    }
                }
                
                NavigationLink(destination: UserInfoView(phoneNumber: chat.groupName), isActive: $showUserInfo) {
                    EmptyView()
                }
            }
        )
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: sendMessageInThread) { newValue in
            toggleReplyMode()
            showSendMode = true
        }
        .onChange(of: showThreadList, perform: { newValue in
            print("ChannelMessagesView: showThreadList \(newValue)")
        })
        .onChange(of: notificationDelegate.selectedThread, perform: { newValue in
            print("ChannelMessagesView: notificationDelegate selectedThread changed \(String(describing: newValue)) isPresented \(isPresented)")
            if let threadId = newValue,
               let thread = model.fetchThread(threadId: threadId) {
                tempThread = thread
                if isPresented {
                    showTempThread = true
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                        showTempThread = true
                    }
                }
            }
//            if newValue != thread.threadUid {
//                dismiss()
//            }
        })
        .onAppear {
            model.chat = chat
            model.groupId = chat.group
            model.performOnceOnAppear()
            model.markAllAsRead()
            model.resetUnreadCount()
            notificationDelegate.currentView = chat.defaultChannel.channelUid
            print("ChannelMessagesView: onAppear \(initialized)")
            
            guard !initialized else {
                return
            }
            
            if let threadId = notificationDelegate.selectedThread,
               let thread = model.fetchThread(threadId: threadId) {
                tempThread = thread
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75){
                    showTempThread = true
                }
            } else if let item = chat.hwListItem,
                        item.unreadCount > 0, let threadId = item.threadId,
               let thread = model.fetchThread(threadId: threadId) {
                print("ChannelMessagesView: showLatestThread")
                tempThread = thread
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75){
                    showTempThread = true
                }
            }
            
            initialized = true
        }
        .onDisappear {
            model.resetUnreadCount()
            notificationDelegate.currentView = ""
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button {
                    showUserInfo = true
                } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(getFullName())
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text("Tap here for more info")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }


            }
            ToolbarItem(placement: .navigationBarTrailing) {
//                NavigationLink(destination: LazyDestination{
//                    GroupThreadsView(model: GroupThreadsView.Model(chat: model.chat))
//                }) { Text("Threads") }
                Button(action: {
                    let threadUid = PushIdGenerator.shared.generatePushID()
                    let title =  attributedString(with: HwMessage(content: "New Topic", mentions: [], links: []), contactRepository: contactRespository)
                    let thread = ChatThreadModel(threadUid: threadUid, group: chat.group, title: title, replyingTo: nil, isTemp: true, members: chat.members, chat: chat)
                    tempThread = thread
                    showTempThread = true
                }) {
                    Text("Start Topic")
                        .padding(5)
                }
            }
        }
        .bottomSheet(bottomSheetPosition: $bottomSheetPosition, options: [.appleScrollBehavior, .swipeToDismiss, .tapToDismiss, .background({AnyView(Color(uiColor: UIColor.systemGroupedBackground))})], title: "Topics", content: {
            GroupThreadsModalView(chat: chat, tempThread: $tempThread, showTempThread: $showTempThread) {
                showThreadList = false
                bottomSheetPosition = .hidden
            }
            .onChange(of: bottomSheetPosition, perform: { [bottomSheetPosition] newValue in
                
                if (bottomSheetPosition == .middle || bottomSheetPosition == .top ) && newValue == .hidden {
                    print("ChannelMessagesView: Threads hidden")
//                    model.resetThreadUnreadCount()
                }
            })
                .environmentObject(authenticationService)
        })
        .fullScreenCover(isPresented: $showImagePicker) {
            SendImageView(chat: chat, completion: send(_:))
        }
//        .adaptiveSheet(isPresented: $showThreadList, detents: [.medium(), .large()], smallestUndimmedDetentIdentifier: .large) {
//
//        }
//        .sheet(isPresented: $showAutocompleteView) {
//            PhotoPicker(selectedImage: $selectedImage)
//        }
//        .sheet(isPresented: $showThreadList, content: {
//            GroupThreadsModalView(chat: chat, tempThread: $tempThread, showTempThread: $showTempThread){
//                                showThreadList.toggle()
//                            }
//        .environmentObject(authenticationService)
//        })
//        .frame(height: 1000)
    }
}

extension ChannelMessagesView {
    func send(_ message: HwMessage) {
        let isTempChatGroup = chat.isTemp
        let chatMessageId = PushIdGenerator.shared.generatePushID()
        let channelUid = chat.defaultChannel.channelUid
        
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
                    SentrySDK.capture(error: error)
                }
            }
            FirebaseAnalytics.Analytics.logEvent("add_group", parameters: nil)
        }
        
        
        // Core Data
        let addMessageModel = AddMessageModel(id: chatMessageId, author: authenticationService.account.userId!, sender: authenticationService.account.phoneNumber!, timestamp: Date(), channel: channelUid, group: chat.group, message: message, thread: nil, replyingInThreadTo: nil, senderPublicKey: authenticationService.account.getPublicKey()!.base64EncodedString(), isOutgoingMessage: true)
        _ = persistenceController.insertMessage(addMessageModel)
        
        FirebaseAnalytics.Analytics.logEvent("send_channel_message", parameters: nil)
    }
}

struct ChannelMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChannelMessagesView(inMemory: true, chat: ChatGroup.preview)
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environmentObject(AuthenticationService.preview)
            .environmentObject(ContactRepository.preview)
            .environmentObject(NotificationDelegate.shared)
            .environmentObject(PersistenceController.preview)
        }
        .preferredColorScheme(.dark)
    }
}

import CoreData
import Combine
import PromiseKit

extension ChannelMessagesView{
    class Model: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
        @Published var members: [GroupMember] = []
        @Published var threadListItems: [HwThreadListItem] = []
        @Published var derivedName: String = ""
        @Published var threadIds = [String]()
        @Published var threadNotificationCount: Int16 = 0
        @Published var mostRecentThread:ChatThreadModel? = nil
        @Published var recentThreadNotificationsCount: Int16 = 0
        
        //init params
        var chat: ChatGroup!
        var groupId: String!
        var inMemory: Bool
        
        private var contactRepository: ContactRepository
        private var authenticationService: AuthenticationService
        var persistenceController: PersistenceController
        private var managedObjectContext: NSManagedObjectContext
        private var fetchedResultsController: NSFetchedResultsController<HwGroupMember>!
        private var groupThreadsController: GroupThreadsController!
        private var groupThreadsNotificationController: GroupThreadsNotificationController!
        private var recentsController: GroupRecentThreadController!
        var initialized: Bool = false
        
        private var cancellables: Set<AnyCancellable> = []
        
        init(inMemory: Bool = false){
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
            super.init()
        }
        
        func performOnceOnAppear(){
            guard !initialized else {
                return
            }
            
            defer {
                initialized = true
            }
            
            threadIds.append(chat.defaultChannel.channelUid)
            fetchGroupMembers()
            groupThreadsNotificationController = GroupThreadsNotificationController(groupId: chat.group, managedObjectContext: managedObjectContext)
            recentsController = GroupRecentThreadController(groupId: chat.group, authenticationService: authenticationService, managedObjectContext: managedObjectContext)
            addSubscribers()
        }
        
        func addSubscribers() {
            groupThreadsNotificationController.$count.assign(to: &$threadNotificationCount)
            recentsController.$thread.assign(to: &$mostRecentThread)
            recentsController.$count.assign(to: &$recentThreadNotificationsCount)
        }
        
        func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
            switch type {
            case .insert:
                if let item = anObject as? HwGroupMember {
                    print("Inserted new member \(item.phoneNumber!)")
                    let uid = item.uid!
                    let phoneNumber = item.phoneNumber!
                    let member = AppUser(uid: uid, phoneNumber: phoneNumber)
                    self.chat.addMembers(appUsers: [member])
                }
            case .delete:
                if let item = anObject as? HwGroupMember {
                    print("Deleted new message \(item.phoneNumber!)")
                }
            case .move:
                break
            case .update:
                if let item = anObject as? HwGroupMember {
                    print("Updated message \(item.phoneNumber!)")
                }
            @unknown default:
                break
            }
        }
        
        func fetchGroupMembers(){
            if fetchedResultsController == nil {
                let request: NSFetchRequest<HwGroupMember> = HwGroupMember.fetchRequest()
                request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwGroupMember.groupId), self.groupId)
                request.sortDescriptors = [
                    NSSortDescriptor(
                        keyPath: \HwGroupMember.uid,
                        ascending: false)]
                
                
                fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
                fetchedResultsController.delegate = self
            }
            
            
            do {
                try fetchedResultsController.performFetch()
                if let results = fetchedResultsController.fetchedObjects {
                    var members = [AppUser]()
                    for hwItem in results {
                        let uid = hwItem.uid!
                        let phoneNumber = hwItem.phoneNumber!
//                        let fullName = self.contactRepository.getFullName(for: phoneNumber) ?? phoneNumber
                        let member = AppUser(uid: uid, phoneNumber: phoneNumber)
                        members.append(member)
                    }
                    
                    DispatchQueue.main.async {
//                        self.members = members
                        self.chat.addMembers(appUsers: members)
                    }
                }
            } catch {
                fatalError("Failed to fetch entities: \(error)")
            }
        }
        
        func fetchLatestThread() -> ChatThreadModel? {
            let request: NSFetchRequest<HwThreadListItem> = HwThreadListItem.fetchRequest()
            request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwThreadListItem.groupId), groupId)
            
            request.sortDescriptors = [
                NSSortDescriptor(
                    keyPath: \HwThreadListItem.lastMessageDate,
                    ascending: false)]
            
            request.fetchLimit = 1
            
            do {
                let results = try managedObjectContext.fetch(request)
                if let listItem = results.first,
                   let hwThread = listItem.thread {
                    return ChatThreadModel(from: hwThread)
                }
            } catch {
                print("Could not fetch. \(error)")
            }
            
            return nil
        }
        
        func fetchThread( threadId: String) -> ChatThreadModel? {
            let request: NSFetchRequest<HwChatThread> = HwChatThread.fetchRequest()
            request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatThread.threadId), threadId)
            
            do {
                let results = try managedObjectContext.fetch(request)
                if let item = results.first {
                    return ChatThreadModel(from: item)
                }
            } catch {
                print("Could not fetch. \(error)")
            }
            
            return nil
        }
        
        func fetchGroupThreadIds(){
            var asyncFetchRequest: NSAsynchronousFetchRequest<HwChatThread>?
            
            let request: NSFetchRequest<HwChatThread> = HwChatThread.fetchRequest()
            request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatThread.groupId), chat.group)
            
            request.sortDescriptors = [
                NSSortDescriptor(
                    keyPath: \HwChatThread.timestamp,
                    ascending: true)]
            
            asyncFetchRequest = NSAsynchronousFetchRequest<HwChatThread>(
                fetchRequest: request) {
                    [weak self] (result: NSAsynchronousFetchResult) in
                    
                    guard let strongSelf = self, let hwItems = result.finalResult else {
                        return
                    }
                    
                    var threadIds = [String]()
                    for item in hwItems {
                        if let threadId = item.threadId, !strongSelf.threadIds.contains(threadId){
                            threadIds.append(threadId)
                        }
                    }
                    
                    strongSelf.threadIds.append(contentsOf: threadIds)
                }
            
            do {
                guard let asyncFetchRequest = asyncFetchRequest else {
                    return
                }
                try managedObjectContext.execute(asyncFetchRequest)
            } catch let error as NSError {
                print("Could not fetch \(error), \(error.userInfo)")
            }
        }
        
        func resetUnreadCount(){
            guard let groupId = groupId else {
                return
            }
            
            //update list item unread count
            persistenceController.enqueue { context in
                let fetchRequest: NSFetchRequest<HwChatListItem> = HwChatListItem.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "groupId = %@", groupId)
                
                if let results = try? context.fetch(fetchRequest),
                   let item = results.first {
                    item.unreadCount = 0
                }
            }
        }
        
        func resetThreadUnreadCount(){
            guard let groupId = groupId else {
                return
            }
            
            //update list item unread count
            persistenceController.enqueue { context in
                let fetchRequest: NSFetchRequest<HwChatListItem> = HwChatListItem.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "groupId = %@", groupId)
                
                if let results = try? context.fetch(fetchRequest),
                   let item = results.first {
                    item.threadUnreadCount = 0
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
                
                fetchRequest.predicate = NSPredicate(format: "%K = %@ AND %K = FALSE AND %K != %@", #keyPath(HwChatMessage.groupUid), groupId, #keyPath(HwChatMessage.isReadByMe),#keyPath(HwChatMessage.author), authenticationService.account.userId!)
                
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
