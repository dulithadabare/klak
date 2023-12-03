//
//  ActivityIndicator.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/26/21.
//

import SwiftUI

// https://bit.ly/3cVlzif
struct ActivityIndicator: View {
  let style = StrokeStyle(lineWidth: 6, lineCap: .round)
  @State private var animate = false

  let color1 = Color.black
  let color2 = Color.white

  var body: some View {
    ZStack {
      Circle()
        .trim(from: 0, to: 0.7)
        .stroke(
          AngularGradient(
            gradient: .init(colors: [color1, color2]),
            center: .center),
          style: style)
        .rotationEffect(Angle(degrees: animate ? 360 : 0))
        .animation(
          Animation.linear(duration: 0.7)
            .repeatForever(autoreverses: false))
    }
    .onAppear {
      animate.toggle()
    }
  }
}

struct ActivityIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ActivityIndicator()
            .previewLayout(.sizeThatFits)
    }
}
