//
//  GroupThreadNotificationController.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-04.
//

import Foundation
import Combine
import CoreData

class GroupThreadsNotificationController: NSObject, ObservableObject {
    @Published var count: Int16 = 0
    var groupId: String
    private let onObjectsChange = CurrentValueSubject<Int16, Never>(0)
    var objects: AnyPublisher<Int16, Never> { onObjectsChange.eraseToAnyPublisher() }
    
    private var fetchedResultsController: NSFetchedResultsController<HwChatListItem>!
    private var managedObjectContext: NSManagedObjectContext
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(groupId: String, managedObjectContext: NSManagedObjectContext) {
        self.groupId = groupId
        self.managedObjectContext = managedObjectContext
        super.init()
        fetch(groupId: groupId, managedObjectContext: managedObjectContext)
    }
    
    func fetch(groupId: String, managedObjectContext: NSManagedObjectContext) {
        let request: NSFetchRequest<HwChatListItem> = HwChatListItem.fetchRequest()
        request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatListItem.groupId), groupId)
        request.sortDescriptors = [
            NSSortDescriptor(
                keyPath: \HwChatListItem.lastMessageDate,
                ascending: false)]
        request.fetchLimit = 1
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            count = fetchedResultsController.fetchedObjects?.first?.threadUnreadCount ?? 0
        } catch {
            fatalError("Failed to fetch entities: \(error)")
        }
    }
    
    func fetchCount() {
        let keypathExp1 = NSExpression(forKeyPath: #keyPath(HwThreadListItem.unreadCount))
        let expression = NSExpression(forFunction: "sum:", arguments: [keypathExp1])
        let sumDesc = NSExpressionDescription()
        sumDesc.expression = expression
        sumDesc.name = "sum"
        sumDesc.expressionResultType = .integer32AttributeType
        
        let request = NSFetchRequest<NSDictionary>(entityName: "HwThreadListItem")
        request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwThreadListItem.groupId), groupId)
        request.returnsObjectsAsFaults = false
        request.propertiesToFetch = [sumDesc]
        request.resultType = .dictionaryResultType
        
        do {
            let results = try managedObjectContext.fetch(request)
            if let dict = results.first {
                count = dict["sum"] as? Int16 ?? 0
            }
            
        } catch {
            print("Error fetching count \(error)")
        }
        
    }
}

extension GroupThreadsNotificationController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let item = controller.fetchedObjects?.first as? HwChatListItem {
            print("ChannelMessagesView: notification updated \(item.threadUnreadCount)")
            count = item.threadUnreadCount
        }

    }
    
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
//        switch type {
//        case .insert:
//            break
//        case .delete:
//            break
//        case .move:
//            break
//        case .update:
//            if let item = anObject as? HwChatListItem {
//                print("ChannelMessagesView: notification updated \(item.threadUnreadCount)")
//                count = item.threadUnreadCount
//            }
//        @unknown default:
//            break
//        }
//    }
}
