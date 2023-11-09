//
//  ViewController.swift
//  GroupCallUI
//
//  Created by Vasanth Kumar on 19/05/21.
//

import UIKit
import WebRTC
import Alamofire
import PulsingHalo
import AVKit
import RxSwift
import MirrorFlySDK
import BottomSheet

enum CallMode : String{
    case Incoming
    case Outgoing
}

enum CallType : String{
    case Audio
    case Video
}

enum CallCurrentStatus: String {
    case Disconnected
    case UserBusy
    case CallEngaged
}

protocol CallViewControllerDelegate {
    func onVideoMute(status:Bool)
    func onAudioMute(status:Bool)
    func onSwitchCamera()
}

protocol CallDismissDelegate {
    func onCallControllerDismissed()
}

class CallViewController: UIViewController ,AVPictureInPictureControllerDelegate, UIAdaptivePresentationControllerDelegate{
    @IBOutlet var outgoingCallView: OutGoingCallXib!
    @IBOutlet var collectionView: UICollectionView!
    var bgcolor = UIColor(hexString: "#0D2852")
    var isTapped : Bool!
    var downloadResponse: DownloadRequest?
    var userName = String()
    var callUsersProfiles = NSMutableArray()
    var delegate : CallViewControllerDelegate?
    static var dismissDelegate : CallDismissDelegate?
    static var refreshDelegate: refreshCallLogDelegate?
    var dismissCalled = false
    var isAudioMuted = false {
        willSet {
            members.last?.isAudioMuted = newValue
        }
    }
    var isVideoMuted = false{
        willSet {
            members.last?.isVideoMuted = newValue
        }
    }
    var isBackCamera = false{
        willSet {
            members.last?.isOnBackCamera = newValue
        }
    }
    var myCallStatus : CallStatus = .calling {
        didSet {
            members.last?.callStatus = myCallStatus
        }
    }
    var panGesture  = UIPanGestureRecognizer()
    var tapGesture  = UITapGestureRecognizer()
    
    let colors = ["#3C9877","#2386CB","#A023CB","#CB2823","#23CB2B"]
    
    var callType : CallType = .Audio
    var audioPlayer : AVAudioPlayer?
    var myLocalVideoTrack : RTCVideoTrack? = nil
    
    var members : [CallMember] = []
    static var sharedInstance = CallViewController()
    var callDurationTimer : Timer?
    var seconds = -1
    var isCallConversionRequestedByMe = false
    var isCallConversionRequestedByRemote = false
    var alertController : UIAlertController?
    var VideoCallConversionTimer : Timer?
    var callViewOverlay = UIView()
    var returnToCall = UIImageView()
    
    var isOnCall = false

    var overlayShown = false
    
    var safeAreaHeight : CGFloat = 0.0
    var safeAraeWidth : CGFloat = 0.0
    var isAddParticipant = false
    var currentOutputDevice : OutputType = .receiver
    var audioDevicesAlertController : UIAlertController? = nil
    var speakingTimer : Timer? = nil
    var speakingDictionary  = Dictionary<String, Int>()
    var isLocalViewSwitched = false
    var groupId : String = ""
    var switchVideoViews = PublishSubject<Bool>()
    #if arch(arm64)
        var localRenderer = RTCMTLVideoView(frame: .zero)
        var remoteRenderer = RTCMTLVideoView(frame: .zero)
    #else
        var localRenderer = RTCEAGLVideoView(frame: .zero)
        var remoteRenderer = RTCEAGLVideoView(frame: .zero)
    #endif
    var remoteImage = emptyString()
    var callHoldLabel = UILabel()
    var isFromInvite = false
    var isVideoPermissionEnabled: Bool = false

    var localProfileImageView = UIImageView()
    
    var reloadForInVite = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("#lifecycle viewDidLoad")
        
        checkForUserBlockingByAdmin()
        
