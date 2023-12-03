//
//  IncomingMessageView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-01-06.
//

import SwiftUI

struct TapShape : Shape {
        func path(in rect: CGRect) -> Path {
            return Path(CGRect(x: 0, y: 0, width: rect.width, height: rect.height))
        }
    }

struct IncomingMessageView: View {
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var contactRespository: ContactRepository
    @ObservedObject var model: IncomingMessageItemModel
    @Binding var selectedReplyItem: ReplyItem?
    
    var maxWidth: CGFloat
    var isPreviousMessageSameSender: Bool
    var isNextMessageSameSender: Bool
    var isThread: Bool
    var isDuo: Bool = false
    
    @State private var parentTextViewWiddth: CGFloat = CGFloat(0)
    @State private var mainTextViewWiddth: CGFloat = CGFloat(0)
    @State private var childTextViewWiddth: CGFloat = .zero
    @State private var maxTextViewWiddth: CGFloat = .zero
    @State private var timestampTextViewWiddth: CGFloat = .zero
    @State private var messageLabelSize: CGSize = .zero
    @State private var moveTimestamp: Bool = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "EdMMM", options: 0, locale: .current)
        //        formatter.timeStyle = .short
        return formatter
    }()
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        //                    formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var maxImageViewWidth: CGFloat {
        (maxWidth * (5/6)) - 3 - 3
    }
    
    var maxMessageLabelWidth: CGFloat {
        maxWidth * (5/6)
    }
    
    var isShortMessage: Bool {
        // message width + space (8) + timestamp width < maxWidth
        return  messageLabelSize.width + 8 + 50 < maxMessageLabelWidth - 8 - 15 - 7
    }
    
    
    
    var body: some View {
        VStack {
//            Text("mainText: \(modifiedAttributedString(from: item.text!, contactRepository: contactRespository, authenticationService: .preview).string)")
//            Text("mainTextViewWidth \(mainTextViewWiddth.description)")
//            Text("parentTextViewWidth \(parentTextViewWiddth.description)")
//            Text("childTextViewWidth \(childTextViewWiddth.description)")
//            Text("moveTimestamp \(moveTimestamp ? "true" : "false")")
            HStack {
                ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom)) {
                    VStack(alignment: .leading, spacing: 0) {
                        if let blurHashImage = model.blurHashImage {
                            IncomingMessageImageView(blurHashImage: blurHashImage, imageDocumentUrl: $model.imageDocumentUrl, isLoading: $model.isLoading, progress: $model.progress) {
                                model.download()
                                print("Tapped")
                            }
                                .frame(maxWidth: maxImageViewWidth, maxHeight: 300, alignment: .topLeading)
                                .cornerRadius(8)
                                .contentShape(TapShape())
                                .padding(EdgeInsets(top: 3, leading: 11, bottom: 3, trailing: 3)) // radius (8) + 3 = 11
                        }
                        
                        if let text = model.item.text, !text.string.isEmpty {
                            IncomingMessageLabelView(attributedText: text, maxWidth: (maxWidth * (5/6) - 8 - 15 - 7 ), timestampWidth: 50, timestamp: model.item.timestamp!, size: $messageLabelSize, moveTimestamp: $moveTimestamp)
                                .frame(width: min(messageLabelSize.width, maxWidth * (5/6)), height: messageLabelSize.height)
                                .padding(EdgeInsets(top: model.item.imageDownloadUrl == nil ? 7 : 0, leading: 15, bottom: 5, trailing: 7))
                        }
                        
//                        if model.isLoading {
//                            ProgressView(value: model.progress)
//                                .padding()
//                        } else if model.imageDocumentUrl == nil {
//                            Button {
//                                print("Tapped \(model.item.text!.string)")
//                                model.download()
//                            } label: {
////                                Text("Download")
//                                Image(systemName: "arrow.down.circle")
//                            }
//                            .buttonStyle(.bordered)
//                        }
                        
//                        Button {
//                            print("Tapped \(model.item.text!.string)")
//                        } label: {
//                            Text("Button")
//                        }
                    }
                    
                    HStack(spacing: 0) {
                        Text(MessageDateFormatter.shared.messageTimestampFormatter.string(from: model.item.timestamp!))
                            .font(.system(size: 10))
                            .foregroundColor( model.item.text == nil || model.item.text!.string.isEmpty ? .primary : .secondary)
                    }
                    .padding(EdgeInsets(top: model.item.imageDownloadUrl == nil ? 7 : 0, leading: 7, bottom: 5, trailing: 7))
                    .alignmentGuide(.bottom, computeValue: {d in moveTimestamp ? d[.bottom] - d.height - 5 : d[.bottom] })
                    .alignmentGuide(.trailing, computeValue: {d in isShortMessage && model.item.imageDownloadUrl == nil ? d[.leading] - 8 : d[.trailing] })
                    
                    
//                    MessageTimestampView(timestamp: item.timestamp!, messageLabelMaxWidth: maxMessageLabelWidth, messageLableSize: $messageLabelSize, moveTimestamp: $moveTimestamp)
                    
//                            .frame(alignment: .bottomTrailing)
//                            .padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 2))
                }
//                .padding(EdgeInsets(top: 7, leading: 15, bottom: 5, trailing: 7))
                .clipped()
                .background(IncomingMessageShape(addTail: !isPreviousMessageSameSender)
                                .fill( Color(UIColor.secondarySystemBackground)))
                .background(TextGeometry())
                .onPreferenceChange(WidthPreferenceKey.self, perform: { value in
                    mainTextViewWiddth = value
                })
                Spacer(minLength: maxWidth * (1/6))
            }
        }
