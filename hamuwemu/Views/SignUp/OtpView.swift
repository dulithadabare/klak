//
//  OtpView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 9/30/21.
//

import SwiftUI
import FirebaseAuth
import PromiseKit

struct OtpView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var model = Model()
    @State private var verificationCode: String = ""
    @State private var showingAlert: SignUpError?
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Enter the confirmation code sent to")
                    .font(.subheadline)
                Text(model.phoneNumber ?? "Phone Number")
                    .font(.title)
                    .fontWeight(.semibold)
                HStack {
//                    Text("Enter the 6-digit code sent to")
//                        .font(.subheadline)
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Change Phone Number")
                            .font(.subheadline)
                    }
                    Text("or")
                                            .font(.subheadline)
                    Button {
                        model.resendCode()
                    } label: {
                        Text("Resend SMS")
                            .font(.subheadline)
                    }
                }

            }
            .padding()
            Form {
                Section(footer: Text(model.prompt).foregroundColor(.red)) {
                    TextField("Confirmation Code", text: $model.text)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
//                        .disabled(model.isLoading)
                }
            }
        }

        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if model.isLoading {
                        ProgressView()
                    }
                    NavigationLink(
                        destination: SignUpDetailsView(), isActive: $model.showNextView){
                            Button(action: {model.signIn()}) {
                                Text("Next")
                            }
                    }
                    .disabled(model.isLoading)
                }
            }
        }
    }
}

struct OtpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OtpView()
        }
    }
}

extension OtpView {
    class Model: ObservableObject {
        @Published var text: String = ""
        @Published var prompt: String = ""
        @Published var alertMessage = ""
        @Published var alert = false
        @Published var showNextView = false
        @Published var isLoading = false
        private var authenticationService: AuthenticationService = .shared
        @AppStorage("authVerificationID") private var verificationID: String?
        @AppStorage("phoneNumber") var phoneNumber: String?
        
        init(){
            
        }
        
        private func showAlertMessage(message: String) {
            alertMessage = message
            alert.toggle()
        }
        
        func signIn() {
            if text.isEmpty  {
                prompt = "Enter the confirmation code to proceed."
                return
            }
            
            guard let verificationID = verificationID else {
                return
            }

            
            isLoading = true
            firstly {
                AuthenticationService.shared.signIn(verificationID: verificationID, code: text)
            }.done { _ in
                self.showNextView = true
            }.catch { error in
                self.handleError(error as NSError)
            }.finally {
                self.isLoading = false
            }
        }
        
        func resendCode() {
            guard let phoneNumber = phoneNumber else {
                return
            }
            
            isLoading = true
            firstly {
                AuthenticationService.shared.verify(phoneNumber: phoneNumber)
            }.done { verificationID in
                self.verificationID = verificationID
            }.catch { error in
                print("Error while performing resend: \(error)")
                self.showAlertMessage(message: "Error while performing resend: \(error)")
            }.finally {
                self.isLoading = false
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
}
