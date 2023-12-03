//
//  ImageGalleryView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-18.
//

import SwiftUI

struct ImageGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    var image: UIImage?
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizableView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }

            }
        }
    }
}

struct ImageGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        ImageGalleryView(image: nil)
    }
}