        isTapped = false
        showHideParticipantButton(hide : true)
        if let heightFormatter = NumberFormatter().number(from: Utility.getStringFromPreference(key: "safeAreaHeight")), let widthFormatter =  NumberFormatter().number(from: Utility.getStringFromPreference(key:  "safeAreaWidth")) {
            safeAreaHeight = CGFloat(Double( Utility.getStringFromPreference(key: "safeAreaHeight"))!)
            safeAraeWidth = CGFloat(Double(Utility.getStringFromPreference(key:  "safeAreaWidth"))!)
        }
        switchVideoViews.throttle(.milliseconds(200), latest: false ,scheduler: MainScheduler.instance).subscribe { [weak self] event in
            if CallManager.isOneToOneCall() && CallManager.isCallConnected(){
                self?.isLocalViewSwitched = !(self?.isLocalViewSwitched ?? false)
                self?.oneToOneVideoViewTransforms()
                self?.switchLoaclandRemoteViews()
            }
        }
    }
    //
    
    func checkForUserBlockingByAdmin() {
        if members.count == 0 {
            return
        }
        var jidToCheck = ""
        if CallManager.isOneToOneCall() {

            let filteredJid = members.filter({$0.jid != AppUtils.getMyJid()})
            if filteredJid.count > 0 {
                jidToCheck = filteredJid[0].jid
            }
        }else {
            jidToCheck = CallManager.getGroupID() ?? ""
        }
        
        

        if  ChatManager.isUserOrGroupBlockedByAdmin(jid: jidToCheck) {
            CallManager.disconnectCall()
            AppAlert.shared.showToast(message: CallManager.isOneToOneCall() ? thisUerIsNoLonger : groupNoLongerAvailable)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "isPictureInPicturePossible" else {
            return
        }
        
        //#9 read the KVO notification for the property isPictureInPicturePossible
        if let pipController = object as? AVPictureInPictureController {
            if pipController.isPictureInPicturePossible {
                //Video can be played in PIP mode.
                pipController.startPictureInPicture()
            }
        }
    }
    
    func showOneToOneAudioCallUI() {
        print("#call showOneToOneAudioCallUI")
        outgoingCallView?.isHidden = false
        collectionView?.isHidden = true
        outgoingCallView?.outGoingAudioCallImageView.isHidden = false
        outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = false
        outgoingCallView?.imageHeight.constant = 100
        outgoingCallView?.viewHeight.constant = 190
        outgoingCallView?.imageTop.constant = 8
        getContactNames()
        outgoingCallView?.backBtn.addTarget(self, action: #selector(backAction(sender:)), for: .touchUpInside)
        outgoingCallView?.localUserVideoView.isHidden = true
        outgoingCallView?.remoteUserVideoView.isHidden = true
        outgoingCallView?.cameraButton.isHidden = true
        outgoingCallView?.OutGoingCallBG.isHidden = false
        outgoingCallView?.OutGoingCallBG.image = UIImage(named: "call_bg")
        outgoingCallView?.videoButton.setImage(UIImage(named: "VideoDisabled" ), for: .normal)
        isCallConversionRequestedByMe = false
    }
    
    func showOneToOneVideoCallUI() {
        print("#call showOneToOneVideoCallUI")
        
        outgoingCallView?.localUserVideoView.isHidden = false
        outgoingCallView?.remoteUserVideoView.isHidden = false
        collectionView?.isHidden = CallManager.isOneToOneCall()
        outgoingCallView?.outGoingAudioCallImageView.isHidden = true
        outgoingCallView?.cameraButton.isHidden = false
        outgoingCallView?.outGoingAudioCallImageView.isHidden = true
        showHideDuration(hide: true)
        outgoingCallView?.OutGoingCallBG.image = nil
        outgoingCallView?.OutGoingCallBG.isHidden = true
        outgoingCallView?.contentView.backgroundColor = .clear
        getContactNames()
        outgoingCallView?.backBtn.addTarget(self, action: #selector(backAction(sender:)), for: .touchUpInside)
        outgoingCallView?.viewHeight.constant = 100
        outgoingCallView?.imageHeight.constant = 0
        if CallManager.isCallConnected() {
            showHideParticipantButton(hide : false )
        }
        if !isOnCall && CallManager.isOneToOneCall(){
            resetLocalVideCallUI()
        }
    }
    
    func showConnectedVideoCallOneToOneUI() {
        outgoingCallView?.localUserVideoView.isHidden = false
        outgoingCallView?.remoteUserVideoView.isHidden = false
        isCallConversionRequestedByMe = false
        outgoingCallView?.localVideoViewHeight.constant =  160
        outgoingCallView?.localVideoViewWidth.constant =  112
        self.localRenderer.frame = CGRect(x: 0, y: 0, width: 160, height: 112)
        outgoingCallView?.localVideoViewTrailing.constant = -16
        outgoingCallView?.localVideoViewBottom.constant = -((outgoingCallView?.callActionsViewHeight.constant ?? 0) + 16)
        outgoingCallView?.localUserVideoView.layer.cornerRadius = 12
        outgoingCallView?.localUserVideoView.layer.masksToBounds = true
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(CallViewController.draggedView(_:)))
        outgoingCallView?.localUserVideoView.isUserInteractionEnabled = true
        outgoingCallView?.localUserVideoView.addGestureRecognizer(panGesture)
        showHideDuration(hide:  false)
        if CallManager.isCallConnected() {
            getContactNames()
            showHideParticipantButton(hide : false)
            let gesture = UIPanGestureRecognizer()
            gesture.state = .ended
            draggedView(gesture)
        }
        setVideoBtnIcon()
        UIView.animate(withDuration: 0.250) { [weak self] in
            self?.view?.layoutIfNeeded()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(smallVideoTileTapped(_:)))
        outgoingCallView?.localUserVideoView?.addGestureRecognizer(tap)
        
    }
    
    @objc func draggedView(_ sender:UIPanGestureRecognizer){
        
        guard let localView = outgoingCallView?.localUserVideoView! else { return }
        let translation = sender.translation(in: view)
        
        switch sender.state {
        case .began, .changed :
            localView.center = CGPoint(x: localView.center.x + translation.x, y: localView.center.y + translation.y)
            sender.setTranslation(CGPoint.zero, in: view)
        case .ended :
            let minX = localView.frame.minX, maxX = localView.frame.maxX, minY = localView.frame.minY, maxY = localView.frame.maxY,viewMaxX = view.frame.maxX
            var viewMaxY = safeAreaHeight
            if isTapped {
                viewMaxY = safeAreaHeight
            } else {
                viewMaxY = safeAreaHeight - 172
            }
            var centerPoint : CGPoint = CGPoint(x: localView.center.x, y: localView.center.y)
            if minX < 0 && minY < 0 {
                centerPoint = CGPoint(x: localView.frame.width/2 + 12 , y: localView.frame.height/2 + 12)
            }else if minX < 0 && maxY > viewMaxY {
                centerPoint = CGPoint(x:localView.frame.width/2 + 12 , y: (viewMaxY - localView.frame.height/2) - 12)
            }else if minX < 0 {
                centerPoint = CGPoint(x: localView.frame.width/2 + 12 , y: localView.center.y)
            }else if minY < 0 && maxX > viewMaxX {
                centerPoint = CGPoint(x:(viewMaxX - localView.frame.width/2) - 12, y:  (localView.frame.height/2) + 12 )
            }else if minY < 0 {
                centerPoint = CGPoint(x:localView.center.x, y:  localView.frame.height/2 + 12)
            }else if maxX > viewMaxX && maxY > viewMaxY {
                centerPoint = CGPoint(x:(viewMaxX - localView.frame.width/2) - 12 , y: (viewMaxY - localView.frame.height/2) - 12)
            }else if maxX > viewMaxX {
                centerPoint = CGPoint(x:(viewMaxX - localView.frame.width/2) - 12, y:  localView.center.y)
            }else if maxY > viewMaxY {
                centerPoint = CGPoint(x:localView.center.x , y: (viewMaxY - localView.frame.height/2) - 12)
            }
            UIView.animate(withDuration: 0.250, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn) { [unowned self] in
                localView.center = centerPoint
                sender.setTranslation(CGPoint.zero, in: self.view)
            } completion: { _ in }

            break
        default:
            break
        }
    }
    
    
    func resetLocalVideCallUI() {
        outgoingCallView?.localUserVideoView.layer.cornerRadius = 0
        outgoingCallView?.localUserVideoView.layer.masksToBounds = true
        outgoingCallView?.localVideoViewHeight.constant = getControllerViewHeight()
        outgoingCallView?.localVideoViewWidth.constant =  getControllerViewWidth()
        outgoingCallView?.localVideoViewTrailing.constant = 0
        outgoingCallView?.localVideoViewBottom.constant = 0
    }
    
    func updateActionsUI() {
        enableDisableUserInteractionFor(view: outgoingCallView?.AttendingBottomView, isDisable: false)
        outgoingCallView?.videoButton.setImage(UIImage(named: isVideoMuted ? "VideoDisabled" :  "VideoEnabled" ), for: .normal)
        outgoingCallView?.audioButton.setImage(UIImage(named: isAudioMuted ? "IconAudioOn" :  "IconAudioOff" ), for: .normal)
        outgoingCallView?.cameraButton.setImage(UIImage(named: isBackCamera ? "IconCameraOn" :  "IconCameraOff" ), for: .normal)
    }
    
    @objc func backAction(sender: UIButton?) {
        showCallOverlay()
        dismiss(animated: false)
    }
    
    func showCallOverlay() {
        
        CallViewController.sharedInstance = self
        
        overlayShown = true
        if let controller = self.presentingViewController {
            if let cont = controller as? UINavigationController, let vc = cont.topViewController {
                ContactManager.shared.profileDelegate = vc as? ProfileEventsDelegate
            }
        }

        callViewOverlay = UIView(frame: CGRect(x: UIScreen.main.bounds.size.width - 150, y: 100, width: 150, height: 150))
        callViewOverlay.backgroundColor = UIColor.clear
        callViewOverlay.layer.cornerRadius = callViewOverlay.frame.size.height / 2
        callViewOverlay.alpha = 1.0
        callViewOverlay.tag = 1104
        
        let clearview = UIView(frame: CGRect(x: 20, y: 20, width: callViewOverlay.frame.size.width - 40, height: callViewOverlay.frame.size.height - 40))
        clearview.layer.cornerRadius = clearview.frame.size.height / 2
        clearview.layer.masksToBounds = true
        
        returnToCall = UIImageView(frame: CGRect(x: 0, y: 0, width: clearview.frame.size.width, height: clearview.frame.size.height))
        print(members)
        var membersJid = members.compactMap { $0.jid }
        
        if membersJid.contains(AppUtils.getMyJid()){
            membersJid.removeAll(where: { $0 == AppUtils.getMyJid()})
        }
        if membersJid.count == 1{
            returnToCall.image = UIImage(named: "Default Avatar_ic")
            if let contact = ChatManager.getContact(jid: membersJid[0].lowercased()){
                returnToCall.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), jid: contact.jid)
            }
        }else{
            returnToCall.image = UIImage(named: "ic_groupPlaceHolder")
        }
        
        clearview.addSubview(returnToCall)
        
        let halo = PulsingHaloLayer()
        halo.position = CGPoint(x: 75, y: 75)
        halo.radius = 85
        halo.haloLayerNumber = 10
        halo.backgroundColor = UIColor.darkGray.cgColor
        halo.start()
        callViewOverlay.layer.addSublayer(halo)
        callViewOverlay.addSubview(clearview)
        
        self.view?.window?.addSubview(callViewOverlay)
        
        let callViewTap = UITapGestureRecognizer(target: self, action: #selector(callViewTapGestureAction(_:)))
        callViewTap.numberOfTapsRequired = 1
        clearview.addGestureRecognizer(callViewTap)
    }
    
    @objc func callViewTapGestureAction(_ tapGesture: UITapGestureRecognizer?) {

        if let topController = UIApplication.shared.keyWindow?.rootViewController {
            if let presentedViewController = topController.presentedViewController {
                if presentedViewController is BottomSheetNavigationController {
                    presentedViewController.dismiss(animated: false)
                }
            }
        }
        overlayShown = false
        ContactManager.shared.profileDelegate = self
        callViewOverlay.removeFromSuperview()
        let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if let rootVC = window?.rootViewController {
            let navigationStack = UINavigationController(rootViewController: self)
            navigationStack.setNavigationBarHidden(true, animated: true)
            navigationStack.modalPresentationStyle = .overFullScreen
            rootVC.present(navigationStack, animated: true, completion: nil)
        }
    }
    
    func updateUI () {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        if !isOnCall{
            myCallStatus = .calling
        }
        outgoingCallView?.localUserVideoView.removeGestureRecognizer(panGesture)
        print("#call updateUI", CallManager.getAllCallUsersList())
        //enableButtons(buttons: outgoingCallView?.audioButton, isEnable: false)
        updateActionsUI()
        
        // configure UI of AudioPicker
        
        delegate = self
        showHideParticipantButton(hide :true)
        showHideCallAgainView(show: false, status: "Trying to connect")
        if CallManager.getCallDirection() == .Incoming {
            updateCallStatus(status: "Connecting")
        } else {
            updateCallStatus(status: "Trying to connect")
        }
        if CallManager.getCallMode() == .MEET && members.isEmpty{
            addMyInfoToMembersArray()
        }
        for (memberJid,status) in CallManager.getCallUsersWithStatus() {
            _ = validateAndAddMember(jid: memberJid, with: convertCallStatus(status: status), shouldReload: true)
        }
        if CallManager.isOneToOneCall() {
            if CallManager.getCallType() == .Audio {
                showOneToOneAudioCallUI()
            } else {
                showOneToOneVideoCallUI()
                if CallManager.isCallConnected() {
                    showConnectedVideoCallOneToOneUI()
                }
                outgoingCallView?.videoButton.setImage(UIImage(named: "VideoEnabled" ), for: .normal)
            }
        } else {
            self.outgoingCallView?.OutGoingCallBG.isHidden = true
            self.outgoingCallView?.cameraButton.isHidden = isVideoMuted
            self.collectionView?.isHidden = false
            if let collectionView = self.collectionView , (collectionView.numberOfItems(inSection: 0) == 0 || (members.count != collectionView.numberOfItems(inSection: 0))){
                self.collectionView?.isHidden = false
                self.collectionView?.reloadData()
            }
            for member in members {
                if member.callStatus == .connected && CallManager.getCallType() == .Video {
                    if !member.isVideoMuted{
                        addGroupTracks(jid: member.jid)
                    }
                }
            }
            showGroupCallUI()
        }
        if CallManager.getCallType() == .Video{
            outgoingCallView?.videoButton.setImage(UIImage(named: "VideoEnabled" ), for: .normal)
            if CallManager.getCallDirection() == .Incoming {
               // _ = requestForVideoTrack()
            }
        }
        setMuteStatusText()
        if CallManager.isCallConnected(){
            isOnCall = true
            updateCallStatus(status:getStatusOfOneToOneCall())
            showHideParticipantButton(hide :false)
           enableButtons(buttons: outgoingCallView?.videoButton, isEnable: true)
        }else{
            showHideParticipantButton(hide :true)
            updateCallStatus(status: CallManager.getCallDirection() == .Incoming ? "Connecting" : "Trying to connect")
            enableButtons(buttons: outgoingCallView?.videoButton, isEnable: false)
        }
        if CallManager.getCallMode() == .MEET{
            enableButtons(buttons: outgoingCallView?.videoButton, isEnable: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("#meet #lifecycle viewWillAppear")
        navigationController?.setNavigationBarHidden(true, animated: false)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        ChatManager.shared.connectionDelegate = self
        CallManager.delegate = self
        AudioManager.shared().audioManagerDelegate = self
        dismissCalled = false
        updateUI()
        if CallManager.getCallMode() == .MEET {
            outgoingCallView?.localUserVideoView.willRemoveSubview(localRenderer)
            outgoingCallView?.remoteUserVideoView.willRemoveSubview(remoteRenderer)
            outgoingCallView?.localUserVideoView.isHidden = true
            outgoingCallView?.remoteUserVideoView.isHidden = true
            localRenderer.removeFromSuperview()
            remoteRenderer.removeFromSuperview()
            isAudioMuted = CallManager.isAudioMuted()
            isVideoMuted = CallManager.isVideoMuted()
            myCallStatus = .connected
            addMyInfoToMembersArray()
            self.outgoingCallView?.OutGoingCallBG.isHidden = true
            self.outgoingCallView?.cameraButton.isHidden = isVideoMuted
            self.collectionView?.isHidden = false
            isOnCall = true
            enableButtons(buttons: outgoingCallView?.videoButton, isEnable: true)
        }else if CallManager.isOneToOneCall(){
            outgoingCallView?.localUserVideoView.isHidden = false
            if CallManager.isCallConnected(){
                outgoingCallView?.remoteUserVideoView.isHidden = false
            }
            updateCallStatus(status: getStatusOfOneToOneCall())
        }else{
            updateCallStatus(status: getCurrentCallStatusAsString())
        }
        if isOnCall {
            outgoingCallView?.localUserVideoView.addGestureRecognizer(panGesture)
        }else{
            outgoingCallView?.localUserVideoView.removeGestureRecognizer(panGesture)
        }
        setTopViewsHeight()
        outgoingCallView?.addParticipantBtn.addTarget(self, action: #selector(addParticipant(sender:)), for: .touchUpInside)
        if isFromInvite {
            isFromInvite = false
        } else {
            self.collectionView?.delegate = self
            self.collectionView?.dataSource = self
        }
        
        if isAddParticipant == false {
           
            collectionView?.backgroundColor = bgcolor
            getContactNames()
            if isOnCall{
                seconds = UserDefaults.standard.object(forKey: "seconds") as? Int ?? -1
                
                updateCallDuration()
            }else{
                UserDefaults.standard.removeObject(forKey: "seconds")
            }
            if CallManager.isCallConnected() && (myCallStatus == .connected || myCallStatus == .reconnected){
                self.showHideParticipantButton(hide :false)
            }else{
                self.showHideParticipantButton(hide : true)
            }
            outgoingCallView?.callEndBtn.addTarget(self, action: #selector(callEndlBtnTapped(sender:)), for: .touchUpInside)
            outgoingCallView?.videoButton.addTarget(self, action: #selector(videoButtonTapped(sender:)), for: .touchUpInside)
            outgoingCallView?.audioButton.addTarget(self, action: #selector(AudioButtonTapped(sender:)), for: .touchUpInside)
            outgoingCallView?.speakerButton.addTarget(self, action: #selector(showAudioActionSheet(sender:)), for: .touchUpInside)
            outgoingCallView?.cameraButton.addTarget(self, action: #selector(CameraButtonTapped(sender:)), for: .touchUpInside)
            outgoingCallView?.cancelButton.addTarget(self, action: #selector(cancelBtnTapped(sender:)), for: .touchUpInside)
            outgoingCallView?.CallAgainButton.addTarget(self, action: #selector(callAgainBtnTapped(sender:)), for: .touchUpInside)
        }
        if CallManager.isOneToOneCall() {
            if CallManager.getCallType() == .Video && CallManager.isCallConnected() {
                showConnectedVideoCallOneToOneUI()
            }
        } else {
            if isOnCall && self.checkIfGroupCallUiIsVisible() {
                showGroupCallUI()
            }
        }
        if CallManager.isCallConnected() && (myCallStatus == .connected || myCallStatus == .reconnected || myCallStatus == .onHold){
            self.showHideParticipantButton(hide : false)
        }else{
            self.showHideParticipantButton(hide : true)
        }
        setActionIconsAfterMaximize()
        updateActionsUI()
        setMuteStatusText()
        setVideoBtnIcon()
        isAddParticipant = false
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(SingleTapGesturTapped(_:)))
        if CallManager.getCallType() == .Video{
            outgoingCallView?.imageHeight.constant = 0
        }
        validateAndUpdateRoutingIcon()
        checkCameraPermission(sourceType: .camera)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("#meet #lifecycle viewDidAppear \(CallManager.getCallMode().rawValue) || \(CallManager.isOneToOneCall()) || \(CallManager.getAllCallUsersList()) || \(CallManager.getCallType().rawValue) ||  \(members.first?.isVideoMuted) || \(members.first?.videoTrack)")
        ContactManager.shared.profileDelegate = self
        isAudioMuted = CallManager.isAudioMuted()
        isVideoMuted = CallManager.isVideoMuted()
        updateActionsUI()
        if reloadForInVite{
            collectionView?.isHidden = false
            if CallManager.getCallType() == .Video && !CallManager.isOneToOneCall(){
                for member in members.map({$0.jid!}) {
                    addGroupTracks(jid: member)
                }
            }
            reloadForInVite = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("#lifecycle viewWillDisappear")
        super.viewWillDisappear(animated)
        if overlayShown == false {
            ContactManager.shared.profileDelegate = nil
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("#lifecycle viewDidDisappear")
        CallManager.delegate = RootViewController .sharedInstance
        if callDurationTimer != nil && isAddParticipant == false {
            callDurationTimer?.invalidate()
            callDurationTimer = nil
            seconds = -1
            clearViews()
        }
        ChatManager.shared.connectionDelegate = nil
       // UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        AudioManager.shared().audioManagerDelegate = nil
    }
    
    func clearViews() {
        showHideParticipantButton(hide : true)
        updateCallStatus()
        outgoingCallView?.OutGoingPersonLabel.text = ""
        showHideDuration(hide: true)
        outgoingCallView?.audioMuteStackView.isHidden = true
        callDurationTimer?.invalidate()
        callDurationTimer = nil
        seconds = -1
        isCallConversionRequestedByMe = false
        isCallConversionRequestedByRemote = false
        print("#mute clearViews \(isAudioMuted) video \(isVideoMuted) ")
        updateActionsUI()
    }
    
    
    func showHideCallAgainView(show: Bool,status: String) {
        if let outgoingCallView = outgoingCallView, CallManager.getCallMode() != .MEET{
            self.outgoingCallView?.localUserVideoView.removeGestureRecognizer(panGesture)
            self.outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = status.isEmpty
            updateCallStatus(status: CallManager.isCallOnHold() ? CallStatus.onHold.rawValue : CallManager.isCallConnected() ? CallStatus.connected.rawValue : status )
            if show {
                self.outgoingCallView?.backBtn.isHidden = true
                self.outgoingCallView?.AttendingBottomView.isHidden = true
                self.outgoingCallView?.callAgainView.isHidden = false
                if CallManager.getCallType() == .Audio{
                    self.outgoingCallView?.CallAgainButton.setImage(UIImage(named: "callAgain"), for: .normal)
                }else{
                    self.outgoingCallView?.CallAgainButton.setImage(UIImage(named: "call again_ic"), for: .normal)
                }
                
            } else {
                self.outgoingCallView?.backBtn.isHidden = false
                self.outgoingCallView?.callAgainView.isHidden = true
                self.outgoingCallView?.AttendingBottomView.isHidden = false
            }
        }
    }
    
    @objc func cancelBtnTapped(sender:UIButton) {
        CallManager.disconnectCall()
        self.dismiss()
    }
    
    @objc func callEndlBtnTapped(sender:UIButton) {
        CallManager.disconnectCall()
        self.dismissWithDelay()
    }
    
    @objc func videoButtonTapped(sender:UIButton) {
        print("isVideoMuted \(isVideoMuted)")
        
        if isVideoPermissionEnabled {
            
            if CallManager.isCallOnHold(){
                return
            }
            
            if CallManager.isOneToOneCall() && CallManager.getCallType() == .Audio {
                callConversionPopup()
            } else {
                print("#mute videoButtonTapped else")
                isVideoMuted.toggle()
                if !CallManager.isOneToOneCall(){
                    if members.last?.videoTrack == nil{
                        print("#mute videoButtonTapped if if isVideoMuted: false")
                        CallManager.enableVideo()
                    }
                }
                delegate?.onVideoMute(status: isVideoMuted)
            }
        } else {
            
            AppPermissions.shared.presentSettingsForPermission(permission: .camera, instance: self as Any)
        }
    }
    
    func dismiss() {
        print("#lifecycle dismiss")
        myCallStatus = .disconnected
        isLocalViewSwitched = false
        reloadForInVite = false
        seconds = -1
        isBackCamera = false
        isVideoMuted = false
        isAudioMuted = false

        speakingDictionary.removeAll()
        removeAllMembers()
        isOnCall = false
        myCallStatus = .calling
        if outgoingCallView != nil { // check this condition if ui is presented
            clearViews()
            showHideCallAgainView(show: false, status: "")
            dismiss(animated: true, completion: nil)
            if dismissCalled == false {
                CallViewController.dismissDelegate?.onCallControllerDismissed()
            }
            dismissCalled = true
        }
    }
    
    
    @objc func callAgainBtnTapped(sender:UIButton) {
        if CallManager.isAlreadyOnAnotherCall(){
            AppAlert.shared.showToast(message: "You’re already on call, can't make new MirrorFly call")
            return
        }
        CallManager.disconnectCall()
        myCallStatus = .calling
        showHideCallAgainView(show: false, status: "Trying to connect")
        let callAgainaMembers = members.compactMap{$0.jid}
        removeAllMembers()
        makeCall(usersList: callAgainaMembers, callType: callType, onCompletion: { isSuccess, message in
            if(!isSuccess){
                let errorMessage = AppUtils.shared.getErrorMessage(description: message)
                AppAlert.shared.showAlert(view: self, title: "", message: errorMessage, buttonTitle: "Okay")
            }
        })
    }
    
    @objc func CameraButtonTapped(sender:UIButton) {
        isBackCamera.toggle()
        if isBackCamera{
            if CallManager.isOneToOneCall() {
                UIView.animate(withDuration: 0.6, delay: 0.0, options: [], animations: { [weak self] in
                    self?.oneToOneVideoViewTransforms()
                })
            }else{
                if let myCell = collectionView?.cellForItem(at: IndexPath(item: findIndexOfUser(jid: AppUtils.getMyJid()) ?? members.count - 1, section: 0)) as? GroupCallCell{
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                        myCell.videoBaseView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    }
                }
            }
        }else{
            if CallManager.isOneToOneCall() {
                UIView.animate(withDuration: 0.6, delay: 0.0, options: [], animations: { [weak self] in
                    self?.oneToOneVideoViewTransforms()
                })
            }else{
                if let myCell = collectionView?.cellForItem(at: IndexPath(item: findIndexOfUser(jid: AppUtils.getMyJid()) ?? members.count - 1, section: 0)) as? GroupCallCell{
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) { [self] in
                        let member = members[findIndexOfUser(jid: AppUtils.getMyJid()) ?? 0]
                        if !member.isVideoMuted {
                            myCell.videoBaseView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                        }
                    }
                }
            }
        }
        delegate?.onSwitchCamera()
    }
    
    @objc func AudioButtonTapped(sender:UIButton) {
        if CallManager.isCallOnHold(){
            return
        }
        isAudioMuted.toggle()
        members.last?.isAudioMuted = isAudioMuted
        delegate?.onAudioMute(status: isAudioMuted)
    }
    
    @objc func SingleTapGesturTapped(_ sender: UITapGestureRecognizer) {
        // if members.count == 2 {
        
        print(self.outgoingCallView?.localUserVideoView.frame.origin.y)
        
        if isTapped == false{
            isTapped = true
            let bottom = CGAffineTransform(translationX: 0, y: 200)
            let top = CGAffineTransform(translationX: 0, y: -400)
            
            UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
                if !CallManager.isOneToOneCall() || CallManager.getCallType() == .Video{
                    self.outgoingCallView?.AttendingBottomView.transform = bottom
                    self.outgoingCallView?.OutGoingPersonLabel.transform = top
                    self.outgoingCallView?.timerLable.transform = top
                    self.outgoingCallView?.outGoingAudioCallImageView.transform = top
                    self.outgoingCallView?.OutgoingRingingStatusLabel?.transform = top
                }
            }, completion: nil)
        }else{
            isTapped = false
            let top = CGAffineTransform(translationX: 0, y: -20)
            let bottom = CGAffineTransform(translationX: 0, y: 0)
            
            let viewMaxY = safeAreaHeight - 172
            if let localView = self.outgoingCallView?.localUserVideoView{
                if localView.frame.maxY > viewMaxY {
                    let gesture = UIPanGestureRecognizer()
                    gesture.state = .ended
                    if isOnCall{
                        draggedView(gesture)
                    }
                }
            }
            
            UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
                if CallManager.getCallType() == .Video || !CallManager.isOneToOneCall() {
                    self.outgoingCallView?.imageHeight.constant = 0
                    self.outgoingCallView?.timerTop.constant = 0
                }else{
                    self.outgoingCallView?.imageHeight.constant = 100
                    self.outgoingCallView?.timerTop.constant = 8
                    self.outgoingCallView?.outGoingAudioCallImageView.transform = bottom
                }
                self.outgoingCallView?.AttendingBottomView.transform = top
                self.outgoingCallView?.AttendingBottomView.transform = top
                self.outgoingCallView?.OutGoingPersonLabel.transform = bottom
                self.outgoingCallView?.timerLable.transform = bottom
                self.outgoingCallView?.OutgoingRingingStatusLabel?.transform = bottom
            }, completion: nil)
        }
        
        if self.outgoingCallView?.localUserVideoView.frame.origin.y == 480.0 ||  self.outgoingCallView?.localUserVideoView.frame.origin.y == 280.0 || self.outgoingCallView?.localUserVideoView.frame.origin.y == 320.0{
            if isTapped == true{
                let bottom = CGAffineTransform(translationX: 0, y: 160)
                UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
                    self.outgoingCallView?.localUserVideoView.transform = bottom
                    self.callHoldLabel.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }, completion: nil)
            }else{
                let top = CGAffineTransform(translationX: 0, y: -40)
                UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
                    self.outgoingCallView?.localUserVideoView.transform = top
                    self.callHoldLabel.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }, completion: nil)
            }
            
            print(self.outgoingCallView?.localUserVideoView.frame.origin.y)
            
        }
        
    }
    
    func setMemberIniitals(name : String , imageView: UIImageView)
    {
        let lblNameInitialize = UILabel()
        lblNameInitialize.frame.size = CGSize(width: 50, height: 50)
        lblNameInitialize.textColor = UIColor.white
        lblNameInitialize.font = AppFont.Medium.size(20)
        lblNameInitialize.text = name.getAcronyms()
        lblNameInitialize.textAlignment = NSTextAlignment.center
        lblNameInitialize.layer.cornerRadius = 50.0
        
        UIGraphicsBeginImageContext(lblNameInitialize.frame.size)
        lblNameInitialize.layer.render(in: UIGraphicsGetCurrentContext()!)
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    @objc func updateCallDuration() {
        if CallManager.getCallMode() == .MEET{
            return
        }
        getContactNames()
        if callDurationTimer == nil {
            callDurationTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateCallDuration), userInfo: nil, repeats: true)
            outgoingCallView?.timerLable.isHidden = false
        }
        seconds = seconds + 1
        UserDefaults.standard.set(seconds, forKey: "seconds")
        
        let duration: TimeInterval = TimeInterval(seconds) //seconds++
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional // Use the appropriate positioning for the current locale
        if seconds >= 3600 {
            formatter.allowedUnits = [ .hour, .minute, .second ] // Units to display in the formatted string
        }
        else {
            formatter.allowedUnits = [.minute, .second]
        }
        formatter.zeroFormattingBehavior = [ .pad] // Pad with zeroes where appropriate for the locale
        
        let formattedDuration = formatter.string(from: duration)
        outgoingCallView?.timerLable?.text = formattedDuration
    }
    
    func updateOneToOneAudioCallUI() {
        showOneToOneAudioCallUI()
        outgoingCallView?.imageHeight.constant = 100
        outgoingCallView?.viewHeight.constant = 190
        outgoingCallView?.imageTop.constant = 8
        showHideDuration(hide: false)
        outgoingCallView?.timerTop.constant = 8
        outgoingCallView?.outGoingAudioCallImageView.transform = CGAffineTransform(translationX: 0, y: 0)
        getContactNames()
        if CallManager.isCallConnected() {
            updateCallStatus(status: (CallManager.isCallConnected() && !CallManager.isOneToOneCall()) ? CallStatus.connected.rawValue :  getStatusOfOneToOneCall())
            setMuteStatusText()
            showHideParticipantButton(hide :false)
        }
    }
    
    func getContactNames(){
         if CallManager.getCallMode() == .MEET {
             outgoingCallView?.OutGoingPersonLabel.text = ""
            return
        }
        var unknowGroupMembers = [String]()
        let membersJid = members.compactMap { $0.jid }.filter {$0 != AppUtils.getMyJid()}
        if membersJid.count == 0 {
            return
        }
        if membersJid.count == 1 {
            if let contact = ChatManager.getContact(jid: membersJid[0].lowercased()){
                outgoingCallView?.OutGoingPersonLabel.text = getNameStringWithGroupName(userNames: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
            }
        } else if membersJid.count == 2 {
            for i in 0...1{
                if let contact = ChatManager.getContact(jid: membersJid[i].lowercased()){
                    unknowGroupMembers.append(getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
                }
            }
            let groupMemberName = unknowGroupMembers.joined(separator: ",")
            outgoingCallView?.OutGoingPersonLabel.text = getNameStringWithGroupName(userNames: groupMemberName)
            outgoingCallView?.outGoingAudioCallImageView.image = UIImage.init(named: "ic_groupPlaceHolder")
        } else if membersJid.count > 2{
            unknowGroupMembers.removeAll()
            for i in 0...1{
                if let contact = ChatManager.getContact(jid: membersJid[i].lowercased()){
                    unknowGroupMembers.append(getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
                }
            }
            let groupMemberName = unknowGroupMembers.joined(separator: ",")
            var nameString = groupMemberName
            if nameString.count > 32 {
                nameString = groupMemberName.substring(to: 31) + "..."
            }
            outgoingCallView?.OutGoingPersonLabel.text = getNameStringWithGroupName(userNames:  String(format: "%@ and (+ %lu)", nameString, membersJid.count - 2))
        }else {
            outgoingCallView?.OutGoingPersonLabel.text = ""
        }
        
        if groupId.isEmpty  && membersJid.count == 1{
            if let contact = ChatManager.profileDetaisFor(jid: membersJid[0].lowercased()), !contact.image.isEmpty{
                outgoingCallView?.outGoingAudioCallImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), jid: contact.jid)
            }else{
                outgoingCallView?.outGoingAudioCallImageView.image = UIImage.init(named: "ic_profile_placeholder")
            }
        }else{
            if let contact = ChatManager.profileDetaisFor(jid: groupId), !contact.image.isEmpty{
                outgoingCallView?.outGoingAudioCallImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), jid: contact.jid)
            }else{
                outgoingCallView?.outGoingAudioCallImageView.image = UIImage.init(named: "ic_groupPlaceHolder")
            }
        }
    }
    
    func getNameStringWithGroupName(userNames : String) -> String{
        var name = ""
        if !groupId.isEmpty{
            if let group = ChatManager.profileDetaisFor(jid: groupId){
                outgoingCallView?.OutGoingPersonLabel.numberOfLines = 2
                name = group.name + "\n" + userNames
            }
        }else{
            outgoingCallView?.OutGoingPersonLabel.numberOfLines = 1
            name = userNames
        }
        return name
    }
    
    func showGroupCallUI() {
        showOneToOneVideoCallUI()
        collectionView?.isHidden = false
        showHideDuration(hide: false)
        outgoingCallView?.imageHeight.constant = 0
        outgoingCallView?.timerTop.constant = 0
        if CallManager.getCallType() == .Video && !isOnCall {
        }else {
            outgoingCallView?.cameraButton.isHidden = isVideoMuted
        }
        outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = false
        outgoingCallView?.localUserVideoView.isHidden = true
        outgoingCallView?.remoteUserVideoView.isHidden = true
        getContactNames()
        outgoingCallView?.audioMuteStackView.isHidden = true
        updateCallStatus(status:  CallManager.isCallConnected() ? CallStatus.connected.rawValue : getCurrentCallStatusAsString() )
        collectionView?.reloadData()
        collectionView?.performBatchUpdates(nil, completion: {
            (result) in
            for member in self.members{
                self.addGroupTracks(jid: member.jid)
            }
        })
    }
    
    func updateOneToOneVideoCallUI() {
        showOneToOneVideoCallUI()
        showHideDuration(hide: false)
//        showConnectedVideoCallOneToOneUI()
    }
    
    func setMuteStatusText() {
        DispatchQueue.main.async { [weak self] in
            if CallManager.isOneToOneCall() {
                let isCallConnected = self?.isOnCall ?? false
                let remoteAudioMuted = self?.members.first?.isAudioMuted ?? false, remoteVideoMuted =  (self?.members.first?.isVideoMuted ?? false && isCallConnected)
                let myVideoMuted =  self?.isVideoMuted
                let showHideView = remoteAudioMuted || remoteVideoMuted
                self?.outgoingCallView?.audioMuteStackView.isHidden = !showHideView
                self?.outgoingCallView?.audioMuteStackView.arrangedSubviews[1].isHidden = !remoteAudioMuted
                self?.outgoingCallView?.audioMuteStackView.arrangedSubviews.first?.isHidden = true
                if (remoteVideoMuted && CallManager.getCallType() == .Video)  && remoteAudioMuted {
                    self?.outgoingCallView?.audioMuteStackView.arrangedSubviews.first?.isHidden = false
                    self?.outgoingCallView?.audioMutedLable.text = "\(self?.members.first?.name ?? "") muted audio and video"
                } else if remoteVideoMuted && CallManager.getCallType() == .Video {
                    self?.outgoingCallView?.audioMuteStackView.arrangedSubviews.first?.isHidden = false
                    self?.outgoingCallView?.audioMutedLable.text = "\(self?.members.first?.name ?? "")'s camera turned off"
                } else  if remoteAudioMuted{
                    self?.outgoingCallView?.audioMuteStackView.arrangedSubviews.first?.isHidden = true
                    self?.outgoingCallView?.audioMutedLable.text = "\(self?.members.first?.name ?? "")'s microphone turned off"
                }
                if (remoteVideoMuted == true) && (myVideoMuted == true){
                    self?.outgoingCallView?.audioMuteStackView.arrangedSubviews.first?.isHidden = true
                    if remoteAudioMuted {
                        self?.outgoingCallView?.audioMutedLable.text = "\(self?.members.first?.name ?? "")'s microphone turned off"
                    }else{
                        self?.outgoingCallView?.audioMuteStackView.isHidden = true
                    }
                    self?.outgoingCallView?.videoButton.setImage(UIImage(named: "VideoDisabled" ), for: .normal)
                }
            }else {
                self?.outgoingCallView?.audioMuteStackView.isHidden = true
            }
        }
    }
    
}


