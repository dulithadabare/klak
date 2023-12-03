//
//  ViewExtensions.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/21/21.
//

import SwiftUI

extension View {
  func resizableView() -> some View {
    return modifier(ResizableView())
  }
}

