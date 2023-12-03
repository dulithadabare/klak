//
//  IncomingMessageImageView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-18.
//

import SwiftUI
import Kingfisher

struct IncomingMessageImageView: View {
    var blurHashImage: UIImage?
    @Binding var imageDocumentUrl: URL?
    @Binding var isLoading: Bool
    @Binding var progress: Double
    
    var download: () -> Void

    @State private var coverImage: CoverImage? = nil
    @StateObject private var model = Model()
    
    var body: some View {
        ZStack {
//                KFImage.dataProvider(provider)
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
            
            if let imageDocumentUrl = imageDocumentUrl {
//                AsyncImage(url: imageDocumentUrl) { image in
//
//                    image
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                        .onTapGesture {
//                            model.showFullScreenImage = true
//                        }
//                } placeholder: {
//                    ProgressView()
//                }
                
                KFImage.dataProvider(LocalFileImageDataProvider(fileURL: imageDocumentUrl))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .onTapGesture {
                        coverImage = CoverImage(url: imageDocumentUrl)
                    }

//                if let image = model.image {
//                    Image(uiImage: image)
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                        .onTapGesture {
//                            model.showFullScreenImage = true
//                        }
//                }
                
            } else if let blurredImage = blurHashImage {
                Image(uiImage: blurredImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            
            if isLoading {
                ProgressView(value: progress)
                    .padding()
            } else if imageDocumentUrl == nil {
                Button {
                    download()
                } label: {
                    Text("Download")
                }
                .buttonStyle(.bordered)
            }
        }
        .onChange(of: imageDocumentUrl, perform: { url in
            if let url = url {
                model.loadImage(for: url)
            }
        })
        .onAppear {
            if let imageDocumentUrl = imageDocumentUrl {
                model.loadImage(for: imageDocumentUrl)
            }
        }
        .fullScreenCover(item: $coverImage, onDismiss: nil, content: { item in
            FullScreenImageView(imageUrl: item.url)
        })
    }
}

struct IncomingMessageImageView_Previews: PreviewProvider {
    static var previews: some View {
        IncomingMessageImageView(blurHashImage: nil, imageDocumentUrl: .constant(nil), isLoading: .constant(true), progress: .constant(0.5), download: {})
    }
}

import Amplify
import PromiseKit

extension IncomingMessageImageView {
    class Model: ObservableObject {
        @Published var isLoading: Bool = false
        @Published var progress: Double = 0.0
        @Published var image: UIImage? = nil
        @Published var blurredImage: UIImage? = nil
        @Published var showFullScreenImage: Bool = false
        
        func loadImage(for imageDocumentUrl: URL) {
            guard image == nil else {
                return
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                let image = UIImage(contentsOfFile: imageDocumentUrl.path)
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
        
        func loadImageBlurHash(for blurHash: String) {
            guard blurredImage == nil else {
                return
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                let blurredImage = BlurHash.image(for: blurHash)
                DispatchQueue.main.async {
                    self.blurredImage = blurredImage
                }
            }
        }
        
        func download(imageDownloadUrl: String, for messageId: String, group: String) {
            isLoading = true
            firstly {
                downloadImage(imageKey: imageDownloadUrl, group: group)
            }.then({ imageKey in
                PersistenceController.shared.update(imageDocumentUrl: imageKey, for: messageId).map({ ($0, imageKey) })
            }).done { _, imageKey in
//                self.loadImage(for: imageKey, group: group)
            }.ensure {
                self.isLoading = false
            }.catch { error in
                print("IncomingMessagesImageView: failed to perform download")
            }
        }
        
        func downloadImage(imageKey: String, group: String) -> Promise<String> {
            let (promise, resolver) = Promise<String>.pending()
            
            let documentsDirectory = FileManager.appGroupDirectory!
            let groupFolder = documentsDirectory.appendingPathComponent(group)
            
            do {
                try FileManager.default.createDirectory(
                    at: groupFolder,
                    withIntermediateDirectories: false,
                    attributes: nil
                )
            } catch CocoaError.fileWriteFileExists {
                // Folder already existed
            } catch {
                print("Error while creating group folder")
            }
            
           
            let downloadToFileName = groupFolder.appendingPathComponent(imageKey)

            let _ = Amplify.Storage.downloadFile(
                key: imageKey,
                local: downloadToFileName,
                progressListener: { progress in
                    DispatchQueue.main.async {
                        self.progress = progress.fractionCompleted
                    }
                    print("Progress: \(progress)")
                }, resultListener: { event in
                    switch event {
                    case .success:
                        print("Completed")
                        resolver.fulfill(imageKey)
                    case .failure(let storageError):
                        print("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
                        resolver.reject(storageError)
                    }
                })
            
            return promise
        }
    }
}
