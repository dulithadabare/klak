//
//  DemoCreateWorkspaceView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-08-29.
//

import SwiftUI

struct DemoCreateWorkspaceView: View {
    @StateObject var model = Model()
    @State private var firstName: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text(NSLocalizedString("Almost Done!", comment: "title"))
                    .font(.title)
                    .fontWeight(.semibold)
                Text("Add your company name so we can create your own workspace.")
                    .font(.subheadline)
            }
            .padding()
            //                .background(Color.red)
            Form {
                Section(footer: Text(model.prompt()).foregroundColor(.red)){
                    TextField("Company Name", text: $model.displayName)
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

struct DemoCreateWorkspaceView_Previews: PreviewProvider {
    static var previews: some View {
        DemoCreateWorkspaceView()
    }
}

import PromiseKit

extension DemoCreateWorkspaceView {
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
            
            let workspace = AddWorkspaceModel(title: displayName)
            isLoading = true
            firstly {
                authenticationService.account.addDemoWorkspace(workspace)
            }.then({ defaultChatGroup in
                PersistenceController.shared.insertGroup(defaultChatGroup)
            }).done { _ in
                UserDefaults.standard.set(true, forKey: "isSignedIn")
            }.catch { error in
                print("Error while performing addDemoWorkspace: \(error)")
                self.showAlertMessage(message: "Error while performing addDemoWorkspace: \(error)")
            }.finally {
                self.isLoading = false
            }
//            UserDefaults.standard.set(true, forKey: "isSignedIn")
        }
        
    }
}