// MARK:- Call Switch pop up
extension CallViewController {
    
    // Show confirmation pop up for call Switching
    func callConversionPopup() {
        //showConfirmationAlertForCallSwitching
        alertController?.dismiss(animated: false)
        alertController = UIAlertController.init(title: nil , message: "Are you sure you want to switch to Video Call", preferredStyle: .alert)
        let switchAction = UIAlertAction(title: "Switch", style: .default) { [weak self] (action) in
            CallManager.requestVideoCallSwitch { isSuccess in
                if isSuccess {
                    self?.isCallConversionRequestedByMe = true
                    self?.showAlertViewWithIndicator()
                    self?.VideoCallConversionTimer = Timer.scheduledTimer(timeInterval: 20, target: self ?? CallViewController.self, selector: #selector(self?.videoCallConversionTimer), userInfo: nil, repeats: false)
                }
            }
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { [weak self] (action) in
            CallManager.setCallType(callType: .Audio)
            self?.isCallConversionRequestedByMe = false
            self?.resetConversionTimer()
        }
        alertController?.addAction(switchAction)
        alertController?.addAction(cancelAction)
        //  let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        DispatchQueue.main.async { [weak self] in
            if let alert = self?.alertController {
                self?.present(alert, animated: true, completion: {
                })
            }
            
        }
    }
    
    func showAlertViewWithIndicator() {
        if self.isCallConversionRequestedByMe && self.isCallConversionRequestedByRemote{
            CallManager.setCallType(callType: .Video)
            CallManager.acceptVideoCallSwitchRequest()
            isVideoMuted = false
            switchAudioToVideoCall()
            isCallConversionRequestedByMe = false
            isCallConversionRequestedByRemote = false
            resetConversionTimer()
            DispatchQueue.main.async  {  [weak self] in
                self?.alertController?.dismiss(animated: true, completion: nil)
            }
        }else {
            alertController = UIAlertController.init(title: "Requesting to switch to video call." , message: "", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .default) { [weak self] (action) in
                // Cancel Request
                CallManager.cancelVideoCallSwitch()
                self?.resetConversionTimer()
                self?.isCallConversionRequestedByMe = false
                self?.updateOneToOneAudioCallUI()
            }
            alertController?.addAction(cancelAction)

            if CallManager.getCallType() == .Video {
                resetConversionTimer()
            }else{
                DispatchQueue.main.async  {  [weak self] in
                    if let alert = self?.alertController {
                        if !(self?.isCallConversionRequestedByRemote ?? false) && CallManager.getCallType() != .Video {
                            self?.present(alert, animated: true, completion: {
                                self?.isCallConversionRequestedByMe = true
                            })
                        }else{
                            self?.resetConversionTimer()
                        }
                    }
                }
            }
        }
    }
    
    func showCallConversionConfirmationRequest() {
        if self.isCallConversionRequestedByMe && self.isCallConversionRequestedByRemote{
            CallManager.setCallType(callType: .Video)
            CallManager.acceptVideoCallSwitchRequest()
            isVideoMuted = false
            switchAudioToVideoCall()
            isCallConversionRequestedByMe = false
            isCallConversionRequestedByRemote = false
        }else {
            alertController?.dismiss(animated: false)
            alertController = UIAlertController.init(title: "Requesting Video Call." , message: "", preferredStyle: .alert)
            let acceptAction = UIAlertAction(title: "Accept", style: .default) { [weak self] (action) in
                if !CallManager.checkIsUserCanceled() {
                    CallManager.acceptVideoCallSwitchRequest()
                    self?.isVideoMuted = false
                    CallManager.setCallType(callType: .Video)
                    self?.isCallConversionRequestedByMe = false
                    self?.isCallConversionRequestedByRemote = false
                    self?.switchAudioToVideoCall()
                    CallManager.muteVideo(false)
                    AudioManager.shared().autoReRoute()
                }
            }
            
            let cancelAction = UIAlertAction(title: "Decline", style: .default) { [weak self] (action) in
                self?.alertController?.dismiss(animated: true, completion: nil)
                CallManager.setCallType(callType: .Audio)
                // Cancel Request
                CallManager.declineVideoCallSwitchRequest()
                self?.isCallConversionRequestedByMe = false
                self?.updateOneToOneAudioCallUI()
                self?.isCallConversionRequestedByRemote = false
            }
            alertController?.addAction(acceptAction)
            alertController?.addAction(cancelAction)
            
            if CallManager.getCallType() == .Video {
                resetConversionTimer()
            }else {
                DispatchQueue.main.async {  [weak self] in
                    if let alert = self?.alertController {
                        if !(self?.isCallConversionRequestedByMe ?? false) && CallManager.getCallType() != .Video {
                            self?.present(alert, animated: true, completion: nil)
                        }else{
                            self?.resetConversionTimer()
                        }
                    }
                }
            }
        }
    }
    
    @objc func videoCallConversionTimer() {
        alertController?.dismiss(animated: true, completion: nil)
        if CallManager.getCallType() != .Video {
            CallManager.setCallType(callType: .Audio)
            isCallConversionRequestedByMe = false
            updateOneToOneAudioCallUI()
            CallManager.cancelVideoCallSwitch()
        }
    }
    
    func resetConversionTimer(){
        VideoCallConversionTimer?.invalidate()
        VideoCallConversionTimer = nil
        alertController?.dismiss(animated: true, completion: nil)
        isCallConversionRequestedByRemote = false
    }
}


extension CallViewController : UICollectionViewDelegate , UICollectionViewDataSource , UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(members.count)
        if (members.count == 8) || CallManager.getCallMode() == .MEET {
            showHideParticipantButton(hide :true)
        }
        return members.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("#call collectionView \(members.count)")
        let groupCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: GroupCallCell.identifier, for: indexPath) as! GroupCallCell
        let member = members[indexPath.row]
        let isLastRow = (indexPath.row == members.count - 1)
        let callStatus =  isLastRow ? (CallManager.getCallStatus(userId: member.jid) == .ON_HOLD  ? .onHold : .connected) : convertCallStatus(status: CallManager.getCallStatus(userId: member.jid))
        if member.jid == AppUtils.getMyJid() && CallManager.getCallStatus(userId: member.jid) == .ON_HOLD{
            _ = updateCallStatus(jid: member.jid, status: .onHold)
        }
        groupCell.profileName.font = AppFont.Regular.size(14)
        groupCell.contentView.backgroundColor = UIColor(hexString: member.color)
        groupCell.videoMuteImage.isHidden = !member.isVideoMuted
        if callStatus == .connected {
            groupCell.audioIconImageView.isHidden = !member.isAudioMuted
            groupCell.foreGroundView.isHidden = true
            groupCell.callActionsView.isHidden = false
            groupCell.statusLable.textColor = UIColor(hexString: "#FFFFFF")
        }
        if isLastRow {
            groupCell.profileName.text = members.count == 1 ? "" : "You"
            groupCell.foreGroundView.isHidden = true
            groupCell.callActionsView.isHidden = false
            groupCell.audioIconImageView.isHidden = true
            print("my status allTpe: \(CallManager.getCallType()) isVideoMuted: \(member.isVideoMuted) videoTrack \(member.videoTrack != nil)")
            if  CallManager.getCallType() == .Video ||  (member.videoTrack != nil && !member.isVideoMuted){
//                groupCell.videoBaseView.isHidden = member.isVideoMuted
//                groupCell.profileImage.isHidden = !member.isVideoMuted
                if isBackCamera {
                    groupCell.videoBaseView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }else {
                   // groupCell.videoBaseView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                }
            } else {
               // groupCell.profileImage.isHidden = false
                groupCell.videoBaseView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }
        } else {
            groupCell.profileName.text = member.name
            groupCell.videoBaseView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }
        if (isLastRow  && member.callStatus == .reconnecting) || (!isLastRow && member.callStatus != .connected) || member.callStatus == .onHold || (isLastRow && CallManager.isCallOnHold()){
            //groupCell.profileImage.isHidden = false
            groupCell.foreGroundView.isHidden = false
            groupCell.callActionsView.isHidden = true
            groupCell.statusLable.text = member.callStatus.rawValue.capitalized
        }else{
            groupCell.foreGroundView.isHidden = true
            groupCell.callActionsView.isHidden = false
            groupCell.statusLable.textColor = UIColor(hexString: "#FFFFFF")
        }
        
        
        if let profileDetail = ContactManager.shared.getUserProfileDetails(for: member.jid) {
            
            let profileImageStr = profileDetail.thumbImage.isEmpty ? profileDetail.image : profileDetail.thumbImage
            
            groupCell.videoBaseView.loadFlyImage(imageURL: profileImageStr, name: getUserName(jid : profileDetail.jid ,name: profileDetail.name, nickName: profileDetail.nickName, contactType: profileDetail.contactType), chatType: profileDetail.profileChatType,contactType: profileDetail.contactType, jid: profileDetail.jid, isBlockedByAdmin: ContactManager.shared.getUserProfileDetails(for: profileDetail.jid)?.isBlockedByAdmin ?? false)
            
            if !profileImageStr.isEmpty {
                groupCell.videoBaseView.contentMode = .scaleAspectFill
//                member.jid == AppUtils.getMyJid() ? "" : member.name
            }else{
                Utility.IntialLetter(name: member.name, imageView: groupCell.videoBaseView, colorCode: member.color,frameSize: 128,fontSize: 64)
            }
        }else {
            
            let (userName, profileImg) = CallManager.getUserNameAndImage(userId: member.jid)
            Utility.IntialLetter(name: member.name, imageView: groupCell.videoBaseView, colorCode: member.color,frameSize: 128,fontSize: 64)
            Utility.download(token: profileImg, profileImage: groupCell.videoBaseView, uniqueId: member.jid,name: userName,colorCode: member.color,frameSize: 128,fontSize: 64,notify: true, completion: {
            })
        }

        if CallManager.getCallType() == .Video && !member.isVideoMuted {

            if let videoView = groupCell.videoBaseView {
                member.videoTrackView.removeFromSuperview()
                videoView.willRemoveSubview(member.videoTrackView)
            }
            #if arch(arm64)
            let localRen = RTCMTLVideoView(frame: .zero)
            #else
            let localRen = RTCEAGLVideoView(frame: .zero)
            #endif
            if let baseView = groupCell.videoBaseView {
                member.videoTrackView = localRen
                member.videoTrackView.frame = CGRect(x: 0, y: 0, width: baseView.bounds.width, height: baseView.bounds.height)
                if member.jid == AppUtils.getMyJid() {
                    let track = CallManager.getRemoteVideoTrack(jid: member.jid)
                    print("#remoteTrack 1243 \(member.jid), \(track)")
                    member.videoTrack = track
                    track?.add(member.videoTrackView)
                    //member.videoTrack?.add(member.videoTrackView)
                } else {
                    let videoTrack = CallManager.getRemoteVideoTrack(jid: member.jid)
                    print("#remoteTrack 1248 \(member.jid), \(videoTrack)")
                    videoTrack?.add(member.videoTrackView)
                }
                baseView.addSubview(member.videoTrackView)
                groupCell.videoMuteImage.isHidden = true
            }
        }

        return groupCell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let lastRowIndex = collectionView.numberOfItems(inSection: collectionView.numberOfSections-1)
        let width = collectionView.frame.size.width
        let height = collectionView.frame.size.height
        switch members.count {
        case 1:
            return CGSize(width: (width), height: (height))
        case 2:
            return CGSize(width: (width), height: (height / 2))
        case 3:
            if collectionView.numberOfItems(inSection: 0) % 2 != 0 && indexPath.row == lastRowIndex - 1 {
                return CGSize(width: width, height: (height) / 2 )
            } else {
                return CGSize(width: (width) / 2, height: (height) / 2)
            }
        case 4:
            return CGSize(width: (width) / 2, height: (height) / 2)
        case 5:
            if collectionView.numberOfItems(inSection: 0) % 2 != 0 && indexPath.row == lastRowIndex - 1 {
                return CGSize(width: width , height: (height) / 3 )
            } else {
                return CGSize(width: (width) / 2, height: (height) / 3)
            }
        case 6:
            return CGSize(width: (width) / 2, height: (height) / 3)
        case 7:
            if collectionView.numberOfItems(inSection: 0) % 2 != 0 && indexPath.row == lastRowIndex - 1 {
                return CGSize(width: width , height: (height) / 4 )
            } else {
                return CGSize(width: (width) / 2, height: (height) / 4)
            }
        case 8:
            return CGSize(width: (width) / 2, height: (height) / 4)
        default:
            print("more than 8 person")
            return CGSize(width: (width), height: (height))
        }
    }
    
    
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        
    }
    
}

