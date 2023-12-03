//
//  BlurHash.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-12.
//

import UIKit
import PromiseKit

class BlurHash {
    // Large enough to reflect max quality of blurHash;
    // Small enough to avoid most perf hotspots around
    // these thumbnails.
    private static let kDefaultSize: CGFloat = 16
    
    static func getBlurHash(for imageKey: String, group: String) -> Promise<String> {
        let (promise, resolver) = Promise<String>.pending()
        
        DispatchQueue.global().async {
            guard let image = loadImageFromDocumentDirectory(nameOfImage: imageKey, group: group) else {
                return
            }
            
            guard let thumbnail = image.thumbnail else {
                resolver.reject(HamuwemuAuthError.missingThumbnail)
                return
            }
            
            guard let normalized = normalize(image: thumbnail, backgroundColor: .white) else {
                resolver.reject(HamuwemuAuthError.imageNormalizationError)
                return
            }
            
            // blurHash uses a DCT transform, so these are AC and DC components.
            // We use 4x3.
            //
            // https://github.com/woltapp/blurhash/blob/master/Algorithm.md
            guard let blurHash = normalized.blurHash(numberOfComponents: (4, 3)) else {
                resolver.reject(HamuwemuAuthError.blurHashGenerationError)
                return
            }
            
            resolver.fulfill(blurHash)
        }
        
        return promise
    }
    
    // BlurHashEncode only works with images in a very specific
    // pixel format: RGBA8888.
    private static func normalize(image: UIImage, backgroundColor: UIColor) -> UIImage? {
        guard let cgImage = image.cgImage else {
            print("Invalid image.")
            return nil
        }

        // As long as we're normalizing the image, reduce the size.
        // The blurHash algorithm doesn't need more data.
        // This also places an upper bound on blurHash perf cost.
        let srcSize = image.pixelSize
        guard srcSize.width > 0, srcSize.height > 0 else {
            print("Invalid image size.")
            return nil
        }
        let srcMinDimension: CGFloat = min(srcSize.width, srcSize.height)
        // Make sure the short dimension is N.
        let scale: CGFloat = min(1.0, kDefaultSize / srcMinDimension)
        let dstWidth: Int = Int(round(srcSize.width * scale))
        let dstHeight: Int = Int(round(srcSize.height * scale))
        let dstSize = CGSize(width: dstWidth, height: dstHeight)
        let dstRect = CGRect(origin: .zero, size: dstSize)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        // RGBA8888 pixel format
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(data: nil,
                                      width: dstWidth,
                                      height: dstHeight,
                                      bitsPerComponent: 8,
                                      bytesPerRow: dstWidth * 4,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else {
                                        return nil
        }
        context.setFillColor(backgroundColor.cgColor)
        context.fill(dstRect)
        context.draw(cgImage, in: dstRect)
        return (context.makeImage().flatMap { UIImage(cgImage: $0) })
    }

    @objc(imageForBlurHash:)
    public static func image(for blurHash: String) -> UIImage? {
        let thumbnailSize = imageSize(for: blurHash)
        guard let image = UIImage(blurHash: blurHash, size: thumbnailSize) else {
//            owsFailDebug("Couldn't generate image for blurHash.")
            return nil
        }
        return image
    }

    private static func imageSize(for blurHash: String) -> CGSize {
        return CGSize(width: kDefaultSize, height: kDefaultSize)
    }
}
