//
//  NewGroupViewController.swift
//  MirrorflyUIkit
//
//  Created by John on 22/11/21.
//

import UIKit
import SwiftUI
import Photos
import QCropper
import Tatsi

protocol GroupCreationDelegate {
    func onGroupCreated()
}

class NewGroupViewController: UIViewController, UITextFieldDelegate {
    
    let groupCreationViewModel = GroupCreationViewModel()
    
    var groupCreationDeletgate : GroupCreationDelegate?
    
    @IBOutlet weak var cameraImageView: UIImageView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var countUILabel: UILabel!
    @IBOutlet weak var groupNameTextField: UITextField!
    @IBOutlet weak var emojiImageViewo: UIImageView!
    
    var groupImageLocalPath = String()
    var isImagePicked: Bool = false
    var groupName = ""
    
    var lastSelectedCollection: PHAssetCollection?
    
    let imagePickerController = UIImagePickerController()
    
    // If the rememberCollectioSwitch is turned on we return the last known collection, if available.
    var firstView: TatsiConfig.StartView {
        if let lastCollection = self.lastSelectedCollection {
            return .album(lastCollection)
        } else {
            return .userLibrary
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpStatusBar()
        setUpUI()
        initialize()
    }
    
    func setUpUI() {
        headerView.addBottomShawdow()
        groupImageView.makeRounded()
        
        groupNameTextField.delegate = self
        
        cameraImageView.isUserInteractionEnabled = true
        let pickImageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(pickImage(sender:)))
        cameraImageView.addGestureRecognizer(pickImageGestureRecognizer)
        
        groupImageView.isUserInteractionEnabled = true
        let groupImageGesture = UITapGestureRecognizer(target: self, action: #selector(pickImage(sender:)))
        groupImageView.addGestureRecognizer(groupImageGesture)
        
        emojiImageViewo.isUserInteractionEnabled = true
        let showKeyboardGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showKeyboard(sender:)))
        emojiImageViewo.addGestureRecognizer(showKeyboardGestureRecognizer)
    }
    
    func initialize() {
        groupCreationViewModel.initializeGroupCreationData()
    }
    
    
    @IBAction func didBackTap(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didNextTap(_ sender: Any) {
        groupName = groupNameTextField.text?.trim() ?? ""
        groupCreationViewModel.isNameEmpty(groupName: groupName, groupCallBack: { [weak self] result, message in
            if result {
                AppAlert.shared.showToast(message: message)
            } else {
               self?.performSegue(withIdentifier: Identifiers.addParticipants, sender: nil)
            }
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Identifiers.addParticipants {
            let addParticipantsViewController = segue.destination as! AddParticipantsViewController
            addParticipantsViewController.groupCreationDeletgate = groupCreationDeletgate
            GroupCreationData.groupName = groupName
            GroupCreationData.groupImageLocalPath = groupImageLocalPath
        }
    }
    
}

extension NewGroupViewController {
    @objc func pickImage(sender : UIImageView) {
        groupNameTextField.endEditing(true)
        var values : [String] = ImagePickingOptions.allCases.map { $0.rawValue }
        
        if !isImagePicked {
            values = values.filter{ $0 != ImagePickingOptions.removePhoto.rawValue }
        }
        
        var actions = [(String, UIAlertAction.Style)]()
        values.forEach { title in
            actions.append((title, UIAlertAction.Style.default))
        }
        AppActionSheet.shared.showActionSeet(title : "", message: "",actions: actions , sheetCallBack: { [weak self] didCancelTap, tappedTitle in
            self?.groupNameTextField.endEditing(true)
            if !didCancelTap {
                switch tappedTitle {
                case ImagePickingOptions.chooseFromGallery.rawValue:
                    self?.checkGalleryPermissionAccess(sourceType: .photoLibrary)
                case ImagePickingOptions.takePhoto.rawValue:
                    self?.checkCameraPermission(sourceType: .camera)
                case ImagePickingOptions.removePhoto.rawValue:
                    self?.removeImage()
                default:
                    print(" \(tappedTitle)")
                }
            } else {
                print("pickImage Cancel")
            }
        })
    }
    
    func removeImage() {
        groupImageLocalPath = ""
        groupImageView.image = UIImage(named: ImageConstant.ic_group_placeholder)
        groupImageView.contentMode = .center
        isImagePicked = false
    }
    
    @objc func showKeyboard(sender : UIImageView) {
        groupNameTextField.becomeFirstResponder()
    }
}

extension NewGroupViewController {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var tempString : String = string
        if string.count > 25 {
            tempString = tempString.substring(to: 25)
            textField.text = tempString
        }
        let count = groupCreationViewModel.calculateTextLength(startingLength: textField.text?.count ?? 0, lengthToAdd: tempString.count, lengthToReplace: range.length)
        let countToDisplay = groupNameCharLimit - count
        countUILabel.text = String(countToDisplay)
        return groupCreationViewModel.textLimit(existingText: textField.text ?? "", newText: tempString, limit: groupNameCharLimit);
    }
}

// Permissions
extension NewGroupViewController {
    /**
     *  This function used to check camera Permission
     */
    
    func checkCameraPermission(sourceType: UIImagePickerController.SourceType) {
        AppPermissions.shared.checkCameraPermissionAccess(permissionCallBack: { [weak self] authorizationStatus in
            switch authorizationStatus {
            case .denied:
                AppPermissions.shared.presentSettingsForPermission(permission: .camera, instance: self as Any)
                break
            case .restricted:
                break
            case .authorized:
                self?.showImagePickerController(sourceType: sourceType)
                break
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        print("Granted access to ")
                        self?.showImagePickerController(sourceType: sourceType)
                    } else {
                        print("Denied access to")
                    }
                }
                break
            @unknown default:
                print("Permission failed")
            }
        })
        
    }
    
    /**
     *  This function used to check gallery Permission
     */
    func checkGalleryPermissionAccess(sourceType: UIImagePickerController.SourceType) {
        var config = TatsiConfig.default
        config.supportedMediaTypes = [.image]
        config.firstView = self.firstView
        config.maxNumberOfSelections = 1
        
        let pickerViewController = TatsiPickerViewController(config: config)
        pickerViewController.pickerDelegate = self
        self.present(pickerViewController, animated: true, completion: nil)
    }
    
}

