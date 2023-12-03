//
//  ChatWallpaperView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-16.
//

import SwiftUI

struct GradientBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var gradient: Gradient {
      Gradient(colors: [
        Color(UIColor(rgb: 0xA0C4E9)),
        Color(UIColor(rgb: 0x478ACD)),
      ])
    }
    
    var darkGradient: Gradient {
      Gradient(colors: [
        Color(UIColor(rgb: 0xE57C00)),
        Color(UIColor(rgb: 0x5E0000)),
      ])
    }
    
    var body: some View {
        LinearGradient(
            gradient: colorScheme == .dark ? darkGradient : gradient,
            startPoint: .top,
            endPoint: .bottom)
//            .edgesIgnoringSafeArea(.all)
            .overlay(Color.black.opacity(0.2))
    }
}

struct GradientBackground_Previews: PreviewProvider {
    static var previews: some View {
        GradientBackground()
            .preferredColorScheme(.dark)
            .frame(width: 300, height: 300)
                  .previewLayout(.sizeThatFits)
    }
}
