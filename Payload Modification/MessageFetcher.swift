//
//  MessageFetcher.swift
//  Payload Modification
//
//  Created by Dulitha Dabare on 2022-04-15.
//

import Foundation
import PromiseKit

struct FetchMessageModel: Decodable {
    let data: [ServerPush]
}

class MessageFetchOperation: Operation {
    let promise: Promise<Void>
    let resolver: Resolver<Void>
    
    override init(){
        let (promise, resolver) = Promise<Void>.pending()
        self.promise = promise
        self.resolver = resolver
        super.init()
    }
    
    override func main() {
        if isCancelled {
            resolver.fulfill(Void())
            return
        }
        
        MessageFetcher.fetch(resolver: resolver)
    }
}

public class MessageFetcher {
    func run() -> Promise<Void> {
        // Use an operation queue to ensure that only one fetch cycle is done
        // at a time.
        let fetchOperation = MessageFetchOperation()
        // We don't want to re-fetch any messages that have
        // already been processed, so fetch operations should
        // block on "message ack" operations.  We accomplish
        // this by having our message fetch operations depend
        // on a no-op operation that flushes the "message ack"
        // operation queue.
        let flushAckOperation = Operation()
        flushAckOperation.queuePriority = .normal
        ackOperationQueue.addOperation(flushAckOperation)

        fetchOperation.addDependency(flushAckOperation)

        fetchOperationQueue.addOperation(fetchOperation)
        
        return fetchOperation.promise
    }
    
    // MARK: - Fetch
    
    // This operation queue ensures that only one fetch operation is
    // running at a given time.
    private let fetchOperationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.name = "MessageFetcherJob.fetchOperationQueue"
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    
    static func fetch(resolver: Resolver<Void>) {
        print("NotificationService: Starting fetch")
    
        firstly {
            getIdToken()
        }.then(on: .global()) { idToken in
            fetch(idToken: idToken)
        }.then(on: .global()) { messages in
            processMessages(messages)
        }.done { _ in
            print("NotificationService: Message Fetch completed")
            resolver.fulfill(Void())
        }
        .catch { error in
            print("Message Fetch failed \(error)")
            resolver.reject(error)
        }
    }
    
    static func processMessages(_ messages: FetchMessageModel) -> Promise<Void> {
        var promises = [Promise<Void>]()
        for message in messages.data {
            let promise = environment.messageHandler.process(message)
            promise.done(on:.global()) { _ in
                environment.messageFetcher.acknowledgeDelivery(messageId: message.id)
            }.catch(on:.global()) { error in
                print("NotificationService: could not perform handle for \(message.id)")
            }
            
            promises.append(promise)
        }
        
        return when(fulfilled: promises)

    }
    
    static func getIdToken() -> Promise<String> {
        do {
            try environment.auth.useUserAccessGroup("group.com.dabare.hamuwemu")
        } catch {
            print("Error while initializing Auth \(String(describing: error))")
                return .init(error: error)
        }
        
        guard let user = environment.auth.currentUser else {
            return .init(error: AuthError.userNil)
        }

        return Promise { seal in
            user.getIDToken { token, error in
                if let error = error {
//                    print("Error retrieving token: \(error.localizedDescription)")
                    seal.reject(error)
                    return
                }
                
                if let token = token {
                    seal.fulfill(token)
//                    print("token: \(token)")
                } else {
                    seal.reject(AuthError.idTokenNil)
                }
                
            }
        }
    }
    
    static func fetch(idToken: String) -> Promise<FetchMessageModel> {
        Promise { seal in
            let urlComponents = URLComponents(
                string: ApiConstants.baseUrlEndpoint + "messages")!
            var rq = URLRequest(url: urlComponents.url!)
            rq.httpMethod = "GET"
            rq.addValue("application/json", forHTTPHeaderField: "Content-Type")
            rq.addValue("application/json", forHTTPHeaderField: "Accept")
            rq.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            
            let task = URLSession.shared.dataTask(with: rq) { data, response, error in
                if let error = error {
                    seal.reject(error)
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                          seal.reject(ApiError.serverError)
                          return
                      }
                if let data = data {
                    do {
                        let resp = try JSONDecoder().decode(FetchMessageModel.self, from: data)
                        seal.fulfill(resp)
                    } catch {
                        seal.reject(error)
                    }
                }
                
                seal.reject(ApiError.serverError)
            }
            task.resume()
        }
    }
    
    static func makeUrlRequest<T: Encodable>(method: String, url: URL, obj: T?, idToken: String) throws -> URLRequest {
        var rq = URLRequest(url: url)
        rq.httpMethod = method
        rq.addValue("application/json", forHTTPHeaderField: "Content-Type")
        rq.addValue("application/json", forHTTPHeaderField: "Accept")
        rq.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        if let obj = obj {
            rq.httpBody = try JSONEncoder().encode(obj)
        }
        return rq
    }
    
