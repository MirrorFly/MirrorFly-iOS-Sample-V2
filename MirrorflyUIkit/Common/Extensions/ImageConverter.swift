//
//  ImageConverter.swift
//  MirrorflyUIkit
//
//  Created by User on 03/09/21.
//

import Foundation
import UIKit
class ImageConverter {
    
    static let shared = ImageConverter()

    func base64ToImage(_ base64String: String) -> UIImage? {
        guard let imageData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) else { return nil }
        return UIImage(data: imageData)
    }
    

    func convertImageToBase64 (img: UIImage) -> String {
        return img.jpegData(compressionQuality: 0.5)?.base64EncodedString(options: .endLineWithLineFeed) ?? ""
    }
    

    func convertImageToBase64String (img: UIImage) -> String {
        var image = img
        var imageData = img.pngData()
        if let imgData = imageData?.count{
            var imgDataCount = imgData
            while imgDataCount / 10 >= 300 {
                let propotion = image.size.width / image.size.height
                image = compressCapturedImage(image, andWidth: image.size.width / 2, andHeight: image.size.width / (2 * propotion))!
                imageData = image.jpegData(compressionQuality: 0.5)
                imgDataCount = imageData!.count
            }
        }
        let strBase64 = imageData?.base64EncodedString(options: .endLineWithLineFeed) ?? ""
        return strBase64
    }
    
     func compressCapturedImage(_ image: UIImage?, andWidth width: CGFloat, andHeight height: CGFloat) -> UIImage? {
            UIGraphicsBeginImageContext(CGSize(width: width, height: height))
            image?.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage
    }
}

