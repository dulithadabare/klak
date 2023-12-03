//
//  TestMessagesView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-22.
//

import SwiftUI

struct CoverImage: Identifiable {
    var id: URL {
        return url
    }
    let url: URL
}

struct TestMessagesView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var contactRespository: ContactRepository
    
    var inMemory: Bool = false
    var chat: ChatGroup
    var channelId: String?
    var threadId: String?
    
    @State private var scrollViewData: ScrollViewData = ScrollViewData(contentSize: .zero, contentOffset: .zero)
    @State private var currOffset: CGFloat = .zero
    @State private var contentSize: CGSize = .zero
    @State private var scrollViewFrameHeigt: CGFloat = .zero
    @State private var showScrollToBottomButton = false
    @State private var navigationBarHeight: CGFloat = .zero
    @State private var initialized: Bool = false
    @State private var coverImage: CoverImage? = nil
    
    @StateObject private var model: Model
    
    init(inMemory: Bool = false, chat: ChatGroup, channelId: String? = nil, threadId: String? = nil) {
        self.inMemory = inMemory
        self.chat = chat
        self.channelId = channelId
        self.threadId = threadId
        _model = StateObject(wrappedValue: Model(inMemory: inMemory, channelId: channelId, threadId: threadId, chat: chat))
    }
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        //            formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    func color(fraction: Double) -> Color {
        Color(red: fraction, green: 1 - fraction, blue: 0.5)
    }
    
    
    
    func isFromCurrentSender(message: HwChatMessage) -> Bool {
        return message.sender == authenticationService.phoneNumber!
    }
    
    func isPreviousMessageSameSender(for item: HwChatMessage, in section: MessageSection) -> Bool {
        guard let indexPath = section.messages.firstIndex(where: {$0.item.messageId! == item.messageId!}) else {
            return false
        }
        guard indexPath - 1 >= 0 else { return false }
        return section.messages[indexPath].item.sender == section.messages[indexPath - 1].item.sender
    }
    
    func isNextMessageSameSender(for item: HwChatMessage, in section: MessageSection) -> Bool {
        guard let indexPath = section.messages.firstIndex(where: {$0.item.messageId! == item.messageId!}) else {
            return false
        }
        guard indexPath + 1 < section.messages.count else { return false }
        return section.messages[indexPath].item.sender == section.messages[indexPath + 1].item.sender
    }
    
