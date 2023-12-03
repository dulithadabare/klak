//
//  ContactRepository.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/4/21.
//

import Foundation
import Contacts
import Combine

import FirebaseDatabase
import FirebaseAuth

struct AppUser {
    let uid: String
    let phoneNumber: String
}

class ContactService: ObservableObject {
    @Published var userContacts: [String] = []
    @Published var appContacts: [AppContact] = []
    private var ref = Database.root
    private var refHandle: DatabaseHandle?
    private let path = "user_contacts"
    private static let fileName = "contacts.json"
    
    //      @Published var cards: [Card] = []
    
    var userID = ""
    private let authenticationService: AuthStore
    private var cancellables: Set<AnyCancellable> = []
    
    init(authenticationService: AuthStore) {
        self.authenticationService = authenticationService
        
        NotificationCenter.default.addObserver(self, selector: #selector(sync), name: .CNContactStoreDidChange, object: nil)
        
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
    
    @objc func fetchContacts() {
    }
    
    @objc func sync() {
        // Check if any contact changes are made
        // if changed, sync with remote server
        // Update local cache
        
        let contacts = getDeviceContacts()
        let storedContacts = readContacts()
        var storedContactDict = [String: AppContact]()
        
        for appContact in storedContacts {
            storedContactDict[appContact.phoneNumber] = appContact
        }
        
        var isChanged = false
        
        for contact in contacts {
            let fullName = CNContactFormatter.string(from: contact, style: .fullName)
            for phone in contact.phoneNumbers {
                let phoneNumber = phone.value.stringValue
                if let appContact = storedContactDict[phoneNumber] {
                    if(appContact.fullName != fullName) {
                        //write to disk
                    }
                } else {
                    isChanged = true
                    break
                }
            }
        }
        
        if(isChanged || storedContacts.isEmpty ) {
            syncRemote(contacts: contacts.flatMap{$0.phoneNumbers.map{$0.value.stringValue}})
        }
    }
    
    func getDeviceContacts() -> [CNContact] {
        let contactStore = CNContactStore()
        //        var contacts = [CNContact]()
        var contacts = [CNContact]()
        //        let keys = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName)]
        let keys = [CNContactIdentifierKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor, CNContactFormatter.descriptorForRequiredKeys(for: .fullName)] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        
        do {
            try contactStore.enumerateContacts(with: request) { (contact, stop) in
                contacts.append(contact)
            }
        } catch {
            print(error.localizedDescription)
            return contacts
        }
        
        return contacts
    }
    
    func readContacts() -> [AppContact] {
        var appContacts = [AppContact]()
        
        if let userId = authenticationService.user?.uid {
            ref.child("user_device_contacts").child(userId).observeSingleEvent(of: .value, with: { snapshot in
                for child in snapshot.children {
                    let snap = child as! DataSnapshot
                    guard let value = snap.value as? [String: Any] else { return }
                    let phoneNumber = value["phoneNumber"] as? String ?? ""
                    let fullName = value["fullName"] as? String ?? ""
                    let appContact = AppContact(id: snap.key, fullName: fullName, phoneNumber: phoneNumber)
                    appContacts.append(appContact)
                }
                
            }) { error in
                print(error.localizedDescription)
            }
        }
        
        return appContacts
    }
    
    func syncRemote(contacts: [String]) {
        var users = [String: AppUser]()
        
        ref.child("users").observeSingleEvent(of: .value, with: { snapshot in
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                guard let value = snap.value as? [String: Any] else { return }
                                let uid = value["uid"] as? String ?? ""
                //                guard let hwUser = HwUser(id: uid, dict: value) else { return }
                //                print("Retrieved Firebase User", hwUser.displayName)
                let phoneNumber = value["phoneNumber"] as? String ?? ""
                let appUser = AppUser(uid: uid, phoneNumber: phoneNumber)
                users[phoneNumber] = appUser
            }
            
            var appUserContacts = [AppUser]()
            
            for contact in contacts {
                if let appUser = users[contact] {
                    appUserContacts.append(appUser)
                }
            }
            
            guard  let uid = self.authenticationService.user?.uid,
                   let currPhoneNumber = self.authenticationService.user?.phoneNumber else {
                return
            }
            
            var childUpdates = [String: Any]()
            
            for appUser in appUserContacts {
                let child = [
                    "phone_number": appUser.phoneNumber,
                    "uid": appUser.uid,
                ]
                childUpdates["/user_contacts/\(uid)/\(appUser.phoneNumber)"] = child
                // if first sync
                let newChild = [
                    "phone_number": currPhoneNumber,
                    "uid": uid,
                ]
                
                childUpdates["/user_contacts/\(appUser.uid)/\(currPhoneNumber)"] = newChild
            }
            
            self.ref.updateChildValues(childUpdates){
                (error:Error?, ref:DatabaseReference) in
                if let error = error {
                    print("Data could not be saved: \(error).")
                } else {
                    print("Data saved successfully!")
                }
            }
            
            
            
        }) { error in
            print(error.localizedDescription)
        }
    }
    
    func getFullName(for phoneNumber: String) {
        //        let store = CNContactStore()
        //        let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey] as [CNKeyDescriptor]
        //        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        //        do {
        //            let predicate = CNContact.predicateForContacts(matchingName: "Appleseed")
        //            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
        //            for contact in contacts {
        //                let fullName = CNContactFormatter.string(from: contact, style: .fullName)
        //                print("\(String(describing: fullName))")
        //            }
        //
        //        } catch {
        //            print("Failed to fetch contact, error: \(error)")
        //            // Handle the error
        //        }
    }
    
    func get() {
        var phoneNumbers = [String]()
        let userID = Auth.auth().currentUser?.uid
        
        ref.child(path).child(userID!).observeSingleEvent(of: .value, with: { [self] snapshot in
            // Get user value
            guard let value = snapshot.value as? [String: Any] else {return}
            for (key, _) in value {
                print(key)
                phoneNumbers.append(key)
            }
            
            self.userContacts.append(contentsOf: phoneNumbers)
        }) { error in
            print(error.localizedDescription)
        }
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
    
    func update(_ card: HwUser) {
        //    guard let cardId = card.id else { return }
        //
        //    do {
        //      try store.collection(path).document(cardId).setData(from: card)
        //    } catch {
        //      fatalError("Unable to update card: \(error.localizedDescription).")
        //    }
    }
    
    func remove(_ card: HwUser) {
        //    guard let cardId = card.id else { return }
        //
        //    store.collection(path).document(cardId).delete { error in
        //      if let error = error {
        //        print("Unable to remove card: \(error.localizedDescription)")
        //      }
        //    }
    }
    
    func readContactsFromDisk() -> [AppContact] {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(ContactService.fileName)
            
            do {
                let data = try Data(contentsOf: fileURL)
                let dataArray = try JSONDecoder().decode([AppContact].self, from: data)
                
                return dataArray
                
            } catch (let error) {
//                os_log(.error, log: .contacts, "Failed to parse list from disk: %@", error.localizedDescription)
                return []
            }
        }
        
//        os_log(.error, log: .contacts, "Unable to locate file")
        return []
    }
    
    func writeContactsToDisk() {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(ContactService.fileName)
            
            // Check if there was previously a file, if so remove it
            deleteContactsFromDisk()
            
            // Write the current contents to disk
            do {
                let encodedData = try? JSONEncoder().encode(appContacts)
                try encodedData?.write(to: fileURL)
                
//                os_log(.debug, log: .contacts, "Serialised contacts to Disk")
                return
                
            } catch (let error) {
//                os_log(.error, log: .contacts, "Failed to write to disk: %@", error.localizedDescription)
            }
        }
        
//        os_log(.error, log: .contacts, "Failed to find documents directory")
    }
    
    func deleteContactsFromDisk() {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(ContactService.fileName)
            
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
}
