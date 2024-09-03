//
//  ProfileViewController.swift
//  MirrorflyUIkit
//
//  Created by User on 17/08/21.
//
import UIKit
import AVFoundation
import MirrorFlySDK
import Foundation
import MobileCoreServices
import Photos
import Tatsi
import QCropper
import SDWebImage
import PhoneNumberKit

protocol ProfileViewControllerProtocol {
    func setCroppedImage(_ croppedImage: UIImage)
}

class ProfileViewController: UIViewController,ProfileViewControllerProtocol {
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var mobileNumberLabel: UITextField!
    @IBOutlet weak var statusButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    
    var isImagePicked: Bool = false
    let imagePickerController = UIImagePickerController()
    private let profileViewModel = ProfileViewModel()
    var profileImageLocalPath = String()
    var previewImage: UIImage!
    var getMobileNumber: String = ""
    var delegate: ProfileViewControllerProtocol?
    var getUserMobileNumber:String = ""
    var profileDetails: ProfileDetails? = nil
    var isSaveButtonTapped: Bool? = false
    // The last collection the user has selected. Set from the picker's delegate method.
    // It is not recommended to PHAssetCollection in persitant storage. If you do, check if the album is still available before showing the picker.
    var lastSelectedCollection: PHAssetCollection?
    
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
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ProfileViewController.onProfileImage(_:)))
        profileImage.isUserInteractionEnabled = true
        profileImage.addGestureRecognizer(tapGesture)
        nameTextField.addTarget(self, action: #selector(ProfileViewController.textFieldDidChange(_:)),
                                for: .editingChanged)
        emailTextField.addTarget(self, action: #selector(ProfileViewController.textFieldDidChange(_:)),
                                for: .editingChanged)

        ContactManager.shared.getUsersIBlocked(fetchFromServer: true) { isSuccess, error, data in }
        prefetchImages()
    }
    
    func prefetchImages() {
//        let recentArray : [RecentChat] = FlyDatabaseController.shared.recentManager.getRecentChatWithConstraints(limit: 100, messageTime: 0)
//        let url = recentArray.compactMap{ ChatUtils.getUserImaeUrl(imageUrl: ($0.profileThumbImage?.isEmpty ?? true) ? $0.profileImage ?? "" : $0.profileThumbImage ?? "") }
//        SDWebImagePrefetcher.shared.prefetchURLs(url)
    }
    
    func setupUI() {
        stopLoading()
        nameTextField.textInputMode?.primaryLanguage == "emoji"
        nameTextField.keyboardType = .default
        nameTextField.adjustsFontSizeToFitWidth = false
        hideKeyboardWhenTappedAround()
        print(getMobileNumber)
        statusLabel.text = inMirrorfly.localized
        profileImage.layer.masksToBounds = false
        profileImage.layer.cornerRadius = profileImage.frame.height/2
        profileImage?.layer.borderWidth = 0.5
        profileImage.layer.borderColor = Color.groupIconBackgroundGray?.cgColor
        profileImage.clipsToBounds = true
        self.getProfile()
        isSaveButtonTapped = false
        mobileNumberLabel.delegate = self
    }
    
    @objc override func didMoveToBackground() {
        print("ProfileViewController ABCXYZ didMoveToBackground")
   }
    
    @objc override func willCometoForeground() {
//        print("ProfileViewController ABCXYZ willCometoForeground ============ ")
//        print("ProfileViewController ABCXYZ willCometoForeground \(profileDetails?.image) ")
//        print("ProfileViewController ABCXYZ willCometoForeground \(FlyDefaults.myName)")
//        print("ProfileViewController ABCXYZ willCometoForeground \(FlyDefaults.myEmail)")
//        print("ProfileViewController ABCXYZ willCometoForeground \(FlyDefaults.myImageUrl)")
      
        if ContactManager.getMyProfile().name.isEmpty || ContactManager.getMyProfile().email.isEmpty {
            print("ProfileViewController ABCXYZ willCometoForeground if ")
            DispatchQueue.main.async { [weak self] in
                self?.stopLoading()
                self?.startLoading(withText: pleaseWait)
            }
           
            DispatchQueue.main.async {
               self.getProfile()
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                if let localPath = (self?.profileDetails?.image.isEmpty ?? false || self?.profileDetails?.image == nil) ? ContactManager.getMyProfile().image : self?.profileDetails?.image {
                    print("image",ContactManager.getMyProfile().image)
                    print("profileImage",self?.profileDetails?.image)
                    if FileManager.default.fileExists(atPath: localPath) {
                        let url = URL.init(fileURLWithPath: localPath)
                        let data = NSData(contentsOf: url as URL)
                        let image = UIImage(data: data! as Data)
                        self?.profileImage.image = image
                    } else {
                        self?.profileImage?.sd_imageIndicator = SDWebImageActivityIndicator.white
                        self?.setImage(imageURL: localPath, completionHandler: { [weak self] _ in
                            DispatchQueue.main.async {
                                self?.stopLoading()
                            }
                        })
                    }
                }
                let tempName = self?.nameTextField.text ?? ""
                let tempEmail = self?.emailTextField.text ?? ""
                if tempName.isEmpty {
                    self?.nameTextField.text = ContactManager.getMyProfile().name
                }
                
                if tempEmail.isEmpty {
                    self?.emailTextField.text = ContactManager.getMyProfile().email
                }
                self?.mobileNumberLabel.text = self?.mobileNumberLabel.text?.isEmpty ?? false ? ContactManager.getMyProfile().mobileNumber : self?.mobileNumberLabel.text
            }
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupUI()
        print("ProfileViewController ABCXYZ viewWillAppear")
         navigationController?.setNavigationBarHidden(true, animated: animated)
        handleBackgroundAndForground()
    }

    override func viewDidAppear(_ animated: Bool) {
        ContactManager.shared.profileDelegate = self
        ChatManager.shared.connectionDelegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ContactManager.shared.profileDelegate = nil
        ChatManager.shared.connectionDelegate = nil
    }
    
    override func viewDidLayoutSubviews(){
        super.viewDidLayoutSubviews()
        profileImage.layer.cornerRadius = profileImage.frame.size.width / 2
        profileImage.clipsToBounds = true
    }
    
    @objc func onProfileImage(_ recognizer: UIGestureRecognizer) {
        if(isImagePicked) {
        performSegue(withIdentifier: Identifiers.profileImageFullView, sender: nil)
        }
    }
}

