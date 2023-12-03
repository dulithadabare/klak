//
//  ChannelView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/1/21.
//

import SwiftUI

import Combine
import FirebaseAuth

struct KeyboardToolbar<ToolbarView: View>: ViewModifier {
    private let height: CGFloat
    private let toolbarView: ToolbarView
    
    init(height: CGFloat, @ViewBuilder toolbar: () -> ToolbarView) {
        self.height = height
        self.toolbarView = toolbar()
    }
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            GeometryReader { geometry in
                VStack {
                    content
                }
                .frame(width: geometry.size.width, height: geometry.size.height - height)
            }
            toolbarView
                .frame(height: self.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


extension View {
    func keyboardToolbar<ToolbarView>(height: CGFloat, view: @escaping () -> ToolbarView) -> some View where ToolbarView: View {
        modifier(KeyboardToolbar(height: height, toolbar: view))
    }
}

struct ChannelView: View {
    @State var showThreadView = false
    @State var selectedThread: ThreadItem?
    @ObservedObject var model: Model
    @State var text = ""
    @State var size: CGSize = CGSize(width: 0, height: 50)
    @StateObject var autocompleteDataModel = AutocompleteDataModel()
    @State var showAutocompleteView: Bool = false
    
//    var table: ChannelViewRepresentable {
//        ChannelViewRepresentable(chat: model.chat, channel: model.channel, contactRepository: model.contactRepository, selectedMessage: $selectedThread)
//        }
    
    var body: some View {
//        VStack{
//            self.table
//            InputBarUI(view: table.inputBar)
//        }
        VStack(spacing: 0){
            NavigationLink(destination: ThreadListModalView(model: ThreadListModalView.Model(chat: model.chat, channel: model.channel, contactRepository: model.contactRepository)), isActive: $showThreadView) { EmptyView() }
            
            NavigationLink(destination: LazyDestination{ ThreadDetailView(model: model.getThreadDetailViewModel()) }, isActive: $model.showThreadDetailView) { EmptyView() }
            
            ZStack{
                ChannelViewRepresentable(chat: model.chat, channel: model.channel, contactRepository: model.contactRepository, selectedReplyMessage: $model.selectedReplyMessage, selectedThreadItem: $model.selectedThreadItem, model: model.childViewModel)
                VStack(spacing: 0){
                    Spacer()
                    if showAutocompleteView {
                        AutocompleteListView(dataModel: autocompleteDataModel)
                    }
                    if model.showReplyView {
                        MessageReplyView(selectedReplyMessage: $model.selectedReplyMessage, message: model.selectedReplyItem!)
                    }
                }
                
            }
//            .border(Color.blue)
//                .onAppear{
//                    model.controller.becomeFirstResponder()
//                }
            
            ChannelInputBarView(showAutocompleteView: $showAutocompleteView, size: $size, chat: model.chat, channel: model.channel, contactRepository: model.contactRepository, dataModel: autocompleteDataModel, replyMessage: $model.selectedReplyMessage)
            .frame(height: size.height)
//                .border(Color.green)

        }
        .onChange(of: size, perform: { value in
            print("ChannelView: Coordinator size changed \(value)")
        })
        .navigationTitle(model.groupName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    model.selectedThreadItem = ThreadItem(title: "New Thread", channel: model.channel.channelUid, group: model.chat.group)
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                                to: nil, from: nil, for: nil)
//                        showThreadView = true
                    
                }) {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showThreadView.toggle()
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                                to: nil, from: nil, for: nil)
                }) {
                    Text("Threads")
                }
            }
        }
        .sheet(isPresented: $model.showAddThreadView) {
            ThreadModalView(selectedThreadItem: $model.selectedThreadItem, model: model.addThreadViewModel!)
        }
        .onAppear{
            model.clearUnread()
        }
        
    }
}

struct ChannelView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChannelView(model: ChannelView.Model( chat: ChatGroup(groupName: "Preview"), channel: ChatChannel(), contactRepository: ContactRepository.preview) )
        }
    }
}

extension ChannelView {
    class Model: ObservableObject {
        let authenticationService: AuthenticationService = .shared
        var chat: ChatGroup
        var channel: ChatChannel
        var contactRepository: ContactRepository
        var chatRepository = ChatRepository()
        @Published var showThreadDetailView = false
        @Published var selectedThreadItem: ThreadItem?
        @Published var selectedReplyMessage: ChatMessage?
        @Published var showReplyView: Bool = false
        @Published var showAddThreadView: Bool = false
        @Published var alertMessage = ""
        @Published var alert = false
        var selectedReplyItem: MessageReplyItem?
        var threadDetailViewModel: ThreadDetailView.Model?
        var childViewModel: ChannelViewRepresentable.Model
        var addThreadViewModel: ThreadModalView.Model?
        
        private var cancellables: Set<AnyCancellable> = []
        
        var groupName: String {
            return chat.isChat ? contactRepository.getFullName(for: chat.groupName) ?? chat.groupName : chat.groupName
        }
        
        deinit {
            print("ChannelView deinit")
        }
        
        init(chat: ChatGroup, channel: ChatChannel, contactRepository: ContactRepository){
            print("ChannelView init")
            self.chat = chat
            self.channel = channel
            self.contactRepository = contactRepository
            self.childViewModel = ChannelViewRepresentable.Model()
            addSubscribers()
        }
        
        func addSubscribers(){
            $selectedReplyMessage
//                .compactMap{$0}
                .sink { (message) in
                    if let message = message {
                        self.showReplyView = true
                        let senderFullName = self.contactRepository.getFullName(for: message.sender) ?? message.sender
                        let content = attributedString(with: message.message, contactRepository: self.contactRepository).string
                        self.selectedReplyItem = MessageReplyItem(senderName: senderFullName, content: content, chatMessage: message)
                    } else {
                        self.showReplyView = false
                    }
                    
                }
                .store(in: &cancellables)
            
            $selectedThreadItem
                .compactMap{$0}
                .sink { [weak self] (item) in
                    guard let self = self else {return}
                    if let threadUid = item.threadUid {
                        let thread = ChatThread(title: item.title, threadUid: threadUid, channel: item.channel, group: item.group, channelMessage: item.message, isTemp: false)
                        self.threadDetailViewModel = ThreadDetailView.Model(chat: self.chat, channel: self.channel, thread: thread, contactRepository: self.contactRepository)
                        self.showThreadDetailView = true
                    } else {
                        self.addThreadViewModel = ThreadModalView.Model(chat: self.chat, channel: self.channel, item: item, contactRepository: self.contactRepository)
                        self.showAddThreadView = true
                    }
                }
                .store(in: &cancellables)
        }
        
        func getThreadDetailViewModel() -> ThreadDetailView.Model {
            if let viewModel = threadDetailViewModel {
                return viewModel
            }
            let thread = ChatThread()
            return ThreadDetailView.Model(chat: chat, channel: channel, thread: thread, contactRepository: contactRepository)
        }
        
        func clearUnread(){
            ChatDataModel.shared.clearUnreadCount(for: chat.group)
        }
    }
}
