//
//  SettingsOtpView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-06-02.
//

import SwiftUI
import PromiseKit
import FirebaseAuth

struct SettingsOtpView: View {
    var phoneNumber: String
    var verificationId: String
    var completion: () -> Void
    
    @State private var text: String = ""
    @State private var prompt: String = ""
    @State private var alertMessage = ""
    @State private var alert = false
    @State private var isLoading = false
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var persistenceController: PersistenceController
    @EnvironmentObject private var contactRepository: ContactRepository
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Enter the confirmation code sent to \(phoneNumber) to proceed")
                    .font(.subheadline)

            }
            .padding()
            Form {
                Section(header: Text("Enter confirmation code"), footer: Text(prompt).foregroundColor(.red)) {
                    TextField("Confirmation Code", text: $text)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
//                        .disabled(model.isLoading)
                    
                }
                
                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                    }
                    Button(role: .destructive) {
                        signIn()
                    } label: {
                        Text("Delete Account")
                    }
                    .disabled(isLoading)
                    Spacer()
                }
            }

        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Delete Account")
                    .fontWeight(.semibold)
            }
        }
        .alert(isPresented: $alert, content: {
            Alert(
                title: Text("Message"),
                message: Text(alertMessage),
                dismissButton: .destructive(Text("OK"))
            )
        })
    }
}

struct SettingsOtpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsOtpView(phoneNumber: "", verificationId: "", completion: {})
                .environmentObject(AuthenticationService.preview)
                .environmentObject(PersistenceController.preview)
                .environmentObject(ContactRepository.preview)
        }
    }
}

extension SettingsOtpView {
    private func showAlertMessage(message: String) {
        alertMessage = message
        alert.toggle()
    }
    
    func signIn() {
        if text.isEmpty  {
            prompt = "Enter the confirmation code to proceed."
            return
        }

        
        isLoading = true
        firstly {
            authenticationService.reauthenticate(verificationID: verificationId, code: text)
        }.done { _ in
            completion()
        }.ensure {
            self.isLoading = false
        }.catch { error in
            print("Error: failed to perform delete account \(error)")
            self.handleError(error as NSError)
        }
    }
    
    func handleError(_ error: NSError) {
        if error.code == AuthErrorCode.invalidVerificationCode.rawValue {
            prompt = "The code isn't valid. You can request a new one"
        } else if error.code == AuthErrorCode.sessionExpired.rawValue {
            prompt = "The code has expired. You can request a new one"
        } else {
            showAlertMessage(message: "Error while performing signIn: \(error)")
        }
    }
}
