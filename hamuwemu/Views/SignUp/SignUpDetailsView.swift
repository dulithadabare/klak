//
//  SignUpDetailsView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 9/30/21.
//

import SwiftUI
import PromiseKit

struct SignUpDetailsView: View {
    @StateObject var model = Model()
    @State private var firstName: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text(NSLocalizedString("Almost Done!", comment: "title"))
                    .font(.title)
                    .fontWeight(.semibold)
                Text("Add your name so you see your name in notifications and mentions.")
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
                    Button(action: {model.signUp()}) {
                        Text("Done")
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

struct SignUpDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SignUpDetailsView()
//                .preferredColorScheme(.dark)
        }
    }
}

import CryptoKit

extension SignUpDetailsView {
    class Model: ObservableObject {
        @Published var displayName = ""
        @Published var alertMessage = ""
        @Published var alert = false
        private var authenticationService: AuthenticationService = .shared
        @Published var isLoading = false
        
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
            
            guard let firebaseUid = authenticationService.user?.uid,
                  let phoneNumber = authenticationService.user?.phoneNumber else {
                showAlertMessage(message: "Phone Number cannot be empty.")
                return
            }
            
            let publicKey = getPublicKeyBase64(for: firebaseUid)
            let newUser = AddUserModel(uid: firebaseUid, phoneNumber: phoneNumber, displayName: displayName, publicKey: publicKey)
            isLoading = true
            firstly {
                authenticationService.account.addUser(newUser)
            }.done { _ in
                UserDefaults.standard.set(true, forKey: "isSignedIn")
            }.catch { error in
                print("Error while performing addUser: \(error)")
                self.showAlertMessage(message: "Error while performing addUser: \(error)")
            }.finally {
                self.isLoading = false
            }
//            UserDefaults.standard.set(true, forKey: "isSignedIn")
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
    }
}
