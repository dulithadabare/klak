//
//  CurrentSenderImageView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-13.
//

import SwiftUI
import Kingfisher
import Amplify
import PromiseKit

struct CurrentSenderImageView: View {
    var imageDocumentUrl: URL?
    var group: String
    @Binding var isLoading: Bool
    @Binding var progress: Double
    
    @State private var coverImage: CoverImage? = nil
    @StateObject private var model = Model()
    
    
    var body: some View {
        if let provider = model.provider(for: imageDocumentUrl!, group: group) {
            ZStack {
                KFImage.dataProvider(provider)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .onTapGesture {
                        coverImage = CoverImage(url: imageDocumentUrl!)
                    }
                
//                AsyncImage(url: imageDocumentUrl) { image in
//                    image
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                        .onTapGesture {
//                            model.showFullScreenImage = true
//                        }
//                } placeholder: {
//                    ProgressView()
//                }

                
//                if let image = model.image {
//                    Image(uiImage: image)
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                        .onTapGesture {
//                            model.showFullScreenImage = true
//                        }
//                }
                if isLoading {
                    ProgressView(value: progress)
                }
            }
            .onAppear {
//                model.loadImage(for: imageDocumentUrl!, group: group)
            }
            .fullScreenCover(item: $coverImage, onDismiss: nil, content: { item in
                FullScreenImageView(imageUrl: item.url)
            })
        }
    }
}

struct CurrentSenderImageView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentSenderImageView(imageDocumentUrl: nil, group: "", isLoading: .constant(false), progress: .constant(0.5))
    }
}

extension CurrentSenderImageView {
    class Model: ObservableObject {
        @Published var isLoading: Bool = false
        @Published var progress: Double = 0.0
        @Published var image: UIImage? = nil
        @Published var showFullScreenImage: Bool = false
        
        private var provider: LocalFileImageDataProvider?
        
        func loadImage(for imageDocumentUrl: URL, group: String) {
            guard image == nil else {
                return
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                let image    = UIImage(contentsOfFile: imageDocumentUrl.path)
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
        
        func provider(for url: URL, group: String) -> LocalFileImageDataProvider? {
            guard provider == nil else {
                return provider
            }
            
            provider = LocalFileImageDataProvider(fileURL: url)
            return provider
                       
        }
    }
}
