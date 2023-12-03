//
//  UserDefaultsExtensions.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-01-05.
//

import Foundation

extension UserDefaults {
    
    static let messagesKey = "mockMessages"
    
    // MARK: Mock Messages
    
    func setMockMessages(count: Int) {
        set(count, forKey: UserDefaults.messagesKey)
        synchronize()
    }
    
    func mockMessagesCount() -> Int {
        if let value = object(forKey: UserDefaults.messagesKey) as? Int {
            return value
        }
        return 20
    }
    
    static func isFirstLaunch() -> Bool {
        let hasBeenLaunchedBeforeFlag = "hasBeenLaunchedBeforeFlag"
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: hasBeenLaunchedBeforeFlag)
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: hasBeenLaunchedBeforeFlag)
            UserDefaults.standard.synchronize()
        }
        return isFirstLaunch
    }
}

extension UserDefaults {
    // 1
    static let suiteName = "group.com.dabare.hamuwemu"
    static let extensions = UserDefaults(suiteName: suiteName)!
    // 2
    enum Keys {
        static let uid = "uid"
        static let badge = "badge"
        static let defaultChatGroupUid = "defaultChatGroupUid"
    }
    // 3
    var badge: Int {
        get { UserDefaults.extensions.integer(forKey: Keys.badge) }
        set { UserDefaults.extensions.set(newValue, forKey: Keys.badge) }
    }
    
    var uid: String? {
      get { UserDefaults.extensions.string(forKey: Keys.uid) }
      set { UserDefaults.extensions.set(newValue, forKey: Keys.uid) }
    }
    
    var defaultChatGroupUid: String? {
      get { UserDefaults.extensions.string(forKey: Keys.defaultChatGroupUid) }
      set { UserDefaults.extensions.set(newValue, forKey: Keys.defaultChatGroupUid) }
    }
}

