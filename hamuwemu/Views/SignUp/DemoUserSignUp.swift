//
//  DemoUserSignUp.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-08-25.
//

import SwiftUI

struct DemoUserSignUp: View {
    @StateObject var model = Model()
    @State private var firstName: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text(NSLocalizedString("Hello!", comment: "title"))
                    .font(.title)
                    .fontWeight(.semibold)
                Text("Add your name so your team members can see who you are.")
                    .font(.subheadline)
            }
            .padding()
            //                .background(Color.red)
            Form {
                Section(footer: Text(model.prompt()).foregroundColor(.red)){
                    TextField("Full Name", text: $model.displayName)
                        .disableAutocorrection(true)
                }
//                    Text(model.prompt())
//                        .fixedSize(horizontal: false, vertical: true)
//                        .font(.caption)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if model.isLoading {
                        ProgressView()
                    }
                    
                    NavigationLink(
                        destination: DemoCreateWorkspaceView(), isActive: $model.showCompanyNameView){
                            Button(action: {model.signUp()}) {
                                Text("Next")
                            }
                    }
                        .disabled(!model.validate() || model.isLoading)
                    
                }
            }
        }
        .alert(isPresented: $model.alert, content: {
              Alert(
                title: Text("Message"),
                message: Text(model.alertMessage),
                dismissButton: .destructive(Text("OK"))
              )
            })
    }
}

struct DemoUserSignUp_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DemoUserSignUp()
        }
    }
}

import CryptoKit
import PromiseKit

extension DemoUserSignUp {
    class Model: ObservableObject {
        @Published var displayName = ""
        @Published var alertMessage = ""
        @Published var alert = false
        private var authenticationService: AuthenticationService = .shared
        @Published var isLoading = false
        @Published var showCompanyNameView = false
        
        init() {
        }
        
        private func showAlertMessage(message: String) {
            alertMessage = message
            alert.toggle()
        }
        
        func validate() -> Bool {
            if displayName.isEmpty {
                return false
            }
            
            //check if length < 30
            if displayName.utf16.count > 30 {
                return false
            }
            
            return true
        }
        
        func prompt() -> String {
            if displayName.utf16.count > 30 {
                return "Enter a name under 30 characters (Yours has \(displayName.utf16.count))."
            }
            
            return ""
        }
        
        func signUp() {
            // check if all fields are inputted correctly
            if displayName.isEmpty  {
                showAlertMessage(message: "Name cannot be empty.")
                return
            }
            
            firstly {
                authenticationService.anonymousSignUp()
            }.then { user in
                self.authenticationService.initAnonymousAccount(user: user, displayName: self.displayName)
            }.done { _ in
                self.showCompanyNameView = true
            }.catch { error in
                print("Error while performing anonymousSignUp: \(error)")
                self.showAlertMessage(message: "Error while performing anonymousSignUp: \(error)")
            }.finally {
                self.isLoading = false
            }
            
//            let publicKey = getPublicKeyBase64(for: firebaseUid)
//            let newUser = AddUserModel(uid: firebaseUid, phoneNumber: phoneNumber, displayName: displayName, publicKey: publicKey)
//            isLoading = true
//            firstly {
//                authenticationService.account.addUser(newUser)
//            }.done { _ in
//                UserDefaults.standard.set(true, forKey: "isSignedIn")
//            }.catch { error in
//                print("Error while performing addUser: \(error)")
//                self.showAlertMessage(message: "Error while performing addUser: \(error)")
//            }.finally {
//                self.isLoading = false
//            }
////            UserDefaults.standard.set(true, forKey: "isSignedIn")
        }
    }
}
