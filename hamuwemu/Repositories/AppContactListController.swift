//
//  AppContactListController.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-10.
//

import Foundation
import Combine
import CoreData

class AppContactListController: NSObject, ObservableObject {
    @Published var items: [HwAppContact] = []
    private var fetchedResultsController: NSFetchedResultsController<HwAppContact>!
    
    init(managedObjectContext: NSManagedObjectContext) {
        super.init()
        fetch(managedObjectContext: managedObjectContext)
    }
    
    func fetch(managedObjectContext: NSManagedObjectContext) {
        let request: NSFetchRequest<HwAppContact> = HwAppContact.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(
                keyPath: \HwAppContact.phoneNumber,
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

extension AppContactListController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        items = fetchedResultsController.fetchedObjects ?? []
    }
}
