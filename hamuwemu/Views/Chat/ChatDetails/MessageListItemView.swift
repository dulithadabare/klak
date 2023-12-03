//
//  MessageListItemView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-01-05.
//

import SwiftUI

struct MessageListItemView: View {
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var contactRespository: ContactRepository
    @ObservedObject var item: HwChatMessage
    var size: CGSize
    var isPreviousMessageDifferentDay: Bool
    var isPreviousMessageSameSession: Bool
    var isNextMessageSameSender: Bool
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        //            formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    func isFromCurrentSender(message: HwChatMessage) -> Bool {
        return message.sender == authenticationService.phoneNumber!
    }
    
    var body: some View {
        HStack{
            VStack(alignment: isFromCurrentSender(message: item) ? .trailing : .leading) {
//                            Text(item.groupUid ?? "No UID")
                LabelView(attributedText: modifiedAttributedString(from: item.text!, contactRepository: contactRespository))
                Text(formatter.string(from: item.timestamp!))
                    .foregroundColor(.gray)
                    .font(.caption2)
            }
                
        }
        .padding()
//        .background(IncomingMessageShape()
//                    .fill( isFromCurrentSender(message: item) ? Color(UIColor.systemBlue) : Color(UIColor.secondarySystemBackground)))
    }
}

//struct MessageListItemView_Previews: PreviewProvider {
//    static var previews: some View {
//        MessageListItemView()
//    }
//}
