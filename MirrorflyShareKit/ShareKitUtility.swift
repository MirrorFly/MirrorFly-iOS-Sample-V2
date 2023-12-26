//
//  ShareUtility.swift
//  MirrorflyUIkit
//
//  Created by John on 17/02/23.
//

import Foundation
import Network
import CommonCrypto
import UIKit
import Photos
import MirrorFlySDK

class ShareKitUtility {
    
    //Singleton class
    static let shared = ShareKitUtility()
    
    class func timeString(time: TimeInterval) -> String {
        let minute = Int(time) / 60 % 60
        let second = Int(time) % 60

        // return formated string
        return String(format: "%02i:%02i", minute, second)
    }
    
    func exitApp() {
        exit(0)
    }
    
    func checkFileType(url: String, typeImageView: UIImageView!) {
        guard let urlString = URL(string: url) else { return }
        let urlExtension = urlString.pathExtension
        
       switch urlExtension {
        case FileType.pdf.rawValue:
            typeImageView.image = UIImage(named: "ic_pdf")
        case FileType.doc.rawValue:
            typeImageView.image = UIImage(named: "ic_doc")
        case FileType.xls.rawValue:
            typeImageView.image = UIImage(named: "ic_xls")
        case FileType.xlsx.rawValue:
            typeImageView.image = UIImage(named: "ic_xlxs")
        case FileType.ppt.rawValue:
            typeImageView.image = UIImage(named: "ic_ppt")
        case FileType.pptx.rawValue:
            typeImageView.image = UIImage(named: "ic_pptx")
        case FileType.txt.rawValue:
            typeImageView.image = UIImage(named: "ic_txt")
        case FileType.zip.rawValue:
            typeImageView.image = UIImage(named: "ic_zip")
        case FileType.rar.rawValue:
            typeImageView.image = UIImage(named: "ic_rar")
        case FileType.csv.rawValue:
            typeImageView.image = UIImage(named: "ic_csv")
        case FileType.docx.rawValue:
            typeImageView.image = UIImage(named: "ic_docx")
       default:
           break
        }
        print("urlExtension \(url)")
    }
    public func getMentionTextContent(message: String, uiLabel: UILabel? = nil, isMessageSentByMe: Bool, mentionedUsers: [String], searchedText: String? = "") -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString(string: message)
        for user in mentionedUsers {
            let JID = user + "@" + ChatManager.getXMPPDetails().XMPPDomain
            let myJID = try? FlyUtils.getMyJid()
            if let profileDetail = ContactManager.shared.getUserProfileDetails(for: JID) {
                let userName = "@\(FlyUtils.getGroupUserName(profile: profileDetail))"
                let messageString: String = attributedString.string
                let mentionRange = (messageString as NSString).range(of: "@[?]")
                if mentionRange.location < attributedString.string.count {
                    attributedString.replaceCharacters(in: mentionRange, with: userName)
                }
                let mentionRange2 = ((attributedString.string) as NSString).range(of: userName)
                if mentionRange2.location < attributedString.string.count {
                    attributedString.addAttributes(uiLabel != nil ? (uiLabel?.font)! : .systemFont(ofSize: 15), color: ShareKitColor.muteSwitchColor, range: mentionRange2)
                    attributedString.addAttributes(uiLabel != nil ? (uiLabel?.font)! : .systemFont(ofSize: 15), color: ShareKitColor.mentionColor!, range: NSRange(location: mentionRange2.location, length: 1))
                    if !isMessageSentByMe , JID == myJID {
                        attributedString.addBGAttributes(uiLabel != nil ? (uiLabel?.font)! : .systemFont(ofSize: 15), color: ShareKitColor.mentionBackgroundColor!, range: mentionRange2)
                    } else {
                        attributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.clear, range: mentionRange2)
                    }
                }
            }
        }
        let attributeTxt = NSMutableAttributedString(string: attributedString.string)
        let range: NSRange = attributeTxt.mutableString.range(of: searchedText ?? "", options: .caseInsensitive)
        
        attributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: ShareKitColor.color_3276E2 ?? UIColor.systemBlue, range: range)
        return attributedString
    }
}


