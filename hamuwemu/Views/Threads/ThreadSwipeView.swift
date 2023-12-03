//
//  ThreadSwipeView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-04-20.
//

import SwiftUI

struct ThreadSwipeView<Content: View>: View {
    var index: Int
    var size: CGSize
    var stackOffsetX: CGFloat
    var dragDistanceX: CGFloat
    var content: () -> Content
    
    private var currOffsetX: CGFloat {
        (CGFloat(index) * size.width) - stackOffsetX + dragDistanceX
    }
    
    init(index: Int, size: CGSize, stackOffsetX: CGFloat, dragDistanceX: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.index = index
        self.size = size
        self.stackOffsetX = stackOffsetX
        self.dragDistanceX = dragDistanceX
        self.content = content
    }
    var body: some View {
        content()
            .offset(x: currOffsetX)
    }
}

struct ThreadSwipeView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { proxy in
            ThreadSwipeView(index: 0, size: proxy.size, stackOffsetX: .zero, dragDistanceX: .zero){
                TestMessagesView(chat: ChatGroup.preview, threadId: ChatThreadModel.preview.threadUid)
            }
        }
    }
}
