//
//  EmbossedButton.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/19/21.
//

import SwiftUI

struct EmbossedButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Button(
                action: {},
                label: {
                    Text("History")
                        .fontWeight(.bold)
                })
                .buttonStyle(EmbossedButtonStyle(buttonShape: .round))
                .padding(40)
                .previewLayout(.sizeThatFits)
            Button(
                action: {},
                label: {
                    Text("History")
                        .fontWeight(.bold)
                })
                .preferredColorScheme(.dark)
                .buttonStyle(EmbossedButtonStyle())
                .padding(40)
                .previewLayout(.sizeThatFits)
        }
    }
}

enum EmbossedButtonShape {
    case round, capsule
}

struct EmbossedButtonStyle: ButtonStyle {
    var buttonShape = EmbossedButtonShape.capsule
    
    func makeBody(configuration: Configuration) -> some View {
        let shadow = Color("drop-shadow")
        let highlight = Color("drop-highlight")
        return configuration.label
            .padding(10)
            .background(
                GeometryReader { geometry in
                    shape(size: geometry.size)
                        .foregroundColor(Color("background"))
                        .shadow(color: shadow, radius: 1, x: 2, y: 2)
                        .shadow(color: highlight, radius: 1, x: -2, y: -2)
                        .offset(x: -1, y: -1)
                }
            )
    }
    
    @ViewBuilder
    func shape(size: CGSize) -> some View {
        switch buttonShape {
        case .round:
            Circle()
                .stroke(Color("background"), lineWidth: 2)
                .frame(
                    width: max(size.width, size.height),
                    height: max(size.width, size.height))
            
        case .capsule:
            Capsule()
                .stroke(Color("background"), lineWidth: 2)
                .offset(x: -1)
                .offset(y: -max(size.width, size.height) / 2 +
                  min(size.width, size.height) / 2)

        }
    }
    
    
    
}
