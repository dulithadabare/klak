//
//  ChangeThreadTitleView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-10.
//

import SwiftUI
import CoreData
import PromiseKit

struct ChangeThreadTitleView: View {
    var thread: ChatThreadModel
    
    @EnvironmentObject private var authenticationService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @State private var isLoading: Bool = false
    
    func validate() -> Bool {
        if text.isEmpty {
            return false
        }
        
        //check if length < 30
        if text.utf16.count > 30 {
            return false
        }
        
        return true
    }
    
    func prompt() -> String {
        if text.utf16.count > 30 {
            return "Enter a name under 30 characters (Yours has \(text.utf16.count))."
        }
        
        return ""
    }
    
    func update() {
        if thread.isTemp {
            thread.title = NSAttributedString(string: text)
            dismiss()
        } else {
            thread.title = NSAttributedString(string: text)
            let model = UpdateThreadTitleModel(threadId: thread.threadUid, title: text)
            
            isLoading = true
            firstly {
                authenticationService.account.updateThreadTitle(model)
            }.then { _ in
                persist(model)
            }.done { _ in
                dismiss()
            }.ensure {
                isLoading = false
            }.catch { error in
                print("Error: Failed to perform update thread title \(error)")
            }
        }
    }
    
    func persist(_ model: UpdateThreadTitleModel) -> Promise<Void> {
        PersistenceController.shared.enqueue { context in
            let fetchRequest: NSFetchRequest<HwChatThread> = HwChatThread.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatThread.threadId), model.threadId)
            if let results = try? context.fetch(fetchRequest),
               let item = results.first {
                item.titleText = NSAttributedString(string: model.title)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Form {
                    Section(footer: Text(prompt()).foregroundColor(.red)) {
                        TextField("Thread Name", text: $text)
                            .disableAutocorrection(true)
    //                        .disabled(model.isLoading)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Edit Name")
                }
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        if isLoading {
                            ProgressView()
                        }
                        Button(action: {
                            update()
                        }) {
                            Text("Done")
                        }
                        .disabled(!validate() || isLoading)
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                    }
                }
            }
        }
    }
}

struct ChangeThreadTitleView_Previews: PreviewProvider {
    static var previews: some View {
        ChangeThreadTitleView(thread: ChatThreadModel.preview)
    }
}
