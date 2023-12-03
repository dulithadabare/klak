//
//  PhotoPicker.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/22/21.
//

import SwiftUI
import PhotosUI

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context)
    -> some UIViewController {
        
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        
        configuration.selectionLimit = 0
        
        let picker =
            PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator

        return picker
        
    }
    
    func updateUIViewController(
        _ uiViewController: UIViewControllerType,
        context: Context
    ) {
    }
    
    func makeCoordinator() -> PhotosCoordinator {
      PhotosCoordinator(parent: self)
    }

}

struct PhotoPicker_Previews: PreviewProvider {
    static var previews: some View {
        PhotoPicker(selectedImage: .constant(nil))
    }
}

class PhotosCoordinator: NSObject,
                         PHPickerViewControllerDelegate {
    var parent: PhotoPicker

    init(parent: PhotoPicker) {
      self.parent = parent
    }
    
    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {
//        guard let item = results.first?.itemProvider else {
//            return
//        }
                
        if  let item = results.first?.itemProvider,
            item.canLoadObject(ofClass: UIImage.self) {
          // 2
          item.loadObject(ofClass: UIImage.self) { image, error in
            // 3
            if let error = error {
              print("Error!", error.localizedDescription)
            } else {
              // 4
              DispatchQueue.main.async {
                if let image = image as? UIImage {
                  self.parent.selectedImage = image
                }
              }
            }
          }
        }
        parent.presentationMode.wrappedValue.dismiss()

    }
    
}

