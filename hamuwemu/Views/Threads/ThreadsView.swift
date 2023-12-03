//
//  ThreadsView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-22.
//

import SwiftUI

struct ThreadsView: View {
    @EnvironmentObject var notificationDelegate: NotificationDelegate
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var contactRepository: ContactRepository
    @State private var selectedChat: String? = nil
    @State private var showAddChatView: Bool = false
    @State private var tempThread: ChatThreadModel? = nil
    @State private var showTempThread: Bool = false
    
    @FetchRequest(
        entity: HwThreadListItem.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \HwThreadListItem.lastMessageDate, ascending: false)
//            NSSortDescriptor(keyPath: \ProgrammingLanguage.creator, ascending: false)
        ]
    ) var items: FetchedResults<HwThreadListItem>
    
    var body: some View {
        NavigationView {
            VStack {
                if let tempThread = tempThread {
                    NavigationLink(destination: LazyDestination {
                        SwipeView(chat: tempThread.chat, thread: tempThread)
//                        ThreadMessagesView(chat: tempThread.chat, thread: tempThread )
                            .onDisappear {
                                //this is slower than onAppear on parent
                                // tempGroup = nil
                            }
                        
                    }, isActive: $showTempThread) { EmptyView() }
                }
                Group {
                    if items.count == 0 {
                        Text("Tap the \(Image(systemName: "square.and.pencil")) icon to start a new thread. You can start as many threads as you like with any contact.")
                            .multilineTextAlignment(.center)
                    } else {
                        List {
                            ForEach(items) { item in
                                NavigationLink(destination: LazyDestination {
                                    Group {
                                        // Only to prevent crashes during dev due to bug
                                        if let group = item.thread?.group,
                                           let chat = ChatGroup(from: group) {
//                                            ThreadMessagesView(chat: chat, thread: ChatThreadModel(from: item.thread!))
                                            SwipeView(chat: chat, thread: ChatThreadModel(from: item.thread!))
                                        } else {
                                            EmptyView()
                                        }
                                    }
                                }, tag: item.threadId!, selection: $notificationDelegate.selectedThread){
                                   ThreadListItemView(item: item)
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
            .navigationTitle(NSLocalizedString("Threads", comment: "title"))
            .navigationBarTitleDisplayMode(.large)
            .onAppear{
                tempThread = nil
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    TitleView(title: "Threads")
                            }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddChatView.toggle()
                    }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showAddChatView, content: {
            AddThreadView(tempThread: $tempThread, showTempThread: $showTempThread)
        })
    }
}

struct ThreadsView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AuthenticationService.preview)
            .environmentObject(ContactRepository.preview)
            .environmentObject(NotificationDelegate.shared)
    }
}

struct ThreadListItemView: View {
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var contactRepository: ContactRepository
    @ObservedObject var item: HwThreadListItem
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                //                            Text(item.thread?.titleText?.string ?? "No Title")
                HStack{
                    Text(item.thread?.titleText?.string ?? "No Title")
                    if let groupName = item.thread?.group?.groupName! {
                        Text(contactRepository.getFullName(for: groupName))
                            .font(.subheadline)
                    }
                }
                HStack {
                    if item.lastMessageAuthorUid == authenticationService.account.userId,
                       let receipt = MessageStatus(rawValue: item.lastMessageStatusRawValue) {
                        MessageStatusView(receipt: .constant(receipt))
                        .font(.footnote)
                    }
                    Text(item.lastMessageText?.string ?? "No Messages")
                        .lineLimit(2)
                        .font(.footnote)
                        .foregroundColor(Color.gray)
                }
            }
            if item.unreadCount > 0 {
                Spacer()
                UnreadCountView(count: UInt(item.unreadCount))
            }
            
        }
    }
}
