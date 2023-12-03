//
//  ApiService.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-04-15.
//

import Foundation
import PromiseKit

class RESTApi {
    static func addUser(_ user: AddUserModel, idToken: String) -> Promise<AddUserModel> {
        let urlComponents = URLComponents(
            string: ApiConstants.baseUrlEndpoint + "users")!
        
        return firstly {
            URLSession.shared.dataTask(.promise, with: try makeUrlRequest(method: "POST", url: urlComponents.url!, obj: user, idToken: idToken)).validate()
        }.map {
            try JSONDecoder().decode(AddUserModel.self, from: $0.data)
        }
    }
    
    static func addUserToken(_ deviceToken: String, idToken: String) -> Promise<ApiResponse> {
        let token = AddTokenModel(deviceToken: deviceToken)
        let urlComponents = URLComponents(
          string: ApiConstants.baseUrlEndpoint + "tokens")!
        
        return firstly {
            URLSession.shared.dataTask(.promise, with: try makeUrlRequest(method: "POST", url: urlComponents.url!, obj: token, idToken: idToken)).validate()
        }.map {
            try JSONDecoder().decode(ApiResponse.self, from: $0.data)
        }
    }
    
    static func sync(_ contacts: [String], idToken: String) -> Promise<[AppUser]> {
        let urlComponents = URLComponents(
          string: ApiConstants.baseUrlEndpoint + "sync")!
        
        return firstly {
            URLSession.shared.dataTask(.promise, with: try makeUrlRequest(method: "POST", url: urlComponents.url!, obj: contacts, idToken: idToken)).validate()
        }.map {
            try JSONDecoder().decode([AppUser].self, from: $0.data)
        }
    }
    
    static func ack(messageId: String, idToken: String) -> Promise<ApiResponse> {
        let urlComponents = URLComponents(
            string: ApiConstants.baseUrlEndpoint + "ack")!
        return firstly {
            dataTaskPromise(request: try makeUrlRequest(method: "POST", url: urlComponents.url!, obj: AddAckModel(messageId: messageId), idToken: idToken))
        }
    }
    
    static func updateThreadTitle(_ model: UpdateThreadTitleModel, idToken: String) -> Promise<ApiResponse> {
        let urlComponents = URLComponents(
            string: ApiConstants.baseUrlEndpoint + "threads/\(model.threadId)/title")!
        
        return firstly {
            URLSession.shared.dataTask(.promise, with: try makeUrlRequest(method: "PUT", url: urlComponents.url!, obj: model, idToken: idToken)).validate()
        }.map {
            try JSONDecoder().decode(ApiResponse.self, from: $0.data)
        }
    }
    
    static func deleteAccount(idToken: String) -> Promise<ApiResponse> {
        let urlComponents = URLComponents(
            string: ApiConstants.baseUrlEndpoint + "accounts")!
        
        return firstly {
            URLSession.shared.dataTask(.promise, with: try makeUrlRequest(method: "DELETE", url: urlComponents.url!, idToken: idToken)).validate()
        }.map {
            try JSONDecoder().decode(ApiResponse.self, from: $0.data)
        }
    }
    
