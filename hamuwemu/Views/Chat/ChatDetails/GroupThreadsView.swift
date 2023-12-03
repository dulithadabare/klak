//
//  GroupThreadsView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-24.
//

import SwiftUI

struct GroupThreadsView: View {
    @ObservedObject var model: Model
    @State var showAddThread: Bool = false
    @State var tempThread: ChatThreadModel? = nil
    @State var showTempThread: Bool = false

    var body: some View {
        List {
            if let tempThread = tempThread {
                NavigationLink(destination: LazyDestination{
                    ThreadMessagesView(chat: model.chat, thread: tempThread )
                        .onDisappear {
                            //this is slower than onAppear on parent
                            // tempGroup = nil
                        }
                    
                }, isActive: $showTempThread) { EmptyView() }
            }
            ForEach(model.items) { item in
                
                NavigationLink(destination: LazyDestination {
                    ThreadMessagesView(chat: model.chat, thread: ChatThreadModel(from: item.thread!))
                }){
                    GroupThreadListItemView(item: item)
//                        VStack{
//                        Text(item.groupId!)
//
//                        }
                    
                }
            }
        }
        .onAppear{
            tempThread = nil
        }
        .navigationTitle(NSLocalizedString("Threads", comment: "title"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
//                NavigationLink(destination: LazyDestination{
//                    GroupThreadsView(model: GroupThreadsView.Model(groupId: model.groupId))
//                }) { Text("Add Thread") }
                Button(action: {
                    showAddThread = true
                }) {
                    Text("Add Thread")
                }
            }
        }
        .sheet(isPresented: $showAddThread, content: {
            AddGroupThreadView(chat: model.chat, tempThread: $tempThread, showTempThread: $showTempThread)
        })
    }
}

struct GroupThreadsView_Previews: PreviewProvider {
    static var previews: some View {
        GroupThreadsView(model: GroupThreadsView.Model(inMemory: true, chat: ChatGroup.preview))
    }
}

import Combine
import CoreData

extension GroupThreadsView {
    class Model: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
        @Published var items: [HwThreadListItem] = []
        
        let groupId: String
        let chat: ChatGroup
        
        private var managedObjectContext: NSManagedObjectContext
        private var persistenceController: PersistenceController
        private var fetchedResultsController: NSFetchedResultsController<HwThreadListItem>!
        private var authenticationService: AuthenticationService
        private var cancellables: Set<AnyCancellable> = []
        
        init(inMemory: Bool = false, chat: ChatGroup) {
            self.groupId = chat.group
            self.chat = chat
            if inMemory {
                persistenceController = PersistenceController.preview
                managedObjectContext = PersistenceController.preview.container.viewContext
                authenticationService = AuthenticationService.preview
            } else {
                persistenceController = PersistenceController.shared
                managedObjectContext = PersistenceController.shared.container.viewContext
                authenticationService = AuthenticationService.shared
            }
            
            super.init()
            fetchItems()
        }
        
        func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
            switch type {
            case .insert:
                if let item = anObject as? HwThreadListItem, let index = newIndexPath?.row {
                    self.items.insert(item, at: index)
//                    print("Inserted new message \(item.phoneNumber!)")
                }
            case .delete:
                if let item = anObject as? HwThreadListItem {
//                    print("Deleted new message \(item.phoneNumber!)")
                }
            case .move:
                break
            case .update:
                if let item = anObject as? HwThreadListItem {
//                    print("Updated message \(item.phoneNumber!)")
                }
            @unknown default:
                break
            }
        }
        
        func fetchItems(){
            if fetchedResultsController == nil {
                let request: NSFetchRequest<HwThreadListItem> = HwThreadListItem.fetchRequest()
                request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwThreadListItem.groupId), self.groupId)
                request.sortDescriptors = [
                    NSSortDescriptor(
                        keyPath: \HwThreadListItem.lastMessageDate,
                        ascending: false)]
                
                fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
                fetchedResultsController.delegate = self
            }
        
            
            
            do {
                try fetchedResultsController.performFetch()
                self.items = fetchedResultsController.fetchedObjects ?? []
            } catch {
                fatalError("Failed to fetch entities: \(error)")
            }
            
            
//            persistenceController.container.performBackgroundTask { context in
//                let fetchRequest: NSFetchRequest<HwThreadListItem> = HwThreadListItem.fetchRequest()
//                fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwThreadListItem.groupId), self.groupId)
//                fetchRequest.sortDescriptors = [
//                    NSSortDescriptor(
//                        keyPath: \HwThreadListItem.lastMessageDate,
//                        ascending: false)]
//                if let results = try? context.fetch(fetchRequest) {
//                    DispatchQueue.main.async {
////                        self.members = members
//                        self.items = results
//                    }
//                }
//            }
        }
    }
}
