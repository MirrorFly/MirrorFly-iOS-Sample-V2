//
//  ImageData.swift
//  MirrorflyShareKit
//
//  Created by Sowmiya on 01/03/23.
//

import Foundation
import UIKit
import Photos
import MirrorFlySDK

public struct ImageData {
    var image : UIImage?
    var thumbImage: UIImage?
    var caption: String?
    var isVideo: Bool
    var phAsset: PHAsset?
    var isSlowMotion : Bool
    var processedVideoURL : URL?
    var isUploaded : Bool?
    var mediaData : Data? = nil
    var fileName : String = emptyString()
    var isCompressed : Bool = false
    var base64Image : String = emptyString()
    var mediaType : MediaType = .image
    var fileExtension : String = emptyString()
    var compressedDataURL : URL? = nil
    var encryptedKey : String = emptyString()
    var inProgress : Bool = false
    var fileSize : Double = 0.0
    var fileURL: URL? = nil
}

//struct Profile {
//    var profileName: String?
//    var jid: String = ""
//    var isSelected: Bool?
//}



