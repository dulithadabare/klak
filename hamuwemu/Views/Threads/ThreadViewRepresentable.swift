//
//  ThreadViewRepresentable.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/7/21.
//

import SwiftUI
import MessageKit

struct ThreadViewRepresentable: UIViewControllerRepresentable {
    @State var initialized = false
    @Binding var selectedReplyMessage: ChatMessage?
    var thread: ChatThread
    var chat: ChatGroup
    var channel: ChatChannel
    var contactRepository: ContactRepository
    
    func makeUIViewController(context: Context)
    -> ThreadViewController {
        let controller = ThreadViewController(thread: thread, chat: chat, channel: channel, contactRepository: contactRepository)
        controller.messageTappedDelegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(
        _ uiViewController: ThreadViewController,
        context: Context
    ) {
        print("ThreadViewController Updating VC")
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    final class Coordinator {
        var control: ThreadViewRepresentable
        
        init(_ control: ThreadViewRepresentable) {
            self.control = control
        }
    }
}

//struct ChannelViewRepresentable_Previews: PreviewProvider {
//    static var previews: some View {
//        ChannelViewRepresentable(model: ChannelView.Model())
//    }
//}

// MARK: - MessageTappedDelegate
extension ThreadViewRepresentable.Coordinator: MessageTappedDelegate {
    func messageTapped(with item: ThreadItem) {
        
    }
    
    func replyToMessage(_ message: ChatMessage) {
        control.selectedReplyMessage = message
    }
}
