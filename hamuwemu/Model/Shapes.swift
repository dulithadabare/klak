//
//  Shapes.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/25/21.
//

import SwiftUI

struct Shapes: View {
    var body: some View {
      VStack {
        Rectangle()
        RoundedRectangle(cornerRadius: 25.0)
        Circle()
        Capsule()
        Ellipse()
      }
      .padding()
    }

}

struct Shapes_Previews: PreviewProvider {
    static var previews: some View {
        Circle()
            .aspectRatio(1, contentMode: .fit)
            .background(Color.yellow)
            .previewLayout(.sizeThatFits)

    }
}
