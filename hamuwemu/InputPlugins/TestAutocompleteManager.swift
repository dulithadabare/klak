//
//  TestAutocompleteManager.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/20/21.
//

import Foundation
import InputBarAccessoryView

class TestAutocompleteManager: AutocompleteManager {
//    var dataModel: AutocompleteDataModel
//    /// Reloads the InputPlugin's session
//    
//    // MARK: - Initialization
//    
//    public init(for textView: UITextView, with dataModel: AutocompleteDataModel ) {
//        super.init()
//        self.textView = textView
//        self.textView?.delegate = self
//        self.dataModel = dataModel
//    }
//    
//    override func reloadData() {
//        
//        var delimiterSet = autocompleteDelimiterSets.reduce(CharacterSet()) { result, set in
//            return result.union(set)
//        }
//        let query = textView?.find(prefixes: autocompletePrefixes, with: delimiterSet)
//        
//        guard let result = query else {
//            if let session = currentSession, session.spaceCounter <= maxSpaceCountDuringCompletion {
//                delimiterSet = delimiterSet.subtracting(.whitespaces)
//                guard let result = textView?.find(prefixes: [session.prefix], with: delimiterSet) else {
//                    unregisterCurrentSession()
//                    return
//                }
//                let wordWithoutPrefix = (result.word as NSString).substring(from: result.prefix.utf16.count)
//                updateCurrentSession(to: wordWithoutPrefix)
//            } else {
//                unregisterCurrentSession()
//            }
//            return
//        }
//        let wordWithoutPrefix = (result.word as NSString).substring(from: result.prefix.utf16.count)
//        guard let session = AutocompleteSession(prefix: result.prefix, range: result.range, filter: wordWithoutPrefix) else { return }
//        guard let currentSession = currentSession else {
//            registerCurrentSession(to: session)
//            return
//        }
//        if currentSession == session {
//            updateCurrentSession(to: wordWithoutPrefix)
//        } else {
//            registerCurrentSession(to: session)
//        }
//    }
//    
//    /// Initializes a session with a new `AutocompleteSession` object
//    ///
//    /// - Parameters:
//    ///   - session: The session to register
//    private func registerCurrentSession(to session: AutocompleteSession) {
//        
//        guard delegate?.autocompleteManager(self, shouldRegister: session.prefix, at: session.range) != false else { return }
//        currentSession = session
//        layoutIfNeeded()
//        delegate?.autocompleteManager(self, shouldBecomeVisible: true)
//    }
//    
//    /// Updates the session to a new String to filter results with
//    ///
//    /// - Parameters:
//    ///   - filterText: The String to filter `AutocompleteCompletion`s
//    private func updateCurrentSession(to filterText: String) {
//        
//        currentSession?.filter = filterText
//        layoutIfNeeded()
//        delegate?.autocompleteManager(self, shouldBecomeVisible: true)
//    }
//    
//    /// Invalidates the `currentSession` session if it existed
//    private func unregisterCurrentSession() {
//        
//        guard let session = currentSession else { return }
//        guard delegate?.autocompleteManager(self, shouldUnregister: session.prefix) != false else { return }
//        currentSession = nil
//        layoutIfNeeded()
//        delegate?.autocompleteManager(self, shouldBecomeVisible: false)
//    }
//    
//    /// Calls the required methods to relayout the `AutocompleteTableView` in it's superview
//    private func layoutIfNeeded() {
//        guard let session = currentSession else { fatalError("Attempted to render a cell for a nil `AutocompleteSession`") }
//        let items =  currentAutocompleteOptions.map{ completion in
//            return attributedText(matching: session, fontSize: 15)
//        }
//    }
}


