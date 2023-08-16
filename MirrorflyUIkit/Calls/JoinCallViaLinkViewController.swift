//
//  JoinCallViaLinkViewController.swift
//  MirrorflyUIkit
//
//  Created by MohanRaj on 19/05/23.
//

import UIKit
import WebRTC
import MirrorFlySDK

class JoinCallViaLinkViewController: UIViewController {

    @IBOutlet var profileImage: [UIImageView]!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var alertLabel: UILabel!
    @IBOutlet weak var audioButton: UIButton!
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var joinButton: UIButton!
    
    @IBOutlet weak var userProfileImage: UIImageView!
    
    @IBOutlet weak var countLabel: UILabel!
    
    var audioPermissionEnabled: Bool = false
    var isVideoPermissionEnabled: Bool = false
    
#if arch(arm64)
    var localRenderer = RTCMTLVideoView(frame: .zero)
#else
    var localRenderer = RTCEAGLVideoView(frame: .zero)
#endif
    
    var callLink = emptyString()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        CallManager.setJoinCallDelegate(delegate: self)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        CallManager.startVideoCapture()
        localRenderer.frame = CGRect(x: 0, y: 0, width: videoView.bounds.width, height: videoView.bounds.height)
        
        CallManager.subscribeToCallEvents(link: self.callLink, name: ContactManager.getMyProfile().name) { isSuccess, flyError in
            if !isSuccess {
                let error = flyError?.description ?? ""
                self.handleErrorResponse(errorMessage: error)
            }else{
                self.joinButton.isEnabled = true
                self.joinButton.alpha = 1
                self.checkMicPermission()
                self.checkCameraPermission(sourceType: .camera)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
//        CallManager.subscribeToCallEvents(link: self.callLink, name:  FlyDefaults.myName) { isSuccess, flyError in
//            print("#join \(message)")
//
//            if !isSuccess {
//                let error = flyError?.description ?? ""
//                self.handleErrorResponse(errorMessage: error)
//            }
//        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        localRenderer.removeFromSuperview()
        CallManager.cleanUpJoinCallViaLink()
    }
    
    func setupUI() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification
                    , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification
                    , object: nil)
        
        self.networkMonitor()
        
        if let profileDetail = ContactManager.shared.getUserProfileDetails(for: AppUtils.getMyJid()) {
           
            let profileImageStr = profileDetail.thumbImage.isEmpty ? profileDetail.image : profileDetail.thumbImage
            
           userProfileImage.loadFlyImage(imageURL: profileImageStr, name: getUserName(jid : profileDetail.jid ,name: profileDetail.name, nickName: profileDetail.nickName, contactType: profileDetail.contactType), chatType: profileDetail.profileChatType,contactType: profileDetail.contactType, jid: profileDetail.jid, isBlockedByAdmin: ContactManager.shared.getUserProfileDetails(for: profileDetail.jid)?.isBlockedByAdmin ?? false)
            
        }
        
        audioButton.setImage(UIImage(named: "ic_audio_active"), for: .normal)
        audioButton.setImage(UIImage(named: "ic_audio_inactive"), for: .selected)
        
        videoButton.setImage(UIImage(named: "ic_video_active"), for: .normal)
        videoButton.setImage(UIImage(named: "ic_video_inactive"), for: .selected)
        
        countLabel.layer.cornerRadius = 25
        countLabel.layer.masksToBounds = true
        videoView.layer.cornerRadius = 10
        videoView.layer.masksToBounds = true
        
        joinButton.isEnabled = false
        joinButton.alpha = 0.5
        
