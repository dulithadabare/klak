//
//  Environment.swift
//  Payload Modification
//
//  Created by Dulitha Dabare on 2022-04-13.
//

import Foundation
import Firebase
import FirebaseAuth

class Environment {
    var messageHandler: MessageHandler!
    var messageFetcher = MessageFetcher()
    var persistentController: PersistenceController!
    var auth: Auth!
    
    func setupIfNecessary(){
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        if auth == nil {
            auth = Auth.auth()
            do {
                try auth!.useUserAccessGroup("group.com.dabare.hamuwemu")
            } catch {
                print("Error while initializing Auth \(String(describing: error))")
            }
        }
        
        if messageHandler == nil, let userId = auth?.currentUser?.uid {
            messageHandler = MessageHandler(userId: userId, transactionAuthor: "nse")
        }
        
        if persistentController == nil {
            persistentController = .shared
        }
        
    }
    
    private static var mainAppDarwinQueue: DispatchQueue { .global(qos: .userInitiated) }
    
    func askMainAppToHandleReceipt(handledCallback: @escaping (_ mainAppHandledReceipt: Bool) -> Void) {
        Self.mainAppDarwinQueue.async {
            // We track whether we've ever handled the call back to ensure
            // we only notify the caller once and avoid any races that may
            // occur between the notification observer and the dispatch
            // after block.
            let hasCalledBack = AtomicBool(false)

//            if DebugFlags.internalLogging {
//                Logger.info("Requesting main app to handle incoming message.")
//            }

            // Listen for an indication that the main app is going to handle
            // this notification. If the main app is active we don't want to
            // process any messages here.
            let token = DarwinNotificationCenter.addObserver(forName: DarwinNotificationName.mainAppHandledNotification.cString, queue: Self.mainAppDarwinQueue) { token in
                guard hasCalledBack.tryToSetFlag() else { return }

                if DarwinNotificationCenter.isValidObserver(token) {
                    DarwinNotificationCenter.removeObserver(token)
                }

//                if DebugFlags.internalLogging {
//                    Logger.info("Main app ack'd.")
//                }

                handledCallback(true)
            }

            // Notify the main app that we received new content to process.
            // If it's running, it will notify us so we can bail out.
            DarwinNotificationCenter.postNotificationName(DarwinNotificationName.nseDidReceiveNotification.cString)

            // The main app should notify us nearly instantaneously if it's
            // going to process this notification so we only wait a fraction
            // of a second to hear back from it.
            Self.mainAppDarwinQueue.asyncAfter(deadline: DispatchTime.now() + 0.010) {
                guard hasCalledBack.tryToSetFlag() else { return }

                if DarwinNotificationCenter.isValidObserver(token) {
                    DarwinNotificationCenter.removeObserver(token)
                }

//                if DebugFlags.internalLogging {
//                    Logger.info("Did timeout.")
//                }

                // If we haven't called back yet and removed the observer token,
                // the main app is not running and will not handle receipt of this
                // notification.
                handledCallback(false)
            }
        }
    }
}