// MARK: Get ,update Profile and remove profile image

extension ProfileViewController {
    
    func getProfile() {
        print( ChatManager.getXMPPDetails().XMPPUsername)
        if(CommonDefaults.isProfileUpdated) {
            do {
                let JID = ChatManager.getXMPPDetails().XMPPUsername + "@" + ChatManager.getXMPPDetails().XMPPDomain
            
                try ContactManager.shared.getUserProfile(for:  JID, fetchFromServer: true, saveAsFriend: true) { [weak self] isSuccess, flyError, flyData in
                    var data  = flyData
                    if(isSuccess) {
                        DispatchQueue.main.async {
                            print(data.getData() as! ProfileDetails)
                            self?.profileDetails = data.getData() as? ProfileDetails
                            let mobileNumber = self?.profileDetails?.mobileNumber ?? ""
//                            FlyDefaults.myImageToken = self?.profileDetails?.image ?? ""
                            if(self?.profileDetails?.image != "") {
                                self?.setImage(imageURL: self?.profileDetails?.image ?? "", completionHandler: { _ in
//                                    self?.stopLoading()
                                })
                                self?.isImagePicked = true
                            } else {
                                self?.getUserNameInitial()
                            }
                            print("profileDetails")
                            self?.nameTextField.text = self?.profileDetails?.name == "" ? self?.profileDetails?.nickName : self?.profileDetails?.name
                            self?.emailTextField.text = self?.profileDetails?.email
                            self?.getUserMobileNumber = self?.profileDetails!.mobileNumber ?? ""
                            if mobileNumber.isEmpty || mobileNumber.count < 6 {
                                self?.mobileNumberLabel.text = ContactManager.getMyProfile().mobileNumber
                            } else {
                                let mobileNumberWithoutCountryCode = AppUtils.shared.mobileNumberParse(phoneNo: mobileNumber)
                                self?.mobileNumberLabel.text = mobileNumberWithoutCountryCode
                            }
                            
                            self?.statusLabel.text = self?.profileDetails?.status == "" ? inMirrorfly.localized : self?.profileDetails?.status
//                            DispatchQueue.main.async { [weak self] in
//                                self?.stopLoading()
//                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self?.stopLoading()
                        }
                    }
                }
            } catch {
                self.stopLoading()
            }
        } else{
            saveButton.setTitle(save.localized, for: .normal)
            self.stopLoading()
        }
    }
    
