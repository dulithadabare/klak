//
//  SystemMessageView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-15.
//

import SwiftUI

struct SystemMessageView: View {
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var contactRespository: ContactRepository
    var text: NSAttributedString
    @State private var modifiedString: String = ""
    var body: some View {
        Text(modifiedString)
            .font(.caption2)
            .foregroundColor(Color.secondary)
            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
            .background(.thickMaterial)
            .containerShape(Capsule())
            .padding(7)
            .onAppear {
//                print("SystemMessage: \(text.string)")
                DispatchQueue.global(qos: .userInitiated).async {
                    let modifiedText = modifiedAttributedString(from: text, contactRepository: contactRespository)
                    DispatchQueue.main.async {
                        modifiedString = modifiedText.string
                    }
                }
            }
    }
}

struct SystemMessageView_Previews: PreviewProvider {
    static var previews: some View {
        SystemMessageView(text: SampleData.shared.normalMentionMessage)
            .environmentObject(AuthenticationService.preview)
            .environmentObject(ContactRepository.preview)
            .frame(width: 400, height: 400)
            .background(GradientBackground())
            .preferredColorScheme(.dark)
            .scaledToFit()
    }
}

extension SystemMessageView {

}
