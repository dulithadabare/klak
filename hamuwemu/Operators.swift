//
//  Operators.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/21/21.
//

import SwiftUI

func + (left: CGSize, right: CGSize) -> CGSize {
  CGSize(
    width: left.width + right.width,
    height: left.height + right.height)
}

