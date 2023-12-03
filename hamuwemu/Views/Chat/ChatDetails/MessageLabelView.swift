//
//  MessageLabelView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-15.
//

import SwiftUI
import UIKit

struct MessageLabelView: View {
    @EnvironmentObject var contactRespository: ContactRepository
    @EnvironmentObject var authenticationService: AuthenticationService
    var attributedText: NSAttributedString
    var maxWidth: CGFloat
    var timestamp: Date
    var receipt: Int16?
    @Binding var size: CGSize
    @StateObject private var coordinator = MessageLabelViewRepresentable.Coordinator()
    var body: some View {
        MessageLabelViewRepresentable(attributedText: attributedText, timestamp: timestamp, maxWidth: maxWidth, status: receipt, size: $size, coordinator: coordinator)
            .onTapWithLocation { point in
                print("Tapped \(point)")
                coordinator.handleTap(point)
            }
    }
}

struct MessageLabelView_Previews: PreviewProvider {
    static var previews: some View {
        MessageLabelView(attributedText: NSAttributedString(string: "Filler text is text that shares some characteristics of a real written text, but is random or otherwise generated. It may be used to display a sample of fonts, generate text for testing, or to spoof an e-mail spam filter."), maxWidth: 200, timestamp: Date(), size: .constant(.zero))
            .background(Color.blue)
            .environmentObject(AuthenticationService.preview)
            .environmentObject(ContactRepository.preview)
        //            .frame(maxWidth: 200)
    }
}

struct MessageLabelViewRepresentable: UIViewRepresentable {
    @EnvironmentObject var contactRespository: ContactRepository
    @EnvironmentObject var authenticationService: AuthenticationService
    var attributedText: NSAttributedString
    var timestamp: Date
    var maxWidth: CGFloat
    var status: Int16?
    @Binding var size: CGSize
    var coordinator: Coordinator
    @State private var modifiedText: NSAttributedString? = nil
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        //                    formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    func makeUIView(context: Context) -> UIView {
        let label = UILabel()
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        //        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.preferredMaxLayoutWidth = maxWidth
        
        //        label.setContentHuggingPriority(.required, for: .horizontal) // << here !!
        //        label.setContentHuggingPriority(.required, for: .vertical)
        //        label.translatesAutoresizingMaskIntoConstraints = false
        
        let messageLabel = CustomMessageLabel()
        messageLabel.preferredMaxLayoutWidth = maxWidth
        
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
        messageLabel.tag = 0xDEADBEEF
//        messageLabel.attributedText = modifiedAttributedString(from: attributedText, contactRepository: contactRespository, authenticationService: authenticationService)
        //dangerous?
        coordinator.messageLabel = messageLabel
        
        
        let msgViewMaxWidth = UIScreen.main.bounds.width * 0.7 // 70% of screen width
        
        let message = "Filler text is text that shares some characteristics of a real written text, but is random or otherwise generated. It may be used to display a sample of fonts, generate text for testing, or to spoof an e-mail spam filter."
        
        // Main container view
        let messageView = UIView(frame: CGRect(x: UIScreen.main.bounds.width * 0.1, y: 150, width: maxWidth - 15 - 7, height: 0))
//        let messageView = UIView()
//        messageView.backgroundColor = UIColor(red: 0.803, green: 0.99, blue: 0.780, alpha: 1)
        messageView.clipsToBounds = false
//        messageView.layer.cornerRadius = 5
        
        let timeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: messageView.bounds.width, height: 0))
        timeLabel.tag = 0xDEADBEEC
        timeLabel.font = UIFont.systemFont(ofSize: 10)
//        timeLabel.text = "12:12 AM"
        timeLabel.text = formatter.string(from: timestamp)
        timeLabel.sizeToFit()
        timeLabel.textColor = .secondaryLabel
        
