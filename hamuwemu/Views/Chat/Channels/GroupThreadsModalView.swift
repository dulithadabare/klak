//
//  GroupThreadsModalView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-03.
//

import SwiftUI

struct GroupThreadsModalView: View {
    @Environment(\.isPresented) private var isPresented
    var inMemory: Bool = false
    var chat: ChatGroup
    @Binding var tempThread: ChatThreadModel?
    @Binding var showTempThread: Bool
    var dismiss: () -> Void
    
    @State private var initialized: Bool = false
    @StateObject private var model = Model()
    
    var body: some View {
        VStack {
            if model.items.isEmpty {
                Text("Tap the \(Image(systemName: "plus.bubble")) icon to start a new topic.")
                    .multilineTextAlignment(.center)
            } else {
                ForEach(model.items) { item in
                    Button {
                        dismiss()
                        tempThread = ChatThreadModel(from: item.thread!)
                        showTempThread = true
                    } label: {
                        GroupThreadListItemView(item: item)
                    }

                    
        //                NavigationLink(destination: LazyDestination {
        //                    ThreadMessagesView(chat: chat, thread: ChatThreadModel(from: item.thread!))
        //                }){
        //                    GroupThreadListItemView(item: item)
        //                }
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(uiColor: UIColor.secondarySystemGroupedBackground)))
        .padding()
        .onReceive(NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange).receive(on: RunLoop.main), perform: { _ in
//            model.load()
        })
        .onAppear(perform: {
            guard !initialized else {
                return
            }
            
            defer {
                initialized = true
            }
            
            model.performOnce(inMemory: inMemory, chat: chat)
        })
//        .toolbar {
//            ToolbarItem(placement: .principal) {
//                Text("Threads")
//            }
//        }
    }
}

struct GroupThreadsModalView_Previews: PreviewProvider {
    static var previews: some View {
        GroupThreadsModalView(chat: ChatGroup.preview, tempThread: .constant(nil), showTempThread: .constant(false), dismiss: {})
            .environmentObject(AuthenticationService.preview)
            .environmentObject(ContactRepository.preview)
    }
}

import CoreData
import Combine

extension GroupThreadsModalView {
    class Model: ObservableObject {
        @Published var items: [HwThreadListItem] = []
        
        var chat: ChatGroup!
        
        private var managedObjectContext: NSManagedObjectContext!
        private var persistenceController: PersistenceController!
        private var groupThreadsController: GroupThreadsController!
        
        private var cancellables: Set<AnyCancellable> = []
        
        init() {
            
        }
        
        func performOnce(inMemory: Bool = false, chat: ChatGroup) {
            self.chat = chat
            if inMemory {
                persistenceController = PersistenceController.preview
                managedObjectContext = PersistenceController.preview.container.viewContext
            } else {
                persistenceController = PersistenceController.shared
                managedObjectContext = PersistenceController.shared.container.viewContext
            }
            
            groupThreadsController = GroupThreadsController(groupId: chat.group, managedObjectContext: managedObjectContext)
            addSubscribers()
        }
        
        func addSubscribers() {
            groupThreadsController.$items.assign(to: &$items)
        }
        
        func load() {
            print("ChannelMessagesView: load threads")
            
            let request: NSFetchRequest<HwThreadListItem> = HwThreadListItem.fetchRequest()
            request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwThreadListItem.groupId), chat.group)
            request.sortDescriptors = [
                NSSortDescriptor(
                    keyPath: \HwThreadListItem.lastMessageDate,
                    ascending: false)]
            if let results = try? managedObjectContext.fetch(request) {
                DispatchQueue.main.async {
                    self.items = results
                }
            }
        }
    }
}
