//
//  FullScreenImageView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-11.
//

import SwiftUI

struct FullScreenImageView: View {
    var imageUrl: URL?
    @Environment(\.dismiss) private var dismiss
    
    @GestureState var magnifyBy = 1.0

    var magnification: some Gesture {
        MagnificationGesture()
            .updating($magnifyBy) { currentState, gestureState, transaction in
                gestureState = currentState
            }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                AsyncImage(url: imageUrl, content: { image in
                    image
                        .resizable()
                        .aspectRatio(nil, contentMode: .fit)
                        .scaleEffect(magnifyBy)
                                    .gesture(magnification)
                }) {
                    ProgressView()
                }
            }
            .onAppear(perform: {
                print("url \(imageUrl?.absoluteString ?? "")")
            })
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }

                }
            }
        }
    }
}

struct FullScreenImageView_Previews: PreviewProvider {
    static var previews: some View {
        FullScreenImageView(imageUrl: nil)
    }
}
