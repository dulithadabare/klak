//
//  AddGroupListItemView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/12/21.
//

import SwiftUI

struct AddGroupListItemView: View {
    var contact: AppContactListItem
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(contact.fullName)
                Text(contact.phoneNumber)
                    .font(.footnote)
                    .foregroundColor(Color.gray)
//                Text(contact.publicKey)
//                    .font(.caption)
//                    .foregroundColor(Color.gray)
            }
            Spacer()
        }
        .contentShape(Rectangle())
        
    }
}

struct AddGroupListItemView_Previews: PreviewProvider {
    static var previews: some View {
        AddGroupListItemView(contact: AppContactListItem(id: "1", fullName: "Asitha", phoneNumber: "+94 777 3106261", groupId: nil, publicKey: "WKNLFNflnwflwnlfnw"))
            .previewLayout(.sizeThatFits)
    }
}
