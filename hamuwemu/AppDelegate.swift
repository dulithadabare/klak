//
//  AppDelegate.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-23.
//

import SwiftUI
import Firebase
import Sentry
import FirebaseMessaging
import CCHDarwinNotificationCenter
import Amplify
import AWSS3StoragePlugin
import AWSCognitoAuthPlugin

public let categoryIdentifier = "AcceptOrReject"

public enum ActionIdentifier: String {
  case accept, reject
}


class AppDelegate: NSObject, UIApplicationDelegate {
    let notificationDelegate = NotificationDelegate.shared

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = notificationDelegate
        
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin())
            try Amplify.configure()
            print("Amplify configured with storage plugin")
        } catch {
            print("Failed to initialize Amplify with \(error)")
        }
        
//        UITableView.appearance().keyboardDismissMode = .onDrag
        
        print("HamuWemu application is starting up. ApplicationDelegate didFinishLaunchingWithOptions.")
//        let center = UNUserNotificationCenter.current()
//        center.requestAuthorization(options: [.badge, .sound, .alert]) {
//            // 1
//            [weak self] granted, _ in
//            
//            // 2
//            guard granted else {
//                return
//            }
//            
//            // 3
//            center.delegate = self?.notificationDelegate
//            
//            DispatchQueue.main.async {
//                application.registerForRemoteNotifications()
//            }
//        }
        
       
        
        SentrySDK.start { options in
            options.dsn = "https://7331154879fe49d485863e2e489e13bd@o1138562.ingest.sentry.io/6192986"
            options.debug = true // Enabled debug when first installing is always helpful
            
            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0
        }
        setupNSEDarwinNotifications()
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            // Pass device token to auth
//            Auth.auth().setAPNSToken(deviceToken, type: .unknown)
            var model = DeviceTokenModel(token: deviceToken)

            // 3
            #if DEBUG
            model.debug.toggle()
            print(model)
            #endif
            let token = deviceToken.reduce("") { $0 + String(format: "%02x", $1) }
            print("device Token ", token)
            UserDefaults.standard.set(token, forKey: "apnsDeviceToken")
            registerCustomActions()
        }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error) {
            print(error)
        }

    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print(" ApplicationDelegate didReceiveRemoteNotification. \(userInfo)")
//        if Auth.auth().canHandleNotification(userInfo) {
//            completionHandler(.noData)
//            return
//          }
        //        FirebaseApp.configure()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//        if Auth.auth().canHandle(url) {
//            return true
//          }
        
        return false
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
    }
    
    private func registerCustomActions() {
      let accept = UNNotificationAction(
        identifier: ActionIdentifier.accept.rawValue,
        title: "Accept")

      let reject = UNNotificationAction(
        identifier: ActionIdentifier.reject.rawValue,
        title: "Reject")

      let category = UNNotificationCategory(
        identifier: categoryIdentifier,
        actions: [accept, reject],
        intentIdentifiers: [])

      UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    private func setupNSEDarwinNotifications() {
        DarwinNotificationCenter.postNotificationName(DarwinNotificationName.mainAppLaunched.cString)
        
        DarwinNotificationCenter.addObserver(forName: DarwinNotificationName.nseDidReceiveNotification.cString, queue: .global()) { _ in
            DarwinNotificationCenter.postNotificationName(DarwinNotificationName.mainAppHandledNotification.cString)
        }
        
//        CCHDarwinNotificationCenter.postNotification(withIdentifier: DarwinNotificationNames.mainAppLaunched)
//        // This turns Darwin notifications into standard NSNotifications
//        CCHDarwinNotificationCenter.startForwardingNotifications(withIdentifier: DarwinNotificationNames.nseDidReceiveNotification, fromEndpoints: .default)
//        // Observe standard NSNotifications
//        NotificationCenter.default.addObserver(self, selector: #selector(nseDidReceiveNotification), name:NSNotification.Name(DarwinNotificationNames.nseDidReceiveNotification), object: nil)
    }
    
    @objc
    func nseDidReceiveNotification() {
        CCHDarwinNotificationCenter.postNotification(withIdentifier: DarwinNotificationNames.mainAppHandledNotification)
    }

}
