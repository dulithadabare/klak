//
//  Badge.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-04.
//

import SwiftUI

struct Badge: View {
    let count: Int16

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
            if count > 0 {
                Text(String(count))
                    .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
                    .font(.footnote)
                    .foregroundColor(.white)
                    .background(Capsule()
                                    .fill(Color.red))
                    // custom positioning in the top-right corner
                    .alignmentGuide(.top) { $0[.bottom] - 20 }
                    .alignmentGuide(.trailing) { $0[.trailing] - $0.width * 0.25 }
            }
        }
//        .animation(.easeInOut, value: count)
    }
}
struct Badge_Previews: PreviewProvider {
    static var previews: some View {
        Text("Threads")
            .overlay(Badge(count: 200))
    }
}