        self.localRenderer.frame = CGRect(x: 0, y: 0, width: videoView.bounds.width, height: videoView.bounds.height)
        videoView.addSubview(self.localRenderer)
    }
    
    @objc func willEnterForeground() {
        initJoinLink()
    }
    
    func initJoinLink() {
        CallManager.setJoinCallDelegate(delegate: self)
        CallManager.setupJoinCallViaLink()
        CallManager.subscribeToCallEvents(link: self.callLink, name: ContactManager.getMyProfile().name) { isSuccess, flyError in
            if !isSuccess {
                let error = flyError?.description ?? ""
                self.handleErrorResponse(errorMessage: error)
            }else{
                self.joinButton.isEnabled = true
                self.joinButton.alpha = 1
                self.checkMicPermission()
                self.checkCameraPermission(sourceType: .camera)
            }
        }
    }
    
    @objc func didEnterBackground() {
        CallManager.cleanUpJoinCallViaLink()
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        
        CallManager.cleanUpJoinCallViaLink()
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func audioButtonAction(_ sender: Any) {
        
        self.checkMicPermission()
        
        if audioPermissionEnabled {
            
            if audioButton.isSelected {
                
                audioButton.isSelected = false
                CallManager.muteAudio(false)
                
            }else {
                
                audioButton.isSelected = true
                CallManager.muteAudio(true)
            }
        }
    }
    
    @IBAction func videoButtonAction(_ sender: Any) {
        
        if isVideoPermissionEnabled {
            
            if videoButton.isSelected {
                
                userProfileImage.isHidden = true
                videoButton.isSelected = false
                CallManager.muteVideo(false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.localRenderer.isHidden = false
                }
                
            }else {
                
                userProfileImage.isHidden = false
                videoView.bringSubviewToFront(userProfileImage)
                
                localRenderer.isHidden = true
                
                videoButton.isSelected = true
                CallManager.muteVideo(true)
            }
        }else {
            AppPermissions.shared.presentSettingsForPermission(permission: .camera, instance: self as Any)
        }
    }
    
    @IBAction func joinNowAction(_ sender: Any) {
        
        if !NetworkReachability.shared.isConnected {
            self.alertLabel.isHidden = false
            self.alertLabel.text = "Please check you’re internet connection"
            return
        }
        
        self.checkMicPermission()
        
        if audioPermissionEnabled {
            
            CallManager.joinCall { success, flyError in
                if success{
                    executeOnMainThread {
                        //CallManager.cleanUpJoinCallViaLink()
                        self.navigationController?.popViewController(animated: true)
                    }
                }else {
                    let errorMessage = flyError?.description ?? ""
                    self.handleErrorResponse(errorMessage: errorMessage)
                }
            }
        }
    }
    
    func updateUsersDetails(usersList: [String]) {
        
        if usersList.count == 0 || usersList.count == 1 {
            
            let current = UIApplication.shared.keyWindow?.getTopViewController()
            if (current is CallEndedViewController) {
                return
            }
            
            let storyboard = UIStoryboard(name: "Call", bundle: nil)
            let callEndedView = storyboard.instantiateViewController(withIdentifier: "CallEndedViewController") as! CallEndedViewController
            callEndedView.isInvalidLink = false
            self.navigationController?.pushViewController(callEndedView, animated: true)
            
        }
        
        if !NetworkReachability.shared.isConnected {
            alertLabel.isHidden = false
            alertLabel.text = "Please check you’re internet connection"
        }else {
            alertLabel.isHidden = (usersList.count >= 8) ? false : true
            alertLabel.text = (usersList.count >= 8) ? "Maximum 8 members allowed in call" : ""
        }
        
        joinButton.isEnabled = (usersList.count >= 8) ? false : true
        joinButton.alpha = (usersList.count >= 8) ? 0.5 : 1.0
        
        var unknowGroupMembers = [String]()
        profileImage[0].isHidden = true
        profileImage[1].isHidden = true
        profileImage[2].isHidden = true
        profileImage[3].isHidden = true
        
        
        for (index, jid) in usersList.enumerated() {
            
            if usersList.count < 4 {
                
                if let contact = ChatManager.getContact(jid: jid) {
                    
                    let profileImageStr = contact.thumbImage.isEmpty ? contact.image : contact.thumbImage
                    
                    profileImage[index].loadFlyImage(imageURL: profileImageStr, name: getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), chatType: contact.profileChatType,contactType: contact.contactType, jid: contact.jid, isBlockedByAdmin: ContactManager.shared.getUserProfileDetails(for: contact.jid)?.isBlockedByAdmin ?? false)
                    profileImage[index].isHidden = false
                    
                    let name = getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType)
                    unknowGroupMembers.append(name)
                    
                    countLabel.isHidden = true
                    
                } else {
                    let userName = CallManager.getUserName(userId: jid)
                    unknowGroupMembers.append(userName)
                    profileImage[index].image = UIImage(named: "ic_profile_placeholder")
                    profileImage[index].isHidden = false
                    countLabel.isHidden = true
                }
                
                let groupMemberName = unknowGroupMembers.joined(separator: ", ")
                titleLabel.text = groupMemberName
                
            }else {
                
                if let contact = ChatManager.getContact(jid: jid) {
                    
                    let profileImageStr = contact.thumbImage.isEmpty ? contact.image : contact.thumbImage
                    
                    profileImage[index].loadFlyImage(imageURL: profileImageStr, name: getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), chatType: contact.profileChatType,contactType: contact.contactType, jid: contact.jid, isBlockedByAdmin: ContactManager.shared.getUserProfileDetails(for: contact.jid)?.isBlockedByAdmin ?? false)
                    profileImage[index].isHidden = (index == 3) ? true : false
                    
                    var name = getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType)
                    name = (index == 3) ? "and (+\(usersList.count - 3))" : name
                    unknowGroupMembers.append(name)
                    
                }else {
                    let userName = CallManager.getUserName(userId: jid)
                    unknowGroupMembers.append(userName)
                    profileImage[index].image = UIImage(named: "ic_profile_placeholder")
                }
                let groupMemberName = unknowGroupMembers.joined(separator: ", ")
                titleLabel.text = groupMemberName
                countLabel.isHidden = false
                countLabel.text = "+\(usersList.count - 3)"
                
                if index == 3 {
                    
                    break
                }
            }
        }
    }
    
    func networkMonitor() {
        
        if !NetworkReachability.shared.isConnected {
                self.alertLabel.isHidden = false
                self.alertLabel.text = "Please check you’re internet connection"
        }
        
        NetworkReachability.shared.netStatusChangeHandler = {
            if !NetworkReachability.shared.isConnected {
                executeOnMainThread {
                    self.initJoinLink()
                    self.alertLabel.isHidden = false
                    self.alertLabel.text = "Please check you’re internet connection"
                }
            }else{
                executeOnMainThread {
                    self.alertLabel.isHidden = true
                    self.alertLabel.text = ""
                }
            }
        }
    }
    
    func handleErrorResponse(errorMessage: String) {
        
        if errorMessage.contains("100601"){
            
            CallManager.cleanUpJoinCallViaLink()
            let storyboard = UIStoryboard(name: "Call", bundle: nil)
            let callEndedView = storyboard.instantiateViewController(withIdentifier: "CallEndedViewController") as! CallEndedViewController
            callEndedView.isInvalidLink = true
            self.navigationController?.pushViewController(callEndedView, animated: false)
            
        }else if errorMessage.contains("100602"){
            
            CallManager.cleanUpJoinCallViaLink()
            let storyboard = UIStoryboard(name: "Call", bundle: nil)
            let callEndedView = storyboard.instantiateViewController(withIdentifier: "CallEndedViewController") as! CallEndedViewController
            callEndedView.isInvalidLink = false
            self.navigationController?.pushViewController(callEndedView, animated: false)
            
        }else if errorMessage.contains("100603"){
            
            alertLabel.isHidden = false
            alertLabel.text = "Maximum 8 members allowed in call"
            joinButton.isEnabled = false
            joinButton.alpha = 0.5
            
            AppAlert.shared.showToast(message: "Maximum 8 members allowed in call")
            CallManager.cleanUpJoinCallViaLink()
            self.navigationController?.popViewController(animated: true)
            
        }else if errorMessage.contains("100605"){
            CallManager.cleanUpJoinCallViaLink()
            self.navigationController?.popViewController(animated: true)
            
        }else {
            CallManager.cleanUpJoinCallViaLink()
            self.navigationController?.popViewController(animated: true)
        }
        
    }
}
extension JoinCallViaLinkViewController: JoinCallDelegate {
    
