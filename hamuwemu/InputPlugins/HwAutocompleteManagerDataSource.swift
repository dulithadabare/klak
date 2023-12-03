//
//  HwAutocompleteManagerDataSource.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/20/21.
//

import UIKit
import InputBarAccessoryView

/// AutocompleteManagerDataSource is a protocol that passes data to the AutocompleteManager
public protocol HwAutocompleteManagerDataSource: AnyObject {
    
    /// The autocomplete options for the registered prefix.
    ///
    /// - Parameters:
    ///   - manager: The HwAutocompleteManager
    ///   - prefix: The registered prefix
    /// - Returns: An array of `AutocompleteCompletion` options for the given prefix
    func autocompleteManager(_ manager: HwAutocompleteManager, autocompleteSourceFor prefix: String) -> [AutocompleteCompletion]
    
    /// The cell to populate the `AutocompleteTableView` with
    ///
    /// - Parameters:
    ///   - manager: The `AttachmentManager` that sources the UITableViewDataSource
    ///   - tableView: The `AttachmentManager`'s `AutocompleteTableView`
    ///   - indexPath: The `IndexPath` of the cell
    ///   - session: The current `Session` of the `AutocompleteManager`
    /// - Returns: A UITableViewCell to populate the `AutocompleteTableView`
    func autocompleteManager(_ manager: HwAutocompleteManager, tableView: UITableView, cellForRowAt indexPath: IndexPath, for session: HwAutocompleteSession) -> UITableViewCell
}

public extension HwAutocompleteManagerDataSource {
    
    func autocompleteManager(_ manager: HwAutocompleteManager, tableView: UITableView, cellForRowAt indexPath: IndexPath, for session: HwAutocompleteSession) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AutocompleteCell.reuseIdentifier, for: indexPath) as? AutocompleteCell else {
            fatalError("AutocompleteCell is not registered")
        }
        
        cell.textLabel?.attributedText = manager.attributedText(matching: session, fontSize: 13)
        if #available(iOS 13, *) {
            cell.backgroundColor = .systemBackground
        } else {
            cell.backgroundColor = .white
        }
        cell.separatorLine.isHidden = tableView.numberOfRows(inSection: indexPath.section) - 1 == indexPath.row
        return cell
        
    }
    
}
