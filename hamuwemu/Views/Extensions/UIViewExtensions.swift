//
//  UIViewExtensions.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/1/21.
//

import UIKit

extension UIView {
  func smoothRoundCorners(to radius: CGFloat) {
    let maskLayer = CAShapeLayer()
    maskLayer.path = UIBezierPath(
      roundedRect: bounds,
      cornerRadius: radius
    ).cgPath

    layer.mask = maskLayer
  }
}