extension CallViewController : CallViewControllerDelegate {
    
    func onVideoMute(status:Bool) {
    
        if CallManager.isCallOnHold(){
            return
        }
        print("#mute status \(status)")
        CallManager.muteVideo(status)
        members.last?.isVideoMuted = status

        if !isLocalViewSwitched {
            if let localView = outgoingCallView?.localUserVideoView {
                addSwitchedRemoteTrackToView(localView: localView, isLocal: true)
            }
        } else {
            if let localView = outgoingCallView?.remoteUserVideoView {
                addSwitchedRemoteTrackToView(localView: localView, isLocal: false)
            }
        }

        if CallManager.isOneToOneCall() {
            setVideoBtnIcon()
            setMuteStatusText()
        } else {
            setVideoBtnIcon()
            outgoingCallView?.cameraButton.isHidden = isVideoMuted
            if !isVideoMuted {
                addGroupTracks(jid: AppUtils.getMyJid())
            } else {
                if let index = findIndexOfUser(jid: AppUtils.getMyJid()) {
                    updateVideoMuteStatus(index: index, userid: AppUtils.getMyJid(), isMute: status)
                }
            }
            AudioManager.shared().autoReRoute()
        }
    }
    
    func onAudioMute(status:Bool) {
        outgoingCallView?.audioButton.setImage(UIImage(named: isAudioMuted ? "IconAudioOn" :  "IconAudioOff" ), for: .normal)
        updateSpeakingUI(userId: AppUtils.getMyJid(), isSpeaking: false)
        CallManager.muteAudio(status)
    }
    
    func setActionIconsAfterMaximize() {
        isAudioMuted = CallManager.isAudioMuted()
        isBackCamera = members.last?.isOnBackCamera ?? false
        isVideoMuted = CallManager.isVideoMuted()
       // AudioManager.shared().getCurrentAudioInput()
    }
    
    func onSwitchCamera() {
        CallManager.switchCamera()
        outgoingCallView?.cameraButton.setImage(UIImage(named: isBackCamera ? "IconCameraOn" :  "IconCameraOff" ), for: .normal)
    }
}


extension CallViewController {
    
    func makeCall(usersList : [String], callType: CallType, groupId : String = "", onCompletion: @escaping (_ isSuccess: Bool, _ message: String) -> Void) {
        CallManager.setMyInfo(name: ContactManager.getMyProfile().name, imageUrl: ContactManager.getMyProfile().image)
        self.groupId = groupId
        AudioManager.shared().audioManagerDelegate = self
        print("#lifecycle makeCall")
        if usersList.isEmpty{
            print("Cannot make call without a callee")
            return
        }
        self.callType = callType
        if members.isEmpty || !members.contains(where: {$0.jid == AppUtils.getMyJid()}) {
            addMyInfoToMembersArray()
        }
        for userJid in usersList where userJid != AppUtils.getMyJid() {
            let _ = addRemoteMembers(for: ChatManager.getContact(jid: userJid.lowercased())!)
        }
        var membersJid = members.compactMap { $0.jid }
        if callType == .Audio {
            if members.count == 2 && groupId.isEmpty{
                try! CallManager.makeVoiceCall(members.first!.jid) { [weak self] (isSuccess , message)  in
                    if isSuccess == false {
                        let errorMessage = AppUtils.shared.getErrorMessage(description: message)
                        AppAlert.shared.showAlert(view: self!, title: "", message: errorMessage, buttonTitle: "Okay")
                        onCompletion(isSuccess,message)
                        self?.removeAllMembers()
                    }
                }
            } else {
                membersJid.remove(at: members.count - 1)
                try! CallManager.makeGroupVoiceCall(membersJid, groupID: groupId) {[weak self] isSuccess , message in
                    if isSuccess == false {
                        let errorMessage = AppUtils.shared.getErrorMessage(description: message)
                        AppAlert.shared.showAlert(view: self!, title: "", message: errorMessage, buttonTitle: "Okay")
                        onCompletion(isSuccess,message)
                        self?.removeAllMembers()
                    }
                }
            }
            if outgoingCallView != nil {
                updateUI()
            }
        } else {
            isVideoMuted = false
            if members.count == 2  && groupId.isEmpty {
                try! CallManager.makeVideoCall(members.first!.jid)  { [weak self]isSuccess, message in
                    if isSuccess == false {
                        let errorMessage = AppUtils.shared.getErrorMessage(description: message)
                        AppAlert.shared.showAlert(view: self!, title: "", message: errorMessage, buttonTitle: "Okay")
                        onCompletion(isSuccess,message)
                        self?.removeAllMembers()
                    }
                }
            } else {
                membersJid.remove(at: members.count - 1)
                try! CallManager.makeGroupVideoCall(membersJid, groupID: groupId) { [weak self] (isSuccess, message) in
                    if isSuccess == false {
                        let errorMessage = AppUtils.shared.getErrorMessage(description: message)
                        AppAlert.shared.showAlert(view: self!, title: "", message: errorMessage, buttonTitle: "Okay")
                        onCompletion(isSuccess,message)
                        self?.removeAllMembers()
                    }
                }
            }
            if outgoingCallView != nil {
                updateUI()
            }
        }
    }
    
    func getControllerViewHeight() -> CGFloat {
        return safeAreaHeight
    }
    
    func getControllerViewWidth() -> CGFloat {
        return safeAraeWidth
    }
    
}

extension CallViewController : CallManagerDelegate {
   
