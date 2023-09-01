//
//  ShareKitViewModel.swift
//  MirrorflyUIkit
//
//  Created by John on 17/02/23.
//

import Foundation
import MirrorFlySDK
import Firebase
import Photos
import Social
import CoreServices
import Contacts


let CONTAINER_ID = "group.com.mirrorfly.qa"
let LICENSE_KEY = "xxxxxxxxxxxxxxxxx"
let IS_LIVE = false
let APP_NAME = "UiKitQa"
let ENABLE_CONTACT_SYNC = false

protocol ShareKitDelegate {
    func removeData()
}

protocol ShareEditImageDelegate: class {
    func sendMedia(mediaData : [MediaData])
}

class ShareKitViewModel {

    static var shared = ShareKitViewModel()

    let dispatchGroup = DispatchGroup()
    let assetDispatchGroup = DispatchGroup()
    let locationDisptachGroup = DispatchGroup()

    var delegate: ShareKitDelegate? = nil
    var invaildMediaFiles: [ShareData]? = [ShareData]()
    var listOfMediaData: [MediaData]? = [MediaData]()
    var contactsList: [CNContact]? = [CNContact]()
    var imageVideoList = [NSItemProvider]()
    var textList = [String]()
    var locationList = [String]()
    var handledAssets = [PHAsset]()
    var handledURL = [URL]()

    init() {
        initialize()
    }
    
    private func initialize() {
        ChatManager.setAppGroupContainerId(id: CONTAINER_ID)
        NetworkReachability.shared.startMonitoring()
    }
    
    func isLoggedIn() -> Bool {
        return ChatManager.getAppLoggedIn()
    }

    func clearModel() {
        invaildMediaFiles = []
        listOfMediaData = []
        contactsList = []
        imageVideoList = []
        textList = []
        locationList = []
        handledAssets = []
        handledURL = []
    }

