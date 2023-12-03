//
//  ChatMessageItem.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/28/21.
//

import SwiftUI

struct ChatMessageItem: View {
    var body: some View {
        VStack {
            Text("Hello!")
                .padding()
        }
        .frame(maxWidth: .infinity)
    }
}

struct ChatMessageItem_Previews: PreviewProvider {
    static var previews: some View {
        ChatMessageItem()
    }
}