    func onRemoteVideoTrackAdded(userId: String, track: RTCVideoTrack) {
        print("onRemoteVideoTrackAdded", userId)
        print("onRemoteVideoTrackAddedOneToOne", CallManager.isOneToOneCall())
        executeOnMainThread {
            if let contact = ContactManager.shared.getUserProfileDetails(for: self.members.first?.jid ?? "") {
                if !contact.image.isEmpty {
                    if let contact = ChatManager.profileDetaisFor(jid: AppUtils.getMyJid()), !contact.image.isEmpty{
                        //localProfileImageView.contentMode = .scaleAspectFill
                        self.outgoingCallView?.remoteImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), jid: contact.jid)
                    }
                } else {
                    let name = getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType)
                    self.outgoingCallView?.remoteImageView.image = self.getPlaceholder(name: name, color: getColor(userName: name), size: Double(self.outgoingCallView?.remoteImageView.frame.size.height ?? 100), callSwitched: false)
                }
            } else{
                self.outgoingCallView?.remoteImageView.image = UIImage.init(named: "ic_profile_placeholder")
            }

            if CallManager.isOneToOneCall() {
                if self.members.first?.jid == userId{
                    self.members.first?.videoTrack = track
                }
                self.outgoingCallView?.remoteUserVideoView.isHidden = false
                self.addRemoteTrackToView()
            } else {
                self.collectionView?.performBatchUpdates(nil, completion: {_ in
                    print("#reload addGroupTracks onRemoteVideoTrackAdded")
                    self.addGroupTracks(jid: userId)
                })
            }
            self.setVideoBtnIcon()
        }
    }
    
    func onLocalVideoTrackAdded(userId: String, videoTrack: RTCVideoTrack) {
        print("#meet #call onLocalVideoTrackAdded() : \(userId)")
        if CallManager.isOneToOneCall()  {
            outgoingCallView?.localUserVideoView.isHidden = false
            outgoingCallView?.OutGoingCallBG.image = nil
            outgoingCallView?.contentView.backgroundColor = .clear
            addMyInfoToMembersArray(videoTrack: videoTrack)
            self.members.last?.videoTrack = videoTrack
            executeOnMainThread {
                autoreleasepool {
                    self.addlocalTrackToView(videoTrack: videoTrack)
                }
            }
        } else {
            if !CallManager.isCallConnected() ||  CallManager.getCallMode() == .MEET{
                addMyInfoToMembersArray(videoTrack: videoTrack)
                executeOnMainThread {
                    autoreleasepool {
                        if CallManager.getCallMode() == .MEET{
                            self.setVideoBtnIcon()
                        }else if let index = self.findIndexOfUser(jid: userId) {
                            let currentMember = self.members[index]
                            if !currentMember.isVideoMuted {
                                self.addlocalTrackToView(videoTrack: videoTrack)
                            }
                        }
                    }
                }
            }
        }
        self.isVideoMuted = false
        self.setVideoBtnIcon()
    }
    
    func addlocalTrackToView(videoTrack: RTCVideoTrack) {
        if videoTrack.isEnabled {
            if self.outgoingCallView != nil {
                if let localView = self.outgoingCallView?.localUserVideoView {
                    self.localRenderer.removeFromSuperview()
                    localView.willRemoveSubview(self.localRenderer)
                    #if arch(arm64)
                    let localRen = RTCMTLVideoView(frame: .zero)
                    #else
                    let localRen = RTCEAGLVideoView(frame: .zero)
                    #endif
                    self.localRenderer = localRen
                    self.localRenderer.frame = CGRect(x: 0, y: 0, width: localView.bounds.width, height: localView.bounds.height)
                    localView.addSubview(self.localRenderer)
                    videoTrack.add(self.localRenderer)
                }
            }
        }
    }
    
    func addRemoteTrackToView() {
        if let remoteView = self.outgoingCallView?.remoteUserVideoView, let jid = members.first?.jid, let videoTrack = CallManager.getRemoteVideoTrack(jid: jid) {
            self.remoteRenderer.removeFromSuperview()
            remoteView.willRemoveSubview(self.remoteRenderer)
            #if arch(arm64)
              let localRen = RTCMTLVideoView(frame: .zero)
            #else
              let localRen = RTCEAGLVideoView(frame: .zero)
            #endif
            self.remoteRenderer = localRen
            self.remoteRenderer.frame = CGRect(x: 0, y: 0, width: remoteView.bounds.width, height: remoteView.bounds.height)
            remoteView.addSubview(self.remoteRenderer)
            videoTrack.add(self.remoteRenderer)
            remoteView.bringSubviewToFront(self.remoteRenderer)
            self.members.first?.videoTrack = videoTrack
            self.showConnectedVideoCallOneToOneUI()
        }
    }
    
    func addMyInfoToMembersArray(videoTrack: RTCVideoTrack? = nil) {
        let callMember = CallMember()
        callMember.name = ContactManager.getMyProfile().name
        callMember.image = ContactManager.getMyProfile().image
        callMember.isCaller = CallManager.getCallDirection() == .Incoming ? false : true
        callMember.jid = AppUtils.getMyJid()
        callMember.isAudioMuted = CallManager.isAudioMuted()
        callMember.isVideoMuted = CallManager.isVideoMuted()
        if CallManager.getCallMode() == .MEET{
            callMember.callStatus = .connected
        }else{
            callMember.callStatus = CallManager.getCallDirection() == .Incoming ? (CallManager.isCallConnected() ? .connected : .connecting) : (CallManager.isCallConnected() ? .connected : .calling)
        }
        
        if let index = findIndexOfUser(jid: AppUtils.getMyJid()) {
            if videoTrack != nil{
                members[index].videoTrack = videoTrack
            }
        } else {
            isVideoMuted = callMember.isVideoMuted
            members.append(callMember)
        }
    }
    
