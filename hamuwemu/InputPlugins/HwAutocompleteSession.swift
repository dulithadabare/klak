//
//  HwAutocompleteSession.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/20/21.
//

import Foundation
import InputBarAccessoryView

/// A class containing data on the `AutocompleteManager`'s session
public class HwAutocompleteSession {
    
    public let prefix: String
    public let range: NSRange
    public var filter: String
    public var completion: AutocompleteCompletion?
    internal var spaceCounter: Int = 0
    
    public init?(prefix: String?, range: NSRange?, filter: String?) {
        guard let pfx = prefix, let rng = range, let flt = filter else { return nil }
        self.prefix = pfx
        self.range = rng
        self.filter = flt
    }
}

extension HwAutocompleteSession: Equatable {

    public static func == (lhs: HwAutocompleteSession, rhs: HwAutocompleteSession) -> Bool {
        return lhs.prefix == rhs.prefix && lhs.range == rhs.range
    }
}
