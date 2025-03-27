//
//  CallUIViewController.swift
//  MirrorflyUIkit
//
//  Created by MohanRaj on 18/08/23.
//

import UIKit
import WebRTC
import Alamofire
import PulsingHalo
import AVKit
import RxSwift
import MirrorFlySDK
import RealmSwift

enum CallMode : String{
    case Incoming
    case Outgoing
}

enum CallType : String{
    case Audio
    case Video
}

protocol CallViewControllerDelegate {
    func onVideoMute(status:Bool)
    func onAudioMute(status:Bool)
    func onSwitchCamera(completion: @escaping () -> Void)
}

protocol CallDismissDelegate {
    func onCallControllerDismissed()
}

protocol callPipModeDelegate {
    func hanlePipMode()
}

class CallUIViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    
    @IBOutlet weak var outgoingCallView: CallUIXib!
    var delegate : CallViewControllerDelegate?
    static var dismissDelegate : CallDismissDelegate?
    static var refreshDelegate: refreshCallLogDelegate?
    
    var isTapped : Bool!
    var dismissCalled = false
    var isCallConversionRequestedByMe = false
    var isCallConversionRequestedByRemote = false
    var isOnCall = false
    var overlayShown = false
    var isLocalViewSwitched = false
    var isFromInvite = false
    var isVideoPermissionEnabled: Bool = false
    var reloadForInVite = false
    var showHideMenu = true
    var showGridView = false
    var isScrolledToEnd = false
    var qualityToastShown = false
    static var isQualityToastShowing = false
    static var pipModeDelegate: callPipModeDelegate?
    var muteViaReload = false
    var remoteHangUpUserList = [String]()
    
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

    var currentCallStatus: CALLSTATUS = .CALLING

    //var panGesture  = UIPanGestureRecognizer()
    var tapGesture  = UITapGestureRecognizer()
    var closeGesture = UITapGestureRecognizer()
    var videoTapGesture  = UITapGestureRecognizer()
    
    var callType : CallType = .Audio
    var audioPlayer : AVAudioPlayer?

    var members : [CallMember] = []
    var callAgainMembers : [CallMember] = []
    static var sharedInstance = CallUIViewController()
    var itemToRemove = [Int]()
    var itemToInsert = [String]()
    
    var callDurationTimer : Timer?
    var qualityTimer : Timer?
    var seconds = -1
   
    var alertController : UIAlertController?
    var VideoCallConversionTimer : Timer?
    var videoCallRequstTimer: Timer?
    var callViewOverlay = UIView()
    var returnToCall = UIImageView()
    
    var safeAreaHeight : CGFloat = 0.0
    var safeAraeWidth : CGFloat = 0.0
   
    var currentOutputDevice : OutputType = .receiver
    var audioDevicesAlertController : UIAlertController? = nil

    var speakingDictionary  = Dictionary<String, Int>()
  
    var groupId : String = ""
    var switchVideoViews = PublishSubject<Bool>()
    #if arch(arm64)
        //var localRenderer = RTCMTLVideoView(frame: .zero)
        var remoteRenderer = RTCMTLVideoView(frame: .zero)
    #else
       // var localRenderer = RTCEAGLVideoView(frame: .zero)
        var remoteRenderer = RTCEAGLVideoView(frame: .zero)
    #endif
    
    
    //var callHoldLabel = UILabel()
    var rippleView = PulsingHaloLayer()
    var menuView = UIControl()
    
    let flowLayout = UICollectionViewFlowLayout()
    
    var fullScreenUser : CallMember = CallMember()
    
    var isRequestingVideoCall: Bool?
    
    var isPipOpen: Bool = false
    var shouldHideProfile: Bool = false
    var layoutSetBool = true
    var getUserJid: String = AppUtils.getMyJid()
    var audioReRouteFirstTimeOnly = true
      
    // MARK: View Controller Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("#CallUII ====> lifecycle viewDidLoad")
        
        checkForUserBlockingByAdmin()
        isTapped = false
        showHideParticipantButton(hide : true)
        showHideMenuButton(hide: true)
        transformTileAndGridConstraints()
        
        if let heightFormatter = NumberFormatter().number(from: Utility.getStringFromPreference(key: "safeAreaHeight")), let widthFormatter =  NumberFormatter().number(from: Utility.getStringFromPreference(key:  "safeAreaWidth")) {
            safeAreaHeight = CGFloat(Double( Utility.getStringFromPreference(key: "safeAreaHeight"))!)
            safeAraeWidth = CGFloat(Double(Utility.getStringFromPreference(key:  "safeAreaWidth"))!)
        }
        
        updateUI()
        
        switchVideoViews.throttle(.milliseconds(200), latest: false ,scheduler: MainScheduler.instance).subscribe { [weak self] event in
            if CallManager.isOneToOneCall() && CallManager.isCallConnected(){
                self?.isLocalViewSwitched = !(self?.isLocalViewSwitched ?? false)
                self?.oneToOneVideoViewTransforms()
                self?.switchLoaclandRemoteViews()
                if CallManager.getCallType() == .Video {
                    self?.outgoingCallView?.audioCallMutedIcon.isHidden = true
                    if let cell = self?.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: 1, section: 0)) as? TileCell{
                        cell.profileImageView.isHidden = true
                    }
                    if !(self?.isLocalViewSwitched ?? false) {
                        if self?.members.first?.isAudioMuted == true {
                            self?.outgoingCallView?.audioMutedIcon.isHidden = false
                            self?.outgoingCallView?.audioMuteStackView.isHidden = false
                        }else{
                            self?.outgoingCallView?.audioMutedIcon.isHidden = true
                            self?.outgoingCallView?.audioMuteStackView.isHidden = true
                        }
                        self?.getUserJid = AppUtils.getMyJid()
                    }else{
                        self?.outgoingCallView?.audioMutedIcon.isHidden = !(self?.members.last?.isAudioMuted ?? false)
                        self?.outgoingCallView?.audioMuteStackView.isHidden = !(self?.members.last?.isAudioMuted ?? false)
                        if self?.members.first?.callStatus == .reconnecting {
                            if let cell = self?.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: 1, section: 0)) as? TileCell{
                                cell.profileImageView.isHidden = false
                            }
                        }else{
                            if let cell = self?.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: 1, section: 0)) as? TileCell{
                                cell.profileImageView.isHidden = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        layoutSetBool = true
        if CallManager.getCallType() == .Audio {
            shouldHideProfile = false
        }
        if audioReRouteFirstTimeOnly == true {
            audioReRouteFirstTimeOnly = false
            AudioManager.shared().autoReRoute()
        }
        outgoingCallView?.speakerButton.isHidden = false
        print("#CallUII ====> #lifecycle viewWillAppear")
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification
                    , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(callPayloadNotificationReceived(_:)), name: NSNotification.Name("CallPayloadReceived"), object: nil)
        
        self.outgoingCallView?.backBtn.isHidden = false
        
        if CallManager.isOngoingCall() == false {
            self.members.removeAll()
        }
        if !CallManager.isOneToOneCall() && self.members.count > 2 && CallManager.isCallConnected() {
            FlyLogWriter.sharedInstance.writeText("#CALLUI #viewWillAppear showGridView \(showGridView)")
            self.showGridView = true
        }
        self.transformTileAndGridConstraints()
        navigationController?.setNavigationBarHidden(true, animated: false)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        ChatManager.shared.connectionDelegate = self
        CallManager.delegate = self
        CallManager.connectionQuality = self
        AudioManager.shared().audioManagerDelegate = self
       // AudioManager.shared().getCurrentAudioInput()
        dismissCalled = false
        updateUI()
        ContactManager.shared.profileDelegate = self
        isAudioMuted = CallManager.isAudioMuted()
        isVideoMuted = CallManager.isVideoMuted()
        
        if CallManager.getCallMode() == .MEET {
            
            if !isOnCall {
                outgoingCallView?.remoteUserVideoView.willRemoveSubview(remoteRenderer)
                outgoingCallView?.remoteUserVideoView.isHidden = true
                // localRenderer.removeFromSuperview()
                remoteRenderer.removeFromSuperview()
                self.outgoingCallView?.OutGoingCallBG.isHidden = false
                outgoingCallView?.OutGoingCallBG.image = UIImage(named: "call_bg")
                self.outgoingCallView?.tileCollectionView?.isHidden = true
            }
            
            isAudioMuted = CallManager.isAudioMuted()
            isVideoMuted = CallManager.isVideoMuted()
            myCallStatus = .connected
            addMyInfoToMembersArray(videoTrack: nil)
           
            self.outgoingCallView?.cameraButton.isHidden = isVideoMuted
           
            if let collectionView = self.outgoingCallView?.tileCollectionView , (collectionView.numberOfItems(inSection: 0) == 0 || (members.count != collectionView.numberOfItems(inSection: 0))){
                print("#Reload ====> #viewWillAppear")
                self.outgoingCallView?.tileCollectionView?.reloadWithoutAnimation()
            }
            isOnCall = true
            enableButtons(buttons: outgoingCallView?.videoButton, isEnable: true)
            if !isVideoMuted {
                if let track = members.first?.videoTrack {
                    self.addlocalTrackToView(videoTrack: track)
                }
            }else{
               let remoteVideoMuted = (((members.count == 1) ? members.first?.isVideoMuted : (members.count == 2) ? members.first?.isVideoMuted : members[members.count - 2].isVideoMuted) ?? false)
                showHideCallBackgroundProfiles(hide: showGridView ? true : remoteVideoMuted ? false : true)
            }
        }else if CallManager.isOneToOneCall(){
            
            if CallManager.getCallType() == .Audio {
                showHideCallBackgroundProfiles(hide: false)
            }
            if CallManager.getCallType() == .Video {
                let remoteVideoTrack = CallManager.getRemoteVideoTrack(jid: AppUtils.getMyJid()) != nil
                let isVideoMuted = CallManager.isRemoteVideoMuted(members.first?.jid ?? "")
                showHideCallBackgroundProfiles(hide: showGridView ? true : (remoteVideoTrack && !isVideoMuted))
            }
            
            updateOutgoingViewCallStatus(status: getStatusOfOneToOneCall())
            if self.members.first?.callStatus == .ringing {
                updateOutgoingViewCallStatus(status: "Ringing")
            }
            if CallManager.getCallType() == .Video && CallManager.isCallConnected() {
                showConnectedVideoCallOneToOneUI()
            }
            self.outgoingCallView?.cameraButton.isHidden = isVideoMuted
        }else{
            updateOutgoingViewCallStatus(status: getCurrentCallStatusAsString())
            self.outgoingCallView?.cameraButton.isHidden = isVideoMuted
        }
        
        if isOnCall && CallManager.isCallConnected(){
            seconds = UserDefaults.standard.object(forKey: "seconds") as? Int ?? -1
            updateCallDuration()
        }else{
            seconds = -1
            UserDefaults.standard.removeObject(forKey: "seconds")
        }

        if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (self.members.count == 1 || self.members.count == 2)) {
            for member in members {
                if member.jid != AppUtils.getMyJid() {
                    if member.callStatus == .reconnecting {
                        if let contact = ChatManager.getContact(jid: member.jid.lowercased()) {
                            let status = "\(getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType)) Reconnecting"
                            print("reconn label update \(status)")
                            self.updateOutgoingViewCallStatus(status: status)
                        }else{
                            self.updateOutgoingViewCallStatus(status: "\(String(describing: member.jid == AppUtils.getMyJid() ? "" : member.jid)) Reconnecting")
                        }
                    }
                }
            }
        }
        
        self.showHideParticipantButton(hide : (CallManager.isCallConnected() && (myCallStatus == .connected || myCallStatus == .reconnected || myCallStatus == .onHold) && members.count != 8) ? false : true)
        showHideMenuButton(hide : (CallManager.isCallConnected() && (myCallStatus == .connected || myCallStatus == .reconnected || myCallStatus == .onHold)) ? false : true)
        isFromInvite = (isFromInvite) ? false : isFromInvite
        setTopViewsHeight()
        getContactNames()
        setButtonsActions()
        setActionIconsAfterMaximize()
        setMuteStatusText()
        setVideoBtnIcon()
        checkCameraPermission(sourceType: .camera)
        setupTileViewConstraints(isRemoveUser: false)
        if CallManager.getCallMode() == .MEET {
            outgoingCallView?.tileCollectionView.isHidden = members.count >= 2 ? false : true
        }else {
            outgoingCallView?.tileCollectionView.isHidden = CallManager.isCallConnected() ? false : true
        }
        if CallManager.isOneToOneCall() && CallManager.getCallType() == .Video {
            if members.last?.isVideoMuted == true {
                if currentOutputDevice == .speaker {
                    outgoingCallView?.speakerButton.isHidden = false
                }
            }
        }else{
            if currentOutputDevice == .speaker && self.members.last?.isVideoMuted ?? false {
                outgoingCallView?.speakerButton.isHidden = false
            }
        }
        if CallManager.getCallConnectedUsersList()?.isEmpty == true {
            self.seconds = -1
            UserDefaults.standard.removeObject(forKey: "seconds")
            self.outgoingCallView?.timerLable.text = "00.00"
            self.callDurationTimer?.invalidate()
            self.callDurationTimer = nil
            self.showUIRingStatus()
        }
        
        if CallManager.isOneToOneCall() || self.members.count == 2 {
            self.showGridView = false
            self.transformTileAndGridConstraints()
        }
        if members.last?.isVideoMuted ?? false == true {
            outgoingCallView?.OutGoingCallBG.isHidden = false
            outgoingCallView?.OutGoingCallBG.image = UIImage(named: "AudioCallBG")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        outgoingCallView?.tileCollectionView.scrollIndicatorInsets = .zero
        ContactManager.shared.profileDelegate = self
        if reloadForInVite{
            
            outgoingCallView?.tileCollectionView.isHidden = false
            if !CallManager.isOneToOneCall() && itemToInsert.count == 0{
                for member in members.map({$0.jid!}) {
                    addGroupTracks(jid: member)
                }
            }
            reloadForInVite = false
        }else {
            if CallManager.getCallMode() == .MEET {
                outgoingCallView?.tileCollectionView.isHidden = members.count >= 2 ? false : true
                
            }else {
                outgoingCallView?.tileCollectionView.isHidden = CallManager.isCallConnected() ? false : true
            }
           
        }
        CallManager.setMobileCallActionDelegate(delegate: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("#CallUII ====> #lifecycle viewWillDisappear")
        super.viewWillDisappear(animated)
        if overlayShown == false {
            ContactManager.shared.profileDelegate = nil
        }
        CallManager.setMobileCallActionDelegate(delegate: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("#CallUII ====> #lifecycle viewDidDisappear")
        CallManager.delegate = RootViewController .sharedInstance
        ChatManager.shared.connectionDelegate = nil
        //AudioManager.shared().audioManagerDelegate = nil
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        if members.count <= self.outgoingCallView?.tileCollectionView.numberOfItems(inSection: 0) ?? 0 {
            if members.count > 2 && self.outgoingCallView?.tileCollectionView.visibleCells.count ?? 0 > 2 && !isScrolledToEnd {
                executeOnMainThread {
                        self.outgoingCallView?.tileCollectionView.scrollToItem(at: IndexPath(item: self.members.count - 1  , section: 0), at: .centeredHorizontally, animated: false)
                    self.isScrolledToEnd = true
                }
            }
            if members.count == 2 && CallManager.isCallConnected() && !isLocalViewSwitched {
                if layoutSetBool == true {
                    executeOnMainThread {
                        UIView.performWithoutAnimation {
                            self.outgoingCallView?.tileCollectionView.scrollToItem(at: IndexPath(item: 1, section: 0), at: .centeredHorizontally, animated: false)
                            self.layoutSetBool = false
                        }
                    }
                }
            }
        } else {
            print("Attempted to scroll to an out-of-bounds item.")
        }
    }
    
    @objc func willEnterForeground() {
        print("#CallUII ====> #willEnterForeground")
        if CallManager.getCallMode() == .MEET && members.count > 2 {
            print("#Reload ====> #willEnterForeground")
            self.outgoingCallView?.tileCollectionView.reloadWithoutAnimation()
        }
    }
    
    @objc func callPayloadNotificationReceived(_ notification : Notification) {
        RootViewController.sharedInstance.initCallSDK()
        audioReRouteFirstTimeOnly = true
        DispatchQueue.main.async { [weak self] in
            if self?.outgoingCallView?.callAgainView.isHidden == false  && self?.myCallStatus == .tryagain {
                self?.dismissWithDelay(withoutDelay: true)
                self?.dismissCallUI()
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("#CallUII ====> #touchesBegan")
        showHideMenu = true
        removePopupView()
    }
    
    func updateUI() {
        print("#CallUII ====> #updateUI")
        outgoingCallView?.tileCollectionView.tag = 1111
        outgoingCallView?.tileCollectionView.isHidden = true
        outgoingCallView?.tileCollectionView.delegate = self
        outgoingCallView?.tileCollectionView.dataSource = self
        outgoingCallView?.tileCollectionView.register(UINib(nibName: "TileCell", bundle: nil), forCellWithReuseIdentifier: "TileCell")
       
        let image = UIImage(named: "icon_add_user")?.withRenderingMode(.alwaysTemplate)
        outgoingCallView?.addParticipantBtn.setImage(image, for: .normal)
        outgoingCallView?.addParticipantBtn.tintColor = UIColor.white
        
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        if !isOnCall{
            myCallStatus = .calling
        }
        updateActionsUI()
        
        delegate = self
        showHideMenuButton(hide: true)
        if CallManager.getCallDirection() == .Incoming {
            updateOutgoingViewCallStatus(status: "Connecting")
        } else {
            showHideCallAgainView(show: false, status: "Trying to connect")
            updateOutgoingViewCallStatus(status: "Trying to connect")
        }
        if CallManager.getCallMode() == .MEET && members.isEmpty{
            addMyInfoToMembersArray(videoTrack: nil)
        }
        for (memberJid,status) in CallManager.getCallUsersWithStatus() {
            validateAndAddMember(jid: memberJid, with: convertCallStatus(status: status))
        }
        
        if CallManager.isOneToOneCall() {
            
            if CallManager.getCallType() == .Video || self.callType == .Video {
                showOneToOneVideoCallUI()
                if CallManager.isCallConnected() {
                    showConnectedVideoCallOneToOneUI()
                }
                outgoingCallView?.videoButton.setImage(UIImage(named: "IconVideoOff" ), for: .normal)
            }else{
                showOneToOneAudioCallUI()
            }
        } else {
            self.outgoingCallView?.OutGoingCallBG.isHidden = true
            self.outgoingCallView?.cameraButton.isHidden = isVideoMuted
            
            if let collectionView = self.outgoingCallView?.tileCollectionView , (collectionView.numberOfItems(inSection: 0) == 0 || (members.count != collectionView.numberOfItems(inSection: 0))){
                self.outgoingCallView?.tileCollectionView.isHidden = isOnCall ? false : true
            }
            for member in members {
                if member.callStatus == .connected && CallManager.getCallType() == .Video  {
                    if !member.isVideoMuted{
                        addGroupTracks(jid: member.jid)
                    }
                }
            }
           // showGroupCallUI()
        }
        if CallManager.getCallType() == .Video{
            outgoingCallView?.videoButton.setImage(UIImage(named: "IconVideoOff" ), for: .normal)
            if CallManager.getCallDirection() == .Incoming {
               // _ = requestForVideoTrack()
            }
        }
        setMuteStatusText()
        if CallManager.isCallConnected(){
            isOnCall = true
            updateOutgoingViewCallStatus(status:getStatusOfOneToOneCall())
            showHideParticipantButton(hide :false)
            showHideMenuButton(hide: false)
           enableButtons(buttons: outgoingCallView?.videoButton, isEnable: true)
        }else{
            showHideParticipantButton(hide :true)
            showHideMenuButton(hide: true)
            updateOutgoingViewCallStatus(status: CallManager.getCallDirection() == .Incoming ? "Connecting" : "Trying to connect")
            FlyLogWriter.sharedInstance.writeText("-------#CallUI----#UpdateUI----- \(CallManager.getCallDirection())")
            enableButtons(buttons: outgoingCallView?.videoButton, isEnable: false)
            if self.members.first?.callStatus == .ringing {
                updateOutgoingViewCallStatus(status: "Ringing")
            }
        }
        if CallManager.getCallMode() == .MEET{
            enableButtons(buttons: outgoingCallView?.videoButton, isEnable: true)
        }
    }
    
    @objc func updateCallDuration() {
        if CallManager.getCallMode() == .MEET || !CallManager.isCallConnected(){
            outgoingCallView?.timerLable.isHidden = true
            return
        }
//        getContactNames()
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
    
   
    func getContactNames(){
        print("#CallUII ====> #getContactNames")
        if CallManager.getCallMode() == .MEET && members.count < 2 {
             outgoingCallView?.OutGoingPersonLabel.text = "You"
             let membersJid = members.compactMap { $0.jid }
             self.showMainScreenProfileImage(membersJid: membersJid)
            return
        }
        
        let callStatus = getCurrentCallStatusAsString()
        let isConnected = (callStatus == "Trying to connect" || callStatus == "Unavailable, Try again later" || callStatus == "Ringing" || callStatus == "Connecting" || callStatus == "Disconnected" || callStatus == "User Seems to be Offline, Trying to Connect") ? false : true
        
        var unknowGroupMembers = [String]()
        let membersJid = members.compactMap { $0.jid }.filter {$0 != AppUtils.getMyJid()}
        if membersJid.count == 1 {
            if let contact = ChatManager.getContact(jid: membersJid[0].lowercased()){
                
                let name = getNameStringWithGroupName(userNames: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
                
                if isConnected {
                    outgoingCallView?.OutGoingPersonLabel.text = CallManager.isCallConnected() && groupId.isEmpty ? "You and \(name)" : name
                }else {
                    outgoingCallView?.OutgoingRingingStatusLabel.text = CallManager.isCallConnected() && groupId.isEmpty ? "You and \(name)" : name
                }
            }
        } else if membersJid.count == 2 {
            for i in 0...1{
                if let contact = ChatManager.getContact(jid: membersJid[i].lowercased()){
                    unknowGroupMembers.append(getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
                }
            }
            unknowGroupMembers = unknowGroupMembers.sorted()
            let groupMemberName = unknowGroupMembers.joined(separator: ",")
            if isConnected {
                outgoingCallView?.OutGoingPersonLabel.text = getNameStringWithGroupName(userNames: "You,\(groupMemberName)")
            }else {
                outgoingCallView?.OutgoingRingingStatusLabel.text = getNameStringWithGroupName(userNames: "You,\(groupMemberName)")
            }
            outgoingCallView?.outGoingAudioCallImageView.image = CallManager.isCallConnected() && groupId.isEmpty ? UIImage.init(named: "ic_profile_placeholder") : UIImage.init(named: "ic_groupPlaceHolder")
        } else if membersJid.count > 2 {
            unknowGroupMembers.removeAll()
            for i in 0...1{
                if let contact = ChatManager.getContact(jid: membersJid[i].lowercased()){
                    unknowGroupMembers.append(getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
                }
            }
            unknowGroupMembers = unknowGroupMembers.sorted()
            let groupMemberName = unknowGroupMembers.joined(separator: ",")
            let nameString = CallManager.isCallConnected()  && groupId.isEmpty ? "You,\(groupMemberName)" : "You,\(groupMemberName)"
//            if nameString.count > 32 {
//                nameString = groupMemberName.substring(to: 31) + "..."
//            }
            if isConnected {
                outgoingCallView?.OutGoingPersonLabel.text = getNameStringWithGroupName(userNames:  String(format: "%@ and (+ %lu)", nameString, membersJid.count - 2))
            }else {
                outgoingCallView?.OutgoingRingingStatusLabel.text = getNameStringWithGroupName(userNames:  String(format: "%@ and (+ %lu)", nameString, membersJid.count - 2))
            }
            outgoingCallView?.outGoingAudioCallImageView.image = CallManager.isCallConnected() && groupId.isEmpty ? UIImage.init(named: "ic_profile_placeholder") : UIImage.init(named: "ic_groupPlaceHolder")
        }else {
            outgoingCallView?.OutGoingPersonLabel.text = ""
        }
        
        
        self.showMainScreenProfileImage(membersJid: membersJid)
        self.showHideMultipleProfileImages(isConnected: isConnected)
    }
    
    func showMainScreenProfileImage(membersJid: [String]) {
        if membersJid.count > 0 {
            
            let lastMember = members.first(where: {$0.jid == membersJid[membersJid.count - 1] && ($0.callStatus == .connected || $0.callStatus == .onHold)})
            let firstMember = members.first(where: {$0.callStatus == .connected})
            
            if groupId.isEmpty  && membersJid.count == 1{
                if let contact = ChatManager.profileDetaisFor(jid: (isLocalViewSwitched) ? AppUtils.getMyJid().lowercased() : membersJid[0].lowercased()){
                    outgoingCallView?.outGoingAudioCallImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), jid: contact.jid)
                    
                    if let index = findIndexOfUser(jid: contact.jid) {
                        fullScreenUser = members[index]
                    }
                    
                }else{
                    outgoingCallView?.outGoingAudioCallImageView.image = UIImage.init(named: "ic_profile_placeholder")
                }
            } else {
                if !groupId.isEmpty && CallManager.getCallType() == .Audio { // To show group image, if it is group call
                    if !CallManager.isOneToOneCall() {
                        if let contact = ChatManager.profileDetaisFor(jid: groupId){
                            outgoingCallView?.outGoingAudioCallImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), chatType: contact.profileChatType,jid: contact.jid)
                        }
                        return
                    }
                }
                if membersJid.count == 1 && membersJid.first != AppUtils.getMyJid() {
                    if groupId.isEmpty {
                        if let contact = ChatManager.profileDetaisFor(jid: membersJid.first ?? ""){
                            outgoingCallView?.outGoingAudioCallImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), chatType: contact.profileChatType, jid: contact.jid)
                            
                            if let index = findIndexOfUser(jid: contact.jid) {
                                fullScreenUser = members[index]
                            }
                        }
                        
                    } else {
                        if let contact = ChatManager.profileDetaisFor(jid: membersJid.first ?? ""){
                            outgoingCallView?.outGoingAudioCallImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), chatType: contact.profileChatType,jid: contact.jid)
                            
                            if let index = findIndexOfUser(jid: contact.jid) {
                                fullScreenUser = members[index]
                            }
                        }
                    }
                } else {
                    if let contact = ChatManager.profileDetaisFor(jid: groupId.isEmpty ? (membersJid.count == 0) ? "" : membersJid[membersJid.count - 1].lowercased() : (lastMember?.callStatus == .connected || lastMember?.callStatus == .onHold) ? membersJid[membersJid.count - 1].lowercased() : (CallManager.getCallType() == .Video && members.first?.callStatus != .connected) ? members.first?.jid ?? "" : (!groupId.isEmpty && !CallManager.isCallConnected()) ? groupId : firstMember?.jid ?? ""){
                        
                        outgoingCallView?.outGoingAudioCallImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), chatType: contact.profileChatType, jid: contact.jid)
                        
                        if let index = findIndexOfUser(jid: contact.jid) {
                            if CallManager.getCallType() == .Audio || self.callType == .Audio {
                                fullScreenUser = members[index]
                            }
                        }
                    } else {
                        
                        if membersJid.count >= 2{
                            
                            if let contact = ChatManager.getContact(jid: groupId.isEmpty ? membersJid[membersJid.count - 1].lowercased() : (lastMember?.callStatus == .connected || lastMember?.callStatus == .onHold) ? membersJid[membersJid.count - 1].lowercased() : (!groupId.isEmpty && !CallManager.isCallConnected()) ? groupId : firstMember?.jid ?? "") {
                                outgoingCallView?.outGoingAudioCallImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), chatType: contact.profileChatType, jid: contact.jid)
                                if let index = findIndexOfUser(jid: contact.jid) {
                                    fullScreenUser = members[index]
                                }
                            } else {
                                
                                if groupId.isEmpty {
                                    
                                    if let contact = ChatManager.getContact(jid: membersJid[membersJid.count - 1].lowercased()) {
                                        outgoingCallView?.outGoingAudioCallImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), chatType: contact.profileChatType, jid: contact.jid)
                                        
                                        if let index = findIndexOfUser(jid: contact.jid) {
                                            fullScreenUser = members[index]
                                        }
                                    }else {
                                        outgoingCallView?.outGoingAudioCallImageView.image = UIImage.init(named: "ic_profile_placeholder")
                                    }
                                    
                                } else {
                                    
                                    outgoingCallView?.outGoingAudioCallImageView.image = CallManager.isCallConnected() ? UIImage.init(named: "ic_profile_placeholder") : UIImage.init(named: "ic_groupPlaceHolder")
                                }
                            }
                        } else {
                            outgoingCallView?.outGoingAudioCallImageView.image = CallManager.isCallConnected() ? UIImage.init(named: "ic_profile_placeholder") : UIImage.init(named: "ic_groupPlaceHolder")
                        }
                    }
                }
            }
        }
    }
    
    func getNameStringWithGroupName(userNames : String) -> String{
        print("#CallUII ====> #getNameStringWithGroupName")
        var name = ""
        if !groupId.isEmpty{
            if let group = ChatManager.profileDetaisFor(jid: groupId){
                name = group.name  //+ "\n" + userNames
            }
        }else{
            name = userNames
        }
        return name
    }
    
    func setMuteStatusText() {
        print("#CallUII ====> #setMuteStatusText")
        DispatchQueue.main.async { [weak self] in
            if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (self?.members.count == 1 || self?.members.count == 2)) {
                if !(self?.isLocalViewSwitched ?? false) {
                    let isCallConnected = self?.isOnCall ?? false
                    let remoteAudioMuted = self?.members.first?.isAudioMuted ?? false, remoteVideoMuted =  (self?.members.first?.isVideoMuted ?? false && isCallConnected)
                    let myVideoMuted =  self?.isVideoMuted
                    let showHideView = remoteAudioMuted || remoteVideoMuted
                    self?.outgoingCallView?.audioMuteStackView.isHidden = !showHideView
                    self?.outgoingCallView?.audioMuteStackView.arrangedSubviews[1].isHidden = (CallManager.getCallType() == .Video) ? !remoteAudioMuted : true
                    self?.outgoingCallView?.audioMuteStackView.arrangedSubviews.first?.isHidden = true
                    if (remoteVideoMuted && CallManager.getCallType() == .Video)  && remoteAudioMuted {
                        self?.outgoingCallView?.audioMuteStackView.arrangedSubviews.first?.isHidden = false
                        self?.outgoingCallView?.audioMutedLable.text = ""
                    } else if remoteVideoMuted && CallManager.getCallType() == .Video {
                        self?.outgoingCallView?.audioMuteStackView.arrangedSubviews.first?.isHidden = false
                        self?.outgoingCallView?.audioMutedLable.text = ""
                    } else  if remoteAudioMuted{
                        self?.outgoingCallView?.audioMuteStackView.arrangedSubviews.first?.isHidden = true
                        self?.outgoingCallView?.audioMutedLable.text = ""
                    }
                    if (remoteVideoMuted == true) && (myVideoMuted == true){
                        self?.outgoingCallView?.audioMuteStackView.arrangedSubviews.first?.isHidden = true
                        if remoteAudioMuted {
                            self?.outgoingCallView?.audioMutedLable.text = ""
                        }else{
                            self?.outgoingCallView?.audioMuteStackView.isHidden = true
                        }
                        self?.outgoingCallView?.videoButton.setImage(UIImage(named: "ic_video_inactive" ), for: .normal)
                    }
                    
                    if self?.showGridView ?? false {
                        
                        self?.outgoingCallView?.audioMuteStackView.isHidden = true
                        self?.outgoingCallView?.audioCallMutedIcon.isHidden = true
                        self?.showOrHideAudioWaveView(hide: true)
                        
                    }else {
                        
                        self?.outgoingCallView?.audioCallMutedIcon.isHidden = (remoteAudioMuted && CallManager.getCallType() == .Audio) ? false : true
                        self?.showOrHideAudioWaveView(hide: (self?.myCallStatus == .tryagain) ? true : (remoteAudioMuted && CallManager.getCallType() == .Audio) || (CallManager.getCallType() == .Video && remoteVideoMuted && remoteAudioMuted) || (CallManager.getCallType() == .Video && !remoteVideoMuted) ? true : false)
                        print("audioWaveView.isHidden 4 \((self?.myCallStatus == .tryagain) ? true : (remoteAudioMuted && CallManager.getCallType() == .Audio) || (CallManager.getCallType() == .Video && remoteVideoMuted && remoteAudioMuted) || (CallManager.getCallType() == .Video && !remoteVideoMuted) ? true : false)")

                        let callStatus = self?.getCurrentCallStatusAsString()
                        let isConnected = (callStatus == "Trying to connect" || callStatus == "Unavailable, Try again later" || callStatus == "Ringing") ? false : true
                        
                        if !isConnected && ((self?.groupId.isEmpty) != nil) && self?.members.count ?? 0 > 2 {
                            self?.showOrHideAudioWaveView(hide: true)
                        }
                        
                        if self?.members.last?.isVideoMuted ?? false == true {
                            self?.outgoingCallView?.audioMuteStackView.isHidden = true
                            self?.outgoingCallView?.audioMutedIcon.isHidden = true
                            self?.outgoingCallView?.audioCallMutedIcon.isHidden = !remoteAudioMuted
                            self?.showHideCallBackgroundProfiles(hide: false)
                            self?.showOrHideAudioWaveView(hide: remoteAudioMuted)
                        }
                        if self?.members.last?.isVideoMuted ?? false == false {
                            self?.outgoingCallView?.audioMuteStackView.isHidden = !remoteAudioMuted
                            self?.outgoingCallView?.audioMutedIcon.isHidden = !remoteAudioMuted
                            self?.outgoingCallView?.audioCallMutedIcon.isHidden = true
                            self?.showHideCallBackgroundProfiles(hide: true)
                            self?.showOrHideAudioWaveView(hide: true)
                        }
                    }
                }else{
                    if let cell = self?.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: 0, section: 0)) as? TileCell{
                        let remoteAudioMuted = self?.members.first?.isAudioMuted ?? false
                        if !remoteAudioMuted {
                            let imageArray = [UIImage(named: "audio_lvl_one")!,UIImage(named: "audio_lvl_two")!,UIImage(named: "audio_lvl_three")!,UIImage(named: "audio_lvl_four")!,UIImage(named: "audio_lvl_five")!]
                            cell.audioIconImageView.animationImages = imageArray
                            cell.audioIconImageView.animationDuration = 0.5
                            cell.audioIconImageView.startAnimating()
                            
                        }else {
                            cell.audioIconImageView.stopAnimating()
                            cell.audioIconImageView.image = UIImage(systemName: "mic.slash.fill")?.withRenderingMode(.alwaysTemplate)
                            cell.audioIconImageView.tintColor = .white
                        }
                    }
                }
            }else {
                
                if self?.showGridView ?? false {
                
                    self?.outgoingCallView?.audioMuteStackView.isHidden = true
                    self?.outgoingCallView?.audioCallMutedIcon.isHidden = true
                    self?.showOrHideAudioWaveView(hide: true)
                    
                }else {
                    
                    let callStatus = self?.getCurrentCallStatusAsString()
                    let isConnected = (callStatus == "Trying to connect" || callStatus == "Unavailable, Try again later" || callStatus == "Ringing") ? false : true
                    
                    self?.outgoingCallView?.audioMuteStackView.isHidden = true

                    if (self?.members.count ?? 0) > 2 {
                       // self?.outgoingCallView?.audioCallMutedIcon.isHidden = self?.members[(self?.members.count ?? 0) - 2].isAudioMuted ?? false ? false : true
                        
                        if (self?.members[(self?.members.count ?? 0) - 2].isVideoMuted ?? false) == false {
                            self?.showOrHideAudioWaveView(hide: true)
                            self?.outgoingCallView?.audioCallMutedIcon.isHidden = true
                        } else {
                            self?.outgoingCallView?.audioCallMutedIcon.isHidden = self?.fullScreenUser.isAudioMuted ?? false ? false : true
                            self?.showOrHideAudioWaveView(hide: (self?.myCallStatus == .tryagain) ? true : (self?.members[(self?.members.count ?? 0) - 2].isAudioMuted ?? false && CallManager.getCallType() == .Audio) || (self?.members[(self?.members.count ?? 0) - 2].isAudioMuted ?? false && CallManager.getCallType() == .Video && self?.members[(self?.members.count ?? 0) - 2].isVideoMuted ?? false) || (CallManager.getCallType() == .Video && !(self?.members[(self?.members.count ?? 0) - 2].isVideoMuted ?? false)) ? true : false)
                        }
                        //|| (CallManager.getCallType() == .Audio && !(self?.members[(self?.members.count ?? 0) - 2].isVideoMuted ?? false))
                        print("audioWaveView.isHidden 5 \((self?.myCallStatus == .tryagain)) - \((self?.members[(self?.members.count ?? 0) - 2].isAudioMuted ?? false && CallManager.getCallType() == .Audio)) - \((self?.members[(self?.members.count ?? 0) - 2].isAudioMuted ?? false && CallManager.getCallType() == .Video && self?.members[(self?.members.count ?? 0) - 2].isVideoMuted ?? false)) - \((CallManager.getCallType() == .Video && !(self?.members[(self?.members.count ?? 0) - 2].isVideoMuted ?? false))) - final = \((self?.myCallStatus == .tryagain) ? true : (self?.members[(self?.members.count ?? 0) - 2].isAudioMuted ?? false && CallManager.getCallType() == .Audio) || (self?.members[(self?.members.count ?? 0) - 2].isAudioMuted ?? false && CallManager.getCallType() == .Video && self?.members[(self?.members.count ?? 0) - 2].isVideoMuted ?? false) || (CallManager.getCallType() == .Video && !(self?.members[(self?.members.count ?? 0) - 2].isVideoMuted ?? false)) ? true : false)")
                    }
                    
                    if !isConnected && ((self?.groupId.isEmpty) != nil) && self?.members.count ?? 0 > 2 {
                        self?.showOrHideAudioWaveView(hide: true)
                    }
                    
                }
            }
        }
    }
    
}