//    func isPreviousMessageDifferentDay(for item: HwChatMessage, in section: MessageSection) -> Bool {
//        guard let indexPath = section.messages.firstIndex(where: {$0.item.messageId! == item.messageId!}) else {
//            return false
//        }
//                
//        guard indexPath - 1 >= 0 else { return false }
//        return !Calendar.current.isDate(model.items[indexPath].timestamp!, equalTo: model.items[indexPath - 1].timestamp!, toGranularity: .day)
//        //        return model.items[indexPath].timestamp.com == model.items[indexPath - 1].sender
//    }
    
    //    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
    //        return (!isNextMessageSameSender(at: indexPath) && isFromCurrentSender(message: message)) ? 16 : 0
    //    }
    
    func isPreviousMessageSameSession(for item: HwChatMessage, in section: MessageSection) -> Bool{
        guard let indexPath = section.messages.firstIndex(where: {$0.item.messageId! == item.messageId!}) else {
            return false
        }
        guard indexPath - 1 >= 0 else { return false }
        return isPreviousMessageSameSender(for: item, in: section) && Calendar.current.isDate(section.messages[indexPath].item.timestamp!, equalTo: section.messages[indexPath - 1].item.timestamp!, toGranularity: .hour)
    }
    
    func scrollToBottom(with proxy: ScrollViewProxy){
        if let lastItem = model.items.last {
            proxy.scrollTo(lastItem.messageId!)
        }
    }
    
    func scrollTo(item: String){
        model.scrollTo = .item(item)
    }
    
    func loadMore() async {
        
    }
    
    var body: some View {
        GeometryReader { reader in
            VStack {
//                Button {
//                    model.loadMoreMessages()
//                } label: {
//                    Text("Load More Messages")
//                }
                ScrollViewReader { proxy in
                    ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom)) {
                        GeometryReader { _ in
                            // to fill the space when empty
                        }
                        ScrollView{
                            ForEach(model.sortedSectionItems) { section in
                                Section(footer: MessageSectionHeaderView(date: section.date).flippedUpsideDown()){
                                    ForEach(section.messages) { item in
                                        Group{
                                            if item.item.isSystemMessage {
                                                SystemMessageView(text: item.item.text!)
                                            }
                                            else if isFromCurrentSender(message: item.item){
                                                CurrentMessageSenderView(model: item as! OutgoingMessageItemModel , selectedReplyItem: .constant(nil), maxWidth: reader.size.width - 7 - 7, isPreviousMessageSameSender: isPreviousMessageSameSender(for: item.item, in: section), isNextMessageSameSender: isNextMessageSameSender(for: item.item, in: section), scrollToItem: scrollTo(item:), coverImage: $coverImage)
                                                
                                            } else {
                                                IncomingMessageView(model: item as! IncomingMessageItemModel, selectedReplyItem: .constant(nil), maxWidth: reader.size.width - 7 - 7, isPreviousMessageSameSender: isPreviousMessageSameSender(for: item.item, in: section), isNextMessageSameSender: isNextMessageSameSender(for: item.item, in: section), isThread: threadId != nil)
                                            }
                                        }
                                        .transition(.opacity)
                                        .id(item.item.messageId!)
                                        .flippedUpsideDown()
                                        .onAppear {
//                                            print("TestMessagesView: onAppear \(item.text!.string)")
                                        }
                                    }
                                }
                                
                            }
                            .background(GeometryReader { reader in
                                //                                    let offset = reader.frame(in: .named("scroll")).minY
                                //                                    let _ = print("MessagesView: ScrollView local frame", reader.frame(in: .local))
                                //                                    let _ = print("MessagesView: ScrollView scroll frame", reader.frame(in: .named("scroll")))
//                                let contentSize = CGSize(width: reader.frame(in: .named("scroll")).width, height: abs(reader.frame(in: .named("scroll")).maxY + reader.frame(in: .named("scroll")).minY))
                                let scrollViewData = ScrollViewData(contentSize: reader.frame(in: .local).size, contentOffset: reader.frame(in: .named("scroll")).minY)
                                Color.clear.preference(key: ScrollViewDataPreferenceKey.self, value: scrollViewData)
                                
                            })
                            HStack {
                                Text("Messages are end-to-end encrypted.")
                                    .multilineTextAlignment(.center)
                                    .font(.footnote)
                                    .foregroundColor( colorScheme == .dark ? .yellow : .primary)
                                    .padding(EdgeInsets(top: 8, leading: 15, bottom: 8, trailing: 15))
                                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                                    .flippedUpsideDown()
                            }
                            .frame(width: reader.size.width - 7 - 7)
                        }
//                        .background(.red)
                        .padding(EdgeInsets(top: 0, leading: 7, bottom: 0, trailing: 7))
                        .coordinateSpace(name: "scroll")
                        .flippedUpsideDown()
                        .introspectScrollView { scrollView in
                            scrollViewFrameHeigt = scrollView.frame.size.height
                            scrollView.keyboardDismissMode = .interactive
                        }
                        .onPreferenceChange(ScrollViewDataPreferenceKey.self) { value in
        //                    print("MessagesView: ScrollView data changed", value)
                            let page = Int((abs(value.contentOffset) + scrollViewFrameHeigt - reader.size.height/3) / reader.size.height)
                            print("TestMessagesView: page", page)
                            model.loadMoreMessages(for: page)
//                            if abs(value.contentOffset) + scrollViewFrameHeigt > value.contentSize.height - reader.size.height/3 {
//                                print("TestMessagesView: Loading More contentOffset: \(value.contentOffset), scrollViewFrameHeigt: \(scrollViewFrameHeigt), value.contentSize.width: \(value.contentSize.width),  value.contentSize.height: \(value.contentSize.height), reader.size.height: \(reader.size.height) ")
//
//                            }
                            
                            
                            if abs(value.contentOffset) > reader.size.height/3 {
                                showScrollToBottomButton = true
                            } else {
                                showScrollToBottomButton = false
                            }
        //                            DispatchQueue.main.async {
        //                                scrollViewData = value
        //                            }
                        }
                        
                        if showScrollToBottomButton {
                            Button {
                                if let messageId = model.sortedSectionItems.first?.messages.first?.item.messageId {
                                        withAnimation {
                                            proxy.scrollTo(messageId)
                                        }
                                    }
    //                            model.scrollTo = .bottonWithAnimation
                            } label: {
                                Image(systemName: "chevron.down.circle")
                                    .font(.system(size: 26))
                                    .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                                    .background(RoundedRectangle(cornerRadius: 5).fill(Color(UIColor.secondarySystemBackground)))
                            }
                        }
                    }
//                    .background(.yellow)
                }
                
                
                
//                HStack {
////                    Text("\( abs(scrollViewData.contentOffset) + scrollViewFrameHeigt)")
////                    Text("\(scrollViewFrameHeigt)")
////                    Text("\( scrollViewData.contentSize.height )")
////                    Text("\( reader.size.height )")
//                    Button {
//                        model.sendMessage()
//                    } label: {
//                        Text("Send")
//                    }
//                    
//                    Button {
//                        model.addMessage()
//                        
//                    } label: {
//                        Text("Add")
//                    }
//                    
//                    Button {
//                        model.addSystemMessage()
//                    } label: {
//                        Text("System")
//                    }
//                    
//                    if let _ = model.lastFetched {
//                        Button {
//                            model.loadMoreMessages()
//                        } label: {
//                            Text("Load More")
//                        }
//                    }
//                    
//                    if let _ = model.latestMessage {
//                        Button {
//                            model.markAsRead()
//                        } label: {
//                            Text("Read")
//                        }
//                    }
//                }
                
            }
            .padding([.bottom], 10)
