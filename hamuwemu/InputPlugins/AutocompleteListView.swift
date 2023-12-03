//
//  AutocompleteListView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/20/21.
//

import SwiftUI
import InputBarAccessoryView

struct AutocompleteListView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @ObservedObject var dataModel: AutocompleteDataModel
    var body: some View {
        List(){
            ForEach(dataModel.items, id: \.self) { item in
                AutocompleteListItemView(attributedString: item.content)
                    .onTapGesture {
                        item.completion()
                    }
//                    .background(Color.red)
            }
            
        }
        .background(Color(UIColor.systemBackground))
        .frame(maxHeight: 44 * CGFloat(min(dataModel.items.count, verticalSizeClass == .compact ? 2 : 3)) )
    }
}

struct AutocompleteListView_Previews: PreviewProvider {
    static var previews: some View {
        AutocompleteListView(dataModel: AutocompleteDataModel())
    }
}

struct AutocompleteItem {
    let content: NSAttributedString
    let completion: () -> ()
}

extension AutocompleteItem: Hashable {
    static func == (lhs: AutocompleteItem, rhs: AutocompleteItem) -> Bool {
        return lhs.content == rhs.content
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(content)
    }
}

public class AutocompleteDataModel: ObservableObject {
    @Published var items: [AutocompleteItem] = []
    
    init() {
        #if DEBUG
        createDevData()
        #endif
    }
}


