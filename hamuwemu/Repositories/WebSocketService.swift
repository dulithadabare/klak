//
//  WebSocketService.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-02-09.
//

import Foundation
import Network
import CoreData
import SwiftUI

struct ClientProtocolCommand: Encodable {
    var id: UInt32 = 0
    
    var method: ClientProtocolCommand.MethodType = .connect
    
    var params: Data = Data()
    
    enum MethodType: Int, Encodable {
        case connect // = 0
        case subscribe // = 1
        case unsubscribe // = 2
        case publish // = 3
        case presence // = 4
        case presenceStats // = 5
        case history // = 6
        case ping // = 7
        case send // = 8
        case rpc // = 9
        case refresh // = 10
        case subRefresh // = 11
    }
}

struct Centrifugal_Centrifuge_Protocol_PublishRequest {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.
    var channel: String = String()
    
    var data: Data = Data()
    
    init() {}
}

struct CentrifugeDisconnectOptions: Decodable {
    var reason: String
    var reconnect: Bool
}

public enum CentrifugeError: Error {
    case timeout
    case duplicateSub
    case disconnected
    case unsubscribed
    case replyError(code: UInt32, message: String)
}

struct CentrifugeResolveData {
    var error: Error?
    var reply: ClientReplyModel?
}

public struct CentrifugePublishResult {}


struct TempServerPush: Decodable {
    let id: String
}

public enum ClientNetworkStatus {
    case connecting, disconnected, connected
    case waitingForNetwork
    case notConnecting
}

public enum CentrifugeClientStatus {
    case new
    case connected
    case disconnected
}

public struct CentrifugeClientConfig {
    public var timeout = 5.0
    public var debug = false
    public var headers = [String:String]()
    public var tlsSkipVerify = false
    public var maxReconnectDelay = 20.0
    public var privateChannelPrefix = "$"
    public var pingInterval = 25.0
    public var name = "swift"
    public var version = ""
    
    public init() {}
}

class InMemoryWebSocketService: WebSocketService {
    override func connect(idToken: String) {
        networkStatus = .waitingForNetwork
        syncQueue.asyncAfter(deadline: .now() + 2, execute: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.status = .connected
//            DispatchQueue.main.async { [weak self] in
//                    guard let strongSelf = self else { return }
//                strongSelf.networkStatus = .connected
//            }
        })
    }
    
    override func disconnect() {
        print("disconnect")
    }
}


class WebSocketService: ObservableObject {
    //    private init(){}
    
//    private var socket: WebSocket
    @Published var networkStatus: ClientNetworkStatus = .disconnected
    var isConnected: Bool = false
    let persistenceController: PersistenceController = PersistenceController.shared
    let reachability = NetworkReachability()
    /* create monitor queue */
    let monitorQueue = DispatchQueue.init(label: "monitor queue", qos: .userInitiated)
    
    //    static let shared = WebSocketService()
    //    static let preview: WebSocketService = {
    //        let service = WebSocketService(inMemory: true)
    //        return service
    //    }()
    
    //MARK -
    fileprivate(set) var url: String
    fileprivate(set) var userId: String
    fileprivate(set) var phoneNumber: String
    fileprivate(set) var syncQueue: DispatchQueue
    fileprivate(set) var config: CentrifugeClientConfig
    
