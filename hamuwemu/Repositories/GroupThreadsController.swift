//
//  GroupThreadsController.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-03.
//

import Foundation
import Combine
import CoreData

class GroupThreadsController: NSObject, ObservableObject {
    @Published var items: [HwThreadListItem] = []
    private var fetchedResultsController: NSFetchedResultsController<HwThreadListItem>!
    
    init(groupId: String, managedObjectContext: NSManagedObjectContext) {
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
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            items = fetchedResultsController.fetchedObjects ?? []
        } catch {
            fatalError("Failed to fetch entities: \(error)")
        }
    }
}

extension GroupThreadsController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        items = fetchedResultsController.fetchedObjects ?? []
    }
}
