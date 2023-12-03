//
//  ContentView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 9/23/21.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @AppStorage("isSignedIn") var isSignedIn: Bool?
    
    var body: some View {
        Group {
            if isSignedIn ?? false {
                HomeView()
    //            ValidatePhoneView()
    //            SignUpDetailsView()
            } else {
                SignInView()
            }
        }
        .onAppear {
//            UITableView.appearance().keyboardDismissMode = .onDrag
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct HomeView: View {
    @EnvironmentObject var notificationDelegate: NotificationDelegate
    @State private var selectedTab = 1
    @StateObject private var model = AppViewModel()
    
    func askNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.badge, .sound, .alert]) { granted, _ in
            
            // 2
            guard granted else {
                return
            }
            
            // 3
            center.delegate = self.notificationDelegate
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    var body: some View {
        TabView(selection: $notificationDelegate.selectedTab){
//            UpdateView()
//                .tabItem {
//                    VStack {
//                        Image(systemName: "number.circle")
//                        Text(NSLocalizedString("Updates", comment: "title"))
//                    }
//                }
//                .tag(0)
//                .environmentObject(model.chatDataModel)
            TasksView()
                .tabItem { VStack {
                    Image(systemName: "checklist")
                    Text(NSLocalizedString("Tasks", comment: "title"))
                } }
                .tag(1)
            ChatView(model: model.chatViewModel)
                .tabItem { VStack {
                    Image(systemName: "bubble.left")
                    Text(NSLocalizedString("Chats", comment: "title"))
                } }
                .tag(2)
            SettingsView()
                .tabItem { VStack {
                    Image(systemName: "gear")
                    Text(NSLocalizedString("Settings", comment: "title"))
                } }
                .tag(3)
            
        }
        .onAppear(perform: {
            askNotificationPermissions()
        })
        .onChange(of: selectedTab, perform: { (value) in
            print("Tab Changed \(value)")
        })
        //            .environmentObject(StatusStore())
        .environmentObject(model.contactRepository)
        .environmentObject(PersistenceController.shared)
    }
}

class AppViewModel: ObservableObject {
    var contactRepository: ContactRepository
    var chatViewModel: ChatView.Model
    var chatDataModel: ChatDataModel
    
    init(){
        let contactRepository = ContactRepository.shared
        let chatDataModel = ChatDataModel.shared
        self.contactRepository = contactRepository
        self.chatDataModel = chatDataModel
        self.chatViewModel = ChatView.Model(chatDataModel: chatDataModel)
    }
}