//    func addMyInfoToMembersArray() {
//        let callMember = CallMember()
//        callMember.name = ContactManager.getMyProfile().name
//        callMember.image = ContactManager.getMyProfile().image
//        callMember.isCaller = CallManager.getCallDirection() == .Incoming ? false : true
//        callMember.jid = AppUtils.getMyJid()
//        callMember.isAudioMuted = CallManager.isAudioMuted()
//        callMember.isVideoMuted = CallManager.isVideoMuted()
//        if CallManager.getCallMode() == .MEET{
//            callMember.callStatus = .connected
//        }else{
//            callMember.callStatus = CallManager.getCallDirection() == .Incoming ? (CallManager.isCallConnected() ? .connected : .connecting) : (CallManager.isCallConnected() ? .connected : .calling)
//        }
//
//        if let index = findIndexOfUser(jid: AppUtils.getMyJid()) {
//
//        } else {
//            isVideoMuted = callMember.isVideoMuted
//            members.append(callMember)
//        }
//    }
    
    func addRemoteMembers(for user : ProfileDetails, with status: CallStatus = .calling) -> Int  {
        print("#call addRemoteMembers \(user.name) \(user.colorCode)")
        var remoteUserProfile : ProfileDetails? = nil
        if let pd = ChatManager.getContact(jid: user.jid.lowercased()) {
            remoteUserProfile = pd
        }else{
            remoteUserProfile = ContactManager.shared.saveTempContact(userId: user.jid)
            try? ContactManager.shared.getUserProfile(for:  user.jid.lowercased(), fetchFromServer: true) { isSuccess, error, data in
                if isSuccess{
                    print("#profile is fetched")
                }
            }
        }
        let callMember = CallMember()
        callMember.jid = user.jid
        callMember.callStatus = status
        let userId = user.jid.components(separatedBy: "@").first!
        callMember.name = getUserName(jid: remoteUserProfile?.jid ?? "",name: remoteUserProfile?.name ?? userId, nickName: remoteUserProfile?.nickName ?? userId,contactType: remoteUserProfile?.contactType ?? .unknown)
        callMember.image = remoteUserProfile?.image ?? user.image
        callMember.color = remoteUserProfile?.colorCode ?? "#00008B"
        callMember.isVideoMuted = CallManager.getMuteStatus(jid: AppUtils.getMyJid(), isAudioStatus: false) //CallManager.getCallType() == .Audio
        callMember.isVideoTrackAdded = false
        remoteImage = remoteUserProfile?.image ?? user.image
        if let index = findIndexOfUser(jid: user.jid){
            return index
        }else {
            members.insert(callMember, at:  0 )
            return 0
        }
    }
    
    func onVideoTrackAdded(userJid: String) {
        
    }
    
    func getDisplayName(IncomingUser :[String], incomingUserName: String) {
        var userString = [String]()
        if isHideNotificationContent {
            userString.append(APP_NAME)
        }else{
            for JID in IncomingUser where JID != AppUtils.getMyJid() {
                print("#jid \(JID)")
                if let contact = ChatManager.getContact(jid: JID.lowercased()){
                    if ENABLE_CONTACT_SYNC{
                        if contact.contactType == .unknown{
                            userString.append((try? FlyUtils.getIdFromJid(jid: JID)) ?? "")
                        }else{
                            userString.append(getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
                        }
                    }else{
                        userString.append(getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
                    }
                }else {
                    let pd = ContactManager.shared.saveTempContact(userId: JID)
                    userString.append(incomingUserName == emptyString() ? incomingUserName : pd?.name ?? "User")
                }
            }
            print("#names \(userString)")
        }
        CallManager.getContactNames(IncomingUserName: userString)
    }
    
    func getGroupName(_ groupId : String) {
        self.groupId = groupId
        if isHideNotificationContent {
            CallManager.getContactNames(IncomingUserName: [APP_NAME])
        }else{
            if let groupContact =  ChatManager.getContact(jid: groupId.lowercased()){
                CallManager.getContactNames(IncomingUserName: [groupContact.name])
            }else{
                CallManager.getContactNames(IncomingUserName: ["Call from Group"])
            }
        }
    }
    
    func socketConnectionEstablished() {
        
    }
    
    func onCallStatusUpdated(callStatus: CALLSTATUS, userId: String) {
        print("STEP #call onCallStatusUpdated \(callStatus.rawValue) userJid : \(userId) memersCount : \(members.count)")
        CallViewController.refreshDelegate?.refreshCallLog()
        
        DispatchQueue.main.async { [weak self] in
            
            if userId == AppUtils.getMyJid() && (callStatus != .RECONNECTING && callStatus != .RECONNECTED) {
                return
            }
            
            switch callStatus {
            case .CALLING:
                if !(self?.isOnCall ?? true) {
                    self?.myCallStatus = .calling
                }
            case .CONNECTING:
                self?.showHideDuration(hide: true)
                if !(self?.isOnCall ?? true){
                    self?.myCallStatus = .connecting
                }
                print("CONNECTING")
                
            case .RINGING:
                print("RINGING \(userId)")
                if !(self?.isOnCall ?? true){
                    self?.myCallStatus = .ringing
                    _ = self?.updateCallStatus(jid: userId, status: .ringing)
                }
                if !CallManager.isCallConnected(){
                    self?.updateCallStatus(status:  "Ringing")
                }
                if CallManager.isOneToOneCall() {
                    self?.outgoingCallView?.viewHeight.constant = 190
                    self?.outgoingCallView?.imageHeight.constant = 100
                    self?.outgoingCallView?.imageTop.constant = 8
                } else if (self?.isOnCall ?? false) {
                    self?.addUpdateCallUsersWithStatus(userJid: userId, status: .ringing, reload: true)
                }
                
            case .ATTENDED:
                self?.setHoldText(isShow: false)
                if !(self?.isOnCall ?? true){
                    self?.myCallStatus = .attended
                }
                self?.showHideCallAgainView(show: false, status: "Connecting")
                self?.seconds = -1
                if CallManager.getCallDirection() == .Incoming && userId.isNotEmpty {
                    self?.addUpdateCallUsersWithStatus(userJid: userId, status: self?.convertCallStatus(status: CallManager.getCallStatus(userId: userId) ?? .ATTENDED) ?? .calling)
                }
                if self?.outgoingCallView != nil {
                    self!.outgoingCallView?.removeGestureRecognizer(self!.tapGesture)
                    self!.outgoingCallView?.addGestureRecognizer(self!.tapGesture)
                    self?.outgoingCallView?.nameTop.constant = 8
                    self?.outgoingCallView?.timerTop.constant = 0
                    self?.outgoingCallView?.imageHeight.constant = 0
                }
                AudioManager.shared().stopPlayingTone()
            case .CONNECTED:
                self?.callHoldLabel.removeFromSuperview()
                self?.validateAndUpdateRoutingIcon()
                self?.setHoldText(isShow: false)
                print("#callStatus onCallStatus ==== \(userId) Connected")
                if ((self?.audioPlayer) != nil) {
                    if ((self?.audioPlayer?.isPlaying) != nil) {
                        self?.audioPlayer?.stop()
                    }
                    self?.audioPlayer = nil
                }
                if !(self?.isOnCall ?? true){
                    if let vcSelf = self{
                        vcSelf.speakingTimer = Timer.scheduledTimer(timeInterval: 0.5, target: vcSelf, selector: #selector(vcSelf.validateSpeaking), userInfo: nil, repeats: true)
                    }
                }
                print("#call CONNECTED : \(userId)")
                self?.myCallStatus = .connected
                self?.showHideCallAgainView(show: false, status: "Connected")
                self?.updateCallStatus(status: CallManager.isCallOnHold() ? CallStatus.onHold.rawValue : "Connected")
                self?.enableButtons(buttons:self?.outgoingCallView?.videoButton, isEnable: true)
                self?.showHideParticipantButton(hide : false)
                self?.outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = false
                self?.outgoingCallView?.OutGoingPersonLabel.isHidden = false
                self?.getContactNames()
                self?.outgoingCallView?.imageTop.constant = 8
                self?.outgoingCallView?.addParticipantBtn.addTarget(self, action: #selector(self?.addParticipant(sender:)), for: .touchUpInside)
                self?.enableDisableUserInteractionFor(view: self?.outgoingCallView?.AttendingBottomView, isDisable: false)
                _ = self?.validateAndAddMember(jid: userId, with: .connected)
                if !CallManager.isOneToOneCall() && (self?.collectionView?.isHidden ?? false){
                    self?.showGroupCallUI()
                }
                if CallManager.isOneToOneCall() {
                    if CallManager.getCallType() == .Video {
                        self?.addOneToOneLocalTracks()
                        self?.setVideoBtnIcon()
                        self?.outgoingCallView?.imageHeight.constant = 0
                    }else{
                        self?.updateOneToOneAudioCallUI()
                    }
                } else {
                    _ = self?.updateMuteStatus(jid: userId, isMute: false, isAudio: CallManager.getCallType() == .Audio)
                    if CallManager.getCallStatus(userId:  userId.isEmpty ? AppUtils.getMyJid() : userId ) == .ON_HOLD{
                        self?.addUpdateCallUsersWithStatus(userJid: userId, status: .onHold, reload: true)
                    }else{
                        self?.addUpdateCallUsersWithStatus(userJid: userId, status: .connected, reload: true)
                    }
                    self?.outgoingCallView?.audioMuteStackView.isHidden = true
                }
                if let ocv = self?.outgoingCallView{
                    ocv.removeGestureRecognizer(self!.tapGesture)
                    ocv.addGestureRecognizer(self!.tapGesture)
                }
                if CallManager.isCallConnected(){
                    self?.updateCallTimerDuration()
                }
                self?.isOnCall = true
                let audioMuteStatus = CallManager.isRemoteAudioMuted(userId)
                let vidooMuteStatus = CallManager.isRemoteVideoMuted(userId)
                print("userJid mute status : \(userId)")
                self?.onMuteStatusUpdated(muteEvent: (audioMuteStatus == true) ? MuteEvent.ACTION_REMOTE_AUDIO_MUTE : MuteEvent.ACTION_REMOTE_AUDIO_UN_MUTE, userId: userId)
                self?.onMuteStatusUpdated(muteEvent: (vidooMuteStatus == true) ? MuteEvent.ACTION_REMOTE_VIDEO_MUTE : MuteEvent.ACTION_REMOTE_VIDEO_UN_MUTE , userId: userId)
                FlyLogWriter.sharedInstance.writeText("#call UI .CONNECTED => \(userId) \(self?.members.count)")

            case .DISCONNECTED:
                self?.outgoingCallView?.speakerButton.setImage(UIImage(named: "IconSpeakerOff" ), for: .normal)
                self?.validateAndUpdateRoutingIcon()
                if userId.isEmpty {
                    self?.dismissWithDelay()
                }else {
                    if let index = self?.findIndexOfUser(jid: userId) {
                        self?.removeDisConnectedUser(userIndex: index)
                    }
                }
                self?.callHoldLabel.removeFromSuperview()
                self?.setHoldText(isShow: false)
                FlyLogWriter.sharedInstance.writeText("#call UI .DISCONNECTED => \(userId) \(self?.members.count)")
            case .ON_HOLD:
                self?.isOnCall = true
                let userId = userId.isEmpty ? AppUtils.getMyJid() : userId
                if let index =  self?.findIndexOfUser(jid: userId) {
                    print("#callStatus onCallStatus ====  .ON_HOLD for \(userId) at \(index)  \(CallManager.isOneToOneCall())  \(String(describing: self?.members.count ?? 0))")
                    self?.members[index].callStatus = .onHold
                }
                self?.setHoldText(isShow: true)
                _ = self?.updateCallStatus(jid: userId, status: .onHold)
                if CallManager.isOneToOneCall() && (self?.members.count == 2) {
                    self?.updateCallStatus(status:  CallStatus.onHold.rawValue)
                }else{
                    self?.updateCallStatus(status:  CallStatus.connected.rawValue)
                }
                FlyLogWriter.sharedInstance.writeText("#call UI .ON_HOLD => \(userId) \(self?.members.count)")
            case .ON_RESUME:
                self?.isOnCall = true
                let userId = userId.isEmpty ? AppUtils.getMyJid() : userId
                var indexValue : Int? = nil
                if userId == AppUtils.getMyJid() {
                    self?.myCallStatus = .connected
                }
                if let index =  self?.findIndexOfUser(jid: userId) {
                    indexValue = index
                    self?.members[index].callStatus = .connected
                }
                _ = self?.updateCallStatus(jid: userId, status: .connected)
                if CallManager.isOneToOneCall() && (self?.members.count == 2) {
                    self?.updateCallStatus(status: CallStatus.connected.rawValue)
                    self?.myCallStatus = .connected
                }else{
                    if !CallManager.getMuteStatus(jid: userId, isAudioStatus: false) && userId != AppUtils.getMyJid() {
                        print("#callStatusRE ON_RESUME If")
                        self?.onCallAction(callAction: .ACTION_REMOTE_VIDEO_ADDED, userId: userId)
                    }else{
                        print("#callStatusRE ON_RESUME ELSE")
                        self?.reloadCollectionViewForIndex(index: indexValue)
                    }
                }
                self?.outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = false
                self?.showHideDuration(hide: false)
                self?.callHoldLabel.removeFromSuperview()
                self?.setHoldText(isShow: false)
                FlyLogWriter.sharedInstance.writeText("#call UI .ON_RESUME => \(userId) \(self?.members.count) videoMute => \(CallManager.getMuteStatus(jid: userId, isAudioStatus: false))")
            case .USER_JOINED:
                if let contact = ChatManager.getContact(jid: userId), let self = self,userId.isNotEmpty{
                    AppAlert.shared.showToast(message:"\(self.getNameStringWithGroupName(userNames: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))) joined")
                }
                if let self = self, CallManager.getCallMode() == .MEET{
                    if  self.members.compactMap({$0.jid}).contains(userId){
                        return
                    }
                    self.validateAndAddMember(jid: userId, with: CallStatus.connecting)
                }
            case .USER_LEFT:
                if let contact = ChatManager.getContact(jid: userId), let self = self,userId.isNotEmpty{
                    AppAlert.shared.showToast(message:"\(self.getNameStringWithGroupName(userNames: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))) left")
                }
                
            case .INVITE_CALL_TIME_OUT:
                print("")
            case .CALL_TIME_OUT:
                print("#call CALL_TIME_OUT  \(self?.isOnCall ?? false)")
                if (self?.isOnCall ?? false) || CallManager.isCallConnected() {
                    self?.isOnCall = true
                    let timedOutUsers = self?.getUnavailableUsers(isTimeOut: true) ?? []
                    if (self?.members.count ?? 0) - timedOutUsers.count > 1 {
                        self?.removeUnavailableUsers(removedUsers: timedOutUsers)
                    }else {
                        if CallManager.getCallMode() != .MEET {
                            self?.dismissWithDelay()
                        }
                    }
                }else{
                    if self?.overlayShown ?? false && !CallManager.isCallConnected(){
                        self?.dismissWithDelay()
                    }else{
                        self?.myCallStatus = .tryagain
                        self?.showHideCallAgainView(show: true, status: "Unavailable, Try again later")
                    }
                }
            case .RECONNECTING:
                if (self?.isOnCall ?? false){
                    self?.myCallStatus = .reconnecting
                }
                self?.showHideParticipantButton(hide:  true)
                self?.outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = !CallManager.isOneToOneCall()
                if CallManager.isOneToOneCall() {
                    self?.updateCallStatus(status: "Reconnecting")
                    self?.outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = false
                }else{
                    self?.updateCallStatus(jid: userId, status: .reconnecting)
                }
            case .RECONNECTED:
                print("#callStatus onCallStatus ====  .RECONNECTED \(userId) \(CallManager.getCallStatus(userId: userId)?.rawValue) 1-1 => \(CallManager.isOneToOneCall())  \((self?.isOnCall ?? false))")
                if !CallManager.isCallConnected(){
                    if CallManager.getCallMode() == .MEET{
                        self?.collectionView?.reloadData()
                    }
                    return
                }
                if CallManager.isOneToOneCall() && (self?.members.count == 2){
                    if (self?.isOnCall ?? false){
                        self?.myCallStatus =  self?.isCallOnHoldForOneToCall() ?? false ?  CallStatus.onHold : CallStatus.connected
                    }
                }else{
                    if (self?.isOnCall ?? false){
                        self?.myCallStatus = .reconnected
                    }
                }
                
                self?.showHideParticipantButton(hide: !CallManager.isCallConnected())
                if CallManager.isOneToOneCall() && (self?.members.count == 2) {
                        self?.updateCallStatus(status: self?.getStatusOfOneToOneCall() ?? "Connected" )
                }else{
                    self?.updateCallStatus(status: CallManager.isCallOnHold() ? CallStatus.onHold.rawValue : CallStatus.connected.rawValue)
                    self?.updateCallStatus(jid: userId, status: CallManager.isCallOnHold() ? .onHold : .connected)
                }
            case .CALLING_10S:
                print("")
            case .CALLING_AFTER_10S:
                print("")

            @unknown default:
                break
            }
            
        }
    }
    
    
    @IBAction func addParticipant(sender: UIButton?){
        
        var controller: ContactViewController
        if #available(iOS 13.0, *) {
            controller = UIStoryboard(name: Storyboards.main, bundle: nil).instantiateViewController(identifier: Identifiers.contactViewController)
        } else {
            // Fallback on earlier versions
            controller = UIStoryboard(name: Storyboards.main, bundle: nil).instantiateViewController(withIdentifier: Identifiers.contactViewController) as! ContactViewController
        }
        controller.modalPresentationStyle = .fullScreen
        controller.makeCall = true
        controller.isMultiSelect = true
        controller.isInvite = true
        controller.hideNavigationbar = true
        controller.groupJid = self.groupId
        controller.refreshDelegate = self
        isFromInvite = true
        if let callLink = CallManager.getCallLink(){
            controller.callLink = callLink
        }
       
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showHideOutgoingCallView(isHide: Bool) {
        if outgoingCallView?.isHidden != isHide {
            outgoingCallView?.isHidden = isHide
        }
    }
    
    func findIndexOfUser(jid : String) -> Int? {
        return members.firstIndex { $0.jid == jid }
    }
    
    func onCallAction(callAction: CallAction, userId: String) {
        if userId == AppUtils.getMyJid() {
            return
        }
        
        if callAction == CallAction.ACTION_REMOTE_VIDEO_ADDED {
            print("#call onCallAction() ACTION_REMOTE_VIDEO_ADDED : \(userId)")
            FlyLogWriter.sharedInstance.writeText("#call UI onCallAction  CallAction.ACTION_REMOTE_VIDEO_ADDED \(userId) \(members.count)")
            if CallManager.isOneToOneCall(){
                members.first?.isVideoMuted = false
                setMuteStatusText()
            }else {
                FlyLogWriter.sharedInstance.writeText("#call UI onCallAction  CallAction.ACTION_REMOTE_VIDEO_ADDED  \(userId) at index \(index)")
            }
        } else if callAction == CallAction.ACTION_REMOTE_BUSY {
            AppAlert.shared.showToast(message: "User is Busy")

            if CallManager.getAllCallUsersList().count == 1{
                self.dismissWithDelay(callStatus: .UserBusy)
            } else {
                if let index = findIndexOfUser(jid: userId) {
                    removeDisConnectedUser(userIndex: index)
                }
            }
        }
        else if callAction == CallAction.ACTION_VIDEO_CALL_CONVERSION_ACCEPTED {
            print("#switch ACTION_VIDEO_CALL_CONVERSION_ACCEPTED me :\(isCallConversionRequestedByMe) remote: \(isCallConversionRequestedByRemote)  isVideo: \(CallManager.getCallType().rawValue)")
            CallManager.setCallType(callType: .Video)
            CallManager.muteVideo(false)
            members.first?.isVideoMuted = false
            switchLoaclandRemoteViews()
            showOneToOneVideoCallUI()
            showHideDuration(hide: false)
            isVideoMuted = false
            setVideoBtnIcon()
            resetConversionTimer()
            localProfileImageView.removeFromSuperview()
            AudioManager.shared().autoReRoute()
        }
        else if callAction == CallAction.ACTION_VIDEO_CALL_CONVERSION_REJECTED {
            print("#switch onCallAction \(callAction.rawValue)")
            // Call conversion is declined by the user
            CallManager.setCallType(callType: .Audio)
            isCallConversionRequestedByMe = false
            isCallConversionRequestedByRemote = false
            resetConversionTimer()
            CallManager.disableVideo()
            isVideoMuted = true
            setVideoBtnIcon()
            updateOneToOneAudioCallUI()
        }
        else if callAction == CallAction.ACTION_VIDEO_CALL_CONVERSION {
            print("#switch onCallAction \(callAction.rawValue) me :\(isCallConversionRequestedByMe) remote: \(isCallConversionRequestedByRemote)  isVideo: \(CallManager.getCallType().rawValue)")
            // Call conversion is requested to the user
            isCallConversionRequestedByRemote = true
            alertController?.dismiss(animated: true, completion:nil)
            showCallConversionConfirmationRequest()
            //let _ = requestForVideoTrack(jid: nil)
        }
        else if callAction == CallAction.CHANGE_TO_AUDIO_CALL {
            print("#switch onCallAction \(callAction.rawValue) me :\(isCallConversionRequestedByMe) remote: \(isCallConversionRequestedByRemote)  isVideo: \(CallManager.getCallType().rawValue)")
            isLocalViewSwitched = false
            CallManager.setCallType(callType: .Audio)
            resetConversionTimer()
            updateOneToOneAudioCallUI()
            removeRemoteOneToOneLocalTracks()
            AudioManager.shared().autoReRoute()
        }
        else if callAction == CallAction.ACTION_INVITE_USERS {
            print("#UI menmenersCount before \(members.count)")
            for userJid in getInvitedUsers(){
                addUpdateCallUsersWithStatus(userJid: userJid, status: convertCallStatus(status: CallManager.getCallStatus(userId: userJid) ?? .CALLING), reload: true, skipTracks: true)
            }
            print("#UI menmenersCount after \(members.count)")
            showGroupCallUI()
            if !reloadForInVite{
                for member in members.map({$0.jid!}) {
                    addGroupTracks(jid: member)
                }
            }
        }
        else if callAction == CallAction.ACTION_REMOTE_ENGAGED {

            AppAlert.shared.showToast(message: "Call Engaged")

            if CallManager.isOneToOneCall() && isOnCall && (CallManager.getCallConnectedUsersList()?.count ?? 0) == 0 {
                dismissWithDelay(callStatus: .CallEngaged)
            }else{
                if let index = findIndexOfUser(jid: userId){
                    removeDisConnectedUser(userIndex: index)
                }
            }
        }

        validateAndUpdateRoutingIcon()
    }
    
    func onMuteStatusUpdated(muteEvent: MuteEvent, userId: String) {
        print("#call onMuteStatusUpdated \(muteEvent) \(userId)")
        switch muteEvent {
        case .ACTION_REMOTE_AUDIO_MUTE:
            if CallManager.isOneToOneCall() {
                members.first?.isAudioMuted = true
                setMuteStatusText()
            } else {
                updateMuteStatus(jid: userId, isMute: true, isAudio: true)
            }
        case .ACTION_REMOTE_AUDIO_UN_MUTE:
            if CallManager.isOneToOneCall() {
                members.first?.isAudioMuted = false
                setMuteStatusText()
            } else {
                updateMuteStatus(jid: userId, isMute: false, isAudio: true)
            }
        case .ACTION_REMOTE_VIDEO_MUTE:
            
            if CallManager.isOneToOneCall() {
                members.first?.isVideoMuted = true
                setMuteStatusText()
                removeRemoteOneToOneLocalTracks()
            } else {
                updateMuteStatus(jid: userId, isMute: true, isAudio: false)
            }
        case .ACTION_REMOTE_VIDEO_UN_MUTE:
            if CallManager.isOneToOneCall() {
                outgoingCallView?.contentView.backgroundColor = .clear
                members.first?.isVideoMuted = false
                setMuteStatusText()
                addRemoteTrackToView()
            } else {
                updateMuteStatus(jid: userId, isMute: false, isAudio: false)
            }
        case .ACTION_LOCAL_AUDIO_MUTE:
            isAudioMuted = true
            outgoingCallView?.audioButton.setImage(UIImage(named: isAudioMuted ? "IconAudioOn" :  "IconAudioOff" ), for: .normal)
        case .ACTION_LOCAL_AUDIO_UN_MUTE:
            isAudioMuted = false
            outgoingCallView?.audioButton.setImage(UIImage(named: isAudioMuted ? "IconAudioOn" :  "IconAudioOff" ), for: .normal)
        }
    }
    
    func switchAudioToVideoCall() {
        CallManager.setCallType(callType: .Video)
        switchLoaclandRemoteViews()
        showOneToOneVideoCallUI()
        setVideoBtnIcon()
        resetConversionTimer()
    }
    
}

// Utility Method extensions

extension CallViewController {
    
    func validateAndAddMember(jid: String? = nil, with status: CallStatus = .calling, shouldReload : Bool = false) -> Bool {
        
        if jid == nil || (jid ?? "").isEmpty {
            return false
        }
        
        if members.isEmpty || !members.contains(where: {$0.jid == AppUtils.getMyJid()}) {
            addMyInfoToMembersArray()
        }
        
        if let jid = jid, jid != AppUtils.getMyJid() {
            if !(members.contains{$0.jid == jid} ) {
                let profileDetails = ProfileDetails(jid: jid)
                _ = addRemoteMembers(for: profileDetails, with: status)
                if !CallManager.isOneToOneCall(){
                    if shouldReload || (members.count - (collectionView?.numberOfItems(inSection: 0) ?? 0) != 1) {
                        showGroupCallUI()
                    }else{
                        let indexPath = IndexPath(item: 0, section: 0)
                        collectionView?.performBatchUpdates({
                            collectionView?.insertItems(at: [indexPath])
                        }, completion: { _ in
                            self.collectionView?.reloadItems(at: [indexPath])
                        })
                    }
                   

                }
                return true
            }else {
                if let index = findIndexOfUser(jid: jid) {
                    if CallManager.getCallStatus(userId: jid) == .ON_HOLD{
                        members[index].callStatus = .onHold
                    }else{
                        members[index].callStatus = status
                    }
                    
                }
            }
        }
        collectionView?.reloadData()
        for member in members {
            addGroupTracks(jid: member.jid)
        }
        return false
    }
    
    func removeAllMembers() {
        //clearAllTrackViews()
        members.removeAll()
        executeOnMainThread {
            if !CallManager.isOneToOneCall(){
                self.collectionView?.reloadData()
            }
        }
    }
    
    func updateMuteStatus(jid : String, isMute : Bool, isAudio : Bool) {
        if let index = findIndexOfUser(jid: jid) {
            if isAudio {
                members[index].isAudioMuted = isMute
                updateUsersDetails(index: index, userid: jid)
            } else {
                updateVideoMuteStatus(index: index, userid: jid, isMute: isMute)
            }
        }
    }
    
    func updateCallStatus(jid: String, status : CallStatus) {
        print("#callStatus CVC \(jid)  \(status.rawValue)")
        if let index = findIndexOfUser(jid: jid) {
            print("#call updateCallStatus \(jid) \(status.rawValue)")
            if CallManager.getCallStatus(userId: jid) == .ON_HOLD{
                members[index].callStatus = .onHold
            }else{
                members[index].callStatus = status
            }
            updateUsersDetails(index: index, userid: jid)
        }
    }
    
    func updateUsersDetails(index: Int, userid: String) {
        print("#call updateUsersDetails \(userid)")
        if !CallManager.isOneToOneCall() && self.collectionView != nil {
            let isLastRow = (index == members.count - 1)
            let member = members[index]
            if let groupCell = self.collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? GroupCallCell {
                if (isLastRow  && member.callStatus == .reconnecting) || (!isLastRow && member.callStatus != .connected) || member.callStatus == .onHold || (isLastRow && CallManager.isCallOnHold()){
                    groupCell.foreGroundView.isHidden = false
                    groupCell.foreGroundView.alpha = 1
                    groupCell.callActionsView.isHidden = true
                    groupCell.statusLable.text = member.callStatus.rawValue.capitalized
                }else{
                    groupCell.foreGroundView.isHidden = true
                    groupCell.foreGroundView.alpha = 0.5
                    groupCell.callActionsView.isHidden = false
                    groupCell.statusLable.textColor = UIColor(hexString: "#FFFFFF")
                    groupCell.profileName.font = AppFont.Regular.size(14)
                }
                    
                if userid == AppUtils.getMyJid() {
                    groupCell.audioIconImageView.isHidden = true
                }else{
                    groupCell.audioIconImageView.isHidden = !member.isAudioMuted
                }
            }
        }
    }
    
    func updateVideoMuteStatus(index: Int, userid: String, isMute : Bool) {
        print("#call updateVideoMuteStatus \(userid)")
        if !CallManager.isOneToOneCall() && self.collectionView != nil {
            self.collectionView?.performBatchUpdates {
                if let groupCell = self.collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? GroupCallCell {
                    let member = members[index]
                    if CallManager.getCallType() == .Video {
                        groupCell.videoMuteImage.isHidden = !isMute
                        if isMute {
                            member.videoTrackView.removeFromSuperview()
                            groupCell.videoBaseView.willRemoveSubview(member.videoTrackView)
                            if userid == AppUtils.getMyJid() {
                                groupCell.videoBaseView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                            }
                        } else {
                            addGroupTracks(jid: userid)
                            if userid == AppUtils.getMyJid() {
                                groupCell.videoBaseView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                            }
                        }
                        members[index].isVideoMuted = isMute
                    }else {
                        if isMute {
                            member.videoTrackView.removeFromSuperview()
                            groupCell.videoBaseView.willRemoveSubview(member.videoTrackView)
                            groupCell.videoMuteImage.isHidden = !isMute
                            if userid == AppUtils.getMyJid() {
                                groupCell.videoBaseView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                            }
                        } else {
                            addGroupTracks(jid: userid)
                            if userid == AppUtils.getMyJid() {
                                groupCell.videoBaseView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                            }
                            groupCell.videoMuteImage.isHidden = !isMute
                        }
                        members[index].isVideoMuted = isMute
                    }
                }
            }
        }
    }
    
    func reloadCollectionViewForIndex(index: Int?) {
        DispatchQueue.main.async { [weak self] in
            if let itemIndex =  index, self?.collectionView?.numberOfItems(inSection: 0) ?? 0 > index ?? -1, self?.collectionView?.isHidden == false {
                print("#callStatus #reloadCollectionViewForIndex \(itemIndex) \(self?.members[itemIndex].jid)")
                let indexPath = IndexPath(item: itemIndex, section: 0)
                self?.collectionView?.reloadItems(at: [indexPath])
            }
        }
    }
    
    func convertCallStatus(status : CALLSTATUS?) -> CallStatus {
        if let status = status {
            if status == .RINGING {
                return .ringing
            }else if status == .CONNECTED {
                return .connected
            }else if status == .ATTENDED {
                return .connecting
            }else if status == .RECONNECTING {
                return .reconnecting
            }else if status == .RECONNECTED {
                return .reconnected
            } else if status == .ON_HOLD {
                return .onHold
            }else if status == .CONNECTING {
                return .connecting
            } else {
                return .calling
            }
        }else {
            return .calling
        }
    }
    
    func shouldSwitchToOneToOneUI() -> Bool {
        return members.count - 1 == 2
    }
    
    func shouldSwitchToGroupUI() -> Bool {
        return members.count + 1 > 2
    }
    
    func removeDisConnectedUser(userIndex : Int){
        if !members.isEmpty && userIndex < members.count {
            if (collectionView?.numberOfItems(inSection: 0) ?? 0 > userIndex)  {
                var oneToOneUsers : [CallMember] = []
                //releaseTrackViewBy(memberIndex: userIndex)
                members.remove(at: userIndex)
                let indexPath =  IndexPath(item: userIndex, section: 0)
                if CallManager.getCallMode() == .MEET || (collectionView?.isHidden == false && collectionView.numberOfItems(inSection: 0) > 2){
                    collectionView?.deleteItems(at: [indexPath])
                }
                showHideParticipantButton(hide : !isOnCall)
                if !isOnCall{
                    getContactNames()
                }else if members.count == 2 && CallManager.getCallMode() != .MEET {
                    if CallManager.getCallType() == .Audio{
                        if let first = members.first, let last = members.last{
                            if !first.isVideoMuted || !last.isVideoMuted {
                                CallManager.setCallType(callType: .Video)
                            }
                        }
                    }
                    if members.first!.isVideoMuted && members.last!.isVideoMuted {
                        CallManager.setCallType(callType: .Audio)
                    }
                    if CallManager.getCallType() == .Video {
                        showConnectedVideoCallOneToOneUI()
                    }
                    collectionView?.isHidden = true
                    
                    if CallManager.getCallType() == .Audio && (members.first?.isVideoMuted ?? true && members.last?.isVideoMuted ?? true) {
                        CallManager.muteVideo(true)
                        updateOneToOneAudioCallUI()
                        if isTapped{
                            SingleTapGesturTapped(UITapGestureRecognizer())
                        }
                    } else {
                        updateOneToOneVideoCallUI()
                        switchLoaclandRemoteViews()
                    }
                    updateCallStatus(status: isCallOnHoldForOneToCall() ? CallStatus.onHold.rawValue : convertCallStatus(status: CallManager.getCallStatus(userId: (members.first?.jid)!) ?? .CALLING).rawValue)
                    oneToOneUsers.removeAll()
                    setMuteStatusText()
                    getContactNames()
                } else if members.count < 2 &&  CallManager.getCallMode() != .MEET{
                    self.dismissWithDelay()
                }
            }else if CallManager.getAllCallUsersList().count <= 1 {
                if CallManager.getCallMode() != .MEET {
                    self.dismissWithDelay()
                }
            }else{
                members.remove(at: userIndex)
                getContactNames()
                updateCallStatus(status: CallStatus.connected.rawValue)
            }
        }
    }
    
    func addUpdateCallUsersWithStatus(userJid: String, status : CallStatus, reload: Bool = false, skipTracks : Bool = false)  {
        
        let isNewUser = validateAndAddMember(jid: userJid, with: status)
        if (isOnCall || !(collectionView?.isHidden ?? false)) {
            print("#UI #addUpdateCallUsersWithStatus \(userJid) \(status.rawValue)")
            updateCallStatus(jid: userJid, status: status)
        }
    }
    
    func renderVideoView(view: RTCMTLVideoView?, track : RTCVideoTrack?){
        if let memberTrack = track , let memberView = view {
            memberTrack.add(memberView)
        }
    }
    
    func getUnavailableUsers(isTimeOut : Bool) -> [String] {
        let currentUsers = isTimeOut ? CallManager.getTimeOutUsersList() ?? [] : CallManager.getCallUsersList() ?? []
        var localUsers = members.compactMap{$0.jid}
        if !members.isEmpty { localUsers.removeLast() }
        var userToBeRemoved : [String] = []
        for userJid in localUsers {
            if !currentUsers.contains(userJid) {
                print("removeUsers \(userJid)")
                userToBeRemoved.append(userJid)
            }
        }
        return userToBeRemoved
    }
    
    func removeUnavailableUsers(removedUsers: [String]) {
        for jid in removedUsers {
            if let index = findIndexOfUser(jid: jid) {
                removeDisConnectedUser(userIndex: index)
            }
        }
    }
    
    func checkIfGroupCallUiIsVisible() -> Bool {
        return collectionView?.isHidden ?? false
    }
    
    func getInvitedUsers()-> [String] {
        var invitedUsers = CallManager.getCallUsersList() ?? []
        let localUsers = members.map{$0.jid!}
        for userJid in localUsers {
            print("#invited \(userJid)")
            if invitedUsers.contains(userJid) {
                invitedUsers.removeAll { oldUser in
                    oldUser == userJid
                }
            }
        }
        return invitedUsers
    }
    
    func dismissWithDelay(callStatus : CallCurrentStatus = .Disconnected){
        outgoingCallView?.localUserVideoView.willRemoveSubview(localRenderer)
        outgoingCallView?.remoteUserVideoView.willRemoveSubview(remoteRenderer)
        localRenderer.removeFromSuperview()
        remoteRenderer.removeFromSuperview()
        self.groupId = ""
        self.isOnCall = false
        isVideoMuted = true
        speakingTimer?.invalidate()
        speakingTimer = nil
        audioDevicesAlertController?.dismiss(animated: true, completion: {
            self.audioDevicesAlertController = nil
        })
        outgoingCallView?.localUserVideoView.removeGestureRecognizer(panGesture)
        alertController?.dismiss(animated: true, completion: nil)
        callDurationTimer?.invalidate()
        callDurationTimer = nil
        if ((audioPlayer) != nil) {
            if ((audioPlayer?.isPlaying) != nil) {
                audioPlayer?.stop()
            }
            audioPlayer = nil
        }
        enableButtons(buttons: outgoingCallView?.videoButton, isEnable: false)
        CallManager.incomingUserJidArr.removeAll()
        updateCallStatus(status: CallStatus.disconnected.rawValue)
        showHideParticipantButton(hide : true)
        enableDisableUserInteractionFor(view: outgoingCallView?.AttendingBottomView, isDisable: true)
        if callStatus != .Disconnected {
            CallManager.disconnectCall()
        }
        callViewOverlay.removeFromSuperview()
        removeAllMembers()
        DispatchQueue.main.asyncAfter(deadline: .now() +  1.5) { [weak self] in
            self?.resetLocalVideCallUI()
            if let self = self, let navigationController = self.navigationController, CallManager.getCallMode() == .MEET {
                for controller in navigationController.viewControllers as Array {
                    if controller.isKind(of: ChatViewParentController.self) {
                        self.navigationController!.popToViewController(controller, animated: true)
                        break
                    }
                }
            }
            self?.outgoingCallView?.OutgoingRingingStatusLabel?.text = emptyString()
            self?.dismiss()
            UserDefaults.standard.removeObject(forKey: "seconds")
        }
    }
    
    func enableDisableUserInteractionFor(view : UIView?, isDisable : Bool)  {
        view?.isUserInteractionEnabled = !isDisable
    }
    
    func setVideoBtnIcon()  {
        
        print("#meet #btn setVideoBtnIcon \(CallManager.isVideoMuted()) || Local \(isVideoMuted)")
        var image = "VideoDisabled"
        if CallManager.isOneToOneCall() && CallManager.getCallType() == .Audio && (isVideoMuted && members.first?.isVideoMuted ?? false) {
            image = "VideoDisabled"
        }else{
            let isVideoTrackAvaialable = members.last?.videoTrack != nil
            if isVideoMuted && isVideoTrackAvaialable {
                image = "VideoDisabled"
            } else if isVideoTrackAvaialable && !isVideoMuted  {
                image = "VideoEnabled"
            }
        }
        outgoingCallView?.videoButton.setImage(UIImage(named: image ), for: .normal)
    }
    
    func enableButtons(buttons : UIButton?..., isEnable : Bool) {
        for button in buttons{
            button?.isEnabled = isEnable
        }
    }
    
    func checkForEmulator(block: () -> Void){
        #if targetEnvironment(simulator)
        print("Video Can't be rendered in simulator")
        #else
        block()
        #endif
    }
    
    func setTopViewsHeight(){
        if CallManager.getCallType() == .Audio && CallManager.isOneToOneCall() {
            outgoingCallView?.viewHeight.constant = 190
            outgoingCallView?.imageHeight.constant = 100
            outgoingCallView?.timerTop.constant = 8
        } else {
            outgoingCallView?.viewHeight.constant = 100
            outgoingCallView?.timerTop.constant = 0
            outgoingCallView?.imageHeight.constant = 0
        }
        outgoingCallView?.nameTop.constant = 8
        outgoingCallView?.imageTop.constant = 8
    }
    
    func getCurrentCallStatusAsString() -> String {
        var status = "Trying to connect"
        switch myCallStatus {
        case .attended :
            status = "Connecting"
        case .ringing :
            status = "Ringing"
        case .calling :
            status = "Trying to connect"
        case .connecting :
            status = "Connecting"
        case .connected :
            status = CallManager.isCallConnected() ? "Connected" : status
        case .disconnected :
            status = "Disconnected"
        case .reconnecting :
            status = "Reconnecting"
        case .reconnected :
            status = "Connected"
        default:
            status = "Unavailable, Try again later"
        }
        
        if !CallManager.isOneToOneCall() && CallManager.isCallConnected(){
            return  CallStatus.connected.rawValue
        }
        if  isCallOnHoldForOneToCall(){
            return CallStatus.onHold.rawValue
        }
        return status
    }
    
    func updateCallTimerDuration(){
        if CallManager.getCallDirection() == .Incoming{
            if isOnCall{
                updateCallDuration()
            }else {
                outgoingCallView?.timerLable.text = "00:00"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.updateCallDuration()
                }
            }
        }else{
            updateCallDuration()
        }
    }
    
    func getCallStatusOf(userId : String) -> CallStatus {
        if let member = members.first {$0.jid == userId}{
            return member.callStatus ?? .calling
        }
        return .calling
    }
    
    func getStatusOfOneToOneCall() -> String {
        if CallManager.isOneToOneCall() && isCallOnHoldForOneToCall(){
            return CallStatus.onHold.rawValue
        }
        return getCurrentCallStatusAsString()
    }
    
    func isCallOnHoldForOneToCall() -> Bool {
        if let firstUserJid = members.first?.jid , let firstStatus = CallManager.getCallStatus(userId: firstUserJid), let myStatus = CallManager.getCallStatus(userId: AppUtils.getMyJid()) {
            if firstStatus == .ON_HOLD || myStatus == .ON_HOLD{
               return true
            }
        }
        return false
    }
}

extension CallViewController : ConnectionEventDelegate{
    
    func onConnectionFailed(error: FlyError) {
        if error.description.contains(FlyConstants.ErrorMessage.authorization_error) {
            CallManager.disconnectCall()
            dismiss()
            ChatManager.shared.resetFlyDefaults()
            //Commented private flydefaults
//            FlyDefaults.myMobileNumber = ""
//            FlyDefaults.myXmppUsername = ""
//            FlyDefaults.myXmppPassword = ""
//            FlyDefaults.myXmppResource = ""
//            FlyDefaults.xmppDomain = ""
//            FlyDefaults.xmppPort = 0
            ChatManager.updateAppLoggedIn(isLoggedin: false)
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            let controller : OTPViewController
            if #available(iOS 13.0, *) {
                controller = UIStoryboard(name: "Login", bundle: nil).instantiateViewController(identifier: "OTPViewController")
            } else {
                // Fallback on earlier versions
                controller = UIStoryboard(name: "Login", bundle: nil).instantiateViewController(withIdentifier: "OTPViewController") as! OTPViewController
            }
            if let navigationController = window?.rootViewController  as? UINavigationController {
                navigationController.popToRootViewController(animated: false)
                navigationController.pushViewController(controller, animated: false)
            }
        }
    }

    
    func onConnected() {
    }
    
    func onDisconnected() {
    }
    
    func onReconnecting(){}

    @objc func copyLink(sender:UIButton){
        if let callLink = CallManager.getCallLink(){
            UIPasteboard.general.string = callLink
            AppAlert.shared.showToast(message: "CallLink \(callLink) copied")

        }
    }
}


extension CallViewController : AudioManagerDelegate {
    
    func audioRoutedTo(deviceName: String, audioDeviceType: OutputType) {
        print("#audiomanager audioRoutedTo  CallViewController \(deviceName) \(audioDeviceType)")
        validateAndUpdateRoutingIcon()
        switch audioDeviceType {
        case .receiver:
            currentOutputDevice = .receiver
            outgoingCallView?.speakerButton.setImage(UIImage(named: "IconSpeakerOff" ), for: .normal)
        case .speaker:
            currentOutputDevice = .speaker
            outgoingCallView?.speakerButton.setImage(UIImage(named: "IconSpeakerOn" ), for: .normal)
        case .headset:
            currentOutputDevice = .headset
            outgoingCallView?.speakerButton.setImage(UIImage(named: "headset" ), for: .normal)
        case .bluetooth:
            currentOutputDevice = .bluetooth
            outgoingCallView?.speakerButton.setImage(UIImage(named: "bluetooth_headset" ), for: .normal)
        @unknown default:
            currentOutputDevice = .receiver
            outgoingCallView?.speakerButton.setImage(UIImage(named: "IconSpeakerOff" ), for: .normal)
        }
    }
    
    @objc func showAudioActionSheet(sender:UIButton){
        audioDevicesAlertController = UIAlertController(title: "Available Devices", message: nil, preferredStyle: .actionSheet)
        for item in AudioManager.shared().getAllAvailableAudioInput() {
            let action = UIAlertAction(title: item.name, style: .default) { _ in
                AudioManager.shared().routeAudioTo(device: item.type, force: true)
                self.audioRoutedTo(deviceName: item.name, audioDeviceType: item.type)
            }
            if item.type == currentOutputDevice{
                let image = UIImage(named: "selectedImg")
                action.setValue(image?.withRenderingMode(.alwaysOriginal), forKey: "image")
            }
            if CallManager.getCallType() == .Video {
                if item.type != .receiver {
                    audioDevicesAlertController!.addAction(action)
                }
            }  else {
                audioDevicesAlertController!.addAction(action)
            }
        }
        audioDevicesAlertController!.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(audioDevicesAlertController!, animated: true)
    }
}

extension CallViewController {
    
    func onUserSpeaking(userId: String, audioLevel: Int) {
        print("#speak speaking \(userId) : \(audioLevel)")
        speakingDictionary[userId] = audioLevel
    }
    
    func onUserStoppedSpeaking(userId: String) {
        print("#speak stopped \(userId)")
        speakingDictionary[userId] = -1
    }
    
    func updateSpeakingUI(userId : String, isSpeaking : Bool, audioLevel : Int = 0 ){
        if !CallManager.isOneToOneCall()  {
            if userId == AppUtils.getMyJid() && isAudioMuted == true && isSpeaking == true {
                updateSpeakingUI(userId: userId, isSpeaking: false)
            }
            if getCallStatusOf(userId: userId) != .connected{
                return
            }
            if let index = findIndexOfUser(jid: userId) {
                if let cell = collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? GroupCallCell{
                    if isSpeaking {
                        cell.contentVIew.layer.borderWidth = 5
                        cell.contentVIew.layer.borderColor = UIColor(named: "PrimaryAppColor")?.cgColor ?? UIColor.systemBlue.cgColor
                    }else {
                        cell.contentVIew.layer.borderWidth = 0
                    }
                }
            }
        }
    }
    
    @objc func validateSpeaking() {
        var highAudioLevel = 0
        var highAudioUserId = ""
        var lastHighAudioUser = ""
        for (id, audioLevel) in speakingDictionary{
            if audioLevel > highAudioLevel{
                highAudioLevel = audioLevel
                highAudioUserId = id
            }
        }
        print("#validateSpeaking loudUser id \(highAudioUserId)")
        var notSpeakingUsers = Array(speakingDictionary.keys)
        notSpeakingUsers.removeAll{$0 == highAudioUserId}
        for userId in notSpeakingUsers{
            updateSpeakingUI(userId: userId, isSpeaking: false)
        }
        if !highAudioUserId.isEmpty {
            lastHighAudioUser = highAudioUserId
            updateSpeakingUI(userId: highAudioUserId, isSpeaking: true)
        }
       
    }
    
}

extension CallViewController {

    func addOneToOneLocalTracks() {
        if !(outgoingCallView?.localUserVideoView.subviews.contains(localRenderer) ?? false) {
            if let localView = outgoingCallView?.localUserVideoView {
                if let localTrack = members.last?.videoTrack {
                    addVideoTrack(to: localView, isLocal: true, track: localTrack)
                }
            }
        }
    }
    
    func addGroupTracks(jid: String) {
        if let index = self.findIndexOfUser(jid: jid) {
            let member = self.members[index]
            if let collectionView = self.collectionView {
                executeOnMainThread {
                    collectionView.performBatchUpdates {
                        if let groupCell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? GroupCallCell {
                            if let videoView = groupCell.videoBaseView {
                                member.videoTrackView.removeFromSuperview()
                                videoView.willRemoveSubview(member.videoTrackView)
                            }
                            #if arch(arm64)
                            let localRen = RTCMTLVideoView(frame: .zero)
                            #else
                            let localRen = RTCEAGLVideoView(frame: .zero)
                            #endif
                            if let baseView = groupCell.videoBaseView {
                                member.videoTrackView = localRen
                                member.videoTrackView.frame = CGRect(x: 0, y: 0, width: baseView.bounds.width, height: baseView.bounds.height)
                                if jid == AppUtils.getMyJid() {
                                    if !member.isVideoMuted {
                                        let track = CallManager.getRemoteVideoTrack(jid: jid)
                                        track?.add(member.videoTrackView)
                                    }
                                } else {
                                    if !member.isVideoMuted {
                                        let videoTrack = CallManager.getRemoteVideoTrack(jid: jid)
                                        videoTrack?.add(member.videoTrackView)
                                    }
                                }
                                baseView.addSubview(member.videoTrackView)
                                groupCell.videoMuteImage.isHidden = (CallManager.getCallType() == .Video && member.isVideoMuted) ? false : true
                            }
                        }
                    }
                }
            }
        }
    }
    
    func switchLoaclandRemoteViews() {
        if isLocalViewSwitched {
            if let localView = outgoingCallView?.localUserVideoView, let remoteView = outgoingCallView?.remoteUserVideoView {
                if let remoteTrack = CallManager.getRemoteVideoTrack(jid: members.first!.jid) {
                    members.first?.videoTrack = remoteTrack
                    addVideoTrack(to: localView, isLocal: true, track: remoteTrack)
                }
                if let localTrack =  CallManager.getRemoteVideoTrack(jid: members.last!.jid) {
                    members.last?.videoTrack = localTrack
                    addVideoTrack(to: remoteView, isLocal: false, track: localTrack)
                    addSwitchedRemoteTrackToView(localView: remoteView, isLocal: false)
                }
            }
        } else {
            if let localView = outgoingCallView?.localUserVideoView, let remoteView = outgoingCallView?.remoteUserVideoView {
                if let localTrack = CallManager.getRemoteVideoTrack(jid: members.last!.jid)  {
                    members.last?.videoTrack = localTrack
                    addVideoTrack(to: localView, isLocal: true, track: localTrack)
                    addSwitchedRemoteTrackToView(localView: localView, isLocal: true)
                }
                if let remoteTrack = CallManager.getRemoteVideoTrack(jid: members.first!.jid) {
                    members.first?.videoTrack = remoteTrack
                    addVideoTrack(to: remoteView, isLocal: false, track: remoteTrack)
                }
            }
        }
    }
    
    func addVideoTrack(to view: UIView, isLocal: Bool, track: RTCVideoTrack) {
        #if arch(arm64)
          let localRen = RTCMTLVideoView(frame: .zero)
        #else
          let localRen = RTCEAGLVideoView(frame: .zero)
        #endif
        if isLocal {
            self.localRenderer.removeFromSuperview()
            view.willRemoveSubview(self.localRenderer)
            self.localRenderer = localRen
            localRenderer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
            view.addSubview(localRenderer)
            track.add(localRenderer)
        } else {
            self.remoteRenderer.removeFromSuperview()
            view.willRemoveSubview(self.remoteRenderer)
            self.remoteRenderer = localRen
            remoteRenderer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
            view.addSubview(remoteRenderer)
            track.add(remoteRenderer)
        }
    }

    func addSwitchedRemoteTrackToView(localView: UIView, isLocal: Bool) {
        if members.last?.isVideoMuted ?? false {
            if let image = ContactManager.shared.getUserProfileDetails(for: members.last?.jid ?? "")?.image {
                remoteImage = image
            }

            localProfileImageView.frame = CGRect(x: 0, y: 0, width: localView.bounds.width, height: localView.bounds.height)
            localProfileImageView.backgroundColor = .black
            localProfileImageView.contentMode = isLocal == false ? .center : .scaleAspectFill
            localProfileImageView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)

            if let contact = ContactManager.shared.getUserProfileDetails(for: members.last?.jid ?? "") {
                if !contact.image.isEmpty {
                    if let contact = ChatManager.profileDetaisFor(jid: AppUtils.getMyJid()), !contact.image.isEmpty{
                        localProfileImageView.contentMode = .scaleAspectFill
                        localProfileImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), jid: contact.jid)
                    }
                } else {
                    let name = getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType)
                    localProfileImageView.image = getPlaceholder(name: name, color: getColor(userName: name), size: isLocal ? Double(localProfileImageView.frame.size.height) : 80, callSwitched: isLocalViewSwitched)
                }
            } else{
                localProfileImageView.image = UIImage.init(named: "ic_profile_placeholder")
            }
            localView.addSubview(localProfileImageView)
        } else {
            localProfileImageView.removeFromSuperview()
        }
    }

    func getPlaceholder(name: String , color: UIColor, size: Double, callSwitched: Bool)->UIImage {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let ipimage = IPImage(text: trimmedName, radius: size, font: UIFont.font32px_appBold(), textColor: nil, color: color)
        let placeholder = callSwitched ? ipimage.generateInitialImage() : ipimage.generateInitialSqareImage()
        return placeholder ??  #imageLiteral(resourceName: "ic_profile_placeholder")
    }
    
    func removeRemoteOneToOneLocalTracks() {
        if let remoteView = self.outgoingCallView?.remoteUserVideoView {
            self.remoteRenderer.removeFromSuperview()
            remoteView.willRemoveSubview(self.remoteRenderer)
        }
    }
    
    func oneToOneVideoViewTransforms(){
        if let localView = outgoingCallView?.localUserVideoView, let remoteView = outgoingCallView?.remoteUserVideoView {
            if isBackCamera {
                if isLocalViewSwitched{
                    remoteView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }else{
                    localView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    callHoldLabel.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }
            }else{
                if isLocalViewSwitched{
                    remoteView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                    callHoldLabel.isHidden = true
                }else{
                    localView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                    callHoldLabel.isHidden = false
                    callHoldLabel.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                }
            }
        }
    }
    func setHoldText(isShow: Bool) {outgoingCallView
        if let localView = outgoingCallView?.localUserVideoView {
            if isShow {
                if !localView.subviews.contains(callHoldLabel) {
                    callHoldLabel = UILabel(frame: CGRect(x: 0, y: 0, width: localView.bounds.width, height: localView.bounds.height))
                    self.callHoldLabel.isHidden = false
                    callHoldLabel.textAlignment = .center
                    callHoldLabel.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                    callHoldLabel.font = .systemFont(ofSize: 14)
                    callHoldLabel.textColor = .white
                    callHoldLabel.text = "Call on hold"
                    localView.addSubview(callHoldLabel)
                } else {
                    self.callHoldLabel.isHidden = false
                }
            } else {
                self.callHoldLabel.isHidden = true
                localView.willRemoveSubview(callHoldLabel)
                callHoldLabel.removeFromSuperview()
            }
        }
    }
    
    @objc func smallVideoTileTapped(_ sender: UITapGestureRecognizer) {
        switchVideoViews.onNext(true)
    }
}

