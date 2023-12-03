//
//  CurrentMessageSenderView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-01-06.
//

import SwiftUI
import PromiseKit
import Amplify
import Kingfisher

struct WidthPreferenceKey: PreferenceKey {
    static var defaultValue = CGFloat(0)
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
    
    typealias Value = CGFloat
}

struct TextGeometry: View {
    var body: some View {
        GeometryReader { geometry in
            return Rectangle().fill(Color.clear).preference(key: WidthPreferenceKey.self, value: geometry.size.width)
        }
    }
}

struct ReplyingToLineShape: Shape {
    var isCurrSender: Bool = true
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = CGFloat(10)
        //        let endX = rect.midX/2
        
        // bottom border start point
        path.move(to: CGPoint(x: rect.midX/2, y: rect.maxY))
        // center
        path.addLine(to: CGPoint(x: rect.midX/2, y: rect.midY + radius))
        
        if isCurrSender {
            let hLineStart = CGPoint(x: rect.midX/2 + radius, y: rect.midY)
            path.addQuadCurve(to: hLineStart, control: CGPoint(x: rect.midX/2, y: rect.midY ))
            //        path.addArc(center: CGPoint(x: rect.midX + 20, y: rect.midY - 20), radius: 20, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        } else {
            path.addQuadCurve(to: CGPoint(x: rect.midX/2 - radius, y: rect.midY), control: CGPoint(x: rect.midX/2, y: rect.midY ))
            //        path.addArc(center: CGPoint(x: rect.midX + 20, y: rect.midY - 20), radius: 20, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        }
        
        
        
        return path
    }
}

struct ReplyThreadShape: Shape {
    var isCurrSender: Bool = true
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = CGFloat(10)
        // top border start point
        path.move(to: CGPoint(x: rect.midX/2, y: rect.minY))
        // center
        path.addLine(to: CGPoint(x: rect.midX/2, y: rect.midY - radius))
        
        if isCurrSender {
            let hLineStart = CGPoint(x: rect.midX/2 + radius, y: rect.midY)
            path.addQuadCurve(to: hLineStart, control: CGPoint(x: rect.midX/2, y: rect.midY ))
            //        path.addArc(center: CGPoint(x: rect.midX + 20, y: rect.midY - 20), radius: 20, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        } else {
            path.addQuadCurve(to: CGPoint(x: rect.midX/2 - radius, y: rect.midY), control: CGPoint(x: rect.midX/2, y: rect.midY ))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        }
        
        
        
        return path
    }
}

struct CurrentMessageSenderView: View {
    @ObservedObject var model: OutgoingMessageItemModel
    @Binding var selectedReplyItem: ReplyItem?
    var maxWidth: CGFloat
    var isPreviousMessageSameSender: Bool
    var isNextMessageSameSender: Bool
    var scrollToItem: (String) -> ()
    var isThread: Bool = false
    var isDuo: Bool = false
    @Binding var coverImage: CoverImage?
    
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var contactRespository: ContactRepository
    @EnvironmentObject private var authenticationService: AuthenticationService
    @State private var parentTextViewWiddth: CGFloat = CGFloat(0)
    @State private var mainTextViewWiddth: CGFloat = CGFloat(0)
    @State private var childTextViewWiddth: CGFloat = .zero
    @State private var maxTextViewWiddth: CGFloat = .zero
    @State private var timestampTextViewWiddth: CGFloat = .zero
    @State private var messageLabelSize: CGSize = .zero
    @State private var moveTimestamp: Bool = false
    @State private var isLoading: Bool = false
    
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
        return  (messageLabelSize.width + 8 + 50 < maxMessageLabelWidth - 8 - 15 - 7) && model.item.imageDocumentUrl == nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
//            Text("\(item.messageId!)")
            //            if isPreviousMessageDifferentDay {
            //                LabelView(attributedText: NSAttributedString(string: dateFormatter.string(from: item.timestamp!), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray]))
            //                    .frame(height: 18)
            //            }
//            Text("okokokokokokokokokokookokok")
//                .background(TextGeometry())
//                .onPreferenceChange(WidthPreferenceKey.self, perform: { value in
//                    mainTextViewWiddth = value
//                })
            