//        .alert("Alert", isPresented: $model.showAlert, actions: {}, message: {
//            Text(model.alertMessage)
//                })
    }
}

struct IncomingMessageView_Previews: PreviewProvider {
    static let shortContent = "Hello @Dulitha Dabare"
    static let longContent = "Hello @Dulitha Dabare lllllllllllllllllllllllllllll lllllllllllllllllllllllllllll lllllllllllllllllllllllllllll llllllllllllllp"
    static let longMessageWithMention = SampleData.shared.getMessageForPreview(managedObjectContext: PersistenceController.preview.container.viewContext, text: SampleData.shared.longMentionMessage)
    static let longMessageWithShortLastLine = SampleData.shared.getMessageForPreview(managedObjectContext: PersistenceController.preview.container.viewContext, text: SampleData.shared.longMessageWithShortLastLine)
    static let shorterThanTimestampItem = SampleData.shared.getMessage( managedObjectContext: PersistenceController.preview.container.viewContext, text: "okokok")
    static let shorterThanTimestampItemWithTopReply = SampleData.shared.getMessageWithParent(managedObjectContext: PersistenceController.preview.container.viewContext, message: "ok")
    static let shorterThanTimestampItemWithBottomReply = SampleData.shared.getMessageWithChild(managedObjectContext: PersistenceController.preview.container.viewContext, message: "ok")
    
    static let longerThanTimestampItemWithReply = SampleData.shared.getMessageWithThreadReply(managedObjectContext: PersistenceController.preview.container.viewContext, message: "okokok")
    static let shorterThanTimestampItemWithReply = SampleData.shared.getMessageWithThreadReply(managedObjectContext: PersistenceController.preview.container.viewContext, message: "ok")
    static var previews: some View {
        Group {
            GeometryReader { proxy in
                IncomingMessageView(model: IncomingMessageItemModel(inMemory: true, chat: ChatGroup.preview, item: shorterThanTimestampItem), selectedReplyItem: .constant(nil), maxWidth: proxy.size.width, isPreviousMessageSameSender: false, isNextMessageSameSender: false, isThread: false)
                    .environment(\.layoutDirection, .leftToRight)
                    .environmentObject(AuthenticationService.preview)
                    .environmentObject(ContactRepository.preview)
            }
            
            GeometryReader { proxy in
                IncomingMessageView(model: IncomingMessageItemModel(inMemory: true, chat: ChatGroup.preview, item: longMessageWithMention), selectedReplyItem: .constant(nil), maxWidth: proxy.size.width, isPreviousMessageSameSender: false, isNextMessageSameSender: false, isThread: false)
                    .environment(\.layoutDirection, .leftToRight)
                    .environmentObject(AuthenticationService.preview)
                    .environmentObject(ContactRepository.preview)
            }
            GeometryReader { proxy in
                IncomingMessageView(model: IncomingMessageItemModel(inMemory: true, chat: ChatGroup.preview, item: longMessageWithShortLastLine), selectedReplyItem: .constant(nil), maxWidth: proxy.size.width, isPreviousMessageSameSender: false, isNextMessageSameSender: false, isThread: false)
                    .environment(\.layoutDirection, .leftToRight)
                    .environmentObject(AuthenticationService.preview)
                    .environmentObject(ContactRepository.preview)
            }
        }
    }
}
