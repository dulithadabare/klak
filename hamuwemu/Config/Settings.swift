//
//  Settings.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/21/21.
//

import SwiftUI

enum Settings {
    static let thumbnailSize =
        CGSize(width: 150, height: 250)
    static let defaultElementSize =
        CGSize(width: 250, height: 180)
    static let borderColor: Color = .blue
    static let borderWidth: CGFloat = 5
}

enum ApiConstants {
#if targetEnvironment(simulator)
  // your simulator code
    static let websocketEndpoint = "ws://localhost:8080/ws"
    static let baseUrlEndpoint =  "http://localhost:8080/"
//    static let websocketEndpoint = "wss://api.hamuwemu.app/ws"
//    static let baseUrlEndpoint =  "https://api.hamuwemu.app/"
#else
  // your real device code
    static let websocketEndpoint = "wss://api.hamuwemu.app/ws"
    static let baseUrlEndpoint =  "https://api.hamuwemu.app/"
#endif
//    static let websocketEndpoint = "wss://api.hamuwemu.app/ws"
//    static let websocketEndpoint = "ws://localhost:8080/ws"
//    static let baseUrlEndpoint =  "https://api.hamuwemu.app/"
//    static let baseUrlEndpoint =  "http://localhost:8080/"
}

enum DarwinNotificationNames {
    static let nseDidReceiveNotification: String = "org.hamuwemu.nseDidReceiveNotification"
    static let mainAppHandledNotification: String = "org.hamuwemu.mainAppHandledNotification"
    static let mainAppLaunched: String = "org.hamuwemu.mainAppLaunched"
}

enum KeyChainServiceConstants: String {
    case encryption
}

