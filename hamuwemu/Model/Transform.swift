//
//  Transform.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/21/21.
//

import SwiftUI

struct Transform {
  var size = CGSize(width: 250, height: 180)
  var rotation: Angle = .zero
  var offset: CGSize = .zero
}

extension Transform: Codable {}

extension Angle: Codable {
    enum CodingKeys: CodingKey {
      case degrees
    }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let degrees = try container
      .decode(Double.self, forKey: .degrees)
    self.init(degrees: degrees)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(degrees, forKey: .degrees)

  }
}



