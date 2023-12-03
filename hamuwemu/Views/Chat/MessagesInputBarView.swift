//
//  MessagesInputBarView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-17.
//

import SwiftUI
import InputBarAccessoryView

struct MessagesInputBarView: UIViewRepresentable {
    @Binding
    var size: CGSize
    @Binding
    var isFirstResponder: Bool
    @Binding
    var showImagePicker: Bool
    
    var send: (HwMessage) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MessagesInputBar {
        let bar = MessagesInputBar()
//        bar.setContentHuggingPriority(.required, for: .vertical)
//        bar.setContentHuggingPriority(.defaultHigh, for: .vertical)
        bar.delegate = context.coordinator
        bar.messagesInputBarDelegate = context.coordinator
        
        DispatchQueue.main.async {
            bar.inputTextView.placeholderLabel.text = String()
        }
        return bar
    }
    
    func updateUIView(_ uiView: MessagesInputBar, context: Context) {
//        print("ChannelInputBarView: updating view \(replyMessage?.id ?? "nil")")
        context.coordinator.control = self
    }
    
    func onSendPerform(_ message: HwMessage) {
        send(message)
    }
    
    class Coordinator {
        
        var control: MessagesInputBarView
        
        init(_ control: MessagesInputBarView) {
            self.control = control
        }
    }
}

extension MessagesInputBarView.Coordinator: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) {
        print("MessagesInputBarView: Coordinator size changed \(size)")
        control.size = size
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let message = getMessage(from: inputBar.inputTextView.attributedText!, with: text)
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
        control.onSendPerform(message)
        inputBar.inputTextView.text = ""
    }
}

extension MessagesInputBarView.Coordinator: MessagesInputBarViewDelegate {
    func showImagePicker() {
        control.showImagePicker = true
    }
    
    func sendModeChanged(_ value: Bool) {
        
    }
    
    func showAutocompleteView(_ value: Bool) {
       
    }
}

struct MessagesInputBarView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesInputBarView(size: .constant(CGSize(width: 0, height: 50)), isFirstResponder: .constant(false), showImagePicker: .constant(false), send: {_ in })
    }
}
