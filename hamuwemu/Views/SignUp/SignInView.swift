//
//  SignInView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 9/28/21.
//

import SwiftUI

struct SignInView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var showSignInView = false
    @State var signUpSuccess = false
    @StateObject var model = Model()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome to Klak!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding([.bottom], 8)
                Text("Read our [Privacy Policy](https://www.hamuwemu.app/privacy.html). Tap \"Agree & Continue\" to accept the [Terms of Service](https://www.hamuwemu.app/terms.html). ")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding([.bottom], 18)
                NavigationLink(destination: DemoUserSignUp()) {
                    Text("Agree & Continue")
                        .font(.headline)
                        .padding([.bottom], 18)
                }
            }
            .padding()
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .preferredColorScheme(.dark)
    }
}