    //MARK -
    fileprivate var status: CentrifugeClientStatus = .new {
        didSet {
            switch status {
            case .new:
                DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else { return }
                    strongSelf.networkStatus = .connecting
                }
            case .connected:
                DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else { return }
                    strongSelf.networkStatus = .connected
                }
            case .disconnected:
                DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else { return }
                    strongSelf.networkStatus = .disconnected
                }
            }
        }
    }
    fileprivate var conn: WebSocket?
    fileprivate var token: String?
    fileprivate var connectData: Data?
    fileprivate var commandId: UInt32 = 0
    fileprivate var commandIdLock: NSLock = NSLock()
    fileprivate var opCallbacks: [UInt32: ((CentrifugeResolveData) -> ())] = [:]
    fileprivate var connectCallbacks: [String: ((Error?) -> ())] = [:]
    fileprivate var needReconnect = true
    fileprivate var numReconnectAttempts = 0
    fileprivate var pingTimer: DispatchSourceTimer?
    fileprivate var disconnectOpts: CentrifugeDisconnectOptions?
    fileprivate var refreshTask: DispatchWorkItem?
    fileprivate var connecting = false {
        didSet {
            let newValue = connecting
            DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return }
                if !oldValue {
                    strongSelf.networkStatus = newValue ?  .connecting : .disconnected
                } else {
                    strongSelf.networkStatus = newValue ? .connecting : .connected
                }
            }
        }
    }
    fileprivate var messageHandler: MessageHandler
    
    init(inMemory: Bool = false, userId: String, phoneNumber: String, config: CentrifugeClientConfig = CentrifugeClientConfig()){
//        url = "wss://api.hamuwemu.app/ws"
        #if targetEnvironment(simulator)
           // code for the simulator here
        url = ApiConstants.websocketEndpoint
        #else
           // code for real devices here
        url = ApiConstants.websocketEndpoint
        #endif
        
//        url = "wss://api.hamuwemu.app/ws"
        self.userId = userId
        self.phoneNumber = phoneNumber
        self.config = config
        let queueID = UUID().uuidString
        self.syncQueue = DispatchQueue(label: "com.dulithadabare.hamuwemu.sync<\(queueID)>")
        messageHandler = MessageHandler(userId: userId)
//        var request = URLRequest(url: URL(string: "wss://api.hamuwemu.com/ws")!)
//        request.timeoutInterval = 5
//        request.setValue(userId, forHTTPHeaderField: "User-Id")
//        socket = WebSocket(request: request)
//        socket.connect()
//        connect()
    }
    
    deinit {
        disconnect()
    }
    
    /**
     Publish message Data to channel
     - parameter channel: String channel name
     - parameter data: Data message data
     - parameter completion: Completion block
     */
    public func publish(channel: String, data: Data, completion: @escaping (CentrifugePublishResult?, Error?)->()) {
        self.syncQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.waitForConnect(completion: { [weak self] error in
                guard let strongSelf = self else { return }
                if let err = error {
                    completion(nil, err)
                    return
                }
                let command = strongSelf.newCommand(method: .addGroup, params: data)
                strongSelf.sendCommand(command: command, completion: { [weak self] reply, error in
                    guard let _ = self else { return }
                    if let err = error {
                        completion(nil, err)
                        return
                    }
                    if let rep = reply {
                        if rep.hasError {
                            completion(nil, CentrifugeError.replyError(code: rep.error.code, message: rep.error.message))
                            return
                        }
                        
                        completion(CentrifugePublishResult(), error)
                    }
                })
            })
        }
    }
    
    /**
     Connect to server
     */
    public func connect(idToken: String) {
        self.syncQueue.async{ [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.connecting == false else { return }
            strongSelf.connecting = true
            strongSelf.needReconnect = true
            var request = URLRequest(url: URL(string: strongSelf.url)!)
            request.timeoutInterval = 5
            request.setValue(strongSelf.userId, forHTTPHeaderField: "User-Id")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            let ws = WebSocket(request: request)
            ws.onConnect = { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.onOpen()
            }
            ws.onDisconnect = { [weak self] (error: Error?) in
                guard let strongSelf = self else { return }
                let decoder = JSONDecoder()
                var serverDisconnect: CentrifugeDisconnectOptions?
                if let err = error as? WSError {
                    do {
                        let disconnect = try decoder.decode(CentrifugeDisconnectOptions.self, from: err.message.data(using: .utf8)!)
                        serverDisconnect = disconnect
                    } catch {}
                }
                strongSelf.onClose(serverDisconnect: serverDisconnect)
            }
            ws.onData = { [weak self] data in
                guard let strongSelf = self else { return }
                strongSelf.onData(data: data)
            }
            
            ws.onText =  { [weak self] text in
                guard let strongSelf = self else { return }
                strongSelf.onText(text: text)
            }
            
            strongSelf.conn = ws
            strongSelf.conn?.connect()
        }
    }
    
    /**
     Disconnect from server
     */
    public func disconnect() {
        self.syncQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.needReconnect = false
            strongSelf.close(reason: "clean disconnect", reconnect: false)
        }
    }
}

