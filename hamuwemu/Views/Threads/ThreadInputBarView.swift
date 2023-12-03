//
//  ThreadInputBarView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/23/21.
//

import SwiftUI
import InputBarAccessoryView

//struct ThreadInputBarView_Previews: PreviewProvider {
//    static var previews: some View {
//        ThreadInputBarView()
//    }
//}

struct ThreadInputBarView: UIViewRepresentable {
    @Binding
    var showAutocompleteView: Bool
    
    @Binding
    var size: CGSize
    
    var thread: ChatThread
    var chat: ChatGroup
    var channel: ChatChannel
    var contactRepository: ContactRepository
    var dataModel: AutocompleteDataModel
    
    var onSendPerform: (HwMessage) -> ()
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> InputBarAccessoryView {
        let bar = ThreadInputBar(chat: chat, contactRepository: contactRepository, dataModel: dataModel)
        bar.delegate = context.coordinator
        bar.autocompleteViewDelegate = context.coordinator
        DispatchQueue.main.async {
            bar.inputTextView.placeholderLabel.text = String()
        }
        return bar
    }
    
    func updateUIView(_ uiView: InputBarAccessoryView, context: Context) {
        context.coordinator.control = self
    }
    
    func onSendPerform(_ message: HwMessage) {
        
    }
    
    class Coordinator {
        
        var control: ThreadInputBarView
        
        init(_ control: ThreadInputBarView) {
            self.control = control
        }
    }
}

extension ThreadInputBarView.Coordinator: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) {
        print("ChannelInputBar: Coordinator size changed \(size)")
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

extension ThreadInputBarView.Coordinator: AutocompleteViewDelegate {
    func showAutocompleteView(_ value: Bool) {
        control.showAutocompleteView = value
    }
}
