//
//  CustomPhotoAlbum.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya T on 22/11/21.
//

import Photos
import UIKit

class CustomPhotoAlbum {

    var assetCollection: PHAssetCollection?
    init() {
    }
    
    func fetchAssetCollectionForAlbum(currentFolderName: String?) -> PHAssetCollection! {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", currentFolderName ?? "")
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let _ = collection.firstObject {
            return collection.firstObject!
        }
        return nil
    }
    
    func createFolder(image: UIImage?,currentFolder : String?) -> PHAssetCollection {
        if let fetchAssetCollection = fetchAssetCollectionForAlbum(currentFolderName: currentFolder) {
            assetCollection = fetchAssetCollection
            return fetchAssetCollection
        }

        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: currentFolder ?? "")
        }) { success, _ in
            if success {
                self.assetCollection = self.fetchAssetCollectionForAlbum(currentFolderName: currentFolder)
            }
        }
        return PHAssetCollection()
    }

    func saveImage(image: UIImage?,currentFolder : String?,imageName: String,assetsCollection: PHAssetCollection?, completion :@escaping () -> Void) {
        if assetsCollection == nil {
            return   // If there was an error upstream, skip the save.
        }
        if image == nil {
            return   // If there was an error upstream, skip the save.
        }
        assetCollection = assetsCollection
        PHPhotoLibrary.shared().performChanges({
          
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image ?? UIImage())
            let assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset
            if let assetCollection = self.assetCollection {
                let options = PHAssetResourceCreationOptions()
                options.originalFilename = imageName
                let newcreation:PHAssetCreationRequest = PHAssetCreationRequest.forAsset()
                newcreation.addResource(with: .photo, data:((image?.jpegData(compressionQuality: 1)))!, options: options)
                let assetPlaceholder = newcreation.placeholderForCreatedAsset
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
                albumChangeRequest?.addAssets([assetPlaceholder] as NSFastEnumeration)
           }
        }, completionHandler: { _,_ in
            DispatchQueue.main.async {
                completion()
            }
        })
    }
    
    private static func saveImageInAlbum(customFolder : String,image: UIImage, imageName: String, completion: @escaping (Bool) -> Void) {
        
        PHPhotoLibrary.shared().performChanges({
            if let fetchAssetCollection = fetchAssetCollectionForAlbum(currentFolderName: customFolder) {
                let options = PHAssetResourceCreationOptions()
                options.originalFilename = imageName
                let newcreation:PHAssetCreationRequest = PHAssetCreationRequest.forAsset()
                newcreation.addResource(with: .photo, data:image.jpegData(compressionQuality: 1)!, options: options)
                let assetPlaceholder = newcreation.placeholderForCreatedAsset
                
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: fetchAssetCollection)
                albumChangeRequest?.addAssets([assetPlaceholder] as NSFastEnumeration)
            }}, completionHandler: { success, error in
                if let error = error {
                    print("appSpecificAssetCollection error: \(error)")
                    completion(false)
                }
                
                if success {
                    completion(true)
                }
            })
    }

    public static func fetchAssetCollectionForAlbum(currentFolderName: String?) -> PHAssetCollection! {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", currentFolderName ?? "")
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let _ = collection.firstObject {
            return collection.firstObject!
        }
        return nil
    }

    public static func saveDownloadImage(customFolder : String,image: UIImage, imageName: String, completion: @escaping (Bool) -> Void) {
        let fetchOption = PHFetchOptions()
        
        fetchOption.predicate = NSPredicate(format: "title == '" + customFolder + "'")
        
        let fetchResult = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: fetchOption)
        
        if fetchResult.firstObject != nil {
            saveImageInAlbum(customFolder: customFolder, image: image, imageName: imageName, completion: completion)
            
        } else {
            PHPhotoLibrary.shared().performChanges({
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: customFolder)
            }, completionHandler: { success, error in
                if let error = error {
                    print("appSpecificAssetCollection error: \(error)")
                    completion(false)
                }
                
                if success {
                    saveImageInAlbum(customFolder: customFolder, image: image, imageName: imageName, completion: completion)
                }
            })
        }
    }
    
    
    public static func deleteDownloadedImageFromAlbum(customFolder : String, imageName: String, completion: @escaping (Bool) -> Void) {
        
        var assetCollection = PHAssetCollection()
        var photoAssets = PHFetchResult<PHAsset>()
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", customFolder)
        
        let collection:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let firstObject = collection.firstObject{
            //found the album
            assetCollection = firstObject
            debugPrint(firstObject)
            
        }
        else {
            debugPrint("Not Found")
        }
        
        let collectionCount = collection.firstObject?.localizedTitle
        photoAssets = PHAsset.fetchAssets(in: assetCollection, options: nil)
        
        let collectionList = PHFetchResultCollection(fetchResult: photoAssets)
        
        if let assetDetail =  collectionList.first(where: { asset in
            return asset.originalFilename == imageName
        }){
            
            let arrayToDelete = NSArray(object: assetDetail)
            PHPhotoLibrary.shared().performChanges( {
                PHAssetChangeRequest.deleteAssets(arrayToDelete)},
                                                    completionHandler: {
                success, error in
                
            })
        }
    }
}

extension PHAsset {
    var primaryResource: PHAssetResource? {
        let types: Set<PHAssetResourceType>

        switch mediaType {
        case .video:
            types = [.video, .fullSizeVideo]
        case .image:
            types = [.photo, .fullSizePhoto]
        case .audio:
            types = [.audio]
        case .unknown:
            types = []
        @unknown default:
            types = []
        }

        let resources = PHAssetResource.assetResources(for: self)
        let resource = resources.first { types.contains($0.type)}

        return resource ?? resources.first
    }

    var originalFilename: String {
        guard let result = primaryResource else {
            return "file"
        }

        return result.originalFilename
    }
}

struct PHFetchResultCollection: RandomAccessCollection, Equatable {

    typealias Element = PHAsset
    typealias Index = Int

    let fetchResult: PHFetchResult<PHAsset>

    var endIndex: Int { fetchResult.count }
    var startIndex: Int { 0 }

    subscript(position: Int) -> PHAsset {
        fetchResult.object(at: fetchResult.count - position - 1)
    }
}
