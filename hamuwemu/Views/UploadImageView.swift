//
//  UploadImageView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-12.
//

import SwiftUI

struct UploadImageView: View {
    var body: some View {
        Image(systemName: "arrow.up")
            .padding()
            .background(Circle().fill(Material.ultraThick))
    }
}

struct UploadImageView_Previews: PreviewProvider {
    static var previews: some View {
        Rectangle().fill(.blue)
            .overlay(UploadImageView())
    }
}

struct DownloadImageView: View {
    var body: some View {
        Image(systemName: "arrow.down")
            .padding()
            .background(Circle().fill(Material.ultraThick))
    }
}

struct DownloadImageView_Previews: PreviewProvider {
    static var previews: some View {
        Rectangle().fill(.blue)
            .overlay(DownloadImageView())
    }
}
