//
//  MessageSender.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-16.
//

import UIKit
import Amplify

class MessageSender {
    // This operation queue ensures that only one fetch operation is
    // running at a given time.
    private let sendOperationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.name = "MessageSender.sendOperationQueue"
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
}

class MessageSendOperation: Operation {
    var messageId: String
    var text: String?
    var groupUid: String
    var channelUid: String?
    var threadUid: String?
    var replyingTo: String?
    var receiver: String
    var authenticationService: AuthenticationService
    var success: () -> Void
    var error: (Error) -> Void
    var progress: ((Progress) -> Void)?
    
    init(inMemory: Bool = false, messageId: String, text: String, groupUid: String, channelUid: String?, threadUid: String, replyingTo: String, receiver: String, success: @escaping () -> Void, error: @escaping (Error) -> Void, progress: ((Progress) -> Void)?) {
        self.messageId = messageId
        self.text = text
        self.groupUid = groupUid
        self.channelUid = channelUid
        self.threadUid = threadUid
        self.replyingTo = replyingTo
        self.receiver = receiver
        self.success = success
        self.error = error
        self.progress = progress
        authenticationService = inMemory ? AuthenticationService.preview : AuthenticationService.shared
        
        super.init()
    }
    
    override func main() {
        if isCancelled {
            return
        }
        
//        MessageFetcher.fetch(resolver: resolver)
    }
}