public final class NetworkReachability {
    
    // MARK: - Properties
    
    public static let shared = NetworkReachability()
    
    var monitor: NWPathMonitor?
    
    var isMonitoring = false
    
    public var didStartMonitoringHandler: (() -> Void)?
    
    public var didStopMonitoringHandler: (() -> Void)?
    
    public var netStatusChangeHandler: (() -> Void)?
    
    
    public var isConnected: Bool {
        guard let monitor = monitor else { return false }
        return monitor.currentPath.status == .satisfied && monitor.currentPath.status != .unsatisfied
    }
    
    
    public var interfaceType: NWInterface.InterfaceType? {
        guard let monitor = monitor else { return nil }
        
        return monitor.currentPath.availableInterfaces.filter {
            monitor.currentPath.usesInterfaceType($0.type) }.first?.type
    }
    
    public var isCellular: Bool {
            guard let monitor = monitor else { return false }
            return monitor.currentPath.usesInterfaceType(.cellular)
        }
    public var isWifi: Bool {
            guard let monitor = monitor else { return false }
            return monitor.currentPath.usesInterfaceType(.wifi)
        }
    
    var availableInterfacesTypes: [NWInterface.InterfaceType]? {
        guard let monitor = monitor else { return nil }
        return monitor.currentPath.availableInterfaces.map { $0.type }
    }
    
    
    var isExpensive: Bool {
        return monitor?.currentPath.isExpensive ?? false
    }
    
    
    // MARK: - Init & Deinit
    
    private init() {
        
    }
    
    
    deinit {
        stopMonitoring()
    }
    
    
    // MARK: - Method Implementation
    
    public func startMonitoring() {
        guard !isMonitoring else { return }
        
        monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetStatus_Monitor")
        monitor?.start(queue: queue)
        
        monitor?.pathUpdateHandler = { _ in
            if self.monitor?.currentPath.status == .satisfied {
                ChatManager.connect()
            }
            executeOnMainThread {
                self.netStatusChangeHandler?()
            }
        }
        
        isMonitoring = true
        executeOnMainThread {
            self.didStartMonitoringHandler?()
        }
    }
    
    
    public func stopMonitoring() {
        guard isMonitoring, let monitor = monitor else { return }
        monitor.cancel()
        self.monitor = nil
        isMonitoring = false
        executeOnMainThread {
            self.didStopMonitoringHandler?()
        }
    }
    
}

class Utility: NSObject{

    public static let shared = Utility()
    
    class func saveInPreference (key : String , value : Any) {
        var stringaValue = ""
        if let boolString = value as? Bool{
            stringaValue = boolString ? "true" : "false"
        }else if let value = value as? String{
            stringaValue  = value
        }
        if let encryptedData = encryptDecryptFlyDefaults(key: key, data:  Data(stringaValue.utf8), encrypt: true){
            UserDefaults.standard.setValue(encryptedData, forKey: key)
            UserDefaults.standard.synchronize()
        }
    }
    
    class func getStringFromPreference(key : String) -> String {
        if let value =  UserDefaults.standard.object(forKey: key) {
            if let encryptedData = value as? Data{
                if let decryptedData = encryptDecryptFlyDefaults(key: key, data:  encryptedData, encrypt: false){
                    return String(data: decryptedData, encoding: .utf8)!
                }
            }else if let oldValue = value as? String {
                saveInPreference(key: key, value: oldValue)
                return oldValue
            }
        }
        return ""
    }
    
    class func encryptDecryptFlyDefaults(key:String, data : Data, encrypt : Bool, iv : String = "ddc0f15cc2c90fca") -> Data?{
        guard let key = FlyEncryption.sha256(key, length: 32) else {
            return data
        }
        guard let flyEncryption = FlyEncryption(encryptionKey: key, initializationVector: iv ) else {
            return data
        }
        
