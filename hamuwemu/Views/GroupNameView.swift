//
//  GroupNameView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/18/21.
//

import SwiftUI

struct GroupNameView: View {
    @EnvironmentObject var contactRepository: ContactRepository
    var isChat: Bool
    var groupName: String
    
    
    func getFullName(for phoneNumber: String)  -> String? {
        return contactRepository.getFullName(for: phoneNumber)
    }
    
    var body: some View {
        Text(isChat ? contactRepository.getFullName(for: groupName) : groupName )
    }
}

struct GroupNameView_Previews: PreviewProvider {
    static var previews: some View {
        GroupNameView(isChat: true, groupName: "+16505553535")
            .environmentObject(ContactRepository.preview)
    }
}
