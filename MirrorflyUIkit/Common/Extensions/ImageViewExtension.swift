//
//  ImageViewExtension.swift
//  MirrorflyUIkit
//
//  Created by User on 18/08/21.
//

import Foundation
import UIKit

extension UIImageView {

    func containsImage(image: UIImage) -> Bool {
        let cgref = image.cgImage
        let cim = image.ciImage

        if cim == nil && cgref == nil {
            print("no underlying data")
            return false
        }
        else {
            return true
        }
    }
    
    func makeRounded() {
        let radius = self.frame.width/2.0
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
    
    // make image as circle view
    func setCircleView() {
        self.layer.cornerRadius = (self.frame.size.width ) / 2
        self.clipsToBounds = true
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.clear.cgColor
    }
    
    func setImageInsect(insect : CGFloat) {
        self.contentMode = .scaleAspectFill
        self.image = self.image?.withAlignmentRectInsets(UIEdgeInsets(top: insect, left: insect, bottom: insect, right: insect))
    }
    func applyShadow(_ shawdowRadius: CGFloat = 8.0,  shawdowOpacity: Float = 0.5){
        self.layer.shadowColor = Color.restoreShadowColor.cgColor
        self.layer.shadowRadius = shawdowRadius
        self.layer.shadowOpacity = shawdowOpacity
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.masksToBounds = false
    }

}

extension UIImage {
    enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }

    func jpeg(_ jpegQuality: JPEGQuality) -> Data? {
        return jpegData(compressionQuality: jpegQuality.rawValue)
    }
    
    func compressImage(image: UIImage) -> Data? {

            let oldImage = image
        var imageData =  Data(oldImage.pngData()!)
            print("***** Uncompressed Size \(imageData.description) **** ")

       imageData = oldImage.jpegData(compressionQuality: 0.025)!
            print("***** Compressed Size \(imageData.description) **** ")

        _ = UIImage(data: imageData)
        return imageData
    }
    
    func scaleToSize(newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext();
        return newImage
    }
    
    //To set automation identifier
    func setAutomationIdentifier(label: String, id: String) {
        self.accessibilityLabel = label
        self.accessibilityIdentifier = id
    }
}
