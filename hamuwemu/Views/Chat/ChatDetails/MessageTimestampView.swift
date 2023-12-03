//
//  MessageTimestampView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-15.
//

import SwiftUI

struct MessageTimestampView: View {
    var timestamp: Date
    var messageLabelMaxWidth: CGFloat
    @Binding var messageLableSize: CGSize
    @Binding var moveTimestamp: Bool
    
    func isShortMessage() -> Bool {
        // message width + space (8) + timestamp width < maxWidth
        return  messageLableSize.width + 8 + 50 < messageLabelMaxWidth - 8 - 15 - 7
    }
    
    var body: some View {
        Text(MessageDateFormatter.shared.messageTimestampFormatter.string(from: timestamp))
            .frame(width: 50)
            .font(.system(size: 10))
            .foregroundColor(.gray)
            .alignmentGuide(.trailing, computeValue: {d in isShortMessage() ? d[.leading] - 8 : d[.trailing] })
            .alignmentGuide(.bottom, computeValue: {d in moveTimestamp ? d[.bottom] - d.height - 5 : d[.bottom] })
    }
}

struct MessageTimestampView_Previews: PreviewProvider {
    static var previews: some View {
        MessageTimestampView(timestamp: Date(), messageLabelMaxWidth: .zero, messageLableSize: .constant(.zero), moveTimestamp: .constant(false))
    }
}
