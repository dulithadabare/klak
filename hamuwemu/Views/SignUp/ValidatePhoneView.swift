//
//  ValidatePhoneView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 9/29/21.
//

import SwiftUI
import FirebaseAuth
import CountryPicker

struct ValidatePhoneView: View {
    @StateObject private var model = Model()
    @State private var showCountryCodePicker = false
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Enter Phone Number")
                    .font(.title)
                    .fontWeight(.semibold)
                Text("We will send an SMS to your phone to verify it's really you")
                    .font(.subheadline)
            }
            .padding()
            Form {
                Section(footer: Text(model.prompt).foregroundColor(.red)) {
                    HStack{
                        Button(action: {showCountryCodePicker.toggle()}) {
                            Text("\(model.country.isoCode) +\(model.country.phoneCode)")
                        }
//                            TextField("Eg: 71 123 4567", text: $model.phoneNumber)
                        PhoneNumberTextFieldView(text: $model.text, country: $model.country)
                    }
                    .onChange(of: model.country.isoCode) { _ in
                        model.phoneNumber = ""
                    }
                }
            }
        }
        .onAppear{
            model.checkForSavedVerificatonID()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if model.isLoading {
                        ProgressView()
                    }
                    NavigationLink(
                        destination: OtpView(), isActive: $model.showOtp){
                            Button(action: {model.verify()}) {
                                Text("Next")
                            }
                    }
                    .disabled(model.isLoading)
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
        .sheet(isPresented: $showCountryCodePicker, content: {
            CountryPicker(country: $model.country)
        })
    }
}

struct ValidatePhoneView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ValidatePhoneView()
        }
    }
}

import PromiseKit

extension ValidatePhoneView {
    class Model: ObservableObject {
        @Published var text: String = ""
        @Published var prompt: String = ""
        @Published var countryCode: String = "+1"
        @Published var country: Country = Country(isoCode: "LK")
        @Published var alertMessage = ""
        @Published var alert = false
        @Published var isLoading = false
        @Published var showOtp = false
        @AppStorage("authVerificationID") private var verificationID: String?
        @AppStorage("phoneNumber") var phoneNumber: String?
        
        init(){
            
        }
        
        func checkForSavedVerificatonID(){
            print("Saved authVerificationID", verificationID ?? "nil")
            showOtp = verificationID != nil
        }
        
        private func showAlertMessage(message: String) {
            alertMessage = message
            alert.toggle()
        }
        
        func validate() -> Bool {
            if text.isEmpty {
                return false
            }
            return true
        }
        
        func verify() {
            guard validate() else {
                prompt = "Looks like your phone number may be incorrect. Please try entering your full number and check that your country code is selected."
                return
            }
            
            
            isLoading = true
            firstly {
                AuthenticationService.shared.verify(phoneNumber: text)
            }.done { verificationID in
                self.verificationID = verificationID
                self.phoneNumber = self.text
                self.showOtp = true
            }.catch { error in
                print("Error while performing addUser: \(error)")
                self.showAlertMessage(message: "Error while performing verify: \(error)")
            }.finally {
                self.isLoading = false
            }
        }
        
    }
}
