//
//  StickyView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-04-19.
//

import SwiftUI

struct StickyDrag: View {
 
    var body: some View {
        HStack {
            StickyShape(color: .red)
            StickyShape(color: .green)
            StickyShape(color: .blue)
        }
    }
}

private let stickyThreshold: CGFloat = 175
private let shapeSize: CGFloat = 100

struct StickyShape: View {
    
    let color: Color
    
    @GestureState private var translation: CGSize = .zero
    
    var scaleForTranslation: CGFloat {
        if abs(translation.width) < stickyThreshold {
            return 1 + abs(translation.width) / shapeSize
        } else {
            return 1
        }
    }
    
    var offsetForTranslation: CGFloat {
        if abs(translation.width) < stickyThreshold {
            return translation.width / 2
        } else {
            return translation.width
        }
    }
    
    var body: some View {
        VStack {
                Rectangle()
                .frame(width: shapeSize, height: shapeSize)
                .background(color)
//                .shadow(5)
                .scaleEffect(x: 1, y: scaleForTranslation, anchor: .center)
                .offset(y:offsetForTranslation)
                .gesture(DragGesture(minimumDistance: 0)
                    .updating(self.$translation) { value, state, _ in
                    state = value.translation
                })
                .animation(.spring(response: 0.2, dampingFraction: 1.0, blendDuration: 1))
        }
    }
}

struct StickyDrag_Previews: PreviewProvider {
    struct StickyDrag_Harness: View {
        
        var body: some View {
            StickyDrag()
        }
    }
    
    static var previews: some View {
        StickyDrag_Harness()
    }
}
