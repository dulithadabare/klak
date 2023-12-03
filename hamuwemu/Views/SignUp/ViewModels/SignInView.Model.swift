//
//  SignInView.Model.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/3/21.
//

import Foundation

extension SignInView {
    class Model: ObservableObject {
        @Published var alertMessage = ""
        @Published var alert = false
        
        init() {
            
        }
        
        private func showAlertMessage(message: String) {
            alertMessage = message
            alert.toggle()
        }
    }
}
