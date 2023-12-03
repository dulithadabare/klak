//
//  SendImageView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-11.
//

import SwiftUI
import PromiseKit
import Amplify

struct SendImageView: View {
    var chat: ChatGroup
    var completion: (HwMessage) -> Void
    
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var persistenceController: PersistenceController
    @Environment(\.dismiss) private var dismiss
    @State private var showImagePicker: Bool = true
    @State private var selectedImage: UIImage? = nil
    @State private var showTappedImage: Bool = false
    @State private var tappedImage: UIImage? = nil
    @State private var size: CGSize = CGSize(width: 0, height: 50)
    
    func maxWidth(_ size: CGSize) -> CGFloat {
        return size.width * 5/6
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { reader in
                VStack {
                    if let selectedImage = selectedImage {
                       Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(nil, contentMode: .fit)
                    }
                    Spacer()
                    SendImageInputBarView(chat: chat, size: $size, onSend: send(_:))
                        .frame(height: size.height)
                }
                
            }
//            .background(.green)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }

                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        showImagePicker = true
                    } label: {
                        Text("Choose...")
                    }

                }
            }
            .sheet(isPresented: $showImagePicker) {
                PhotoPicker(selectedImage: $selectedImage)
            }
        }
    }
}

struct SendImageView_Previews: PreviewProvider {
    static var previews: some View {
        SendImageView(chat: ChatGroup.preview, completion: {_ in })
            .environmentObject(AuthenticationService.preview)
            .environmentObject(PersistenceController.preview)
    }
}

extension SendImageView {
    func send(_ message: HwMessage) {
        var message = message
        let fileName = "image_\(PushIdGenerator.shared.generatePushID()).jpeg"  // name of the image to be saved
        if let image = selectedImage,
           let _ = saveImageToDocumentDirectory(image: image, group: chat.group, fileName: fileName) {
            message.imageDocumentUrl = fileName
        }
        
        completion(message)
        dismiss()
    }

    func insertMessage(_ message: HwMessage, withReplyTo replyToItem: HwChatMessage?, chatMessageId: String, channel: String?, thread: String?, imageDocumentUrl: String?) -> Promise<Void> {
        let userId = authenticationService.userId!
        let phoneNumber = authenticationService.phoneNumber!
        let messageText = HwChatListItem.getAttributedString(from: message)
        let replyingToObjectId = replyToItem?.objectID
        let groupId = chat.group
        
        return persistenceController.enqueue { context in
            let item = HwChatMessage(context: context)
            
            item.author = userId
            item.sender = phoneNumber
            item.groupUid = groupId
            item.channelUid = channel
            item.threadUid = thread
            item.isSystemMessage = false
            item.messageId = chatMessageId
            item.timestamp = Date()
            item.text = messageText
            item.isReadByMe = true
            item.statusRawValue = MessageStatus.none.rawValue
            item.imageDocumentUrl = imageDocumentUrl
            
            if let replyingToObjectId = replyingToObjectId,
               let replyingToMessageItem = try? context.existingObject(with: replyingToObjectId),
            let replyingToMessage = replyingToMessageItem as? HwChatMessage {
                item.replyingTo = replyingToMessage
                replyingToMessage.addToReplies(item)
                replyingToMessage.replyCount += 1
                replyingToMessage.replyingThreadId = thread
            }
        }
    }
    
    func upload(image: UIImage, fileName: String) -> Promise<Void> {
        guard let data = image.pngData() else {
            return Promise.init(error: HamuwemuAuthError.imageCompressionError)
        }
        return Promise { seal in
            let _ = Amplify.Storage.uploadData(
                key: fileName,
                data: data,
                progressListener: { progress in
                    print("Progress: \(progress)")
                }, resultListener: { event in
                    switch event {
                    case .success(let data):
                        print("Completed: \(data)")
                        seal.fulfill(Void())
                    case .failure(let storageError):
                        print("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
                        seal.reject(storageError)
                    }
                }
            )
        }
    }
}
