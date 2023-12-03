//
//  AddTaskView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-06-16.
//

import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var persistenceController: PersistenceController
    @State private var title: String = ""
    @State private var messageText: String = ""
    @State private var isUrgent = false
    @State private var dueDate: Date = .now
    @State private var assignedTo: String? = nil
    @State private var assignedGroup: String = ""
    @State private var initialized = false
    @State private var members: [AppUser] = []
    @State private var groups: [ChatGroup] = []
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    TextField("Title", text: $title)
                    TextField("Message", text: $messageText)
                    Section(header: Text("Details")) {
                        DatePicker(
                            "Start Date",
                            selection: $dueDate,
                            displayedComponents: [.date]
                        )
                        Toggle("Urgent", isOn: $isUrgent)
                        Picker("Assigned To", selection: $assignedTo) {
                            ForEach(members, id:\.uid) { member in
                                Text(member.phoneNumber).tag(member.uid as String?)
                            }
                        }
                        Picker("Group", selection: $assignedGroup) {
                            ForEach(groups, id:\.group) { group in
                                Text(group.groupName).tag(group.group)
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("New Task")
                        .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }

                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        send()
                    } label: {
                        Text("Send")
                    }

                }
            }
        }
        .onAppear {
            guard !initialized else {
                return
            }
            
            loadAppContacts()
            loadChatGroups()
        }
    }
}

struct AddTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AddTaskView()
            .environmentObject(AuthenticationService.preview)
            .environmentObject(PersistenceController.preview)
    }
}

import CoreData
import PromiseKit
import HealthKit

extension AddTaskView {
    func loadAppContacts(){
        let fetchRequest: NSFetchRequest<HwGroupMember> = HwGroupMember.fetchRequest()
        if let results = try? persistenceController.container.viewContext.fetch(fetchRequest) {
            var appContacts = [AppUser]()
            for hwItem in results {
                let appContact = AppUser(uid: hwItem.uid!, phoneNumber: hwItem.phoneNumber!)
                appContacts.append(appContact)
            }
            
            DispatchQueue.main.async {
//                        self.members = members
                self.members = appContacts
            }
        }
    }
    
    func loadChatGroups(){
        let fetchRequest: NSFetchRequest<HwChatGroup> = HwChatGroup.fetchRequest()
        if let results = try? persistenceController.container.viewContext.fetch(fetchRequest) {
            var chatGroups = [ChatGroup]()
            for hwItem in results {
//                let appContact = AppUser(uid: hwItem.uid!, phoneNumber: hwItem.phoneNumber!)
                chatGroups.append(ChatGroup(from: hwItem))
            }
            
            DispatchQueue.main.async {
//                        self.members = members
                self.groups = chatGroups
            }
        }
    }
    
    func mergeMessages(prefixMessage: HwMessage, suffixMessage: HwMessage) -> HwMessage {
        let messageContent = "\(prefixMessage.content!) \(suffixMessage.content!)"
        var messageMentions: [Mention] = prefixMessage.mentions
        var messageTaskMentions: [Mention] = prefixMessage.taskMentions
        
        for mention in suffixMessage.mentions {
            var mention =  mention
            mention.range = NSMakeRange("\(prefixMessage.content!) ".utf16.count + mention.range.location, mention.range.length)
            messageMentions.append(mention)
        }
        
        for mention in suffixMessage.taskMentions {
            var mention =  mention
            mention.range = NSMakeRange("\(prefixMessage.content!) ".utf16.count + mention.range.location, mention.range.length)
            messageTaskMentions.append(mention)
        }
        
        return HwMessage(content: messageContent, mentions: messageMentions, taskMentions: messageTaskMentions, links: [], imageDocumentUrl: nil, imageDownloadUrl: nil, imageBlurHash: nil)
    }
    
    
    func send() {
        guard let assignedTo = assignedTo else {
            return
        }
        
        let message = HwMessage(content: messageText, mentions: [], links: [], imageDocumentUrl: nil, imageDownloadUrl: nil, imageBlurHash: nil)
        let chatGroup = groups.first(where: {$0.group == assignedGroup})!
        let taskUid = PushIdGenerator.shared.generatePushID()
        let task = AddTaskModel(id: taskUid, title: title, message: message, assignedTo: assignedTo, assignedBy: authenticationService.account.user!.uid, isUrgent: isUrgent, dueDate: dueDate, groupUid: assignedGroup)
        let logItem = AddTaskLogItemModel(id: PushIdGenerator.shared.generatePushID(), task: task, message: message, createdBy: authenticationService.account.user!.uid, status: .open, pendingDueDate: nil, timestamp: .now)
        
        let prefixContent = "Assigned #\(title) to @\(assignedTo)"
        let prefixMention = Mention(range: NSMakeRange("Assigned #\(title) to ".utf16.count, "@\(assignedTo)".utf16.count), uid: assignedTo, phoneNumber: assignedTo)
        let prefixTaskMention = Mention(range: NSMakeRange("Assigned ".utf16.count, "#\(title)".utf16.count), uid: taskUid, phoneNumber: taskUid, taskTitle: title)
        let prefixMessage = HwMessage(content: prefixContent, mentions: [prefixMention], taskMentions: [prefixTaskMention], links: [], imageDocumentUrl: nil, imageDownloadUrl: nil, imageBlurHash: nil)
        
        let addMessageModel = AddMessageModel(id: PushIdGenerator.shared.generatePushID(), author: authenticationService.account.userId!, sender: authenticationService.account.phoneNumber!, timestamp: .now, channel: chatGroup.defaultChannel.channelUid, group: chatGroup.group, message: mergeMessages(prefixMessage: prefixMessage, suffixMessage: message), thread: nil, replyingInThreadTo: nil, senderPublicKey: authenticationService.account.getPublicKey()!.base64EncodedString(), isOutgoingMessage: true)
        
        
        _ = persistenceController.insertTask(task)
        _ = persistenceController.insertTaskLogItem(logItem)
        _ = persistenceController.insertMessage(addMessageModel)
        
        authenticationService.account.sendTaskLogItem(logItem) { result, error in
            print("AddTaskView: sent task")
        }
        authenticationService.account.sendMessage(addMessageModel.message, messageId: addMessageModel.id, group: addMessageModel.group, channel: addMessageModel.channel, thread: addMessageModel.thread, replyingTo: addMessageModel.replyingInThreadTo, receiver: addMessageModel.group){ result, error in
            if let error = error {
                print("AddTaskView Error: \(error)")
                return
            }
        }
        
        dismiss()
        
    }
}

extension AddTaskView {
    class Model: ObservableObject {
        @Published var members: [AppUser] = []
        
        private var persistenceController: PersistenceController!
        private var authenticationService: AuthenticationService!
        init() {
            
        }
        
        func performOnceOnAppear(persistenceController: PersistenceController, authenticationService: AuthenticationService) {
            self.persistenceController = persistenceController
            self.authenticationService = authenticationService
            loadAppContacts()
        }
        
        func loadAppContacts(){
            let fetchRequest: NSFetchRequest<HwGroupMember> = HwGroupMember.fetchRequest()
            if let results = try? persistenceController.container.viewContext.fetch(fetchRequest) {
                var appContacts = [AppUser]()
                for hwItem in results {
                    let appContact = AppUser(uid: hwItem.uid!, phoneNumber: hwItem.phoneNumber!)
                    appContacts.append(appContact)
                }
                
                DispatchQueue.main.async {
//                        self.members = members
                    self.members = appContacts
                }
            }
        }
    }
}
