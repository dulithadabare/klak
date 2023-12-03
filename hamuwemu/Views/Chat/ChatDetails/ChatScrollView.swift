//
//  ChatScrollView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/28/21.
//

import SwiftUI

struct ChatScrollView: View {
    
    var body: some View {
        ScrollView {
            VStack() {
                ForEach( 1 ..< 20){ index in
                    ChatMessageItem()
                }
            }
        }
    }
}

struct ChatScrollView_Previews: PreviewProvider {
    static var previews: some View {
        ChatScrollView()
    }
}
