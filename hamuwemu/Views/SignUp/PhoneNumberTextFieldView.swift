//
//  PhoneNumberTextFieldView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-10.
//

import SwiftUI
import PhoneNumberKit
import CountryPicker

struct PhoneNumberTextFieldView: UIViewRepresentable {
    typealias UIViewType = PhoneNumberTextField
    
    @Binding var text: String
    @Binding var country: Country
//    @State private var displayedText: String = ""
    
    func makeUIView(context: Context) -> PhoneNumberTextField {
        let uiView = PhoneNumberTextField()
        
        uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        uiView.addTarget(context.coordinator,
                         action: #selector(Coordinator.textViewDidChange),
                         for: .editingChanged)
        uiView.delegate = context.coordinator
        uiView.withFlag = false
        uiView.withExamplePlaceholder = false
        uiView.partialFormatter.defaultRegion = "LK"
        uiView.withPrefix = false
        return uiView
    }

    func updateUIView(_ uiView: PhoneNumberTextField, context: Context) {
//        uiView.text = displayedText
        if uiView.partialFormatter.currentRegion != country.isoCode {
            uiView.text = ""
            uiView.partialFormatter.defaultRegion = country.isoCode
        }
       
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: PhoneNumberTextFieldView
        init(_ parent: PhoneNumberTextFieldView) {
            self.parent = parent
        }
    }
}

struct PhoneNumberTextFieldView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneNumberTextFieldView(text: .constant(""), country: .constant(Country(isoCode: "LK")))
    }
}

extension PhoneNumberTextFieldView.Coordinator: UITextFieldDelegate {
    @objc public func textViewDidChange(_ textField: UITextField) {
        guard let textField = textField as? PhoneNumberTextField else {
            return assertionFailure("Undefined state")
        }
        if let number = textField.phoneNumber {
            // If we have a valid number, update the binding
            let country = String(number.countryCode)
            let nationalNumber = String(number.nationalNumber)
            parent.text = "+" + country + nationalNumber
            
        } else {
            // Otherwise, maintain an empty string
            parent.text = ""
        }
        
        //        parent.text = textField.text ?? ""
        //        parent.displayedText = textField.text ?? ""
    }
}
