//
//  FileManagerExtensions.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/25/21.
//

import Foundation

extension FileManager {
    static let groupName = "group.com.dabare.hamuwemu"
    
    static var documentURL: URL? {
        return Self.default.urls(
            for: .documentDirectory,
            in: .userDomainMask).first
    }
    
    static var appGroupDirectory: URL? {
        Self.default.containerURL(forSecurityApplicationGroupIdentifier: groupName)
    }
}