//        let textView = UITextView(frame: CGRect(x: 0, y: 0, width: messageView.bounds.width, height: 0))
//        textView.isEditable = false
//        textView.isScrollEnabled = false
//        textView.showsVerticalScrollIndicator =  false
//        textView.showsHorizontalScrollIndicator = false
//        textView.backgroundColor = .clear
//        textView.text = message
        
        let textView = messageLabel
        textView.frame = CGRect(x: 0, y: 0, width: messageView.bounds.width, height: 0)
        
        
        
        // Wrap time label and status image in single view
        // Here stackview can be used if ios 9 below are not support by your app.
        let rightBottomView = UIView()
        rightBottomView.tag = 0xDEADBEEA
        let rightBottomViewHeight: CGFloat = 16
        
        if let status = status,
        let receipt = MessageStatus(rawValue: status){
            let readStatusImg = UIImageView()
            readStatusImg.tag = 0xDEADBEEB
            //            readStatusImg.image = UIImage(named: "double-tick-indicator.png")
            switch receipt {
            case .sent:
                readStatusImg.image = UIImage(systemName: "checkmark")
                readStatusImg.frame.size = CGSize(width: 12, height: 10)
                // Create a configuration object that’s initialized with two palette colors.
                if #available(iOS 15.0, *) {
                    let config = UIImage.SymbolConfiguration(hierarchicalColor: .systemGray)
                    readStatusImg.preferredSymbolConfiguration = config
                } else {
                    // Fallback on earlier versions
                }
            case .delivered:
                readStatusImg.image = UIImage(named: "custom.checkmark.double")
                readStatusImg.frame.size = CGSize(width: 16, height: 10)
                // Create a configuration object that’s initialized with two palette colors.
                if #available(iOS 15.0, *) {
                    let config = UIImage.SymbolConfiguration(hierarchicalColor: .systemGray)
                    readStatusImg.preferredSymbolConfiguration = config
                } else {
                    // Fallback on earlier versions
                }
                
            case .read:
                readStatusImg.image = UIImage(named: "custom.checkmark.double")
                readStatusImg.frame.size = CGSize(width: 16, height: 10)
                // Create a configuration object that’s initialized with two palette colors.
                if #available(iOS 15.0, *) {
                    let config = UIImage.SymbolConfiguration(hierarchicalColor: .systemBlue)
                    readStatusImg.preferredSymbolConfiguration = config
                } else {
                    // Fallback on earlier versions
                }
            default:
                break
            }
            // Here 7 pts is used to keep distance between timestamp and status image
            // and 5 pts is used for trail space.
            rightBottomView.frame.size = CGSize(width: readStatusImg.frame.width + 7 + timeLabel.frame.width + 5, height: rightBottomViewHeight)
            rightBottomView.addSubview(timeLabel)
            readStatusImg.frame.origin = CGPoint(x: timeLabel.frame.width + 7, y: 0)
            rightBottomView.addSubview(readStatusImg)
        } else {
            // Here 7 pts is used to keep distance between timestamp and status image
            // and 5 pts is used for trail space.
            rightBottomView.frame.size = CGSize(width: timeLabel.frame.width + 5, height: rightBottomViewHeight)
            rightBottomView.addSubview(timeLabel)
        }
        
        
        
        // Fix right and bottom margin
        rightBottomView.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        
        messageView.addSubview(textView)
        messageView.addSubview(rightBottomView)
        
        // Update textview height
        textView.sizeToFit()
        // Update message view size with textview size
        messageView.frame.size = textView.frame.size
        
        // Keep at right bottom in parent view
        rightBottomView.frame.origin = CGPoint(x: messageView.bounds.width - rightBottomView.bounds.width, y: messageView.bounds.height - rightBottomView.bounds.height)
        
        // Get glyph index in textview, make sure there is atleast one character present in message
        let lastGlyphIndex = textView.layoutManager.glyphIndexForCharacter(at: attributedText.string.count - 1)
        // Get CGRect for last character
        let lastLineFragmentRect = textView.layoutManager.lineFragmentUsedRect(forGlyphAt: lastGlyphIndex, effectiveRange: nil)
        
        // Check whether enough space is avaiable to show in last line of message, if not add extra height for timestamp
        if lastLineFragmentRect.maxX > (textView.frame.width - rightBottomView.frame.width) {
            // Subtracting 5 to reduce little top spacing for timestamp
            messageView.frame.size.height += (rightBottomViewHeight - 5)
        }
        
        return messageView
    }
    
    func updateUIView(_ messageView: UIView, context: Context) {
        print("Updating messageLabelView: receipt \(status ?? -1)")
//        uiView.attributedText = modifiedAttributedString(from: attributedText, contactRepository: contactRespository, authenticationService: authenticationService)
        DispatchQueue.main.async {
            if let textView = messageView.viewWithTag(0xDEADBEEF) as? CustomMessageLabel,
               let rightBottomView =  messageView.viewWithTag(0xDEADBEEA),
               let timeLabel = messageView.viewWithTag(0xDEADBEEC) as? UILabel,
               let readStatusImg = rightBottomView.viewWithTag(0xDEADBEEB) as? UIImageView {
                let rightBottomViewHeight: CGFloat = 16
                textView.attributedText = modifiedAttributedString(from: attributedText, contactRepository: contactRespository, authenticationService: authenticationService)
                // Update textview height
                textView.sizeToFit()
                textView.preferredMaxLayoutWidth = maxWidth
                
//                textView.layer.borderWidth = 1
                textView.layer.borderColor = UIColor.red.cgColor
                
//                rightBottomView.layer.borderWidth = 1
                rightBottomView.layer.borderColor = UIColor.red.cgColor
                
//                messageView.layer.borderWidth = 1
//                messageView.layer.borderColor = UIColor.red.cgColor
                
                if let status = status, let receipt = MessageStatus(rawValue: status) {
                    switch receipt {
                    case .sent:
                        readStatusImg.image = UIImage(systemName: "checkmark")
                        readStatusImg.frame.size = CGSize(width: 12, height: 10)
                        // Create a configuration object that’s initialized with two palette colors.
                        if #available(iOS 15.0, *) {
                            let config = UIImage.SymbolConfiguration(hierarchicalColor: .systemGray)
                            readStatusImg.preferredSymbolConfiguration = config
                        } else {
                            // Fallback on earlier versions
                        }
                    case .delivered:
                        readStatusImg.image = UIImage(named: "custom.checkmark.double")
                        readStatusImg.frame.size = CGSize(width: 16, height: 10)
                        // Create a configuration object that’s initialized with two palette colors.
                        if #available(iOS 15.0, *) {
                            let config = UIImage.SymbolConfiguration(hierarchicalColor: .systemGray)
                            readStatusImg.preferredSymbolConfiguration = config
                        } else {
                            // Fallback on earlier versions
                        }
                        
                    case .read:
                        readStatusImg.image = UIImage(named: "custom.checkmark.double")
                        readStatusImg.frame.size = CGSize(width: 16, height: 10)
                        // Create a configuration object that’s initialized with two palette colors.
                        if #available(iOS 15.0, *) {
                            let config = UIImage.SymbolConfiguration(hierarchicalColor: .systemBlue)
                            readStatusImg.preferredSymbolConfiguration = config
                        } else {
                            // Fallback on earlier versions
                        }
                    default:
                        break
                    }
                }
                rightBottomView.frame.size = CGSize(width: readStatusImg.frame.width + 7 + timeLabel.frame.width + 5, height: rightBottomViewHeight)
                readStatusImg.frame.origin = CGPoint(x: timeLabel.frame.width + 7, y: 0)
                
                
                // Update message view size with textview size
