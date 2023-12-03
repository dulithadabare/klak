//
//  UIImageExtensions.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/1/21.
//

import UIKit

extension UIImage {
    var scaledToSafeUploadSize: UIImage? {
        let maxImageSideLength: CGFloat = 380
        
        let largerSide: CGFloat = max(size.width, size.height)
        let ratioScale: CGFloat = largerSide > maxImageSideLength ? largerSide / maxImageSideLength : 1
        let newImageSize = CGSize(
            width: size.width / ratioScale,
            height: size.height / ratioScale)
        
        return image(scaledTo: newImageSize)
    }
    
    var thumbnail: UIImage? {
        let maxImageSideLength: CGFloat = 200
        
        let largerSide: CGFloat = max(size.width, size.height)
        let ratioScale: CGFloat = largerSide > maxImageSideLength ? largerSide / maxImageSideLength : 1
        let newImageSize = CGSize(
            width: size.width / ratioScale,
            height: size.height / ratioScale)
        
        return image(scaledTo: newImageSize)
    }
    
    func image(scaledTo size: CGSize) -> UIImage? {
        defer {
            UIGraphicsEndImageContext()
        }
        
        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        draw(in: CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    enum JPEGQuality: CGFloat {
            case lowest  = 0
            case low     = 0.25
            case medium  = 0.5
            case high    = 0.75
            case highest = 1
        }

    /// Returns the data for the specified image in JPEG format.
    /// If the image object’s underlying image data has been purged, calling this function forces that data to be reloaded into memory.
    /// - returns: A data object containing the JPEG data, or nil if there was a problem generating the data. This function may return nil if the image has no data or if the underlying CGImageRef contains data in an unsupported bitmap format.
    func jpeg(_ jpegQuality: JPEGQuality) -> Data? {
        return jpegData(compressionQuality: jpegQuality.rawValue)
    }
    
    var pixelWidth: Int {
        switch (self.imageOrientation) {
        case .up, .down, .upMirrored, .downMirrored:
            return self.cgImage!.width
        case .left, .right, .leftMirrored, .rightMirrored:
            return self.cgImage!.height
        @unknown default:
            return 0
        }
    }

    var pixelHeight: Int {
        switch (self.imageOrientation) {
        case .up, .down, .upMirrored, .downMirrored:
            return self.cgImage!.height
        case .left, .right, .leftMirrored, .rightMirrored:
            return self.cgImage!.width
        @unknown default:
            return 0
        }
    }

    var pixelSize: CGSize {
        return CGSize(width: self.pixelWidth, height: self.pixelHeight);
    }
}