        if encrypt {
            guard let encryptedData  = flyEncryption.crypt(data: data, option: CCOperation(kCCEncrypt)) else {
                return data
            }
            print("#ud encrypt \(key)  \(encryptedData)")
            return encryptedData
        } else {
            guard let decryptedData  = flyEncryption.crypt(data: data, option:  CCOperation(kCCDecrypt)) else {
                return nil
            }
            print("#ud decrypt \(key)  \(decryptedData)")
            return decryptedData
        }
    }

    func setRandomColors(totalCount: Int) -> [UIColor?] {
        var colors : [UIColor?] = []
        while totalCount > 0 {
            colors.append(contentsOf: getRandomColors())
            if totalCount <= colors.count {
                return colors
            }
        }
        return getRandomColors()
    }

    func getRandomColors() ->[UIColor?] {
        let colors = [ShareKitColor.color1, ShareKitColor.color2, ShareKitColor.color3, ShareKitColor.color4, ShareKitColor.color5, ShareKitColor.color6, ShareKitColor.color7, ShareKitColor.color8, ShareKitColor.color9, ShareKitColor.color10, ShareKitColor.color11, ShareKitColor.color12, ShareKitColor.color13, ShareKitColor.color14, ShareKitColor.color15, ShareKitColor.color16, ShareKitColor.color17, ShareKitColor.color18, ShareKitColor.color19, ShareKitColor.color20 ]
        return colors
    }

    func getErrorMessage(description: String) -> String {

        let split = description.components(separatedBy: "ErrorCode")
        let errorMessage = split.isEmpty ? description : split[0]
        return errorMessage
    }

    static func getColorForUser(userName: String?) -> UIColor {
        if let name = userName, !name.isEmpty {
            var totalAsciiValue = 0
            for char in name {
                if char.isASCII {
                    totalAsciiValue = totalAsciiValue + Int(char.asciiValue ?? UInt8(name.count))
                } else {
                    totalAsciiValue = totalAsciiValue + name.count
                }
            }
            let colorValue = totalAsciiValue * 10000
            let colorNum = colorValue
            let blue = colorNum >> 16
            let red = (colorNum & 0x00FF00) >> 8
            let green = (colorNum & 0x0000FF)
            let userColor = UIColor(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: 1.0)
            return userColor
        } else {
            return UIColor.gray
        }
    }

    static func setIconForAudio(imageView : UIImageView?, chatMessage : ChatMessage?, replyParentMessage : ReplyParentChatMessage? = nil) {
        if let imageView = imageView, let message = chatMessage {
            if message.mediaChatMessage?.audioType == AudioType.recording {
                imageView.image = UIImage(named: ImageConstant.ic_audio_filled)
            } else {
                imageView.image = UIImage(named: message.isMessageSentByMe ? "senderAudio" : "receiverAudio")
            }
        } else if let imageView = imageView, let message = replyParentMessage {
            if message.mediaChatMessage?.audioType == AudioType.recording {
                imageView.image = UIImage(named: ImageConstant.ic_audio_filled)
            } else {
                imageView.image = UIImage(named: message.isMessageSentByMe ? "senderAudio" : "receiverAudio")
            }
        }
    }
}

func executeOnMainThread( codeBlock: @escaping () -> Void) {
    DispatchQueue.main.async {
        codeBlock()
    }
}

func executeInBackground( codeBlock: @escaping () -> Void) {
    DispatchQueue.global(qos: .background).async {
        codeBlock()
    }
}


class ShareChatUtils {
    static func checkImageFileFormat(format : String) -> Bool{
        debugPrint("ChatUtils Image Format === \(format)")
        if format.isEmpty {
            return false
        }
        
        switch format.lowercased() {
        case "png":
            return true
        case "jpg":
            return true
        case "jpeg":
            return true
        case "gif":
            return true
        case "heic":
            return true
        case "heics":
            return true
        case "heif":
            return true
        case "heifs":
            return true
        case "hevc":
            return true
        default:
            return false
        }
    }
    
