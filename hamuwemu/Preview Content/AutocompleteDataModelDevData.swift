//
//  AutocompleteDataModelDevData.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/20/21.
//

import Foundation
import InputBarAccessoryView

extension AutocompleteDataModel {
    func createDevData(){
        items = [
            AutocompleteItem(content: NSAttributedString(string: "@Asitha"), completion: { print("Tapped @Asitha")}),
            AutocompleteItem(content: NSAttributedString(string: "@Kalpana"), completion: { print("Tapped @Asitha")})]
    }
}
