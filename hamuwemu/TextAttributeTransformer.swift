//
//  TextAttributeTransformer.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/28/21.
//

import UIKit

@objc(TextAttributeTransformer)
class TextAttributeTransformer: NSSecureUnarchiveFromDataTransformer {
    //1
      override static var allowedTopLevelClasses: [AnyClass] {
        [NSAttributedString.self]
      }

      //2
      static func register() {
        let className = String(describing: TextAttributeTransformer.self)
        let name = NSValueTransformerName(className)

        let transformer = TextAttributeTransformer()
        ValueTransformer.setValueTransformer(
          transformer, forName: name)
      }
}
