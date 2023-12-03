//
//  Account.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-22.
//

import Foundation
import PromiseKit
import FirebaseAuth
import FirebaseMessaging
import CryptoKit
import CoreData

class Account: ObservableObject {
    @Published var networkStatus: ClientNetworkStatus = .disconnected
    
    private var network: WebSocketService
    private var encryption: EncryptionService
    
    var user: User?
    var userId: String?
    var phoneNumber: String?
    var displayName: String?
    var publicKey: Data?
    
    var inMemory: Bool = false
    var isUpdatingToken: Bool = false
    
//    private var cancellables: Set<AnyCancellable> = []
    
    init(inMemory: Bool = false, user: User?, userId: String, phoneNumber: String, displayName: String) {
        self.inMemory = inMemory
        self.user = user
        self.userId = userId
        self.phoneNumber = phoneNumber
        self.displayName = displayName
        
        if inMemory {
            network = InMemoryWebSocketService(userId: userId, phoneNumber: phoneNumber)
            encryption = EncryptionService.preview
        } else {
            network = WebSocketService(userId: userId, phoneNumber: phoneNumber)
            encryption = EncryptionService.shared
            encryption.loadKeys()
            addSubscribers()
        }
    }
    
//    func performInitialDataLoading(for userId: String){
//        let isDataLoadedFromServer = UserDefaults.standard.bool(forKey: "isDataLoadedFromServer")
//        if !isDataLoadedFromServer {
//            UserDefaults.standard.set(true, forKey: "isDataLoadedFromServer")
//        }
//    }
    
//    func loadChatIds(userId: String){
//        print("Loading chatIds")
//        firstly {
//            ChatRepository.Api.loadContactIds(userId: userId)
//        }.done { [weak self] result in
//            self?.insertChatId(result.chatIds)
//            UserDefaults.standard.set(true, forKey: "isDataLoadedFromServer")
//        }.catch { error in
//            print("Error: \(error)")
//        }
//    }
    
//    func insertChatId(_ chatIds: [ChatIdModel]){
//        PersistenceController.shared.enqueue { context in
//            for chatId in chatIds {
//                let chatIdItem = HwChatId(context: context)
//                chatIdItem.groupId = chatId.groupId
//                chatIdItem.phoneNumber = chatId.phoneNumber
//            }
//        }
//
//    }
    
    func addSubscribers() {
        network.$networkStatus
            .handleEvents(receiveOutput: {
                print("Received network status ", $0)
            })
            .assign(to: &$networkStatus)
    }
    
    func getPublicKey() -> Data? {
        if let publicKey = publicKey {
            return publicKey
        } else if let userId = userId,
                  let privateKey = try? KeychainWrapper.shared.getGenericPasswordFor(account: userId, service: .encryption) {
            publicKey = privateKey.publicKey.rawRepresentation
            return publicKey
        }
        
        return nil
    }
    
    func getIdToken() -> Promise<String> {
        guard let user = user else {
            return .init(error: AuthError.userNil)
        }

        return Promise { seal in
            user.getIDToken { token, error in
                if let error = error {
//                    print("Error retrieving token: \(error.localizedDescription)")
                    seal.reject(error)
                    return
                }
                
                if let token = token {
                    seal.fulfill(token)
//                    print("token: \(token)")
                } else {
                    seal.reject(AuthError.idTokenNil)
                }
                
            }
        }
    }
    
    func connect() {
        firstly {
            getIdToken()
        }.done { idToken in
            self.network.connect(idToken: idToken)
        }.catch { error in
            print("Error while performing connect: \(error)")
        }
    }
    
    func disconnect() {
        network.disconnect()
    }
    
    func addUser(_ user: AddUserModel) -> Promise<Void> {
        firstly {
            getIdToken()
        }.then { idToken in
            RESTApi.addUser(user, idToken: idToken)
        }.then { user in
            self.updateProfile(with: user.displayName)
        }
    }
    
    func addDemoWorkspace(_ workspace: AddWorkspaceModel) -> Promise<AddGroupModel> {
        firstly {
            getIdToken()
        }.then { idToken in
            RESTApi.addDemoWorkspace(workspace, idToken: idToken)
        }
    }
    
    func addToken() {
        let lastUpdated = UserDefaults.standard.object(forKey: "deviceTokenLastUpdated")
        var needUpdate = false
        
        if let timestamp = lastUpdated as? Date, timestamp < Calendar.current.date(byAdding: .day, value: -30, to: Date())! {
            needUpdate = true
        }
        
        guard !isUpdatingToken && (lastUpdated == nil || needUpdate) else {
            return
        }
        
        isUpdatingToken = true
        
        firstly {
            getDeviceToken()
        }.then { deviceToken in
            self.addToken(deviceToken)
        }.ensure {
            self.isUpdatingToken = false
        }.done { _ in
            UserDefaults.standard.set(Date(), forKey: "deviceTokenLastUpdated")
            print("Account: perfomed device token update")
        }.catch { error in
            print("Error while performing addToken: \(error)")
        }
    }
    
    private func addToken(_ deviceToken: String) -> Promise<ApiResponse> {
        firstly {
            getIdToken()
        }.then { idToken in
            RESTApi.addUserToken(deviceToken, idToken: idToken)
        }
    }
    
    func updateThreadTitle(_ model: UpdateThreadTitleModel) -> Promise<ApiResponse> {
        firstly {
            getIdToken()
        }.then { idToken in
            RESTApi.updateThreadTitle(model, idToken: idToken)
        }
    }
    