    static func getImageSize(asset : PHAsset) -> Float {
        var imageSize : Float = 0.0
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = true
        manager.requestImageData(for: asset, options: options) { data, _, _, _ in
            print("getAssetThumbnail \(asset.mediaType)")
            imageSize = Float(data?.count ?? 0)
        }
        return imageSize
    }
}


public class ShareMediaUtils {
    /**
     Process and provides the  Image meta data information for an PHAsset's Image/Video object
     
     - parameter asset: PHAsset object
     - returns:  (String,Data,Double,UIImage, UIImage,Bool)?  for fileName,imageData,imageSize,Image ,Thumb Image ,is it a video file in the respective order
     */
    public static func getAssetsImageInfo(asset : PHAsset) -> (String,Data,Double,UIImage, UIImage,Bool)? {
        var imageData : Data? =  nil
        var fileExtension : String =  emptyString()
        var fileName : String =  emptyString()
        var image = UIImage()
        var thumbnail = UIImage()
        var imageSize = 0.0
        if let assetName = asset.value(forKey: "filename") as? String {
            fileExtension = URL(fileURLWithPath: assetName).pathExtension
            fileName = assetName
            let manager = PHImageManager.default()
            let option = PHImageRequestOptions()
            option.version = .current
            option.isSynchronous = true
            option.isNetworkAccessAllowed = true
            manager.requestImageData(for: asset, options: option) { data, _, _, _ in
                if asset.mediaType == PHAssetMediaType.image ||  asset.mediaType == PHAssetMediaType.video {
                    if let data = data, let uiImage =  UIImage(data: data){
                        imageData = data
                        image = uiImage
                        imageSize = Double(data.count)
                    }
                }
            }
            manager.requestImage(for: asset, targetSize: CGSize(width: 32, height: 32), contentMode: .aspectFit, options: option) { result, info in
                thumbnail = result!
            }
        }
        if imageData == nil{
            return nil
        }else{
            return (fileName, imageData!, imageSize, image , thumbnail ,asset.mediaType == .video)
        }
    }

    public static func resizeImage(image: UIImage?, imageUrl: URL?, targetSize: CGSize) -> UIImage? {

        if let url = imageUrl {
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: max(targetSize.width, targetSize.height)
            ]

            guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil),
                let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary)
            else {
                return nil
            }

            return UIImage(cgImage: image)
        } else if let image = image {

            let size = image.size

            let widthRatio  = targetSize.width  / size.width
            let heightRatio = targetSize.height / size.height

            // Figure out what our orientation is, and use that to form the rectangle
            var newSize: CGSize
            if(widthRatio > heightRatio) {
                newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
            } else {
                newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
            }

            // This is the rect that we've calculated out and this is what is actually used below
            let rect = CGRect(origin: .zero, size: newSize)

            // Actually do the resizing to the rect using the ImageContext stuff
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return newImage
        }
        return nil
    }

    public static func downsample(imageAt imageURL: URL,
                    to pointSize: CGSize,
                    scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions) else {
            return nil
        }
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        return UIImage(cgImage: downsampledImage)
    }

    
}
extension NSMutableAttributedString {
    
    @discardableResult public func appendText(_ text: String, font: UIFont, color: UIColor) -> NSMutableAttributedString {
        let attributes = [NSAttributedString.Key.foregroundColor: color,
                          NSAttributedString.Key.font: font] as [NSAttributedString.Key : Any]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        self.append(attributedText)
        
        return self
    }
    
    @discardableResult public func addAttributes(_ font: UIFont, color: UIColor, range: NSRange) -> NSMutableAttributedString {
        let attributes = [NSAttributedString.Key.foregroundColor: color,
                          NSAttributedString.Key.font: font] as [NSAttributedString.Key : Any]
        self.addAttributes(attributes, range: range)
        
        return self
    }
    
    @discardableResult public func addBGAttributes(_ font: UIFont, color: UIColor, range: NSRange) -> NSMutableAttributedString {
        let attributes = [NSAttributedString.Key.backgroundColor: color,
                          NSAttributedString.Key.font: font] as [NSAttributedString.Key : Any]
        self.addAttributes(attributes, range: range)
        
        return self
    }
}
