//
//  KeychainServices.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-30.
//

import Foundation
import CryptoKit
import MapKit

struct KeychainWrapperError: Error {
    var message: String?
    var type: KeychainErrorType
    
    enum KeychainErrorType {
        case badData
        case servicesError
        case itemNotFound
        case unableToConvertToString
    }
    
    init(status: OSStatus, type: KeychainErrorType) {
        self.type = type
        if let errorMessage = SecCopyErrorMessageString(status, nil) {
            self.message = String(errorMessage)
        } else {
            self.message = "Status Code: \(status)"
        }
    }
    
    init(type: KeychainErrorType) {
        self.type = type
    }
    
    init(message: String, type: KeychainErrorType) {
        self.message = message
        self.type = type
    }
}

class KeychainWrapper {
    static let shared = KeychainWrapper()
    
    private init(){}
    
    private let accessGroup = "group.com.dabare.hamuwemu"
    func storeGenericPasswordFor(
        account: String,
        service: KeyChainServiceConstants,
        password: Curve25519.KeyAgreement.PrivateKey
    ) throws {
        
        // 1
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service.rawValue,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrAccessGroup as String: accessGroup,
            kSecValueData as String: password.rawRepresentation
        ]
        
        // 1
        let status = SecItemAdd(query as CFDictionary, nil)
        switch status {
            // 2
        case errSecSuccess:
            break
        case errSecDuplicateItem:
            try updateGenericPasswordFor(
                account: account,
                service: service,
                password: password)
            // 3
        default:
            throw KeychainWrapperError(status: status, type: .servicesError)
        }
    }
    
    func getGenericPasswordFor(account: String, service: KeyChainServiceConstants) throws -> Curve25519.KeyAgreement.PrivateKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service.rawValue,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccessGroup as String: accessGroup,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else {
            throw KeychainWrapperError(type: .itemNotFound)
        }
        guard status == errSecSuccess else {
            throw KeychainWrapperError(status: status, type: .servicesError)
        }
        
        guard let data = item as? Data else {  throw KeychainWrapperError(type: .unableToConvertToString) }
        return try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data)
    }
    
    func updateGenericPasswordFor(
        account: String,
        service: KeyChainServiceConstants,
        password: Curve25519.KeyAgreement.PrivateKey
    ) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service.rawValue,
            kSecAttrAccessGroup as String: accessGroup
        ]
        
        // 2
        let attributes: [String: Any] = [
            kSecValueData as String: password.rawRepresentation
        ]
        
        // 3
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard status != errSecItemNotFound else {
            throw KeychainWrapperError(message: "Matching Item Not Found", type: .itemNotFound)
        }
        guard status == errSecSuccess else {
            throw KeychainWrapperError(status: status, type: .servicesError)
        }
    }
    
    func deleteGenericPasswordFor(account: String, service: KeyChainServiceConstants) throws {
        // 1
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service.rawValue,
            kSecAttrAccessGroup as String: accessGroup
        ]
        
        // 2
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainWrapperError(status: status, type: .servicesError)
        }
    }
}
