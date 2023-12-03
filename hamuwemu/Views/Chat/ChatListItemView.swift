//
//  ChatListItemView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/27/21.
//

import SwiftUI

struct ChatListItemView: View {
    @ObservedObject var item: HwChatListItem
    let width: CGFloat
    
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var contactRepository: ContactRepository
    @Environment(\.colorScheme) private var colorScheme
    
    
    @State var modifiedText: NSAttributedString = NSAttributedString(string: "Preview Message")
    
    func getReceipt(receipt: MessageStatus) -> UIImage? {
        switch receipt {
        case .sent:
            return UIImage(named: "sent-receipt")
        case .delivered:
            return UIImage(named: "delivered-receipt")
        case .read:
            return colorScheme == .dark  ?  UIImage(named: "read-dark") :  UIImage(named: "read-light")
               
        default:
            return nil
        }
    }
    
    func getFullString() -> NSAttributedString {
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(systemName: "checkmark.circle")

        // If you want to enable Color in the SF Symbols.
        imageAttachment.image = UIImage(systemName: "checkmark.circle")?.withTintColor(.blue)
        
        
        var prefix: NSAttributedString = NSAttributedString()
        if let _ = item.threadId {
            if let threadName = item.thread?.titleText?.string {
                prefix = NSAttributedString(string: "\(threadName): ", attributes: [.font: UIFont.systemFont(ofSize: 15.0, weight: .semibold)])
            } else {
                prefix = NSAttributedString(string: "In Topic ", attributes: [.font: UIFont.systemFont(ofSize: 15.0, weight: .semibold)])
//                Text("In Topic ")
//                    .font(.subheadline)
//                    .fontWeight(.semibold)
            }
        }
        

        let fullString = NSMutableAttributedString(attributedString: prefix)
//        fullString.append(NSAttributedString(attachment: imageAttachment))
        
        if item.lastMessageAuthorUid == authenticationService.account.userId,
           let receipt = MessageStatus(rawValue: item.lastMessageStatusRawValue) {
            let receiptAttachment = NSTextAttachment()
            receiptAttachment.image = getReceipt(receipt: receipt)
            receiptAttachment.setImageHeight(height: 13.0)
            
            let receiptString = NSMutableAttributedString(attachment: receiptAttachment)
            receiptString.append(NSAttributedString(string: " "))
            receiptString.addAttributes([.baselineOffset: -1.0], range: NSMakeRange(0, receiptString.length))
            
            fullString.append(receiptString)
        }
        
        var content: NSAttributedString = NSAttributedString()
        if let messageType = MessageType(rawValue: item.lastMessageType) {
            switch messageType {
            case .text:
                content = NSAttributedString(string: modifiedText.string.trimmingCharacters(in: .whitespacesAndNewlines), attributes: [.font: UIFont.systemFont(ofSize: 15.0),
                                                                                                                                       .foregroundColor: UIColor.secondaryLabel])
                
            case .image:
                let temp = NSMutableAttributedString(string: "📸", attributes: [.baselineOffset: 2.0])
                temp.append(NSAttributedString(string: " Photo", attributes: [.font: UIFont.systemFont(ofSize: 15.0),
                                                                              .foregroundColor: UIColor.secondaryLabel]))
                content = temp
                
            case .imageWithCaption:
                let camera = NSTextAttachment()
                camera.image = UIImage(systemName: "camera.fill", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 14.0)))?.withTintColor(.secondaryLabel)
//                camera.setImageHeight(height: 15.0)
                
                let attachement = NSAttributedString(attachment: camera)
                
                let temp = NSMutableAttributedString(attributedString: attachement)
                temp.append(NSAttributedString(string: " " + modifiedText.string.trimmingCharacters(in: .whitespacesAndNewlines),attributes: [.font: UIFont.systemFont(ofSize: 15.0),
                                                                                                                                        .foregroundColor: UIColor.secondaryLabel]))
                
               
                content = temp
                
            }
        }
        
        
        fullString.append(content)
        
        return fullString
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
//                            Text(chat.id)
//                GroupNameView(isChat: item.isChat, groupName: item.group?.groupName ?? "No Content")
                if let groupName = item.group?.groupName {
                    Text(contactRepository.getFullName(for: groupName))
                }
                HStack {
//                    if let receipt = MessageStatus(rawValue: item.lastMessageStatusRawValue) {
//                        MessageStatusView(receipt: .constant(receipt))
//                        .font(.footnote)
//                    }
                    AttributedTextLabel(getFullString(), width: width)
                }
            }
            if item.unreadCount > 0 {
                Spacer()
                UnreadCountView(count: UInt(item.unreadCount))
            }
            
        }
        .onReceive(contactRepository.$contactNames, perform: { _ in
            if let newValue = item.lastMessageAttrText {
                modifiedText = modifiedAttributedString(from: newValue, contactRepository: contactRepository)
            }
        })
        .onAppear {
            if let newValue = item.lastMessageAttrText {
                modifiedText = modifiedAttributedString(from: newValue, contactRepository: contactRepository)
            }
        }
        .onChange(of: item.lastMessageAttrText) { newValue in
            if let newValue = newValue {
                modifiedText = modifiedAttributedString(from: newValue, contactRepository: contactRepository)
            } else {
                modifiedText = NSAttributedString(string: "📸 Photo")
            }
        }
    }
}

//struct ChatListItemView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChatListItemView(item: SampleData.shared.getChatListItem(with: PersistenceController.preview.container.viewContext, sender: AuthenticationService.preview.account.phoneNumber!, author: AuthenticationService.preview.account.userId!, status: .delivered) )
//            .environmentObject(AuthenticationService.preview)
//            .environmentObject(ContactRepository.preview)
//            .padding()
//            .previewLayout(.sizeThatFits)
//    }
//}
