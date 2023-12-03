//
//  SettingsValidatePhoneView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-06-02.
//

import SwiftUI
import CountryPicker
import PromiseKit

struct SettingsValidatePhoneView: View {
    var completion: () -> Void
    
    @State private var showCountryCodePicker = false
    @State private var text: String = ""
    @State private var verificationId: String = ""
    @State private var prompt: String = ""
    @State private var countryCode: String = "+1"
    @State private var country: Country = Country(isoCode: "LK")
    @State private var alertMessage = ""
    @State private var alert = false
    @State private var isLoading = false
    @State private var showOtp = false
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Deleting your account will remove your profile from Klak servers and delete all the data and settings stored on this device.")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("\nAuthenticate your phone number to proceed.")
                    .font(.subheadline)
            }
            .padding([.leading, .trailing, .top])
//            .padding()
            Form {
                Section(header: Text("Enter your phone number "), footer: Text(prompt).foregroundColor(.red)) {
                    HStack{
                        Button(action: {showCountryCodePicker.toggle()}) {
                            Text("\(country.isoCode) +\(country.phoneCode)")
                        }
//                            TextField("Eg: 71 123 4567", text: $model.phoneNumber)
                        PhoneNumberTextFieldView(text: $text, country: $country)
                    }
                    .onChange(of: country.isoCode) { _ in
                        text = ""
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if isLoading {
                        ProgressView()
                    }
                    NavigationLink(
                        destination: SettingsOtpView(phoneNumber: text, verificationId: verificationId, completion: completion), isActive: $showOtp){
                            Button(action: {
                                verify()
                            }) {
                                Text("Next")
                            }
                    }
                    .disabled(isLoading)
                }
            }
        }
        .alert(isPresented: $alert, content: {
            Alert(
                title: Text("Message"),
                message: Text(alertMessage),
                dismissButton: .destructive(Text("OK"))
            )
        })
        .sheet(isPresented: $showCountryCodePicker, content: {
            CountryPicker(country: $country)
        })
    }
}

struct SettingsValidatePhoneView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsValidatePhoneView(completion: {})
    }
}

extension SettingsValidatePhoneView {
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
            self.verificationId = verificationID
            self.showOtp = true
        }.catch { error in
            print("Error while performing addUser: \(error)")
            self.showAlertMessage(message: "Error while performing verify: \(error)")
        }.finally {
            self.isLoading = false
        }
    }
    
    private func showAlertMessage(message: String) {
        alertMessage = message
        alert.toggle()
    }
}
