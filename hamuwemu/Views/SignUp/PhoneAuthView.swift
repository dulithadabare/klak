//
//  PhoneAuthView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/2/21.
//

import SwiftUI
import FirebaseAuth

struct PhoneAuthView: View {
    @StateObject var model = Model()
    @Binding var signUpSuccess: Bool
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
//            if model.isLoading {
//                ActivityIndicator()
//            } else if model.showOtp {
//                OtpView(model: model)
//            } else {
//                ValidatePhoneView(model: model)
//            }
            ZStack {
                NavigationLink(
                    destination: OtpView(),
                    isActive: $model.showOtp){
                }
                ValidatePhoneView()
            }
        }
        .onAppear(){
            model.presentationMode = presentationMode
            model.signUpSuccess = $signUpSuccess
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

struct PhoneAuthView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneAuthView(signUpSuccess: .constant(false))
    }
}