//            .background(Color.red, ignoresSafeAreaEdges: [])
            .background(GradientBackground())
        }
        .onAppear{
//            UITableView.appearance().keyboardDismissMode = .onDrag
//            model.inMemory = inMemory
//            model.channelUid = channelId
//            model.threadId = threadId
//            model.performInitialization()
        }
        .introspectNavigationController { nvc in
//                        nvc.navigationBar.backgroundColor = .red
            navigationBarHeight = nvc.navigationBar.frame.size.height
            
        }
    }
}

struct TestMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        TestMessagesView(inMemory: true, chat: ChatGroup.preview, channelId: SampleData.shared.channelId)
//            .preferredColorScheme(.dark)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AuthenticationService.preview)
            .environmentObject(ContactRepository.preview)
    }
}

import CoreData
import Combine
import PromiseKit

extension TestMessagesView {
    class Model: NSObject, ObservableObject {
        @Published var items: [HwChatMessage] = []
        @Published var sortedSectionItems: [MessageSection] = []
        @Published var scrollViewOffset: CGFloat?
        @Published var scrollTo: ScrollTo = .none
        var scrollToBottomClosure: (() -> ())? = nil
        var sections: [Date: MessageSection] = [:]
        var latestMessage: HwChatMessage? = nil
        var lastFetched: (id: String, timestamp: Date)? = nil
        var uiScrollView: UIScrollView? = nil
        var intitialized: Bool = false
        var isLoadingPage = false
        private var latestPage = 0
        private var canLoadMorePages = true
        
        //init params
        //        var groupId: String
        var threadId: String?
        var channelUid: String?
        var inMemory: Bool
        var chat:  ChatGroup
        
        private var managedObjectContext: NSManagedObjectContext
        private var persistenceController: PersistenceController
        private var fetchedResultsController: NSFetchedResultsController<HwChatMessage>!
        private var authenticationService: AuthenticationService
        private var cancellables: Set<AnyCancellable> = []
        private let fetchLimit = 20
        
        init(inMemory: Bool = false, channelId: String? = nil, threadId: String? = nil, chat: ChatGroup){
            //            self.groupId = groupId
            self.inMemory = inMemory
            self.threadId = threadId
            self.channelUid = channelId
            self.chat = chat
            if inMemory {
                persistenceController = PersistenceController.preview
                managedObjectContext = PersistenceController.preview.container.viewContext
                authenticationService = AuthenticationService.preview
            } else {
                persistenceController = PersistenceController.shared
                managedObjectContext = PersistenceController.shared.container.viewContext
                authenticationService = AuthenticationService.shared
            }
            super.init()
            performInitialization()
        }
        
