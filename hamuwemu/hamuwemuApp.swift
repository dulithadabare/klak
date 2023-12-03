//
//  hamuwemuApp.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 9/23/21.
//

import SwiftUI
import Firebase
import Sentry

@main
struct hamuwemuApp: App {
    //    @StateObject var authStore = AuthStore()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) var scenePhase
    let persistenceController = PersistenceController.shared
    //    let authenticationService = AuthenticationService.shared
    
    init() {
        Team.load()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
//            AlignementGuideToolContentView()
            //                .environmentObject(authStore)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(AuthenticationService.shared)
                .environmentObject(delegate.notificationDelegate)
                .onAppear {
                    print(FileManager.documentURL ?? "")
                }
        }
        .onChange(of: scenePhase) { [scenePhase] newPhase in
            persistenceController.save()
            print("debug", scenePhase, newPhase) // will print two values - old, then new
            if newPhase == .active {
                print("Active")
                UIApplication.shared.applicationIconBadgeNumber = 0
                UserDefaults.extensions.badge = 0
            } else if newPhase == .inactive {
                print("Inactive")
                if scenePhase == .background {
                    AuthenticationService.shared.account.connect()
                }
            } else if newPhase == .background {
                print("Background")
                AuthenticationService.shared.account.disconnect()
            }
            
            
        }
    }
}

struct Team: Codable {
    let names: [String]
    let count: Int
    
    static func save() {
        do {
            // 1
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            // 2
            let data = try encoder.encode(teamData)
            // 3
            if let url = FileManager.documentURL?
                .appendingPathComponent("TeamData") {
                try data.write(to: url)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    static func load() {
        // 1
        if let url = FileManager.documentURL?
            .appendingPathComponent("TeamData") {
            do {
                // 2
                let data = try Data(contentsOf: url)
                // 3
                let decoder = JSONDecoder()
                // 4
                let team = try decoder.decode(Team.self, from: data)
                print(team)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    
}

let teamData = Team(
    names: [
        "Richard", "Libranner", "Caroline", "Audrey", "Manda"
    ], count: 5)