    func loadData(attachments: [NSItemProvider], completion: @escaping() -> Void) {

        var hasText = false
        var hasVcard = false
        var hasUrl = false
        var hasExternalUrl = false
        
        var locationValues = [String]()

        attachments.forEach { attachment in
            if attachment.hasItemConformingToTypeIdentifier("public.plain-text") {
                locationDisptachGroup.enter()
                attachment.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { [weak self] data, error in
                    hasText = true
                    if let data {
                        locationValues.append(String(describing: data))
                    }
                    self?.locationDisptachGroup.leave()
                }
            }
            if attachment.hasItemConformingToTypeIdentifier("public.vcard") {
                locationDisptachGroup.enter()
                attachment.loadItem(forTypeIdentifier: "public.vcard", options: nil) { [weak self] data, error in
                    hasVcard = true
                    //locationValues.append(String(describing: data))
                    self?.locationDisptachGroup.leave()
                }
            }
            if attachment.hasItemConformingToTypeIdentifier("public.url") {
                locationDisptachGroup.enter()
                attachment.loadItem(forTypeIdentifier: "public.url", options: nil) { [weak self] data, error in
                    hasUrl = true
                    if !String(describing: data).contains("file://") {
                        hasExternalUrl = true
                    }
                    if let data {
                        locationValues.append(String(describing: data))
                    }
                    self?.locationDisptachGroup.leave()
                }
            }
        }
        locationDisptachGroup.notify(queue: .main) {
            if (hasText && hasUrl) || (hasText && hasUrl && hasVcard) {
                self.locationList.append(locationValues.joined(separator: "\n"))
                return
            } else if (hasUrl && hasExternalUrl) {
                self.locationList.append(locationValues.joined(separator: "\n"))
                return
            }
        }

        attachments.forEach({ attachment in
            dispatchGroup.enter()
            switch true {
            case attachment.hasItemConformingToTypeIdentifier(kUTTypeImage as String):
                imageVideoList.append(attachment)
                attachment.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil) { [weak self] data, error in
                    print ("data: \(String(describing: data))")
                    var sharedData = ShareData()
                    sharedData.url = data as? URL
                    sharedData.contentType = .image
                    self?.insertData(sharedData: sharedData)
                    self?.dispatchGroup.leave()
                }
                break
            case attachment.hasItemConformingToTypeIdentifier(kUTTypeContact as String):
                attachment.loadItem(forTypeIdentifier: kUTTypeContact as String, options: nil) { [weak self] data, error in
                    print ("data: \(String(describing: data))")
                    if error == nil {
                        do {
                            if let data = data as? Data {
                                let contactVcard = try CNContactVCardSerialization.contacts(with: data)
                                if contactVcard is [CNContact] {
                                    self?.contactsList = contactVcard
                                }
                            }
                        } catch {}
                    }
                    self?.dispatchGroup.leave()
                }
                break
            case attachment.hasItemConformingToTypeIdentifier(kUTTypeWaveformAudio as String):
                attachment.loadItem(forTypeIdentifier: kUTTypeWaveformAudio as String, options: nil) { [weak self] data, error in
                    print ("data: \(String(describing: data))")
                    var sharedData = ShareData()
                    sharedData.url = data as? URL
                    sharedData.contentType = .audio
                    self?.insertData(sharedData: sharedData)
                    self?.dispatchGroup.leave()
                }
                break
            case attachment.hasItemConformingToTypeIdentifier(kUTTypeMP3 as String):
                attachment.loadItem(forTypeIdentifier: kUTTypeMP3 as String, options: nil) { [weak self] data, error in
                    print ("data: \(String(describing: data))")
                    var sharedData = ShareData()
                    sharedData.url = data as? URL
                    sharedData.contentType = .audio
                    self?.insertData(sharedData: sharedData)
                    self?.dispatchGroup.leave()
                }
                break
            case attachment.hasItemConformingToTypeIdentifier(kUTTypeAudio as String):
                attachment.loadItem(forTypeIdentifier: kUTTypeAudio as String, options: nil) { [weak self] data, error in
                    print ("data: \(String(describing: data))")
                    var sharedData = ShareData()
                    sharedData.url = data as? URL
                    sharedData.contentType = .audio
                    self?.insertData(sharedData: sharedData)
                    self?.dispatchGroup.leave()
                }
                break
            case attachment.hasItemConformingToTypeIdentifier(kUTTypeMovie as String):
                imageVideoList.append(attachment)
                attachment.loadItem(forTypeIdentifier: kUTTypeMovie as String, options: nil) { [weak self] data, error in
                    print ("data: \(String(describing: data))")
                    var sharedData = ShareData()
                    sharedData.url = data as? URL
                    sharedData.contentType = .video
                    self?.insertData(sharedData: sharedData)
                    self?.dispatchGroup.leave()
                }
                break
            case attachment.hasItemConformingToTypeIdentifier(kUTTypeVideo as String):
                imageVideoList.append(attachment)
                attachment.loadItem(forTypeIdentifier: kUTTypeVideo as String, options: nil) { [weak self] data, error in
                    print ("data: \(String(describing: data))")
                    var sharedData = ShareData()
                    sharedData.url = data as? URL
                    sharedData.contentType = .video
                    self?.insertData(sharedData: sharedData)
                    self?.dispatchGroup.leave()
                }
                break
            case attachment.hasItemConformingToTypeIdentifier(kUTTypeFileURL as String):
                attachment.loadItem(forTypeIdentifier: kUTTypeFileURL as String, options: nil) { [weak self] data, error in
                    print ("data: \(String(describing: data))")
                    var sharedData = ShareData()
                    sharedData.url = data as? URL
                    sharedData.contentType = .document
                    self?.insertData(sharedData: sharedData)
                    self?.dispatchGroup.leave()
                }
                break
            case attachment.hasItemConformingToTypeIdentifier(kUTTypePlainText as String):
                attachment.loadItem(forTypeIdentifier: kUTTypePlainText as String, options: nil) { [weak self] data, error in
                    print ("data: \(String(describing: data))")
                    if let data {
                        self?.textList.append(String(describing: data))
                    }
                    self?.dispatchGroup.leave()
                }
                break
            case attachment.hasItemConformingToTypeIdentifier(kUTTypeContent as String):
                attachment.loadItem(forTypeIdentifier: kUTTypeContent as String, options: nil) { [weak self] data, error in
                    print ("data: \(String(describing: data))")
                    var sharedData = ShareData()
                    sharedData.url = data as? URL
                    sharedData.contentType = .document
                    self?.insertData(sharedData: sharedData)
                    self?.dispatchGroup.leave()
                }
            case attachment.hasItemConformingToTypeIdentifier(kUTTypeZipArchive as String):
                attachment.loadItem(forTypeIdentifier: kUTTypeZipArchive as String, options: nil) { [weak self] data, error in
                    print ("data: \(String(describing: data))")
                    var sharedData = ShareData()
                    sharedData.url = data as? URL
                    sharedData.contentType = .document
                    self?.insertData(sharedData: sharedData)
                    self?.dispatchGroup.leave()
                }
                break
            case attachment.hasItemConformingToTypeIdentifier("com.microsoft.excel.xls"):
                attachment.loadItem(forTypeIdentifier: "com.microsoft.excel.xls", options: nil) { [weak self] data, error in
                    print ("data: \(String(describing: data))")
                    var sharedData = ShareData()
                    sharedData.url = data as? URL
                    sharedData.contentType = .document
                    self?.insertData(sharedData: sharedData)
                    self?.dispatchGroup.leave()
                }
                break
            case attachment.hasItemConformingToTypeIdentifier("org.openxmlformats.spreadsheetml.sheet"):
                attachment.loadItem(forTypeIdentifier: "org.openxmlformats.spreadsheetml.sheet", options: nil) { [weak self] data, error in
                    print ("data: \(String(describing: data))")
                    var sharedData = ShareData()
                    sharedData.url = data as? URL
                    sharedData.contentType = .document
                    self?.insertData(sharedData: sharedData)
                    self?.dispatchGroup.leave()
                }
                break
            case attachment.hasItemConformingToTypeIdentifier("com.microsoft.word.doc"):
                attachment.loadItem(forTypeIdentifier: "com.microsoft.word.doc", options: nil) { [weak self] data, error in
                    print ("data: \(String(describing: data))")
                    var sharedData = ShareData()
                    sharedData.url = data as? URL
                    sharedData.contentType = .document
                    self?.insertData(sharedData: sharedData)
                    self?.dispatchGroup.leave()
                }
                break
            case attachment.hasItemConformingToTypeIdentifier("com.microsoft.word.doc"):
                attachment.loadItem(forTypeIdentifier: "com.microsoft.word.doc", options: nil) { [weak self] data, error in
                    print ("data: \(String(describing: data))")
                    var sharedData = ShareData()
                    sharedData.url = data as? URL
                    sharedData.contentType = .document
                    self?.insertData(sharedData: sharedData)
                    self?.dispatchGroup.leave()
                }
                break
            default:
                textList.append(locationValues.first ?? emptyString())
                dispatchGroup.leave()
                break
            }
        })
        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }
    
    private func saveInLocalPath(path: String,localPath: String) -> URL {
        let directoryURL: URL = FlyUtils.getGroupContainerIDPath()!
        let folderPath: URL = directoryURL.appendingPathComponent(path, isDirectory: true)
        let fileURL: URL = folderPath.appendingPathComponent(localPath)
        return fileURL
    }
    
    func insertData(sharedData: ShareData) {
        //        if sharedData.contentType == .contact {
        //            contacts?.append(sharedData)
        //            return
        //        }
        guard let sharedURL = sharedData.url else { return }
        //if let data = try? Data(contentsOf: sharedURL) {
        //let data = Data()

        let resource = try? sharedURL.resourceValues(forKeys:[.fileSizeKey])
        let pathExtension = sharedData.url?.pathExtension
        let size = Double(resource?.fileSize ?? 0 / 1000)
        let fileSize = Double(Double(size / 1000) / 1000)
        switch sharedData.contentType {
        case .audio:
            if fileSize <= 30 && (pathExtension?.lowercased() == "aac" || pathExtension?.lowercased() == "mp3" || pathExtension?.lowercased() == "wav" || pathExtension?.lowercased() == "m4a") {
                MediaUtils.processAudio(url: sharedData.url ?? URL(string: "")!) { isSuccess, fileName ,localPath, fileSize, duration, fileKey  in
                    print("#media \(duration)")
                    if isSuccess {
                        if let localPathURL = localPath, isSuccess{
                            var mediaData = MediaData()
                            mediaData.fileName = fileName
                            mediaData.fileURL = localPathURL
                            mediaData.fileSize = fileSize
                            mediaData.duration = duration
                            mediaData.fileKey = fileKey
                            mediaData.mediaType = .audio
                            self.listOfMediaData?.append(mediaData)
                        }
                    }
                }

            } else {
                var file = sharedData
                file.invalidType = fileSize > 30 ? .size : .format
                invaildMediaFiles?.append(file)
            }
        case .image:
            if fileSize > 10 {
                var file = sharedData
                file.invalidType = .size
                invaildMediaFiles?.append(file)
            } else {
                var mediaData = MediaData()
                mediaData.fileName = sharedData.url?.lastPathComponent
                mediaData.fileSize = Double(fileSize)
                let asset = AVAsset(url: ((sharedData.url ?? URL(string: ""))!))
                let duration = asset.duration
                let durationTime = CMTimeGetSeconds(duration)
                mediaData.duration = Double(durationTime)
                mediaData.mediaType = .image
                mediaData.fileURL = saveInLocalPath(path: "FlyMedia/Image",localPath: sharedData.url?.lastPathComponent ?? "")
                listOfMediaData?.append(mediaData)
            }
        case .document:
            if fileSize <= 20 && (pathExtension?.lowercased() == "pdf" || pathExtension?.lowercased() == "xls" || pathExtension?.lowercased() == "xlsx" || pathExtension?.lowercased() == "doc" || pathExtension?.lowercased() == "docx" ||
                                  pathExtension?.lowercased() == "txt" || pathExtension?.lowercased() == "ppt" || pathExtension?.lowercased() == "zip" || pathExtension?.lowercased() == "rar" || pathExtension?.lowercased() == "pptx" || pathExtension?.lowercased() == "csv" || pathExtension?.lowercased() == "csv") {
                MediaUtils.processDocument(url: sharedData.url ?? URL(string: "")!){ isSuccess,localPath,fileSize,fileName, errorMessage in
                    if isSuccess {
                        if let localPathURL = localPath, isSuccess {
                            var mediaData = MediaData()
                            mediaData.fileName = fileName
                            mediaData.fileURL = localPathURL
                            mediaData.fileSize = fileSize
                            mediaData.mediaType = .document

                            self.listOfMediaData?.append(mediaData)
                        }
                    }
                }
            } else {
                var file = sharedData
                file.invalidType = fileSize > 20 ? .size : .format
                invaildMediaFiles?.append(file)
            }
        case .video:
            if fileSize >= 30 {
                var file = sharedData
                file.invalidType = .size
                invaildMediaFiles?.append(file)
            } else {
                var mediaData = MediaData()
                mediaData.fileName = sharedData.url?.lastPathComponent
                mediaData.fileURL = saveInLocalPath(path: "FlyMedia/Image",localPath: sharedData.url?.lastPathComponent ?? "")
                mediaData.fileSize = Double(fileSize)
                let asset = AVAsset(url: ((sharedData.url ?? URL(string: ""))!))
                let duration = asset.duration
                let durationTime = CMTimeGetSeconds(duration)
                mediaData.duration = Double(durationTime)
                mediaData.mediaType = .video
                listOfMediaData?.append(mediaData)
            }
        default:
            break
        }
        //}
    }

    /// Key is the matched asset's original file name without suffix. E.g. IMG_193
    private lazy var imageAssetDictionary: [String : PHAsset] = {

        let options = PHFetchOptions()
        options.includeHiddenAssets = true
        let fetchResult = PHAsset.fetchAssets(with: .image, options: options)

        var assetDictionary = [String : PHAsset]()

        for i in 0 ..< fetchResult.count {
            let asset = fetchResult[i]
            let fileName = asset.value(forKey: "originalFilename") as? String ?? ""
            let fileNameWithoutSuffix = fileName.components(separatedBy: ".").first ?? ""
            assetDictionary[fileNameWithoutSuffix] = asset
        }

        return assetDictionary
    }()

    private lazy var videoAssetDictionary: [String : PHAsset] = {

        let options = PHFetchOptions()
        options.includeHiddenAssets = true
        let fetchResult = PHAsset.fetchAssets(with: .video, options: options)

        var assetDictionary = [String : PHAsset]()

        for i in 0 ..< fetchResult.count {
            let asset = fetchResult[i]
            let fileName = asset.value(forKey: "originalFilename") as! String
            let fileNameWithoutSuffix = fileName.components(separatedBy: ".").first!
            assetDictionary[fileNameWithoutSuffix] = asset
        }

        return assetDictionary
    }()

    func getAsset(completion: @escaping() -> Void) {
        let allProvider = imageVideoList
        allProvider.forEach { provider in
            assetDispatchGroup.enter()
            provider.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil) {
                data, _ in
                if let url = data as? URL {
                    if let fileName = url.lastPathComponent.components(separatedBy: ".").first {
                        if let asset = self.imageAssetDictionary[fileName] {
                            self.handledAssets.append(asset)
                        } else {
                            self.handledURL.append(url)
                        }
                        self.assetDispatchGroup.leave()
                    }
                }
            }
            provider.loadItem(forTypeIdentifier: kUTTypeMovie as String, options: nil) {
                data, _ in
                if let url = data as? URL {
                    if let fileName = url.lastPathComponent.components(separatedBy: ".").first {
                        if let asset = self.videoAssetDictionary[fileName] {
                            self.handledAssets.append(asset)
                        } else {
                            self.handledURL.append(url)
                        }
                        self.assetDispatchGroup.leave()
                    }
                }
            }
        }
        assetDispatchGroup.notify(queue: .main) {
            completion()
        }
    }

}

 