        func performInitialization(){
            guard !intitialized else {
                return
            }
            print("MessagesView: init")
            addSubscribers()
            loadMessages()
            intitialized = true
        }
        
        func isFromCurrentSender(message: HwChatMessage) -> Bool {
            return message.sender == authenticationService.phoneNumber!
        }
        
        func addSubscribers(){
            
        }
        
        func createMessageFetchRequest() {
            
        }
        
        func loadMessages(){
            if fetchedResultsController == nil {
                initializeFetchedResultsController()
            }
            loadFirstMessages()
        }
        
        func initializeFetchedResultsController() {
            let request: NSFetchRequest<HwChatMessage> = HwChatMessage.fetchRequest()
            if let channelUid = channelUid {
                request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatMessage.channelUid), channelUid)
            } else if let threadId = threadId {
                request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatMessage.threadUid), threadId)
            }
            request.sortDescriptors = [
                NSSortDescriptor(
                    keyPath: \HwChatMessage.timestamp,
                    ascending: false)]
            // Listen only for latest message
            request.fetchLimit = 1
            
            //                request.fetchBatchSize = 20
            
            fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController.delegate = self
            
            do {
                try fetchedResultsController.performFetch()
            } catch {
                print("Fetch failed")
            }
        }
        
        func loadFirstMessages(){
            let request: NSFetchRequest<HwChatMessage> = HwChatMessage.fetchRequest()
            if let channelUid = channelUid {
                request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatMessage.channelUid), channelUid)
            } else if let threadId = threadId {
                request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatMessage.threadUid), threadId)
            }
            
            request.sortDescriptors = [
                NSSortDescriptor(
                    keyPath: \HwChatMessage.timestamp,
                    ascending: false)]
            request.sortDescriptors = [
                NSSortDescriptor(
                    keyPath: \HwChatMessage.messageId,
                    ascending: false)]
            
            request.fetchLimit = fetchLimit + 1
            
            defer {
                isLoadingPage = false
            }
            
            do {
                isLoadingPage = true
                let hwItems = try managedObjectContext.fetch(request)
                
                let strongSelf = self
                if hwItems.count <= strongSelf.fetchLimit {
                    strongSelf.canLoadMorePages = false
                }
                
                if let lastItem = hwItems.last {
                    strongSelf.lastFetched = (lastItem.messageId!, lastItem.timestamp!)
                }
                
                let items = hwItems
                
                var sections = [Date: MessageSection]()
                for hwItem in items {
                    var item: MessageItemModel
                    if hwItem.sender! == authenticationService.account.phoneNumber! {
                        item = OutgoingMessageItemModel(inMemory: inMemory, chat: chat, item: hwItem)
                    } else {
                        item = IncomingMessageItemModel(inMemory: inMemory, chat: chat, item: hwItem)
                    }
                    
                    let timestamp = item.item.timestamp!
                    let dateKey = MessageDateFormatter.shared.removeTimeStamp(fromDate: timestamp)
                    if let section = sections[dateKey]{
                        var section = section
                        section.messages.append(item)
                        sections[dateKey] = section
                    } else {
                        let section = MessageSection(date: dateKey, messages: [item])
                        sections[dateKey] = section
                    }
                }
                strongSelf.sections = sections
                let sortedSections = Array(sections.values).sorted { $0.date > $1.date }
                
                
                strongSelf.items = hwItems
                strongSelf.sortedSectionItems = sortedSections
            } catch let error as NSError {
                print("Could not fetch \(error), \(error.userInfo)")
            }
        }
        
        func loadFirstMessagesAsync(){
            var asyncFetchRequest: NSAsynchronousFetchRequest<HwChatMessage>?
            
            let request: NSFetchRequest<HwChatMessage> = HwChatMessage.fetchRequest()
            if let channelUid = channelUid {
                request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatMessage.channelUid), channelUid)
            } else if let threadId = threadId {
                request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatMessage.threadUid), threadId)
            }
            
            request.sortDescriptors = [
                NSSortDescriptor(
                    keyPath: \HwChatMessage.timestamp,
                    ascending: false)]
            request.sortDescriptors = [
                NSSortDescriptor(
                    keyPath: \HwChatMessage.messageId,
                    ascending: false)]
            
            request.fetchLimit = fetchLimit + 1
            
            asyncFetchRequest = NSAsynchronousFetchRequest<HwChatMessage>(
                fetchRequest: request) {
                    [weak self] (result: NSAsynchronousFetchResult) in
                    
                    guard let strongSelf = self, let hwItems = result.finalResult else {
                        return
                    }
                    
                    if hwItems.count <= strongSelf.fetchLimit {
                        strongSelf.canLoadMorePages = false
                    }
                    
                    if let lastItem = hwItems.last {
                        strongSelf.lastFetched = (lastItem.messageId!, lastItem.timestamp!)
                    }
                    
                    let items = hwItems
                    
                    var sections = [Date: MessageSection]()
                    for hwItem in items {
                        var item: MessageItemModel
                        if hwItem.sender! == strongSelf.authenticationService.account.phoneNumber! {
                            item = OutgoingMessageItemModel(inMemory: strongSelf.inMemory, chat: strongSelf.chat, item: hwItem)
                        } else {
                            item = IncomingMessageItemModel(inMemory: strongSelf.inMemory, chat: strongSelf.chat, item: hwItem)
                        }
                        
                        let timestamp = item.item.timestamp!
                        let dateKey = MessageDateFormatter.shared.removeTimeStamp(fromDate: timestamp)
                        if let section = sections[dateKey]{
                            var section = section
                            section.messages.append(item)
                            sections[dateKey] = section
                        } else {
                            let section = MessageSection(date: dateKey, messages: [item])
                            sections[dateKey] = section
                        }
                    }
                    strongSelf.sections = sections
                    let sortedSections = Array(sections.values).sorted { $0.date > $1.date }
                    
                    
                    strongSelf.items = hwItems
                    strongSelf.sortedSectionItems = sortedSections
                    self?.isLoadingPage = false
                }
            
            do {
                guard let asyncFetchRequest = asyncFetchRequest else {
                    return
                }
                isLoadingPage = true
                try managedObjectContext.execute(asyncFetchRequest)
            } catch let error as NSError {
                print("Could not fetch \(error), \(error.userInfo)")
            }
        }
        
        func loadMoreMessages(for page: Int){
            guard latestPage < page else {
                return
            }
            
            guard let lastFetched = lastFetched else {
                return
            }
            
            guard !isLoadingPage && canLoadMorePages else {
                  return
                }

            isLoadingPage = true
            print("TestMessagesView: Loading More Messages")
            
            firstly {
                fetchMore(timestamp: lastFetched.timestamp, messageId: lastFetched.id, limit: fetchLimit + 1)
            }.done { hwItems in
                if hwItems.count <= self.fetchLimit {
                    self.canLoadMorePages = false
                }
                self.handleMessages(hwItems)
                self.latestPage += 1
            }.catch { error in
                print("MessagesView Error while performing fetchMore", error)
            }.finally {
                self.isLoadingPage = false
            }

        }
        
        func fetchMore(timestamp: Date, messageId: String, limit: Int) -> Promise<[HwChatMessage]>{
            Promise { seal in
                let fetchRequest: NSFetchRequest<HwChatMessage> = HwChatMessage.fetchRequest()
                if let channelUid = channelUid {
                    // A < X OR (A = X AND B < Y)
                    fetchRequest.predicate = NSPredicate(format: "channelUid = %@ AND (timestamp < %@ OR ( timestamp = %@ AND messageId < %@ ))", channelUid, timestamp as NSDate, timestamp as NSDate, messageId)
                } else if let threadId = threadId {
                    fetchRequest.predicate = NSPredicate(format: "threadUid = %@ AND (timestamp < %@ OR ( timestamp = %@ AND messageId < %@ ))", threadId, timestamp as NSDate, timestamp as NSDate, messageId)
                }
                
                
                fetchRequest.sortDescriptors = [
                    NSSortDescriptor(
                        keyPath: \HwChatMessage.timestamp,
                        ascending: false)]
                fetchRequest.sortDescriptors = [
                    NSSortDescriptor(
                        keyPath: \HwChatMessage.messageId,
                        ascending: false)]
                
                fetchRequest.fetchLimit = limit
                
                let asyncFetchRequest =
                NSAsynchronousFetchRequest<HwChatMessage>(
                    fetchRequest: fetchRequest) {
                       (result: NSAsynchronousFetchResult) in
                        
                        guard let hwItems = result.finalResult else {
                            seal.reject(NSError(domain: "MessagesView", code: 1, userInfo: nil))
                            return
                        }
                        
                        seal.fulfill(hwItems)
                    }
                
                do {
                    try managedObjectContext.execute(asyncFetchRequest)
                } catch let error as NSError {
                    seal.reject(error)
                    print("Could not fetch \(error), \(error.userInfo)")
                }
            }
        }
        
        func handleMessages(_ hwItems: [HwChatMessage]) {
            if let lastItem = hwItems.last {
                self.lastFetched = (lastItem.messageId!, lastItem.timestamp!)
            }
            
            let items = hwItems
            
            var sections = [Date: MessageSection]()
            
            for hwItem in items {
                var item: MessageItemModel
                if hwItem.sender! == authenticationService.account.phoneNumber! {
                    item = OutgoingMessageItemModel(inMemory: inMemory, chat: chat, item: hwItem)
                } else {
                    item = IncomingMessageItemModel(inMemory: inMemory, chat: chat, item: hwItem)
                }
                
                let timestamp = item.item.timestamp!
                let dateKey = MessageDateFormatter.shared.removeTimeStamp(fromDate: timestamp)
                if let section = sections[dateKey]{
                    var section = section
                    section.messages.append(item)
                    sections[dateKey] = section
                } else {
                    let section = MessageSection(date: dateKey, messages: [item])
                    sections[dateKey] = section
                }
            }
            
            var newItems = [HwChatMessage]()
            newItems.append(contentsOf: items)
            newItems.append(contentsOf: self.items)
            self.items = newItems
            
            var currSections = self.sections
            for (dateKey, newSection) in sections {
                if var section = currSections[dateKey] {
                    var sectionMessages = [MessageItemModel]()
                    sectionMessages.append(contentsOf: section.messages)
                    sectionMessages.append(contentsOf: newSection.messages)
                    section.messages = sectionMessages
                    currSections[dateKey] = section
                } else {
                    currSections[dateKey] = newSection
                }
            }
            self.sections = currSections
            let sortedSections = Array(currSections.values).sorted { $0.date > $1.date }
            
            self.sortedSectionItems = sortedSections
        }
        
        func sendMessage(){
            persistenceController.enqueue { context in
                let _ = SampleData.shared.getMessage(managedObjectContext: context, text: "New Message", isFromCurrentSender: true)
            }
            //            let item = SampleData.shared.getMessage(managedObjectContext: managedObjectContext, text: "New Message", isFromCurrentSender: true)
            //            persistenceController.save()
            
            //            updateSections(with: item)
            //            scrollToBottom()
            //            latestMessage = item
        }
        
        func updateMessageView(withNewMessage item: MessageItemModel){
            //            scrollToBottomClosure?()
            //            scrollToBottom()
            updateSections(withNewMessage: item)
//            scrollToBottom(isFromCurrentSender: isFromCurrentSender(message: item))
            //            scrollToBottomClosure?()
        }
        
        func updateSections(withNewMessage item: MessageItemModel){
            let dateKey = MessageDateFormatter.shared.removeTimeStamp(fromDate: item.item.timestamp!)
            if var section = sections[dateKey] {
                guard let messageId = item.item.messageId,
                      section.messages.first(where: {$0.item.messageId! == messageId}) == nil else {
                          return
                      }
                
                var messages = [item]
                messages.append(contentsOf: section.messages)
                section.messages = messages
                sections[dateKey] = section
                if let index = sortedSectionItems.firstIndex(where: {$0.date == dateKey}) {
                    withAnimation {
                        sortedSectionItems[index] = section
                    }
                } else {
                    withAnimation {
                        sortedSectionItems.insert(section, at: 0)
                    }
                }
            } else {
                let section = MessageSection(date: dateKey, messages: [item])
                sections[dateKey] = section
                if let index = sortedSectionItems.firstIndex(where: {$0.date == dateKey}) {
                    withAnimation {
                        sortedSectionItems[index] = section
                    }
                } else {
                    withAnimation {
                        sortedSectionItems.insert(section, at: 0)
                    }
                }
            }
            
//            let sortedSections = Array(sections.values).sorted { $0.date < $1.date }
//            sortedSectionItems = sortedSections
        }
        
