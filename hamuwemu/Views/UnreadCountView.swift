//
//  UnreadCountView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/23/21.
//

import SwiftUI

struct UnreadCountView: View {
    var count: UInt
    var body: some View {
        Text("\(count)")
            .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
            .font(.footnote)
            .foregroundColor(.white)
            .background(Capsule()
                            .fill(Color.blue))
            
        
    }
}

struct UnreadCountView_Previews: PreviewProvider {
    static var previews: some View {
        UnreadCountView(count: 5)
    }
}
