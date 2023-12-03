//
//  UIEdgeInsetsExtensions.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-15.
//

import Foundation
import UIKit

extension UIEdgeInsets {

    var vertical: CGFloat {
        return top + bottom
    }

    var horizontal: CGFloat {
        return left + right
    }

}