//                messageView.frame.size = textView.frame.size
                messageView.frame.size.width = min(maxWidth, textView.frame.width + rightBottomView.frame.width + 15 + 7 + 7)
                messageView.frame.size.height = textView.frame.height
                
//                if textView.frame.width + rightBottomView.frame.width + 7 < maxWidth {
//                    messageView.frame.size.width = textView.frame.width + rightBottomView.frame.width + 20
//                }
                
                
                // Keep at right bottom in parent view
                rightBottomView.frame.origin = CGPoint(x: messageView.bounds.width - rightBottomView.bounds.width, y: messageView.bounds.height - rightBottomView.bounds.height)
                
                // Get glyph index in textview, make sure there is atleast one character present in message
                let lastGlyphIndex = textView.layoutManager.glyphIndexForCharacter(at: attributedText.string.count - 1)
                // Get CGRect for last character
                let lastLineFragmentRect = textView.layoutManager.lineFragmentUsedRect(forGlyphAt: lastGlyphIndex, effectiveRange: nil)
                
                // Check whether enough space is avaiable to show in last line of message, if not add extra height for timestamp
//                let maxX = lastLineFragmentRect.origin
//                let convertedRect = textView.convert(CGPoint.zero, to: messageView)
//                textView.text = "\(rightBottomView.frame.origin.x) \(lastLineFragmentRect.maxX)"
                
                let isShortMessage = textView.frame.width + rightBottomView.frame.width + 15 + 7 + 7 < maxWidth
                if lastLineFragmentRect.maxX > (textView.frame.width - rightBottomView.frame.width) && !isShortMessage {
                    // Subtracting 5 to reduce little top spacing for timestamp
                    messageView.frame.size.height += (rightBottomViewHeight + 10)
                } else {
                    messageView.frame.size.height += (10)
                }
                
                
                
                
                
                size = messageView.frame.size
            }
            
//            size = messageView.sizeThatFits(CGSize(width: messageView.bounds.width, height: messageView.bounds.height))
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

extension MessageLabelViewRepresentable.Coordinator: MessageLabelDelegate {
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
