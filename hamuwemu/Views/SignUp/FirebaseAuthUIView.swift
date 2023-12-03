//
//  FirebaseAuthUIView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/25/21.
//

import SwiftUI


//struct FirebaseAuthUIView: UIViewControllerRepresentable {
//    @Binding var signUpSuccess: Bool
////    typealias UIViewControllerType = type
//
//    func makeUIViewController(context: Context)
//    -> some UIViewController {
//        let authUI = FUIAuth.defaultAuthUI()!
//        authUI.delegate = context.coordinator
//        let providers: [FUIAuthProvider] = [
//          FUIPhoneAuth(authUI:authUI),
//        ]
//        authUI.providers = providers
//
//        return authUI.authViewController()
//    }
//
//    func updateUIViewController(
//        _ uiViewController: UIViewControllerType,
//        context: Context
//    ) {
//    }
//
//    func makeCoordinator() -> AuthCoordinator {
//        AuthCoordinator(parent: self)
//    }
//
//
//}
//
//struct FirebaseAuthUIView_Previews: PreviewProvider {
//    static var previews: some View {
//        FirebaseAuthUIView(signUpSuccess: .constant(false))
//    }
//}
//
//
//class AuthCoordinator: NSObject,
//                         FUIAuthDelegate {
//    var parent: FirebaseAuthUIView
//
//    init(parent: FirebaseAuthUIView) {
//      self.parent = parent
//    }
//    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
//        if let error = error {
//            print("Sign Up Error",error.localizedDescription)
//            return
//        }
//
//        print("Firebase User", user?.displayName ?? "No Display Name")
//        parent.signUpSuccess = true
//    }
//
//}

