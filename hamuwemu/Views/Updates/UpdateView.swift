//
//  StatusView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 9/28/21.
//

import SwiftUI

import Combine
import FirebaseDatabase

enum UpdateListState {
    case mentions, links, images
}

struct UpdateView: View {
    @StateObject var model = Model()
    @EnvironmentObject var contactRepository: ContactRepository

    var body: some View {
        NavigationView {
            VStack {
                Picker(selection: $model.selectedList, label: Text("")) {
                    //                    Image(systemName: "square.grid.2x2.fill")
                    //                      .tag(UpdateListState.all)
                    //                    Image(systemName: "link")
                    //                      .tag(UpdateListState.links)
                    //                    Image(systemName: "photo.fill")
                    //                        .tag(UpdateListState.images)
                    
                    Text("@")
                        .tag(UpdateListState.mentions)
                    Text("<>")
                        .tag(UpdateListState.links)
                    Text(":)")
                        .tag(UpdateListState.images)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
                UpdatesListView(updateModel: model)
            }
            .navigationTitle("Updates")
            .navigationBarTitleDisplayMode(.large)
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct StatusView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateView()
            .environmentObject(StatusStore())
    }
}

//struct ListPicker: View {
//    @Binding var selectedList: UpdateListState
//    var body: some View {
//
//    }
//}

extension UpdateView {
    class Model: ObservableObject {
        @Published var selectedList = UpdateListState.mentions
        @Published var messages: [Update] = []
        @Published var channels = [String: Update]()
        @Published var showReplyView = false
        @Published var selectedUpdate: Update?
        @Published var alertMessage = ""
        @Published var alert = false
        private var ref = Database.root
        private var refHandle: DatabaseHandle?
        private let path = "updates"
        private var authenticationService: AuthenticationService = .shared
        private var dataInitialized = false
        private var cancellables: Set<AnyCancellable> = []
        
        init() {
            addSubscribers()
//            addListener()
            #if DEBUG
            createDevData()
            #endif
        }
        
        deinit {
            ref.removeAllObservers()
        }
        
        func load() {
            // because onAppear gets called multiple times. Other solution is to
            // inject the VM as a ObservableObject from the previous view
            cancellables = []
            
            
        }
        
        // MARK: - Database Listeners
//        func addListener() {
//            guard let userId = authenticationService.user?.uid
//            else {
//                return
//            }
//            refHandle = ref.child(DatabaseHelper.pathUserUpdates).child(userId).observe( .value, with: { snapshot in
//                var chats = [String: Update]()
//                for child in snapshot.children {
//                    let snap = child as! DataSnapshot
//                    guard let value = snap.value as? [String: Any] else { continue }
//                    if let chat  = Update(dict: value) {
//                        chats[chat.id] = chat
//                    }
//                }
//
//                DispatchQueue.main.async {
//                    self.channels = chats
//                }
//            })
//        }
        
        func addSubscribers() {
           $channels
                .map({ (dict) -> [Update] in
                    return Array(dict.values).sorted(by: {  $0.timestamp > $1.timestamp })
                })
                .assign(to: &$messages)
        }
    }
}

extension NSMutableAttributedString {

    func apply(link: String, subString: String)  {
        if let range = self.string.range(of: subString) {
            self.apply(link: link, onRange: NSRange(range, in: self.string))
        }
    }
    private func apply(link: String, onRange: NSRange) {
        self.addAttributes([NSAttributedString.Key.link: link], range: onRange)
    }

}