    static func dataTaskPromise<T: Decodable>(request: URLRequest) -> Promise<T> {
        Promise { seal in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
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
                        let resp = try JSONDecoder().decode(T.self, from: data)
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
    
//        static func addGroup( _ chat: ChatGroup) -> Promise<String> {
//            let urlComponents = URLComponents(
//              string: baseURLString + "groups/")!
//
//            return firstly {
//                URLSession.shared.dataTask(.promise, with: try makeUrlRequest(url: urlComponents.url!, obj: chat)).validate()
//            }.map {
//                try JSONDecoder().decode(String.self, from: $0.data)
//            }
//
////            return Promise{ seal in
////                guard chat.isTemp else {
////                    seal.fulfill(chat.group)
////                    return
////                }
////
////                firstly {
////                    URLSession.shared.dataTask(.promise, with: try makeUrlRequest(url: urlComponents.url!, obj: chat)).validate()
////                }.map {
////                    try JSONDecoder().decode(String.self, from: $0.data)
////                }.done{ result in
////                    seal.fulfill(result)
////                }.catch { e in
////                    seal.reject(ApiError.errorCreatingChatGroup(error: e))
////                }
////            }
//
//
//
////            return Future { promise in
////                guard let uploadData = try? encoder.encode(chat) else {
////                    promise(.failure(ApiError.jsonEncodeError))
////                    return
////                }
////
////                let urlComponents = URLComponents(
////                  string: baseURLString + "groups/")!
////                var request = URLRequest(url: urlComponents.url!)
////                request.httpMethod = "POST"
////                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
////
////                let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
////                    if let error = error {
////                        print ("error: \(error)")
////                        promise(.failure(error))
////                        return
////                    }
////                    guard let response = response as? HTTPURLResponse,
////                        (200...299).contains(response.statusCode) else {
////                        print ("server error")
////                        promise(.failure(ApiError.serverError))
////                        return
////                    }
////                    if let mimeType = response.mimeType,
////                        mimeType == "application/json",
////                        let data = data,
////                        let dataString = String(data: data, encoding: .utf8) {
////                        print ("got data: \(dataString)")
////                        promise(.success(dataString))
////                    }
////                }
////                task.resume()
////
////            }
//        }
    
    struct ChatIdResult: Decodable {
        let chatIds: [ChatIdModel]
    }
    
    static func loadContactIds(userId: String, idToken: String) -> Promise<ChatIdResult> {
        let urlComponents = URLComponents(
          string: ApiConstants.baseUrlEndpoint + "chatIds")!
        
        var rq = URLRequest(url: urlComponents.url!)
        rq.httpMethod = "GET"
        rq.addValue("application/json", forHTTPHeaderField: "Content-Type")
        rq.addValue("application/json", forHTTPHeaderField: "Accept")
        rq.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        
        return firstly {
            URLSession.shared.dataTask(.promise, with: rq).validate()
        }.map {
            try JSONDecoder().decode(ChatIdResult.self, from: $0.data)
        }
    }
    
//        static func addReadReceipts(receipts: [ReadReceipt]) -> Promise<[ReadReceipt]> {
//            return Promise{ seal in
//                guard !receipts.isEmpty else {
//                    seal.fulfill([])
//                    return
//                }
//
//                let model = AddReadReceiptModel(receipts: receipts)
//                let urlComponents = URLComponents(
//                  string: baseURLString + "read")!
//
//
//                firstly {
//                    URLSession.shared.dataTask(.promise, with: try makeUrlRequest(url: urlComponents.url!, obj: model)).validate()
//                }.map {
//                    try JSONDecoder().decode(ApiResponse.self, from: $0.data)
//                }.done{ _ in
//                    seal.fulfill(receipts)
//                }.catch { _ in
//                    seal.reject(ApiError.errorSendingMessage)
//                }
//            }
//        }
    
//        static func sendMessage(_ message: HwMessage, messageId: String, group: String, channel: String?, thread: String?, replyingTo: String?) -> Promise<String> {
//            guard let userID = authenticationService.user?.uid,
//                  let phoneNumber = authenticationService.user?.phoneNumber else { return Promise(error: AuthError.userIdNil) }
//
//            let model = AddMessageModel(id: messageId, author: userID, sender: phoneNumber, timestamp: Date(), channel: channel, group: group, message: message, thread: thread, replyingInThreadTo: replyingTo)
//
//
//            let urlComponents = URLComponents(
//              string: baseURLString + "messages/")!
//
//            return Promise{ seal in
//                firstly {
//                    URLSession.shared.dataTask(.promise, with: try makeUrlRequest(url: urlComponents.url!, obj: model)).validate()
//                }.map {
//                    try JSONDecoder().decode(String.self, from: $0.data)
//                }.done{ result in
//                    seal.fulfill(result)
//                }.catch { _ in
//                    seal.reject(ApiError.errorSendingMessage)
//                }
//            }
//        }
    
    static func makeUrlRequest(method: String, url: URL, idToken: String) throws -> URLRequest {
        var rq = URLRequest(url: url)
        rq.httpMethod = method
        rq.addValue("application/json", forHTTPHeaderField: "Content-Type")
        rq.addValue("application/json", forHTTPHeaderField: "Accept")
        rq.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        
        return rq
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
    
    static func addThread(group: String, members: [String: AppUser], replyingTo: String?){
//            let thread = AddThreadModel(threadUid: <#T##String#>, title: <#T##HwMessage#>, replyingTo: <#T##String?#>, members: <#T##[String : AppUser]#>)
    }
    
    static func addDemoWorkspace(_ workspace: AddWorkspaceModel, idToken: String) -> Promise<AddGroupModel> {
        let urlComponents = URLComponents(
            string: ApiConstants.baseUrlEndpoint + "workspaces")!
        
        return firstly {
            URLSession.shared.dataTask(.promise, with: try makeUrlRequest(method: "POST", url: urlComponents.url!, obj: workspace, idToken: idToken)).validate()
        }.map {
            try JSONDecoder().decode(AddGroupModel.self, from: $0.data)
        }
    }
}