extension CallViewController : ProfileEventsDelegate{
    func userCameOnline(for jid: String) {
        
    }
    
    func userWentOffline(for jid: String) {
        
    }
    
    func userProfileFetched(for jid: String, profileDetails: ProfileDetails?) {
        
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
    
    func userUpdatedTheirProfile(for jid: String, profileDetails: ProfileDetails) {
        
    }
    
    func userBlockedMe(jid: String) {
        getContactNames()
    }
    
    func userUnBlockedMe(jid: String) {
        getContactNames()
    }
    
    func hideUserLastSeen() {
        
    }
    
    func getUserLastSeen() {
        
    }
    
    func userDeletedTheirProfile(for jid: String, profileDetails: ProfileDetails) {
        if CallManager.isOneToOneCall() && CallManager.getAllCallUsersList().contains(jid){
            if CallManager.getCallMode() != .MEET {
                dismissWithDelay()
            }
        }else{
            onCallStatusUpdated(callStatus: .DISCONNECTED, userId: jid)
        }
    }
    
    
}

extension CallViewController : RefreshProfileInfo {
    
    func refreshProfileDetails(profileDetails: ProfileDetails?) {
        if let jid = profileDetails?.jid{
            if CallManager.isOneToOneCall() && CallManager.getAllCallUsersList().contains(jid){
                if CallManager.getCallMode() != .MEET {
                    dismissWithDelay()
                }
            }else{
                onCallStatusUpdated(callStatus: .DISCONNECTED, userId: jid)
            }
        }
        reloadForInVite = true
    }
}

extension CallViewController {
    
