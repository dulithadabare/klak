//
//  MessageReplyView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/22/21.
//

import SwiftUI

struct MessageReplyItem {
    let senderName: String
    let content: String
    let chatMessage: ChatMessage
}

extension MessageReplyItem {
    init(){
        senderName = "Dulitha Dabare"
        content = "@Asitha 🎶 Kurpp🏴󠁧󠁢󠁷󠁬󠁳󠁿u` in `Hello 👋 🏴󠁧󠁢󠁷󠁬󠁳󠁿 sgsgsgs @Asitha 🎶 Kurpp🏴󠁧󠁢󠁷󠁬󠁳󠁿u  🏴󠁧󠁢󠁷󠁬󠁳󠁿🏴󠁧󠁢󠁷󠁬󠁳󠁿GSgsg 😳😘😍🎶  @+16505553535 "
        chatMessage = ChatMessage()
    }
}

struct MessageReplyView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedReplyMessage: ChatMessage?
    var message: MessageReplyItem
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(message.senderName)
                    .font(.body)
                    .fontWeight(.bold)
                Text(message.content)
                    .font(.footnote)
                    .lineLimit(1)
            }
            Spacer()
            VStack {
                Button(action: {selectedReplyMessage = nil}, label: {
                    Image(systemName: "xmark.circle")
                })
                
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 50, idealHeight: 50, maxHeight: 50)
        .background(colorScheme == .dark ? Color.gray : Color(UIColor.systemGray6))
    }
}

struct MessageReplyView_Previews: PreviewProvider {
    static var previews: some View {
        MessageReplyView(selectedReplyMessage: .constant(nil), message: MessageReplyItem())
    }
}
