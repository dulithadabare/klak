//
//  MessagesView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-01-05.
//

import SwiftUI
import MessageKit

struct ScrollViewDataPreferenceKey: PreferenceKey {
    typealias Value = ScrollViewData
    static var defaultValue: ScrollViewData = ScrollViewData(contentSize: .zero, contentOffset: .zero)
    static func reduce(value: inout ScrollViewData, nextValue: () -> ScrollViewData) {
//        value = nextValue()
    }
}

private struct ContentSizePreferenceKey: PreferenceKey {
  static var defaultValue: CGSize = .zero
  static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

struct ScrollViewData: Equatable {
    let contentSize: CGSize
    let contentOffset: CGFloat
}

struct ScrollViewFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct ScrollViewContentSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

enum ScrollTo: Equatable {
    case top, bottom, bottonWithAnimation, none
    case item(String)
}

struct MessageSection: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    var messages: [MessageItemModel]
    
}

struct ScrollToBottomButtonView: View {
    var parentViewSize: CGSize
    @Binding var currOffset: CGFloat
    @Binding var contentSize: CGSize
    @Binding var scrollViewFrameHeigt: CGFloat
    var action: ()->()
    
    var body: some View {
        if abs(currOffset) + scrollViewFrameHeigt < contentSize.height - parentViewSize.height/3 {
            Button {
                action()
            } label: {
                Image(systemName: "chevron.down.circle")
                    .font(.system(size: 26))
                    .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color(UIColor.secondarySystemBackground)))
            }
        } else {
            EmptyView()
        }
    }
}

struct MessageSectionHeaderView: View {
    var date: Date
    
    var body: some View {
        Text(MessageDateFormatter.shared.string(from: date))
            .font(.system(size: 10, weight: .bold, design: .default))
            .foregroundColor(Color(UIColor.white))
            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
            .background(Capsule().fill(Color(UIColor.black).opacity(0.75)))
    }
}

struct MessagesView: View {
    //    @FetchRequest(fetchRequest: HwChatMessage.request)
    //    private var fetchedItems: FetchedResults<HwChatMessage>
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
    
    @StateObject private var model: Model
    