    func checkCameraPermission(sourceType: UIImagePickerController.SourceType) {
        AppPermissions.shared.checkCameraPermissionAccess(permissionCallBack: { [weak self] authorizationStatus in
            switch authorizationStatus {
            case .denied:
                self?.isVideoPermissionEnabled = false
               // AppPermissions.shared.presentSettingsForPermission(permission: .camera, instance: self as Any)
                break
            case .restricted:
                self?.isVideoPermissionEnabled = false
                break
            case .authorized:
                self?.isVideoPermissionEnabled = true
                break
            case .notDetermined:
                self?.isVideoPermissionEnabled = true
                break
            @unknown default:
                print("Permission failed")
                self?.isVideoPermissionEnabled = false
               
            }
        })
        
    }
}


extension CallViewController {
    
    func updateCallStatus(status : String = emptyString()){
        if CallManager.getCallMode() == .MEET{
            outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = true
        }else{
            outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = false
            outgoingCallView?.OutgoingRingingStatusLabel?.text = status
        }
    }
    
    func showHideDuration(hide : Bool){
        if CallManager.getCallMode() == .MEET{
            outgoingCallView?.timerLable.isHidden = true
        }else{
            outgoingCallView?.timerLable.isHidden = hide
        }
    }
    
    func showHideParticipantButton(hide : Bool){
        if CallManager.getCallMode() == .MEET{
            outgoingCallView?.addParticipantBtn.isHidden = false
        }else{
            outgoingCallView?.addParticipantBtn.isHidden = hide
        }
       
    }
    
    func validateAndUpdateRoutingIcon(){
        if CallManager.getCallType() == .Video && !(AudioManager.shared().getAllAvailableAudioInput().contains(where: {$0.type == .bluetooth || $0.type == .headset})) {
            outgoingCallView?.speakerButton.isHidden = true
        } else {
            outgoingCallView?.speakerButton.isHidden = false
        }
    }
}

extension String {
    
    func isMyJid()-> Bool{
        if self == nil {
            return false
        }
        return self == AppUtils.getMyJid()
    }
    
}
