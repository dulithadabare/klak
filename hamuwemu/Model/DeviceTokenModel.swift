//
//  DeviceTokenModel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-23.
//

import Foundation

struct DeviceTokenModel: Encodable {
  let token: String
  var debug = false
}

extension DeviceTokenModel {
    init(token: Data) {
      self.token = token.reduce("") { $0 + String(format: "%02x", $1) }
//      self.encoder.outputFormatting = .prettyPrinted
    }

}