    init(inMemory: Bool = false, chat: ChatGroup, channelId: String? = nil, threadId: String? = nil) {
        self.inMemory = inMemory
        self.chat = chat
        self.channelId = channelId
        self.threadId = threadId
        _model = StateObject(wrappedValue: Model(inMemory: inMemory, channelId: channelId, threadId: threadId))
    }
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        //            formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        Text("Use TestMessagesView")
//        GeometryReader { reader in
//            VStack {
//                ScrollViewReader { proxy in
//                    ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom)) {
//                        ScrollView {
//    //                                Button("Scroll to Bottom") {
//    //                                    withAnimation {
//    //                                        proxy.scrollTo("bottom")
//    //                                    }
//    //                                }
//    //                                .id("2")
//
//                            if model.canLoadMorePages {
//                                if model.isLoadingPage {
//                                    ProgressView()
//                                } else {
//                                    Button {
//                                        model.loadMoreMessages()
//                                    } label: {
//                                        Text("Load More Messages")
//                                    }
//                                }
//                            }
//                            ZStack{
//                                GeometryReader { proxy in
////                                    let contentSize = proxy.frame(in: .local).size
////                                    Color.clear.preference(key: ContentSizePreferenceKey.self, value: contentSize)
//                                }
//                                VStack() {
//                                    ForEach(model.sortedSectionItems) { section in
//                                        Section(header: MessageSectionHeaderView(date: section.date)) {
//                                            ForEach(section.messages.indices, id: \.self) { i in
//                                                if let item = section.messages[i],
//                                                   item.isSystemMessage {
//                                                    SystemMessageView(text: item.text!)
//                                                }
//                                                else if let item = section.messages[i],
//                                                        isFromCurrentSender(message: item) {
//                                                    CurrentMessageSenderView(chat: chat, item: section.messages[i], selectedReplyItem: .constant(nil), maxWidth: reader.size.width, isPreviousMessageDifferentDay: isPreviousMessageDifferentDay(at: i), isPreviousMessageSameSender: isPreviousMessageSameSender(at: i, in: section), isNextMessageSameSender: isNextMessageSameSender(at: i, in: section), scrollToItem: scrollTo(item:), isThread: model.threadId != nil)
//                                                        .id(section.messages[i].messageId!)
//                                                } else {
//                                                    IncomingMessageView(item: section.messages[i],
//                                                                        selectedReplyItem: .constant(nil),maxWidth: reader.size.width, isPreviousMessageDifferentDay: isPreviousMessageDifferentDay(at: i), isPreviousMessageSameSender:isPreviousMessageSameSender(at: i, in: section), isNextMessageSameSender: isNextMessageSameSender(at: i, in: section), isThread: model.threadId != nil
//                                                    )
//                                                        .id(section.messages[i].messageId!)
//                                                }
//
//
//                                            }
//                                        }
//
//                                        //                                Text(model.items[i].messageId!)
//                                        //                                        .id(i)
//                                        //                                    .padding()
//                                    }
//                                }
//                                .background(GeometryReader { reader in
//                                    //                                    let offset = reader.frame(in: .named("scroll")).minY
//                                    //                                    let _ = print("MessagesView: ScrollView local frame", reader.frame(in: .local))
//                                    //                                    let _ = print("MessagesView: ScrollView scroll frame", reader.frame(in: .named("scroll")))
//                                    let scrollViewData = ScrollViewData(contentSize: reader.frame(in: .local).size, contentOffset: reader.frame(in: .named("scroll")).minY)
//                                    Color.clear.preference(key: ScrollViewDataPreferenceKey.self, value: scrollViewData)
//
//                                })
//
//                            }
//    //                           Text("Bottom").id("bottom")
//                        }
//                        .coordinateSpace(name: "scroll")
//                        .onPreferenceChange(ScrollViewDataPreferenceKey.self) { value in
//                            print("MessagesView: ScrollView data changed", value)
////                            DispatchQueue.main.async {
////                                scrollViewData = value
////                            }
//                        }
////                        .onPreferenceChange(ScrollViewFramePreferenceKey.self) { value in
////                            DispatchQueue.main.async {
////                                currOffset = value.minY
////                            }
////                        }
////                        .onPreferenceChange(ContentSizePreferenceKey.self) { value in
////    //                            print("MessagesView: ScrollView content size", value)
////                            DispatchQueue.main.async {
////                                contentSize = value
////                            }
////
////                        }
//                        .padding(EdgeInsets(top: 0, leading: 7, bottom: 0, trailing: 7))
//                        .onChange(of: model.scrollTo, perform: { scrollTo in
//                            print("MessagesView: Scrolling")
//                            switch scrollTo {
//                            case .bottom:
//                                if let lastItem = model.sortedSectionItems.last?.messages.last {
//                                    proxy.scrollTo(lastItem.messageId!)
//                                }
//    //                                proxy.scrollTo("bottom")
//
//                            case .bottonWithAnimation:
//                                if let lastItem = model.sortedSectionItems.last?.messages.last {
//                                    withAnimation {
//                                        proxy.scrollTo(lastItem.messageId!)
//                                    }
//                                }
//
//                            case .top:
//                                print("Scrolling to Top")
//
//                            case .item(let messageId):
//                                withAnimation {
//                                    proxy.scrollTo(messageId)
//                                }
//                            case .none:
//                                print("Stop")
//                            }
//                            // This will not cause the onChange to loop
//                            model.scrollTo = .none
//                        })
//                        .introspectScrollView { scrollView in
//                            scrollViewFrameHeigt = scrollView.frame.size.height
//                        }
//
//                        if abs(scrollViewData.contentOffset) + scrollViewFrameHeigt < scrollViewData.contentSize.height - reader.size.height/3 {
//                            Button {
//                                    if let lastItem = model.sortedSectionItems.last?.messages.last {
//                                        withAnimation {
//                                            proxy.scrollTo(lastItem.messageId!)
//                                        }
//                                    }
//    //                            model.scrollTo = .bottonWithAnimation
//                            } label: {
//                                Image(systemName: "chevron.down.circle")
//                                    .font(.system(size: 26))
//                                    .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
//                                    .background(RoundedRectangle(cornerRadius: 5).fill(Color(UIColor.secondarySystemBackground)))
//                            }
//                        }
//
//                    }
//                }
//
//                HStack {
////                    Text("\( abs(currOffset) + scrollViewFrameHeigt)")
////                    Text("\(scrollViewFrameHeigt)")
////                    Text("\( contentSize.height )")
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
//
//            }
//            .background(GradientBackground())
//        }
//        .onAppear{
////            model.inMemory = inMemory
////            model.channelUid = channelId
////            model.threadId = threadId
////            model.performInitialization()
//        }
//        .introspectNavigationController { nvc in
////                        nvc.navigationBar.backgroundColor = .red
//            navigationBarHeight = nvc.navigationBar.frame.size.height
//
//                    }
    }
}

struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView(inMemory: true, chat: ChatGroup.preview, channelId: SampleData.shared.channelId)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AuthenticationService.preview)
            .environmentObject(ContactRepository.preview)
    }
}

//extension MessagesView {
//    func color(fraction: Double) -> Color {
//        Color(red: fraction, green: 1 - fraction, blue: 0.5)
//    }
//
//    func isFromCurrentSender(message: HwChatMessage) -> Bool {
//        return message.sender == authenticationService.phoneNumber!
//    }
//
//    func isPreviousMessageSameSender(at indexPath: Int, in section: MessageSection) -> Bool {
//        guard indexPath - 1 >= 0 else { return false }
//        return section.messages[indexPath].sender == section.messages[indexPath - 1].sender
//    }
//
//    func isNextMessageSameSender(at indexPath: Int, in section: MessageSection) -> Bool {
//        guard indexPath + 1 < section.messages.count else { return false }
//        return section.messages[indexPath].sender == section.messages[indexPath + 1].sender
//    }
//
//    func isPreviousMessageDifferentDay(at indexPath: Int) -> Bool {
//        guard indexPath - 1 >= 0 else { return false }
//        return !Calendar.current.isDate(model.items[indexPath].timestamp!, equalTo: model.items[indexPath - 1].timestamp!, toGranularity: .day)
//        //        return model.items[indexPath].timestamp.com == model.items[indexPath - 1].sender
//    }
//
//    //    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
//    //        return (!isNextMessageSameSender(at: indexPath) && isFromCurrentSender(message: message)) ? 16 : 0
//    //    }
//
//    func isPreviousMessageSameSession(at indexPath: Int, in section: MessageSection) -> Bool{
//        guard indexPath - 1 >= 0 else { return false }
//        return isPreviousMessageSameSender(at: indexPath, in: section) && Calendar.current.isDate(section.messages[indexPath].timestamp!, equalTo: section.messages[indexPath - 1].timestamp!, toGranularity: .hour)
//    }
//
//    func scrollToBottom(with proxy: ScrollViewProxy){
//        if let lastItem = model.items.last {
//            proxy.scrollTo(lastItem.messageId!)
//        }
//    }
//
//    func scrollTo(item: String){
//        model.scrollTo = .item(item)
//    }
//}

import CoreData
import Combine
import PromiseKit

extension MessagesView {
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
        @Published var isLoadingPage = false
        private var currentPage = 1
        @Published var canLoadMorePages = true
        
        //init params
        //        var groupId: String
        var threadId: String?
        var channelUid: String?
        var inMemory: Bool
        
