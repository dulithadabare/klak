//
//  SettingsPhoneAuthView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-06-02.
//

import SwiftUI

struct SettingsPhoneAuthView: View {
    var onReauthentication: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    
    var body: some View {
        NavigationView {
            SettingsValidatePhoneView() {
                dismiss()
                onReauthentication()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                    
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Delete Account")
                        .fontWeight(.semibold)
                }
            }
        }
        
    }
}

struct SettingsPhoneAuthView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsPhoneAuthView(onReauthentication: {})
    }
}
