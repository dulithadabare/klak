//
//  MessageContentView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/23/21.
//

import SwiftUI

struct AttributedMessageContentView: View {
    var message: ChatMessage? = nil
    var contactRepository: ContactRepository
    
    var body: some View {
        MessageContentView(message: message, contactRepository: contactRepository, showAttributedString: true)
    }
}

struct MessageContentView: View {
    var message: ChatMessage? = nil
    @ObservedObject var contactRepository: ContactRepository
    var showAttributedString = false
    private var content: String = "No Messages"
    private var attributedContent: NSAttributedString = NSAttributedString(string: "No Messages", attributes: [NSAttributedString.Key : Any]())
    private var authenticationService: AuthenticationService = .shared
    private var sender = ""
    private var isSent = false
    private var isDelivered = false
    private var isRead = false
    
    init(message: ChatMessage?, contactRepository: ContactRepository, showAttributedString: Bool = false) {
        self.message = message
        self.contactRepository = contactRepository
        self.showAttributedString = showAttributedString
        
        var temp = "No Messages"
        if let message = message {
            let attributedText = attributedString(with: message.message, contactRepository: contactRepository)
            temp = attributedText.string
            self.attributedContent = attributedText
            
            if message.author == authenticationService.userId! {
                sender = "You"
                isRead = message.isRead
                isDelivered = message.isDelivered
                isSent = message.isSent
            } else {
                sender = contactRepository.getFullName(for: message.sender) ?? message.sender
            }

        }
        self.content = temp
        
    }
    
    var body: some View {
        HStack {
            Text("\(sender):")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundColor(Color.gray)
            
            if isRead {
                ZStack{
                    Image(systemName: "checkmark")
                        .font(.footnote)
                        .foregroundColor(.blue)
                    Image(systemName: "checkmark")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
            } else if isDelivered {
                Image(systemName: "checkmark")
                    .font(.footnote)
                    .foregroundColor(Color.gray)
                Image(systemName: "checkmark")
                    .font(.footnote)
                    .foregroundColor(Color.gray)
            } else if isSent {
                Image(systemName: "checkmark")
                    .font(.footnote)
                    .foregroundColor(Color.gray)
            }
            if showAttributedString {
                TextView(attributedText: attributedContent)
            } else {
                Text(content)
                    .lineLimit(2)
                    .font(.footnote)
                    .foregroundColor(Color.gray)
            }
        }
        
    }
}

struct MessageContentView_Previews: PreviewProvider {
    static var previews: some View {
        MessageContentView(message: ChatMessage(), contactRepository: ContactRepository.preview)
    }
}

struct TextView: UIViewRepresentable {
    var attributedText: NSAttributedString
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.textAlignment = .justified
        textView.isScrollEnabled = false
        textView.isSelectable = true
        textView.isEditable = false
        textView.dataDetectorTypes = UIDataDetectorTypes.link
        //        textView.isUserInteractionEnabled = true
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.allowsEditingTextAttributes = false
        textView.backgroundColor = .clear
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        textView.delegate = context.coordinator
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedText
    }
    
    func makeCoordinator() -> TextViewCoordinator {
        TextViewCoordinator()
    }
    
}

class TextViewCoordinator: NSObject, UITextViewDelegate {
    //    var parent: FirebaseAuthUIView
    //
    //    init(parent: FirebaseAuthUIView) {
    //      self.parent = parent
    //    }
    //    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
    //        if let error = error {
    //            print("Sign Up Error",error.localizedDescription)
    //            return
    //        }
    //
    //        print("Firebase User", user?.displayName ?? "No Display Name")
    //        parent.signUpSuccess = true
    //    }
    
    func showHashTagAlert(_ tagType:String, payload:String){
        let alertView = UIAlertView()
        alertView.title = "\(tagType) tag detected"
        // get a handle on the payload
        alertView.message = "\(payload)"
        alertView.addButton(withTitle: "Ok")
        alertView.show()
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        // check for our fake URL scheme hash:helloWorld
        if let scheme = URL.scheme {
            switch scheme {
            case "mention" :
                //                showHashTagAlert("mention", payload: URL.path)
                print("mention", URL.path)
            default:
                print("just a regular url")
            }
        }
        
        return true
    }
    
    
}



