//
//  EncryptionService.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-31.
//

import Foundation
import CoreData
import CryptoKit

public class EncryptionService {
    static let shared = EncryptionService()
    
    static let preview: EncryptionService = {
        let service = EncryptionService()
        return service
    }()
    
    var keyMap: [String: Data] = [:]
    var managedObjectContext: NSManagedObjectContext
    
    private init(){
        managedObjectContext = PersistenceController.shared.container.viewContext
    }
    
    func loadKeys() {
        fetchPublicKeys()
    }
    
    func encrypt(data: Data, for receiver: String, inGroup salt: String, userId: String) -> Data {
        guard let privateKey = try? KeychainWrapper.shared.getGenericPasswordFor(account: userId, service: .encryption),
              let receiverPublicKeyData = getPublicKey(for: receiver),
              let receiverPublicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: receiverPublicKeyData),
              let sharedSecret = try? privateKey.sharedSecretFromKeyAgreement(with: receiverPublicKey),
              let protocolSalt = salt.data(using: .utf8)
        else {
            return data
        }
        
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: protocolSalt, sharedInfo: Data(), outputByteCount: 32)
        let sealedBoxData = try! ChaChaPoly.seal(data, using: symmetricKey).combined

        return sealedBoxData
    }
    
    func encrypt(content: String, for receiver: String, inGroup salt: String, userId: String) -> String {
        guard let privateKey = try? KeychainWrapper.shared.getGenericPasswordFor(account: userId, service: .encryption),
              let receiverPublicKeyData = getPublicKey(for: receiver),
              let receiverPublicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: receiverPublicKeyData),
              let sharedSecret = try? privateKey.sharedSecretFromKeyAgreement(with: receiverPublicKey),
              let protocolSalt = salt.data(using: .utf8),
              let data = content.data(using: .utf8)
        else {
            return content
        }
        
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: protocolSalt, sharedInfo: Data(), outputByteCount: 32)
        let sealedBoxData = try! ChaChaPoly.seal(data, using: symmetricKey).combined

        return sealedBoxData.base64EncodedString()
    }
    
    func decrypt(data: Data, from sender: String, senderPublicKey: String?, inGroup salt: String, userId: String) -> Data {
        var senderPublicKeyData: Data?
        if let senderPublicKey = senderPublicKey {
            senderPublicKeyData = Data(base64Encoded: senderPublicKey)
        } else {
            senderPublicKeyData = getPublicKey(for: sender)
        }
        
        guard let privateKey = try? KeychainWrapper.shared.getGenericPasswordFor(account: userId, service: .encryption),
              let senderPublicKeyData = senderPublicKeyData,
              let senderPublicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: senderPublicKeyData),
              let sharedSecret = try? privateKey.sharedSecretFromKeyAgreement(with: senderPublicKey),
              let protocolSalt = salt.data(using: .utf8)
        else {
            return data
        }
        
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: protocolSalt, sharedInfo: Data(), outputByteCount: 32)
        if let sealedBox = try? ChaChaPoly.SealedBox(combined: data),
           let decryptedData = try? ChaChaPoly.open(sealedBox, using: symmetricKey) {
            
            return decryptedData
        }
        
        return data
    }
    
    func decrypt(content: String, from sender: String, senderPublicKey: String?, inGroup salt: String, userId: String) -> String {
        var senderPublicKeyData: Data?
        if let senderPublicKey = senderPublicKey {
            senderPublicKeyData = Data(base64Encoded: senderPublicKey)
        } else {
            senderPublicKeyData = getPublicKey(for: sender)
        }
        
        guard let privateKey = try? KeychainWrapper.shared.getGenericPasswordFor(account: userId, service: .encryption),
              let senderPublicKeyData = senderPublicKeyData,
              let senderPublicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: senderPublicKeyData),
              let sharedSecret = try? privateKey.sharedSecretFromKeyAgreement(with: senderPublicKey),
              let protocolSalt = salt.data(using: .utf8),
              let sealedBoxData = Data(base64Encoded: content)
        else {
            return content
        }
        
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: protocolSalt, sharedInfo: Data(), outputByteCount: 32)
        if let sealedBox = try? ChaChaPoly.SealedBox(combined: sealedBoxData),
           let decryptedData = try? ChaChaPoly.open(sealedBox, using: symmetricKey) {
            
            return String(data: decryptedData, encoding: .utf8)!
        }
        
        return content
    }
    
    func getPublicKey(for phoneNumber: String) -> Data? {
        return keyMap[phoneNumber] ?? fetchPublicKey(for: phoneNumber)
    }
    
    private func fetchPublicKey(for phoneNumber: String) -> Data? {
        let fetchRequest: NSFetchRequest<HwAppContact> = HwAppContact.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwAppContact.phoneNumber), phoneNumber)
        if let results = try? managedObjectContext.fetch(fetchRequest),
           let item = results.first,
           let publicKeyData = item.publicKey{
            keyMap[phoneNumber] = publicKeyData
            return publicKeyData
        }
        
        return nil
    }
    
    private func fetchPublicKeys(){
        var asyncFetchRequest: NSAsynchronousFetchRequest<HwAppContact>?
        
        let request: NSFetchRequest<HwAppContact> = HwAppContact.fetchRequest()
        
        asyncFetchRequest = NSAsynchronousFetchRequest<HwAppContact>(
            fetchRequest: request) {
                [weak self] (result: NSAsynchronousFetchResult) in
                
                guard let strongSelf = self, let hwItems = result.finalResult else {
                    return
                }
                
                for hwItem in hwItems {
                    if let phoneNumber = hwItem.phoneNumber,
                       let publicKey = hwItem.publicKey {
                        strongSelf.keyMap[phoneNumber] = publicKey
                    }
                }
            }
        
        do {
            guard let asyncFetchRequest = asyncFetchRequest else {
                return
            }
            try managedObjectContext.execute(asyncFetchRequest)
        } catch let error as NSError {
            print("EncryptionService: Could not perform fetchPublicKeys \(error), \(error.userInfo)")
        }
    }
}
