//
//  UserInfoView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-04-08.
//

import SwiftUI

struct UserInfoView: View {
    @EnvironmentObject var contactRepository: ContactRepository
    var phoneNumber: String
    var body: some View {
        VStack {
            Form {
                Section() {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(contactRepository.getFullName(for: phoneNumber))
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Phone Number")
                        Spacer()
                        Text(phoneNumber)
                            .foregroundColor(.gray)
                    }
                }
                
            }
//            Text("Dulitha Dabare")
//                .font(.title2)
//                .fontWeight(.bold)
//            Text(phoneNumber)
//                .font(.body)
//                .foregroundColor(.secondary)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Contact Info")
                    .fontWeight(.semibold)
            }
        }
    }
}

struct UserInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UserInfoView(phoneNumber: "+16505553535")
        }
        .environmentObject(ContactRepository.preview)
    }
}