    func setImage(imageURL: String,completionHandler:  @escaping (Bool?)-> Void) {
        profileImage.sd_imageIndicator = SDWebImageActivityIndicator.white
        let urlString = ChatManager.getImageUrl(imageName: imageURL)
        let url = URL(string: urlString)
        profileImage.sd_setImage(with: url, placeholderImage: #imageLiteral(resourceName: "ic_profile_placeholder"), completed: { [weak self]image,error,_,imageUrl in
            self?.profileImage.stopAnimating()
            completionHandler(true)
        })
    }
    
    private func saveMyProfileDataToUserDefaults(profile : FlyProfile){
        // Commented private flydefaults profile saved inside SDK
//        FlyDefaults.myName = profile.name
//        FlyDefaults.myImageUrl = profile.image
//        FlyDefaults.myImageToken = profile.image
//        FlyDefaults.myMobileNumber = profile.mobileNumber
//        FlyDefaults.myStatus = profile.status
//        FlyDefaults.myEmail = profile.email
    }

    func updateProfile(profileDetails: ProfileDetails) {
        executeOnMainThread { [weak self] in
            self?.profileDetails = profileDetails
            let mobileNumber = self?.profileDetails?.mobileNumber ?? ""
//            FlyDefaults.myImageToken = self?.profileDetails?.image ?? ""
            if(self?.profileDetails?.image != "") {
                self?.setImage(imageURL: self?.profileDetails?.image ?? "", completionHandler: { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self?.stopLoading()
                    }
                })
                self?.isImagePicked = true
            } else {
                self?.getUserNameInitial()
            }
            print("profileDetails")
            self?.nameTextField.text = self?.profileDetails?.name == "" ? self?.profileDetails?.nickName : self?.profileDetails?.name
            self?.emailTextField.text = self?.profileDetails?.email
            self?.getUserMobileNumber = self?.profileDetails!.mobileNumber ?? ""
            if mobileNumber.isEmpty || mobileNumber.count < 6 {
                self?.mobileNumberLabel.text = ContactManager.getMyProfile().mobileNumber
            } else {
                let mobileNumberWithoutCountryCode = AppUtils.shared.mobileNumberParse(phoneNo: mobileNumber)
                self?.mobileNumberLabel.text = mobileNumberWithoutCountryCode
            }

            self?.statusLabel.text = self?.profileDetails?.status == "" ? inMirrorfly.localized : self?.profileDetails?.status
        }
    }
    
    // MARK: Update Profile
    func updateMyProfile() {
        
        print("ProfileViewController ABCXYZ updateMyProfile")
        
        if NetworkReachability.shared.isConnected {
            let JID = ChatManager.getXMPPDetails().XMPPUsername + "@" + ChatManager.getXMPPDetails().XMPPDomain
            if isSaveButtonTapped == true {
                startLoading(withText: pleaseWait)
            }
            var myProfile = FlyProfile(jid: JID)
            guard let email = emailTextField.text else {
                return
            }
            myProfile.email = email
            guard let mobileNumber = mobileNumberLabel.text else {
                return
            }
            myProfile.mobileNumber = getPhoneNumberToUpdate(phoneNumber: mobileNumber.isNotEmpty ? mobileNumber : ContactManager.getMyProfile().mobileNumber)
            
            guard let nickName = nameTextField.text else {
                return
            }
            myProfile.nickName = nickName
            myProfile.name = nickName
            
            guard let status = statusLabel.text else {
                return
            }
            myProfile.status = status
            if(isImagePicked) {
                myProfile.image = profileImageLocalPath
                if profileImageLocalPath.isEmpty && profileDetails?.image != ""{
                    myProfile.image = profileDetails?.image ?? ""
                    isImagePicked = false
                }
            }
            ContactManager.shared.updateMyProfile(for: myProfile) { [weak self] isSuccess, flyError, flyData in
                self?.stopLoading()
                var data  = flyData
                if isSuccess {
                    ChatManager.sendRegisterUpdate { isSuccess, error, data in
                    }
                    Utility.saveInPreference(key: isProfileSaved, value: true)
                    Utility.saveInPreference(key: isLoginContactSyncDone, value: false)
                    self?.getProfile()
                    if ENABLE_CONTACT_SYNC {
                        if self?.isSaveButtonTapped == true {
                            AppAlert.shared.showToast(message: profileUpdateSuccess.localized)
                            let storyboard = UIStoryboard.init(name: Storyboards.profile, bundle: nil)
                            let contactSyncController = storyboard.instantiateViewController(withIdentifier: Identifiers.contactSyncController) as! ContactSyncController
                            self?.navigationController?.pushViewController(contactSyncController, animated: true)
                            self?.navigationController?.viewControllers.removeAll(where: { (vc) -> Bool in
                                if vc.isKind(of: ContactSyncController.self){
                                    return false
                                } else {
                                    return true
                                }
                            })
                        }
                    }else{
                        self?.saveMyProfileDataToUserDefaults(profile: myProfile)
                        if self?.isSaveButtonTapped == true {
                            AppAlert.shared.showToast(message: profileUpdateSuccess.localized)
                            self?.moveToDashboard()
                        }
                    }
                }else {
                    print(data.getMessage() as! String)
                    AppAlert.shared.showToast(message: "Please try again later")
                }
                self?.profileImageLocalPath = ""
            }
        }else {
            stopLoading()
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
        }
    }
    
    //MARK: Remove Profile Image
    func removeProfileImage(fileUrl : String){
        if NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: profilePictureRemoved.localized)
            ContactManager.shared.removeProfileImage( completionHandler: { isSuccess, flyError, flyData in
                var data  = flyData
                if isSuccess {
                    print(data.getMessage() as! String)
//                    FlyDefaults.myProfileImageUrl = ""
                } else{
                    print(data.getMessage() as! String)
                }
            })
        }
        else {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
        }
    }
}

