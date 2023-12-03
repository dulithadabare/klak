//
//  GroupThreadListView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-01-20.
//

import SwiftUI

struct GroupThreadListView: View {
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var contactRepository: ContactRepository
    
    @ObservedObject var model: Model
    
    var body: some View {
        Text("Temp")
//        List{
//            ForEach(model.items) { item in
//                NavigationLink( destination: LazyDestination{ EmptyView() }){
//                    HStack {
//                        VStack(alignment: .leading) {
//            //                            Text(chat.id)
//                            HStack {
//                                Text("Replying to: ")
//                                    .font(.caption)
//                                Text(modifiedAttributedString(from: item.thread!.titleText!, contactRepository: contactRepository, authenticationService: authenticationService).string)
//                                    .lineLimit(1)
//                            }
//                            HStack {
//                                Text("status")
//                                    .font(.footnote)
//                                Text(modifiedAttributedString(from: item.lastMessageText!, contactRepository: contactRepository, authenticationService: authenticationService).string)
//                                    .lineLimit(2)
//                                    .font(.footnote)
//                                    .foregroundColor(Color.gray)
//                            }
//                        }
//                        if item.unreadCount > 0 {
//                            Spacer()
//                            UnreadCountView(count: UInt(item.unreadCount))
//                        }
//
//                    }
//                }
//            }
//        }
    }
}

struct GroupThreadListView_Previews: PreviewProvider {
    static var previews: some View {
        GroupThreadListView(model: GroupThreadListView.Model(inMemory: true, groupId: SampleData.shared.groupId))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AuthenticationService.preview)
            .environmentObject(ContactRepository.preview)
    }
}

import CoreData

extension GroupThreadListView {
    class Model: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
        @Published var items: [HwThreadListItem] = []
        var groupId: String
        private var managedObjectContext: NSManagedObjectContext
        private var persistenceController: PersistenceController
        private var authenticationService: AuthenticationService
        private var fetchedResultsController: NSFetchedResultsController<HwThreadListItem>!
        
        
        init(inMemory: Bool = false, groupId: String){
            self.groupId = groupId
            
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
            
            loadItems()
        }
        
        func loadItems(){
            if fetchedResultsController == nil {
                let request: NSFetchRequest<HwThreadListItem> = HwThreadListItem.fetchRequest()
                request.sortDescriptors = [
                    NSSortDescriptor(
                        keyPath: \HwThreadListItem.lastMessageDate,
                        ascending: false)]
                request.predicate = NSPredicate(format: "%K = %@",#keyPath(HwThreadListItem.groupId), groupId)
                
                fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
                fetchedResultsController.delegate = self
            }
            
            
            do {
                try fetchedResultsController.performFetch()
                items = fetchedResultsController.fetchedObjects ?? []
            } catch {
                print("Fetch failed")
            }
        }
        
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            print("Did Change Content")
            items = fetchedResultsController.fetchedObjects ?? []
        }
    }
}
