//
//  AttributedTextLabel.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-26.
//

import SwiftUI

struct AttributedTextLabel: View {
    @State private var size: CGSize = .zero
    let attributedString: NSAttributedString
    let width: CGFloat
    
    init(_ attributedString: NSAttributedString, width: CGFloat) {
        self.attributedString = attributedString
        self.width = width
    }
    
    var body: some View {
        AttributedTextRepresentable(attributedString: attributedString, size: $size, maxWidth: width * 2/3)
            .frame(width: size.width, height: size.height)
//            .border(.red)
    }
    
    struct AttributedTextRepresentable: UIViewRepresentable {
        
        let attributedString: NSAttributedString
        @Binding var size: CGSize
        let maxWidth: CGFloat

        func makeUIView(context: Context) -> UILabel {
            let label = UILabel()
            
            label.lineBreakMode = .byWordWrapping
            label.numberOfLines = 2
            label.preferredMaxLayoutWidth = maxWidth

            return label
        }
        
        func updateUIView(_ uiView: UILabel, context: Context) {
            uiView.attributedText = attributedString
            
            DispatchQueue.main.async {
                size = uiView.sizeThatFits(uiView.superview?.bounds.size ?? .zero)
            }
        }
    }
}

//struct AttributedTextLabel_Previews: PreviewProvider {
//    static var previews: some View {
//        AttributedTextLabel(NSAttributedString())
//    }
//}