        private var managedObjectContext: NSManagedObjectContext
        private var persistenceController: PersistenceController
        private var fetchedResultsController: NSFetchedResultsController<HwChatMessage>!
        private var authenticationService: AuthenticationService
        private var cancellables: Set<AnyCancellable> = []
        
        private let fetchLimit = 20
        
        init(inMemory: Bool = false, channelId: String? = nil, threadId: String? = nil){
            //            self.groupId = groupId
            self.inMemory = inMemory
            self.threadId = threadId
            self.channelUid = channelId
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
//            performInitialization()
        }
        
//        func performInitialization(){
//            guard !intitialized else {
//                return
//            }
//            print("MessagesView: init")
//            addSubscribers()
//            loadMessages()
//            intitialized = true
//        }
//
//        func isFromCurrentSender(message: HwChatMessage) -> Bool {
//            return message.sender == authenticationService.phoneNumber!
//        }
//
//        func addSubscribers(){
//
//        }
//
//        func loadFirstMessagesSync(){
//            //            let sectionKeyDateFormatter = DateFormatter()
//            //            sectionKeyDateFormatter.dateStyle = .medium
//            //            sectionKeyDateFormatter.timeStyle = .none
//
//            var asyncFetchRequest: NSAsynchronousFetchRequest<HwChatMessage>?
//
//            let fetchRequest: NSFetchRequest<HwChatMessage> = HwChatMessage.fetchRequest()
//
//            if let channelUid = channelUid {
//                fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatMessage.channelUid), channelUid)
//            } else if let threadId = threadId {
//                fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatMessage.threadUid), threadId)
//            }
//
//            fetchRequest.sortDescriptors = [
//                NSSortDescriptor(
//                    keyPath: \HwChatMessage.timestamp,
//                    ascending: false)]
//            fetchRequest.sortDescriptors = [
//                NSSortDescriptor(
//                    keyPath: \HwChatMessage.messageId,
//                    ascending: false)]
//
//
//
//            if fetchedResultsController == nil {
//                let request: NSFetchRequest<HwChatMessage> = HwChatMessage.fetchRequest()
//                if let channelUid = channelUid {
//                    request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatMessage.channelUid), channelUid)
//                } else if let threadId = threadId {
//                    request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatMessage.threadUid), threadId)
//                }
//                request.sortDescriptors = [
//                    NSSortDescriptor(
//                        keyPath: \HwChatMessage.timestamp,
//                        ascending: false)]
//
//                //                request.fetchBatchSize = 20
//
//                fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
//                fetchedResultsController.delegate = self
//            }
//
//
//            do {
//                try fetchedResultsController.performFetch()
//                guard let hwItems = fetchedResultsController.fetchedObjects else {
//                    return
//                }
//
//                if let lastItem = hwItems.last {
//                    self.lastFetched = (lastItem.messageId!, lastItem.timestamp!)
//                }
//
//                let items = hwItems.reversed()
//
//                var sections = [Date: MessageSection]()
//                for item in items {
//                    let timestamp = item.timestamp!
//                    let dateKey = MessageDateFormatter.shared.removeTimeStamp(fromDate: timestamp)
//                    if let section = sections[dateKey]{
//                        var section = section
//                        section.messages.append(item)
//                        sections[dateKey] = section
//                    } else {
//                        let section = MessageSection(date: dateKey, messages: [item])
//                        sections[dateKey] = section
//                    }
//                }
//                self.sections = sections
//                let sortedSections = Array(sections.values).sorted { $0.date < $1.date }
//
//
//                self.items = hwItems.reversed()
//                self.sortedSectionItems = sortedSections
//                self.scrollToBottom()
//            } catch {
//                print("Fetch failed")
//            }
//
////            fetchRequest.fetchLimit = 10
//        }
//
//        func loadMessages(){
//            if fetchedResultsController == nil {
//                initializeFetchedResultsController()
//            }
//            loadFirstMessagesAsync()
//        }
//
//        func initializeFetchedResultsController() {
//            let request: NSFetchRequest<HwChatMessage> = HwChatMessage.fetchRequest()
//            if let channelUid = channelUid {
//                request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatMessage.channelUid), channelUid)
//            } else if let threadId = threadId {
//                request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatMessage.threadUid), threadId)
//            }
//            request.sortDescriptors = [
//                NSSortDescriptor(
//                    keyPath: \HwChatMessage.timestamp,
//                    ascending: false)]
//            // Listen only for latest message
//            request.fetchLimit = 1
//
//            //                request.fetchBatchSize = 20
//
//            fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
//            fetchedResultsController.delegate = self
//
//            do {
//                try fetchedResultsController.performFetch()
//            } catch {
//                print("Fetch failed")
//            }
//        }
//
//        func loadFirstMessagesAsync(){
//            var asyncFetchRequest: NSAsynchronousFetchRequest<HwChatMessage>?
//
//            let request: NSFetchRequest<HwChatMessage> = HwChatMessage.fetchRequest()
//            if let channelUid = channelUid {
//                request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatMessage.channelUid), channelUid)
//            } else if let threadId = threadId {
//                request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatMessage.threadUid), threadId)
//            }
//
//            request.sortDescriptors = [
//                NSSortDescriptor(
//                    keyPath: \HwChatMessage.timestamp,
//                    ascending: false)]
//            request.sortDescriptors = [
//                NSSortDescriptor(
//                    keyPath: \HwChatMessage.messageId,
//                    ascending: false)]
//
//            request.fetchLimit = fetchLimit + 1
//
//            asyncFetchRequest = NSAsynchronousFetchRequest<HwChatMessage>(
//                fetchRequest: request) {
//                    [weak self] (result: NSAsynchronousFetchResult) in
//
//                    guard let strongSelf = self, let hwItems = result.finalResult else {
//                        return
//                    }
//
//                    if hwItems.count <= strongSelf.fetchLimit {
//                        strongSelf.canLoadMorePages = false
//                    }
//
//                    if let lastItem = hwItems.last {
//                        strongSelf.lastFetched = (lastItem.messageId!, lastItem.timestamp!)
//                    }
//
//                    let items = hwItems.reversed()
//
//                    var sections = [Date: MessageSection]()
//                    for item in items {
//                        let timestamp = item.timestamp!
//                        let dateKey = MessageDateFormatter.shared.removeTimeStamp(fromDate: timestamp)
//                        if let section = sections[dateKey]{
//                            var section = section
//                            section.messages.append(item)
//                            sections[dateKey] = section
//                        } else {
//                            let section = MessageSection(date: dateKey, messages: [item])
//                            sections[dateKey] = section
//                        }
//                    }
//                    strongSelf.sections = sections
//                    let sortedSections = Array(sections.values).sorted { $0.date < $1.date }
//
//
//                    strongSelf.items = hwItems.reversed()
//                    strongSelf.sortedSectionItems = sortedSections
//                    strongSelf.scrollToBottom()
//                }
//
//            do {
//                guard let asyncFetchRequest = asyncFetchRequest else {
//                    return
//                }
//                try managedObjectContext.execute(asyncFetchRequest)
//            } catch let error as NSError {
//                print("Could not fetch \(error), \(error.userInfo)")
//            }
//        }
//
//        func loadMoreMessages(){
//            guard let lastFetched = lastFetched else {
//                return
//            }
//
//            guard !isLoadingPage && canLoadMorePages else {
//                  return
//                }
//
//            isLoadingPage = true
//
//            firstly {
//                fetchMore(timestamp: lastFetched.timestamp, messageId: lastFetched.id)
//            }.done { hwItems in
//                if hwItems.count <= self.fetchLimit {
//                    self.canLoadMorePages = false
//                }
//                self.handleMessages(hwItems)
//            }.catch { error in
//                print("MessageView Error while performing fetchMore", error)
//            }.finally {
//                self.isLoadingPage = false
//            }
//
//        }
//
//        func fetchMore(timestamp: Date, messageId: String) -> Promise<[HwChatMessage]>{
//            Promise { seal in
//                let fetchRequest: NSFetchRequest<HwChatMessage> = HwChatMessage.fetchRequest()
//                // A < X OR (A = X AND B < Y)
//                fetchRequest.predicate = NSPredicate(format: "timestamp < %@ OR ( timestamp = %@ AND messageId < %@ )", timestamp as NSDate, timestamp as NSDate, messageId)
//
//                fetchRequest.sortDescriptors = [
//                    NSSortDescriptor(
//                        keyPath: \HwChatMessage.timestamp,
//                        ascending: false)]
//                fetchRequest.sortDescriptors = [
//                    NSSortDescriptor(
//                        keyPath: \HwChatMessage.messageId,
//                        ascending: false)]
//
//                fetchRequest.fetchLimit = fetchLimit + 1
//
//                let asyncFetchRequest =
//                NSAsynchronousFetchRequest<HwChatMessage>(
//                    fetchRequest: fetchRequest) {
//                       (result: NSAsynchronousFetchResult) in
//
//                        guard let hwItems = result.finalResult else {
//                            seal.reject(NSError(domain: "MessagesView", code: 1, userInfo: nil))
//                            return
//                        }
//
//                        seal.fulfill(hwItems)
//                    }
//
//                do {
//                    try managedObjectContext.execute(asyncFetchRequest)
//                } catch let error as NSError {
//                    seal.reject(error)
//                    print("Could not fetch \(error), \(error.userInfo)")
//                }
//            }
//        }
//
//        func handleMessages(_ hwItems: [HwChatMessage]) {
//            if let lastItem = hwItems.last {
//                self.lastFetched = (lastItem.messageId!, lastItem.timestamp!)
//            }
//
//            let items = hwItems.reversed()
//
//            var sections = [Date: MessageSection]()
//            for item in items {
//                let timestamp = item.timestamp!
//                let dateKey = MessageDateFormatter.shared.removeTimeStamp(fromDate: timestamp)
//                if let section = sections[dateKey]{
//                    var section = section
//                    section.messages.append(item)
//                    sections[dateKey] = section
//                } else {
//                    let section = MessageSection(date: dateKey, messages: [item])
//                    sections[dateKey] = section
//                }
//            }
//
//            var newItems = [HwChatMessage]()
//            newItems.append(contentsOf: items)
//            newItems.append(contentsOf: self.items)
//            self.items = newItems
//
//            var currSections = self.sections
//            for (dateKey, newSection) in sections {
//                if var section = currSections[dateKey] {
//                    var sectionMessages = [HwChatMessage]()
//                    sectionMessages.append(contentsOf: newSection.messages)
//                    sectionMessages.append(contentsOf: section.messages)
//                    section.messages = sectionMessages
//                    currSections[dateKey] = section
//                } else {
//                    currSections[dateKey] = newSection
//                }
//            }
//            self.sections = currSections
//            let sortedSections = Array(currSections.values).sorted { $0.date < $1.date }
//
//            self.sortedSectionItems = sortedSections
//        }
//
//        func sendMessage(){
//            persistenceController.enqueue { context in
//                let _ = SampleData.shared.getMessage(managedObjectContext: context, text: "New Message", isFromCurrentSender: true)
//            }
//            //            let item = SampleData.shared.getMessage(managedObjectContext: managedObjectContext, text: "New Message", isFromCurrentSender: true)
//            //            persistenceController.save()
//
//            //            updateSections(with: item)
//            //            scrollToBottom()
//            //            latestMessage = item
//        }
//
//        func updateMessageView(withNewMessage item: HwChatMessage){
//            //            scrollToBottomClosure?()
//            //            scrollToBottom()
//            updateSections(withNewMessage: item)
//            scrollToBottom(isFromCurrentSender: isFromCurrentSender(message: item))
//            //            scrollToBottomClosure?()
//        }
//
//        func updateSections(withNewMessage item: HwChatMessage){
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
//
//        func updateMessageView(with item: HwChatMessage){
//            //            scrollToBottomClosure?()
//            //            scrollToBottom()
//            updateSections(withNewMessage: item)
//            scrollToBottom(isFromCurrentSender: isFromCurrentSender(message: item))
//            //            scrollToBottomClosure?()
//        }
//
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
//
//        func addMessage(){
//            persistenceController.enqueue { context in
//                let _ = SampleData.shared.getMessage(managedObjectContext: context, text: "New Incoming Message")
//            }
//        }
//
//        func addSystemMessage(){
//            let userId = authenticationService.userId!
//            let phoneNumber = authenticationService.phoneNumber!
//
//
//            persistenceController.enqueue { context in
//                let content = "\(phoneNumber) created a thread in reply to"
//                let mention = Mention(range: NSMakeRange(0, phoneNumber.utf16.count), uid: userId, phoneNumber: phoneNumber)
//                let systemMessage = HwMessage(content: content, mentions: [mention], links: [])
//                let messageText = HwChatListItem.getAttributedString(from: systemMessage)
//                let item = SampleData.shared.getMessage(managedObjectContext: context, text: "New Incoming Message", isSystemMessage: true)
//                item.text = messageText
//            }
//        }
//
//        func markAsRead(message: HwChatMessage) {
//            guard !inMemory, let author = message.author, author != authenticationService.account.userId! else {
//                return
//            }
//
//            let receipts = [ReadReceipt(author: message.author!, messageId: message.messageId!)]
//            firstly {
//                AuthenticationService.shared.account.addReadReceipts(receipts: receipts)
//            }.done { receipts in
//                let messageIdArray = receipts.map({ $0.messageId })
//                PersistenceController.shared.enqueue { context in
//                    let fetchRequest: NSFetchRequest<HwChatMessage> = HwChatMessage.fetchRequest()
//                    fetchRequest.predicate = NSPredicate(format: "%K IN %@",#keyPath(HwChatMessage.messageId), messageIdArray)
//
//                    guard let results = try? context.fetch(fetchRequest) else {
//                        return
//                    }
//
//                    for item in results {
//                        item.isReadByMe = true
//                    }
//                }
//            }.catch { error in
//                print("Error occured while marking read")
//            }
//        }
//
//        func markAsRead(){
//            guard let lastSection = sortedSectionItems.last,
//                  let latestMessage = lastSection.messages.randomElement() else {
//                      return
//                  }
//
//            let taskContext = persistenceController.container.newBackgroundContext()
//
//            taskContext.perform {
//                let fetchRequest: NSFetchRequest<HwChatMessage> = HwChatMessage.fetchRequest()
//                fetchRequest.predicate = NSPredicate(format: "messageId = %@", latestMessage.messageId!)
//
//                if let results = try? taskContext.fetch(fetchRequest),
//                   let item = results.first {
//                    let reply = SampleData.shared.getMessageWithThreadReply(managedObjectContext: taskContext, message: "New reply")
//                    item.statusRawValue = MessageStatus.read.rawValue
//                    item.addToReplies(reply)
//
//                    do {
//                        try taskContext.save()
//                    } catch {
//                        fatalError("Failure to save context: \(error)")
//                    }
//                }
//            }
//        }
//
//        func scrollToBottom(isFromCurrentSender: Bool = true){
//            DispatchQueue.main.async {
//                if isFromCurrentSender {
//                    self.scrollTo = .bottom
//                } else {
//                    //check current offset. if is in bottom of scrollview, scroll.
//                    // else show button for scrolling to bottom
//
//                    self.scrollTo = .bottonWithAnimation
//                }
//            }
//        }
    }
}

extension MessagesView.Model: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Will Change Content")
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        print("Did Change Section")
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let item = anObject as? HwChatMessage {
                print("Inserted new message \(item.text!.string)")
//                updateMessageView(withNewMessage: item)
//                markAsRead(message: item)
                latestMessage = item
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

