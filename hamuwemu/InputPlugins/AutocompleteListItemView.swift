//
//  AutocompleteListItemView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/20/21.
//

import SwiftUI

struct LabelView: View {
    var attributedText: NSAttributedString
    var body: some View {
        LabelViewRepresentable(attributedText: attributedText)
    }
}

struct LabelViewRepresentable: UIViewRepresentable {
    var attributedText: NSAttributedString
    var width: CGFloat? = nil
    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
//        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
                label.numberOfLines = 0
        if let width = width {
            label.preferredMaxLayoutWidth = width
        }
        return label
    }
    
    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.attributedText = attributedText
    }
    
}

struct AutocompleteListItemView: View {
    var attributedString: NSAttributedString
    var body: some View {
        HStack{
//            Text(attributedString.string)
            LabelView(attributedText: attributedString)
            Spacer()
//                .padding(.leading)
//            Divider()
        }
        .contentShape(Rectangle())
    }
}

struct AutocompleteListItemView_Previews: PreviewProvider {
    static var previews: some View {
        AutocompleteListItemView(attributedString: NSAttributedString(string: "Preview Item"))
    }
}