//MARK : Actions
extension ProfileViewController {
    @IBAction func onCameraButton(_ sender: Any) {
        showActionSheet()
    }
    
    @IBAction func onStatusButton(_ sender: Any) {
         performSegue(withIdentifier: Identifiers.editStatusView, sender: self)
    }
    
    @IBAction func onSaveButton(_ sender: Any) {
        isSaveButtonTapped = true
        guard let userName = nameTextField.text else {return}
        guard let email = emailTextField.text else {return}
        guard let mobileNumber = mobileNumberLabel.text else {return}
        profileViewModel.profileCompletionHandler { (status, message) in
            if status {
                self.updateMyProfile()
            } else {
                AppAlert.shared.showToast(message: message)
            }
        }
        profileViewModel.updateProfileWith(userName: userName, emailId: email, mobileNumber: mobileNumber)
    }
    
    func moveToDashboard() {
        RootViewController.sharedInstance.initCallSDK()
        let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
        let mainTabBarController = storyboard.instantiateViewController(withIdentifier: Identifiers.mainTabBarController) as! MainTabBarController
        navigationController?.pushViewController(mainTabBarController, animated: true)
        navigationController?.viewControllers.removeAll(where: { viewControllers in
            !viewControllers.isKind(of: MainTabBarController.self)
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Identifiers.profileImageFullView {
            let imageViewer: ImageViewerViewController = segue.destination as! ImageViewerViewController
            imageViewer.getProfileImage = previewImage
            imageViewer.profileDetailsImage = profileDetails?.image
        }
        else if segue.identifier == Identifiers.editStatusView { 
            let editStatus: EditStatusViewController = segue.destination as! EditStatusViewController
            editStatus.defaultStatus = statusLabel.text
            editStatus.delegate = self
        }
    }
}

extension ProfileViewController: UITextFieldDelegate{
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if(CommonDefaults.isProfileUpdated) {
            if(nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) != profileDetails?.nickName || emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) != profileDetails?.email || statusLabel.text != profileDetails?.status) {
                saveButton.setTitle(updateAndContinue.localized, for: .normal)
            }
            else {
                saveButton.setTitle(save.localized, for: .normal)
            }
        }
       if(!isImagePicked) {
        if (textField == nameTextField) {
                getUserNameInitial()
            }
        }
    }
    
    func getUserNameInitial() {
        guard let name = nameTextField.text else {
            let imageUrl = ContactManager.getMyProfile().image
            if FileManager.default.fileExists(atPath: imageUrl) {
                let url = URL.init(fileURLWithPath: imageUrl)
                let data = NSData(contentsOf: url as URL)
                let image = UIImage(data: data! as Data)
                profileImage.image = image
            } else {
                setImage(imageURL: imageUrl, completionHandler: { [weak self] _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self?.stopLoading()
                    }
                })
            }
            return
        }
        if !name.isEmpty {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let ipimage = IPImage(text: trimmedName, radius: Double(profileImage.frame.size.height), font: UIFont.font84px_appBold(), textColor: nil, randomBackgroundColor:  false)
            profileImage.image = ipimage.generateImage()
        }
        else {
            let imageUrl = ContactManager.getMyProfile().image
            if FileManager.default.fileExists(atPath: imageUrl) {
                let url = URL.init(fileURLWithPath: imageUrl)
                let data = NSData(contentsOf: url as URL)
                let image = UIImage(data: data! as Data)
                profileImage.image = image
            } else {
                setImage(imageURL: imageUrl, completionHandler: { [weak self] _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self?.stopLoading()
                    }
                })
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if(textField == nameTextField) {
            return  textLimit(existingText: textField.text, newText: string, limit: userNameMaxLength, isName: true)
        }
        if(textField == mobileNumberLabel) {
            return  textLimit(existingText: textField.text, newText: string, limit: 17, isName: false)
        }
        return true
    }
    
    func textView(_ textField: UITextField,
                    shouldChangeTextIn range: NSRange,
                    replacementText text: String) -> Bool{
        if(textField == nameTextField) {
          var nsString:NSString = ""
          
          if textField.text != nil  && text != "" {
              nsString = textField.text! as NSString
              nsString = nsString.replacingCharacters(in: range, with: text) as NSString
          }   else if (text == "") && textField.text != ""  {
              nsString = textField.text! as NSString
              nsString = nsString.replacingCharacters(in: range, with: text) as NSString
              
          } else if (text == "") && textField.text == "" {
            textField.text = ""
          }

          guard let texts = textField.text else { return true }
          let currentText = nsString as NSString
          if currentText.length >= userNameMaxLength {
            textField.text = currentText.substring(to: userNameMaxLength)
          }
          return currentText.length <= userNameMaxLength
        }
        
        return true
    }
    
    func textLimit(existingText: String?, newText: String, limit: Int, isName: Bool) -> Bool {
          let text = existingText ?? ""
          let limitText = text.count + newText.count
          let isAtLimit = text.count + newText.count <= limit
          if limitText > limit {
              AppAlert.shared.showToast(message:  isName ? userNameValidation.localized : userMobileNumber.localized)
          }
          return isAtLimit
      }
    
}

