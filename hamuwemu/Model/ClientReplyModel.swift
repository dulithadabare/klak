//
//  ClientReplyModel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-04-15.
//

import Foundation

struct ClientProtocolError: Decodable {
    var code: UInt32 = 0
    
    var message: String = String()
    
    init() {}
}

struct ClientReplyModel: Decodable {
    var id: UInt32 = 0
    
    var error: ClientProtocolError {
        get {return _error ?? ClientProtocolError()}
        set {_error = newValue}
    }
    /// Returns true if `error` has been explicitly set.
    var hasError: Bool {return self._error != nil}
    /// Clears the value of `error`. Subsequent reads from it will return its default value.
    mutating func clearError() {self._error = nil}
    
    var result: Any? = nil
    
    init() {}
    
    fileprivate var _error: ClientProtocolError? = nil
    
    enum CodingKeys: String, CodingKey {
        case id, error, result    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UInt32.self, forKey: .id)
        _error = try? values.decode(ClientProtocolError.self, forKey: .error)
        result = try? values.decode(MessageReceiptModel.self, forKey: .result)
    }
}