            //frame debugging
//            Text("mainText: \(modifiedAttributedString(from: item.text!, contactRepository: contactRespository, authenticationService: .preview).string)")
//            Text("mainTextViewWidth \(mainTextViewWiddth.description)")
//            Text("parentTextViewWidth \(parentTextViewWiddth.description)")
//            Text("childTextViewWidth \(childTextViewWiddth.description)")
            HStack {
                Spacer(minLength: maxWidth * (1/6))
                VStack(alignment: .leading, spacing: 0) {
//                    if let replyingTo = item.replyingTo {
//
//                        HStack {
//                            ReplyingToLineShape()
//                                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
//                                .foregroundColor(Color(UIColor.secondaryLabel))
//                                .frame(width: 30, height: 40 )
//                            //                            .frame(maxWidth: mainTextViewWiddth * (1/5), maxHeight: 40 )
//                            //                            .frame(width: 200, height: 80 )
//                            VStack(alignment: .leading){
//                                Text(contactRespository.getFullName(for: item.sender!) ?? item.sender!)
//                                    .font(.system(size: 12, weight: .bold, design: .default))
//                                    .foregroundColor(Color(UIColor.secondaryLabel))
//
//                                Text(modifiedAttributedString(from: replyingTo.text!, contactRepository: contactRespository, authenticationService: authenticationService).string)
//                                    .lineLimit(1)
//                                    .font(.footnote)
//                                    .foregroundColor(Color(UIColor.secondaryLabel))
//                            }
//                            .padding(7)
//                            .background(RoundedRectangle(cornerRadius: 8)
//                                            .fill(Color(UIColor.secondarySystemBackground)))
//                        }
//                        .background(TextGeometry())
//                        .onPreferenceChange(WidthPreferenceKey.self, perform: { value in
//                            parentTextViewWiddth = value
//                        })
//                        .onTapGesture {
//                            scrollToItem(replyingTo.messageId!)
//                        }
//
//                    }
                    VStack(alignment: .leading, spacing: 0) {
                        
                        
                        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom)) {
                            VStack(alignment: .leading, spacing: 0) {
                                if let imageDocumentUrl = model.imageDocumentUrl {
                                    CurrentSenderImageView(imageDocumentUrl: imageDocumentUrl, group: model.item.groupUid!, isLoading: $model.isUploading, progress: $model.progress)
                                    //                                    .clipped()
                                        .frame(maxWidth: maxImageViewWidth, maxHeight: 300, alignment: .topLeading)
                                        .cornerRadius(8)
                                        .contentShape(TapShape())
                                        .padding(EdgeInsets(top: 3, leading: 3, bottom: 3, trailing: 11)) // radius (8) + 3 = 11
//                                        .border(.blue)
                                        
                                }
                                
                                if let text = model.item.text, !text.string.isEmpty {
                                    IncomingMessageLabelView(attributedText: text, maxWidth: (maxMessageLabelWidth - 8 - 15 - 7 ), timestampWidth: 16 + 5 + 50, timestamp: model.item.timestamp!, size: $messageLabelSize, moveTimestamp: $moveTimestamp)
                                        .frame(width: min(messageLabelSize.width, maxMessageLabelWidth), height: messageLabelSize.height)
                                        .padding(EdgeInsets(top: model.item.imageDocumentUrl == nil ? 7 : 0, leading: 7, bottom: 5, trailing: 15))
                                }
                            }
                            HStack(spacing: 0) {
                                MessageStatusView(receipt: $model.status)
                                    .padding([.trailing], 5)
                                Text(MessageDateFormatter.shared.messageTimestampFormatter.string(from: model.item.timestamp!))
                                    .font(.system(size: 10))
                                    .foregroundColor( model.item.text == nil || model.item.text!.string.isEmpty ? .primary : .secondary)
                            }
                            .padding(EdgeInsets(top: model.item.imageDocumentUrl == nil ? 7 : 0, leading: 7, bottom: 5, trailing: 15))
                            .alignmentGuide(.bottom, computeValue: {d in moveTimestamp ? d[.bottom] - d.height - 5 : d[.bottom] })
                            .alignmentGuide(.trailing, computeValue: {d in isShortMessage ? d[.leading] - 8 : d[.trailing] })
                            
                            
//                            MessageTimestampWithReceiptView(timestamp: model.item.timestamp!, receipt: $model.status, messageLabelMaxWidth: maxMessageLabelWidth, messageLableSize: $messageLabelSize, moveTimestamp: $moveTimestamp)
                                

                            //                            .frame(alignment: .bottomTrailing)
                            //                            .padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 2))
                        }
//                        .border(.red)
//                        .padding(EdgeInsets(top: 7, leading: 7, bottom: 5, trailing: 15))
//                        .clipped()
                        
                        
                        
//                        .contextMenu {
//                            Button {
//                                selectedReplyItem = ReplyItem(item: item)
//                            } label: {
//                                Label("Reply", systemImage: "arrowshape.turn.up.left")
//                            }
//
//                            if !isThread{
//                                Button {
//                                    selectedReplyItem = ReplyItem(item: item, isThreadReply: true)
//                                } label: {
//                                    Label("Reply in Thread", systemImage: "number.square")
//                                }
//                            }
//
//                            Button {
//                                print("Forward")
//                            } label: {
//                                Label("Forward", systemImage: "arrowshape.turn.up.forward")
//                            }
//                        }
                        //                        HStack(alignment: .lastTextBaseline) {
                        //                            Text("Live")
                        //                                .font(.caption)
                        //                            Text("long")
                        //                            Text("and")
                        //                                .font(.title)
                        //                            Text("prosper")
                        //                                .font(.largeTitle)
                        //                        }
                        //
                        //                        VStack(alignment: .leading) {
                        //                                    Text("Hello, world!")
                        //                                    Text("This is a longer line of text")
                        //                                }
                        //                                .background(Color.red)
                        //                                .frame(width: 400, height: 400)
                        //                                .background(Color.blue)
                    }
                    .background(CurrentSenderMessageShape(isFromCurrentSender: true, addTail: !isPreviousMessageSameSender)
                                    .fill( colorScheme == .dark ? Color(UIColor(rgb: 0x1D8663)) :  Color(UIColor(red: 0.803, green: 0.99, blue: 0.780, alpha: 1))
                                         ))
                    .background(TextGeometry())
                    .onPreferenceChange(WidthPreferenceKey.self, perform: { value in
                        mainTextViewWiddth = value
                    })
                    
//                    if let latestReply = item.replies?.lastObject as? HwChatMessage {
//                        NavigationLink(destination: LazyDestination {
//                            ThreadDetailView(model: getThreadDetailViewModel(for: item.threadUid!))
//                        }) {
//                            HStack {
//                                ReplyThreadShape()
//                                    .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
//                                    .foregroundColor(Color(UIColor.secondaryLabel))
//                                    .frame(width: 30, height: 40 )
//                                VStack(alignment: .leading){
//                                    Text(contactRespository.getFullName(for: item.sender!) ?? item.sender!)
//                                        .font(.system(size: 12, weight: .bold, design: .default))
//                                        .foregroundColor(Color(UIColor.secondaryLabel))
//
//                                    Text(modifiedAttributedString(from: latestReply.text!, contactRepository: contactRespository, authenticationService: .preview).string)
//                                        .lineLimit(1)
//                                        .font(.footnote)
//                                        .foregroundColor(Color(UIColor.secondaryLabel))
//                                }
//                                .padding(7)
//                                .background(RoundedRectangle(cornerRadius: 8)
//                                                .fill(Color(UIColor.secondarySystemBackground)))
//                            }
//                            .background(TextGeometry())
//                            .onPreferenceChange(WidthPreferenceKey.self, perform: { value in
//                                childTextViewWiddth = value
//                            })
//                        }
//                    }
                }
                //                        .frame(width: max(mainTextViewWiddth, parentTextViewWiddth, childTextViewWiddth, timestampTextViewWiddth), alignment: .leading  )
            }
        }
        .onAppear {
           
        }
    }
}