fileprivate extension WebSocketService {
    func onOpen() {
        self.syncQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.connecting = false
            strongSelf.status = .connected
            strongSelf.numReconnectAttempts = 0
            for cb in strongSelf.connectCallbacks.values {
                cb(nil)
            }
            strongSelf.connectCallbacks.removeAll(keepingCapacity: true)
            // Process server-side subscriptions.
            strongSelf.startPing()
        }
    }
    
    func onData(data: Data) {
        print("Received data: \(data.count)")
        self.syncQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.handleData(data as Data)
        }
    }
    
    func onText(text: String) {
//        print("Received text: \(text)")
        let jsonData = text.data(using: .utf8)!
        self.syncQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.handleData(jsonData as Data)
        }
    }
    
    func onClose(serverDisconnect: CentrifugeDisconnectOptions?) {
        self.syncQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            
            let reachable = strongSelf.reachability.checkConnection()
            if !reachable {
                DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else { return }
                    strongSelf.networkStatus = .waitingForNetwork
                }
            }
            
            let disconnect: CentrifugeDisconnectOptions = serverDisconnect
            ?? strongSelf.disconnectOpts
            ?? CentrifugeDisconnectOptions(reason: "connection closed", reconnect: true)
            
            strongSelf.connecting = false
            strongSelf.disconnectOpts = nil
            let reconnect = reachable ? disconnect.reconnect : false
            strongSelf.scheduleDisconnect(reason: disconnect.reason, reconnect: reconnect)
        }
    }
    
    private func startNetworkMonitor(){
        let monitor = NWPathMonitor()
        
        /* closure called when path changes */
        let pathUpdateHandler = {[weak self]  (path:NWPath) in
            guard let strongSelf = self else {
                return
            }
            let availableInterfaces = path.availableInterfaces
            
            if !availableInterfaces.isEmpty {
                //e.g. [ipsec4, en0, pdp_ip0]
                let list = availableInterfaces.map { $0.debugDescription }.joined(separator: "\n")
            }
            
            if path.status == .satisfied {
                monitor.cancel()
                strongSelf.scheduleReconnect()
            }
            
            var status = "undetermined"
            switch path.status {
            case .requiresConnection:
                status =  "requires connection"
            case .satisfied:
                status = "satisfied"
            case .unsatisfied:
                status = "unsatisfied"
            }
        }
        
        /* set the closure */
        monitor.pathUpdateHandler = pathUpdateHandler
        
        /* start monitoring for changes */
        monitor.start(queue: monitorQueue)
    }
    
    private func startPing() {
        if self.config.pingInterval == 0 {
            return
        }
        self.pingTimer = DispatchSource.makeTimerSource()
        self.pingTimer?.setEventHandler { [weak self] in
            guard let strongSelf = self else { return }
            let command = strongSelf.newCommand(method: .ping, params: Data())
            strongSelf.sendCommand(command: command, completion: { [weak self] res, error in
                guard let strongSelf = self else { return }
                if let err = error {
                    switch err {
                    case CentrifugeError.timeout:
                        strongSelf.close(reason: "no ping", reconnect: true)
                        return
                    default:
                        // Nothing to do.
                        return
                    }
                }
            })
        }
        self.pingTimer?.schedule(deadline: .now() + self.config.pingInterval, repeating: self.config.pingInterval)
        self.pingTimer?.resume()
    }
    
    private func stopPing() {
        self.pingTimer?.cancel()
    }
    
    func close(reason: String, reconnect: Bool) {
        self.disconnectOpts = CentrifugeDisconnectOptions(reason: reason, reconnect: reconnect)
        self.conn?.disconnect()
    }
    
    private func nextCommandId() -> UInt32 {
        self.commandIdLock.lock()
        self.commandId += 1
        let cid = self.commandId
        self.commandIdLock.unlock()
        return cid
    }
    
    private func newCommand(method: ClientPushType, params: Any) -> ClientPushModel {
        let nextId = self.nextCommandId()
        return ClientPushModel(id: nextId, type: method, data: params)
    }
    
    private func sendCommand(command: ClientPushModel, completion: @escaping (ClientReplyModel?, Error?)->()) {
        self.syncQueue.async {
            do {
                let data = try JSONEncoder().encode(command)
                self.conn?.write(data: data)
                self.waitForReply(id: command.id, completion: completion)
            } catch {
                completion(nil, error)
                return
            }
        }
    }
    
    private func sendCommandAsync(command: ClientPushModel) throws {
        let data = try JSONEncoder().encode(command)
        self.conn?.write(data: data)
    }
    
    private func waitForReply(id: UInt32, completion: @escaping (ClientReplyModel?, Error?)->()) {
        let timeoutTask = DispatchWorkItem { [weak self] in
            self?.opCallbacks[id] = nil
            completion(nil, CentrifugeError.timeout)
        }
        self.syncQueue.asyncAfter(deadline: .now() + self.config.timeout, execute: timeoutTask)
        
        self.opCallbacks[id] = { [weak self] rep in
            timeoutTask.cancel()
            
            self?.opCallbacks[id] = nil
            
            if let err = rep.error {
                completion(nil, err)
            } else {
                completion(rep.reply, nil)
            }
        }
    }
    
    private func waitForConnect(completion: @escaping (Error?)->()) {
        if !self.needReconnect {
            completion(CentrifugeError.disconnected)
            return
        }
        if self.status == .connected {
            completion(nil)
            return
        }
        
        let uid = UUID().uuidString
        
        let timeoutTask = DispatchWorkItem { [weak self] in
            self?.connectCallbacks[uid] = nil
            completion(CentrifugeError.timeout)
        }
        self.syncQueue.asyncAfter(deadline: .now() + self.config.timeout, execute: timeoutTask)
        
        self.connectCallbacks[uid] = { error in
            timeoutTask.cancel()
            completion(error)
        }
    }
    
    private func scheduleReconnect() {
        self.syncQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.connecting = true
            // TODO: add jitter here
            let delay = 0.05 + min(pow(Double(strongSelf.numReconnectAttempts), 2), strongSelf.config.maxReconnectDelay)
            strongSelf.numReconnectAttempts += 1
            strongSelf.syncQueue.asyncAfter(deadline: .now() + delay, execute: { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.syncQueue.async { [weak self] in
                    guard let strongSelf = self else { return }
                    if strongSelf.needReconnect {
                        strongSelf.conn?.connect()
                    } else {
                        strongSelf.connecting = false
                    }
                }
            })
        }
    }
    
    private func scheduleDisconnect(reason: String, reconnect: Bool) {
        self.status = .disconnected
        
        for resolveFunc in self.opCallbacks.values {
            resolveFunc(CentrifugeResolveData(error: CentrifugeError.disconnected, reply: nil))
        }
        self.opCallbacks.removeAll(keepingCapacity: true)
        
        for resolveFunc in self.connectCallbacks.values {
            resolveFunc(CentrifugeError.disconnected)
        }
        self.connectCallbacks.removeAll(keepingCapacity: true)
        
        self.stopPing()
        
        if reconnect {
            self.scheduleReconnect()
        }
    }
}

