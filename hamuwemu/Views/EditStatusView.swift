//
//  AddStatusView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/19/21.
//

import SwiftUI

struct EditStatusView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var status : StatusStore
    
    var body: some View {
        VStack {
            HStack {
                Text("Edit")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .padding()
            Spacer()
        }
    
        
    }
}

struct AddStatusView_Previews: PreviewProvider {
    static var previews: some View {
        EditStatusView()
    }
}