    func onSubscribeSuccess() {
        print("#join onSubscribeSuccess")
        joinButton.isEnabled = true
        joinButton.alpha = 1
    }
    
    func onUsersUpdated(usersList: [String]) {
        
        if usersList.count == 8 && usersList.contains(AppUtils.getMyJid()){
            return
        }
        self.updateUsersDetails(usersList: usersList)
    }
    
    func onLocalTrack(videoTrack: RTCVideoTrack?) {
        videoTrack?.add(localRenderer)
    }
    
    func onError(reason: String) {
        print("#join onError \(reason)")
    }
    
}

extension JoinCallViaLinkViewController {
    
    func checkCameraPermission(sourceType: UIImagePickerController.SourceType) {
        AppPermissions.shared.checkCameraPermissionAccess(permissionCallBack: { [weak self] authorizationStatus in
            switch authorizationStatus {
            case .denied:
                self?.isVideoPermissionEnabled = false
                self?.videoPermissionDenied()
               // AppPermissions.shared.presentSettingsForPermission(permission: .camera, instance: self as Any)
                break
            case .restricted:
                self?.isVideoPermissionEnabled = false
                self?.videoPermissionDenied()
                break
            case .authorized:
                self?.isVideoPermissionEnabled = true
                self?.videoPermissionEnabled()
                break
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [self] granted in
                    if granted {
                        print("Granted access to ")
                        self?.isVideoPermissionEnabled = true
                        self?.videoPermissionEnabled()
                    } else {
                        print("Denied access to")
                        self?.isVideoPermissionEnabled = false
                        self?.videoPermissionDenied()
                    }
                }
                break
            @unknown default:
                print("Permission failed")
                self?.isVideoPermissionEnabled = false
                self?.videoPermissionDenied()
               
            }
        })
        
    }
    
    func checkMicPermission() {
        AppPermissions.shared.checkMicroPhonePermission { [weak self] status in
            switch status {
            case .granted:
                self?.audioPermissionEnabled = true
                break
            case .denied, .undetermined:
                self?.audioPermissionEnabled = false
                AppPermissions.shared.presentSettingsForPermission(permission: .microPhone, instance: self as Any)
                break
            default:
                self?.audioPermissionEnabled = false
                AppPermissions.shared.presentSettingsForPermission(permission: .microPhone, instance: self as Any)
                break
            }
        }
    }
    
    func videoPermissionDenied() {
        
        executeOnMainThread {
            self.userProfileImage.isHidden = false
            self.videoView.bringSubviewToFront(self.userProfileImage)
            self.localRenderer.isHidden = true
            self.videoButton.isSelected = true
            CallManager.muteVideo(true)}
    }
    
    func videoPermissionEnabled() {
        
        executeOnMainThread {
            self.userProfileImage.isHidden = true
            self.videoButton.isSelected = false
            self.localRenderer.isHidden = false
            CallManager.muteVideo(false)
        }
    }
}