extension WebSocketService {
    func write(type: ClientPushType, data: Any, completion: @escaping (CentrifugePublishResult?, Error?)->()){
        self.syncQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.waitForConnect(completion: { [weak self] error in
                guard let strongSelf = self else { return }
                if let err = error {
                    completion(nil, err)
                    return
                }
                let command = strongSelf.newCommand(method: type, params: data)
                strongSelf.sendCommand(command: command, completion: { [weak self] reply, error in
                    guard let _ = self else { return }
                    if let err = error {
                        completion(nil, err)
                        return
                    }
                    if let rep = reply {
                        if rep.hasError {
                            completion(nil, CentrifugeError.replyError(code: rep.error.code, message: rep.error.message))
                            return
                        }
                        
                        completion(CentrifugePublishResult(), error)
                    }
                })
            })
        }
    }
    
    func writeAsync(type: ClientPushType, data: Any, completion: @escaping (Error?)->()){
        self.syncQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.waitForConnect(completion: { [weak self] error in
                guard let strongSelf = self else { return }
                if let err = error {
                    completion(err)
                    return
                }
                do {
                    let command = strongSelf.newCommand(method: type, params: data)
                    try strongSelf.sendCommandAsync(command: command)
                    completion(nil)
                } catch {
                    completion(error)
                }
            })
        }
    }
    
    func ack(messageId: String, completion: @escaping (Error?)->()) throws {
//        print("Ack: \(messageId)")
        writeAsync(type: .ack, data: messageId, completion: completion)
    }
}

