//
//  GroupChannelNotificationController.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-05.
//

import Foundation
import Combine
import CoreData

class GroupChannelNotificationController: NSObject, ObservableObject {
    @Published var count: Int16 = 0
    var channelId: String
    private let onObjectsChange = CurrentValueSubject<Int16, Never>(0)
    var objects: AnyPublisher<Int16, Never> { onObjectsChange.eraseToAnyPublisher() }
    
    private var fetchedResultsController: NSFetchedResultsController<HwChatMessage>!
    private var authenticationService: AuthenticationService
    private var managedObjectContext: NSManagedObjectContext
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(channelId: String, authenticationService: AuthenticationService, managedObjectContext: NSManagedObjectContext) {
        self.channelId = channelId
        self.authenticationService = authenticationService
        self.managedObjectContext = managedObjectContext
        super.init()
        fetch(channelId: channelId, managedObjectContext: managedObjectContext)
    }
    
    func fetch(channelId: String, managedObjectContext: NSManagedObjectContext) {
        let request: NSFetchRequest<HwChatMessage> = HwChatMessage.fetchRequest()
        request.predicate = NSPredicate(format: "%K = %@ AND %K != %@ AND %K = FALSE", #keyPath(HwChatMessage.channelUid), channelId, #keyPath(HwChatMessage.author), authenticationService.account.userId!, #keyPath(HwChatMessage.isSystemMessage))
        request.sortDescriptors = [
            NSSortDescriptor(
                keyPath: \HwChatMessage.timestamp,
                ascending: false)]
        request.fetchLimit = 1
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to fetch entities: \(error)")
        }
    }
    
    func resetCount() {
        count = 0
    }
}

extension GroupChannelNotificationController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let _ = anObject as? HwChatMessage {
                count += 1
                print("ThreadMessagesView: channel notification updated \(count)")
            }
            break
        case .delete:
            break
        case .move:
            break
        case .update:
           break
        @unknown default:
            break
        }
    }
}
