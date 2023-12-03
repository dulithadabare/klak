//
//  MessageItemModel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-16.
//

import UIKit
import PromiseKit
import Amplify
import Combine
import Sentry

class MessageItemModel: Identifiable, Equatable {
    static func == (lhs: MessageItemModel, rhs: MessageItemModel) -> Bool {
        lhs.id == rhs.id
    }
    
    var id: String {
        item.messageId!
    }
    var item: HwChatMessage
    
    init(inMemory: Bool = false, item: HwChatMessage) {
        self.item = item
    }
}


class OutgoingMessageItemModel: MessageItemModel, ObservableObject {
    @Published var isUploading: Bool = false
    @Published var progress: Double = 0.0
    
    var messageId: String
    var receiver: String
    var imageDocumentUrl: URL?
    var authenticationService: AuthenticationService
    @Published var status: MessageStatus = .none
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(inMemory: Bool = false, chat: ChatGroup, item: HwChatMessage) {
        self.messageId = item.messageId!
        self.receiver = chat.groupName
        self.status = MessageStatus(rawValue: item.statusRawValue) ?? .none
        if let imageKey = item.imageDocumentUrl {
            self.imageDocumentUrl = urlForImage(nameOfImage: imageKey, group: item.groupUid!)
        }
        
        authenticationService = inMemory ? AuthenticationService.preview : AuthenticationService.shared
        
        super.init(item: item)
        
        addSubscribers()
    }
    
    func addSubscribers() {
        guard status != .read else {
            return
        }
        
        item.publisher(for: \.statusRawValue).sink { statusRawValue in
            if let status = MessageStatus(rawValue: statusRawValue) {
                print("CurrentSenderMessageView: status \(statusRawValue)")
                // Delay to remove insert animation lag
                self.status = status
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//
//                }
                
            }
        }.store(in: &cancellables)
    }
    
    func performOnceOnAppear(inMemory: Bool = false, item: HwChatMessage) {
        self.item = item
    }
    
    func send() {
        guard status == .none else {
            return
        }
        
        if let imageKey = item.imageDocumentUrl {
            send(with: imageKey)
        } else {
            firstly {
                send(message: HwMessage(content: item.text!.string, mentions: [], links: [], imageDocumentUrl: nil, imageDownloadUrl: nil, imageBlurHash: nil))
            }.then{ receipt in
                MessageHandler(userId: self.authenticationService.account.userId!).updateMessageStatus(receipt)
            }.done { _ in
                print("CurrentSenderMessageView: sent")
            }.catch { error in
                print("CurrentSenderMessageView: failed to perform send \(error)")
                self.status = .errorSendingMessage
                SentrySDK.capture(error: error)
            }
        }
    }
    
    private func send(with imageKey: String) {
        guard let imageKey = item.imageDocumentUrl else {
            return
        }
        
        isUploading = true
        firstly {
            upload(fileName: imageKey)
        }.then { imageKey in
            BlurHash.getBlurHash(for: imageKey, group: self.item.groupUid!).map({($0, imageKey)})
        }.then { imageBlurHash, imageKey in
            self.send(message: HwMessage(content: self.item.text?.string, mentions: [], links: [], imageDocumentUrl: nil, imageDownloadUrl: imageKey, imageBlurHash: imageBlurHash))
        }.then{ receipt in
            MessageHandler(userId: self.authenticationService.account.userId!).updateMessageStatus(receipt)
        }.done { _ in
            print("CurrentSenderMessageView: sent")
        }.ensure {
            self.isUploading = false
        }.catch { error in
            print("CurrentSenderMessageView: failed to perform send \(error)")
            self.status = .errorSendingMessage
            SentrySDK.capture(error: error)
        }
    }
    
    
    private func upload(fileName: String) -> Promise<String> {
        let (promise, resolver) = Promise<String>.pending()
        guard let originalImage = loadImageFromDocumentDirectory(nameOfImage: fileName, group: item.groupUid!),
              let image = originalImage.scaledToSafeUploadSize,
              let data = image.jpeg(.highest) else {
                return Promise.init(error: HamuwemuAuthError.imageCompressionError)
        }
        
        let encryptedData = EncryptionService.shared.encrypt(data: data, for: receiver, inGroup: item.groupUid!, userId: authenticationService.account.userId!)
        
        let _ = Amplify.Storage.uploadData(
            key: fileName,
            data: encryptedData,
            progressListener: { progress in
                print("CurrentSenderImageView: Progress: \(progress)")
                DispatchQueue.main.async {
                    self.progress = progress.fractionCompleted
                }
            }, resultListener: { event in
                switch event {
                case .success(let data):
                    print("CurrentSenderImageView: Completed: \(data)")
                    resolver.fulfill(fileName)
                case .failure(let storageError):
                    print("CurrentSenderImageView: Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
                    resolver.reject(storageError)
                }
            }
        )
        
        return promise
    }
    
    private func send(message: HwMessage) -> Promise<MessageReceiptModel> {
        Promise { seal in
            authenticationService.account.sendMessage(message, messageId: item.messageId!, group: item.groupUid!, channel: item.channelUid, thread: item.threadUid, replyingTo: item.replyingTo?.messageId, receiver: receiver){ _, error in
                if let error = error {
                    print("ChannelMessagesView Error: \(error)")
                    seal.reject(error)
                    return
                }
                
                seal.fulfill(MessageReceiptModel(type: .sent, appUser: nil, messageId: self.item.messageId!))
            }
        }
    }

//    func loadImageFromDocumentDirectory(nameOfImage : String) -> UIImage? {
//    //            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
//    //            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
//    //            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
//    //            if let dirPath = paths.first{
//    //                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(nameOfImage)
//    //                let image    = UIImage(contentsOfFile: imageURL.path)
//    //                return image!
//    //            }
//        if let imageURL = FileManager.documentURL?.appendingPathComponent(nameOfImage),
//           let image    = UIImage(contentsOfFile: imageURL.path) {
//            return image
//        }
//
//        return nil
//    }
    
}
