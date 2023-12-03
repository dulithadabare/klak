//
//  ContactRepository.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/4/21.
//

import Foundation
import Contacts
import Combine
import CoreData
import FirebaseAuth
import PromiseKit

struct StoredContacts: Codable {
    let contacts: [String]
}

class ContactRepository: ObservableObject {
    @Published var deviceContacts = [String: [CNContact]]()
    @Published var contactNames = [String: String]()
    private static let fileName = "contacts.json"
    let contactStore = CNContactStore()
    @Published var isRefreshing: Bool = false
    private var persistenceController: PersistenceController
    
    //      @Published var cards: [Card] = []
    
    var userID = ""
    private let authenticationService: AuthenticationService
    private var cancellables: Set<AnyCancellable> = []
    
    // A singleton for our entire app to use
    
    static let shared = ContactRepository()
    
    static var preview: ContactRepository = {
        return ContactRepository(inMemory: true)
    }()
    
    private init(inMemory: Bool = false) {
        if inMemory {
            persistenceController = PersistenceController.preview
            authenticationService = AuthenticationService.preview
            
            contactNames["+16505553535"] = "Asitha"
            contactNames["+16505553636"] = "Kalpana"
            
        } else {
            persistenceController = PersistenceController.shared
            authenticationService = AuthenticationService.shared
//            print("Adding observer")
            NotificationCenter.default.addObserver(self, selector: #selector(fetchContacts), name: .CNContactStoreDidChange, object: nil)
            addSubscribers()
            requestPermission()
            fetchImportedContacts()
        }
       
        //        authenticationService.$user
        //          .compactMap { user in
        //            user?.uid
        //          }
        //          .assign(to: \.userID, on: self)
        //          .store(in: &cancellables)
        //
        //        authenticationService.$user
        //          .receive(on: DispatchQueue.main)
        //          .sink{ [weak self] _ in
        //            self?.get()
        //          }
        //          .store(in: &cancellables)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .CNContactStoreDidChange, object: nil)
    }
    
    func requestPermission(){
        if currentAuthorizationStatus() == .notDetermined {
            requestAccessIfNeeded { granted, error in
                if let error = error {
                    print("Error while requesting contact permission \(error.localizedDescription)")
                    return
                }
                
                if granted {
                    self.fetchContacts()
                }
            }
        } else if currentAuthorizationStatus() == .authorized {
            fetchContacts()
        }
    }
    
    func addSubscribers(){
        $deviceContacts
            //            .print("deviceContacts")
            .dropFirst()
            .sink(receiveValue: { deviceContacts in
                var importedContacts = [ImportedContact]()
                var contactNames = [String: String]()
                for (phoneNumber, contacts) in deviceContacts {
                    let first = contacts.first!
                    let fullName = CNContactFormatter.string(from: first, style: .fullName)
                    contactNames[phoneNumber] = fullName
                    if let fullName = fullName {
                        importedContacts.append(ImportedContact(phoneNumber: phoneNumber, displayName: fullName))
                    }
                }
                self.contactNames = contactNames
                self.sync(deviceContacts)
                self.persistenceController.importContacts(from: importedContacts)
            })
            .store(in: &cancellables)
    }
    
    func fetchImportedContacts() {
        guard currentAuthorizationStatus() == .authorized else {
            return
        }
        
        let request = HwImportedContact.fetchRequest()
        do {
            let results = try persistenceController.container.viewContext.fetch(request)
            for hwItem in results {
                if let fullName = hwItem.displayName {
                    self.contactNames[hwItem.phoneNumber!] = fullName
                }
                
            }
        } catch {
            print("Error: could not fetch imported contacts \(error)")
        }
    }
    
    @objc func fetchContacts() {
        print("Fetching contacts")
        if isRefreshing || currentAuthorizationStatus() != .authorized {
            return
        }
        
        isRefreshing = true
        //        var contacts = [CNContact]()
        var contacts = [CNContact]()
        //        let keys = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName)]
        let keys = [CNContactIdentifierKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor, CNContactFormatter.descriptorForRequiredKeys(for: .fullName)] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let strongSelf = self else { return }
            do {
                try strongSelf.contactStore.enumerateContacts(with: request) { (contact, stop) in
                    contacts.append(contact)
                }
                
                var contactDict = [String: [CNContact]]()
                
                for contact in contacts {
                    for phone in contact.phoneNumbers {
                        let phoneNumber = phone.value.stringValue.replacingOccurrences(of: "[^+0-9]", with: "", options: .regularExpression)
                        contactDict.merge(zip([phoneNumber], [[contact]]), uniquingKeysWith: { (current, new) in
                            var temp = [CNContact]()
                            temp.append(contentsOf: current)
                            temp.append(contentsOf: new)
                            return temp
                            
                        } )
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    strongSelf.isRefreshing = false
                    strongSelf.deviceContacts = contactDict
                }
                
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    @objc func sync(_ deviceContacts: [String: [CNContact]]) {
        // Check if any contact changes are made
        // if changed, sync with remote server
        // Update local cache
        
        firstly {
            filterContacts(deviceContacts)
        }.then { updatedStoredContacts in
            self.authenticationService.account.sync(updatedStoredContacts)
        }.done(on: .global()) { appUserContacts in
            //update app users
            self.insertAppContact(appUserContacts)
            self.removeDeletedAppContacts(currAppContacts: appUserContacts.map({$0.phoneNumber}))
        }.catch { error in
            print("Error while performing sync: \(error)")
        }
    }
    
    func filterContacts(_ deviceContacts: [String: [CNContact]]) -> Promise<[String]> {
        Promise { seal in
            DispatchQueue.global(qos: .background).async { [self] in
                
                let storedContacts = readContactsFromDisk()
                var updatedContacts = storedContacts
                var storedContactDict = [String: Bool]()
                
                for phoneNumber in storedContacts {
                    storedContactDict[phoneNumber] = true
                }
                
                //check for added contacts
                var newContacts = [String]()
                for (phoneNumber, _) in deviceContacts {
                    if storedContactDict[phoneNumber] == nil {
                        newContacts.append(phoneNumber)
                        updatedContacts.append(phoneNumber)
                    }
                }
                
                //check for deleted contacts
                var removedContacts = [String]()
                for (phoneNumber, _) in storedContactDict {
                    if deviceContacts[phoneNumber] == nil, let index = storedContacts.firstIndex(of: phoneNumber) {
                        updatedContacts.remove(at: index)
                        removedContacts.append(phoneNumber)
                        print("Removing \(phoneNumber) from contacts")
                    }
                }
                
                writeContactsToDisk(contacts: updatedContacts)
                
                
                //remove deleted contacts from app users
                if !removedContacts.isEmpty {
                    removeAppContact(removedContacts)
                }
                
                seal.fulfill(updatedContacts)
            }
        }
    }
    
    func removeDeletedAppContacts(currAppContacts: [String]){
        let storedAppContacts = loadAppContacts()
        var deletedAppContacts = [String]()
        
        for storedAppContact in storedAppContacts {
            if currAppContacts.firstIndex(of: storedAppContact) == nil {
                deletedAppContacts.append(storedAppContact)
            }
        }
        
        removeAppContact(deletedAppContacts)
    }
    
    func removeAppContact(_ contacts: [String]){
        persistenceController.enqueue { context in
            let fetchRequest: NSFetchRequest<HwAppContact> = HwAppContact.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K IN %@",#keyPath(HwAppContact.phoneNumber), contacts)

            guard let results = try? context.fetch(fetchRequest) else {
                return
            }

            for item in results {
                context.delete(item)
            }
        }
    }
    
    func insertAppContact(_ appContacts: [AppUser]){
        persistenceController.enqueue { context in
            for appContact in appContacts {
                guard let publicKey = appContact.publicKey,
                      !publicKey.isEmpty,
                    let publicKeyData = Data(base64Encoded: publicKey) else {
                            continue
                        }
                let item = HwAppContact(context: context)
                item.phoneNumber = appContact.phoneNumber
                item.uid = appContact.uid
                item.publicKey = publicKeyData
            }
        }
    }
    
    func loadAppContacts() -> [String] {
        var appContacts = [String]()
        
        let fetchRequest: NSFetchRequest<HwAppContact> = HwAppContact.fetchRequest()

        guard let results = try? persistenceController.container.viewContext.fetch(fetchRequest) else {
            return appContacts
        }
        
        for item in results {
            appContacts.append(item.phoneNumber!)
        }
        
        return appContacts
    }
    
    func getFullName(for phoneNumber: String)  -> String {
//        guard let contacts  = deviceContacts[phoneNumber],
//              let first = contacts.first,
//              let fullName = CNContactFormatter.string(from: first, style: .fullName) else {
//            return nil
//        }
        
        return contactNames[phoneNumber] ?? phoneNumber
    }
    
    func get() {
//        var phoneNumbers = [String]()
//        let userID = Auth.auth().currentUser?.uid
//
//        ref.child(path).child(userID!).observeSingleEvent(of: .value, with: { snapshot in
//            // Get user value
//            guard let value = snapshot.value as? [String: Any] else {return}
//            for (key, _) in value {
//                print(key)
//                phoneNumbers.append(key)
//            }
//
//            //            self.userContacts.append(contentsOf: phoneNumbers)
//        }) { error in
//            print(error.localizedDescription)
//        }
        //    store.collection(path)
        //      .whereField("userID", isEqualTo: userID)
        //      .addSnapshotListener { querySnapshot, error in
        //        if let error = error {
        //          print("Error getting cards: \(error.localizedDescription)")
        //          return
        //        }
        //
        //        self.cards = querySnapshot?.documents.compactMap { document in
        //          try? document.data(as: Card.self)
        //        } ?? []
        //      }
    }
    
    func add(_ appUserContacts: [String]) {
        //        guard let key = ref.child("posts").childByAutoId().key else { return }
        //        let post = ["uid": userID,
        //                    "author": username,
        //                    "title": title,
        //                    "body": body]
        //        let childUpdates = ["/posts/\(key)": post,
        //                            "/user-posts/\(userID)/\(key)/": post]
        //        ref.updateChildValues(childUpdates)
        
        
    }
    
//    func update(_ card: AddUserModel) {
//        //    guard let cardId = card.id else { return }
//        //
//        //    do {
//        //      try store.collection(path).document(cardId).setData(from: card)
//        //    } catch {
//        //      fatalError("Unable to update card: \(error.localizedDescription).")
//        //    }
//    }
//    
//    func remove(_ card: AddUserModel) {
//        //    guard let cardId = card.id else { return }
//        //
//        //    store.collection(path).document(cardId).delete { error in
//        //      if let error = error {
//        //        print("Unable to remove card: \(error.localizedDescription)")
//        //      }
//        //    }
//    }
    
    func readContactsFromDisk() -> [String] {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(ContactRepository.fileName)
            
            do {
                let data = try Data(contentsOf: fileURL)
                let dataArray = try JSONDecoder().decode([String].self, from: data)
                
                return dataArray
                
            } catch (let error) {
                //                os_log(.error, log: .contacts, "Failed to parse list from disk: %@", error.localizedDescription)
                return []
            }
        }
        
        //        os_log(.error, log: .contacts, "Unable to locate file")
        return []
    }
    
    func writeContactsToDisk(contacts: [String]) {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(ContactRepository.fileName)
            
            // Check if there was previously a file, if so remove it
            deleteContactsFromDisk()
            
            // Write the current contents to disk
            do {
                let encodedData = try JSONEncoder().encode(contacts)
                try encodedData.write(to: fileURL)
                
                //                os_log(.debug, log: .contacts, "Serialised contacts to Disk")
                return
                
            } catch (let error) {
                print("Error occured while saving contacts: \(error)")
                //                os_log(.error, log: .contacts, "Failed to write to disk: %@", error.localizedDescription)
            }
        }
        
        //        os_log(.error, log: .contacts, "Failed to find documents directory")
    }
    
    func deleteContactsFromDisk() {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(ContactRepository.fileName)
            
            // Check if there was previously a file, if so remove it
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                    return
                    
                } catch (let error) {
                    //                    os_log(.error, log: .contacts, "Failed to delete previous json file: %@", "\(error)")
                }
            }
        }
    }
    
    func currentAuthorizationStatus() -> CNAuthorizationStatus {
        return type(of: contactStore).authorizationStatus(for: CNEntityType.contacts)
    }
    
    func requestAccessIfNeeded(completion: @escaping ((Bool, Error?) -> Void)) {
        let authStatus = currentAuthorizationStatus()
        if authStatus == .notDetermined {
            //            (UIApplication.shared.delegate as? AppDelegate)?.launchingSystemPopup = true
            contactStore.requestAccess(for: CNEntityType.contacts) { (granted, error) in
                if let err = error {
                    //                    os_log("Error requesting contacts permissions: %@", log: .contacts, type: .error, "\(err)")
                }
                DispatchQueue.main.async { completion(granted, error) }
            }
            
        } else if authStatus == .authorized {
            DispatchQueue.main.async { completion(true, nil) }
            
        } else {
            DispatchQueue.main.async { completion(false, nil) }
        }
    }
}