//        func updateMessageView(with item: HwChatMessage){
//            //            scrollToBottomClosure?()
//            //            scrollToBottom()
//            updateSections(withNewMessage: item)
//            scrollToBottom(isFromCurrentSender: isFromCurrentSender(message: item))
//            //            scrollToBottomClosure?()
//        }
        
//        func updateSections(with item: HwChatMessage){
//            let dateKey = MessageDateFormatter.shared.removeTimeStamp(fromDate: item.timestamp!)
//            if var section = sections[dateKey] {
//                section.messages.append(item)
//                sections[dateKey] = section
//            } else {
//                let section = MessageSection(date: dateKey, messages: [item])
//                sections[dateKey] = section
//            }
//
//            let sortedSections = Array(sections.values).sorted { $0.date < $1.date }
//
//            items.append(item)
//            sortedSectionItems = sortedSections
//        }
        
        func addMessage(){
            persistenceController.enqueue { context in
                let _ = SampleData.shared.getMessage(managedObjectContext: context, text: "New Incoming Message")
            }
        }
        
        func addSystemMessage(){
            let userId = authenticationService.userId!
            let phoneNumber = authenticationService.phoneNumber!
            
            
            persistenceController.enqueue { context in
                let content = "\(phoneNumber) created a thread in reply to"
                let mention = Mention(range: NSMakeRange(0, phoneNumber.utf16.count), uid: userId, phoneNumber: phoneNumber)
                let systemMessage = HwMessage(content: content, mentions: [mention], links: [])
                let messageText = HwChatListItem.getAttributedString(from: systemMessage)
                let item = SampleData.shared.getMessage(managedObjectContext: context, text: "New Incoming Message", isSystemMessage: true)
                item.text = messageText
            }
        }
        
        func markAsRead(message: HwChatMessage) {
            guard !inMemory, let author = message.author, author != authenticationService.account.userId! else {
                return
            }
            
            let receipts = [ReadReceipt(author: message.author!, messageId: message.messageId!)]
            firstly {
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
                print("MessagesView: Error occured while marking read \(error.localizedDescription)")
            }
        }
        
        func markAsRead(){
            guard let lastSection = sortedSectionItems.last,
                  let latestMessage = lastSection.messages.randomElement() else {
                      return
                  }
            
            let taskContext = persistenceController.container.newBackgroundContext()
            
            taskContext.perform {
                let fetchRequest: NSFetchRequest<HwChatMessage> = HwChatMessage.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "messageId = %@", latestMessage.item.messageId!)
                
                if let results = try? taskContext.fetch(fetchRequest),
                   let item = results.first {
                    let reply = SampleData.shared.getMessageWithThreadReply(managedObjectContext: taskContext, message: "New reply")
                    item.statusRawValue = MessageStatus.read.rawValue
                    item.addToReplies(reply)
                    
                    do {
                        try taskContext.save()
                    } catch {
                        fatalError("Failure to save context: \(error)")
                    }
                }
            }
        }
        
        func scrollToBottom(isFromCurrentSender: Bool = true){
            DispatchQueue.main.async {
                if isFromCurrentSender {
                    self.scrollTo = .bottonWithAnimation
                } else {
                    //check current offset. if is in bottom of scrollview, scroll.
                    // else show button for scrolling to bottom
                    
                    self.scrollTo = .bottonWithAnimation
                }
            }
        }
    }
}

extension TestMessagesView.Model: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Will Change Content")
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        print("Did Change Section")
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let hwItem = anObject as? HwChatMessage {
                print("MessagesView: Inserted new message \(hwItem.text?.string)")
                
                if hwItem.sender! == authenticationService.account.phoneNumber! {
                    let item = OutgoingMessageItemModel(inMemory: inMemory, chat: chat, item: hwItem)
                    item.send()
                    updateSections(withNewMessage: item)
                } else {
                    let item = IncomingMessageItemModel(inMemory: inMemory, chat: chat, item: hwItem)
                    updateSections(withNewMessage: item)
                    markAsRead(message: hwItem)
                }
            
                items.insert(hwItem, at: 0)
                latestMessage = hwItem
            }
        case .delete:
            break
        case .move:
            break
        case .update:
            if let item = anObject as? HwChatMessage {
                print("Updated message \(item.messageId!)")
            }
        @unknown default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Did Change Content")
    }
}


