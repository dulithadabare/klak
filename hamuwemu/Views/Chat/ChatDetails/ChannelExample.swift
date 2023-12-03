//
//  Channel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/1/21.
//

//import FirebaseFirestore
//
//struct ChannelExample {
//  let id: String?
//  let name: String
//
//  init(name: String) {
//    id = nil
//    self.name = name
//  }
//
//  init?(document: QueryDocumentSnapshot) {
//    let data = document.data()
//
//    guard let name = data["name"] as? String else {
//      return nil
//    }
//
//    id = document.documentID
//    self.name = name
//  }
//}
//
//// MARK: - DatabaseRepresentation
//extension ChannelExample: DatabaseRepresentation {
//  var representation: [String: Any] {
//    var rep = ["name": name]
//
//    if let id = id {
//      rep["id"] = id
//    }
//
//    return rep
//  }
//}
//
//// MARK: - Comparable
//extension ChannelExample: Comparable {
//  static func == (lhs: ChannelExample, rhs: ChannelExample) -> Bool {
//    return lhs.id == rhs.id
//  }
//
//  static func < (lhs: ChannelExample, rhs: ChannelExample) -> Bool {
//    return lhs.name < rhs.name
//  }
//}