    // MARK: - Ack
    
    class MessageAckOperation: Operation {
        var messageId: String
        private let pendingAck: PendingTask

        // A heuristic to quickly filter out multiple ack attempts for the same message
        // This doesn't affect correctness, just tries to guard against backing up our operation queue with repeat work
        static private var inFlightAcks = AtomicSet<String>()
        private var didRecordAckId = false
        private let inFlightAckId: String
        
        private static let unfairLock = UnfairLock()
        private static var successfulAckSet = OrderedSet<String>()
        private static func didAck(inFlightAckId: String) {
            unfairLock.withLock {
                successfulAckSet.append(inFlightAckId)
                // REST fetches are batches of 100.
                let maxAckCount: Int = 128
                while successfulAckSet.count > maxAckCount,
                      let firstAck = successfulAckSet.first {
                    successfulAckSet.remove(firstAck)
                }
            }
        }
        private static func hasAcked(inFlightAckId: String) -> Bool {
            unfairLock.withLock {
                successfulAckSet.contains(inFlightAckId)
            }
        }
        
        init?(_ messageId: String, pendingAcks: PendingTasks) {
            self.inFlightAckId = messageId
            guard !Self.hasAcked(inFlightAckId: inFlightAckId) else {
//                Logger.info("Skipping new ack operation for \(envelopeInfo). Duplicate ack already complete")
                return nil
            }
            guard !Self.inFlightAcks.contains(inFlightAckId) else {
//                Logger.info("Skipping new ack operation for \(envelopeInfo). Duplicate ack already enqueued")
                return nil
            }

            let pendingAck = pendingAcks.buildPendingTask(label: "Ack, messageId: \(messageId)")

            self.messageId = messageId
            self.pendingAck = pendingAck

            super.init()

            // MessageAckOperation must have a higher priority than than the
            // operations used to flush the ack operation queue.
            self.queuePriority = .high
            Self.inFlightAcks.insert(inFlightAckId)
            didRecordAckId = true
        }
        
        override func main() {
            if isCancelled {
                return
            }
            let inFlightAckId = self.inFlightAckId
            firstly {
                MessageFetcher.getIdToken()
            }.then(on: .global()) { idToken in
                MessageFetcher.ack(messageId: self.messageId, idToken: idToken)
            }.done(on: .global()) { _ in
                Self.didAck(inFlightAckId: inFlightAckId)
                print("NotificationService: ack success for \(self.messageId)")
                self.didComplete()
            }.catch(on: .global()) { error in
                print("NotificationService: ack failed for \(self.messageId)")
                self.didComplete()
            }
        }
        
        func didComplete() {
            if didRecordAckId {
                Self.inFlightAcks.remove(inFlightAckId)
            }
            pendingAck.complete()
        }
    }
    
    // We want to have multiple ACKs in flight at a time.
    private let ackOperationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.name = "MessageFetcherJob.ackOperationQueue"
        operationQueue.maxConcurrentOperationCount = 5
        return operationQueue
    }()
    
    private let pendingAcks = PendingTasks(label: "Acks")
    
    func acknowledgeDelivery(messageId: String) {
        guard let ackOperation = MessageAckOperation(messageId, pendingAcks: pendingAcks) else {
            return
        }
        ackOperationQueue.addOperation(ackOperation)
    }
    
    public func pendingAcksPromise() -> Promise<Void> {
        // This promise blocks on all operations already in the queue,
        // but will not block on new operations added after this promise
        // is created. That's intentional to ensure that NotificationService
        // instances complete in a timely way.
        pendingAcks.pendingTasksPromise()
    }
    
    static func ack(messageId: String, idToken: String) -> Promise<Void> {
        Promise { seal in
            let urlComponents = URLComponents(
                string: ApiConstants.baseUrlEndpoint + "ack")!
            do {
                let rq = try makeUrlRequest(method: "POST", url: urlComponents.url!, obj: AddAckModel(messageId: messageId), idToken: idToken)
                let task = URLSession.shared.dataTask(with: rq) { data, response, error in
                    if let error = error {
                        seal.reject(error)
                        return
                    }
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                              seal.reject(ApiError.serverError)
                              return
                          }
                    if let data = data {
                        do {
                            let resp = try JSONDecoder().decode(ApiResponse.self, from: data)
                            if resp.status == "ok" {
                                seal.fulfill(Void())
                            }
                        } catch {
                            seal.reject(error)
                        }
                    }
                    
                    seal.reject(ApiError.serverError)
                }
                task.resume()
                
            } catch {
                seal.reject(error)
            }
        }
    }
}