extension WebSocketService {
    //    func websocketDidConnect(socket: WebSocketClient) {
    //        isConnected = true
    //        print("websocket is connected")
    //    }
    //
    //    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
    //        isConnected = false
    //        print("websocket is disconnected")
    //        handleError(error)
    //    }
    //
    //    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
    //        print("Received text: \(text)")
    //        let jsonData = text.data(using: .utf8)!
    //        handleData(jsonData)
    //    }
    //
    //    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
    //        print("Received data: \(data.count)")
    //    }
    
    
    
    
    //    func didReceive(event: WebSocketEvent, client: WebSocket) {
    //        switch event {
    //        case .connected(let headers):
    //            isConnected = true
    //            print("websocket is connected: \(headers)")
    //        case .disconnected(let reason, let code):
    //            isConnected = false
    //            print("websocket is disconnected: \(reason) with code: \(code)")
    //        case .text(let string):
    //            print("Received text: \(string)")
    //            let jsonData = string.data(using: .utf8)!
    //            handleData(jsonData)
    //        case .binary(let data):
    //            print("Received data: \(data.count)")
    //        case .ping(_):
    //            break
    //        case .pong(_):
    //            break
    //        case .viabilityChanged(_):
    //            break
    //        case .reconnectSuggested(_):
    //            break
    //        case .cancelled:
    //            isConnected = false
    //        case .error(let error):
    //            isConnected = false
    //            handleError(error)
    //        }
    //    }
    
    private func handleError(_ error: Error?) {
        if let e = error as? WSError {
            print("websocket encountered an error: \(e.message)")
        } else if let e = error {
            print("websocket encountered an error: \(e.localizedDescription)")
        } else {
            print("websocket encountered an error")
        }
    }
    
    private func handleData(_ data: Data) {
        do {
            _ = try JSONDecoder().decode(ServerPush.self, from: data)
        } catch {
            print(error)
        }
        
        if let serverPush = try? JSONDecoder().decode(ServerPush.self, from: data){
            print("Received serverPush: \(serverPush.type)")
            if serverPush.type == .reply {
                let reply = serverPush.data as! ClientReplyModel
                if reply.id > 0 {
                    self.opCallbacks[reply.id]?(CentrifugeResolveData(error: nil, reply: reply))
                }
            } else {
                _ = messageHandler.process(serverPush)
                try! ack(messageId: serverPush.id, completion: { error in
                    if let error = error {
                        print("Unknown error occured: \(error)")
                    }
                })
            }
          
        } else {
            print("Incorrect message format")
            //           if let serverPush = try? JSONDecoder().decode(TempServerPush.self, from: data) {
            //               try! ack(messageId: serverPush.id)
            //           }
        }
    }
    
}
