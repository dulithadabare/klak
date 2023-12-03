//
//  IncomingMessageLabelView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-15.
//

import SwiftUI

struct IncomingMessageLabelView: View {
    @EnvironmentObject var contactRespository: ContactRepository
    @EnvironmentObject var authenticationService: AuthenticationService
    var attributedText: NSAttributedString
    var maxWidth: CGFloat
    var timestampWidth: CGFloat
    var timestamp: Date
    var receipt: Int16?
    @Binding var size: CGSize
    @Binding var moveTimestamp: Bool
    @StateObject private var coordinator = IncomingMessageLabelViewRepresentable.Coordinator()
    var body: some View {
        IncomingMessageLabelViewRepresentable(attributedText: attributedText, timestamp: timestamp, maxWidth: maxWidth, timestampWidth: timestampWidth, status: receipt, size: $size, moveTimestamp: $moveTimestamp, coordinator: coordinator)
            .onTapWithLocation { point in
                print("Tapped \(point)")
                coordinator.handleTap(point)
            }
    }
}

struct IncomingMessageLabelView_Previews: PreviewProvider {
    static var previews: some View {
        IncomingMessageLabelView(attributedText: NSAttributedString(string: "Filler text is text that shares some characteristics of a real written text, but is random or otherwise generated. It may be used to display a sample of fonts, generate text for testing, or to spoof an e-mail spam filter."), maxWidth: 200, timestampWidth: 50, timestamp: Date(), size: .constant(.zero), moveTimestamp: .constant(false))
            .background(Color.blue)
            .environmentObject(AuthenticationService.preview)
            .environmentObject(ContactRepository.preview)
        //            .frame(maxWidth: 200)
    }
}


struct IncomingMessageLabelViewRepresentable: UIViewRepresentable {
    @EnvironmentObject var contactRespository: ContactRepository
    @EnvironmentObject var authenticationService: AuthenticationService
    var attributedText: NSAttributedString
    var timestamp: Date
    var maxWidth: CGFloat
    var timestampWidth: CGFloat
    var status: Int16?
    @Binding var size: CGSize
    @Binding var moveTimestamp: Bool
    var coordinator: Coordinator
    @State private var modifiedText: NSAttributedString? = nil
        
    func makeUIView(context: Context) -> CustomMessageLabel {
        let messageLabel = CustomMessageLabel()
        messageLabel.frame = CGRect(x: UIScreen.main.bounds.width * 0.1, y: 150, width: maxWidth, height: 0)
        messageLabel.preferredMaxLayoutWidth = maxWidth
        messageLabel.clipsToBounds = false
        
        func detectorAttributes(for detector: DetectorType) -> [NSAttributedString.Key: Any] {
            switch detector {
                //            case .hashtag, .mention: return [.foregroundColor: UIColor.link]
            case .url: return [.foregroundColor: UIColor.link]
            default: return CustomMessageLabel.defaultAttributes
            }
        }
        
        let enabledDetectors: [DetectorType] = [.url, .address, .date, .transitInformation,]
        
        messageLabel.configure {
            messageLabel.enabledDetectors = enabledDetectors
            for detector in enabledDetectors {
                let attributes = detectorAttributes(for: detector)
                messageLabel.setAttributes(attributes, detector: detector)
            }
            messageLabel.attributedText = attributedText
        }
        
        messageLabel.delegate = context.coordinator
        messageLabel.attributedText = modifiedAttributedString(from: attributedText, contactRepository: contactRespository, authenticationService: authenticationService)
        //dangerous?
        coordinator.messageLabel = messageLabel
        
        return messageLabel
    }
    
    func updateUIView(_ textView: CustomMessageLabel, context: Context) {
//        print("Updating messageLabelView: receipt \(status ?? -1)")
        DispatchQueue.main.async {
            textView.attributedText = modifiedAttributedString(from: attributedText, contactRepository: contactRespository, authenticationService: authenticationService)
            textView.sizeToFit()
            size = textView.frame.size
            
            // Get glyph index in textview, make sure there is atleast one character present in message
            let lastGlyphIndex = textView.layoutManager.glyphIndexForCharacter(at: attributedText.string.count - 1)
            // Get CGRect for last character
            let lastLineFragmentRect = textView.layoutManager.lineFragmentUsedRect(forGlyphAt: lastGlyphIndex, effectiveRange: nil)
            
            // Check whether enough space is avaiable to show in last line of message, if not add extra height for timestamp
            print("lastLineFragmentRect.maxX: \(lastLineFragmentRect.maxX) maxWidth: \(maxWidth) message: \(attributedText.string)")
            if lastLineFragmentRect.maxX > (maxWidth - timestampWidth - 8) {
                moveTimestamp = true
                // Subtracting 5 to reduce little top spacing for timestamp
//                messageView.frame.size.height += (rightBottomViewHeight - 5)
            } else {
                moveTimestamp = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        coordinator
    }
    
    class Coordinator: ObservableObject {
        weak var messageLabel: CustomMessageLabel? = nil
        
        func handleTap(_ touchLocation: CGPoint){
            _ = messageLabel?.handleGesture(touchLocation)
        }
    }
    
}

extension IncomingMessageLabelViewRepresentable.Coordinator: MessageLabelDelegate {
    func didSelectAddress(_ addressComponents: [String: String]) {
        print("Address Selected: \(addressComponents)")
    }
    
    func didSelectDate(_ date: Date) {
        print("Date Selected: \(date)")
    }
    
    func didSelectPhoneNumber(_ phoneNumber: String) {
        print("Phone Number Selected: \(phoneNumber)")
    }
    
    func didSelectURL(_ url: URL) {
        print("URL Selected: \(url)")
    }
    
    func didSelectTransitInformation(_ transitInformation: [String: String]) {
        print("TransitInformation Selected: \(transitInformation)")
    }
    
    func didSelectHashtag(_ hashtag: String) {
        print("Hashtag selected: \(hashtag)")
    }
    
    func didSelectMention(_ mention: String) {
        print("Mention selected: \(mention)")
    }
    
    func didSelectCustom(_ pattern: String, match: String?) {
        print("Custom data detector patter selected: \(pattern)")
    }
}
