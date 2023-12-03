//
//  GroupThreadListItemView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-03.
//

import SwiftUI

struct GroupThreadListItemView: View {
    @EnvironmentObject var authenticationService: AuthenticationService
    @ObservedObject var item: HwThreadListItem
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                //                            Text(item.thread?.titleText?.string ?? "No Title")
                Text(item.thread?.titleText?.string ?? "No Title")
                HStack {
                    if item.lastMessageAuthorUid == authenticationService.account.userId,
                       let receipt = MessageStatus(rawValue: item.lastMessageStatusRawValue) {
                        MessageStatusView(receipt: .constant(receipt))
                        .font(.footnote)
                    }
                    
                    if let messageType = MessageType(rawValue: item.lastMessageType) {
                        Group {
                            switch messageType {
                            case .text:
                                Text(item.lastMessageText?.string.trimmingCharacters(in: .whitespaces) ?? "No Message")
                                    .lineLimit(2)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            case .image:
                                Text("📸 Photo")
                                    .lineLimit(2)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            case .imageWithCaption:
                                Text("\(Image(systemName: "camera.fill")) \(item.lastMessageText?.string.trimmingCharacters(in: .whitespaces) ?? "No Message")")
                                    .lineLimit(2)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            Spacer()
            if item.unreadCount > 0 {
                Spacer()
                UnreadCountView(count: UInt(item.unreadCount))
            }
            
        }
        .padding(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
        .frame(maxWidth: .infinity)
        
        
    }
}

struct GroupThreadListItemView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            ForEach(0..<10) { i in
                GroupThreadListItemView(item: SampleData.shared.loadThreadListItem(with: PersistenceController.preview.container.viewContext, threadId: "", groupId: "", isReplyingTo: false, titleText: NSAttributedString(string: "New Thread"), messageText: NSAttributedString(string: "Hello"), sender: SampleData.shared.currentSender, status: 2, undreadCount: 2))
                    .preferredColorScheme(.dark)
                    .environmentObject(AuthenticationService.preview)
            }
        }
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(uiColor: UIColor.secondarySystemBackground)))
        .padding()
    }
}
