//
//  PersistenceController.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/27/21.
//

import CoreData
import OSLog
import UIKit
import PromiseKit

class PersistenceController: ObservableObject {
    // A singleton for our entire app to use
    static let shared = PersistenceController()
    
    // MARK: Logging

    let logger = Logger(subsystem: "com.dabare.hamuwemu", category: "persistence")

    // Storage for Core Data
    let container: NSPersistentContainer
    private var notificationToken: NSObjectProtocol?
    private lazy var persistentContainerQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
//    lazy var taskContext: NSManagedObjectContext = {
//        // Create a private queue context.
//        /// - Tag: newBackgroundContext
//        let taskContext = container.newBackgroundContext()
//        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
//        return taskContext
//    }()

    // An initializer to load Core Data, optionally able
    // to use an in-memory store.
    init(inMemory: Bool = false) {
        // If you didn't name your model Main you'll need
        // to change this name below.
        TextAttributeTransformer.register()
        container = NSPersistentContainer(name: "Main")
        persistentContainerQueue.maxConcurrentOperationCount = 1
        
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }

        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        } else {
            let groupName = "group.com.dabare.hamuwemu"
            description.url = FileManager.default
              .containerURL(forSecurityApplicationGroupIdentifier: groupName)!
              .appendingPathComponent("Main.sqlite")
            
            // Enable persistent store remote change notifications
            /// - Tag: persistentStoreRemoteChange
            description.setOption(true as NSNumber,
                                  forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            // Enable persistent history tracking
            /// - Tag: persistentHistoryTracking
            description.setOption(true as NSNumber,
                                  forKey: NSPersistentHistoryTrackingKey)
          }
        
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true


        container.loadPersistentStores { description, error in
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            self.container.viewContext.stalenessInterval = 0
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
//        NotificationCenter.default.addObserver(self, selector: #selector(contextDidSave(_:)), name: Notification.Name.NSManagedObjectContextDidSave, object: taskContext)
        
        // Observe Core Data remote change notifications on the queue where the changes were made.
        notificationToken = NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange, object: nil, queue: nil) { note in
            if let storeUrl = note.userInfo?[NSPersistentStoreURLKey] as? String {
                self.logger.debug("Received a persistent store remote change notification. storeUrl \(storeUrl)")
            }
            self.logger.debug("Received a persistent store remote change notification.")
            Task {
                await self.fetchPersistentHistory()
            }
        }
    }
    
    deinit {
        if let observer = notificationToken {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    /// A peristent history token used for fetching transactions from the store.
    private var lastToken: NSPersistentHistoryToken? = nil
    {
        didSet {
            guard let token = lastToken,
                  let data = try? NSKeyedArchiver.archivedData(
                    withRootObject: token,
                    requiringSecureCoding: true
                  ) else { return }
            do {
                try data.write(to: tokenFile)
            } catch {
                let message = "Could not write token data"
                print("###\(#function): \(message): \(error)")
            }
        }
    }
    
//    {
//        get {
//                guard let data = UserDefaults.extensions.data(forKey: "persistentHistoryToken") else { return nil }
//            return (try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)) as? NSPersistentHistoryToken
//            }
//            set {
//                guard let newValue = newValue else { return }
//                let encodedData = try? NSKeyedArchiver.archivedData(
//                    withRootObject: newValue,
//                    requiringSecureCoding: true
//                )
//                UserDefaults.extensions.set(encodedData, forKey: "persistentHistoryToken")
//            }
//
//    }
    
    lazy var tokenFile: URL = {
        let groupName = "group.com.dabare.hamuwemu"
        let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupName)!
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(
                    at: url,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                let message = "Could not create persistent container URL"
                print("###\(#function): \(message): \(error)")
            }
        }
        return url.appendingPathComponent("token.data", isDirectory: false)
    }()
    
    func deleteAllEntities() {
        let entities = container.managedObjectModel.entities
        for entitie in entities {
            debugPrint("Deleting Entitie - ", entitie.name ?? "None")
          delete(entityName: entitie.name!)
        }
      }
      
      func delete(entityName: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try container.viewContext.execute(deleteRequest)
          debugPrint("Deleted Entitie - ", entityName)
        } catch let error as NSError {
          debugPrint("Delete ERROR \(entityName)")
          debugPrint(error)
        }
      }
    
    //swift
    @discardableResult
    func enqueue(contextName: String? = nil, transactionAuthor: String? = nil, block: @escaping (_ context: NSManagedObjectContext) -> Void) -> Promise<Void> {
        return Promise { seal in
            persistentContainerQueue.addOperation(){
              let context: NSManagedObjectContext = self.container.newBackgroundContext()
                context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                context.name = contextName
                context.transactionAuthor = transactionAuthor
                context.performAndWait{
                  block(context)
                    if context.hasChanges {
                        do {
                            try context.save()
                            seal.fulfill(Void())
                        } catch {
                            // Show some error here
                            seal.reject(error)
                            let nserror = error as NSError
                                        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                        }
                    } else {
                        seal.fulfill(Void())
                    }
                }
                
                context.transactionAuthor = nil
              }
        }
   }
    
    /// Creates and configures a private queue context.
    private func newTaskContext() -> NSManagedObjectContext {
        // Create a private queue context.
        /// - Tag: newBackgroundContext
        let taskContext = container.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Set unused undoManager to nil for macOS (it is nil by default on iOS)
        // to reduce resource requirements.
        taskContext.undoManager = nil
        return taskContext
    }
    
    /// Uses `NSBatchInsertRequest` (BIR) to import a JSON dictionary into the Core Data store on a private queue.
    func importContacts(from propertiesList: [ImportedContact]) {
        guard !propertiesList.isEmpty else { return }

        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "importContext"
        taskContext.transactionAuthor = "importQuakes"

        /// - Tag: perform
        taskContext.perform {
            // Execute the batch insert.
            /// - Tag: batchInsertRequest
            let batchInsertRequest = self.newBatchInsertRequest(with: propertiesList)
            if let fetchResult = try? taskContext.execute(batchInsertRequest),
               let batchInsertResult = fetchResult as? NSBatchInsertResult,
               let success = batchInsertResult.result as? Bool, success {
                self.logger.debug("PersistanceController: Successfully inserted data.")
                return
            }
            self.logger.debug("PersistanceController: Failed to execute batch insert request.")
        }
    }

    private func newBatchInsertRequest(with propertyList: [ImportedContact]) -> NSBatchInsertRequest {
        var index = 0
        let total = propertyList.count

        // Provide one dictionary at a time when the closure is called.
        let batchInsertRequest = NSBatchInsertRequest(entity: HwImportedContact.entity(), dictionaryHandler: { dictionary in
            guard index < total else { return true }
            dictionary.addEntries(from: propertyList[index].dictionaryValue)
            index += 1
            return false
        })
        return batchInsertRequest
    }
    
    @objc func contextDidSave(_ notification: Notification) {
        print(notification)
        let viewContext = container.viewContext
        viewContext.perform {
            viewContext.mergeChanges(fromContextDidSave: notification)
        }
        
//        if let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as? Set<HwChatMessage>, !insertedObjects.isEmpty {
//                print(insertedObjects)
//
//            }
//
//        if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updatedObjects.isEmpty {
//                print(updatedObjects)
//            }
    }
    
    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Show some error here
                let nserror = error as NSError
                            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func fetchPersistentHistory() async {
        do {
            try await fetchPersistentHistoryTransactionsAndChanges()
        } catch {
            logger.debug("\(error.localizedDescription)")
        }
    }

    private func fetchPersistentHistoryTransactionsAndChanges() async throws {
        let taskContext = newTaskContext()
        taskContext.name = "persistentHistoryContext"
        logger.debug("Start fetching persistent history changes from the store...")

        try await taskContext.perform {
            // Execute the persistent history change since the last transaction.
            /// - Tag: fetchHistory
            let changeRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: self.lastToken)
            let historyResult = try taskContext.execute(changeRequest) as? NSPersistentHistoryResult
            if let history = historyResult?.result as? [NSPersistentHistoryTransaction],
               !history.isEmpty {
                let filteredTransactions = history.filter({ transaction in
                    if let contextName = transaction.contextName,
                    contextName == "importContext"{
                        return true
                    }
                    
                    if let transactionAuthor = transaction.author,
                       transactionAuthor == "nse"{
                        return true
                    }
                    
                    return false
                })
                
                guard !filteredTransactions.isEmpty else {
                    return
                }
                
                self.mergePersistentHistoryChanges(from: filteredTransactions)
                return
            }

            self.logger.debug("No persistent history transactions found.")
            throw PersistenceError.persistentHistoryChangeError
        }

        logger.debug("Finished merging history changes.")
    }

    private func mergePersistentHistoryChanges(from history: [NSPersistentHistoryTransaction]) {
        self.logger.debug("Received \(history.count) persistent history transactions.")
        // Update view context with objectIDs from history change request.
        /// - Tag: mergeChanges
        let viewContext = container.viewContext
        let previousToken = lastToken
        viewContext.perform {
            for transaction in history {
                // the list of changes
                if let changes = transaction.changes {
                    for change in changes {
                            
                            let objectID = change.changedObjectID
                            let changeID = change.changeID
                            let transaction = change.transaction
                            let changeType = change.changeType
                            
                            switch(changeType) {
                            case .update:
                                guard let updatedProperties = change.updatedProperties else { break }
                                for updatedProperty in updatedProperties {
                                    let name = updatedProperty.name
                                    print("\(name) updated ")
                                }
                            case .delete:
                                if let tombstone = change.tombstone {
                                    let name = tombstone["name"]
                                }
                            default:
                                break
                            }
                        }
                }
                
                
                viewContext.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
                self.lastToken = transaction.token
            }
            self.purgePersistentHistory()
        }
    }
    
    private func purgePersistentHistory() {
        let sevenDaysAgo = Date(timeIntervalSinceNow: TimeInterval(exactly: -604_800)!)
        let purgeHistoryRequest =
            NSPersistentHistoryChangeRequest.deleteHistory(
                before: sevenDaysAgo)

        do {
            try container.newBackgroundContext().execute(purgeHistoryRequest)
        } catch {
            fatalError("Could not purge history: \(error)")
        }
    }
}

