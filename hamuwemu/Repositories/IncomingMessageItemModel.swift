//
//  IncomingMessageItemModel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-18.
//

import Foundation
import UIKit
import Combine
import PromiseKit
import Amplify

class IncomingMessageItemModel: MessageItemModel, ObservableObject {
    @Published var isLoading: Bool = false
    @Published var progress: Double = 0.0
    @Published var imageDocumentUrl: URL? = nil
    @Published var showAlert: Bool = false
    var alertMessage: String = ""
    
    var messageId: String
    var authenticationService: AuthenticationService
    var persistenceController: PersistenceController
    var contactRepository: ContactRepository
    var blurHashImage: UIImage?
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(inMemory: Bool = false, chat: ChatGroup, item: HwChatMessage) {
        self.messageId = item.messageId!
        if let imageKey = item.imageDocumentUrl {
            self.imageDocumentUrl = urlForImage(nameOfImage: imageKey, group: item.groupUid!)
        }
        
        if let imageBlurHash = item.imageThumbnailBase64 {
            self.blurHashImage = BlurHash.image(for: imageBlurHash)
        }
        
        authenticationService = inMemory ? AuthenticationService.preview : AuthenticationService.shared
        persistenceController = inMemory ? PersistenceController.preview : PersistenceController.shared
        contactRepository = inMemory ? ContactRepository.preview : ContactRepository.shared
        super.init(item: item)
        
        addSubscribers()
    }
    
    func addSubscribers() {
        
    }
    
    func performOnceOnAppear(inMemory: Bool = false, item: HwChatMessage) {
        self.item = item
    }
    
    func download() {
        guard let imageDownloadUrl = item.imageDownloadUrl,
              let group = item.groupUid,
              let messageId = item.messageId else {
            return
        }
        
        isLoading = true
        firstly {
            downloadImage(imageKey: imageDownloadUrl, group: group)
        }.then { imageKey in
            self.persistenceController.update(imageDocumentUrl: imageKey, for: messageId).map({ ($0, imageKey) })
        }.done { _, imageKey in
            self.imageDocumentUrl = urlForImage(nameOfImage: imageKey, group: group)
            print("IncomingMessagesImageView: downloaded")
        }.ensure {
            self.isLoading = false
        }.catch { error in
            print("IncomingMessagesImageView: failed to perform download")
            if let _ = error as? StorageError, let sender = self.item.sender {
                self.showAlert(with: "This image is no longer available. Please ask \(self.contactRepository.getFullName(for: sender)) to resend it.")
            }
        }
    }
    
    func downloadImage(imageKey: String, group: String) -> Promise<String> {
        let (promise, resolver) = Promise<String>.pending()

        guard let sender = item.sender,
              let senderPublicKey = item.senderPublicKey else {
                  resolver.reject(HamuwemuAuthError.missingPublicKey)
                  return promise
              }
        
        let userId = authenticationService.account.userId!
                
        let _ = Amplify.Storage.downloadData(
            key: imageKey,
            progressListener: { progress in
                DispatchQueue.main.async {
                    self.progress = progress.fractionCompleted
                }
                print("Progress: \(progress)")
            }, resultListener: { (event) in
                switch event {
                case let .success(data):
                    print("Completed: \(data)")
                    let decryptedData = EncryptionService.shared.decrypt(data: data, from: sender, senderPublicKey: senderPublicKey, inGroup: group, userId: userId)
                    let image = UIImage(data: decryptedData)!
                    _ = saveImageToDocumentDirectory(image: image, group: group, fileName: imageKey, saveToCameraRoll: true)
                    resolver.fulfill(imageKey)
                case let .failure(storageError):
                    print("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
                    resolver.reject(storageError)
            }
        })
        
        return promise
    }
    
    func showAlert(with message: String) {
        alertMessage = message
        showAlert = true
    }
    
}