struct CurrentMessageSenderView_Previews: PreviewProvider {
    static let shortContent = "Hello @Dulitha Dabare"
    static let longContent = "Hello @Dulitha Dabare lllllllllllllllllllllllllllll lllllllllllllllllllllllllllll lllllllllllllllllllllllllllll llllllllllllllp"
    static let longMessage = SampleData.shared.getMessageForPreview( managedObjectContext: PersistenceController.preview.container.viewContext, text: SampleData.shared.longMentionMessage)
    static let longMessageWithShortLastLine = SampleData.shared.getMessageForPreview( managedObjectContext: PersistenceController.preview.container.viewContext, text: SampleData.shared.longMessageWithShortLastLine)
    static let shorterThanTimestampItem = SampleData.shared.getMessage( managedObjectContext: PersistenceController.preview.container.viewContext, text: "ok")
    static let shorterThanTimestampItemWithTopReply = SampleData.shared.getMessageWithParent(managedObjectContext: PersistenceController.preview.container.viewContext, message: "ok")
    static let shorterThanTimestampItemWithBottomReply = SampleData.shared.getMessageWithChild(managedObjectContext: PersistenceController.preview.container.viewContext, message: "ok")
    
    static let longerThanTimestampItemWithReply = SampleData.shared.getMessageWithThreadReply(managedObjectContext: PersistenceController.preview.container.viewContext, message: "okokok")
    static let shorterThanTimestampItemWithReply = SampleData.shared.getMessageWithThreadReply(managedObjectContext: PersistenceController.preview.container.viewContext, message: "ok")
    static let scrollToItem: (String) -> () = { item in
    }
    static var previews: some View {
        Group {
            GeometryReader { proxy in
                CurrentMessageSenderView(model: OutgoingMessageItemModel(inMemory: true, chat: ChatGroup.preview, item: longMessage), selectedReplyItem: .constant(nil), maxWidth: proxy.size.width, isPreviousMessageSameSender: false, isNextMessageSameSender: false, scrollToItem: scrollToItem, coverImage: .constant(nil))
                    .environment(\.layoutDirection, .leftToRight)
                    .environmentObject(ContactRepository.preview)
                    .environmentObject(AuthenticationService.preview)
            }
            .preferredColorScheme(.dark)
            
            GeometryReader { proxy in
                CurrentMessageSenderView(model: OutgoingMessageItemModel(inMemory: true, chat: ChatGroup.preview, item: longMessageWithShortLastLine), selectedReplyItem: .constant(nil), maxWidth: proxy.size.width, isPreviousMessageSameSender: false, isNextMessageSameSender: false, scrollToItem: scrollToItem, coverImage: .constant(nil))
                    .environment(\.layoutDirection, .leftToRight)
                    .environmentObject(ContactRepository.preview)
                    .environmentObject(AuthenticationService.preview)
            }
            GeometryReader { proxy in
                CurrentMessageSenderView(model: OutgoingMessageItemModel(inMemory: true, chat: ChatGroup.preview, item: longerThanTimestampItemWithReply), selectedReplyItem: .constant(nil), maxWidth: proxy.size.width, isPreviousMessageSameSender: false, isNextMessageSameSender: false, scrollToItem: scrollToItem, coverImage: .constant(nil))
                    .environment(\.layoutDirection, .leftToRight)
                    .environmentObject(AuthenticationService.preview)
                    .environmentObject(ContactRepository.preview)
            }
        }
    }
}
