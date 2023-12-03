//
//  ChatIdListController.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-10.
//

import Foundation
import Combine
import CoreData

class ChatIdListController: NSObject, ObservableObject {
    @Published var items: [HwChatId] = []
    private var fetchedResultsController: NSFetchedResultsController<HwChatId>!
    
    init(managedObjectContext: NSManagedObjectContext) {
        super.init()
        fetch(managedObjectContext: managedObjectContext)
    }
    
    func fetch(managedObjectContext: NSManagedObjectContext) {
        let request: NSFetchRequest<HwChatId> = HwChatId.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(
                keyPath: \HwChatId.phoneNumber,
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

extension ChatIdListController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        items = fetchedResultsController.fetchedObjects ?? []
    }
}