extension PersistenceController {
    func loadGroupMembers(_ groupId: String) -> [String: AppUser]? {
        let request: NSFetchRequest<HwGroupMember> = HwGroupMember.fetchRequest()
        request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwGroupMember.groupId), groupId)
        request.sortDescriptors = [
            NSSortDescriptor(
                keyPath: \HwGroupMember.uid,
                ascending: false)]
        
        do {
            let results = try container.viewContext.fetch(request)
            var appUserMap: [String: AppUser] = [:]
            for hwItem in results {
                let appUser = AppUser(uid: hwItem.uid!, phoneNumber: hwItem.phoneNumber!)
                appUserMap[hwItem.uid!] = appUser
            }
            
            return appUserMap
        } catch {
            print("Error fetching \(error)")
        }
        
        return nil
    }
    
    func update(imageDocumentUrl: String, for messageId: String) -> Promise<Void> {
        enqueue { context in
            let fetchRequest: NSFetchRequest<HwChatMessage> = HwChatMessage.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatMessage.messageId), messageId)
            
            if let results = try? context.fetch(fetchRequest),
               let item = results.first {
                item.imageDocumentUrl = imageDocumentUrl
            }
        }
    }
}

extension PersistenceController {
    func insertGroup(_ chat: AddGroupModel, transactionAuthor: String? = nil) -> Promise<Void> {
        enqueue(transactionAuthor: transactionAuthor) { context in
            let group = HwChatGroup(context: context)
            group.groupId = chat.group
            group.groupName = chat.groupName
            group.createdAt = Date()
            group.isChat = chat.isChat
            group.isTemp = false
            
            let defaultChannel = HwChatChannel(context: context)
            defaultChannel.channelId = chat.defaultChannel.channelUid
            defaultChannel.channelName = chat.defaultChannel.title
            group.defaultChannel = defaultChannel
            
            let item = HwChatListItem(context: context)
            item.groupId = chat.group
            item.groupName = chat.groupName
            item.channelId = chat.defaultChannel.channelUid
            item.channelName = chat.defaultChannel.title
            item.unreadCount = 0
            item.group = group
            
            for (_, member) in chat.members {
                let groupMember = HwGroupMember(context: context)
                groupMember.uid = member.uid
                groupMember.phoneNumber = member.phoneNumber
                groupMember.groupId = chat.group
            }
        }
        
    }
    
