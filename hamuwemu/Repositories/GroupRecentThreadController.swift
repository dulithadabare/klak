//
//  GroupRecentThreadController.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-05.
//

import Foundation
import Combine
import CoreData

class GroupRecentThreadController: NSObject, ObservableObject {
    @Published var thread: ChatThreadModel? = nil
    @Published var count: Int16 = 0
    var groupId: String
    private let onObjectsChange = CurrentValueSubject<Int16, Never>(0)
    var objects: AnyPublisher<Int16, Never> { onObjectsChange.eraseToAnyPublisher() }
    
    private var fetchedResultsController: NSFetchedResultsController<HwThreadListItem>!
    private var authenticationService: AuthenticationService
    private var notificationsController: GroupRecentThreadNotificationsController?
    private var managedObjectContext: NSManagedObjectContext
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(groupId: String, authenticationService: AuthenticationService, managedObjectContext: NSManagedObjectContext) {
        self.groupId = groupId
        self.authenticationService = authenticationService
        self.managedObjectContext = managedObjectContext
        super.init()
        fetch(groupId: groupId, managedObjectContext: managedObjectContext)
    }
    
    func fetch(groupId: String, managedObjectContext: NSManagedObjectContext) {
        let request: NSFetchRequest<HwThreadListItem> = HwThreadListItem.fetchRequest()
        request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwThreadListItem.groupId), groupId)
        request.sortDescriptors = [
            NSSortDescriptor(
                keyPath: \HwThreadListItem.lastMessageDate,
                ascending: false)]
        request.fetchLimit = 1
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            if let hwThread = fetchedResultsController.fetchedObjects?.first?.thread {
                thread = ChatThreadModel(from: hwThread)
                count = fetchedResultsController.fetchedObjects?.first?.unreadCount ?? 0
            }
           
//            if let hwThread = fetchedResultsController.fetchedObjects?.first,
//               let threadId = hwThread.threadId {
//                thread = ChatThreadModel(from: hwThread)
//                notificationsController = GroupRecentThreadNotificationsController(threadId: threadId, authenticationService: authenticationService, managedObjectContext: managedObjectContext)
//                notificationsController?.$count.assign(to: &$count)
//            }
            
        } catch {
            fatalError("Failed to fetch entities: \(error)")
        }
    }
    
    func addSubscribers() {
        
    }
}

extension GroupRecentThreadController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let hwThread = fetchedResultsController.fetchedObjects?.first?.thread {
            thread = ChatThreadModel(from: hwThread)
            count = fetchedResultsController.fetchedObjects?.first?.unreadCount ?? 0
        }
    }
    
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
//        switch type {
//        case .insert:
//            print("ChannelMessagesView: recent inserted")
//            handleChange(anObject)
//            break
//        case .delete:
//            break
//        case .move:
//            print("ChannelMessagesView: recent moved")
//            handleChange(anObject)
//            break
//        case .update:
//            print("ChannelMessagesView: recent updated")
//            handleChange(anObject)
//        @unknown default:
//            break
//        }
//    }
//
//    private func handleChange(_ anObject: Any) {
//        if let item = anObject as? HwChatThread, let threadId = item.threadId {
//            thread = ChatThreadModel(from: item)
//            // For new chats
//            if notificationsController == nil {
//                notificationsController = GroupRecentThreadNotificationsController(threadId: threadId, authenticationService: authenticationService, managedObjectContext: managedObjectContext)
//                notificationsController?.$count.assign(to: &$count)
//            } else {
//                notificationsController?.updateThreadId(threadId: threadId)
//            }
//        }
//    }
}

