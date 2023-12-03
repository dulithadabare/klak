//
//  SettingsView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 9/28/21.
//

import SwiftUI
import PromiseKit

struct SettingsView: View {
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var persistenceController: PersistenceController
    @EnvironmentObject var contactRepository: ContactRepository
    @StateObject var model = Model()
    @State private var isLoading: Bool = false
    @State private var alertMessage = ""
    @State private var alert = false
    @State private var showAuthView = false
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Profile")
                            .font(.headline)) {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(authenticationService.account.displayName ?? "No Display Name")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Phone Number")
                        Spacer()
                        Text(authenticationService.account.phoneNumber ?? "No Number")
                            .foregroundColor(.gray)
                    }
                }
                
                HStack {
                    if isLoading {
                        ProgressView()
                    }
                    Button("Delete Account", role: .destructive) {
    //                    authStore.logOut()
                        showAuthView.toggle()
                    }
                    .disabled(isLoading)
                }
                
            }
        }
        .navigationTitle(NSLocalizedString("Settings", comment: "title"))
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAuthView, onDismiss: nil) {
            SettingsPhoneAuthView() {
                deleteAccount()
            }
        }

    }
}

extension SettingsView {
    func deleteAccount() {
        // check if all fields are inputted correctly
        
//            userRepository.remove(newUser)
        isLoading = true
        firstly {
            authenticationService.deleteAccount()
        }.done { _ in
            self.persistenceController.deleteAllEntities()
            self.contactRepository.deleteContactsFromDisk()
            self.authenticationService.logOut()
            
        }.ensure {
            self.isLoading = false
        }.catch { error in
            print("Error: failed to perform delete account \(error)")
            showAlertMessage(message: "Error while performing signIn: \(error)")
        }
    }
    
    private func showAlertMessage(message: String) {
        alertMessage = message
        alert.toggle()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AuthenticationService.preview)
    }
}

extension SettingsView {
    class Model: ObservableObject {
        @Published var alertMessage = ""
        @Published var alert = false
        private var authenticationService: AuthenticationService = .shared
        private var persistenceController: PersistenceController = .shared
        
        init(inMempry: Bool = false) {
            if inMempry {
                authenticationService = .preview
                persistenceController = .preview
            }
        }
        
        private func showAlertMessage(message: String) {
            alertMessage = message
            alert.toggle()
        }
        
        
    }
}