//MARK: ImagePicker Action
extension ProfileViewController {
    func showActionSheet() {
        let alertAction = UIAlertController(title: nil, message:nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: takePhoto.localized, style: .default) { [weak self] _ in
            
            if NetworkReachability.shared.isConnected {
            if UIImagePickerController.isSourceTypeAvailable(.camera){
                self?.checkCameraPermissionAccess(sourceType: .camera)
            } else {
                AppAlert.shared.showAlert(view: self!, title: noCamera.localized, message: noCameraMessage.localized, buttonTitle: noCamera.localized)
            }
            }
            else {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
        }
        let galleryAction = UIAlertAction(title: chooseFromGallery.localized, style: .default) { [weak self] _ in
            if NetworkReachability.shared.isConnected {
            self?.checkGalleryPermissionAccess(sourceType: .photoLibrary)
            }
            else {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
        }
        let cancelAction = UIAlertAction(title: cancel, style: .cancel)
        
        cameraAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
        galleryAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
        cancelAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
        alertAction.addAction(cameraAction)
        alertAction.addAction(galleryAction)
        if(isImagePicked) {
            let removeAction = UIAlertAction(title: removePhoto.localized, style: .default) { [weak self] _ in
                guard let self = self else {
                    return
                }
                if NetworkReachability.shared.isConnected {
                    AppAlert.shared.showAlert(view: self, title: alert, message: removePhotoAlert, buttonOneTitle: cancel, buttonTwoTitle: removeButton)
                    AppAlert.shared.onAlertAction = { [weak self] (result) ->
                        Void in
                        if result == 1 {
                            self?.isImagePicked = false
                            self?.profileDetails?.image = ""
                            guard let nameText = self?.nameTextField.text else {
                                return
                            }
                            if(nameText.count > 0) {
                                self?.getUserNameInitial()
                            }
                            else {
                                self?.profileImage.image = UIImage.init(named: ImageConstant.ic_profile_placeholder)
                            }
                         
                            self?.removeProfileImage(fileUrl:  self!.profileImageLocalPath)
                        }else {
                           
                        }
                    }
                }
                else {
                    AppAlert.shared.showToast(message: ErrorMessage.noInternet)
                }
            }
            removeAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
            alertAction.addAction(removeAction)
        }
        alertAction.addAction(cancelAction)
         present(alertAction, animated: true, completion: nil)
    }
    /**
     *  This function used to check camera Permission
     */
    func checkCameraPermissionAccess(sourceType: UIImagePickerController.SourceType) {
        let authorizationStatus =  AVCaptureDevice.authorizationStatus(for: .video)
        switch authorizationStatus {
        case .denied:
            presentCameraSettings()
            break
        case .restricted:
            break
        case .authorized:
            showImagePickerController(sourceType: sourceType)
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                   if granted {
                    print("Granted access to ")
                    self.showImagePickerController(sourceType: sourceType)
                   } else {
                       print("Denied access to")
                   }
            }
            break
        @unknown default:
            print("Permission failed")
        }
    }
    
    func presentCameraSettings() {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "",
                message: cameraAccessDenied.localized,
                preferredStyle: UIAlertController.Style.alert
            )
            
            alert.addAction(UIAlertAction(title: cancel.localized, style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: settings.localized, style: .default, handler: { (alert) -> Void in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                    })
                    
                }
            }))
            
            self.present(alert, animated: false, completion: nil)
        }
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
    
   func getAssetThumbnail(asset: PHAsset) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var thumbnail = UIImage()
        option.isSynchronous = true
        manager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            thumbnail = result!
        })
        return thumbnail
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

