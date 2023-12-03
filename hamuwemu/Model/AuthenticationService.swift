//
//  AuthStore.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/19/21.
//

import Foundation
import SwiftUI
import FirebaseAuth
import PromiseKit
import CryptoKit

public class AuthenticationService: ObservableObject {
    
//    private init() { }
    static let shared = AuthenticationService()
    static let preview: AuthenticationService = {
        let service = AuthenticationService(inMemory: true)
        return service
    }()
    
    var user: User?
    @Published var userId: String?
    var phoneNumber: String?
    var displayName: String?
    
    var account: Account
    private var inMemory: Bool
    private let auth: Auth = Auth.auth()
    
//    @Published var user: User?
    private var authenticationStateHandle: AuthStateDidChangeListenerHandle?
    
    private init(inMemory: Bool = false){
        self.inMemory = inMemory
        if inMemory {
            let userId = UUID().uuidString
            self.userId = userId
            self.phoneNumber = "+16505553434"
            self.displayName = "Dulitha Dabare"
            self.account = Account(inMemory: true, user: nil, userId: userId, phoneNumber: "+16505553434", displayName: "Dulitha Dabare")
        } else {
            let userId = UUID().uuidString
            self.account = Account(inMemory: true, user: nil, userId: userId, phoneNumber: "+16505553434", displayName: "Dulitha Dabare")
            do {
                try auth.useUserAccessGroup("group.com.dabare.hamuwemu")
            } catch {
                fatalError("Error while initializing Auth \(String(describing: error))")
//                print("Error while initializing Auth \(String(describing: error))")
            }
            addListeners()
        }
    }
    
    func saveToken(){
        guard !account.inMemory else {
            return
        }
        
        account.addToken()
    }
    
    func validate(phoneNumber: String, completionHandler: @escaping VerificationResultCallback) {
        PhoneAuthProvider.provider()
            .verifyPhoneNumber(phoneNumber, uiDelegate: nil, completion: completionHandler)
    }
    
