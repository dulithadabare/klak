//
//  AddGroupView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/2/21.
//

import SwiftUI
import Combine
import Contacts

struct AddGroupView: View {
    var inMemory: Bool = false
    @Binding var selectedChat: String?
    @Binding var tempGroup: ChatGroup?
    @Binding var  showTempGroup: Bool
    
    @EnvironmentObject private var contactRepository: ContactRepository
    @EnvironmentObject private var authenticationService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = Model()
    @State private var text: String = ""
    @State private var initialized: Bool = false
    
    var body: some View {
        NavigationView {
            Group {
                if model.contactPermission != .authorized {
                    ContactPermissionGuideView()
                } else if model.messages.isEmpty {
                    if contactRepository.isRefreshing {
                        ProgressView()
                    } else {
                        Text("Ensure you have added the correct phone number in full international format.")
                            .multilineTextAlignment(.center)
                    }
                    
                } else {
                    VStack {
                        List {
                            ForEach(model.messages) { contact in
                                ZStack {
                                    Button(action: {
                                        if let groupId = contact.groupId {
                                            selectedChat = groupId
                                        } else {
                                            let currUser = AppUser(uid: authenticationService.account.userId!, phoneNumber: authenticationService.account.phoneNumber!)
                                            let members = [currUser, AppUser(uid: contact.id, phoneNumber: contact.phoneNumber)]
                                            let chat = ChatGroup(groupName: contact.phoneNumber, isChat: true, members: members)
                            //                let item = ChatListItem(from: chat)
                            //                chatViewModel.items.append(item)
                            //                chatDataModel.add(chat)
                                            
                            //                chatDataModel.addTempChatListItem(from: chat)
                                            
                                            //working
                            //                addNewGroup(with: chat)
                            //                selectedChat.wrappedValue = chat.group
                                            
                                            //also working
                                            tempGroup = chat
                                            showTempGroup = true
                                            
                                            
                            //                chatRepository?.add(with: contact)
                                        }
                                        
                                        dismiss()
                                    }, label: {
                                        AddGroupListItemView(contact: contact)
                                    })
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                            dismiss()
                    }) {
                        Text("Cancel")
                    }
                }
            }
        }
        .onAppear {
            guard !initialized else {
                return
            }
            
            model.performOnceOnAppear(inMemory: inMemory)
            initialized = true
        }
    }
}

//struct AddGroupView_Previews: PreviewProvider {
//    static var previews: some View {
//        AddGroupView(model: AddGroupView.Model(inMemory: true, chatDataModel: ChatDataModel.shared, contactGroupID: [:],  contactRepository: ContactRepository(), selectedChat: .constant(nil)))
//    }
//}

import CoreData

extension AddGroupView {
    class Model: ObservableObject {
        @Published var messages: [AppContactListItem] = []
        @Published var contactPermission: CNAuthorizationStatus = .notDetermined
        @Published var contactGroupID = [String: String]()
        @Published var appContacts = [AppUser]()
        var contactRepository: ContactRepository!
        var authenticationService: AuthenticationService!
        
        @Published var alertMessage = ""
        @Published var alert = false
        
        private var persistenceController: PersistenceController!
        private var managedObjectContext: NSManagedObjectContext!
        private var appContactListController: AppContactListController!
        private var chatIdListController: ChatIdListController!
        
        private var cancellables: Set<AnyCancellable> = []
        
        init() {
         
        }
        
        func performOnceOnAppear(inMemory: Bool = false) {
            if inMemory {
                self.contactGroupID = ["+16505553535":SampleData.shared.groupId]
                self.contactRepository = ContactRepository.preview
                self.contactPermission = .authorized
                persistenceController = PersistenceController.preview
                managedObjectContext = PersistenceController.preview.container.viewContext
                authenticationService = AuthenticationService.preview
            } else {
                self.contactRepository = ContactRepository.shared
                self.contactPermission = contactRepository.currentAuthorizationStatus()
                persistenceController = PersistenceController.shared
                managedObjectContext = PersistenceController.shared.container.viewContext
                authenticationService = AuthenticationService.shared
            }
            
            appContactListController = AppContactListController(managedObjectContext: managedObjectContext)
            chatIdListController = ChatIdListController(managedObjectContext: managedObjectContext)
            
            addSubscribers()
            
            #if DEBUG
            //            createDevData()
            #endif
        }
        
        func loadChatIds(){
            let fetchRequest: NSFetchRequest<HwChatId> = HwChatId.fetchRequest()
//            fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatGroup.groupId), self.groupId)
            if let results = try? managedObjectContext.fetch(fetchRequest) {
                var chatIds = [String: String]()
                for hwItem in results {
                    chatIds[hwItem.phoneNumber!] = hwItem.groupId!
                }
                
                DispatchQueue.main.async {
//                        self.members = members
                    self.contactGroupID = chatIds
                }
            }
        }
        
        func loadAppContacts(){
            let fetchRequest: NSFetchRequest<HwAppContact> = HwAppContact.fetchRequest()
            if let results = try? managedObjectContext.fetch(fetchRequest) {
                var appContacts = [AppUser]()
                for hwItem in results {
                    guard let publicKeyData = hwItem.publicKey
                           else {
                              continue
                          }
                    let publicKey = publicKeyData.base64EncodedString()
                    let appContact = AppUser(uid: hwItem.uid!, phoneNumber: hwItem.phoneNumber!, publicKey: publicKey)
                    appContacts.append(appContact)
                }
                
                DispatchQueue.main.async {
//                        self.members = members
                    self.appContacts = appContacts
                }
            }
        }
        
        func addSubscribers() {
            
            appContactListController.$items
                .map { hwItems in
                    var appContacts = [AppUser]()
                    for hwItem in hwItems {
                        guard let publicKeyData = hwItem.publicKey
                        else {
                            continue
                        }
                        let publicKey = publicKeyData.base64EncodedString()
                        let appContact = AppUser(uid: hwItem.uid!, phoneNumber: hwItem.phoneNumber!, publicKey: publicKey)
                        appContacts.append(appContact)
                    }
                    
                    return appContacts
                }.assign(to: &$appContacts)
            
            chatIdListController.$items.map { hwItems in
                var chatIds = [String: String]()
                for hwItem in hwItems {
                    chatIds[hwItem.phoneNumber!] = hwItem.groupId!
                }
                return chatIds
            }.assign(to: &$contactGroupID)
            
//            let filteredGroupIDs = Just(contactGroupID)
//                .print("ContactGroups")
//                .filter({!$0.isEmpty})
            
//            let filteredAppContacts = contactRepository.$appContacts
//                .print("AppContacts")
//                .filter({!$0.isEmpty})
            
            let contactNames = contactRepository.$contactNames
//                .print("DeviceContacts")
                .filter({!$0.isEmpty})
            
            $appContacts
                .combineLatest($contactGroupID)
                .combineLatest(contactNames)
                .map({ (dicts, contactNames) -> [AppContactListItem] in
                    var items = [AppContactListItem]()
                    let (appContacts, chatIds) = dicts
                    
                    for appContact in appContacts {
                        let phoneNumber = appContact.phoneNumber
                        if  phoneNumber != self.authenticationService.account.phoneNumber!,
                            let fullName = contactNames[phoneNumber]{
                            let groupId = chatIds[phoneNumber]
                            items.append(AppContactListItem( id: appContact.uid, fullName: fullName, phoneNumber: appContact.phoneNumber, groupId: groupId, publicKey: appContact.publicKey!))
                        }
                    }
                    
                    return items.sorted {
                        $0.fullName.compare($1.fullName, options: .caseInsensitive) == .orderedAscending
                    }
                })
                .assign(to: &$messages)
        }
        
        func addGroup(contact: AppContactListItem) {
            //            print("tapped")
            //            let number = Int.random(in: 10..<100)
            //            let chat = Chat(id: "3\(number)", chatName: "Asitha 3\(number)", message: nil)
            //            chatModel.addChat(chat: chat)
            
            
            //            var chat: Chat?
            //            if let groupId = contact.groupId {
            //                chat = Chat(id: groupId, chatName: "Asitha", message: nil)
            //
            //            } else {
            //                let number = Int.random(in: 10..<20)
            //                chat = Chat(id: "", chatName: "Asitha", message: nil)
            //                chatModel.addChat(chat: chat!)
            //            }
        }
        
        func addNewGroup(with chat: ChatGroup){
            persistenceController.enqueue { context in
                let item = HwChatListItem(context: context)
                let groupId = chat.group
                let groupName = chat.groupName
                let channelId = chat.defaultChannel.channelUid
                let channelName = chat.defaultChannel.title
                item.groupId = groupId
                item.groupName = groupName
                item.channelId = channelId
                item.channelName = channelName
                item.isChat = chat.isChat
                item.unreadCount = 0
                
                let group = HwChatGroup(context: context)
                group.groupId = groupId
                group.groupName = groupName
                group.createdAt = Date()
                group.isChat = true
                
                let defaultChannel = HwChatChannel(context: context)
                defaultChannel.channelId = channelId
                defaultChannel.channelName = channelName
                group.defaultChannel = defaultChannel
                
                item.group = group
                item.isTemp = true
                
                for (_, appUser) in chat.members {
                    let member = HwGroupMember(context: context)
                    member.groupId = chat.group
                    member.uid = appUser.uid
                    member.phoneNumber = appUser.phoneNumber
                }
            }
        }
    }
}

