//
//  ThreadListItem.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/25/21.
//

import Foundation

struct ThreadListItem: Identifiable {
    var id: String
    let thread: ChatThread
    let timestamp: Date
    let message: ChatMessage?
}

extension ThreadListItem {
    init(from thread: ChatThread) {
        self.id = thread.threadUid
        self.thread = thread
        self.message = thread.message
        self.timestamp = thread.message?.timestamp ?? thread.timestamp
    }
}

// MARK: - Comparable
extension ThreadListItem: Hashable {
    static func == (lhs: ThreadListItem, rhs: ThreadListItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