//MARK: ImagePicker Delegate Method
extension ProfileViewController: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    func showImagePickerController(sourceType: UIImagePickerController.SourceType) {
        DispatchQueue.main.async {
            self.imagePickerController.delegate = self
            self.imagePickerController.mediaTypes = ["public.image"]
            self.imagePickerController.sourceType = sourceType
            self.present(self.imagePickerController, animated: true, completion: nil)
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            isImagePicked = true
            if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let cropper = CropperViewController(originalImage: userPickedImage , isCircular: true)
            cropper.delegate = self
            picker.dismiss(animated: true) {
                self.present(cropper, animated: true, completion: nil)
                }
            }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension ProfileViewController: StatusDelegate {
    func userSelectedStatus(selectedStatus: String) {
      
        statusLabel.text = selectedStatus
        if(CommonDefaults.isProfileUpdated) {
            if(nameTextField.text != profileDetails?.nickName || emailTextField.text != profileDetails?.email || statusLabel.text != profileDetails?.status) {
                saveButton.setTitle(updateAndContinue.localized, for: .normal)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        AppAlert.shared.showToast(message: profileUpdateSuccess.localized)
        }
    }
}

//MARK : Photos cropping
extension ProfileViewController: CropperViewControllerDelegate {
    func cropperDidConfirm(_ cropper: CropperViewController, state: CropperState?) {
        cropper.dismiss(animated: true, completion: nil)
        isSaveButtonTapped = false
        if let state = state,
            let image = cropper.originalImage.cropped(withCropperState: state) {
            
            self.profileImage.contentMode = .scaleAspectFit
            self.previewImage = image
          
            profileImage.image = image
            print(cropper.isCurrentlyInInitialState)
            print(image)
            
            let str = AppUtils.shared.getRandomString(length: 15)
            let fileName = str ?? ""
            profileImageLocalPath = AppUtils.shared.saveInDirectory(with: profileImage.image?.jpegData(compressionQuality: 1.0), fileName: fileName + jpg) ?? ""
//            FlyDefaults.myProfileImageUrl = profileImageLocalPath
//            print("fileName--\( FlyDefaults.myProfileImageUrl)")
            print("localPath--\( profileImageLocalPath)")
            DispatchQueue.main.async { [weak self] in
                self?.updateMyProfile()
            }
        }
    }
}

//MARK: For Gallery picker - Select photos and allow photos in permisssion
extension ProfileViewController: TatsiPickerViewControllerDelegate {
    
    func pickerViewController(_ pickerViewController: TatsiPickerViewController, didSelectCollection collection: PHAssetCollection) {
        self.lastSelectedCollection = collection
        print("User selected collection: \(collection)")
    }
    
    func pickerViewController(_ pickerViewController: TatsiPickerViewController, didPickAssets assets: [PHAsset]) {
        print("Picked assets: \(assets)")
        
        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = false //for icloud backup assets
        let asset : PHAsset = assets .first!
        asset.requestContentEditingInput(with: options) { (contentEditingInput, info) in
            if let uniformTypeIdentifier = contentEditingInput?.uniformTypeIdentifier {
                var fullImage: CIImage? = nil
                if let fullSizeImageURL = contentEditingInput?.fullSizeImageURL {
                    fullImage = CIImage(contentsOf: fullSizeImageURL)
                }
                print("uniformTypeIdentifier", uniformTypeIdentifier)
                //if uniformTypeIdentifier == (kUTTypePNG as String) || uniformTypeIdentifier == (kUTTypeJPEG as String) {
                    self.isImagePicked = true
                    
                    guard let assetToImage = self.getUIImage(asset: asset) else {
                        return
                    }
                    let cropper = CropperViewController(originalImage: assetToImage, isCircular: true)
                    cropper.delegate = self
                    pickerViewController.dismiss(animated: true) {
                        self.present(cropper, animated: true, completion: nil)
                    }
                //}
                
//                else {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                        AppAlert.shared.showToast(message: unsupportedFile.localized)
//                    }

               // }
               
            }
        }
    }
    
    func setCroppedImage(_ croppedImage: UIImage) {
        self.profileImage.image = croppedImage
    }
}

extension ProfileViewController: ProfileEventsDelegate {
    func userCameOnline(for jid: String) {

    }

    func userWentOffline(for jid: String) {

    }

    func userProfileFetched(for jid: String, profileDetails: MirrorFlySDK.ProfileDetails?) {
        if let details = profileDetails {
            if details.jid == AppUtils.getMyJid() {
                print("#profile update: userProfileFetched \(details.image)")
                updateProfile(profileDetails: details)
            }
        }
    }

    func myProfileUpdated() {

    }

    func usersProfilesFetched() {

    }

    func blockedThisUser(jid: String) {

    }

    func unblockedThisUser(jid: String) {

    }

    func usersIBlockedListFetched(jidList: [String]) {

    }

    func usersBlockedMeListFetched(jidList: [String]) {

    }

    func userUpdatedTheirProfile(for jid: String, profileDetails: MirrorFlySDK.ProfileDetails) {
        if profileDetails.jid == AppUtils.getMyJid() {
            print("#profile update: userUpdatedTheirProfile \(profileDetails.image)")
            updateProfile(profileDetails: profileDetails)
        }
    }

    func userBlockedMe(jid: String) {

    }

    func userUnBlockedMe(jid: String) {

    }

    func hideUserLastSeen() {

    }

    func getUserLastSeen() {

    }

    func userDeletedTheirProfile(for jid: String, profileDetails: MirrorFlySDK.ProfileDetails) {

    }

}

extension ProfileViewController: ConnectionEventDelegate {
    
    func onConnectionFailed(error: FlyError) {
        
    }
    
    func onReconnecting() {
        
    }
    
    func onConnected() {
        getProfile()
    }

    func onDisconnected() {

    }

}