    func insertThread(_ thread: AddThreadModel, transactionAuthor: String? = nil) -> Promise<Void> {
        let titleText = HwChatListItem.getAttributedString(from: thread.title)
        
        return enqueue(transactionAuthor: transactionAuthor) { context in
            //create thread
            let item = HwThreadListItem(context: context)
            let threadItem = HwChatThread(context: context)
            
            threadItem.threadId = thread.threadUid
            threadItem.titleText = titleText
            threadItem.groupId = thread.group
            
            threadItem.isTemp = false
            threadItem.threadListItem = item
            
            if let _ = thread.replyingTo {
                threadItem.isReplyingTo = true
            }
            
            item.thread = threadItem
            item.threadId = thread.threadUid
            item.groupId = thread.group
            item.unreadCount = 0
            
            //add thread memebers
            for (_, user) in thread.members {
                let member = HwThreadMember(context: context)
                member.threadId = thread.threadUid
                member.uid = user.uid
                member.phoneNumber = user.phoneNumber
            }
            
            let fetchRequest: NSFetchRequest<HwChatGroup> = HwChatGroup.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatGroup.groupId), thread.group)
            
            if let results = try? context.fetch(fetchRequest),
               let groupItem = results.first {
                groupItem.addToThreads(threadItem)
                threadItem.group = groupItem
            }
        }
    }
    
    func getMessageTypeRawValue(from message: HwMessage) -> Int16 {
        var type: MessageType = .text
        
        let containsImage = message.imageDownloadUrl != nil || message.imageDocumentUrl != nil
        if message.content != nil && containsImage {
            type = .imageWithCaption
        } else if containsImage {
            type = .image
        }
        
        return type.rawValue
    }
    
    func insertMessage(_ message: AddMessageModel, transactionAuthor: String? = nil) -> Promise<Void> {
        if let _ = message.channel {
            return insertChannelMessage(message, transactionAuthor: transactionAuthor)
        } else if let _ = message.thread {
            return insertThreadMessage(message, transactionAuthor: transactionAuthor)
        }
        
        return .value(Void())
    }
    
    func insertChannelMessage(_ message: AddMessageModel, transactionAuthor: String? = nil) -> Promise<Void> {
        let messageText = HwChatListItem.getAttributedString(from: message.message)
        let messageType = getMessageTypeRawValue(from: message.message)
        return enqueue(transactionAuthor: transactionAuthor) { context in
            let item = HwChatMessage(context: context)
            
            item.author = message.author
            item.sender = message.sender
            item.groupUid = message.group
            item.channelUid = message.channel
            item.threadUid = message.thread
            item.isSystemMessage = false
            item.messageId = message.id
            item.timestamp = message.timestamp
            item.text = messageText
            item.isReadByMe = false
            item.statusRawValue = MessageStatus.none.rawValue
            item.imageDownloadUrl = message.message.imageDownloadUrl
            item.imageDocumentUrl = message.message.imageDocumentUrl
            item.imageThumbnailBase64 = message.message.imageBlurHash
            item.senderPublicKey = message.senderPublicKey
            
            let fetchRequest: NSFetchRequest<HwChatListItem> = HwChatListItem.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatListItem.groupId), message.group)
            
            if let results = try? context.fetch(fetchRequest),
               let listItem = results.first {
                listItem.lastMessageText =  messageText?.string  ?? "Image"
                listItem.lastMessageSender = message.sender
                listItem.lastMessageId = message.id
                listItem.lastMessageDate = message.timestamp
                listItem.lastMessageAttrText = messageText
                listItem.lastMessageAuthorUid = message.author
                listItem.lastMessageStatusRawValue = MessageStatus.none.rawValue
                listItem.threadId = nil
                listItem.unreadCount += message.isOutgoingMessage ? 0 : 1
                listItem.lastMessageType = messageType
            }
            
            if let replyingTo = message.replyingInThreadTo {
                let fetchRequest: NSFetchRequest<HwChatMessage> = HwChatMessage.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatMessage.messageId), replyingTo)
                if let results = try? context.fetch(fetchRequest),
                   let replyingToMessage = results.first {
                    item.replyingTo = replyingToMessage
                    replyingToMessage.addToReplies(item)
                    replyingToMessage.replyCount += 1
                    replyingToMessage.replyingThreadId = item.threadUid
                }
            }
        }
    }
    
    func insertThreadMessage(_ message: AddMessageModel, transactionAuthor: String? = nil) -> Promise<Void> {
        let messageText = HwChatListItem.getAttributedString(from: message.message)
        let messageType = getMessageTypeRawValue(from: message.message)
        return enqueue(transactionAuthor: transactionAuthor) { context in
            let item = HwChatMessage(context: context)
            
            item.author = message.author
            item.sender = message.sender
            item.groupUid = message.group
            item.channelUid = message.channel
            item.threadUid = message.thread
            item.isSystemMessage = false
            item.messageId = message.id
            item.timestamp = message.timestamp
            item.text = messageText
            item.isReadByMe = false
            item.statusRawValue = MessageStatus.none.rawValue
            item.imageDownloadUrl = message.message.imageDownloadUrl
            item.imageDocumentUrl = message.message.imageDocumentUrl
            item.imageThumbnailBase64 = message.message.imageBlurHash
            item.senderPublicKey = message.senderPublicKey
            
            let fetchRequest: NSFetchRequest<HwThreadListItem> = HwThreadListItem.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwThreadListItem.threadId), message.thread!)
            
            if let results = try? context.fetch(fetchRequest),
               let listItem = results.first {
                listItem.lastMessageText =  messageText
                listItem.lastMessageSender = message.sender
                listItem.lastMessageId = message.id
                listItem.lastMessageDate = message.timestamp
                listItem.lastMessageStatusRawValue = MessageStatus.none.rawValue
                listItem.unreadCount += message.isOutgoingMessage ? 0 : 1
                listItem.lastMessageAuthorUid = message.author
                listItem.lastMessageType = messageType
            }
            
            let request: NSFetchRequest<HwChatListItem> = HwChatListItem.fetchRequest()
            request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatListItem.groupId), message.group)
            
            if let results = try? context.fetch(request),
               let listItem = results.first {
                listItem.lastMessageText =  messageText?.string  ?? "Image"
                listItem.lastMessageSender = message.sender
                listItem.lastMessageId = message.id
                listItem.lastMessageDate = message.timestamp
                listItem.lastMessageAttrText = messageText
                listItem.lastMessageAuthorUid = message.author
                listItem.lastMessageStatusRawValue = MessageStatus.none.rawValue
                listItem.threadId = message.thread
                listItem.unreadCount += message.isOutgoingMessage ? 0 : 1
                listItem.threadUnreadCount += message.isOutgoingMessage ? 0 : 1
                listItem.lastMessageType = messageType
                
                if let threadId = message.thread {
                    let threadRequest: NSFetchRequest<HwChatThread> = HwChatThread.fetchRequest()
                    threadRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatThread.threadId), threadId)
                    
                    if let threadResults = try? context.fetch(threadRequest),
                       let thread = threadResults.first {
                        listItem.thread = thread
                    }
                }
            }
            
            
            if let replyingTo = message.replyingInThreadTo {
                let fetchRequest: NSFetchRequest<HwChatMessage> = HwChatMessage.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatMessage.messageId), replyingTo)
                if let results = try? context.fetch(fetchRequest),
                   let replyingToMessage = results.first {
                    item.replyingTo = replyingToMessage
                    replyingToMessage.addToReplies(item)
                    replyingToMessage.replyCount += 1
                    replyingToMessage.replyingThreadId = item.threadUid
                }
            }
        }
    }
    
    func insertTask(_ task: AddTaskModel, transactionAuthor: String? = nil) -> Promise<Void> {
        let messageText = HwChatListItem.getAttributedString(from: task.message)
        return enqueue(transactionAuthor: transactionAuthor) { context in
            let item = KlakTask(context: context)
            
            item.taskId = task.id
            item.title = task.title
            item.message = messageText
            item.assignedTo = task.assignedTo
            item.assignedBy = task.assignedBy
            item.dueDate = task.dueDate
            item.isUrgent = task.isUrgent
            item.groupUid = task.groupUid
            item.latestStatusRawValue = TaskStatus.open.rawValue
            item.unreadCount = 0
            item.isMarkedToday = false
        }
    }
    
    func insertTaskLogItem(_ logItem: AddTaskLogItemModel, transactionAuthor: String? = nil) -> Promise<Void> {
        let messageText = HwChatListItem.getAttributedString(from: logItem.message)
        return enqueue(transactionAuthor: transactionAuthor) { context in
            let item = KlakTaskLogItem(context: context)
            
            item.itemId = logItem.id
            item.message = messageText
            item.createdBy = logItem.createdBy
            item.pendingDueDate = logItem.pendingDueDate
            item.timestamp = logItem.timestamp
            item.taskStatusRawValue = logItem.status.rawValue
            
            let request: NSFetchRequest<KlakTask> = KlakTask.fetchRequest()
            request.predicate = NSPredicate(format: "%K = %@", #keyPath(KlakTask.taskId), logItem.task.id)
            
            if let results = try? context.fetch(request),
               let taskItem = results.first {
                taskItem.addToLogItems(item)
                item.task = taskItem
            }
            
        }
    }
}
