//
//  GroupRecentThreadNotificationsController.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-05.
//

import Foundation
import Combine
import CoreData

class GroupRecentThreadNotificationsController: NSObject, ObservableObject {
    @Published var count: Int16 = 0
    var threadId: String
    private let onObjectsChange = CurrentValueSubject<Int16, Never>(0)
    var objects: AnyPublisher<Int16, Never> { onObjectsChange.eraseToAnyPublisher() }
    
    private var fetchedResultsController: NSFetchedResultsController<HwThreadListItem>!
    private var authenticationService: AuthenticationService
    private var managedObjectContext: NSManagedObjectContext
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(threadId: String, authenticationService: AuthenticationService, managedObjectContext: NSManagedObjectContext) {
        self.threadId = threadId
        self.authenticationService = authenticationService
        self.managedObjectContext = managedObjectContext
        super.init()
        fetch(threadId: threadId, managedObjectContext: managedObjectContext)
    }
    
    func fetch(threadId: String, managedObjectContext: NSManagedObjectContext) {
        let request: NSFetchRequest<HwThreadListItem> = HwThreadListItem.fetchRequest()
        request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwThreadListItem.threadId), threadId)
        request.sortDescriptors = [
            NSSortDescriptor(
                keyPath: \HwThreadListItem.lastMessageDate,
                ascending: false)]
        request.fetchLimit = 1
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            count = fetchedResultsController.fetchedObjects?.first?.unreadCount ?? 0
        } catch {
            fatalError("Failed to fetch entities: \(error)")
        }
    }
    
    func updateThreadId(threadId: String) {
        print("ChannelMessagesView: recent notification changed thread")
        count = 0
        fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwThreadListItem.threadId), threadId)
        do {
            try fetchedResultsController.performFetch()
            count = fetchedResultsController.fetchedObjects?.first?.unreadCount ?? 0
        } catch {
            fatalError("Failed to fetch entities: \(error)")
        }
    }
}

extension GroupRecentThreadNotificationsController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("ChannelMessagesView: recent notification updated")
        count = fetchedResultsController.fetchedObjects?.first?.unreadCount ?? 0
    }
}