    func getDeviceToken() -> Promise<String> {
        return Promise { seal in
            Messaging.messaging().token { token, error in
                if let error = error {
                    print("Error fetching FCM registration token: \(error)")
                    seal.reject(error)
                  } else if let token = token {
                    print("FCM registration token: \(token)")
                    seal.fulfill(token)
                  } else {
                    seal.reject(AuthError.deviceTokenNil)
                  }
            }
        }
    }
    
    func updateProfile(with displayName: String) -> Promise<Void> {
        let changeRequest = user?.createProfileChangeRequest()
        changeRequest?.displayName = displayName
        
        return Promise { seal in
            changeRequest?.commitChanges { error in
                if let error = error {
                    seal.reject(error)
                } else {
                    seal.fulfill(Void())
                }
            }
        }
    }
    
    func sync(_ contacts: [String]) -> Promise<[AppUser]> {
        firstly {
            getIdToken()
        }.then { idToken in
            RESTApi.sync(contacts, idToken: idToken)
        }
    }
    
    func deleteAccount() -> Promise<ApiResponse> {
        firstly {
            getIdToken()
        }.then { idToken in
            RESTApi.deleteAccount(idToken: idToken)
        }
    }
    
    
    
    
    func addGroup(_ chatGroup: ChatGroup, completion: @escaping (CentrifugePublishResult?, Error?)->()) {
        let defaultChannelModel = AddChannelModel(channelUid: chatGroup.defaultChannel.channelUid, title: chatGroup.defaultChannel.title, group: chatGroup.group)
        let model = AddGroupModel(author: userId!, group: chatGroup.group, groupName: chatGroup.groupName, isChat: chatGroup.isChat, defaultChannel: defaultChannelModel, members: chatGroup.members)
        
        network.write(type: .addGroup, data: model, completion: completion)
    }
    
    func addThreadWithMessage(threadUid: String, group: String, message: HwMessage, members: [String: AppUser], completion: @escaping (CentrifugePublishResult?, Error?)->()) {
        
        let title = HwChatListItem.getAttributedString(from: message)!
        addThread(threadUid: threadUid, group: group, title: title, replyingTo: nil, members: members, completion: completion)
    }
    
    func addThreadInReply(threadUid: String, group: String, replyingTo: HwChatMessage, members: [String: AppUser], completion: @escaping (CentrifugePublishResult?, Error?)->()) {
        
        let title = replyingTo.text!
        let replyingToMessageId = replyingTo.messageId
        
        addThread(threadUid: threadUid, group: group, title: title, replyingTo: replyingToMessageId, members: members, completion: completion)
    }
    
   func addThread(threadUid: String, group: String, title: NSAttributedString, replyingTo: String?, members: [String: AppUser], completion: @escaping (CentrifugePublishResult?, Error?)->()) {
        let titleMessage = getMessage(from: title)
        let model = AddThreadModel(author: userId!, threadUid: threadUid, group: group, title: titleMessage, replyingTo: replyingTo, members: members)
        network.write(type: .addThread, data: model, completion: completion)
    }
    
    func sendMessage(_ message: HwMessage, messageId: String, group: String, channel: String?, thread: String?, replyingTo: String?, receiver: String, completion: @escaping (CentrifugePublishResult?, Error?)->()) {
        var message = message
        if let content = message.content {
            message.content = encrypt(content: content, for: receiver, inGroup: group)
        }
        
        guard let senderPublicKey = getPublicKey()?.base64EncodedString() else {
            completion(nil, HamuwemuAuthError.missingPublicKey)
            return
        }
        
        let model = AddMessageModel(id: messageId, author: userId!, sender: phoneNumber!, timestamp: Date(), channel: channel, group: group, message: message, thread: thread, replyingInThreadTo: replyingTo, senderPublicKey: senderPublicKey)
        
        network.write(type: .addMessage, data: model, completion: completion)
    }
    
    func sendTaskLogItem(_ model: AddTaskLogItemModel, completion: @escaping (CentrifugePublishResult?, Error?)->()) {
        network.write(type: .addTaskLogItem, data: model, completion: completion)
    }
    
    func addReadReceipts(receipts: [ReadReceipt]) -> Promise<[ReadReceipt]> {
        Promise { seal in
            guard !receipts.isEmpty else {
                seal.fulfill(receipts)
                return
            }
            
            addReadReceipts(receipts: receipts) { _, error in
                if let error = error {
                    seal.reject(error)
                    print("Error while performing addReadReceipts: \(error)")
                    return
                }
                
                seal.fulfill(receipts)
            }
        }
    }
    
    func addReadReceipts(receipts: [ReadReceipt], completion: @escaping (CentrifugePublishResult?, Error?)->()) {
        let model = AddReadReceiptModel(receipts: receipts)
        
        network.write(type: .addReadReceipts, data: model, completion: completion)
    }
    
    //MARK: Helpers
    
    
    func encrypt(content: String, for receiver: String, inGroup salt: String) -> String {
        guard let userId = userId else {
            return content
        }
        
        return encryption.encrypt(content: content, for: receiver, inGroup: salt, userId: userId)
    }
    
    func decrypt(content: String, from sender: String, senderPublicKey: String?, inGroup salt: String) -> String {
        guard let userId = userId else {
            return content
        }
        
        return encryption.decrypt(content: content, from: sender, senderPublicKey: senderPublicKey, inGroup: salt, userId: userId)
    }
    
    func fetchAppContact(phoneNumber: String) -> HwAppContact? {
        let fetchRequest: NSFetchRequest<HwAppContact> = HwAppContact.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwAppContact.phoneNumber), phoneNumber)
        if let results = try? PersistenceController.shared.container.viewContext.fetch(fetchRequest),
           let item = results.first {
            return item
        }
        
        return nil
    }
}
