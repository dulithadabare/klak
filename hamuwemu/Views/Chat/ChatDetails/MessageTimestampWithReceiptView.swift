//
//  MessageTimestampWithReceiptView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-04-06.
//

import SwiftUI

struct MessageTimestampWithReceiptView: View {
    var timestamp: Date
    @Binding var receipt: MessageStatus
    var messageLabelMaxWidth: CGFloat
    @Binding var messageLableSize: CGSize
    @Binding var moveTimestamp: Bool
    
    func isShortMessage() -> Bool {
        // message width + space (8) + timestamp width < maxWidth
        return  messageLableSize.width + 8 + 50 < messageLabelMaxWidth - 8 - 15 - 7
    }
    
    var body: some View {
        HStack(spacing: 0) {
            MessageStatusView(receipt: $receipt)
                .padding([.trailing], 5)
            Text(MessageDateFormatter.shared.messageTimestampFormatter.string(from: timestamp))
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(width: 16 + 5 + 50) // image width + padding + timestamp width
        .alignmentGuide(.trailing, computeValue: {d in isShortMessage() ? d[.leading] - 8 : d[.trailing] })
        .alignmentGuide(.bottom, computeValue: {d in moveTimestamp ? d[.bottom] - d.height - 5 : d[.bottom] })
    }
}

struct MessageStatusView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var receipt: MessageStatus
    var body: some View {
        Group {
            switch receipt {
            case .sent:
                Image("sent-receipt")
                    .resizable()
                    .scaledToFit()
            case .delivered:
                Image("delivered-receipt")
                    .resizable()
                    .scaledToFit()
            case .read:
                Image(colorScheme == .dark ?  "read-dark" : "read-light")
                    .resizable()
                    .scaledToFit()
            default:
                EmptyView()
            }
        }
        .frame(width: 16)
//        .font(.system(size: 8))
    }
}

struct MessageTimestampWithReceiptView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MessageTimestampWithReceiptView(timestamp: Date(), receipt: .constant(.sent), messageLabelMaxWidth: .zero, messageLableSize: .constant(.zero), moveTimestamp: .constant(false))
            MessageTimestampWithReceiptView(timestamp: Date(), receipt: .constant(.delivered), messageLabelMaxWidth: .zero, messageLableSize: .constant(.zero), moveTimestamp: .constant(false))
            MessageTimestampWithReceiptView(timestamp: Date(), receipt: .constant(.read), messageLabelMaxWidth: .zero, messageLableSize: .constant(.zero), moveTimestamp: .constant(false))
        }
        .background(Color(UIColor(rgb: 0xEBEBF54)))
        .previewLayout(.sizeThatFits)
    }
}
