//
//  AddThreadView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-04-06.
//

import SwiftUI

struct AddThreadView: View {
    @Binding var tempThread: ChatThreadModel?
    @Binding var showTempThread: Bool
    
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var model = Model()
    var body: some View {
        NavigationView {
            List(model.items) { item in
                NavigationLink {
                    LazyDestination {
                        AddThreadNameView(chat: model.getChatGroup(contact: item), tempThread: $tempThread, showTempThread: $showTempThread, dismiss: {
                            presentationMode.wrappedValue.dismiss()
                        })
                    }
                } label: {
                    AddGroupListItemView(contact: item)
                }

            }
            .navigationTitle("New Thread")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                            presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                    }
                }
            }
        }
    }
}

struct AddThreadView_Previews: PreviewProvider {
    static var previews: some View {
        AddThreadView(tempThread: .constant(nil), showTempThread: .constant(false))
    }
}

import Combine
import CoreData
import Contacts

extension AddThreadView {
    class Model: ObservableObject {
        @Published var items: [AppContactListItem] = []
        @Published var contactPermission: CNAuthorizationStatus = .notDetermined
        @Published var chaIdMap = [String: String]()
        @Published var appContacts = [AppUser]()
        @Published var alertMessage = ""
        @Published var alert = false
  
        private var contactRepository: ContactRepository
        private var authenticationService: AuthenticationService
        private var persistenceController: PersistenceController
        private var managedObjectContext: NSManagedObjectContext
        
        private var cancellables: Set<AnyCancellable> = []
        
        init(inMemory: Bool = false) {
            if inMemory {
                self.chaIdMap = ["+16505553535":SampleData.shared.groupId]
                contactRepository = ContactRepository.preview
                self.contactPermission = .authorized
                persistenceController = PersistenceController.preview
                managedObjectContext = PersistenceController.preview.container.viewContext
                authenticationService = AuthenticationService.preview
            } else {
                contactRepository = ContactRepository.shared
                self.contactPermission = contactRepository.currentAuthorizationStatus()
                persistenceController = PersistenceController.shared
                managedObjectContext = PersistenceController.shared.container.viewContext
                authenticationService = AuthenticationService.shared
            }
            
            addSubscribers()
            loadChatIds()
            loadAppContacts()
        }
        
        func addSubscribers() {
            let contactNames = contactRepository.$contactNames
//                .print("DeviceContacts")
                .filter({!$0.isEmpty})
            
            $appContacts
                .combineLatest($chaIdMap)
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
                .assign(to: &$items)
        }
        
        func loadChatIds(){
            let fetchRequest: NSFetchRequest<HwChatId> = HwChatId.fetchRequest()
            if let results = try? managedObjectContext.fetch(fetchRequest) {
                var chatIds = [String: String]()
                for hwItem in results {
                    chatIds[hwItem.phoneNumber!] = hwItem.groupId!
                }
                
                DispatchQueue.main.async {
//                        self.members = members
                    self.chaIdMap = chatIds
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
        
        func getChatGroup(contact: AppContactListItem) -> ChatGroup {
            if let groupId = contact.groupId,
            let hwChatGroup = fetchChatGroup(groupId: groupId),
            let members = fetchGroupMembers(groupId: groupId){
                let chat = ChatGroup(from: hwChatGroup)
                chat.addMembers(appUsers: members)
                return chat
            } else {
                let currUser = AppUser(uid: authenticationService.account.userId!, phoneNumber: authenticationService.account.phoneNumber!)
                let members = [currUser, AppUser(uid: contact.id, phoneNumber: contact.phoneNumber)]
                let chat = ChatGroup(groupName: contact.phoneNumber, isChat: true, members: members)

                return chat
            }
        }
        
        func fetchChatGroup(groupId: String) -> HwChatGroup? {
            let fetchRequest: NSFetchRequest<HwChatGroup> = HwChatGroup.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatGroup.groupId), groupId)
            if let results = try? managedObjectContext.fetch(fetchRequest),
               let item = results.first {
                return item
            }
            
            return nil
        }
        
        func fetchGroupMembers(groupId: String) -> [AppUser]? {
            let fetchRequest: NSFetchRequest<HwGroupMember> = HwGroupMember.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwGroupMember.groupId), groupId)
            if let results = try? managedObjectContext.fetch(fetchRequest) {
                var members = [AppUser]()
                for hwItem in results {
                    let uid = hwItem.uid!
                    let phoneNumber = hwItem.phoneNumber!
                    let member = AppUser(uid: uid, phoneNumber: phoneNumber)
                    members.append(member)
                }
                
                return members
            }
            
            return nil
        }
    }
}