// MARK: Setup UI for Audio/Video Call
extension CallUIViewController {

    func showOneToOneAudioCallUI() {
        outgoingCallView?.isHidden = false
        outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = false
        setupTopViewConstraints()
        getContactNames()
        outgoingCallView?.remoteUserVideoView.isHidden = true
        outgoingCallView?.cameraButton.isHidden = true
        showHideCallBackgroundProfiles(hide: showGridView ? true : false)
        outgoingCallView?.videoButton.setImage(UIImage(named: "ic_video_inactive" ), for: .normal)
        isCallConversionRequestedByMe = false
        setupTileViewConstraints(isRemoveUser: false)

        if CallManager.isCallConnected() {
            //outgoingCallView?.timerTop.constant = 8
            outgoingCallView?.outGoingAudioCallImageView.transform = CGAffineTransform(translationX: 0, y: 0)
            if CallManager.getCallStatus(userId: AppUtils.getMyJid()) != .RECONNECTING{
                updateOutgoingViewCallStatus(status: (CallManager.isCallConnected() && !CallManager.isOneToOneCall()) ? CallStatus.connected.rawValue :  getStatusOfOneToOneCall())
            }
            setMuteStatusText()
            showHideParticipantButton(hide :false)
            showHideDuration(hide: false)
            showHideMenuButton(hide: false)
        }
        validateReconnectingStatus()
        updatePipProfileImage()
    }
    
    func showOneToOneVideoCallUI() {
        if !showGridView && (CallManager.isOneToOneCall() || members.count == 2) {
            outgoingCallView?.remoteUserVideoView.isHidden = false
        }else{
            outgoingCallView?.remoteUserVideoView.isHidden = true
        }
        outgoingCallView?.cameraButton.isHidden = isVideoMuted
        outgoingCallView?.outGoingAudioCallImageView.isHidden = !groupId.isEmpty && !CallManager.isCallConnected() ? false : true
        //let remoteVideoMuted = members[members.count - 2].isVideoMuted
        var remoteVideoMuted = false
        if CallManager.getCallMode() == .MEET {
            remoteVideoMuted = (((members.count == 1) ? members.first?.isVideoMuted : (members.count == 2) ? members.first?.isVideoMuted : members[members.count - 2].isVideoMuted) ?? false)
        }else {
            if members.count > 2 {
                remoteVideoMuted = members[members.count - 2].isVideoMuted
            }
        }
        
        if remoteVideoMuted {
            outgoingCallView?.outGoingAudioCallImageView.isHidden = false
        }
        showHideDuration(hide: true)
        outgoingCallView?.OutGoingCallBG.image = CallManager.getRemoteVideoTrack(jid: AppUtils.getMyJid())  != nil  ? nil : UIImage(named: "call_bg")
        outgoingCallView?.OutGoingCallBG.isHidden = CallManager.getRemoteVideoTrack(jid: AppUtils.getMyJid())  != nil
        //outgoingCallView?.contentView.backgroundColor = .clear
        getContactNames()
        setupTopViewConstraints()
        if CallManager.isCallConnected() {
            showHideParticipantButton(hide : false)
            showHideMenuButton(hide: false)
            showHideDuration(hide: false)
        }
        if !isOnCall && CallManager.isOneToOneCall(){
            resetLocalVideCallUI()
        }
        setupTileViewConstraints(isRemoveUser: false)
        validateReconnectingStatus()
        updatePipProfileImage()
        if members.first?.isAudioMuted == true {
            if !isLocalViewSwitched {
                self.outgoingCallView?.audioMutedIcon.isHidden = false
                self.outgoingCallView?.audioCallMutedIcon.isHidden = true
            }
        }
    }
    
    func showConnectedVideoCallOneToOneUI() {
        print("#CallUII ====> #showConnectedVideoCallOneToOneUI")
        if !showGridView && (CallManager.isOneToOneCall() || members.count == 2) {
            outgoingCallView?.remoteUserVideoView.isHidden = false
        }else{
            outgoingCallView?.remoteUserVideoView.isHidden = true
        }
        isCallConversionRequestedByMe = false
        //self.localRenderer.frame = CGRect(x: 0, y: 0, width: 110, height: 160)
        showHideDuration(hide:  false)
        
        if CallManager.isCallConnected() {
            getContactNames()
            showHideParticipantButton(hide : false)
            showHideMenuButton(hide: false)

            if !(members.last?.isVideoMuted ?? false) && !(members.first?.isVideoMuted ?? false) {
                videoTapGesture = UITapGestureRecognizer(target: self, action: #selector(smallVideoTileTapped(_:)))
                outgoingCallView?.tileCollectionView?.addGestureRecognizer(videoTapGesture)
            }
        }
        setVideoBtnIcon()
    }
    
    func showGroupCallUI() {
        print("#CallUII ====> #showGroupCallUI")
        if CallManager.getCallType() == .Video {
            showOneToOneVideoCallUI()
            addRemoteTrackToView()
        }else {
            showOneToOneAudioCallUI()
        }
        getContactNames()
        setupTileViewConstraints(isRemoveUser: false)
        // outgoingCallView?.tileCollectionView.reloadWithoutAnimation()  - avoid invite user flicker.
       // validateReconnectingStatus()
    }
    
}

// MARK: Setup Actions for Audio/Video Call
extension CallUIViewController {
    
    func checkForUserBlockingByAdmin() {
        print("#CallUII ====> #checkForUserBlockingByAdmin")
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
    
    @objc func draggedCollectionView(_ sender:UIPanGestureRecognizer){
        print("#CallUII ====> #draggedCollectionView")
        guard let localView = outgoingCallView?.tileCollectionView! else { return }
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
        print("#CallUII ====> #resetLocalVideCallUI")
        outgoingCallView?.tileCollectionView.isHidden = true
    }
    
    func updateActionsUI() {
        print("#CallUII ====> #updateActionsUI")
        enableDisableUserInteractionFor(view: outgoingCallView?.AttendingBottomView, isDisable: false)
        outgoingCallView?.videoButton.setImage(UIImage(named: isVideoMuted ? "ic_video_inactive" :  "IconVideoOff" ), for: .normal)
        outgoingCallView?.audioButton.setImage(UIImage(named: isAudioMuted ? "IconAudioOn" :  "IconAudioOff" ), for: .normal)
        outgoingCallView?.cameraButton.setImage(UIImage(named: isBackCamera ? "IconCameraOn" :  "IconCameraOff" ), for: .normal)
    }
    
    @objc func backAction(sender: UIButton?) {
        CallUIViewController.pipModeDelegate?.hanlePipMode()
        let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if let navigationController = window?.rootViewController as? UINavigationController,let presented = navigationController.presentedViewController {
            print("#dismissCallUI dismissed root")
            window?.rootViewController?.dismiss(animated: true)
        }else{
            print("#dismissCallUI dismissed")
            dismiss(animated: true, completion: nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {[weak self] in
            self?.showCallOverlay()
        }
    }
    
    @objc func cancelBtnTapped(sender:UIButton) {
        print("#CallUII ====> #cancelBtnTapped")
        dismissWithDelay()
        dismissCallUI()
    }
    
    @objc func callEndlBtnTapped(sender:UIButton) {
        members.removeAll()
        dismissWithDelay()
        print("#CallUII ====> #dismissCallUI #callEndlBtnTapped")
        dismissCallUI()
        outgoingCallView?.OutGoingPersonLabel.text = "Disconnected"
        CallManager.disconnectCall()
    }
    
    private func onCallConversion() {
        if CallManager.isOneToOneCall() && CallManager.getCallType() == .Audio {
            callConversionPopup()
        } else {
            print("#mute videoButtonTapped else")
            isVideoMuted.toggle()
            if !CallManager.isOneToOneCall(){
                if members.last?.videoTrack == nil{
                    print("#mute videoButtonTapped if if isVideoMuted: false")
                    CallManager.enableVideo()
                }else {
                    let notVideoMuted = members.filter({$0.isVideoMuted == false})
                    if notVideoMuted.count == 0 {
                        CallManager.setCallType(callType: .Audio)
                        getUserJid = AppUtils.getMyJid()
                    }else {
                        CallManager.setCallType(callType: .Video)
                        getUserJid = AppUtils.getMyJid()
                    }
                }
            }
            delegate?.onVideoMute(status: isVideoMuted)
        }
    }
    
    @objc func videoButtonTapped(sender:UIButton) {
        
        if CallManager.isCallOnHold() {
            return
        }
        
        if isVideoPermissionEnabled {
            onCallConversion()
        } else {
            AppPermissions.shared.checkCameraPermissionAccess(permissionCallBack: { [weak self] authorizationStatus in
                switch authorizationStatus {
                case .denied:
                    AppPermissions.shared.presentSettingsForPermission(permission: .camera, instance: self as Any)
                    break
                case .restricted:
                    AppPermissions.shared.presentSettingsForPermission(permission: .camera, instance: self as Any)
                    break
                case .authorized:
                    self?.onCallConversion()
                    break
                case .notDetermined:
                    AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                        if granted {
                            executeOnMainThread { [weak self] in
                                self?.isVideoPermissionEnabled = true
                                self?.videoButtonTapped(sender: UIButton())
                                self?.setMuteStatusText()
                            }
                        } else {
                            AppPermissions.shared.presentSettingsForPermission(permission: .camera, instance: self as Any)
                        }
                    })
                    break
                @unknown default:
                    print("Permission failed")
                    AppPermissions.shared.presentSettingsForPermission(permission: .camera, instance: self as Any)
                   
                }
            })
        }
    }
    
    @objc func callAgainBtnTapped(sender:UIButton) {
        if let topController = UIApplication.shared.keyWindow?.rootViewController {
            if let presentedViewController = topController.presentedViewController {
                presentedViewController.dismiss(animated: false)
            }
        }
        if NetworkReachability.shared.isConnected {
            if CallManager.isAlreadyOnAnotherCall(){
                AppAlert.shared.showToast(message: "You’re already on call, can't make new MirrorFly call")
                return
            }
            myCallStatus = .calling
            showHideCallAgainView(show: false, status: "Trying to connect")

            makeCall(usersList: callAgainMembers.compactMap{$0.jid}, callType: callType, groupId: self.groupId, onCompletion: { isSuccess, message in
                if(!isSuccess){
                    let errorMessage = AppUtils.shared.getErrorMessage(description: message)
                    AppAlert.shared.showAlert(view: self, title: "", message: errorMessage, buttonTitle: "Okay")
                }else{
                    RootViewController.sharedInstance.addCallUIVC()
                }
            })
        }else {
            AppAlert.shared.showToast(message: ErrorMessage.checkYourInternet)
        }
    }
    
    @objc func CameraButtonTapped(sender:UIButton) {
        print("#CallUII ====> #CameraButtonTapped")
        isBackCamera.toggle()
        members.last?.isOnBackCamera = isBackCamera
        delegate?.onSwitchCamera() {
            executeOnMainThread { [weak self] in
                guard let self else {return}
                if self.isBackCamera{
                    if CallManager.isOneToOneCall() {
                        self.oneToOneVideoViewTransforms()
                    }else{
                        if let myCell = self.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: self.findIndexOfUser(jid: AppUtils.getMyJid()) ?? self.members.count - 1, section: 0)) as? TileCell{
                            myCell.videoBaseView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                        }
                    }
                }else{
                    if CallManager.isOneToOneCall() {
                        self.oneToOneVideoViewTransforms()
                    }else{
                        if let myCell = self.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: self.findIndexOfUser(jid: AppUtils.getMyJid()) ?? self.members.count - 1, section: 0)) as? TileCell{
                            myCell.videoBaseView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                        }
                    }
                }
            }
        }
    }
    
    @objc func AudioButtonTapped(sender:UIButton) {
        print("#CallUII ====> #AudioButtonTapped")
        if CallManager.isCallOnHold(){
            FlyLogWriter.sharedInstance.writeText("#Unable audio mute action isCallOnHold reurn butonn action...........")
            return
        }
        isAudioMuted.toggle()
        members.last?.isAudioMuted = isAudioMuted
        delegate?.onAudioMute(status: isAudioMuted)
    }
    
    @objc func SingleTapGesturTapped(_ sender: UITapGestureRecognizer) {
        print("#CallUII ====> #SingleTapGesturTapped")
        showHideMenu = true
        removePopupView()
        
        if CallManager.isCallConnected(){
            
            if isTapped == false{
                isTapped = true
                let bottom = CGAffineTransform(translationX: 0, y: 200)
                let top = CGAffineTransform(translationX: 0, y: -400)
                let collectionBottom = CGAffineTransform(translationX: 0, y: showGridView ? 0 : 150)
                
                UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
                    self.outgoingCallView?.AttendingBottomView.transform = bottom
                    self.outgoingCallView?.tileCollectionView.transform = collectionBottom
                }, completion: nil)
            }else{
                isTapped = false
                let top = CGAffineTransform(translationX: 0, y: showGridView ? 0 : -20)
                let bottom = CGAffineTransform(translationX: 0, y: 0)
                
                let collectionTop = CGAffineTransform(translationX: 0, y: showGridView ? 0 : -20)
                
                let viewMaxY = safeAreaHeight - 172
               
                UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
                    self.outgoingCallView?.AttendingBottomView.transform = top
                    self.outgoingCallView?.tileCollectionView.transform = top
                }, completion: nil)
            }
        }
        
    }
    
}


// MARK: Call Switch Pop-Up & UI Changes
extension CallUIViewController {
    
