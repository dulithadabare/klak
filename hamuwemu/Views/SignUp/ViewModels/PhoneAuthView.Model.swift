//
//  PhoneAuthView.Model.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/4/21.
//

import SwiftUI

extension PhoneAuthView {
    class Model: ObservableObject {
        @Published var userRepository: UserRepository
        @Published var alertMessage = ""
        @Published var alert = false
        @Published var showOtp = false
        @Published var isLoading = false
        private var authenticationService: AuthenticationService = .shared
        @AppStorage("authVerificationID") private var verificationID: String?
        @AppStorage("phoneNumber") var phoneNumber: String?
        var presentationMode: Binding<PresentationMode>?
        var signUpSuccess: Binding<Bool>?
        
        init() {
            userRepository = UserRepository()
            print("Saved authVerificationID", verificationID ?? "nil")
            showOtp = verificationID != nil
        }
        
        private func showAlertMessage(message: String) {
            alertMessage = message
            alert.toggle()
        }
        
        func validate(phoneNumber: String) {
            isLoading = true
            authenticationService.validate(phoneNumber: phoneNumber) { verificationID, error in
                    defer{ self.isLoading = false}
                    if let error = error {
                        self.showAlertMessage(message: error.localizedDescription)
                        return
                    }
                    
                    self.verificationID = verificationID ?? ""
                    self.phoneNumber = phoneNumber
                    self.showOtp = true
                    
                    print("Firebase Auth Verification Id")
                    //                    UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
                    // Sign in using the verificationID and the code sent to the user
                    // ...
                }
        }
        
        func signIn(code: String) {
            if code.isEmpty  {
                showAlertMessage(message: "Name cannot be empty.")
                return
            }
            
            isLoading = true
            authenticationService.signIn(verificationID: verificationID!, code: code) { authResult, error in
                defer{ self.isLoading = false}
                if let error = error {
                    self.showAlertMessage(message: error.localizedDescription)
                    return
                }
                // User is signed in
                self.signUpSuccess?.wrappedValue = true
                self.presentationMode?.wrappedValue.dismiss()
            }
        }
        
        func cancel() {
            presentationMode?.wrappedValue.dismiss()
        }
    }
}