    func verify(phoneNumber: String) -> Promise<String> {
        Promise { seal in
            PhoneAuthProvider.provider()
                .verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
                    if let error = error {
                        seal.reject(error)
                        return
                    }

                    if let verificationID = verificationID {
                        seal.fulfill(verificationID)
                        print("Firebase Auth Verification Id")
                    } else {
                        seal.reject(AuthError.verificationIdNil)
                    }
                }
        }
    }
    
    func signIn(verificationID: String, code: String, completionHandler: @escaping (AuthDataResult?, Error?) -> Void) {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        
        auth.signIn(with: credential, completion: completionHandler)
    }
    
    func signIn(verificationID: String, code: String) -> Promise<Void> {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        
        return Promise { seal in
            do {
                try auth.useUserAccessGroup("group.com.dabare.hamuwemu")
            } catch {
                print("Error while initializing Auth \(String(describing: error))")
                seal.reject(error)
            }
            auth.signIn(with: credential){ authResult, error in
                if let error = error {
                    seal.reject(error)
                    return
                }
                seal.fulfill(Void())
            }
        }
    }
    
    func reauthenticate(verificationID: String, code: String) -> Promise<Void> {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        
        return Promise { seal in
            do {
                try auth.useUserAccessGroup("group.com.dabare.hamuwemu")
            } catch {
                print("Error while initializing Auth \(String(describing: error))")
                seal.reject(error)
            }
            auth.currentUser?.reauthenticate(with: credential) { result, error in
                if let error = error {
                  // An error happened.
                    seal.reject(error)
                } else {
                  // User re-authenticated.
                    seal.fulfill(Void())
                }
              }
        }
    }
    
    func anonymousSignUp() -> Promise<User> {
        return Promise { seal in
            do {
                try auth.useUserAccessGroup("group.com.dabare.hamuwemu")
            } catch {
                print("Error while initializing Auth \(String(describing: error))")
                seal.reject(error)
            }
            auth.signInAnonymously{ authResult, error in
                if let error = error {
                    seal.reject(error)
                    return
                }
                
                guard let user = authResult?.user else {
                    seal.reject(AuthError.userNil)
                    return
                }
//                let isAnonymous = user.isAnonymous  // true
//                let uid = user.uid
                
                seal.fulfill(user)
            }
        }
    }
    
    func initAnonymousAccount(user: User, displayName: String) -> Promise<Void>{
        self.user = user
        self.userId = user.uid
        //DEMO: user does not have a phone number. Use uid instead.
        self.phoneNumber = user.uid
        self.displayName = user.displayName
        UserDefaults.extensions.uid = user.uid
        user.getIDToken { token, error in
            if let error = error {
                print("Error retrieving token: \(error.localizedDescription)")
                return
            }
            
            if let token = token {
                print("token: \(token)")
            }
            
        }
        //DEMO: user does not have a phone number. Use uid instead.
        self.account = Account(user: user, userId: user.uid, phoneNumber: user.phoneNumber ?? user.uid, displayName: displayName)
        self.account.connect()
        self.account.addToken()
        
        let publicKey = getPublicKeyBase64(for: user.uid)
        let newUser = AddUserModel(uid: user.uid, phoneNumber: user.uid, displayName: displayName, publicKey: publicKey)
        
        return account.addUser(newUser)
    }
    
    func getPublicKeyBase64(for uid: String) -> String {
        if let privateKey = try? KeychainWrapper.shared.getGenericPasswordFor(account: uid, service: .encryption) {
            return privateKey.publicKey.rawRepresentation.base64EncodedString()
        } else {
            let privateKey = Curve25519.KeyAgreement.PrivateKey()
            try! KeychainWrapper.shared.storeGenericPasswordFor(account: uid, service: .encryption, password: privateKey)
            return privateKey.publicKey.rawRepresentation.base64EncodedString()
        }
    }
    
    func deleteAccount() -> Promise<Void> {
        firstly {
            account.deleteAccount()
        }.then { _ in
            self.deleteUser()
        }
    }
    
    private func deleteUser() -> Promise<Void> {
        Promise { seal in
            auth.currentUser?.delete(completion: { error in
                if let error = error {
                    // An error happened.
                    seal.reject(error)
                  } else {
                    // Account deleted.
                      seal.fulfill(Void())
                  }
            })
        }
    }
    
    func logIn() {
        UserDefaults.standard.set(true, forKey: "isSignedIn")
    }
    
    func logOut() {
        UserDefaults.standard.removeObject(forKey: "authVerificationID")
        UserDefaults.standard.removeObject(forKey: "phoneNumber")
        UserDefaults.standard.set(false, forKey: "isSignedIn")
        UserDefaults.extensions.removeObject(forKey: UserDefaults.Keys.uid)
    }
    
    private func addListeners() {
        if let handle = authenticationStateHandle {
            auth.removeStateDidChangeListener(handle)
        }

        authenticationStateHandle = auth
            .addStateDidChangeListener { _, user in
                print("User changed")
                self.user = user
                self.userId = user?.uid
                //DEMO user has no phone number. Use uid instead.
                self.phoneNumber = user?.phoneNumber ?? user?.uid
                self.displayName = user?.displayName
                UserDefaults.extensions.uid = user?.uid
                if let user = user {
                    user.getIDToken { token, error in
                        if let error = error {
                            print("Error retrieving token: \(error.localizedDescription)")
                            return
                        }
                        
                        if let token = token {
                            print("token: \(token)")
                        }
                        
                    }
                    //DEMO: use user id instead of phone number
                    self.account = Account(user: user, userId: user.uid, phoneNumber: user.phoneNumber ?? user.uid, displayName: user.displayName ?? "Asitha Kuruppu")
                    self.account.connect()
                    self.account.addToken()
                }
            }
    }
}