    // Show confirmation pop up for call Switching
    func callConversionPopup() {
        print("#CallUII ====> #callConversionPopup")
        //showConfirmationAlertForCallSwitching
        alertController?.dismiss(animated: false)
        alertController = UIAlertController.init(title: nil , message: "Are you sure you want to switch to Video Call", preferredStyle: .alert)
        let switchAction = UIAlertAction(title: "Switch", style: .default) { [weak self] (action) in
            CallManager.requestVideoCallSwitch { isSuccess in
                if isSuccess {
                    self?.isCallConversionRequestedByMe = true
                    self?.showAlertViewWithIndicator()
                    print("**** Send switch call request ****** Timer started \(NSDate())")
                    self?.VideoCallConversionTimer = Timer.scheduledTimer(timeInterval: 20, target: self ?? CallUIViewController.self, selector: #selector(self?.videoCallConversionTimer), userInfo: nil, repeats: false)
                }
            }
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { [weak self] (action) in
            CallManager.setCallType(callType: .Audio)
            self?.getUserJid = AppUtils.getMyJid()
            self?.isCallConversionRequestedByMe = false
            self?.resetConversionTimer()
        }
        alertController?.addAction(switchAction)
        alertController?.addAction(cancelAction)
        //  let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        DispatchQueue.main.async { [weak self] in
            if let topController = UIApplication.shared.keyWindow?.rootViewController {
                if let presentedViewController = topController.presentedViewController {
                    if let alert = self?.alertController {
                        presentedViewController.present(alert, animated: true, completion: {
                        })
                    }
                }
            }
        }
    }
    
    func showAlertViewWithIndicator() {
        if self.isCallConversionRequestedByMe && self.isCallConversionRequestedByRemote{
            CallManager.setCallType(callType: .Video)
            self.showHideCallBackgroundProfiles(hide: true)
            CallManager.acceptVideoCallSwitchRequest()
            isVideoMuted = false
            switchAudioToVideoCall()
            isCallConversionRequestedByMe = false
            isCallConversionRequestedByRemote = false
            resetConversionTimer()
            DispatchQueue.main.async  {  [weak self] in
                self?.alertController?.dismiss(animated: true, completion: nil)
            }
            CallManager.muteVideo(false)
            AudioManager.shared().autoReRoute()
        }else {
            alertController?.dismiss(animated: true)
            if self.members.count > 2 {
                return
            }
            alertController = UIAlertController.init(title: "Requesting to switch to video call." , message: "", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .default) { [weak self] (action) in
                // Cancel Request
                let isCancelSuccess = CallManager.cancelVideoCallSwitch()
                self?.resetConversionTimer()
                self?.isCallConversionRequestedByMe = false
                FlyLogWriter.sharedInstance.writeText("---------------#CallUI---------------#Cancel Tapped---------------")
                if isCancelSuccess == true {
                    self?.showOneToOneAudioCallUI()
                }
            }
            alertController?.addAction(cancelAction)

            if CallManager.getCallType() == .Video {
                resetConversionTimer()
            }else{
                DispatchQueue.main.async  {  [weak self] in
                    
                    if let topController = UIApplication.shared.keyWindow?.rootViewController {
                        if let presentedViewController = topController.presentedViewController {
                            if let alert = self?.alertController {
                                if !(self?.isCallConversionRequestedByRemote ?? false) && CallManager.getCallType() != .Video {
                                    presentedViewController.present(alert, animated: true, completion: {
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
        }
    }
    
    func showCallConversionConfirmationRequest() {
        self.videoCallRequstTimer = Timer.scheduledTimer(timeInterval: 20, target: self ?? CallUIViewController.self, selector: #selector(self.videoCallRequestTimer), userInfo: nil, repeats: false)
        if self.isCallConversionRequestedByMe && self.isCallConversionRequestedByRemote{
            CallManager.setCallType(callType: .Video)
            self.showHideCallBackgroundProfiles(hide: true)
            CallManager.acceptVideoCallSwitchRequest()
            isVideoMuted = false
            switchAudioToVideoCall()
            isCallConversionRequestedByMe = false
            isCallConversionRequestedByRemote = false
            CallManager.muteVideo(false)
            AudioManager.shared().autoReRoute()
            resetConversionTimer()
            if CallManager.getCallStatus(userId: AppUtils.getMyJid()) != .RECONNECTING{
                AudioManager.shared().stopPlayingTone()
            }
            UIView.performWithoutAnimation {
                self.outgoingCallView.tileCollectionView.reloadData()
            }
        }else {
            alertController?.dismiss(animated: false)
            alertController = UIAlertController.init(title: "Requesting Video Call." , message: "", preferredStyle: .alert)
            let acceptAction = UIAlertAction(title: "Accept", style: .default) { [weak self] (action) in
                if !CallManager.checkIsUserCanceled() && NetworkReachability.shared.isConnected {
                    print("Network isconnected *****")
                    CallManager.setCallType(callType: .Video)
                    self?.showHideCallBackgroundProfiles(hide: true)
                    CallManager.acceptVideoCallSwitchRequest()
                    self?.isVideoMuted = false
                    self?.isCallConversionRequestedByMe = false
                    self?.isCallConversionRequestedByRemote = false
                    self?.switchAudioToVideoCall()
                    CallManager.muteVideo(false)
                    AudioManager.shared().autoReRoute()
                    self?.outgoingCallView?.tileCollectionView.reloadData()
                    self?.resetConversionTimer()
                }
                else
                {
                    self?.isCallConversionRequestedByMe = false
                    self?.isCallConversionRequestedByRemote = false
                }
            }
            
            let cancelAction = UIAlertAction(title: "Decline", style: .default) { [weak self] (action) in
                self?.alertController?.dismiss(animated: true, completion: nil)
                CallManager.setCallType(callType: .Audio)
                self?.getUserJid = AppUtils.getMyJid()
                // Cancel Request
                CallManager.declineVideoCallSwitchRequest()
                self?.isCallConversionRequestedByMe = false
                self?.showOneToOneAudioCallUI()
                self?.isCallConversionRequestedByRemote = false
                FlyLogWriter.sharedInstance.writeText("---------------#CallUI---------------#Decline Tapped---------------")
                self?.resetConversionTimer()
            }
            alertController?.addAction(acceptAction)
            alertController?.addAction(cancelAction)
            
            if CallManager.getCallType() == .Video {
                resetConversionTimer()
            }else {
                DispatchQueue.main.async {  [weak self] in
                    
                    if let topController = UIApplication.shared.keyWindow?.rootViewController {
                        if let presentedViewController = topController.presentedViewController {
                            if let alert = self?.alertController {
                                if !(self?.isCallConversionRequestedByMe ?? false) && CallManager.getCallType() != .Video {
                                    presentedViewController.present(alert, animated: true, completion: nil)
                                }else{
                                    self?.resetConversionTimer()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
                                                                                 
    
    @objc func videoCallConversionTimer() {
        print("#CallUII ====> #videoCallConversionTimer")
        print("**** Send switch call request ****** Timer elapsed \(NSDate())")
        alertController?.dismiss(animated: true, completion: nil)
        AudioManager.shared().stopPlayingTone()
        if CallManager.getCallType() != .Video {
            CallManager.setCallType(callType: .Audio)
            getUserJid = AppUtils.getMyJid()
            isCallConversionRequestedByMe = false
            isCallConversionRequestedByRemote = false
            showOneToOneAudioCallUI()
            CallManager.cancelVideoCallSwitch()
        }
    }
    
    @objc func videoCallRequestTimer() {
        print("#CallUII ====> #videoCallConversionTimer")
        print("**** Send switch call request ****** Timer elapsed \(NSDate())")
        alertController?.dismiss(animated: true, completion: nil)
        AudioManager.shared().stopPlayingTone()
        if CallManager.getCallType() != .Video {
            CallManager.setCallType(callType: .Audio)
            getUserJid = AppUtils.getMyJid()
            isCallConversionRequestedByMe = false
            isCallConversionRequestedByRemote = false
            showOneToOneAudioCallUI()
            CallManager.declineVideoCallSwitchRequest()
        }
    }
    
    func resetConversionTimer(){
        FlyLogWriter.sharedInstance.writeText("---------------#CallUI---------------#resetConversionTimer---------------")
        videoCallRequstTimer?.invalidate()
        videoCallRequstTimer = nil
        VideoCallConversionTimer?.invalidate()
        VideoCallConversionTimer = nil
        alertController?.dismiss(animated: true, completion: nil)
        isCallConversionRequestedByRemote = false
    }
    
    func switchAudioToVideoCall() {
        CallManager.setCallType(callType: .Video)
        switchLoaclandRemoteViews()
        showOneToOneVideoCallUI()
        showConnectedVideoCallOneToOneUI()
        setVideoBtnIcon()
        resetConversionTimer()
        AudioManager.shared().stopPlayingTone()
    }
}

// MARK: PIP Mode & Actions
extension CallUIViewController {
    
    func showCallOverlay() {
        showHideMenu = true
        removePopupView()
        
        CallUIViewController.sharedInstance = self
        
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
        } else {
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
    
    func updatePipProfileImage(){
        if overlayShown{
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
        }
    }
    
    @objc func callViewTapGestureAction(_ tapGesture: UITapGestureRecognizer?) {

        overlayShown = false
        ContactManager.shared.profileDelegate = self
        callViewOverlay.removeFromSuperview()
        getContactNames()
        print("#Reload ====> #callViewTapGestureAction")
        outgoingCallView?.tileCollectionView.reloadWithoutAnimation()
        
        let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if let rootVC = window?.rootViewController {
            let navigationStack = UINavigationController(rootViewController: self)
            navigationStack.setNavigationBarHidden(true, animated: true)
            navigationStack.modalPresentationStyle = .fullScreen
            rootVC.present(navigationStack, animated: true, completion: nil)
        }
    }
    
}

// MARK: Call Disconnection & Call Again UI Updates
extension CallUIViewController {
    
    func clearViews() {
        print("#CallUII ====> #clearViews")
        showHideParticipantButton(hide : true)
        showHideMenuButton(hide: true)
        showHideDuration(hide: true)
        outgoingCallView?.audioMuteStackView.isHidden = true
        print("#mute clearViews \(isAudioMuted) video \(isVideoMuted) ")
        updateActionsUI()
    }
    
    
    func showHideCallAgainView(show: Bool,status: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.outgoingCallView != nil{
                self.outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = status.isEmpty
                self.updateOutgoingViewCallStatus(status: CallManager.isCallConnected() ? CallStatus.connected.rawValue : status )
                if show {
                    if self.overlayShown {
                        self.callViewOverlay.removeFromSuperview()
                    }
                    if !self.members.isEmpty{
                        self.callAgainMembers = members
                    }
                    
                    self.removeAllMembers()
                    
                    self.showOrHideAudioWaveView(hide: true)
                    self.outgoingCallView?.AttendingBottomView.isHidden = true
                    self.outgoingCallView?.callAgainView.isHidden = false
                    self.showHideParticipantButton(hide:  true)
                    self.showHideMenuButton(hide: true)
                    
                    if self.callType == .Audio {
                        self.outgoingCallView?.CallAgainButton.setImage(UIImage(named: "callAgain"), for: .normal)
                    }else{
                        self.outgoingCallView?.CallAgainButton.setImage(UIImage(named: "call again_ic"), for: .normal)
                    }
                    self.outgoingCallView?.callAgainView.backgroundColor = UIColor(hexString: "151F32")
                    self.outgoingCallView?.backBtn.isHidden = true
                    if self.overlayShown {
                        self.dismiss()
                        self.overlayShown = false
                    }
                } else {
                    self.outgoingCallView?.callAgainView.isHidden = true
                    self.outgoingCallView?.AttendingBottomView.isHidden = false
                    if status == "Connecting" {
                        if CallManager.isOneToOneCall() {
                            self.outgoingCallView?.stackView.isHidden = true
                        } else {
                            self.outgoingCallView?.stackView.isHidden = false
                        }
                    } else {
                        self.outgoingCallView?.stackView.isHidden = false
                    }
                    self.outgoingCallView?.backBtn.isHidden = false
                }
            }
        }
    }
    
    func dismiss() {
        print("#lifecycle dismiss")
        
    }
    
    func resetVariables(){
        print("#CallUII ====> #resetVariables")
        callDurationTimer?.invalidate()
        isOnCall = false
        isLocalViewSwitched = false
        reloadForInVite = false
        isBackCamera = false
        isVideoMuted = false
        isAudioMuted = false
        seconds = -1
      //  groupId = ""
        showGridView = false
        isVideoMuted = true
        isCallConversionRequestedByMe = false
        isCallConversionRequestedByRemote = false
        myCallStatus = .calling
        fullScreenUser = CallMember()
        speakingDictionary.removeAll()
        callAgainMembers.removeAll()
        members.removeAll()
        qualityTimer?.invalidate()
        qualityTimer = nil
        qualityToastShown = false
        outgoingCallView?.tileCollectionView.delegate = nil
        outgoingCallView?.tileCollectionView.dataSource = nil
    }
    
    func dismissCallUI(){
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            FlyLogWriter.sharedInstance.writeText("#flow #UI dismissCallUI  \(CallManager.getAllCallUsersList().count)")
            if CallManager.getCallMode() == .MEET {
                for controller in (self.navigationController?.viewControllers ?? []) as Array {
                    if controller.isKind(of: ChatViewParentController.self) {
                        self.navigationController!.popToViewController(controller, animated: true)
                        break
                    }
                }
            }
            UserDefaults.standard.removeObject(forKey: "seconds")
            self.groupId = ""
            self.seconds = -1
            self.myCallStatus = .calling
            self.outgoingCallView?.reconnectingLable?.text = emptyString()
            self.outgoingCallView?.timerLable.isHidden = true
            self.outgoingCallView?.timerLable.text = ""
            self.outgoingCallView?.OutGoingPersonLabel.text = ""
            self.showHideDuration(hide: true)
            self.currentCallStatus = .CALLING
            self.outgoingCallView?.qualityView?.isHidden = true
            self.outgoingCallView?.qualityIcon?.isHidden = true
            self.outgoingCallView?.AttendingBottomView.isHidden = true
            CallUIViewController.isQualityToastShowing = false
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            if let navigationController = window?.rootViewController as? UINavigationController,let _ = navigationController.presentedViewController {
                print("#dismissCallUI dismissed root")
                window?.rootViewController?.dismiss(animated: true)
            }else{
                print("#dismissCallUI dismissed")
                self.dismiss(animated: true, completion: nil)
            }
            if self.dismissCalled == false {
                CallUIViewController.dismissDelegate?.onCallControllerDismissed()
            }
            self.dismissCalled = true
            UIApplication.shared.isIdleTimerDisabled = false
            self.outgoingCallView?.tileCollectionView.delegate = nil
            self.outgoingCallView?.tileCollectionView.dataSource = nil
        }
    }
    
    func dismissWithDelay(callStatus : String = "Disconnected", withoutDelay : Bool? = false){
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.resetVariables()
            self.enableDisableUserInteractionFor(view: outgoingCallView?.AttendingBottomView, isDisable: true)
            CallManager.incomingUserJidArr.removeAll()
            AudioManager.shared().audioManagerDelegate = nil
            self.callDurationTimer = nil
            self.VideoCallConversionTimer = nil
            self.videoCallRequstTimer = nil
            self.alertController = nil
           
            self.outgoingCallView?.OutGoingPersonLabel?.isHidden = false
            self.outgoingCallView?.OutGoingPersonLabel?.text = callStatus
            UserDefaults.standard.removeObject(forKey: "seconds")
            self.showHideParticipantButton(hide : true)
            self.showHideMenuButton(hide: true)
            self.outgoingCallView?.audioMuteStackView.isHidden = true
            self.outgoingCallView?.callAgainView.isHidden = true
            self.outgoingCallView?.backBtn.isHidden = true
            self.outgoingCallView?.reconnectingLable?.isHidden = true
            self.remoteRenderer.removeFromSuperview()
            self.callViewOverlay.removeFromSuperview()
            self.outgoingCallView?.remoteUserVideoView.willRemoveSubview(remoteRenderer)
            self.removePopupView()
            self.resetLocalVideCallUI()
            self.removeRemoteOneToOneLocalTracks()
            for view in self.outgoingCallView?.remoteUserVideoView?.subviews ?? [] {
                view.removeFromSuperview()
            }
            self.audioDevicesAlertController?.dismiss(animated: true, completion: {
                self.audioDevicesAlertController = nil
            })
            self.alertController?.dismiss(animated: true, completion: nil)
            if ((self.audioPlayer) != nil) {
                if ((self.audioPlayer?.isPlaying) != nil) {
                    self.audioPlayer?.stop()
                }
                self.audioPlayer?.stop()
                self.audioPlayer = nil
            }
            self.isTapped = false
           let top = CGAffineTransform(translationX: 0, y: showGridView ? 0 : -20)
                UIView.animate(withDuration: 0.1, delay: 0.0, options: [], animations: {
                    self.outgoingCallView?.AttendingBottomView.transform = top
                    self.outgoingCallView?.tileCollectionView.transform = top
                    
                }, completion: { finished in
                    self.outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = true
                })
            self.showHideQualityView(show: false)
        }
    }
}

// MARK: Collection View Delegate & DataSource

extension CallUIViewController : UICollectionViewDelegate , UICollectionViewDataSource , UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if members.count > 0 {
            if (members.count == 8) || CallManager.getCallMode() == .MEET {
                showHideParticipantButton(hide :true)
            }
            return members.count
        }else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let tileCell = collectionView.dequeueReusableCell(withReuseIdentifier: "TileCell", for: indexPath) as? TileCell else {
            print("Fatal error Collection view cell occured.")
            return UICollectionViewCell()
        }
        if members.count > 0 && members.count > indexPath.item {
            
            var member = members[indexPath.item]
            
            if CallManager.isOneToOneCall() && !showGridView {
                if isLocalViewSwitched{
                    member = members.first ?? CallMember()
                }else {
                    member = members.last ?? CallMember()
                }
            }else if (CallManager.getCallMode() == .MEET) {
                
                if (members.count == 1 || members.count == 2)   {
                    if !showGridView{
                        if let index = findIndexOfUser(jid: AppUtils.getMyJid()) {
                            member = members[index]
                        }
                    }else {
                        member = members[indexPath.item]
                    }
                }else {
                    member = members[indexPath.item]
                }
            }else{
                member = members[indexPath.item]
            }
            let isLastRow = (CallManager.getCallMode() == .MEET && (members.count == 1 || members.count == 2) && !showGridView) ? true : (CallManager.isOneToOneCall() && !showGridView) ? true : (indexPath.item == members.count - 1)
            
            let callStatus =  isLastRow ? (CallManager.getCallStatus(userId: member.jid) == .ON_HOLD  ? .onHold : .connected) : convertCallStatus(status: CallManager.getCallStatus(userId: member.jid))
            if member.jid == AppUtils.getMyJid() && CallManager.getCallStatus(userId: member.jid) == .ON_HOLD{
                _ = updateCallStatus(jid: member.jid, status: .onHold)
            }
            tileCell.setupDataForTileCell(tileCell: tileCell, indexPath: indexPath, members: members, member: member, isBackCamera: isBackCamera, showGridView: showGridView, callStatus: callStatus)
            let ishide = members.count > 2 ? false : shouldHideProfile
            tileCell.setImageHidden(ishide)
            return tileCell
        }else{
            return tileCell
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if showGridView {
            
            let width = self.view.frame.size.width
            let height = self.view.frame.size.height
            switch members.count {
            case 1:
                return CGSize(width: (width), height: (height))
            case 2:
                return CGSize(width: (width - 30), height: (height / 2) - 75)
            case 3,4,5,6,7,8:
                return CGSize(width: ((width) / 2 - 15), height: (200))
            default:
                print("more than 8 person")
                return CGSize(width: (width), height: (height))
            }
            
        }else {
            
            if members.count > indexPath.item {
                
                let callMember = members[indexPath.item]
                
                if (CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && members.count == 2) || (CallManager.getCallMode() == .MEET && members.count == 1)){
                    if members.count == 1 {
                        return CGSize(width: 0, height: 0)
                    }else {
                        return CGSize(width: 110, height: 160)
                    }
                }else {
                    
                    let firstMember = members.first(where: {$0.callStatus == .connected})
                    let index = findIndexOfUser(jid: firstMember?.jid ?? "")
                    
                    if (callMember.jid == fullScreenUser.jid) {
                        return CGSize(width: 0, height: 0)
                    } else {
                        return CGSize(width: 110, height: 160)
                    }
                }
            }
        }
        
        return CGSize(width: 110, height: 160)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        return showGridView ? CGSize(width: collectionView.frame.size.width, height: 100) : CGSize(width: 0, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        
        return showGridView ? CGSize(width: collectionView.frame.size.width, height: 50) : CGSize(width: 0, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return showGridView ? UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10) : UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        showHideMenu = true
        removePopupView()
    }
}

// MARK: Audio/Video mute & Camera switch for current user

extension CallUIViewController : CallViewControllerDelegate {
    
    func onVideoMute(status:Bool) {
        print("#CallUII ====> #onVideoMute")
        if CallManager.isOneToOneCall() || members.count == 2 {
            if status == true {
                shouldHideProfile = false
            }else{
                shouldHideProfile = true
            }
        }
        if CallManager.isCallOnHold(){
            return
        }
        print("#mute status \(status)")
        CallManager.muteVideo(status)
        members.last?.isVideoMuted = status
        
        if status && CallManager.isOneToOneCall() && myCallStatus != .reconnecting {
            if isLocalViewSwitched {
                addRemoteTrackToView()
            } else {
                if let cell = self.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: 0, section: 0)) as? TileCell{
                    cell.profileImageView.isHidden = true
                }
            }
            isLocalViewSwitched = false
        }

        if !isLocalViewSwitched {
            //if let localView = outgoingCallView?.localUserVideoView {
                addSwitchedRemoteTrackToView(localView: UIView(), isLocal: true)
            //}
        } else {
            if let localView = outgoingCallView?.remoteUserVideoView {
                addSwitchedRemoteTrackToView(localView: localView, isLocal: false)
            }
        }

        if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (members.count == 2 || members.count == 1)) {
            setVideoBtnIcon()
            outgoingCallView?.cameraButton.isHidden = isVideoMuted
            setMuteStatusText()
            
            if status {
                if let cell = self.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: 0, section: 0)) as? TileCell{
                    cell.profileImageView.isHidden = false
                }
                outgoingCallView?.tileCollectionView.removeGestureRecognizer(videoTapGesture)
            }else{
                
                if !(members.last?.isVideoMuted ?? false) && !(members.first?.isVideoMuted ?? false) {
                    
                    videoTapGesture = UITapGestureRecognizer(target: self, action: #selector(smallVideoTileTapped(_:)))
                    outgoingCallView?.tileCollectionView?.addGestureRecognizer(videoTapGesture)
                }
            }
            outgoingCallView?.tileCollectionView.reloadWithoutAnimation()
        } else {
            setVideoBtnIcon()
            outgoingCallView?.cameraButton.isHidden = isVideoMuted
        
            if !isVideoMuted {
                if (CallManager.getCallMode() == .MEET && members.count == 1){
                    if let track = members.first?.videoTrack {
                        self.addlocalTrackToView(videoTrack: track)
                        self.showHideCallBackgroundProfiles(hide: true)
                    }
                }else{
                    addGroupTracks(jid: AppUtils.getMyJid())
                }
            } else {
                if (CallManager.getCallMode() == .MEET && members.count == 1){
                    removeRemoteOneToOneLocalTracks()
                    showHideCallBackgroundProfiles(hide: showGridView ? true : false)
                    if let isAudioMute = members.first?.isAudioMuted {
                        showOrHideAudioWaveView(hide: isAudioMute)
                    }
                } else {
                    if let index = findIndexOfUser(jid: AppUtils.getMyJid()) {
                        updateVideoMuteStatus(index: index, userid: AppUtils.getMyJid(), isMute: status)
                    }
                }
            }
            AudioManager.shared().autoReRoute()
            
            if isVideoMuted == true {
                outgoingCallView?.speakerButton.isHidden = false
                outgoingCallView?.speakerButton.setImage(UIImage(named: "IconSpeakerOn" ), for: .normal)
            }
        }
    }
    
    func onAudioMute(status:Bool) {
        print("#CallUII ====> #onAudioMute")
        outgoingCallView?.audioButton.setImage(UIImage(named: isAudioMuted ? "IconAudioOn" :  "IconAudioOff" ), for: .normal)
        CallManager.muteAudio(status)
        members.last?.isAudioMuted = status
        if !isLocalViewSwitched{
            updateSpeakingUI(userId: AppUtils.getMyJid(), isSpeaking: !status)
        }else{
            self.outgoingCallView?.audioMutedIcon.isHidden = !status
            self.outgoingCallView?.audioMuteStackView.isHidden = !status
        }
    }
    
    func setActionIconsAfterMaximize() {
        print("#CallUII ====> #setActionIconsAfterMaximize")
        isAudioMuted = CallManager.isAudioMuted()
        isBackCamera = members.last?.isOnBackCamera ?? false
        isVideoMuted = CallManager.isVideoMuted()
    }
    
    func onSwitchCamera(completion: @escaping () -> Void) {
        print("#CallUII ====> #onSwitchCamera")
        CallManager.switchCamera(completion: completion)
        outgoingCallView?.cameraButton.setImage(UIImage(named: isBackCamera ? "IconCameraOn" :  "IconCameraOff" ), for: .normal)
    }
}


// MARK: Make Audio/Video call from call again view

extension CallUIViewController {
    
    func makeCall(usersList : [String], callType: CallType, groupId : String = "", onCompletion: @escaping (_ isSuccess: Bool, _ message: String) -> Void) {
        if let contact = ChatManager.profileDetaisFor(jid: AppUtils.getMyJid()) {
            FlyLogWriter.sharedInstance.writeText("#flow  #makeCall #callUI #myJid ==> \(AppUtils.getMyJid()) #myPhoneNumber ==> \(contact.mobileNumber) #myName ==> \(contact.name) #myNickname ==> \(contact.nickName)")
        }
        remoteHangUpUserList.removeAll()
        if members.count > 0 {
            members.removeAll()
        }
        FlyLogWriter.sharedInstance.writeText("#flow #CallUI #makeCall Users ====> \(usersList)")
        CallManager.setMyInfo(name: ContactManager.getMyProfile().name, imageUrl: ContactManager.getMyProfile().image)
        self.groupId = groupId
        AudioManager.shared().audioManagerDelegate = self
        print("#lifecycle makeCall")
        if usersList.isEmpty{
            print("Cannot make call without a callee")
            return
        }
        self.callType = callType
        addMyInfoToMembersArray(videoTrack: nil)
        for userJid in usersList where userJid != AppUtils.getMyJid() {
            let _ = addRemoteMembers(for: ChatManager.getContact(jid: userJid.lowercased())!)
        }
        var membersJid = members.compactMap { $0.jid }
        
        executeOnMainThread { [weak self] in
            self?.outgoingCallView?.tileCollectionView.reloadWithoutAnimation()
        }
        
        showHideCallAgainView(show: false, status: "Trying to connect")
        if callType == .Audio {
            if members.count == 2 && groupId.isEmpty{
                try! CallManager.makeVoiceCall(members.first!.jid) { [weak self] (isSuccess , message)  in
                    if isSuccess == false {
                        let errorMessage = message?.description ?? emptyString()
                        AppAlert.shared.showAlert(view: self!, title: "", message: errorMessage, buttonTitle: "Okay")
                        FlyLogWriter.sharedInstance.writeText("#makeCall Audio #########=========> \(errorMessage)")
                        if errorMessage.contains("100507"){
                            self?.dismissWithDelay()
                            self?.dismissCallUI()
                        }else{
                            onCompletion(isSuccess,errorMessage)
                            self?.removeAllMembers()
                        }
                    }
                }
            } else {
                for (index, jid) in membersJid.enumerated() {
                    if jid == AppUtils.getMyJid() {
                        membersJid.remove(at: index)
                    }
                }
//                membersJid.remove(at: members.count - 1)
                try! CallManager.makeGroupVoiceCall(membersJid, groupID: groupId) {[weak self] isSuccess , message in
                    if isSuccess == false {
                        let errorMessage = message?.description ?? emptyString()
                        AppAlert.shared.showAlert(view: self!, title: "", message: errorMessage, buttonTitle: "Okay")
                        FlyLogWriter.sharedInstance.writeText("#makeCall group Audio #########=========> \(errorMessage)")
                        if errorMessage.contains("100507"){
                            self?.dismissWithDelay()
                            self?.dismissCallUI()
                        }else{
                            onCompletion(isSuccess,errorMessage)
                            self?.removeAllMembers()
                        }
                    }
                }
            }
        } else {
            isVideoMuted = false
            if members.count == 2  && groupId.isEmpty {
                try! CallManager.makeVideoCall(members.first!.jid)  { [weak self]isSuccess, message in
                    if isSuccess == false {
                        let errorMessage = message?.description ?? emptyString()
                        AppAlert.shared.showAlert(view: self!, title: "", message: errorMessage, buttonTitle: "Okay")
                        FlyLogWriter.sharedInstance.writeText("#makeCall Video #########=========> \(errorMessage)")
                        if errorMessage.contains("100507"){
                            self?.dismissWithDelay()
                            self?.dismissCallUI()
                        }else{
                            onCompletion(isSuccess,errorMessage)
                            self?.removeAllMembers()
                        }
                    }
                }
            } else {
                for (index, jid) in membersJid.enumerated() {
                    if jid == AppUtils.getMyJid() {
                        membersJid.remove(at: index)
                    }
                }
//                membersJid.remove(at: members.count - 1)
                try! CallManager.makeGroupVideoCall(membersJid, groupID: groupId) { [weak self] (isSuccess, message) in
                    if isSuccess == false {
                        let errorMessage = message?.description ?? emptyString()
                        AppAlert.shared.showAlert(view: self!, title: "", message: errorMessage, buttonTitle: "Okay")
                        FlyLogWriter.sharedInstance.writeText("#makeCall group Video #########=========> \(errorMessage)")
                        if errorMessage.contains("100507"){
                            self?.dismissWithDelay()
                            self?.dismissCallUI()
                        }else{
                            onCompletion(isSuccess,errorMessage)
                            self?.removeAllMembers()
                        }
                    }
                }
            }
            if outgoingCallView != nil {
                updateUI()
            }
        }
    }
}

// MARK: Call Manager Delegate Methods

extension CallUIViewController : CallManagerDelegate {
   
    func onRemoteVideoTrackAdded(userId: String, track: RTCVideoTrack) {
        DispatchQueue.main.async {
            print("#reloadCell #onRemoteVideoTrackAdded: userId: \(userId)")
            FlyLogWriter.sharedInstance.writeText("#callflow CallUI onRemoteVideoTrackAdded userId \(userId)")
            let index = self.findIndexOfUser(jid: userId) ?? 0
            
            self.updateMuteStatusOfUser(userId: userId)
            let indxPath = IndexPath(item: index, section: 0)
            
            if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (self.members.count == 1 || self.members.count == 2))  {
                if !self.isLocalViewSwitched {
                    if self.members.first?.jid == userId{
                        self.members.first?.videoTrack = track
                    }
                    self.addRemoteTrackToView()
                }else{
                    self.oneToOneVideoViewTransforms()
                    self.switchLoaclandRemoteViews()
                    let  member = self.members[indxPath.item]
                    member.videoTrack = track
                    self.setVideoBtnIcon()
                    self.addGroupTracks(jid: userId)
                    if self.members.count == self.outgoingCallView?.tileCollectionView.numberOfItems(inSection: 0) ?? 0 {
                        if self.members.count > 1 {
                            self.outgoingCallView?.tileCollectionView.performBatchUpdates({
                                self.outgoingCallView?.tileCollectionView.reloadItems(at: [IndexPath(item: 1, section: 0)])
                            }, completion: nil)
                        }
                    }
                }
            }else {
                if self.members.count > 0 {
                    if !(self.showGridView ) && (CallManager.isOneToOneCall() || self.members.count == 2) {
                        self.outgoingCallView?.remoteUserVideoView.isHidden = false
                    }else{
                        self.outgoingCallView?.remoteUserVideoView.isHidden = true
                    }
                    
                    let  member = self.members[indxPath.item]
                    member.videoTrack = track
                    
                    if let totItem = self.outgoingCallView?.tileCollectionView.numberOfItems(inSection: 0) {
                        FlyLogWriter.sharedInstance.writeText("#Callflow #onRemoteVideoTrackAdded MembersCount \(self.members.count ) totItem: \(totItem) userId: \(userId)")
                        self.setVideoBtnIcon()
                        self.addRemoteTrackToView()
                        self.addGroupTracks(jid: userId)
                    }
                }
            }
        }
    }
    
    func onLocalVideoTrackAdded(userId: String, videoTrack: RTCVideoTrack) {
        updateMuteStatusOfUser(userId: userId)
        FlyLogWriter.sharedInstance.writeText("#callflow UI onLocalVideoTrackAdded userId \(userId)")
        if CallManager.isOneToOneCall()  {
            //outgoingCallView?.contentView.backgroundColor = .clear
            addMyInfoToMembersArray(videoTrack: videoTrack)
            self.members.last?.videoTrack = videoTrack
            if !isOnCall {
                executeOnMainThread {
                    autoreleasepool {
                        self.addlocalTrackToView(videoTrack: videoTrack)
                        self.outgoingCallView?.OutGoingCallBG.image = nil
                        self.outgoingCallView?.OutGoingCallBG.isHidden = true
                    }
                }
            }
        } else {
            if !CallManager.isCallConnected() ||  CallManager.getCallMode() == .MEET{
                addMyInfoToMembersArray(videoTrack: videoTrack)
                executeOnMainThread {
                    autoreleasepool {
                        if CallManager.getCallMode() == .MEET{
                            self.addGroupTracks(jid: userId)
                            self.addlocalTrackToView(videoTrack: videoTrack)
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
        print("#CallUII ====> #addlocalTrackToView")
        if videoTrack.isEnabled {
            if let localView = self.outgoingCallView?.remoteUserVideoView {
#if arch(arm64)
                let localRen = RTCMTLVideoView(frame: .zero)
#else
                let localRen = RTCEAGLVideoView(frame: .zero)
#endif
                localRen.frame = CGRect(x: 0, y: 0, width: localView.bounds.width, height: localView.bounds.height)
                localView.addSubview(localRen)
                videoTrack.add(localRen)
            }
            self.outgoingCallView?.remoteUserVideoView.isHidden = false
        }
    }
    
    func addRemoteTrackToView() {
        print("#CallUII ====> #addRemoteTrackToView")
        DispatchQueue.main.async {
            guard self.members.count > 1 else { return }
            var userJID = self.members[self.members.count - 2].jid
            guard userJID != AppUtils.getMyJid() else { return }
            if (self.members[self.members.count - 2].callStatus != .connected) {
                
                let firstMember = self.members.first(where: {$0.callStatus == .connected})
                userJID = firstMember?.jid
            }
            
            if let remoteView = self.outgoingCallView?.remoteUserVideoView, let jid = CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (self.members.count == 1 || self.members.count == 2)) ? self.members.first?.jid : userJID, let videoTrack = CallManager.getRemoteVideoTrack(jid: jid) {
                
//                for view in self.outgoingCallView?.remoteUserVideoView?.subviews ?? [] {
//                    view.removeFromSuperview()
//                }
//
                videoTrack.remove(self.remoteRenderer)
              //  self.remoteRenderer.removeFromSuperview()
//                remoteView.willRemoveSubview(self.remoteRenderer)
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
                
                if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (self.members.count == 1 || self.members.count == 2)) {
                    self.members.first?.videoTrack = videoTrack
                }else {
                    if self.members.count > 2 {
                        self.members[self.members.count - 2].videoTrack = videoTrack
                        self.fullScreenUser = self.members[self.members.count - 2]
                    }
                }
                
                if self.members.count == 2 && CallManager.isRemoteVideoMuted(self.members.first?.jid ?? "") {
                    self.showHideCallBackgroundProfiles(hide: self.showGridView ? true : false)
                } else {
                    if self.members.count == 2 && CallManager.getCallType() == .Audio {
                        self.showHideCallBackgroundProfiles(hide: false)
                    } else {
                        if self.showGridView || (self.members.count == 2 && self.members.first?.isVideoMuted == false && self.isLocalViewSwitched == false) || CallManager.getCallType() == .Video {
                            self.showHideCallBackgroundProfiles(hide: true)
                        }
                    }
                }
                if self.members.count == 2 && self.members.first?.isVideoMuted == false && self.isLocalViewSwitched == false {
                    self.members.first?.videoTrack = videoTrack
                    self.showHideCallBackgroundProfiles(hide: true)
                }
                self.setMuteStatusText()
                self.validateReconnectingStatus()
            }
        }
    }
    
    func addMyInfoToMembersArray(videoTrack: RTCVideoTrack?) {
        print("#CallUII ====> #addMyInfoToMembersArray")
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
        
        if videoTrack != nil {
            callMember.videoTrack = videoTrack
        }
        
        if let index = findIndexOfUser(jid: AppUtils.getMyJid()) {
            if videoTrack != nil {
                members[index].videoTrack = videoTrack
            }
        } else {
            isVideoMuted = callMember.isVideoMuted
            members.append(callMember)
        }
    }
    
    func addRemoteMembers(for user : ProfileDetails, with status: CallStatus = .calling) -> Int  {
        print("##CallUIIICheckk addRemoteMembers  \(user.jid) \(user.name) \(user.nickName) \(user.colorCode)")
        
        resetConversionTimer()
        
        var remoteUserProfile : ProfileDetails? = nil
        if let pd = ChatManager.getContact(jid: user.jid.lowercased()) {
            remoteUserProfile = pd
        }else{
            remoteUserProfile = ContactManager.shared.saveTempContact(userId: user.jid)
        }
        let callMember = CallMember()
        callMember.jid = user.jid
        callMember.callStatus = status
        let userId = user.jid.components(separatedBy: "@").first!
        callMember.name = getUserName(jid: remoteUserProfile?.jid ?? "",name: remoteUserProfile?.name ?? userId, nickName: remoteUserProfile?.nickName ?? userId,contactType: remoteUserProfile?.contactType ?? .unknown)
        callMember.image = remoteUserProfile?.image ?? user.image
        callMember.color = remoteUserProfile?.colorCode ?? "#00008B"
      
        callMember.isVideoMuted = CallManager.getMuteStatus(jid: user.jid, isAudioStatus: false) //CallManager.getCallType() == .Audio
        callMember.isVideoTrackAdded = false
        if let index = findIndexOfUser(jid: user.jid){
            return index
        }
        else {
            members.insert(callMember, at:  members.count >= 2 ? (members.count - 2) : 0 ) //0
            //setupTileViewConstraints(isRemoveUser: false)
            return 0
        }
    }
    
    func onVideoTrackAdded(userJid: String) {
        print("#CallUII ====> #onVideoTrackAdded")
    }
    
    func getDisplayName(IncomingUser :[String], incomingUserName: String, metaData: [CallMetadata]) -> [String] {
        print("#CallUII ====> #getDisplayName")
        var userString = [String]()
        if isHideNotificationContent {
            userString.append(APP_NAME)
        }else{
            for JID in IncomingUser where JID != AppUtils.getMyJid() {
                print("#jid \(JID)")
                if CallManager.getGroupID() == JID {
                    print("#getDisplayName getGroupID \(JID)")
                    print("#getDisplayName getGroupID \(CallManager.getGroupID())")
                    if let contact = ChatManager.getContact(jid: JID.lowercased()) {
                        userString.append(getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
                    }
                }else{
                    print("#getDisplayName GETJID \(JID)")
                    if let contact = ChatManager.getContact(jid: JID.lowercased()){
                        if ENABLE_CONTACT_SYNC{
                            if contact.contactType == .unknown{
                                userString.append((try? FlyUtils.getIdFromJid(jid: JID)) ?? "")
                            } else {
                                userString.append(getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
                            }
                        } else {
                            userString.append(getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
                        }
                    }else {
                        let pd = ContactManager.shared.saveTempContact(userId: JID)
                        userString.append(pd?.name ?? "User")
                    }
                }
            }
            print("#names \(userString)")
        }
        return userString
    }
    
    func getGroupName(_ groupId : String) {
        print("#CallUII ====> #getGroupName")
        if !isOnCall {
            self.groupId = groupId
        }
        
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
        print("#CallUII ====> #socketConnectionEstablished")
    }
    
    func isValidIndexPath(_ indexPath: IndexPath, in dataSource: [CallMember]) -> Bool {
        let section = indexPath.section
        let row = indexPath.row
        
        guard section == 0 else {
            return false
        }
        
        guard row >= 0 && row < dataSource.count else {
            return false
        }
        
        return true
    }
    
    func removeVideoViewCell() {
        DispatchQueue.main.async {
            if CallManager.getCallType() == .Audio {
                for (memberJid,_) in CallManager.getCallUsersWithStatus() {
                    if let index = self.findIndexOfUser(jid: memberJid) {
                        if let cell = self.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? TileCell{
                            print("#removeVideoViewCell cell ====> \(memberJid)")
                            if let videoView = cell.videoBaseView {
                                print("#removeVideoViewCell cell videoView ====> \(memberJid)")
                                for view in videoView.subviews {
                                    view.removeFromSuperview()
                                    videoView.willRemoveSubview(view)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func reloadCell(userId: String) {
        if let index =  self.findIndexOfUser(jid: userId) {
            let indxPath = IndexPath(item: index, section: 0)
            if self.members.count > 0 {
                if let totItem = self.outgoingCallView?.tileCollectionView?.numberOfItems(inSection: 0) {
                    if  self.members.count  == totItem {
                        if self.outgoingCallView?.tileCollectionView != nil && indxPath.item <= (self.members.count) - 1  {
                            print("#reloadCell(userId: \(userId) #reloadItems")
                            UIView.performWithoutAnimation {
                                if #available(iOS 16.0, *) {
                                    self.outgoingCallView?.tileCollectionView.reloadSections(IndexSet(integer: 0))
                                }else{
                                    self.outgoingCallView?.tileCollectionView.reloadData()
                                }
                            }
                        }
                    }else {
                        print("#reloadCell(userId: \(userId) #reloadData 2")
                        self.outgoingCallView?.tileCollectionView?.reloadData()
                    }
                }else {
                    print("#reloadCell(userId: \(userId) #reloadData 3")
                    self.outgoingCallView?.tileCollectionView?.reloadData()
                }
            }
        }
    }
    
    private func showOrHideGroupImage() {
        if CallManager.isOneToOneCall() && CallManager.getCallType() == .Audio {
            self.outgoingCallView?.outGoingAudioCallImageView.isHidden = false
            self.showOrHideAudioWaveView(hide: false)
        }
        if !CallManager.isOneToOneCall() && CallManager.getCallMode() != .MEET && CallManager.getCallType() == .Audio && !CallManager.isCallConnected() && groupId.isNotEmpty {
            self.outgoingCallView?.outGoingAudioCallImageView.isHidden = false
        } else if !CallManager.isOneToOneCall() && CallManager.getCallType() == .Video {
            self.outgoingCallView?.outGoingAudioCallImageView.isHidden = true
            self.showOrHideAudioWaveView(hide: true)
        }
    }
    
    func inviteReloadCells(userId: String) {
        if self.itemToInsert.count == 0{
            self.reloadCell(userId: userId)
        }else {
            if let index = self.findIndexOfUser(jid: userId) {
                if self.members.count == self.outgoingCallView?.tileCollectionView.numberOfItems(inSection: 0) ?? 0 {
                    self.outgoingCallView?.tileCollectionView.performBatchUpdates({
                        self.outgoingCallView?.tileCollectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                    }, completion: nil)
                }
            }
        }
    }
    
    func onCallStatusUpdated(callStatus: CALLSTATUS, userId: String) {
        print("#reloadCell #onCallStatusUpdated: \(callStatus.rawValue) userJid : \(userId) memersCount : \(members.count) \(myCallStatus) MyJID: \(AppUtils.getMyJid())")
        checkCameraPermission(sourceType: .camera)
        setButtonsActions()
        
        if myCallStatus == .tryagain{
            if CallManager.getCallDirection() == .Outgoing {
                return
            }
        }
        let filteredUsers = members.filter { $0.jid == userId }
        let filterUserCallstatus = filteredUsers.filter({$0.callStatus == .ringing})
        if filterUserCallstatus.count > 0 {
            if filterUserCallstatus.first?.callStatus.rawValue == callStatus.rawValue {
                return
            }
        }
        addUsers(callStatus: callStatus, userId: userId)
        if callStatus == .ATTENDED || callStatus == .CONNECTED {
            validateAndAddMember(jid: userId, with: self.convertCallStatus(status: callStatus))
        }
        currentCallStatus = callStatus
        updateMuteStatusOfUser(userId: userId)
        let nonVideoMuted = members.filter({$0.isVideoMuted == false})
        if nonVideoMuted.count == 0 {
            removeVideoViewCell()
        }
        if members.count > 2 {
            if alertController != nil {
                if CallManager.getCallStatus(userId: AppUtils.getMyJid()) != .RECONNECTING{
                    AudioManager.shared().stopPlayingTone()
                }
            }
        }
        if CallManager.isOneToOneCall() && CallManager.getCallType() == .Video {
            if self.members.last?.isVideoMuted == true {
                if self.currentOutputDevice == .speaker {
                    self.outgoingCallView?.speakerButton.isHidden = false
                }
            }
        }else{
            if self.currentOutputDevice == .speaker && self.members.last?.isVideoMuted ?? false {
                executeOnMainThread {
                    self.outgoingCallView?.speakerButton.isHidden = false
                }
            }
        }
        
        if self.currentOutputDevice == .headset {
            audioRoutedTo(deviceName: "headset", audioDeviceType: .headset)
        } else if self.currentOutputDevice == .bluetooth {
            audioRoutedTo(deviceName: "bluetooth", audioDeviceType: .bluetooth)
        }
        
        if members.count > 2 {
            DispatchQueue.main.async {
                self.outgoingCallView?.audioCallMutedIcon.isHidden = true
                self.outgoingCallView?.audioMutedIcon.isHidden = true
            }
            if alertController != nil {
                self.resetConversionTimer()
                if CallManager.getCallStatus(userId: AppUtils.getMyJid()) != .RECONNECTING{
                    AudioManager.shared().stopPlayingTone()
                }
            }
        }
        
        executeOnMainThread { [weak self] in
            if callStatus == .RINGING || callStatus == .ATTENDED || callStatus == .CONNECTED || callStatus == .RECONNECTED {
                if self?.members.count ?? 0 > 2 {
                    self?.outgoingCallView?.outGoingAudioCallImageView.isHidden = true
                    self?.outgoingCallView?.audioCallMutedIcon.isHidden = true
                    self?.outgoingCallView?.audioMutedIcon.isHidden = true
                    self?.showOrHideAudioWaveView(hide: true)
                    self?.showGridView = true
                    self?.transformTileAndGridConstraints()
                    self?.outgoingCallView?.reconnectingLable.isHidden = true
                }else{
                    self?.showGridView = false
                    self?.transformTileAndGridConstraints()
                    self?.showOrHideGroupImage()
                }
            }
            if CallManager.getCallType() == .Audio && self?.members.last?.isVideoMuted ?? false == true {
                self?.showHideCallBackgroundProfiles(hide: false)
            }
            switch callStatus {
            case .CALLING:
                if !(self?.isOnCall ?? true) {
                    self?.myCallStatus = .calling
                }
                self?.showOrHideGroupImage()
            case .CONNECTING:
                self?.showHideDuration(hide: true)
                if !(self?.isOnCall ?? true){
                    self?.myCallStatus = .connecting
                }
                self?.showOrHideGroupImage()
                self?.inviteReloadCells(userId: userId)
            case .RINGING:
                self?.alertController?.dismiss(animated: true)
                if !(self?.isOnCall ?? true) {
                    self?.myCallStatus = .ringing
                }
                if !CallManager.isCallConnected() {
                    self?.updateOutgoingViewCallStatus(status:  "Ringing")
                    self?.getContactNames()
                }else{
                    let _ = self?.updateCallStatus(jid: userId, status: .ringing)
                }
                if CallManager.isOneToOneCall() {
                    self?.setupTopViewConstraints()
                }
                self?.showOrHideGroupImage()
                self?.inviteReloadCells(userId: userId)
            case .ATTENDED:
                if self?.members.count ?? 0 > 2 {
                    self?.showGridView = true
                    self?.transformTileAndGridConstraints()
                }else{
                    self?.showGridView = false
                    self?.transformTileAndGridConstraints()
                }
                
                if !(self?.isOnCall ?? true){
                    self?.myCallStatus = .attended
                }
                self?.showHideCallAgainView(show: false, status: "Connecting")
                if self?.outgoingCallView != nil {
                    if let tapGesture = self?.tapGesture {
                        self?.outgoingCallView?.removeGestureRecognizer(tapGesture)
                        self?.outgoingCallView?.addGestureRecognizer(tapGesture)
                    }
                }
                self?.inviteReloadCells(userId: userId)
                if CallManager.getCallDirection() == .Outgoing {
                    AudioManager.shared().stopPlayingTone()
                }
                //                self?.outgoingCallView?.outGoingAudioCallImageView.isHidden = true
            case .CONNECTED:
                self?.outgoingCallView?.stackView.isHidden = false
                self?.itemToInsert.removeAll()
                if userId == AppUtils.getMyJid() {
                    self?.outgoingCallView?.reconnectingLable?.text = ""
                    self?.myCallStatus = .connected
                }
                if !CallManager.isOneToOneCall() && self?.members.count ?? 0 > 2 {
                    self?.showGridView = true
                    self?.transformTileAndGridConstraints()
                }
                self?.updateConnectedUIStatus()
                if !(self?.isOnCall ?? true){
                    self?.myCallStatus = .connected
                }
                if CallManager.getCallType() == .Video {
                    self?.outgoingCallView?.cameraButton.isEnabled = true
                }
                if (CallManager.isOneToOneCall() || CallManager.getCallMode() == .MEET) && self?.members.count == 2 {
                    if CallManager.getCallType() == .Video {
                        self?.showOneToOneVideoCallUI()
                        self?.showConnectedVideoCallOneToOneUI()
                        self?.switchLoaclandRemoteViews()
                        self?.outgoingCallView?.imageHeight.constant = 100
                        if CallManager.getCallMode() != .MEET {
                            self?.showConnectedVideoCallOneToOneUI()
                        }
                        let remoteVideoTrack = CallManager.getRemoteVideoTrack(jid: AppUtils.getMyJid()) != nil
                        let isVideoMuted = CallManager.isRemoteVideoMuted(self?.members.first?.jid ?? "")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self?.showHideCallBackgroundProfiles(hide: self?.showGridView ?? true ? true : (remoteVideoTrack && !isVideoMuted))
                        }
                    }else{
                        self?.showOneToOneAudioCallUI()
                        if let cell = self?.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: 0, section: 0)) as? TileCell{
                            cell.profileImageView.isHidden = false
                            cell.contentVIew.isHidden = false
                            self?.setupTileViewConstraints(isRemoveUser: false)
                        }
                    }
                    self?.reloadCell(userId: userId)
                    self?.validateReconnectingStatus()
                }else{
                    if CallManager.getCallMode() == .MEET && self?.members.count == 1 {
                        if !(self?.isVideoMuted ?? false){
                            if let track = self?.members.first?.videoTrack {
                                self?.addlocalTrackToView(videoTrack: track)
                            }
                        }else{
                            let remoteVideoMuted = (((self?.members.count == 1) ? (self?.members.first?.isVideoMuted ?? false) : (self?.members.count == 2) ? (self?.members.first?.isVideoMuted ?? false) : self?.members[(self?.members.count ?? 0) - 2].isVideoMuted) ?? false)
                            self?.showHideCallBackgroundProfiles(hide: remoteVideoMuted ? false : true)
                        }
                    }else{
                        self?.outgoingCallView?.remoteUserVideoView.isHidden = true
                        if self?.members.count ?? 0 > 2 {
                            if let index = self?.findIndexOfUser(jid: userId) {
                                if self?.members.count ?? 0 == self?.outgoingCallView?.tileCollectionView.numberOfItems(inSection: 0) ?? 0 {
                                    self?.outgoingCallView?.tileCollectionView.performBatchUpdates({
                                        self?.outgoingCallView?.tileCollectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                                    }, completion: nil)
                                }else{
                                    self?.reloadCell(userId: userId)
                                }
                            }
                        }
                        self?.outgoingCallView?.audioMuteStackView.isHidden = true
                        self?.showHideCallBackgroundProfiles(hide: true)
                    }
                }
                self?.outgoingCallView?.tileCollectionView.isHidden = false
                if let ocv = self?.outgoingCallView{
                    ocv.removeGestureRecognizer(self!.tapGesture)
                    ocv.addGestureRecognizer(self!.tapGesture)
                }
                if !(self?.isOnCall ?? true){
                    if CallManager.getCallConnectionQuality() == .poor{
                        self?.didQualityUpdated(quality: .poor)
                    }
                }
                if CallManager.isCallConnected(){
                    self?.isOnCall = true
                    self?.updateCallTimerDuration()
                }
                UIApplication.shared.isIdleTimerDisabled = true
            case .DISCONNECTED:
                self?.itemToInsert.removeAll()
                print("#STA= #callStatus onCallStatus ====  .DISCONNECTED \(userId) ")
                if self?.members.count == 1 {
                    self?.outgoingCallView?.speakerButton.setImage(UIImage(named: "IconSpeakerOff" ), for: .normal)
                }
                if (self?.myCallStatus == .tryagain) { return }
                
                if userId.isEmpty || userId == AppUtils.getMyJid() || CallManager.getAllCallUsersList().count == 0 {
                    DispatchQueue.main.async {
                        FlyLogWriter.sharedInstance.writeText("#flow #UI .DISCONNECTED \(userId)  \(CallManager.getAllCallUsersList().count)")
                        self?.dismissWithDelay()
                        self?.onCallAction(callAction: CallAction.ACTION_LOCAL_HANGUP, userId: AppUtils.getMyJid())
                    }
                }else {
                    if let index = self?.findIndexOfUser(jid: userId) {
                        self?.removeDisConnectedUser(userIndex: index)
                    }
                    
                }
                UserDefaults.standard.removeObject(forKey: "seconds")
                
                self?.validateReconnectingStatus()
                
                
                FlyLogWriter.sharedInstance.writeText("#call UI .DISCONNECTED => \(userId) \(self?.members.count)")
            case .ON_HOLD:
                self?.itemToInsert.removeAll()
                self?.isOnCall = true
                let userId = userId.isEmpty ? AppUtils.getMyJid() : userId
                if let index =  self?.findIndexOfUser(jid: userId) {
                    print("#callStatus onCallStatus ====  .ON_HOLD for \(userId) at \(index)  \(CallManager.isOneToOneCall())  \(String(describing: self?.members.count ?? 0))")
                    self?.members[index].callStatus = .onHold
                }
                _ = self?.updateCallStatus(jid: userId, status: .onHold)
                if CallManager.isOneToOneCall() && (self?.members.count == 2) {
                    self?.updateOutgoingViewCallStatus(status:  CallStatus.onHold.rawValue)
                }else{
                    if userId == self?.fullScreenUser.jid {
                        self?.updateOutgoingViewCallStatus(status:  CallStatus.onHold.rawValue)
                    }else{
                        self?.updateOutgoingViewCallStatus(status:  CallStatus.connected.rawValue)
                    }
                }
                self?.validateReconnectingStatus()
                FlyLogWriter.sharedInstance.writeText("#call UI .ON_HOLD => \(userId) \(self?.members.count)")
            case .ON_RESUME:
                self?.itemToInsert.removeAll()
                if !CallManager.isCallConnected(){
                    return
                }
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
                    self?.updateOutgoingViewCallStatus(status: CallStatus.connected.rawValue)
                    self?.myCallStatus = .connected
                }else{
                    self?.updateOutgoingViewCallStatus(status: CallStatus.connected.rawValue)
                    self?.myCallStatus = .connected
                    if !CallManager.getMuteStatus(jid: userId, isAudioStatus: false) && userId != AppUtils.getMyJid() {
                        print("#callStatusRE ON_RESUME If")
                        self?.onCallAction(callAction: .ACTION_REMOTE_VIDEO_ADDED, userId: userId)
                    }else{
                        print("#callStatusRE ON_RESUME ELSE")
                        self?.reloadCell(userId: userId)                    }
                }
                
                if CallManager.getCallMode() == .MEET && self?.members.count ?? 0 > 2 {
                    print("#Reload ====> #ON_RESUME")
                    self?.outgoingCallView?.tileCollectionView.reloadWithoutAnimation()
                }
                self?.outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = false
                self?.showHideDuration(hide: false)
                // self?.callHoldLabel.removeFromSuperview()
                
                // self?.setHoldText(isShow: false)
                FlyLogWriter.sharedInstance.writeText("#call UI .ON_RESUME => \(userId) \(self?.members.count) videoMute => \(CallManager.getMuteStatus(jid: userId, isAudioStatus: false))")
            case .USER_JOINED:
                self?.itemToInsert.removeAll()
                if CallManager.getCallMode() == .MEET {
                    if (self?.members.count ?? 0) > 1{
                        self?.outgoingCallView?.qualityIcon.isHidden = true
                    }
                    //  self?.reloadCell(userId: userId) // For flicker issue.
                    if let contact = ChatManager.getContact(jid: userId), let self = self,userId.isNotEmpty{
                        AppAlert.shared.showToast(message:"\(self.getNameStringWithGroupName(userNames: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))) joined")
                    }
                }
            case .USER_LEFT:
                self?.itemToInsert.removeAll()
                if let contact = ChatManager.getContact(jid: userId), let self = self,userId.isNotEmpty{
                    if let index = self.findIndexOfUser(jid: userId) {
                        AppAlert.shared.showToast(message:"\(getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType)) left")
                    }
                }
                if let index = self?.findIndexOfUser(jid: userId) {
                    self?.removeDisConnectedUser(userIndex: index)
                }
                self?.getContactNames()
                if CallManager.getCallMode() == .MEET && (self?.members.count ?? 0) == 1 {
                    self?.outgoingCallView?.qualityIcon.isHidden = CallManager.getCallConnectionQuality() != .poor
                }
                if CallManager.getCallConnectedUsersList()?.isEmpty == true {
                    self?.seconds = -1
                    UserDefaults.standard.removeObject(forKey: "seconds")
                    self?.outgoingCallView?.timerLable.text = "00.00"
                    self?.callDurationTimer?.invalidate()
                    self?.callDurationTimer = nil
                    self?.showUIRingStatus()
                }
            case .INVITE_CALL_TIME_OUT:
                print("")
            case .CALL_TIME_OUT:
                self?.itemToInsert.removeAll()
                FlyLogWriter.sharedInstance.writeText("#CallUi--------------- .CALL_TIME_OUT Code executed.")
                if (self?.isOnCall ?? false) || CallManager.isCallConnected() {
                    self?.isOnCall = CallManager.isCallConnected()
                    if userId.isEmpty || userId == AppUtils.getMyJid() {
                        let timedOutUsers = userId.components(separatedBy: ",")
                        if (self?.members.count ?? 0) - timedOutUsers.count > 1 {
                            self?.removeUnavailableUsers(removedUsers: timedOutUsers)
                        } else {
                            if CallManager.getCallMode() != .MEET {
                                executeOnMainThread {
                                    FlyLogWriter.sharedInstance.writeText("#flow #UI .CALL_TIME_OUT \(userId)  \(CallManager.getAllCallUsersList().count)")
                                    self?.dismissWithDelay()
                                    self?.onCallAction(callAction: CallAction.ACTION_LOCAL_HANGUP, userId: AppUtils.getMyJid())
                                }
                            }
                        }
                    } else {
                        self?.removeUnavailableUsers(removedUsers: userId.components(separatedBy: ","))
                    }
                }else{
                    if CallManager.getCallDirection() == .Incoming{
                        executeOnMainThread {
                            self?.dismissWithDelay()
                            self?.dismissCallUI()
                            CallManager.disconnectCall()
                        }
                    }else{
                        self?.myCallStatus = .tryagain
                        self?.audioDevicesAlertController?.dismiss(animated: true)
                        self?.showHideCallAgainView(show: true, status: "Unavailable, Try again later")
                    }
                }
            case .RECONNECTING:
                self?.itemToInsert.removeAll()
                if CallManager.isCallConnected() {
                    self?.showHideParticipantButton(hide:  userId == AppUtils.getMyJid())
                    self?.showHideMenuButton(hide: userId == AppUtils.getMyJid())
                }
                if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (self?.members.count == 1 || self?.members.count == 2)) {
                     self?.alertController?.dismiss(animated: true, completion: nil)
                    if (self?.isOnCall ?? false) && userId ==  AppUtils.getMyJid(){
                        self?.myCallStatus = .reconnecting
                    }
                    if let contact = ChatManager.getContact(jid: userId.lowercased()), userId != AppUtils.getMyJid(){
                        let status = "\(getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType)) Reconnecting"
                        self?.updateOutgoingViewCallStatus(status: status ?? "")
                    }else{
                        self?.updateOutgoingViewCallStatus(status: "\(userId == AppUtils.getMyJid() ? "" : userId) Reconnecting")
                    }
                }
                if self?.members.count ?? 0 > 2 {
                    self?.updateCallStatus(jid: userId, status: .reconnecting)
                }
                self?.validateReconnectingStatus()
                if userId == AppUtils.getMyJid(){
                    self?.showHideQualityView(show: false)
                }
                
            case .RECONNECTED:
                self?.itemToInsert.removeAll()
                if userId == AppUtils.getMyJid() {
                    self?.outgoingCallView?.reconnectingLable?.text = ""
                }
                if !CallManager.isCallConnected(){
                    return
                }
                let index = self?.updateCallStatus(jid: userId, status: .connected)
                if CallManager.isOneToOneCall() && (self?.members.count == 2){
                    if (self?.isOnCall ?? false){
                        self?.myCallStatus =  self?.isCallOnHoldForOneToCall() ?? false ?  CallStatus.onHold : CallStatus.connected
                    }
                }else{
                    self?.myCallStatus = .connected
                }
                
                self?.outgoingCallView?.reconnectingLable?.text = emptyString()
                if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (self?.members.count == 1 || self?.members.count == 2)) {
                    self?.updateActionsUI()
                    if CallManager.getCallType() == .Audio {
                        //self?.showOneToOneAudioCallUI()
                    } else {
                        //self?.showOneToOneVideoCallUI()
                        // self?.addRemoteTrackToView()
                        if self?.members.first?.isVideoMuted ?? false{
                            self?.outgoingCallView?.remoteUserVideoView.isHidden = true
                            self?.showHideCallBackgroundProfiles(hide: self?.showGridView ?? false ? true : false)
                        }
                        self?.setMuteStatusText()
                    }
                    if !(self?.isLocalViewSwitched ?? false){
                        if self?.members.count ?? 0 == self?.outgoingCallView?.tileCollectionView.numberOfItems(inSection: 0) ?? 0 {
                            if let index = self?.findIndexOfUser(jid: userId) {
                                self?.outgoingCallView?.tileCollectionView.performBatchUpdates({
                                    self?.outgoingCallView?.tileCollectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                                }, completion: nil)
                            }
                        }
                    }
                    for i in self?.members ?? [] {
                        if i.callStatus == .onHold {
                            if CallManager.isOneToOneCall() && (self?.members.count == 2) {
                                self?.updateOutgoingViewCallStatus(status:  CallStatus.onHold.rawValue)
                            }else{
                                
                                if userId == self?.fullScreenUser.jid {
                                    self?.updateOutgoingViewCallStatus(status:  CallStatus.onHold.rawValue)
                                }else{
                                    self?.updateOutgoingViewCallStatus(status:  CallStatus.connected.rawValue)
                                }
                            }
                        }
                    }
                }else{
                    // self?.showGroupCallUI()
                    self?.addRemoteTrackToView()
                    let remoteVideoMuted =  self?.members[(self?.members.count ?? 0) - 2].isVideoMuted
                    if !(self?.showGridView ?? false) {
                        self?.outgoingCallView?.remoteUserVideoView.isHidden = remoteVideoMuted ?? false ? true : false
                    }else{
                        self?.outgoingCallView?.remoteUserVideoView.isHidden = true
                    }
                    self?.showHideCallBackgroundProfiles(hide: self?.showGridView ?? false ? true : remoteVideoMuted ?? false ? false : true)
                    self?.setMuteStatusText()
                    //  self?.isBackCamera = false
                    self?.updateActionsUI()
                    if self?.members.count ?? 0 > 2 {
                        self?.reloadCell(userId: userId)
                    }
                }
                self?.setupTileViewConstraints(isRemoveUser: false)
                
                self?.showHideParticipantButton(hide: !CallManager.isCallConnected())
                self?.showHideMenuButton(hide: !CallManager.isCallConnected())
                
                if CallManager.getCallConnectionQuality() == .poor && CallManager.isCallConnected(){
                    self?.didQualityUpdated(quality: .poor)
                }
            case .CALLING_10S:
                print("")
            case .CALLING_AFTER_10S:
                print("Call Status ===> \(callStatus.rawValue)")
                self?.updateOutgoingViewCallStatus(status: callStatus.rawValue)
                
            @unknown default:
                break
            }
        }
        //Added for UI not shown properly for Audio and Video calls in Same time call scenario
        executeOnMainThread { [weak self] in
            if callStatus != .DISCONNECTED {
                self?.setActionIconsAfterMaximize()
            }
        }
    }
    
    func showUIRingStatus() {
        for i in members {
            if i.callStatus == .ringing || i.callStatus == .calling {
                switch i.callStatus {
                case .calling:
                    self.outgoingCallView?.timerLable.text = self.convertCallStatus(status: .CALLING).rawValue
                case .ringing:
                    self.outgoingCallView?.timerLable.text = self.convertCallStatus(status: .RINGING).rawValue
                default:
                    break
                }
            }
        }
    }
    
    @IBAction func addParticipant(sender: UIButton?){
        print("#CallUII ====> #addParticipant")
        if !NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: "Please check your internet connection!")
            return
        }
        
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
        controller.addParicipantDelegate = self
        isFromInvite = true
        if let callLink = CallManager.getCallLink(){
            controller.callLink = callLink
        }
       
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    @IBAction func showPopupMenu(sender: UIButton?){
        print("#CallUII ====> #showPopupMenu")
        if !NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: "Please check your internet connection!")
            return
        }
        
        if (CallManager.getCallMode() == .MEET && members.count == 1) {
            AppAlert.shared.showToast(message: "Option not available for single user")
            return
        }
        
        if showHideMenu {
            popupView()
            showHideMenu = false
        }else{
            removePopupView()
            showHideMenu = true
        }
    }

    func addUsers(callStatus: CALLSTATUS, userId: String) {
        for (memberJid,status) in CallManager.getCallUsersWithStatus() {
            validateAndAddMember(jid: memberJid, with: convertCallStatus(status: status))
        }
    }

    func popupView() {
        print("#CallUII ====> #popupView")
        let popupView = UIControl(frame: CGRect(x: Int(view.frame.size.width) - 170, y: Int(outgoingCallView?.menuButton.frame.maxY ?? 0) + 20, width: 150, height: 50))
        popupView.backgroundColor = .white
        popupView.layer.cornerRadius = 5
        popupView.layer.masksToBounds = true
        popupView.addTarget(self, action: #selector(transformTileToGrid(sender:)), for: .touchUpInside)
        self.view.addSubview(popupView)
       
        
        let iconImageView = UIImageView(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
        iconImageView.image = UIImage(named: "icon_grid_view")
        iconImageView.contentMode = .center
        popupView.addSubview(iconImageView)
        
        let titleLable = UILabel(frame: CGRect(x: iconImageView.frame.maxX + 2, y: 5, width: 100, height: 40))
        titleLable.backgroundColor = .white
        titleLable.font = UIFont(name: "SFUIDisplay-Medium", size: 14)
        titleLable.text = (showGridView) ? "Tile view" : "Grid view"
        popupView.addSubview(titleLable)
        
        menuView = popupView
        
    }
    
    func removePopupView() {
        menuView.removeFromSuperview()
    }
    
    func changeCollectionViewSemanticContent() {
        print("#CallUII ====> #changeCollectionViewSemanticContent")
        executeOnMainThread { [weak self] in
            if let weakSelf = self {
                weakSelf.transformTileAndGridConstraints()
                print("#Reload ====> #changeCollectionViewSemanticContent")
                weakSelf.outgoingCallView?.tileCollectionView.reloadWithoutAnimation()
            }
        }
    }
    
    @objc func transformTileToGrid(sender: UIControl?){
        print("#CallUII ====> #transformTileToGrid")
        removePopupView()
        showHideMenu = true
        showGridView = !showGridView
        
        changeCollectionViewSemanticContent()
        
        if showGridView {
            outgoingCallView?.outGoingAudioCallImageView.isHidden = true
            outgoingCallView?.audioCallMutedIcon.isHidden = true
            showOrHideAudioWaveView(hide: true)
            outgoingCallView?.audioMuteStackView.isHidden = true
            outgoingCallView?.reconnectingLable?.isHidden = true
            
        }else {
            autoreleasepool{
                if CallManager.isOneToOneCall() {
                    if CallManager.getCallType() == .Audio{
                        showOneToOneAudioCallUI()
                        setMuteStatusText()
                    }else {
                        showConnectedVideoCallOneToOneUI()
                        setMuteStatusText()
                        
                        let remoteVideoMuted =  (self.members.first?.isVideoMuted ?? false && isOnCall)
                        outgoingCallView?.outGoingAudioCallImageView.isHidden = remoteVideoMuted ? false : true
                        if !showGridView {
                            outgoingCallView?.remoteUserVideoView.isHidden = remoteVideoMuted ? true : false
                        }else{
                            outgoingCallView?.remoteUserVideoView.isHidden = true
                        }
                        showHideCallBackgroundProfiles(hide: remoteVideoMuted ? false : true)
                    }
                    
                }else{
                    showGroupCallUI()
                    //let remoteVideoMuted = members[members.count - 2].isVideoMuted
                    var remoteVideoMuted = false
                    if CallManager.getCallMode() == .MEET {
                        remoteVideoMuted = (((members.count == 1) ? members.first?.isVideoMuted : (members.count == 2) ? members.first?.isVideoMuted : members[members.count - 2].isVideoMuted) ?? false)
                    }else {
                        remoteVideoMuted = members[members.count - 2].isVideoMuted
                    }
                    outgoingCallView?.outGoingAudioCallImageView.isHidden = remoteVideoMuted ? false : true
                    showOrHideAudioWaveView(hide: remoteVideoMuted ? true : false)
                    if !showGridView {
                        outgoingCallView?.remoteUserVideoView.isHidden = remoteVideoMuted ? true : false
                    }else{
                        outgoingCallView?.remoteUserVideoView.isHidden = true
                    }
                    showHideCallBackgroundProfiles(hide: remoteVideoMuted ? false : true)
                    
                    setMuteStatusText()
                }
                outgoingCallView?.reconnectingLable?.isHidden = false
                validateReconnectingStatus()
                if fullScreenUser.callStatus == .onHold{
                    updateOutgoingViewCallStatus(status: CallStatus.onHold.rawValue)
                }
            }
        }
        autoreleasepool {
            isTapped = false
            let top = CGAffineTransform(translationX: 0, y: showGridView ? 0 : -20)
            self.outgoingCallView?.AttendingBottomView.transform = top
            self.outgoingCallView?.tileCollectionView.transform = top
            
            transformTileAndGridConstraints()
            self.outgoingCallView?.tileCollectionView.reloadWithoutAnimation()
            
            if !CallManager.isOneToOneCall() {
                for member in members {
                    outgoingCallView?.tileCollectionView?.performBatchUpdates {
                        print("#performBatchUpdates ====> #transformTileToGrid")
                        addGroupTracks(jid: member.jid)
                    }
                }
            }
        }
    }
    
    func validateReconnectionStatusForGroupCall(){
        print("#CallUII ====> #validateReconnectionStatusForGroupCall")
        if showGridView{
            outgoingCallView?.reconnectingLable?.text = emptyString()
            return
        }
        let reconnectingMembers = members.filter({$0.callStatus == .reconnecting}).compactMap({$0.jid})
        if !reconnectingMembers.isEmpty{
            outgoingCallView?.reconnectingLable?.isHidden = false
        }
        for (_, element) in members.enumerated().reversed(){
            if reconnectingMembers.contains(element.jid){
                updateReconnectingLabel(reconnectingUserId: element.jid)
                break
            }
        }
    }
    
    func validateReconnectingStatus(){
        print("#CallUII ====> #validateReconnectingStatus")
        if CallManager.getCallDirection() != .Incoming && (!CallManager.isCallConnected() || showGridView){
            outgoingCallView?.reconnectingLable?.text = emptyString()
            return
        }
        
        for member in members{
            if CallManager.getCallStatus(userId: member.jid) == .RECONNECTING{
                if let index = findIndexOfUser(jid: member.jid){
                    members[index].callStatus = .reconnecting
                    updateUsersDetails(index: index, userid: member.jid)
                }
            }
        }
        
        if ( (members.filter({$0.callStatus == .reconnecting}).count > 0) || members.filter({$0.callStatus == .onHold}).count > 0){
            if members.count <= 2  {
                if let firstUser = members.first, let lastUser = members.last {
                    if firstUser.callStatus == .reconnecting || lastUser.callStatus == .reconnecting{
                        if let reconnectingUserId = lastUser.callStatus == .reconnecting ? lastUser.jid : firstUser.jid{
//                            print("#STA= #callStatus onCallStatus ==== \("Reconnecting label hidden ***")")
                            updateReconnectingLabel(reconnectingUserId: reconnectingUserId)
                        }
                    }else if firstUser.callStatus == .onHold || lastUser.callStatus == .onHold{
                        updateOutgoingViewCallStatus(status: CallStatus.onHold.rawValue)
                    }else{
                        updateOutgoingViewCallStatus(status: CallStatus.connected.rawValue)
                    }
                }
            }else{
                validateReconnectionStatusForGroupCall()
            }
        }else{
//            print("#STA= #callStatus onCallStatus ==== \("Reconnecting label hidden else")")
            outgoingCallView?.reconnectingLable?.text = emptyString()
        }
    }

    func updateReconnectingLabel(reconnectingUserId : String){
        print("#CallUII ====> #updateReconnectingLabel")
        if let contact = ChatManager.getContact(jid: reconnectingUserId.lowercased()), reconnectingUserId != AppUtils.getMyJid() {
            let status = "\(getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType)) Reconnecting"
            updateOutgoingViewCallStatus(status: status ?? "")
        }else {
            updateOutgoingViewCallStatus(status: "\(reconnectingUserId == AppUtils.getMyJid() ? "" : reconnectingUserId) Reconnecting")
        }
    }

    func findIndexOfUser(jid : String) -> Int? {
        return members.firstIndex { $0.jid == jid }
    }
    
    func onCallAction(callAction: CallAction, userId: String) {
        print("#reloadCellss #oncallcation \(callAction), \(userId)")
        if callAction == CallAction.ACTION_LOCAL_HANGUP {
            self.itemToInsert.removeAll()
            if CallManager.getCallDirection() == .Outgoing {
                self.dismissWithDelay()
                self.dismissCallUI()
            }else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    self.dismissWithDelay()
                    self.dismissCallUI()
                })
            }
            FlyLogWriter.sharedInstance.writeText("#flow #UI ACTION_LOCAL_HANGUP  \(CallManager.getAllCallUsersList().count)")
        } else if callAction == CallAction.ACTION_REMOTE_VIDEO_ADDED {
            self.itemToInsert.removeAll()
            print("#call onCallAction() ACTION_REMOTE_VIDEO_ADDED : \(userId)")
            FlyLogWriter.sharedInstance.writeText("#call UI onCallAction  CallAction.ACTION_REMOTE_VIDEO_ADDED \(userId) \(members.count)")
            if CallManager.isOneToOneCall(){
                members.first?.isVideoMuted = false
                setMuteStatusText()
            }else {
                FlyLogWriter.sharedInstance.writeText("#call UI onCallAction  CallAction.ACTION_REMOTE_VIDEO_ADDED  \(userId) at index \(index)")
            }
        } else if callAction == CallAction.ACTION_REMOTE_BUSY {
            self.itemToInsert.removeAll()
            if CallManager.getCallDirection() == .Outgoing || CallManager.isCallConnected() == true {
                AppAlert.shared.showToast(message: "User is Busy")
            }
            if CallManager.getCallUsersList()?.count == 0 {
                DispatchQueue.main.async  {
                    self.dismissWithDelay(callStatus: "User Busy")
                    self.dismissCallUI()
                }
            } else {
                if CallManager.getCallDirection() == .Incoming {
                    if CallManager.isCallConnected() || CallManager.getCallStatus(userId: AppUtils.getMyJid()) == .ATTENDED || CallManager.getCallStatus(userId: AppUtils.getMyJid()) == .CONNECTING {
                        if let index = findIndexOfUser(jid: userId) {
                            removeDisConnectedUser(userIndex: index)
                        }
                    }else{
                        if CallManager.getCallUsersList()?.count == 0 {
                            self.dismissWithDelay(callStatus: "User Busy")
                            self.dismissCallUI()
                        }else{
                            if let index = findIndexOfUser(jid: userId) {
                                self.members.remove(at: index)
                            }
                        }
                    }
                }else{
                    if members.count > 0 {
                        if members.count == self.outgoingCallView?.tileCollectionView.numberOfItems(inSection: 0) ?? 0 {
                            if let index = findIndexOfUser(jid: userId) {
                                removeDisConnectedUser(userIndex: index)
                            }
                        }else{
                            if CallManager.getCallUsersList()?.count == 0 {
                                self.dismissWithDelay(callStatus: "User Busy")
                                self.dismissCallUI()
                            }else{
                                if let index = findIndexOfUser(jid: userId) {
                                    self.members.remove(at: index)
                                }
                            }
                        }
                    }else{
                        if CallManager.getCallUsersList()?.count == 0 {
                            self.dismissWithDelay(callStatus: "User Busy")
                            self.dismissCallUI()
                        }else{
                            if let index = findIndexOfUser(jid: userId) {
                                self.members.remove(at: index)
                            }
                        }
                    }
                }
            }
            if CallManager.isCallConnected() {
                self.addRemoteTrackToView()
            }
        }
        else if callAction == CallAction.ACTION_VIDEO_CALL_CONVERSION_ACCEPTED {
            self.itemToInsert.removeAll()
            print("#switch ACTION_VIDEO_CALL_CONVERSION_ACCEPTED me :\(isCallConversionRequestedByMe) remote: \(isCallConversionRequestedByRemote)  isVideo: \(CallManager.getCallType().rawValue)")
            isCallConversionRequestedByRemote = true
            showHideCallBackgroundProfiles(hide: true)
            CallManager.setCallType(callType: .Video)
            getUserJid = AppUtils.getMyJid()
            CallManager.muteVideo(false)
            members.first?.isVideoMuted = false
            isVideoMuted = false
            showOneToOneVideoCallUI()
            showConnectedVideoCallOneToOneUI()
            switchLoaclandRemoteViews()
            showHideDuration(hide: false)
            setVideoBtnIcon()
            resetConversionTimer()
            //localProfileImageView.removeFromSuperview()
            AudioManager.shared().autoReRoute()
            self.outgoingCallView?.tileCollectionView.reloadData()
        }
        else if callAction == CallAction.ACTION_VIDEO_CALL_CONVERSION_REJECTED {
            self.itemToInsert.removeAll()
            print("#switch onCallAction \(callAction.rawValue)")
            
            // Call conversion is declined by the user
            
            let filteredmember = members.filter({$0.jid != AppUtils.getMyJid()})
            if filteredmember.count > 0 {
            AppAlert.shared.showToast(message: filteredmember[0].name.isEmpty ? "Request declined" : "Request declined by \(filteredmember[0].name)")
        }
            if CallManager.getCallType() == .Video {
                print("#switch Simulataious Switch Video \(callAction.rawValue)")
                if currentOutputDevice == .speaker {
                    AudioManager.shared().routeToSpeaker()
                    audioRoutedTo(deviceName: "Speaker", audioDeviceType: .speaker)
                }else{
                    audioRoutedTo(deviceName: "iPhone", audioDeviceType: .receiver)
                }
            }
            CallManager.setCallType(callType: .Audio)
            getUserJid = AppUtils.getMyJid()
            isCallConversionRequestedByMe = false
            isCallConversionRequestedByRemote = false
            resetConversionTimer()
            CallManager.disableVideo()
            isVideoMuted = true
            setVideoBtnIcon()
            showOneToOneAudioCallUI()
        }
        else if callAction == CallAction.ACTION_VIDEO_CALL_CONVERSION {
            self.itemToInsert.removeAll()
            print("#switch onCallAction \(callAction.rawValue) me :\(isCallConversionRequestedByMe) remote: \(isCallConversionRequestedByRemote)  isVideo: \(CallManager.getCallType().rawValue)")
            // Call conversion is requested to the user
            if overlayShown && !isPipOpen {
                self.callViewTapGestureAction(UITapGestureRecognizer())
            }
            isCallConversionRequestedByRemote = true
            if CallManager.isCallConversionRequestAvailable() == false {
                alertController?.dismiss(animated: true, completion:nil)
                if CallManager.getCallType() != .Video {
                    CallManager.setCallType(callType: .Audio)
                    getUserJid = AppUtils.getMyJid()
                    isCallConversionRequestedByRemote = false
                    showOneToOneAudioCallUI()
                    CallManager.cancelVideoCallSwitch()
                }
                return
            }
            showCallConversionConfirmationRequest()
            //let _ = requestForVideoTrack(jid: nil)
        }
        else if callAction == CallAction.CHANGE_TO_AUDIO_CALL {
            self.itemToInsert.removeAll()
            print("#switch onCallAction \(callAction.rawValue) me :\(isCallConversionRequestedByMe) remote: \(isCallConversionRequestedByRemote)  isVideo: \(CallManager.getCallType().rawValue)")
            isLocalViewSwitched = false
            if VideoCallConversionTimer != nil, let remoteMember = members.first {
                AppAlert.shared.showToast(message: remoteMember.name.isEmpty ? "No response" : "No response from \(remoteMember.name)")
            }
            alertController?.dismiss(animated: true, completion: nil)
            CallManager.setCallType(callType: .Audio)
            getUserJid = AppUtils.getMyJid()
            resetConversionTimer()
            showOneToOneAudioCallUI()
            removeRemoteOneToOneLocalTracks()
            self.callType = .Audio
            if isCallConversionRequestedByRemote && isCallConversionRequestedByMe {
                if currentOutputDevice == .speaker {
                    AudioManager.shared().routeToSpeaker()
                    audioRoutedTo(deviceName: "Speaker", audioDeviceType: .speaker)
                }
            }else{
                AudioManager.shared().autoReRoute()
                let audioOUtput = AudioManager.shared().currentAudioOutput()
                if audioOUtput.0 == .headset || audioOUtput.0 == .bluetooth {
                    outgoingCallView?.speakerButton.isHidden = false
                }
                audioRoutedTo(deviceName: audioOUtput.1, audioDeviceType: audioOUtput.0)
            }
            isCallConversionRequestedByRemote = false
            isCallConversionRequestedByMe = false
            if members.count == 2 {
                if members[0].isVideoMuted && !members[1].isVideoMuted {
                    if #available(iOS 16.0, *) {
                        self.outgoingCallView?.tileCollectionView.reloadSections(IndexSet(integer: 0))
                    }else{
                        self.outgoingCallView?.tileCollectionView.reloadData()
                    }
                }
            }
        }
        else if callAction == CallAction.ACTION_INVITE_USERS {
            self.resetConversionTimer()
            print("#UI menmenersCount before \(members.count) \(userId)")
            outgoingCallView?.remoteUserVideoView.willRemoveSubview(self.remoteRenderer)
            self.remoteHangUpUserList.removeAll()
            self.showGridView = true
            self.transformTileAndGridConstraints()
            for userJid in userId.components(separatedBy: ",") {
                self.itemToInsert.append(userJid)
            }
            itemToInsert.forEach {
                validateAndAddMember(jid: $0, with: convertCallStatus(status: CallManager.getCallStatus(userId: $0)))
            }
            getContactNames()
            setupTileViewConstraints(isRemoveUser: false)
            if members.count > self.outgoingCallView?.tileCollectionView.numberOfItems(inSection: 0) ?? 0 {
                UIView.performWithoutAnimation {
                    self.outgoingCallView?.tileCollectionView.reloadData()
                }
            }else{
                self.reloadCell(userId: userId)
            }
            self.showOrHideAudioWaveView(hide: true)
            updateActionsUI()
            updatePipProfileImage()
            outgoingCallView?.outGoingAudioCallImageView.isHidden = true
            if CallManager.isCallConversionRequestAvailable() == false {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    self.resetConversionTimer()
                })
            }
            self.outgoingCallView?.cameraButton.isHidden = isVideoMuted
            if self.members.count > 2 {
                self.outgoingCallView?.audioCallMutedIcon.isHidden = true
                self.outgoingCallView?.audioMutedIcon.isHidden = true
            }
        }
        else if callAction == CallAction.ACTION_REMOTE_ENGAGED {
            self.itemToInsert.removeAll()
            if CallManager.isOneToOneCall() && isOnCall && (CallManager.getCallConnectedUsersList()?.count ?? 0) == 0 {
                executeOnMainThread {
                    self.dismissWithDelay(callStatus: "Call Engaged")
                    self.onCallAction(callAction: CallAction.ACTION_LOCAL_HANGUP, userId: AppUtils.getMyJid())
                }
            }else{
                if userId != AppUtils.getMyJid() {
                    if members.count > 0 {
                        for i in members {
                            if i.jid == userId && userId != AppUtils.getMyJid() {
                                remoteHangUpUserList.append(i.name)
                            }
                        }
                        let hanpUpUsers = remoteHangUpUserList.joined(separator: ",")
                        AppAlert.shared.showToast(message: "\(hanpUpUsers) is on another call")
                    }
                }
                if CallManager.getCallDirection() == .Incoming {
                    if CallManager.isCallConnected() || CallManager.getCallStatus(userId: AppUtils.getMyJid()) == .ATTENDED || CallManager.getCallStatus(userId: AppUtils.getMyJid()) == .CONNECTING {
                        if let index = findIndexOfUser(jid: userId) {
                            removeDisConnectedUser(userIndex: index)
                        }
                    }else{
                        if CallManager.getCallUsersList()?.count == 0 {
                            self.dismissWithDelay(callStatus: "Call Engaged")
                            self.onCallAction(callAction: CallAction.ACTION_LOCAL_HANGUP, userId: AppUtils.getMyJid())
                        }else{
                            if let index = findIndexOfUser(jid: userId) {
                                self.members.remove(at: index)
                            }
                        }
                    }
                }else{
                    if members.count > 0 {
                        if members.count == self.outgoingCallView?.tileCollectionView.numberOfItems(inSection: 0) ?? 0 {
                            if let index = findIndexOfUser(jid: userId) {
                                removeDisConnectedUser(userIndex: index)
                            }
                        }else{
                            if CallManager.getCallUsersList()?.count == 0 {
                                self.dismissWithDelay(callStatus: "Call Engaged")
                                self.onCallAction(callAction: CallAction.ACTION_LOCAL_HANGUP, userId: AppUtils.getMyJid())
                            }else{
                                if let index = findIndexOfUser(jid: userId) {
                                    self.members.remove(at: index)
                                }
                            }
                        }
                    }else{
                        if CallManager.getCallUsersList()?.count == 0 {
                            self.dismissWithDelay(callStatus: "Call Engaged")
                            self.onCallAction(callAction: CallAction.ACTION_LOCAL_HANGUP, userId: AppUtils.getMyJid())
                        }else{
                            if let index = findIndexOfUser(jid: userId) {
                                self.members.remove(at: index)
                            }
                        }
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.reloadCell(userId: userId)
            }
        }
    }
    
    func onMuteStatusUpdated(muteEvent: MuteEvent, userId: String) {
        var videoStatus = Bool()
        if let index = findIndexOfUser(jid: userId) {
            videoStatus = members[index].isVideoMuted
        }
        updateMuteStatusOfUser(userId: userId)
        switch muteEvent {
        case .ACTION_REMOTE_AUDIO_MUTE:
            if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (members.count == 1 || members.count == 2)) {
                members.first?.isAudioMuted = true
                setMuteStatusText()
                if let cell = self.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: 1, section: 0)) as? TileCell{
                    if CallManager.getCallType() == .Video {
                        if isLocalViewSwitched {
                            getUserJid = userId
                            self.showHideSpeakingAnimation(isShow: false, cell: cell, isMuted:true)
                        }
                    }
                }
            } else {
                updateMuteStatus(jid: userId, isMute: true, isAudio: true)
                setMuteStatusText()
            }
        case .ACTION_REMOTE_AUDIO_UN_MUTE:
            if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (members.count == 1 || members.count == 2)) {
                members.first?.isAudioMuted = false
                setMuteStatusText()
                if let cell = self.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: 1, section: 0)) as? TileCell{
                    if CallManager.getCallType() == .Video {
                        if isLocalViewSwitched {
                            getUserJid = userId
                            self.showHideSpeakingAnimation(isShow: true, cell: cell, isMuted:false)
                        }
                    }
                }
            } else {
                updateMuteStatus(jid: userId, isMute: false, isAudio: true)
                setMuteStatusText()
            }
        case .ACTION_REMOTE_VIDEO_MUTE:
            if videoStatus == true {
                return
            }
            muteViaReload = true
                if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (members.count == 1 || members.count == 2)) {
                    members.first?.isVideoMuted = true
                    setMuteStatusText()
                    removeRemoteOneToOneLocalTracks()

                    if isLocalViewSwitched {
                        isLocalViewSwitched = false
                        print("#Reload ====> #onMuteStatusUpdated userid:\(userId) #ACTION_REMOTE_VIDEO_MUTE")
                        outgoingCallView?.tileCollectionView.reloadWithoutAnimation()
                    }
                   
                    if showGridView { reloadCell(userId: userId) }
                        getContactNames()
                    showHideCallBackgroundProfiles(hide: false)
                        setupTopViewConstraints()
                    if members.count == 2 {
                        if members[0].isVideoMuted && members[1].isVideoMuted {
                            for item in AudioManager.shared().getAllAvailableAudioInput() {
                                if item.type != .speaker {
                                    AudioManager.shared().routeAudioTo(device: item.type, force: true)
                                }
                            }
                        }
                    }
                } else {
                    updateMuteStatus(jid: userId, isMute: true, isAudio: false)
                }
        case .ACTION_REMOTE_VIDEO_UN_MUTE:
            muteViaReload = true
            if !showGridView && (CallManager.isOneToOneCall() || members.count == 2) {
                self.outgoingCallView?.remoteUserVideoView.isHidden = false
            }else{
                self.outgoingCallView?.remoteUserVideoView.isHidden = true
            }
            if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (members.count == 1 || members.count == 2)) {
                //outgoingCallView?.contentView.backgroundColor = .clear
                members.first?.isVideoMuted = false
                setMuteStatusText()
                addRemoteTrackToView()
                if !(members.last?.isVideoMuted ?? false) && !(members.first?.isVideoMuted ?? false) {
                    
                    videoTapGesture = UITapGestureRecognizer(target: self, action: #selector(smallVideoTileTapped(_:)))
                    outgoingCallView?.tileCollectionView?.addGestureRecognizer(videoTapGesture)
                }
                
                getContactNames()
                let remoteVideoTrack = CallManager.getRemoteVideoTrack(jid: AppUtils.getMyJid()) != nil
                let isVideoMuted = CallManager.isRemoteVideoMuted(members.first?.jid ?? "")
                showHideCallBackgroundProfiles(hide: showGridView ? true : (remoteVideoTrack && !isVideoMuted))
                setupTopViewConstraints()
            } else {
                updateMuteStatus(jid: userId, isMute: false, isAudio: false)
            }
        case .ACTION_LOCAL_AUDIO_MUTE:
            if !isLocalViewSwitched {
                getUserJid = userId
            }
            isAudioMuted = true
            outgoingCallView?.audioButton.setImage(UIImage(named: isAudioMuted ? "IconAudioOn" :  "IconAudioOff" ), for: .normal)
            if (CallManager.getCallMode() == .MEET && members.count == 1){ setMuteStatusText() }
        case .ACTION_LOCAL_AUDIO_UN_MUTE:
            isAudioMuted = false
            if !isLocalViewSwitched {
                getUserJid = userId
            }
            outgoingCallView?.audioButton.setImage(UIImage(named: isAudioMuted ? "IconAudioOn" :  "IconAudioOff" ), for: .normal)
            if (CallManager.getCallMode() == .MEET && members.count == 1){ setMuteStatusText() }
        case .ACTION_LOCAL_VIDEO_MUTE:
            if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && members.count == 2) {
                if members.count == 2 {
                    if members[0].isVideoMuted && members[1].isVideoMuted {
                        AudioManager.shared().routeAudioTo(device: .receiver, force: true)
                    }
                }
            }
            break
        case .ACTION_LOCAL_VIDEO_UN_MUTE:
            break
        @unknown default:
            break
        }
    }
}

// MARK:  Utility Method extensions
extension CallUIViewController {
    
    func validateAndAddMember(jid: String? = nil, with status: CallStatus) {
        print("#CallUIICheckk ====> #validateAndAddMember \(jid) \(status)")
        if members.isEmpty || !members.contains(where: {$0.jid == AppUtils.getMyJid()}) {
            addMyInfoToMembersArray(videoTrack: nil)
        }
        
        if let jid = jid, jid != AppUtils.getMyJid() {
            // For Remote Users
            if !(members.contains{$0.jid == jid} ) {
                let profileDetails = ProfileDetails(jid: jid)
                // New Remote Users Added
                _ = addRemoteMembers(for: profileDetails, with: status)
                if let index = findIndexOfUser(jid: jid) {
                    members[index].isVideoMuted = CallManager.isRemoteVideoMuted(jid)
                    members[index].isAudioMuted = CallManager.isRemoteAudioMuted(jid)
                }
            }else {
                // Existing Remote Users
                if let index = findIndexOfUser(jid: jid) {
                    if CallManager.getCallStatus(userId: jid) == .ON_HOLD{
                        members[index].callStatus = .onHold
                    }else{
                        members[index].callStatus = status
                    }
                    members[index].isVideoMuted = CallManager.isRemoteVideoMuted(jid)
                    members[index].isAudioMuted = CallManager.isRemoteAudioMuted(jid)
                }
            }
        }
    }
    
    func removeAllMembers() {
        print("#CallUII ====> #removeAllMembers")
        //clearAllTrackViews()
       // members.removeAll()
    }
    
    func updateMuteStatus(jid : String, isMute : Bool, isAudio : Bool) {
        print("#CallUII ====> #updateMuteStatus")
        if let index = findIndexOfUser(jid: jid) {
            if isAudio {
                updateUsersDetails(index: index, userid: jid)
            } else {
                updateVideoMuteStatus(index: index, userid: jid, isMute: isMute)
            }
        }
    }
    
    func updateConnectedUIStatus()
    {
        if ((self.audioPlayer) != nil) {
            if ((self.audioPlayer?.isPlaying) != nil) {
                self.audioPlayer?.stop()
            }
            self.audioPlayer = nil
        }
       
        if CallManager.getCallStatus(userId: AppUtils.getMyJid()) != .RECONNECTING{
          updateOutgoingViewCallStatus(status:"Connected")
           showHideCallAgainView(show: false, status: "Connected")
        }
        self.enableButtons(buttons:self.outgoingCallView?.videoButton, isEnable: true)
        self.showHideParticipantButton(hide : false)
        self.showHideMenuButton(hide: false)
        self.outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = true
        self.outgoingCallView?.OutGoingPersonLabel.isHidden = false
        self.getContactNames()
        self.outgoingCallView?.imageTop.constant = 28
        self.enableDisableUserInteractionFor(view: self.outgoingCallView?.AttendingBottomView, isDisable: false)
    }
    
    func updateCallStatus(jid: String, status : CallStatus)  -> Int?{
        print("#CallUII ====> #updateCallStatus")
       // print("#callStatus CVC \(jid)  \(status.rawValue)")
       // print("#STA= #callStatus onCallStatus ==== \(jid)  \(status.rawValue)")
        if let index = findIndexOfUser(jid: jid) {
           // print("#call updateCallStatus \(jid) \(status.rawValue)")
           
            if CallManager.getCallStatus(userId: jid) == .ON_HOLD{
                members[index].callStatus = .onHold
            }else if CallManager.getCallStatus(userId: jid) == .RECONNECTING{
                members[index].callStatus = .reconnecting
            }else{
                members[index].callStatus = status
            }
           // print("#STA= #callStatus onCallStatus ==== \(members[index].callStatus)  SDk status : \(CallManager.getCallStatus(userId: jid) )")
            updateUsersDetails(index: index, userid: jid)
            return index
        }
        return nil
    }
    
    func updateUsersDetails(index: Int, userid: String) {
        print("#CallUII ====> #updateUsersDetails")
        print("#call updateUsersDetails \(userid)")
            if !CallManager.isOneToOneCall() && self.outgoingCallView?.tileCollectionView != nil && !(CallManager.getCallMode() == .MEET && (members.count == 1 || members.count == 2)) {
            if (index == members.count - 2 && !showGridView) { return }
            let isLastRow = (index == members.count - 1)
            let member = members[index]
            if let tileCell = self.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? TileCell {
                if member.callStatus == .reconnecting || (!isLastRow && member.callStatus != .connected) || member.callStatus == .onHold || (isLastRow && CallManager.isCallOnHold()){
                    tileCell.foreGroundView.isHidden = false
                    tileCell.audioIconImageView.isHidden = true
                    tileCell.statusLable.text = member.callStatus.rawValue.capitalized
                }else{
                    tileCell.foreGroundView.isHidden = true
                    tileCell.statusLable.textColor = UIColor(hexString: "#FFFFFF")
                    tileCell.statusLable.text = ""
                    tileCell.audioIconImageView.isHidden = false
                    tileCell.audioIconImageView.isHidden = false
                    tileCell.audioIconImageView.image = (member.isAudioMuted) ? UIImage(systemName: "mic.slash.fill")?.withRenderingMode(.alwaysTemplate) : UIImage(named: "audio_lvl_one")?.withRenderingMode(.alwaysOriginal)
                    tileCell.audioIconImageView.tintColor = .white
                    showHideSpeakingAnimation(isShow: !member.isAudioMuted, cell: tileCell, isMuted: member.isAudioMuted)
                }
            }
        }
    }
    
    func updateVideoMuteStatus(index: Int, userid: String, isMute : Bool) {
        print("#CallUII ====> #updateVideoMuteStatus")
        print("#CR func updateVideoMuteStatus \(userid)")
            if (!CallManager.isOneToOneCall() && self.outgoingCallView?.tileCollectionView != nil && !(CallManager.getCallMode() == .MEET && members.count > 0)) || (CallManager.getCallMode() == .MEET && members.count > 0) {
                if members.count != outgoingCallView?.tileCollectionView.numberOfItems(inSection: 0){
                    print("#Reload ====> #updateVideoMuteStatus index:\(index) #userid \(userid)")
                    outgoingCallView?.tileCollectionView?.reloadWithoutAnimation()
                }else{
                    self.outgoingCallView?.tileCollectionView?.performBatchUpdates {
                        print("#performBatchUpdates ====>  #updateVideoMuteStatus index:\(index) #userid \(userid)")
                        if let tileCell = self.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? TileCell {
                            let member = members[index]
                            if isMute {
                                member.videoTrackView.removeFromSuperview()
                                tileCell.videoBaseView.willRemoveSubview(member.videoTrackView)
                                if userid == AppUtils.getMyJid() {
                                    tileCell.videoBaseView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                                }
                            } else {
                                 addGroupTracks(jid: userid)
                                if userid == AppUtils.getMyJid() {
                                    tileCell.videoBaseView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                                }
                            }
                        }
                    }
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
                return .connected
            } else if status == .ON_HOLD {
                return .onHold
            } else if status == .CONNECTING {
                return .connecting
            } else {
                return .calling
            }
        }else {
            return .calling
        }
    }
    
    func removeDisConnectedUser(userIndex : Int){
        if !members.isEmpty && userIndex < members.count {
            let islastUser = members.count - 2 == userIndex
            if (outgoingCallView?.tileCollectionView?.numberOfItems(inSection: 0) ?? 0 > userIndex) {
                if CallManager.getCallMode() == .MEET || (outgoingCallView?.tileCollectionView?.isHidden == false && (outgoingCallView?.tileCollectionView.numberOfItems(inSection: 0) ?? 0) > 2){
                    members.remove(at: userIndex)
                    if showGridView && members.count > 2 {
                        if userIndex < members.count {
                            FlyLogWriter.sharedInstance.writeText("#flow #CallUI #removeDisConnectedUser have userIndex")
                            self.outgoingCallView?.tileCollectionView.performBatchUpdates({
                                self.outgoingCallView?.tileCollectionView.deleteItems(at: [IndexPath(item: userIndex, section: 0)])
                            }, completion: nil)
                        } else {
                            FlyLogWriter.sharedInstance.writeText("#flow #CallUI #removeDisConnectedUser out of bound.")
                            // out of bound we dont need reload cell below code. - chandru.
//                            for i in members {
//                                if i.jid == self.members[userIndex].jid {
//                                    self.reloadCell(userId: i.jid)
//                                }
//                            }
                        }
                    }
                }else{
                    members.remove(at: userIndex)
                }
                itemToRemove.removeAll()
                showHideParticipantButton(hide : !isOnCall)
                showHideMenuButton(hide: !isOnCall)
                if !isOnCall{
                    //getContactNames()
                    if CallManager.getCallUsersList()?.count == 0 {
                        if CallManager.getCallMode() != .MEET {
                            executeOnMainThread {
                                self.dismissWithDelay()
                                self.onCallAction(callAction: CallAction.ACTION_LOCAL_HANGUP, userId: AppUtils.getMyJid())
                            }
                        }
                    }
                }else if (members.count == 2 && CallManager.getCallMode() != .MEET) || (members.count == 2 && CallManager.getCallMode() == .MEET) {
                    isLocalViewSwitched = false
                    if CallManager.getCallType() == .Audio{
                        if let first = members.first, let last = members.last{
                            if !first.isVideoMuted || !last.isVideoMuted {
                                CallManager.setCallType(callType: .Video)
                            }
                        }
                    }
                    if (members.first?.isVideoMuted ?? true) && (members.last?.isVideoMuted ?? true) {
                        CallManager.setCallType(callType: .Audio)
                        getUserJid = AppUtils.getMyJid()
                    }
                    if CallManager.getCallType() == .Audio && (members.first?.isVideoMuted ?? true && members.last?.isVideoMuted ?? true) {
                        self.showOneToOneAudioCallUI()
                        DispatchQueue.main.async {
                            self.outgoingCallView?.remoteUserVideoView.isHidden = true
                            self.showHideCallBackgroundProfiles(hide: false)
                        }
                        if currentOutputDevice == .speaker {
                            outgoingCallView?.speakerButton.setImage(UIImage(named: "IconSpeakerOn" ), for: .normal)
                        }
                        self.outgoingCallView?.tileCollectionView.isHidden = false
                        if self.isTapped{
                            self.SingleTapGesturTapped(UITapGestureRecognizer())
                        }
                        self.outgoingCallView?.outGoingAudioCallImageView.isHidden = false
                        outgoingCallView?.tileCollectionView.collectionViewLayout.invalidateLayout()
                        outgoingCallView?.tileCollectionView.layoutSubviews()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                            self.layoutSetBool = true
                            self.outgoingCallView?.tileCollectionView.reloadData()
                        })
                    } else {
                        self.isLocalViewSwitched = false
                        if CallManager.getCallType() == .Video && (self.members.first?.isVideoMuted == false && self.members.last?.isVideoMuted == false) {
                            self.remainingUserVideoCallUI()
                        }else{
                            showHideCallBackgroundProfiles(hide: false)
                            self.outgoingCallView?.cameraButton.isHidden = (self.members.last?.isVideoMuted ?? false) ? true : false
                            self.addRemoteTrackToView()
                            outgoingCallView?.tileCollectionView.collectionViewLayout.invalidateLayout()
                            outgoingCallView?.tileCollectionView.layoutSubviews()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                                self.layoutSetBool = true
                                self.outgoingCallView?.tileCollectionView.reloadData()
                            })
                        }
                        updateOutgoingViewCallStatus(status: isCallOnHoldForOneToCall() ? CallStatus.onHold.rawValue : convertCallStatus(status: CallManager.getCallStatus(userId: (members.first?.jid)!) ?? .CALLING).rawValue)
                        setMuteStatusText()
                        getContactNames()
                    }
                    if CallManager.getCallType() == .Video && members.first?.callStatus != .connected {
                        if let contact = ChatManager.profileDetaisFor(jid:members.first?.jid ?? ""){
                            outgoingCallView?.outGoingAudioCallImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType),chatType: contact.profileChatType, jid: contact.jid)
                            
                            if let index = findIndexOfUser(jid: contact.jid) {
                                fullScreenUser = members[index]
                            }
                        }else{
                            outgoingCallView?.outGoingAudioCallImageView.image = UIImage.init(named: "ic_profile_placeholder")
                        }
                    }
                    validateReconnectingStatus()
                } else if members.count < 2 &&  CallManager.getCallMode() != .MEET{
                    executeOnMainThread {
                        self.dismissWithDelay()
                        self.onCallAction(callAction: CallAction.ACTION_LOCAL_HANGUP, userId: AppUtils.getMyJid())
                    }
                }
                else if members.count > 2 &&  CallManager.getCallType() == .Video && islastUser {
                    addRemoteTrackToView()
                }
                else if CallManager.getAllCallUsersList().count <= 1 && CallManager.getCallMode() == .MEET  {
                    if !isVideoMuted {
                        if let track = members.first?.videoTrack {
                            showHideCallBackgroundProfiles(hide: true)
                            self.addlocalTrackToView(videoTrack: track)
                        }
                    }else{
                        removeRemoteOneToOneLocalTracks()
                        showHideCallBackgroundProfiles(hide: showGridView ? true : false)
                        setMuteStatusText()
                    }
                } else if members.count >= 2 && CallManager.getCallMode() == .MEET  {
                    if islastUser {
                        addRemoteTrackToView()
                        if !showGridView && (CallManager.isOneToOneCall() || members.count == 2) {
                            self.outgoingCallView?.remoteUserVideoView.isHidden = false
                        }else{
                            self.outgoingCallView?.remoteUserVideoView.isHidden = true
                        }
                    }
                    setupTileViewConstraints(isRemoveUser: true)
                }
            }else if CallManager.getAllCallUsersList().count <= 1 {
                if CallManager.getCallMode() != .MEET {
                    executeOnMainThread {
                        FlyLogWriter.sharedInstance.writeText("#flow #UI removeDisConnectedUser OUT  \(CallManager.getAllCallUsersList().count)")
                        self.dismissWithDelay()
                        self.onCallAction(callAction: CallAction.ACTION_LOCAL_HANGUP, userId: AppUtils.getMyJid())
                    }
                }
            }else{
                members.remove(at: userIndex)
                self.outgoingCallView?.tileCollectionView.reloadData()
                if CallManager.getCallType() == .Audio && members.count == 2 {
                    self.outgoingCallView?.outGoingAudioCallImageView.isHidden = false
                    let isAudioMuted = members.last?.isAudioMuted ?? false
                    showOrHideAudioWaveView(hide: isAudioMuted ? true : false)
                }
                validateReconnectingStatus()
            }
            if !CallManager.isOneToOneCall() && self.members.count > 2 {
                self.showGridView = true
            }else{
                self.showGridView = false
            }
            self.transformTileAndGridConstraints()
        }
        
        if CallManager.getCallMode() == .MEET && self.members.count == 1 {
            self.outgoingCallView?.tileCollectionView.isHidden = true
        }
        
        self.validateReconnectingStatus()
        self.getContactNames()
    }
    
    func remainingUserVideoCallUI() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.showOneToOneVideoCallUI()
            self.showConnectedVideoCallOneToOneUI()
            self.switchLoaclandRemoteViews()
            self.outgoingCallView?.tileCollectionView.isHidden = false
            if self.members.first?.callStatus != .connected {
                self.removeRemoteOneToOneLocalTracks()
                self.setupTopViewConstraints()
                self.showHideCallBackgroundProfiles(hide: self.showGridView ? true : false)
            }
            
            if self.members.first?.isVideoMuted ?? false {
                self.setupTopViewConstraints()
                self.showHideCallBackgroundProfiles(hide: self.showGridView ? true : false)
            }else{
                self.showHideCallBackgroundProfiles(hide: true)
            }
            self.outgoingCallView?.tileCollectionView.collectionViewLayout.invalidateLayout()
            self.outgoingCallView?.tileCollectionView.layoutSubviews()
            self.layoutSetBool = true
            self.viewDidLayoutSubviews()
        })
    }
    
    func addUpdateCallUsersWithStatus(userJid: String, status : CallStatus, reload: Bool = false, skipTracks : Bool = false)  {
        print("#CallUII ====> #addUpdateCallUsersWithStatus")
        validateAndAddMember(jid: userJid, with: status)
        
            if (isOnCall || !(outgoingCallView?.tileCollectionView?.isHidden ?? false)) {
                updateCallStatus(jid: userJid, status: status)
            }
    }
    
    func insertUsersToCollectionView(userIndex: Int, userJid: String) {
        print("#CallUII ====> #insertUsersToCollectionView userIndex: \(userIndex),userJid: \(userJid)")
        if outgoingCallView?.tileCollectionView?.numberOfItems(inSection: 0) == 0 {
            print("#Reload ====> #insertUsersToCollectionView userIndex: \(userIndex),userJid: \(userJid)")
            outgoingCallView?.tileCollectionView.reloadWithoutAnimation()
        }else{
            outgoingCallView?.audioMuteStackView.isHidden = true
            executeOnMainThread {
                print("#Reload ====> insertUsersToCollectionView else")
                self.outgoingCallView?.tileCollectionView.reloadItems(at: [IndexPath(item: userIndex, section: 0)])
                self.outgoingCallView?.tileCollectionView.reloadData()
            }
        }
        validateReconnectingStatus()
    }
    
    func getUnavailableUsers(isTimeOut : Bool) -> [String] {
        print("#CallUII ====> #getUnavailableUsers(isTimeOut")
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
        print("#CallUII ====> #removeUnavailableUsers(removedUsers\(removedUsers)")
        for jid in removedUsers {
            if let index = findIndexOfUser(jid: jid) {
                removeDisConnectedUser(userIndex: index)
                getContactNames()
                
                if CallManager.isOneToOneCall() && myCallStatus == .reconnecting {
                    updateOutgoingViewCallStatus(status: "Reconnecting")
                }
            }
        }
        
        setupTileViewConstraints(isRemoveUser: true)
    }
    
    func checkIfGroupCallUiIsVisible() -> Bool {
        print("#CallUII ====> #checkIfGroupCallUiIsVisible")
        return outgoingCallView?.tileCollectionView?.isHidden ?? false
    }

    func updateMuteStatusOfUser(userId: String) {
        print("#CallUII ====> #updateMuteStatusOfUser(userId: \(userId)")
        if userId == AppUtils.getMyJid() {
            if let index = findIndexOfUser(jid: userId) {
                members[index].isAudioMuted = CallManager.isAudioMuted()
                members[index].isVideoMuted = CallManager.isVideoMuted()
            }
        } else {
            if let index = findIndexOfUser(jid: userId) {
                members[index].isAudioMuted = CallManager.isRemoteAudioMuted(userId)
                members[index].isVideoMuted = CallManager.isRemoteVideoMuted(userId)
            }
        }
    }

    func getInvitedUsers()-> [String] {
        print("#CallUII ====> #getInvitedUsers")
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
    
   
    
    func enableDisableUserInteractionFor(view : UIView?, isDisable : Bool)  {
        print("#CallUII ====> #enableDisableUserInteractionFor")
        view?.isUserInteractionEnabled = !isDisable
    }
    
    func setVideoBtnIcon()  {
        print("#CallUII ====> #setVideoBtnIcon")
        print("#meet #btn setVideoBtnIcon \(CallManager.isVideoMuted()) || Local \(isVideoMuted)")
        var image = "ic_video_inactive"
        if members.count == 2 {
           if CallManager.isOneToOneCall() && (isVideoMuted && members.first?.isVideoMuted ?? false){
                CallManager.setCallType(callType: .Audio)
               getUserJid = AppUtils.getMyJid()
            }
        }
        if CallManager.isOneToOneCall() && CallManager.getCallType() == .Audio && (isVideoMuted && members.first?.isVideoMuted ?? false) {
            image = "ic_video_inactive"
        }else{
            let isVideoTrackAvaialable = members.last?.videoTrack != nil
            if isVideoMuted && isVideoTrackAvaialable {
                image = "ic_video_inactive"
            } else if isVideoTrackAvaialable || !isVideoMuted  {
                image = "IconVideoOff"
            }
        }
        outgoingCallView?.videoButton.setImage(UIImage(named: image ), for: .normal)
    }
    
    func setButtonsActions()  {
        print("#CallUII ====> #setButtonsActions")
        outgoingCallView?.addParticipantBtn.addTarget(self, action: #selector(addParticipant(sender:)), for: .touchUpInside)
        outgoingCallView?.menuButton.addTarget(self, action: #selector(showPopupMenu(sender:)), for: .touchUpInside)
        outgoingCallView?.callEndBtn.addTarget(self, action: #selector(callEndlBtnTapped(sender:)), for: .touchUpInside)
        outgoingCallView?.videoButton.addTarget(self, action: #selector(videoButtonTapped(sender:)), for: .touchUpInside)
        outgoingCallView?.audioButton.addTarget(self, action: #selector(AudioButtonTapped(sender:)), for: .touchUpInside)
        outgoingCallView?.speakerButton.addTarget(self, action: #selector(showAudioActionSheet(sender:)), for: .touchUpInside)
        outgoingCallView?.cameraButton.addTarget(self, action: #selector(CameraButtonTapped(sender:)), for: .touchUpInside)
        outgoingCallView?.cancelButton.addTarget(self, action: #selector(cancelBtnTapped(sender:)), for: .touchUpInside)
        outgoingCallView?.CallAgainButton.addTarget(self, action: #selector(callAgainBtnTapped(sender:)), for: .touchUpInside)
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(SingleTapGesturTapped(_:)))
        closeGesture = UITapGestureRecognizer(target: self, action: #selector(qualityViewCloseTapped(_:)))
        outgoingCallView?.qualityView.closeView.addGestureRecognizer(closeGesture)
        outgoingCallView?.backBtn.addTarget(self, action: #selector(backAction(sender:)), for: .touchUpInside)
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
        print("#CallUII ====> #setTopViewsHeight")
        if CallManager.getCallType() == .Audio && CallManager.isOneToOneCall() {
            setupTopViewConstraints()
        } else {
            if CallManager.getCallType() == .Video {
                //outgoingCallView?.timerTop.constant = 0
                outgoingCallView?.imageHeight.constant = 100
            }else {
                setupTopViewConstraints()
            }
        }
        outgoingCallView?.nameTop.constant = 8
        outgoingCallView?.imageTop.constant = 28
        
        if CallManager.getCallType() == .Video{
            let remoteVideoMuted =  (self.members.first?.isVideoMuted ?? false && isOnCall)
            outgoingCallView?.imageHeight.constant = (!groupId.isEmpty && !CallManager.isCallConnected()) || (CallManager.isOneToOneCall() && remoteVideoMuted) ? 100 : 100
        }
        changeTopViewHeight()
    }
    
    func changeTopViewHeight() {
        if showGridView {
            outgoingCallView?.viewHeight.constant = 80
            let top = CGAffineTransform(translationX: 0, y: 0)
            self.outgoingCallView?.tileCollectionView.transform = top
        } else {
            outgoingCallView?.viewHeight.constant = 190
        }
    }
    
    func getCurrentCallStatusAsString() -> String {
        FlyLogWriter.sharedInstance.writeText("-------#CallUI----#getCurrentCallStatusAsString----- \(CallManager.getCallDirection())")
        var status = CallManager.getCallDirection() == .Incoming ? "Connecting" : "Trying to connect"
        switch myCallStatus {
        case .attended :
            status = "Connecting"
        case .ringing :
            status = "Ringing"
        case .calling :
            status = currentCallStatus == .CALLING_AFTER_10S ? "User Seems to be Offline, Trying to Connect" : CallManager.getCallDirection() == .Incoming ? "Connecting" : "Trying to connect"
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
        print("#CallUII ====> #updateCallTimerDuration")
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
        print("#CallUII ====> #getStatusOfOneToOneCall")
        if CallManager.isOneToOneCall() && isCallOnHoldForOneToCall(){
            return CallStatus.onHold.rawValue
        }
        return getCurrentCallStatusAsString()
    }
    
    func isCallOnHoldForOneToCall() -> Bool {
        print("#CallUII ====> #isCallOnHoldForOneToCall")
        if let firstUserJid = members.first?.jid , let firstStatus = CallManager.getCallStatus(userId: firstUserJid), let myStatus = CallManager.getCallStatus(userId: AppUtils.getMyJid()) {
            if firstStatus == .ON_HOLD || myStatus == .ON_HOLD{
               return true
            }
        }
        return false
    }
}

// MARK:  Connection Event Delegate Methods
extension CallUIViewController : ConnectionEventDelegate{
    
    func onConnectionFailed(error: FlyError) {
        print("#CallUII ====> #onConnectionFailed")
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
            controller = UIStoryboard(name: "Login", bundle: nil).instantiateViewController(identifier: "OTPViewController")
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

// MARK:  Audio Manager Delegate Methods
extension CallUIViewController : AudioManagerDelegate {
    
    func audioRoutedTo(deviceName: String, audioDeviceType: OutputType) {
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
            executeOnMainThread {
                self.outgoingCallView?.speakerButton.setImage(UIImage(named: "bluetooth_headset" ), for: .normal)
            }
        @unknown default:
            currentOutputDevice = .receiver
            outgoingCallView?.speakerButton.setImage(UIImage(named: "IconSpeakerOff" ), for: .normal)
        }
    }
    
    @objc func showAudioActionSheet(sender:UIButton){
        print("#CallUII ====> #showAudioActionSheet")
        audioDevicesAlertController = UIAlertController(title: "Available Devices", message: nil, preferredStyle: .actionSheet)
        for item in AudioManager.shared().getAllAvailableAudioInput() {
            let action = UIAlertAction(title: item.name, style: .default) { _ in
                if item.type == .speaker {
                    AudioManager.shared().routeToSpeaker()
                }
                AudioManager.shared().routeAudioTo(device: item.type, force: true)
                self.audioRoutedTo(deviceName: item.name, audioDeviceType: item.type)
            }
            if item.type == currentOutputDevice{
                let image = UIImage(named: "selectedImg")
                action.setValue(image?.withRenderingMode(.alwaysOriginal), forKey: "image")
            }
            if CallManager.getCallType() == .Video && members.last?.isVideoMuted == false {
                if item.type != .receiver {
                    audioDevicesAlertController!.addAction(action)
                }
            }  else {
                audioDevicesAlertController!.addAction(action)
            }
        }
        audioDevicesAlertController!.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let topController = UIApplication.shared.keyWindow?.rootViewController {
            if let presentedViewController = topController.presentedViewController {
                presentedViewController.present(audioDevicesAlertController!, animated: true)
            }
        }
    }
}


// MARK:  User Speaking validation Methods
extension CallUIViewController {
    
    func onUserSpeaking(userId: String, audioLevel: Int) {
        // TODO : Commented due to crash issue
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.speakingDictionary[userId] = audioLevel
            self.updateSpeakingUI(userId: userId, isSpeaking: true, audioLevel: audioLevel)
        }
    }
    
    func onUserStoppedSpeaking(userId: String) {
        speakingDictionary[userId] = -1
        updateSpeakingUI(userId: userId, isSpeaking: false, audioLevel: -1)
    }
    
    func updateSpeakingUI(userId : String, isSpeaking : Bool, audioLevel : Int = 0 ){
        if (!CallManager.isOneToOneCall() && !(CallManager.getCallMode() == .MEET && members.count == 2)) || (CallManager.getCallMode() == .MEET && members.count > 2)  {
            if getCallStatusOf(userId: userId) != .connected{
                return
            }
            if let index = findIndexOfUser(jid: userId) {
                
                if (index == members.count - 1 && !showGridView) { return }
                
                if let cell = outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? TileCell{
                    if isSpeaking {
                        
                        self.showHideSpeakingAnimation(isShow: isSpeaking, cell: cell, isMuted: members[index].isAudioMuted)
                        
                        if userId == AppUtils.getMyJid() && members[index].isAudioMuted { cell.audioIconImageView.image =  UIImage(systemName: "mic.slash.fill")?.withRenderingMode(.alwaysTemplate)
                            cell.audioIconImageView.tintColor = .white }
                        
                        //Transform view based on speaking indicator
                        if !showGridView {
                            autoreleasepool {
                                if userId != AppUtils.getMyJid() && ((CallManager.getCallType() == .Audio && audioLevel >= 4) || (CallManager.getCallType() == .Video && audioLevel >= 5))  {
                                    let speakingMember = members[index]
                                    members.remove(at: index)
                                    
                                    members.insert(speakingMember, at: members.count - 1)
                                    
                                    fullScreenUser = speakingMember
                                    
                                    let sourceIndex = IndexPath(item: index, section: 0)
                                    let destinationIndex = IndexPath(item:  members.count - 2, section: 0)
//                                    outgoingCallView?.tileCollectionView.performBatchUpdates({
//                                        outgoingCallView?.tileCollectionView.moveItem(at: sourceIndex, to: destinationIndex)
//                                    })
                                    print("#Reload ====> #UserSpeakinguserJid: \(userId)")
                                    outgoingCallView?.tileCollectionView.reloadWithoutAnimation()
                                    let getmember = members[members.count - 3]
                                    print("getmember \(getmember.name) \(getmember.isAudioMuted)")
                                    updateUsersDetails(index: (members.count - 3), userid: emptyString())
                                   
                                    setMuteStatusText()
//                                    getContactNames()
                                    let callStatus = getCurrentCallStatusAsString()
                                    let isConnected = (callStatus == "Trying to connect" || callStatus == "Unavailable, Try again later" || callStatus == "Ringing" || callStatus == "Connecting" || callStatus == "Disconnected" || callStatus == "User Seems to be Offline, Trying to Connect") ? false : true
                                    let membersJid = members.compactMap { $0.jid }.filter {$0 != AppUtils.getMyJid()}
                                    self.showMainScreenProfileImage(membersJid: membersJid)
                                    self.showHideMultipleProfileImages(isConnected: isConnected)
                                    
//                                    if CallManager.getCallType() == .Video {
//                                        addRemoteTrackToView()
//                                    }
                                    let remoteVideoMuted = members[members.count - 2].isVideoMuted
                                    if !remoteVideoMuted {
                                        addRemoteTrackToView()
                                        showHideCallBackgroundProfiles(hide: true)
                                    }else {
                                        showHideCallBackgroundProfiles(hide: showGridView ? true : false)
                                    }
                                    if !showGridView {
                                        outgoingCallView?.remoteUserVideoView.isHidden = remoteVideoMuted ? true : false
                                    }else {
                                        outgoingCallView?.remoteUserVideoView.isHidden = true
                                    }
                                }
                            }
                        }
                    }else {
                        self.showHideSpeakingAnimation(isShow: isSpeaking, cell: cell, isMuted: members[index].isAudioMuted)
                    }
                }
            }
        }else {
            if userId == AppUtils.getMyJid() {
                if !isLocalViewSwitched {
                    print("Tilecells Items \(outgoingCallView?.tileCollectionView?.numberOfItems(inSection: 0))")
                    if let cell = self.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: 1, section: 0)) as? TileCell{
                        self.showHideSpeakingAnimation(isShow: isSpeaking, cell: cell, isMuted: self.members.last?.isAudioMuted ?? false)
                    }
                }
            }
        }
    }
    
    func showHideSpeakingAnimation(isShow: Bool, cell: TileCell, isMuted: Bool) {
        if showGridView {
            if isShow && !isMuted {
                let imageArray = [UIImage(named: "audio_lvl_one")!,UIImage(named: "audio_lvl_two")!,UIImage(named: "audio_lvl_three")!,UIImage(named: "audio_lvl_four")!,UIImage(named: "audio_lvl_five")!]
                cell.audioIconImageView.animationImages = imageArray
                cell.audioIconImageView.animationDuration = 0.5
                cell.audioIconImageView.startAnimating()
                
            }else {
                cell.audioIconImageView.stopAnimating()
                cell.audioIconImageView.image = (isMuted) ? UIImage(systemName: "mic.slash.fill")?.withRenderingMode(.alwaysTemplate) : UIImage(named: "audio_lvl_one")?.withRenderingMode(.alwaysOriginal)
                cell.audioIconImageView.tintColor = .white
            }
        }else{
            if CallManager.getCallType() == .Audio {
                if !isLocalViewSwitched {
                    if isShow && !isMuted {
                        print("$%$%$$% ----> !isLocalViewSwitched audio level")
                        let imageArray = [UIImage(named: "audio_lvl_one")!,UIImage(named: "audio_lvl_two")!,UIImage(named: "audio_lvl_three")!,UIImage(named: "audio_lvl_four")!,UIImage(named: "audio_lvl_five")!]
                        cell.audioIconImageView.animationImages = imageArray
                        cell.audioIconImageView.animationDuration = 0.5
                        cell.audioIconImageView.startAnimating()
                    }else {
                        print("$%$%$$% ----> !isLocalViewSwitched mute")
                        cell.audioIconImageView.stopAnimating()
                        cell.audioIconImageView.isHidden = false
                        cell.audioIconImageView.image = (isMuted) ? UIImage(systemName: "mic.slash.fill")?.withRenderingMode(.alwaysTemplate) : UIImage(named: "audio_lvl_one")?.withRenderingMode(.alwaysOriginal)
                    }
                }
            }else{
                if !isLocalViewSwitched && getUserJid == AppUtils.getMyJid() {
                    if isShow && !isMuted {
                        print("$%$%$$% ----> !isLocalViewSwitched audio level")
                        let imageArray = [UIImage(named: "audio_lvl_one")!,UIImage(named: "audio_lvl_two")!,UIImage(named: "audio_lvl_three")!,UIImage(named: "audio_lvl_four")!,UIImage(named: "audio_lvl_five")!]
                        cell.audioIconImageView.animationImages = imageArray
                        cell.audioIconImageView.animationDuration = 0.5
                        cell.audioIconImageView.startAnimating()
                    }else {
                        print("$%$%$$% ----> !isLocalViewSwitched mute")
                        cell.audioIconImageView.stopAnimating()
                        cell.audioIconImageView.isHidden = false
                        cell.audioIconImageView.image = (isMuted) ? UIImage(systemName: "mic.slash.fill")?.withRenderingMode(.alwaysTemplate) : UIImage(named: "audio_lvl_one")?.withRenderingMode(.alwaysOriginal)
                    }
                }else{
                    if isLocalViewSwitched && getUserJid != AppUtils.getMyJid() {
                        if isShow && !isMuted {
                            print("$%$%$$% ----> isLocalViewSwitched audio levellll")
                            let imageArray = [UIImage(named: "audio_lvl_one")!,UIImage(named: "audio_lvl_two")!,UIImage(named: "audio_lvl_three")!,UIImage(named: "audio_lvl_four")!,UIImage(named: "audio_lvl_five")!]
                            cell.audioIconImageView.animationImages = imageArray
                            cell.audioIconImageView.animationDuration = 0.5
                            cell.audioIconImageView.startAnimating()
                        }else{
                            print("$%$%$$% ----> isLocalViewSwitched audio muteeeee")
                            cell.audioIconImageView.stopAnimating()
                            cell.audioIconImageView.isHidden = false
                            cell.audioIconImageView.image = (isMuted) ? UIImage(systemName: "mic.slash.fill")?.withRenderingMode(.alwaysTemplate) : UIImage(named: "audio_lvl_one")?.withRenderingMode(.alwaysOriginal)
                        }
                    }
                }
            }
        }
    }
}

extension CallUIViewController: particpantsAddDelegate {
    func participantsAdded(profiles: [String]) {
        print("#reloadcell #CallUII ====> #participantsAdded profiles \(profiles) \(myCallStatus)")
        CallManager.inviteUsersToOngoingCall(profiles) { isSuccess, error in
            self.remoteHangUpUserList.removeAll()
            if !isSuccess {
                let errorMessage = AppUtils.shared.getErrorMessage(description: error?.description ?? emptyString())
                AppAlert.shared.showToast(message: errorMessage)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    self.reloadForInVite = true
                }
            }
        }
    }
}

// MARK:  Video Tracks add,remove and switch
extension CallUIViewController {

    func addOneToOneLocalTracks() {
        print("#CallUII ====> #addOneToOneLocalTracks")
        if let localTrack = members.last?.videoTrack {
            addVideoTrack(to: UIView(), isLocal: true, track: localTrack)
        }
    }
    
    func addGroupTracks(jid: String) {
        print("#performBatchUpdates ====> #addGroupTracks: \(jid)")
        if let index = self.findIndexOfUser(jid: jid), !((members.count - 2) < 0 ) {
            if (members[members.count - 2].callStatus != .connected && !showGridView){ return }
            let member = self.members[index]
            if let collectionView = self.outgoingCallView?.tileCollectionView {
                executeOnMainThread {
                    if self.members.count != collectionView.numberOfItems(inSection: 0){
                        collectionView.reloadWithoutAnimation()
                    }else{
                        print("#CallUUIIII collectionView.cellForItem _ member.isVideoMuted =======>\(member.isVideoMuted), \(jid) \(String(describing: CallManager.getRemoteVideoTrack(jid: jid)))")
                        if let groupCell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? TileCell, let track = CallManager.getRemoteVideoTrack(jid: jid) {
                            
                        #if arch(arm64)
                            let localRen = RTCMTLVideoView(frame: .zero)
                        #else
                            let localRen = RTCEAGLVideoView(frame: .zero)
                        #endif
                            print("** member.isVideoMuted =======>\(member.isVideoMuted), \(jid)")
                            if let baseView = groupCell.videoBaseView  {
                                
                                track.remove(member.videoTrackView)
                                member.videoTrackView.removeFromSuperview()
                                baseView.willRemoveSubview(member.videoTrackView)
                                
                                member.videoTrackView = localRen
                                member.videoTrackView.frame = CGRect(x: 0, y: 0, width: baseView.bounds.width, height: baseView.bounds.height)
                                if member.isVideoMuted == false {
                                    print("#call addGroupTracks Added.... \(jid)")
                                    track.add(member.videoTrackView)
                                    baseView.addSubview(member.videoTrackView)
                                }
                            }
                            if self.muteViaReload {
                                self.muteViaReload = false
                                print("#call addGroupTracks muteViaReload \(jid)")
                             //   self.outgoingCallView?.tileCollectionView?.reloadData()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func switchLoaclandRemoteViews() {
        print("#switchLoaclandRemoteViews ====> \(isLocalViewSwitched)")
        if isLocalViewSwitched {
            if let remoteView = outgoingCallView?.remoteUserVideoView {
                if let remoteTrack = CallManager.getRemoteVideoTrack(jid: members.first?.jid ?? "") {
                    members.first?.videoTrack = remoteTrack
                    addVideoTrack(to: UIView(), isLocal: true, track: remoteTrack)
                }
                if let localTrack =  CallManager.getRemoteVideoTrack(jid: members.last?.jid ?? "") {
                    members.last?.videoTrack = localTrack
                    addVideoTrack(to: remoteView, isLocal: false, track: localTrack)
                    addSwitchedRemoteTrackToView(localView: remoteView, isLocal: false)
                }
            }
        } else {
            if let remoteView = outgoingCallView?.remoteUserVideoView {
                if let localTrack = CallManager.getRemoteVideoTrack(jid: members.last?.jid ?? "")  {
                    members.last?.videoTrack = localTrack
                    addVideoTrack(to: UIView(), isLocal: true, track: localTrack)
                    addSwitchedRemoteTrackToView(localView: UIView(), isLocal: true)
                }
                if let remoteTrack = CallManager.getRemoteVideoTrack(jid: members.first?.jid ?? "") {
                    members.first?.videoTrack = remoteTrack
                    addVideoTrack(to: remoteView, isLocal: false, track: remoteTrack)
                }
            }
        }
    }
    
    func addVideoTrack(to view: UIView, isLocal: Bool, track: RTCVideoTrack) {
       // print("#CallUII ====> #addVideoTrack")
        #if arch(arm64)
          let localRen = RTCMTLVideoView(frame: .zero)
        #else
          let localRen = RTCEAGLVideoView(frame: .zero)
        #endif
        if isLocal {
//            self.localRenderer.removeFromSuperview()
//            view.willRemoveSubview(self.localRenderer)
//            self.localRenderer = localRen
//            localRenderer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
//            view.addSubview(localRenderer)
//            track.add(localRenderer)
            
            if let collectionView = outgoingCallView?.tileCollectionView {
                executeOnMainThread {
                    if self.members.count != collectionView.numberOfItems(inSection: 0){
                       // print("#Reload ====> #addVideoTrack")
                        collectionView.reloadWithoutAnimation()
                    }else{
                        collectionView.performBatchUpdates {
                            print("#performBatchUpdates ====> #addVideoTrack")
                            if let tileCell = collectionView.cellForItem(at: IndexPath(item: self.showGridView ? 1 : 0, section: 0)) as? TileCell {
                                if let member = (self.isLocalViewSwitched) ? self.members.first : self.members.last {
                                    
                            #if arch(arm64)
                                    let localRen = RTCMTLVideoView(frame: .zero)
                            #else
                                    let localRen = RTCEAGLVideoView(frame: .zero)
                            #endif
                                    
                                    if let videoView = tileCell.videoBaseView {
                                        track.remove(member.videoTrackView)
                                        member.videoTrackView.removeFromSuperview()
                                        videoView.willRemoveSubview(member.videoTrackView)
                                        
                                        member.videoTrackView = localRen
                                        member.videoTrackView.frame = CGRect(x: 0, y: 0, width: videoView.bounds.width, height: videoView.bounds.height)
                                        track.add(member.videoTrackView)
                                        videoView.addSubview(member.videoTrackView)
                                    }
                                }
                            }
                        }
                        
                    }
                }
            }
        } else {
            track.remove(self.remoteRenderer)
           // self.remoteRenderer.removeFromSuperview()
          //  view.willRemoveSubview(self.remoteRenderer)
            self.remoteRenderer = localRen
            remoteRenderer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
            view.addSubview(remoteRenderer)
            track.add(remoteRenderer)
            
           if showGridView {
                if let collectionView = outgoingCallView?.tileCollectionView {
                    executeOnMainThread {
                        collectionView.performBatchUpdates {
                            print("#performBatchUpdates ====> #addVideoTrack showGridView")
                            if let tileCell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? TileCell {
                                if let member = self.members.first {
                                    
                                    #if arch(arm64)
                                    let localRen = RTCMTLVideoView(frame: .zero)
                                    #else
                                    let localRen = RTCEAGLVideoView(frame: .zero)
                                    #endif
                                    
                                    if let videoView = tileCell.videoBaseView {
                                        track.remove(member.videoTrackView)
                                        member.videoTrackView.removeFromSuperview()
                                        videoView.willRemoveSubview(member.videoTrackView)
                                        
                                        member.videoTrackView = localRen
                                        member.videoTrackView.frame = CGRect(x: 0, y: 0, width: videoView.bounds.width, height: videoView.bounds.height)
                                        track.add(member.videoTrackView)
                                        videoView.addSubview(member.videoTrackView)
                                    }
                                }
                            }
                            
                        }
                    }
                }
            }
        }
    }

    func addSwitchedRemoteTrackToView(localView: UIView, isLocal: Bool) {
        print("#CallUII ====> #addSwitchedRemoteTrackToView")
        if isLocalViewSwitched {
            if members.last?.isVideoMuted ?? false {
                showHideCallBackgroundProfiles(hide: showGridView ? true : false)
                setupTopViewConstraints()
            }else {
                showHideCallBackgroundProfiles(hide: true)
                setupTopViewConstraints()
            }
        }
    }
    
    func removeRemoteOneToOneLocalTracks() {
        print("#CallUII ====> #removeRemoteOneToOneLocalTracks")
        if let remoteView = self.outgoingCallView?.remoteUserVideoView {
            // self.remoteRenderer.removeFromSuperview()
          //  remoteView.willRemoveSubview(self.remoteRenderer)
        }
        if members.count > 0 {
            for i in 0..<members.count - 1 {
                if let index = findIndexOfUser(jid: members[i].jid) {
                    if let groupCell = outgoingCallView?.tileCollectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? TileCell,  let track = CallManager.getRemoteVideoTrack(jid: members[i].jid) {
                        if let baseView = groupCell.videoBaseView  {
                            track.remove(members[i].videoTrackView)
                            members[i].videoTrackView.removeFromSuperview()
                            baseView.willRemoveSubview(members[i].videoTrackView)
                        }
                    }
                }
            }
        }
    }
    
    func oneToOneVideoViewTransforms(){
        print("#CallUII ====> #oneToOneVideoViewTransforms")
        if let remoteView = outgoingCallView?.remoteUserVideoView {
            if isBackCamera {
                if isLocalViewSwitched{
                    remoteView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }
            }else{
                if isLocalViewSwitched{
                    remoteView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                }
            }
        }
    }
    
    @objc func smallVideoTileTapped(_ sender: UITapGestureRecognizer) {
        
        showHideMenu = true
        removePopupView()
        
        if (!showGridView && (!(members.last?.isVideoMuted ?? false) && !(members.first?.isVideoMuted ?? false))) {
            switchVideoViews.onNext(true)
            shouldHideProfile = true
            self.outgoingCallView?.tileCollectionView.reloadData()
        }else {
            shouldHideProfile = false
            SingleTapGesturTapped(UITapGestureRecognizer())
        }
    }
}


// MARK:  Profile Events Delegate Methods
extension CallUIViewController : ProfileEventsDelegate{
    
    func userCameOnline(for jid: String) { }
    
    func userWentOffline(for jid: String) { }
    
    func userProfileFetched(for jid: String, profileDetails: ProfileDetails?) { }
    
    func myProfileUpdated() { }
    
    func usersProfilesFetched() { }
    
    func blockedThisUser(jid: String) { }
    
    func unblockedThisUser(jid: String) { }
    
    func usersIBlockedListFetched(jidList: [String]) { }
    
    func usersBlockedMeListFetched(jidList: [String]) { }
    
    func userUpdatedTheirProfile(for jid: String, profileDetails: ProfileDetails) {
        print("#CallUII ====> #userUpdatedTheirProfile jid: \(jid)")
        getContactNames()
        print("#Reload ====> #userUpdatedTheirProfile jid: \(jid)")
        outgoingCallView?.tileCollectionView?.reloadWithoutAnimation()
    }
    
    func userBlockedMe(jid: String) {
        getContactNames()
    }
    
    func userUnBlockedMe(jid: String) {
        getContactNames()
    }
    
    func hideUserLastSeen() { }
    
    func getUserLastSeen() { }
    
    func userDeletedTheirProfile(for jid: String, profileDetails: ProfileDetails) {
        print("#CallUII ====> #userDeletedTheirProfile jid: \(jid)")
        if CallManager.isOneToOneCall() && CallManager.getAllCallUsersList().contains(jid){
            if CallManager.getCallMode() != .MEET {
                dismissCallUI()
            }
        }else{
            onCallStatusUpdated(callStatus: .DISCONNECTED, userId: jid)
        }
    }
}

// MARK:  Refresh Profile Info Delegate Methods
extension CallUIViewController : RefreshProfileInfo {
    
    func refreshProfileDetails(profileDetails: ProfileDetails?) {
        print("#CallUII ====> #refreshProfileDetails profileDetails: \(profileDetails)")
        if let jid = profileDetails?.jid{
            if CallManager.isOneToOneCall() && CallManager.getAllCallUsersList().contains(jid){
                if CallManager.getCallMode() != .MEET {
                    dismissCallUI()
                }
            }else{
                onCallStatusUpdated(callStatus: .DISCONNECTED, userId: jid)
            }
        }
        reloadForInVite = true
    }
}

// MARK:  Check Camera Permission
extension CallUIViewController {
    
    func checkCameraPermission(sourceType: UIImagePickerController.SourceType) {
        print("#CallUII ====> #checkCameraPermission: \(sourceType)")
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
                self?.isVideoPermissionEnabled = false
                break
            @unknown default:
                print("Permission failed")
                self?.isVideoPermissionEnabled = false
               
            }
        })
        
    }
}

// MARK:  Utility Method extensions
extension CallUIViewController {
    
    func updateOutgoingViewCallStatus(status : String = emptyString()){
        print("#CallUII ====> #updateOutgoingViewCallStatus: \(status)")
        if !CallManager.isCallConnected() && status.contains("Reconnecting")  {
            return
        }
        if CallManager.getCallMode() == .MEET {
            outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = true
            outgoingCallView?.reconnectingLable?.isHidden = false
            let threeDot = status.contains("Reconnecting") ? "..." : ""
            outgoingCallView?.reconnectingLable?.text = ((status.contains("Reconnecting") || status == "Call on Hold") && !showGridView) ? "\(status)\(threeDot)" : ""
            print("#STA= #callStatus onCallStatus ==== updateCallStatus meet")
        }else{
            if (status == "Trying to connect" || status == "Unavailable, Try again later" || status == "Ringing" || status == "Disconnected" || status == "User Seems to be Offline, Trying to Connect" || status == "Connecting") {
                outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = false
                getContactNames()
                outgoingCallView?.OutGoingPersonLabel.isHidden = false
                outgoingCallView?.OutGoingPersonLabel.text  =  status == "User Seems to be Offline, Trying to Connect" ? "User Seems to be Offline,\n Trying to Connect\n" : status
                outgoingCallView?.OutGoingPersonLabel.numberOfLines = 0
                showHideDuration(hide:true)
//                if status == "Trying to connect" && CallManager.isOneToOneCall() && CallManager.getCallType() == .Video {
//                    outgoingCallView?.cameraButton.isEnabled = false
//                } else {
//                    outgoingCallView?.cameraButton.isEnabled = true
//                }
                if status == "Connecting" && !CallManager.isOneToOneCall() {
                    outgoingCallView?.profileImageStackView.isHidden = true
                } else {
                    outgoingCallView?.profileImageStackView.isHidden = false
                }
            }else{
                outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = true
                if !status.contains("Reconnecting"){
                    outgoingCallView?.OutgoingRingingStatusLabel?.text = (status == "Connected" || status == "Call on Hold" || status == "Calling") ? "" : (status == "" ? getNameStringWithGroupName(userNames: "") : status)
                }
                let threeDot = status.contains("Reconnecting") ? "..." : ""
                outgoingCallView?.reconnectingLable?.isHidden = !((status.contains("Reconnecting") || status == "Call on Hold") && !showGridView)
                outgoingCallView?.reconnectingLable?.text = ((status.contains("Reconnecting") || status == "Call on Hold") && !showGridView) ? "\(status)\(threeDot)" : ""
                print("reconn label update text \(outgoingCallView?.reconnectingLable?.text)")
               // print("#STA= #callStatus onCallStatus ==== \(String(describing: outgoingCallView?.reconnectingLable?.isHidden)) status")
                showHideDuration(hide: (status == "Disconnected" || status == "Connecting" || status.isEmpty) ? true : false)
            }
        }
    }
    
    func showHideDuration(hide : Bool){
        print("#CallUII ====> #showHideDuration: \(hide)")
        if CallManager.getCallMode() == .MEET{
            outgoingCallView?.timerLable.isHidden = true
        }else{
            outgoingCallView?.timerLable.isHidden = hide
        }
    }
    
    func showHideParticipantButton(hide : Bool){
        print("#CallUII ====> #showHideParticipantButton: \(hide)")
        if CallManager.getCallMode() == .MEET{
            outgoingCallView?.addParticipantBtn.isHidden = false
        }else{
            outgoingCallView?.addParticipantBtn.isHidden = hide
        }
        
    }
    
    func updateRemoteViewForMuteAndUnmute(){
        print("#CallUII ====> #updateRemoteViewForMuteAndUnmute")
        if !CallManager.isOneToOneCall() && CallManager.getCallType() == .Video {
            if members.count > 0 {
                if members[members.count - 2].isVideoMuted  {
                    getContactNames()
                    showHideCallBackgroundProfiles(hide: showGridView ? true : false)
                    setupTopViewConstraints()
                }else {
                    getContactNames()
                    showHideCallBackgroundProfiles(hide: true)
                    setupTopViewConstraints()
                }
            }
        }
    }
    
    func setupTopViewConstraints() {
        print("#CallUII ====> #setupTopViewConstraints")
        outgoingCallView?.imageHeight.constant = 100
        outgoingCallView?.imageTop.constant = 28
    }
    
    func showHideCallBackgroundProfiles(hide: Bool) {
        print("#CallUII ====> #showHideCallBackgroundProfiles  \(hide)")
        print("###T showHideCallBackgroundProfiles Hide \(hide)")
        showOrHideAudioWaveView(hide: hide)
        outgoingCallView?.outGoingAudioCallImageView.isHidden = hide
        outgoingCallView?.OutGoingCallBG.isHidden = hide
        outgoingCallView?.OutGoingCallBG.image = (hide) ? nil : UIImage(named: "AudioCallBG")
        
        outgoingCallView?.OutGoingCallBG.backgroundColor = UIColor(hexString: "151F32")
        self.view.backgroundColor = UIColor(hexString: "151F32")
        outgoingCallView?.remoteUserVideoView.backgroundColor = UIColor(hexString: "151F32")
    }
    
    func showHideMenuButton(hide : Bool){
        print("#CallUII ====> #showHideMenuButton  \(hide)")
        if CallManager.getCallMode() == .MEET{
            outgoingCallView?.menuButton.isHidden = false
        }else{
            outgoingCallView?.menuButton.isHidden = true
        }
    }
    
    private func showOrHideAudioWaveView(hide : Bool) {
        print("#showOrHideAudioWaveView \(hide)")
        executeOnMainThread { [weak self] in
            if let weakSelf = self {
                self?.outgoingCallView?.audioWaveView.isHidden = hide
                if !((weakSelf.outgoingCallView?.audioWaveView.layer.sublayers?.contains(weakSelf.rippleView)) != nil) {
                    weakSelf.rippleView = PulsingHaloLayer()
                    weakSelf.rippleView.position = CGPoint(x: (weakSelf.outgoingCallView?.audioWaveView.frame.width ?? 0)/2, y:  (weakSelf.outgoingCallView?.audioWaveView.frame.height ?? 0)/2)
                    weakSelf.rippleView.radius = 80
                    weakSelf.rippleView.haloLayerNumber = 5
                    weakSelf.rippleView.backgroundColor = UIColor.lightGray.cgColor
                    weakSelf.rippleView.start()
                    weakSelf.outgoingCallView?.audioWaveView.layer.addSublayer(weakSelf.rippleView)
                }
            }
        }
        
    }
    
    func setupTileViewConstraints(isRemoveUser: Bool) {
        print("#CallUII ====> #setupTileViewConstraints  \(isRemoveUser)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else{return}
            if self.showGridView {
                self.outgoingCallView?.tileCollectionWidth.constant = self.view.frame.size.width
            }else{
                if isRemoveUser{
                    self.outgoingCallView?.tileCollectionWidth.constant = self.members.count <= 2 ? 110 : self.view.frame.size.width - 30
                }else{
                    self.outgoingCallView?.tileCollectionWidth.constant = ((CallManager.isOneToOneCall() || members.count == 2) || (CallManager.getCallMode() == .MEET && members.count <= 2)) ? 110 : self.view.frame.size.width - 30
                }
            }
        }
    }
    
    func transformTileAndGridConstraints() {
        DispatchQueue.main.async {
            let collectionHeight = CGFloat(160)
            if self.showGridView{
                if self.outgoingCallView?.tileCollectionView.collectionViewLayout != nil {
                    self.outgoingCallView?.tileCollectionView.collectionViewLayout.invalidateLayout()
                    self.outgoingCallView?.tileCollectionView.layoutSubviews()
                }
                self.flowLayout.scrollDirection = .vertical
                self.outgoingCallView?.tileCollectionView.collectionViewLayout = self.flowLayout
                self.outgoingCallView?.tileCollectionView.backgroundColor = .black
                
                self.outgoingCallView?.tileCollectionView.showsVerticalScrollIndicator = true
                
                self.outgoingCallView?.tileCollectionHeight?.constant = self.view.bounds.height
                self.outgoingCallView?.tileCollectionTop.constant = 0
                self.outgoingCallView?.tileCollectionTrailing.constant = 0
                self.outgoingCallView?.tileCollectionLeading.isActive = true
                self.outgoingCallView?.tileCollectionView.isScrollEnabled = true
            }else{
                if self.outgoingCallView?.tileCollectionView.collectionViewLayout != nil {
                    self.outgoingCallView?.tileCollectionView.collectionViewLayout.invalidateLayout()
                    self.outgoingCallView?.tileCollectionView.layoutSubviews()
                }
                self.flowLayout.scrollDirection = .horizontal
                self.outgoingCallView?.tileCollectionView.collectionViewLayout = self.flowLayout
                self.outgoingCallView?.tileCollectionView.backgroundColor = .clear
                
                self.outgoingCallView?.tileCollectionView.showsVerticalScrollIndicator = false
                self.outgoingCallView?.tileCollectionWidth.constant = self.members.count <= 2 ? 110 : self.view.frame.size.width - 30
                self.outgoingCallView?.tileCollectionHeight?.constant = collectionHeight
                self.outgoingCallView?.tileCollectionTop.constant = self.safeAreaHeight - ((self.outgoingCallView?.AttendingBottomView.frame.height ?? 0) + collectionHeight + 25)
                self.outgoingCallView?.tileCollectionTrailing.constant = -15
                self.outgoingCallView?.tileCollectionLeading.isActive = false
                self.outgoingCallView?.remoteUserVideoView.isHidden = false
                self.outgoingCallView?.remoteUserVideoView.backgroundColor = .black
                self.outgoingCallView?.tileCollectionView.isScrollEnabled = false
                
            }
            self.changeTopViewHeight()
        }
    }
    
    func showHideMultipleProfileImages(isConnected: Bool) {
        print("#CallUII ====> #showHideMultipleProfileImages")
        outgoingCallView?.profileImage[0].isHidden = true
        outgoingCallView?.profileImage[1].isHidden = true
        outgoingCallView?.profileImage[2].isHidden = true
        outgoingCallView?.profileImage[3].isHidden = true
        outgoingCallView?.countLabel.isHidden = true
        
        if members.count > 2 && groupId.isEmpty && !isConnected {
            
            for (index, member) in members.enumerated() {
                
                if members.count < 4 {
                    
                    if let contact = ChatManager.getContact(jid: member.jid) {
                        
                        let profileImageStr = contact.thumbImage.isEmpty ? contact.image : contact.thumbImage
                        
                        outgoingCallView?.profileImage[index].loadFlyImage(imageURL: profileImageStr, name: getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), chatType: contact.profileChatType,contactType: contact.contactType, jid: contact.jid, isBlockedByAdmin: ContactManager.shared.getUserProfileDetails(for: contact.jid)?.isBlockedByAdmin ?? false)
                        outgoingCallView?.profileImage[index].isHidden = false
                        
                        outgoingCallView?.countLabel.isHidden = true
                        
                    } else {
                       
                        outgoingCallView?.profileImage[index].image = UIImage(named: "ic_profile_placeholder")
                        outgoingCallView?.profileImage[index].isHidden = false
                        outgoingCallView?.countLabel.isHidden = true
                    }
                    
                }else {
                    
                    if let contact = ChatManager.getContact(jid: member.jid) {
                        
                        let profileImageStr = contact.thumbImage.isEmpty ? contact.image : contact.thumbImage
                        
                        outgoingCallView?.profileImage[index].loadFlyImage(imageURL: profileImageStr, name: getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), chatType: contact.profileChatType,contactType: contact.contactType, jid: contact.jid, isBlockedByAdmin: ContactManager.shared.getUserProfileDetails(for: contact.jid)?.isBlockedByAdmin ?? false)
                        outgoingCallView?.profileImage[index].isHidden = (index == 3) ? true : false
                        
                    }else {
                        outgoingCallView?.profileImage[index].image = UIImage(named: "ic_profile_placeholder")
                    }
                    outgoingCallView?.countLabel.isHidden = false
                    outgoingCallView?.countLabel.text = "+\(members.count - 3)"
                    
                    if index == 3 {
                        
                        break
                    }
                }
//                if callType == .Audio {
//                    outgoingCallView?.outGoingAudioCallImageView.isHidden = false
//                } else {
                    outgoingCallView?.outGoingAudioCallImageView.isHidden = true
                    showOrHideAudioWaveView(hide: true)
//                }
            }
        }
    }
}


extension CallUIViewController : MobileCallActionDelegate {
    func whileIncoming() {
        print("#CallUII ====> #whileIncoming")
        if outgoingCallView != nil { // check this condition if ui is presented
            if dismissCalled == false {
                CallUIViewController.dismissDelegate?.onCallControllerDismissed()
            }
            dismissCalled = true
        }
    }
    
    func didCallAnswered() {

    }
    
    func whileDialing() {

    }
    
    func didCallDisconnected() {

    }
    

}

extension CallUIViewController : ConnectionQualityDelegate{
    
    func didQualityUpdated(quality: ConnectionQuality) {
        print("#CallUII ====> #didQualityUpdated(quality \(quality.rawValue)")
        print("#quality #sl \(quality.rawValue) ")
        if !CallManager.isCallConnected(){
            return
        }
        if qualityToastShown && quality != .poor{
            qualityToastShown = false
        }
        if quality == .poor {
            FlyLogWriter.sharedInstance.writeText("#Poor ------ #CallUIViewController ------- didQualityUpdated ----- quality: \(quality.rawValue)")
        }
        DispatchQueue.main.async { [weak self] in
            self?.showHideQualityView(show: quality == .poor)
        }
    }
    
    func showHideQualityView(show : Bool, fromTimer : Bool = false) {
        print("#CallUII ====> #showHideQualityView(show \(show)")
        if qualityTimer == nil && show && !qualityToastShown {
            outgoingCallView?.qualityView?.closeView.addGestureRecognizer(closeGesture)
            qualityTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(qualityViewCloseTapped(_:)), userInfo: nil, repeats: false)
            outgoingCallView?.timerLable.isHidden = false
            qualityToastShown = true
            CallUIViewController.isQualityToastShowing = true
            executeOnMainThread {
                self.outgoingCallView?.qualityView?.isHidden = false
            }
        }
        if show{
            executeOnMainThread {
                self.updateQualityInCollectionView()
                if CallManager.getCallMode() == .MEET && self.members.count == 1 && CallManager.getCallConnectionQuality() == .poor{
                    self.outgoingCallView?.qualityIcon.isHidden = false
                }
            }
        }
        if !show{
            executeOnMainThread {
                CallUIViewController.isQualityToastShowing = false
                let index = self.getLastIndexInCollectionView()
                if let myCell = self.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? TileCell, CallManager.isCallConnected() {
                    if !fromTimer || CallManager.getCallStatus(userId: AppUtils.getMyJid()) == .RECONNECTING{
                        myCell.qualityView.isHidden = true
                    }else if CallManager.getCallConnectionQuality() == .poor{
                        myCell.qualityView.isHidden = false
                    }
                }
                self.outgoingCallView?.qualityView?.isHidden = true
                CallUIViewController.isQualityToastShowing = false
                if CallManager.getCallMode() == .MEET && self.members.count == 1 {
                    self.outgoingCallView?.qualityIcon.isHidden = CallManager.getCallConnectionQuality() != .poor
                }
            }
        }
    }
    
    func updateQualityInCollectionView(){
        print("#CallUII ====> #updateQualityInCollectionView")
        let index = self.getLastIndexInCollectionView()
        if let myCell = self.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? TileCell, CallManager.isCallConnected(){
            myCell.qualityView.isHidden = false
        }
    }
    
    @objc func qualityViewCloseTapped(_ sender: UITapGestureRecognizer) {
        outgoingCallView?.qualityView?.closeView.removeGestureRecognizer(closeGesture)
        qualityTimer?.invalidate()
        qualityTimer = nil
        self.showHideQualityView(show: false, fromTimer: true)
        
    }
    
    func getLastIndexInCollectionView() -> Int {
        print("#CallUII ====> #getLastIndexInCollectionView")
        if let items = self.outgoingCallView?.tileCollectionView?.numberOfItems(inSection: 0){
            return items - 1
        }
        return 0
    }
}

extension UICollectionView {
    func reloadWithoutAnimation(){
       print("reloadWithoutAnimation called.....")
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        self.reloadData()
        CATransaction.commit()
    }
}

