//
//  ContactPermissionGuideView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-04-07.
//

import SwiftUI

struct ContactPermissionGuideView: View {
    var body: some View {
        VStack {
            Text("Allow Klak access to your contacts so you can send and receive messages. To do this, tap Settings and turn on Contacts.")
                .multilineTextAlignment(.center)
                .padding([.bottom], 12)
            Button {
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                            return
                        }

                        if UIApplication.shared.canOpenURL(settingsUrl) {
                            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                print("Settings opened: \(success)") // Prints true
                            })
                        }
            } label: {
                Text("Settings")
            }

        }
        .padding()
    }
}

struct ContactPermissionGuideView_Previews: PreviewProvider {
    static var previews: some View {
        ContactPermissionGuideView()
    }
}