//MARK: ImagePicker Delegate Method
extension NewGroupViewController: UIImagePickerControllerDelegate ,UINavigationControllerDelegate {
    
    func showImagePickerController(sourceType: UIImagePickerController.SourceType) {
        DispatchQueue.main.async { [weak self] in
            self?.imagePickerController.delegate = self
            self?.imagePickerController.mediaTypes = [cameraMediaTypeImage]
            self?.imagePickerController.sourceType = sourceType
            self?.present(self!.imagePickerController, animated: false, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        isImagePicked = true
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let cropper = CropperViewController(originalImage: userPickedImage , isCircular: true)
            cropper.delegate = self
            picker.dismiss(animated: false) {
                self.present(cropper, animated: false, completion: nil)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: false, completion: nil)
    }
}

//MARK : Photos cropping
extension NewGroupViewController: CropperViewControllerDelegate {
    
    func cropperDidConfirm(_ cropper: CropperViewController, state: CropperState?) {
        cropper.dismiss(animated: false, completion: nil)
        
        if let state = state,
           let image = cropper.originalImage.cropped(withCropperState: state) {
            
            groupImageView.contentMode = .scaleAspectFit
            groupImageView.image = image
            
            print(cropper.isCurrentlyInInitialState)
            print(image)
            
            let str = AppUtils.shared.getRandomString(length: 15)
            let fileName = str ?? ""
            groupImageLocalPath = AppUtils.shared.saveInDirectory(with: groupImageView.image?.jpegData(compressionQuality: 1.0), fileName: fileName + jpg) ?? ""
            
            print("localPath-- \( groupImageLocalPath)")
        }
    }
    
    func cropperDidCancel(_ cropper: CropperViewController) {
        cropper.dismiss(animated: false, completion: nil)
        if groupImageLocalPath.isEmpty {
            removeImage()
        }
    }
}

//MARK: For Gallery picker - Select photos and allow photos in permisssion
extension NewGroupViewController: TatsiPickerViewControllerDelegate {
    
    func pickerViewController(_ pickerViewController: TatsiPickerViewController, didSelectCollection collection: PHAssetCollection) {
        self.lastSelectedCollection = collection
    }
    
    func pickerViewController(_ pickerViewController: TatsiPickerViewController, didPickAssets assets: [PHAsset]) {
        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = false //for icloud backup assets
        let asset : PHAsset = assets .first!
        asset.requestContentEditingInput(with: options) { [weak self] (contentEditingInput, info) in
            if (contentEditingInput?.uniformTypeIdentifier) != nil {
                self?.isImagePicked = true
                
                guard let assetToImage = self?.getUIImage(asset: asset) else {
                    return
                }
                let cropper = CropperViewController(originalImage: assetToImage, isCircular: true)
                cropper.delegate = self
                pickerViewController.dismiss(animated: false) {
                    self?.present(cropper, animated: false, completion: nil)
                }
            }
        }
    }
    
    func setCroppedImage(_ croppedImage: UIImage) {
        self.groupImageView.image = croppedImage
    }
    
    func getUIImage(asset: PHAsset) -> UIImage? {
        
        var img: UIImage?
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = true
        manager.requestImageData(for: asset, options: options) { data, _, _, _ in
            if let data = data {
                img = UIImage(data: data)
            }
        }
        return img
    }
}


