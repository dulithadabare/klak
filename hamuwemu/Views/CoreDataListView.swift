//
//  CoreDataListView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/27/21.
//

import SwiftUI

struct CoreDataListView: View {
    @FetchRequest(
        entity: HwChatGroup.entity(),
        sortDescriptors: [
//            NSSortDescriptor(keyPath: \ProgrammingLanguage.name, ascending: true),
//            NSSortDescriptor(keyPath: \ProgrammingLanguage.creator, ascending: false)
        ]
    ) var languages: FetchedResults<HwChatGroup>
    
    func add(){
      
    }
    
    var body: some View {
        List(languages, id: \.self) { language in
            LabelView(attributedText: language.lastMessageText ?? NSAttributedString(string: "sfsf"))
        }
    }
}

struct CoreDataListView_Previews: PreviewProvider {
    static var previews: some View {
        CoreDataListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
