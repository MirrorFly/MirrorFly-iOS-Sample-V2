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

class CallUIViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    
    @IBOutlet var outgoingCallView: CallUIXib!
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
    
    var callDurationTimer : Timer?
    var qualityTimer : Timer?
    var seconds = -1
   
    var alertController : UIAlertController?
    var VideoCallConversionTimer : Timer?
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
  
    
    // MARK: View Controller Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("#lifecycle viewDidLoad")
        
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
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("#meet #lifecycle viewWillAppear")
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification
                    , object: nil)
        self.outgoingCallView?.backBtn.isHidden = false
        transformTileAndGridConstraints()
        navigationController?.setNavigationBarHidden(true, animated: false)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        ChatManager.shared.connectionDelegate = self
        CallManager.delegate = self
        CallManager.connectionQuality = self
        AudioManager.shared().audioManagerDelegate = self
        AudioManager.shared().getCurrentAudioInput()
        dismissCalled = false
        
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
                outgoingCallView?.OutGoingCallBG.image = UIImage(named: "AudioCallBG")
                self.outgoingCallView?.tileCollectionView?.isHidden = true
            }
            
            isAudioMuted = CallManager.isAudioMuted()
            isVideoMuted = CallManager.isVideoMuted()
            myCallStatus = .connected
            addMyInfoToMembersArray(videoTrack: nil)
           
            self.outgoingCallView?.cameraButton.isHidden = isVideoMuted
           
            if let collectionView = self.outgoingCallView?.tileCollectionView , (collectionView.numberOfItems(inSection: 0) == 0 || (members.count != collectionView.numberOfItems(inSection: 0))){
                self.outgoingCallView?.tileCollectionView?.reloadData()
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
            
            showHideCallBackgroundProfiles(hide: showGridView ? true : false)
            if CallManager.getCallType() == .Video {
                showHideCallBackgroundProfiles(hide: showGridView ? true : CallManager.getRemoteVideoTrack(jid: AppUtils.getMyJid()) != nil)
            }
            
            updateCallStatus(status: getStatusOfOneToOneCall())
    
            if CallManager.getCallType() == .Video && CallManager.isCallConnected() {
                showConnectedVideoCallOneToOneUI()
            }
            self.outgoingCallView?.cameraButton.isHidden = isVideoMuted
        }else{
            
            updateCallStatus(status: getCurrentCallStatusAsString())
            
//            for member in members {
//                if member.callStatus == .connected && CallManager.getCallType() == .Video {
//                    addGroupTracks(jid: member.jid)
//                }
//            }
            if isOnCall && self.checkIfGroupCallUiIsVisible() {
                showGroupCallUI()
            }
            self.outgoingCallView?.cameraButton.isHidden = isVideoMuted
        }
        
        if isOnCall && CallManager.isCallConnected(){
            seconds = UserDefaults.standard.object(forKey: "seconds") as? Int ?? -1
            updateCallDuration()
        }else{
            UserDefaults.standard.removeObject(forKey: "seconds")
        }
        
        self.showHideParticipantButton(hide : (CallManager.isCallConnected() && (myCallStatus == .connected || myCallStatus == .reconnected || myCallStatus == .onHold) && members.count != 8) ? false : true)
        showHideMenuButton(hide : (CallManager.isCallConnected() && (myCallStatus == .connected || myCallStatus == .reconnected || myCallStatus == .onHold)) ? false : true)
        isFromInvite = (isFromInvite) ? false : isFromInvite
        setTopViewsHeight()
        getContactNames()
        setButtonsActions()
        setActionIconsAfterMaximize()
        updateActionsUI()
        setMuteStatusText()
        setVideoBtnIcon()
        checkCameraPermission(sourceType: .camera)
        showRippleView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("#meet #lifecycle viewDidAppear \(CallManager.getCallMode().rawValue) || \(CallManager.isOneToOneCall()) || \(CallManager.getAllCallUsersList()) || \(CallManager.getCallType().rawValue) ||  \(members.first?.isVideoMuted) || \(members.first?.videoTrack)")
        outgoingCallView?.tileCollectionView.scrollIndicatorInsets = .zero
        ContactManager.shared.profileDelegate = self
        if reloadForInVite{
            
            outgoingCallView?.tileCollectionView.isHidden = false
            if CallManager.getCallType() == .Video && !CallManager.isOneToOneCall(){
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
        print("#lifecycle viewWillDisappear")
        super.viewWillDisappear(animated)
        if overlayShown == false {
            ContactManager.shared.profileDelegate = nil
        }
        CallManager.setMobileCallActionDelegate(delegate: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("#lifecycle viewDidDisappear")
        CallManager.delegate = RootViewController .sharedInstance
//        if callDurationTimer != nil  {
//            callDurationTimer?.invalidate()
//            callDurationTimer = nil
//            seconds = -1
//            clearViews()
//        }
        ChatManager.shared.connectionDelegate = nil
        AudioManager.shared().audioManagerDelegate = nil
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        
        if members.count > 2 && self.outgoingCallView?.tileCollectionView.visibleCells.count ?? 0 > 2 && !isScrolledToEnd {
            executeOnMainThread {
                    self.outgoingCallView?.tileCollectionView.scrollToItem(at: IndexPath(item: self.members.count - 1  , section: 0), at: .centeredHorizontally, animated: false)
                self.isScrolledToEnd = true
            }
        }
    }
    
    @objc func willEnterForeground() {
        if CallManager.getCallMode() == .MEET && members.count > 2 {
            self.outgoingCallView?.tileCollectionView.reloadData()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        showHideMenu = true
        removePopupView()
    }
    
    func updateUI () {
        
        outgoingCallView?.tileCollectionView.tag = 1111
        outgoingCallView?.tileCollectionView.isHidden = true
        outgoingCallView?.tileCollectionView.register(UINib(nibName: "TileCell", bundle: nil), forCellWithReuseIdentifier: "TileCell")
        outgoingCallView?.tileCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        outgoingCallView?.tileCollectionView.delegate = self
        outgoingCallView?.tileCollectionView.dataSource = self
        
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        if !isOnCall{
            myCallStatus = .calling
        }
        //outgoingCallView?.tileCollectionView.removeGestureRecognizer(panGesture)
        print("#call updateUI", CallManager.getAllCallUsersList())
        //enableButtons(buttons: outgoingCallView?.audioButton, isEnable: false)
        updateActionsUI()
        
        delegate = self
        showHideParticipantButton(hide :true)
        showHideMenuButton(hide: true)
        showHideCallAgainView(show: false, status: "Trying to connect")
        if CallManager.getCallDirection() == .Incoming {
            updateCallStatus(status: "Connecting")
        } else {
            updateCallStatus(status: "Trying to connect")
        }
        if CallManager.getCallMode() == .MEET && members.isEmpty{
            addMyInfoToMembersArray(videoTrack: nil)
        }
        for (memberJid,status) in CallManager.getCallUsersWithStatus() {
            _ = validateAndAddMember(jid: memberJid, with: convertCallStatus(status: status))
        }
        if CallManager.isOneToOneCall() {
            
            if CallManager.getCallType() == .Video || self.callType == .Video {
                showOneToOneVideoCallUI()
                if CallManager.isCallConnected() {
                    showConnectedVideoCallOneToOneUI()
                }
                outgoingCallView?.videoButton.setImage(UIImage(named: "ic_video_active" ), for: .normal)
            }else{
                showOneToOneAudioCallUI()
            }
        } else {
            self.outgoingCallView?.OutGoingCallBG.isHidden = true
            self.outgoingCallView?.cameraButton.isHidden = isVideoMuted
            
            if let collectionView = self.outgoingCallView?.tileCollectionView , (collectionView.numberOfItems(inSection: 0) == 0 || (members.count != collectionView.numberOfItems(inSection: 0))){
                self.outgoingCallView?.tileCollectionView.isHidden = isOnCall ? false : true
                self.outgoingCallView?.tileCollectionView.reloadData()
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
            outgoingCallView?.videoButton.setImage(UIImage(named: "ic_video_active" ), for: .normal)
            if CallManager.getCallDirection() == .Incoming {
               // _ = requestForVideoTrack()
            }
        }
        setMuteStatusText()
        if CallManager.isCallConnected(){
            isOnCall = true
            updateCallStatus(status:getStatusOfOneToOneCall())
            showHideParticipantButton(hide :false)
            showHideMenuButton(hide: false)
           enableButtons(buttons: outgoingCallView?.videoButton, isEnable: true)
        }else{
            showHideParticipantButton(hide :true)
            showHideMenuButton(hide: true)
            updateCallStatus(status: CallManager.getCallDirection() == .Incoming ? "Connecting" : "Trying to connect")
            enableButtons(buttons: outgoingCallView?.videoButton, isEnable: false)
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
    
   
    func getContactNames(){
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
            let groupMemberName = unknowGroupMembers.joined(separator: ",")
            if isConnected {
                outgoingCallView?.OutGoingPersonLabel.text = getNameStringWithGroupName(userNames: "You,\(groupMemberName)")
            }else {
                outgoingCallView?.OutgoingRingingStatusLabel.text = getNameStringWithGroupName(userNames: "You,\(groupMemberName)")
            }
            outgoingCallView?.outGoingAudioCallImageView.image = CallManager.isCallConnected() && groupId.isEmpty ? UIImage.init(named: "ic_profile_placeholder") : UIImage.init(named: "ic_groupPlaceHolder")
        } else if membersJid.count > 2{
            unknowGroupMembers.removeAll()
            for i in 0...1{
                if let contact = ChatManager.getContact(jid: membersJid[i].lowercased()){
                    unknowGroupMembers.append(getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
                }
            }
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
    
        
//        if groupId.isEmpty  && membersJid.count == 1{
//            if let contact = ChatManager.profileDetaisFor(jid: (isLocalViewSwitched) ? AppUtils.getMyJid().lowercased() : membersJid[0].lowercased()){
//                outgoingCallView?.outGoingAudioCallImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), jid: contact.jid)
//            }else{
//                outgoingCallView?.outGoingAudioCallImageView.image = UIImage.init(named: "ic_profile_placeholder")
//            }
//        }else{
//            if let contact = ChatManager.profileDetaisFor(jid: groupId.isEmpty ? (membersJid.count == 0) ? "" : membersJid[membersJid.count - 1].lowercased() : (CallManager.isCallConnected()) ? membersJid[membersJid.count - 1].lowercased() : groupId.lowercased()), !contact.image.isEmpty{
//                outgoingCallView?.outGoingAudioCallImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), jid: contact.jid)
//            }else{
//
//                if membersJid.count >= 2{
//
//                    if let contact = ChatManager.getContact(jid: groupId.isEmpty ? membersJid[membersJid.count - 1].lowercased() : (CallManager.isCallConnected()) ? membersJid[membersJid.count - 1].lowercased() : groupId.lowercased()), !contact.image.isEmpty {
//                        outgoingCallView?.outGoingAudioCallImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), jid: contact.jid)
//                    }else{
//
//                        if groupId.isEmpty {
//
//                            if let contact = ChatManager.getContact(jid: membersJid[membersJid.count - 1].lowercased()) {
//                                outgoingCallView?.outGoingAudioCallImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), jid: contact.jid)
//                            }else {
//                                outgoingCallView?.outGoingAudioCallImageView.image = UIImage.init(named: "ic_profile_placeholder")
//                            }
//
//                        }else {
//
//                            outgoingCallView?.outGoingAudioCallImageView.image = CallManager.isCallConnected() ? UIImage.init(named: "ic_profile_placeholder") : UIImage.init(named: "ic_groupPlaceHolder")
//                        }
//                    }
//                }else {
//
//                    outgoingCallView?.outGoingAudioCallImageView.image = CallManager.isCallConnected() ? UIImage.init(named: "ic_profile_placeholder") : UIImage.init(named: "ic_groupPlaceHolder")
//                }
//            }
//        }

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
            }else{
                if membersJid.count == 1 && membersJid.first != AppUtils.getMyJid() {
                    if groupId.isEmpty {
                        if let contact = ChatManager.profileDetaisFor(jid: membersJid.first ?? ""){
                            outgoingCallView?.outGoingAudioCallImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), jid: contact.jid)
                            
                            if let index = findIndexOfUser(jid: contact.jid) {
                                fullScreenUser = members[index]
                            }
                        }
                       
                    }else{
                        if let contact = ChatManager.profileDetaisFor(jid: membersJid.first ?? ""){
                            outgoingCallView?.outGoingAudioCallImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), jid: contact.jid)
                            
                            if let index = findIndexOfUser(jid: contact.jid) {
                                fullScreenUser = members[index]
                            }
                        }
                    }
                } else {
                if let contact = ChatManager.profileDetaisFor(jid: groupId.isEmpty ? (membersJid.count == 0) ? "" : membersJid[membersJid.count - 1].lowercased() : (lastMember?.callStatus == .connected || lastMember?.callStatus == .onHold) ? membersJid[membersJid.count - 1].lowercased() : (CallManager.getCallType() == .Video && members.first?.callStatus != .connected) ? members.first?.jid ?? "" : (!groupId.isEmpty && !CallManager.isCallConnected()) ? groupId : firstMember?.jid ?? ""){
                    outgoingCallView?.outGoingAudioCallImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), jid: contact.jid)
                    
                    if let index = findIndexOfUser(jid: contact.jid) {
                        if CallManager.getCallType() == .Audio || self.callType == .Audio {
                            fullScreenUser = members[index]
                        }
                    }
                }else{

                    if membersJid.count >= 2{

                        if let contact = ChatManager.getContact(jid: groupId.isEmpty ? membersJid[membersJid.count - 1].lowercased() : (lastMember?.callStatus == .connected || lastMember?.callStatus == .onHold) ? membersJid[membersJid.count - 1].lowercased() : (!groupId.isEmpty && !CallManager.isCallConnected()) ? groupId : firstMember?.jid ?? "") {
                            outgoingCallView?.outGoingAudioCallImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), jid: contact.jid)
                            if let index = findIndexOfUser(jid: contact.jid) {
                                fullScreenUser = members[index]
                            }
                        }else{

                            if groupId.isEmpty {

                                if let contact = ChatManager.getContact(jid: membersJid[membersJid.count - 1].lowercased()) {
                                    outgoingCallView?.outGoingAudioCallImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), jid: contact.jid)
                                    
                                    if let index = findIndexOfUser(jid: contact.jid) {
                                        fullScreenUser = members[index]
                                    }
                                }else {
                                    outgoingCallView?.outGoingAudioCallImageView.image = UIImage.init(named: "ic_profile_placeholder")
                                }

                            }else {

                                outgoingCallView?.outGoingAudioCallImageView.image = CallManager.isCallConnected() ? UIImage.init(named: "ic_profile_placeholder") : UIImage.init(named: "ic_groupPlaceHolder")
                            }
                        }
                    }else {
                        outgoingCallView?.outGoingAudioCallImageView.image = CallManager.isCallConnected() ? UIImage.init(named: "ic_profile_placeholder") : UIImage.init(named: "ic_groupPlaceHolder")
                    }
                }
            }
        }
    }
    }
    
    func getNameStringWithGroupName(userNames : String) -> String{
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
        DispatchQueue.main.async { [weak self] in
            if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (self?.members.count == 1 || self?.members.count == 2)) {
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
                    self?.outgoingCallView?.audioWaveView.isHidden = true
                    
                }else {
                    
                    self?.outgoingCallView?.audioCallMutedIcon.isHidden = (remoteAudioMuted && CallManager.getCallType() == .Audio) ? false : true
                    
                    self?.outgoingCallView?.audioWaveView.isHidden = (self?.myCallStatus == .tryagain) ? true : (remoteAudioMuted && CallManager.getCallType() == .Audio) || (CallManager.getCallType() == .Video && remoteVideoMuted && remoteAudioMuted) || (CallManager.getCallType() == .Video && !remoteVideoMuted) ? true : false
                    print("audioWaveView.isHidden 4 \((self?.myCallStatus == .tryagain) ? true : (remoteAudioMuted && CallManager.getCallType() == .Audio) || (CallManager.getCallType() == .Video && remoteVideoMuted && remoteAudioMuted) || (CallManager.getCallType() == .Video && !remoteVideoMuted) ? true : false)")

                    let callStatus = self?.getCurrentCallStatusAsString()
                    let isConnected = (callStatus == "Trying to connect" || callStatus == "Unavailable, Try again later" || callStatus == "Ringing") ? false : true
                    
                    if !isConnected && ((self?.groupId.isEmpty) != nil) && self?.members.count ?? 0 > 2 {
                        self?.outgoingCallView?.audioWaveView.isHidden = true
                    }
                    
                }
                    
                
            }else {
                
                if self?.showGridView ?? false {
                    
                    self?.outgoingCallView?.audioMuteStackView.isHidden = true
                    self?.outgoingCallView?.audioCallMutedIcon.isHidden = true
                    self?.outgoingCallView?.audioWaveView.isHidden = true
                    
                }else {
                    
                    let callStatus = self?.getCurrentCallStatusAsString()
                    let isConnected = (callStatus == "Trying to connect" || callStatus == "Unavailable, Try again later" || callStatus == "Ringing") ? false : true
                    
                    self?.outgoingCallView?.audioMuteStackView.isHidden = true

                    if (self?.members.count ?? 0) > 2 {
                       // self?.outgoingCallView?.audioCallMutedIcon.isHidden = self?.members[(self?.members.count ?? 0) - 2].isAudioMuted ?? false ? false : true
                        self?.outgoingCallView?.audioCallMutedIcon.isHidden = self?.fullScreenUser.isAudioMuted ?? false ? false : true
                        
                        if (self?.members[(self?.members.count ?? 0) - 2].isVideoMuted ?? false) == false {
                            self?.outgoingCallView?.audioWaveView.isHidden = true
                        } else {
                            self?.outgoingCallView?.audioWaveView.isHidden = (self?.myCallStatus == .tryagain) ? true : (self?.members[(self?.members.count ?? 0) - 2].isAudioMuted ?? false && CallManager.getCallType() == .Audio) || (self?.members[(self?.members.count ?? 0) - 2].isAudioMuted ?? false && CallManager.getCallType() == .Video && self?.members[(self?.members.count ?? 0) - 2].isVideoMuted ?? false) || (CallManager.getCallType() == .Video && !(self?.members[(self?.members.count ?? 0) - 2].isVideoMuted ?? false)) ? true : false
                        }
                        //|| (CallManager.getCallType() == .Audio && !(self?.members[(self?.members.count ?? 0) - 2].isVideoMuted ?? false))
                        print("audioWaveView.isHidden 5 \((self?.myCallStatus == .tryagain)) - \((self?.members[(self?.members.count ?? 0) - 2].isAudioMuted ?? false && CallManager.getCallType() == .Audio)) - \((self?.members[(self?.members.count ?? 0) - 2].isAudioMuted ?? false && CallManager.getCallType() == .Video && self?.members[(self?.members.count ?? 0) - 2].isVideoMuted ?? false)) - \((CallManager.getCallType() == .Video && !(self?.members[(self?.members.count ?? 0) - 2].isVideoMuted ?? false))) - final = \((self?.myCallStatus == .tryagain) ? true : (self?.members[(self?.members.count ?? 0) - 2].isAudioMuted ?? false && CallManager.getCallType() == .Audio) || (self?.members[(self?.members.count ?? 0) - 2].isAudioMuted ?? false && CallManager.getCallType() == .Video && self?.members[(self?.members.count ?? 0) - 2].isVideoMuted ?? false) || (CallManager.getCallType() == .Video && !(self?.members[(self?.members.count ?? 0) - 2].isVideoMuted ?? false)) ? true : false)")
                    }
                    
                    if !isConnected && ((self?.groupId.isEmpty) != nil) && self?.members.count ?? 0 > 2 {
                        self?.outgoingCallView?.audioWaveView.isHidden = true
                    }
                    
                }
            }
        }
    }
    
}

// MARK: Setup UI for Audio/Video Call
extension CallUIViewController {

    func showOneToOneAudioCallUI() {
        print("#call showOneToOneAudioCallUI")
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
                updateCallStatus(status: (CallManager.isCallConnected() && !CallManager.isOneToOneCall()) ? CallStatus.connected.rawValue :  getStatusOfOneToOneCall())
            }
            setMuteStatusText()
            showHideParticipantButton(hide :false)
            showHideDuration(hide: false)
            showHideMenuButton(hide: false)
        }
        validateReconnectingStatus()
    }
    
    func showOneToOneVideoCallUI() {
        print("#call showOneToOneVideoCallUI")
        outgoingCallView?.remoteUserVideoView.isHidden = false
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
        outgoingCallView?.OutGoingCallBG.image = CallManager.getRemoteVideoTrack(jid: AppUtils.getMyJid())  != nil  ? nil : UIImage(named: "AudioCallBG")
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
    }
    
    func showConnectedVideoCallOneToOneUI() {
        outgoingCallView?.remoteUserVideoView.isHidden = false
        isCallConversionRequestedByMe = false
        //self.localRenderer.frame = CGRect(x: 0, y: 0, width: 110, height: 160)
        showHideDuration(hide:  false)
        
        if CallManager.isCallConnected() {
            getContactNames()
            showHideParticipantButton(hide : false)
            showHideMenuButton(hide: false)
//            let gesture = UIPanGestureRecognizer()
//            gesture.state = .ended
//            draggedCollectionView(gesture)
            
            if !(members.last?.isVideoMuted ?? false) && !(members.first?.isVideoMuted ?? false) {
                videoTapGesture = UITapGestureRecognizer(target: self, action: #selector(smallVideoTileTapped(_:)))
                outgoingCallView?.tileCollectionView?.addGestureRecognizer(videoTapGesture)
            }
        }
        setVideoBtnIcon()
    }
    
    func showGroupCallUI() {
        
        if CallManager.getCallType() == .Video {
            showOneToOneVideoCallUI()
            addRemoteTrackToView()
        }else {
            showOneToOneAudioCallUI()
        }
        getContactNames()
        //outgoingCallView?.tileCollectionView.removeGestureRecognizer(panGesture)
        setupTileViewConstraints(isRemoveUser: false)
        outgoingCallView?.tileCollectionView.reloadData()
        validateReconnectingStatus()
    }
    
}

// MARK: Setup Actions for Audio/Video Call
extension CallUIViewController {
    
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
    
    @objc func draggedCollectionView(_ sender:UIPanGestureRecognizer){
        
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
        outgoingCallView?.tileCollectionView.isHidden = true
    }
    
    func updateActionsUI() {
        enableDisableUserInteractionFor(view: outgoingCallView?.AttendingBottomView, isDisable: false)
        outgoingCallView?.videoButton.setImage(UIImage(named: isVideoMuted ? "ic_video_inactive" :  "ic_video_active" ), for: .normal)
        outgoingCallView?.audioButton.setImage(UIImage(named: isAudioMuted ? "IconAudioOn" :  "IconAudioOff" ), for: .normal)
        outgoingCallView?.cameraButton.setImage(UIImage(named: isBackCamera ? "IconCameraOn" :  "IconCameraOff" ), for: .normal)
    }
    
    @objc func backAction(sender: UIButton?) {
        showCallOverlay()
        dismiss(animated: true)
    }
    
    @objc func cancelBtnTapped(sender:UIButton) {
        dismissWithDelay()
        dismissCallUI()
    }
    
    @objc func callEndlBtnTapped(sender:UIButton) {
        dismissWithDelay()
        CallManager.disconnectCall()
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
                    }else {
                        CallManager.setCallType(callType: isVideoMuted ? .Audio : .Video)
                    }
                }
                delegate?.onVideoMute(status: isVideoMuted)
            }
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
                    AppPermissions.shared.presentSettingsForPermission(permission: .camera, instance: self as Any)
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
        
        if NetworkReachability.shared.isConnected {
            if CallManager.isAlreadyOnAnotherCall(){
                AppAlert.shared.showToast(message: "You’re already on call, can't make new MirrorFly call")
                return
            }
//            CallManager.disconnectCall()
            myCallStatus = .calling
            showHideCallAgainView(show: false, status: "Trying to connect")
            
//            let callAgainaMembers = members.compactMap{$0.jid}
//            removeAllMembers()
            makeCall(usersList: callAgainMembers.compactMap{$0.jid}, callType: callType, groupId: self.groupId, onCompletion: { isSuccess, message in
                if(!isSuccess){
                    let errorMessage = AppUtils.shared.getErrorMessage(description: message)
                    AppAlert.shared.showAlert(view: self, title: "", message: errorMessage, buttonTitle: "Okay")
                }
            })
        }else {
            AppAlert.shared.showToast(message: ErrorMessage.checkYourInternet)
        }
    }
    
    @objc func CameraButtonTapped(sender:UIButton) {
        isBackCamera.toggle()
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
        if CallManager.isCallOnHold(){
            return
        }
        isAudioMuted.toggle()
        members.last?.isAudioMuted = isAudioMuted
        delegate?.onAudioMute(status: isAudioMuted)
    }
    
    @objc func SingleTapGesturTapped(_ sender: UITapGestureRecognizer) {
        
        showHideMenu = true
        removePopupView()
        
        if CallManager.isCallConnected(){
            
            if isTapped == false{
                isTapped = true
                let bottom = CGAffineTransform(translationX: 0, y: 200)
                let top = CGAffineTransform(translationX: 0, y: -400)
                let collectionBottom = CGAffineTransform(translationX: 0, y: showGridView ? 0 : 150)
                
                UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
//                    if !CallManager.isOneToOneCall() || CallManager.getCallType() == .Video{
//                                            self.outgoingCallView?.AttendingBottomView.transform = bottom
//                                            self.outgoingCallView?.OutGoingPersonLabel.transform = top
//                                            self.outgoingCallView?.timerLable.transform = top
//                                            self.outgoingCallView?.outGoingAudioCallImageView.transform = top
//                                            self.outgoingCallView?.OutgoingRingingStatusLabel?.transform = top
//                    }
                    self.outgoingCallView?.AttendingBottomView.transform = bottom
                    self.outgoingCallView?.tileCollectionView.transform = collectionBottom
                }, completion: nil)
            }else{
                isTapped = false
                let top = CGAffineTransform(translationX: 0, y: showGridView ? 0 : -20)
                let bottom = CGAffineTransform(translationX: 0, y: 0)
                
                let collectionTop = CGAffineTransform(translationX: 0, y: showGridView ? 0 : -20)
                
                let viewMaxY = safeAreaHeight - 172
                //            if let localView = self.outgoingCallView?.localUserVideoView{
                //                if localView.frame.maxY > viewMaxY {
                //                    let gesture = UIPanGestureRecognizer()
                //                    gesture.state = .ended
                //                    if isOnCall{
                //                        //draggedView(gesture)
                //                        draggedCollectionView(gesture)
                //                    }
                //                }
                //            }
                
                UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
                    //                if CallManager.getCallType() == .Video !CallManager.isOneToOneCall() {
                    //                    self.outgoingCallView?.imageHeight.constant = 0
                    //                    self.outgoingCallView?.timerTop.constant = 0
                    //                }else{
                    //                    self.outgoingCallView?.imageHeight.constant = 100
                    //                    self.outgoingCallView?.timerTop.constant = 8
                    //                    self.outgoingCallView?.outGoingAudioCallImageView.transform = bottom
                    //                }
                    //                self.outgoingCallView?.AttendingBottomView.transform = top
                    //                self.outgoingCallView?.AttendingBottomView.transform = top
                    //                self.outgoingCallView?.OutGoingPersonLabel.transform = bottom
                    //                self.outgoingCallView?.timerLable.transform = bottom
                    //                self.outgoingCallView?.OutgoingRingingStatusLabel?.transform = bottom
                    
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
        //showConfirmationAlertForCallSwitching
        alertController?.dismiss(animated: false)
        alertController = UIAlertController.init(title: nil , message: "Are you sure you want to switch to Video Call", preferredStyle: .alert)
        let switchAction = UIAlertAction(title: "Switch", style: .default) { [weak self] (action) in
            CallManager.requestVideoCallSwitch { isSuccess in
                if isSuccess {
                    self?.isCallConversionRequestedByMe = true
                    self?.showAlertViewWithIndicator()
                    self?.VideoCallConversionTimer = Timer.scheduledTimer(timeInterval: 20, target: self ?? CallUIViewController.self, selector: #selector(self?.videoCallConversionTimer), userInfo: nil, repeats: false)
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
                self?.showOneToOneAudioCallUI()
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
                    CallManager.setCallType(callType: .Video)
                    self?.showHideCallBackgroundProfiles(hide: true)
                    CallManager.acceptVideoCallSwitchRequest()
                    self?.isVideoMuted = false
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
                self?.showOneToOneAudioCallUI()
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
            showOneToOneAudioCallUI()
            CallManager.cancelVideoCallSwitch()
        }
    }
    
    func resetConversionTimer(){
        VideoCallConversionTimer?.invalidate()
        VideoCallConversionTimer = nil
        alertController?.dismiss(animated: true, completion: nil)
        isCallConversionRequestedByRemote = false
    }
    
    func switchAudioToVideoCall() {
        CallManager.setCallType(callType: .Video)
        switchLoaclandRemoteViews()
        showOneToOneVideoCallUI()
        setVideoBtnIcon()
        resetConversionTimer()
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

        overlayShown = false
        ContactManager.shared.profileDelegate = self
        callViewOverlay.removeFromSuperview()
        getContactNames()
        outgoingCallView?.tileCollectionView.reloadData()
        
        for member in members.map({$0.jid!}) {
            addGroupTracks(jid: member)
        }
        
        let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if let rootVC = window?.rootViewController {
            let navigationStack = UINavigationController(rootViewController: self)
            navigationStack.setNavigationBarHidden(true, animated: true)
            navigationStack.modalPresentationStyle = .overFullScreen
            rootVC.present(navigationStack, animated: true, completion: nil)
        }
    }
    
}

// MARK: Call Disconnection & Call Again UI Updates
extension CallUIViewController {
    
    func clearViews() {
        showHideParticipantButton(hide : true)
        showHideMenuButton(hide: true)
        showHideDuration(hide: true)
        outgoingCallView?.audioMuteStackView.isHidden = true
        print("#mute clearViews \(isAudioMuted) video \(isVideoMuted) ")
        updateActionsUI()
    }
    
    
    func showHideCallAgainView(show: Bool,status: String) {
        if outgoingCallView != nil{
            //self.outgoingCallView?.tileCollectionView.removeGestureRecognizer(panGesture)
            self.outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = status.isEmpty
            updateCallStatus(status: CallManager.isCallConnected() ? CallStatus.connected.rawValue : status )
            if show {
                
                if overlayShown {
                    callViewOverlay.removeFromSuperview()
                }
                if !members.isEmpty{
                    callAgainMembers = members
                }
                
                self.removeAllMembers()
                
                self.outgoingCallView?.audioWaveView.isHidden = true
                self.outgoingCallView?.AttendingBottomView.isHidden = true
                self.outgoingCallView?.callAgainView.isHidden = false
                self.showHideParticipantButton(hide:  true)
                self.showHideMenuButton(hide: true)
                
                if callType == .Audio {
                    self.outgoingCallView?.CallAgainButton.setImage(UIImage(named: "callAgain"), for: .normal)
                }else{
                    self.outgoingCallView?.CallAgainButton.setImage(UIImage(named: "call again_ic"), for: .normal)
                }
                self.outgoingCallView?.callAgainView.backgroundColor = UIColor(hexString: "151F32")
                self.outgoingCallView?.backBtn.isHidden = true
                if overlayShown {
                    dismiss()
                    overlayShown = false
                }
            } else {
                self.outgoingCallView?.callAgainView.isHidden = true
                self.outgoingCallView?.AttendingBottomView.isHidden = false
                self.outgoingCallView?.backBtn.isHidden = false
            }
        }
    }
    
    func dismiss() {
        print("#lifecycle dismiss")
        
    }
    
    func resetVariables(){
        callDurationTimer?.invalidate()
        isOnCall = false
        isLocalViewSwitched = false
        reloadForInVite = false
        isBackCamera = false
        isVideoMuted = false
        isAudioMuted = false
        seconds = -1
        groupId = ""
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
    }
    
    func dismissCallUI(){
        if CallManager.getCallMode() == .MEET {
            for controller in (navigationController?.viewControllers ?? []) as Array {
                if controller.isKind(of: ChatViewParentController.self) {
                    navigationController!.popToViewController(controller, animated: true)
                    break
                }
            }
        }
        outgoingCallView?.reconnectingLable?.text = emptyString()
        outgoingCallView?.timerLable.isHidden = true
        outgoingCallView?.timerLable.text = ""
        outgoingCallView?.OutGoingPersonLabel.text = ""
        showHideDuration(hide: true)
        myCallStatus = .calling
        currentCallStatus = .CALLING
        outgoingCallView?.qualityView?.isHidden = true
        outgoingCallView?.qualityIcon?.isHidden = true
        CallUIViewController.isQualityToastShowing = false
        let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if let navigationController = window?.rootViewController as? UINavigationController,let presented = navigationController.presentedViewController {
            window?.rootViewController?.dismiss(animated: true)
        }else{
            dismiss(animated: true, completion: nil)
        }
        if dismissCalled == false {
            CallUIViewController.dismissDelegate?.onCallControllerDismissed()
        }
        dismissCalled = true
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func dismissWithDelay(callStatus : String = "Disconnected"){
        resetVariables()
        enableDisableUserInteractionFor(view: outgoingCallView?.AttendingBottomView, isDisable: true)
        CallManager.incomingUserJidArr.removeAll()
        callDurationTimer = nil
        outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = true
        outgoingCallView?.OutGoingPersonLabel?.isHidden = false
        outgoingCallView?.OutGoingPersonLabel?.text = callStatus
        UserDefaults.standard.removeObject(forKey: "seconds")
        showHideParticipantButton(hide : true)
        showHideMenuButton(hide: true)
        outgoingCallView?.audioMuteStackView.isHidden = true
        outgoingCallView?.callAgainView.isHidden = true
        outgoingCallView?.backBtn.isHidden = true
        outgoingCallView?.reconnectingLable?.isHidden = true
        remoteRenderer.removeFromSuperview()
        callViewOverlay.removeFromSuperview()
        outgoingCallView?.remoteUserVideoView.willRemoveSubview(remoteRenderer)
        removePopupView()
        resetLocalVideCallUI()
        removeRemoteOneToOneLocalTracks()
        for view in outgoingCallView?.remoteUserVideoView?.subviews ?? [] {
            view.removeFromSuperview()
        }
        audioDevicesAlertController?.dismiss(animated: true, completion: {
            self.audioDevicesAlertController = nil
        })
        alertController?.dismiss(animated: true, completion: nil)
        if ((audioPlayer) != nil) {
            if ((audioPlayer?.isPlaying) != nil) {
                audioPlayer?.stop()
            }
            audioPlayer = nil
        }
        
            isTapped = false
            let top = CGAffineTransform(translationX: 0, y: showGridView ? 0 : -20)
            UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
                self.outgoingCallView?.AttendingBottomView.transform = top
                self.outgoingCallView?.tileCollectionView.transform = top
            }, completion: nil)
        showHideQualityView(show: false)
    }
}

// MARK: Collection View Delegate & DataSource

extension CallUIViewController : UICollectionViewDelegate , UICollectionViewDataSource , UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(members.count)
        
        if members.count > 0 {
            if (members.count == 8) || CallManager.getCallMode() == .MEET {
                showHideParticipantButton(hide :true)
            }
            
            // return showGridView ? members.count : (CallManager.isOneToOneCall()) ? 1 : members.count
            
            // return showGridView ? members.count : (CallManager.isOneToOneCall()) ? 1 : members[members.count - 2].callStatus != .connected ? members.count - 1 : members.count
            
            if (CallManager.getCallMode() == .MEET) {
                switch members.count {
                case 0,1:
                    return 0
                case 2:
                    return showGridView ? members.count : 1
                default :
                    return showGridView ? members.count : (CallManager.isOneToOneCall()) ? 1 : members.count > 2 ? members[members.count - 2].callStatus != .connected ? members.count : members.count : members.count
                }
            } else {
                return  showGridView ? members.count : (CallManager.isOneToOneCall()) ? 1 : members.count > 2 ? members[members.count - 2].callStatus != .connected ? members.count : members.count : members.count
            }
        }else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            
        let tileCell = collectionView.dequeueReusableCell(withReuseIdentifier: "TileCell", for: indexPath) as! TileCell
        if members.count > 0 && members.count > indexPath.item {
            
            var member = members[indexPath.item]
            
            if CallManager.isOneToOneCall() && !showGridView {
                if isLocalViewSwitched{
                    member = members.first ?? CallMember()
                }else {
                    if let index = findIndexOfUser(jid: AppUtils.getMyJid()) {
                        member = members[index]
                    }
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
            
            if (member.jid == fullScreenUser.jid && !showGridView && !CallManager.isOneToOneCall()) {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
                return cell
            }else {
                
                //            let isLastRow = (CallManager.getCallMode() == .MEET && (members.count == 1 || members.count == 2) && !showGridView) ? true : (CallManager.isOneToOneCall() && !showGridView) ? true : members[members.count - 2].callStatus != .connected ? (indexPath.item == members.count - 2) : (indexPath.item == members.count - 1)
                
                let isLastRow = (CallManager.getCallMode() == .MEET && (members.count == 1 || members.count == 2) && !showGridView) ? true : (CallManager.isOneToOneCall() && !showGridView) ? true : (indexPath.item == members.count - 1)
                
                let callStatus =  isLastRow ? (CallManager.getCallStatus(userId: member.jid) == .ON_HOLD  ? .onHold : .connected) : convertCallStatus(status: CallManager.getCallStatus(userId: member.jid))
                if member.jid == AppUtils.getMyJid() && CallManager.getCallStatus(userId: member.jid) == .ON_HOLD{
                    _ = updateCallStatus(jid: member.jid, status: .onHold)
                }
                tileCell.setupDataForTileCell(tileCell: tileCell, indexPath: indexPath, members: members, member: member, isBackCamera: isBackCamera, showGridView: showGridView, callStatus: callStatus)
                return tileCell
            }
        }
        return tileCell
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
                
//                let callMember = members[indexPath.item]
//                if (CallManager.isOneToOneCall()) {
//                    return CGSize(width: 110, height: 160)
//                }
//                if (indexPath.item == members.count - 2 && callMember.callStatus == .connected) {
//                    return CGSize(width: 0, height: 0)
//                }
//                else if (callMember == members.first(where: {$0.callStatus == .connected})) {
//                    return CGSize(width: 0, height: 0)
//                }
                
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
                
//                    if (indexPath.item == index && members[members.count - 2].callStatus != .connected && callMember.jid != AppUtils.getMyJid()) {
//                        return CGSize(width: 0, height: 0)
//                    } else if (indexPath.item == members.count - 2 && callMember.callStatus == .connected) {
//                        return CGSize(width: 0, height: 0)
//                    } else {
//                        return CGSize(width: 110, height: 160)
//                    }
                    if (callMember.jid == fullScreenUser.jid) {
                        return CGSize(width: 0, height: 0)
                    } else {
                        return CGSize(width: 110, height: 160)
                    }
                }
                
//                return (!CallManager.isOneToOneCall()) ?  (indexPath.item == members.count - 2 && callMember.callStatus == .connected) || (indexPath.item == 0 && members[members.count - 2].callStatus != .connected) ? CGSize(width: 0, height: 0) : CGSize(width: 110, height: 160) : CGSize(width: 110, height: 160)
                    
//                    return (!CallManager.isOneToOneCall()) ?  (indexPath.item == members.count - 2 && callMember.callStatus == .connected) ? CGSize(width: 0, height: 0) : CGSize(width: 110, height: 160) : CGSize(width: 110, height: 160)
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
    
        if CallManager.isCallOnHold(){
            return
        }
        print("#mute status \(status)")
        CallManager.muteVideo(status)
        members.last?.isVideoMuted = status
        
        if status && CallManager.isOneToOneCall() && myCallStatus != .reconnecting {
            isLocalViewSwitched = false
            addRemoteTrackToView()
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

        if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && members.count == 2) {
            setVideoBtnIcon()
            outgoingCallView?.cameraButton.isHidden = isVideoMuted
            setMuteStatusText()
            outgoingCallView?.tileCollectionView.reloadData()
            
            
            if status {
                
//                for recognizer in outgoingCallView?.tileCollectionView.gestureRecognizers ?? [] {
//                    outgoingCallView?.tileCollectionView.removeGestureRecognizer(recognizer)
//                }
                outgoingCallView?.tileCollectionView.removeGestureRecognizer(videoTapGesture)
                
            }else{
                
                if !(members.last?.isVideoMuted ?? false) && !(members.first?.isVideoMuted ?? false) {
                    
                    videoTapGesture = UITapGestureRecognizer(target: self, action: #selector(smallVideoTileTapped(_:)))
                    outgoingCallView?.tileCollectionView?.addGestureRecognizer(videoTapGesture)
                }
            }
            
        } else {
            setVideoBtnIcon()
            outgoingCallView?.cameraButton.isHidden = isVideoMuted
            if !isVideoMuted {
                if (CallManager.getCallMode() == .MEET && members.count == 1){
                    if let track = members.first?.videoTrack {
                        self.addlocalTrackToView(videoTrack: track)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.showHideCallBackgroundProfiles(hide: true)
                        }
                    }
                }else{
                    addGroupTracks(jid: AppUtils.getMyJid())
                }
            } else {
                if (CallManager.getCallMode() == .MEET && members.count == 1){
                    removeRemoteOneToOneLocalTracks()
                    showHideCallBackgroundProfiles(hide: showGridView ? true : false)
                    if let isAudioMute = members.first?.isAudioMuted {
                        outgoingCallView?.audioWaveView.isHidden = isAudioMute
                    }
                } else {
                    if let index = findIndexOfUser(jid: AppUtils.getMyJid()) {
                        updateVideoMuteStatus(index: index, userid: AppUtils.getMyJid(), isMute: status)
                    }
                }
            }
            AudioManager.shared().autoReRoute()
        }
    }
    
    func onAudioMute(status:Bool) {
        outgoingCallView?.audioButton.setImage(UIImage(named: isAudioMuted ? "IconAudioOn" :  "IconAudioOff" ), for: .normal)
        CallManager.muteAudio(status)
        members.last?.isAudioMuted = status
        updateSpeakingUI(userId: AppUtils.getMyJid(), isSpeaking: !status)
    }
    
    func setActionIconsAfterMaximize() {
        isAudioMuted = CallManager.isAudioMuted()
        isBackCamera = members.last?.isOnBackCamera ?? false
        isVideoMuted = CallManager.isVideoMuted()
        if CallManager.getCallType() == .Audio {
            self.outgoingCallView?.speakerButton.isHidden = false
        } else {
            self.outgoingCallView?.speakerButton.isHidden = true
        }
        //AudioManager.shared().getCurrentAudioInput()
    }
    
    func onSwitchCamera(completion: @escaping () -> Void) {
        CallManager.switchCamera(completion: completion)
        outgoingCallView?.cameraButton.setImage(UIImage(named: isBackCamera ? "IconCameraOn" :  "IconCameraOff" ), for: .normal)
    }
}


// MARK: Make Audio/Video call from call again view

extension CallUIViewController {
    
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
        addMyInfoToMembersArray(videoTrack: nil)
        for userJid in usersList where userJid != AppUtils.getMyJid() {
            let _ = addRemoteMembers(for: ChatManager.getContact(jid: userJid.lowercased())!)
        }
        var membersJid = members.compactMap { $0.jid }
        showHideCallAgainView(show: false, status: "Trying to connect")
        if callType == .Audio {
            if members.count == 2 && groupId.isEmpty{
                try! CallManager.makeVoiceCall(members.first!.jid) { [weak self] (isSuccess , message)  in
                    if isSuccess == false {
                        let errorMessage = message?.description ?? emptyString()
                        AppAlert.shared.showAlert(view: self!, title: "", message: errorMessage, buttonTitle: "Okay")
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
                membersJid.remove(at: members.count - 1)
                try! CallManager.makeGroupVoiceCall(membersJid, groupID: groupId) {[weak self] isSuccess , message in
                    if isSuccess == false {
                        let errorMessage = message?.description ?? emptyString()
                        AppAlert.shared.showAlert(view: self!, title: "", message: errorMessage, buttonTitle: "Okay")
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
                membersJid.remove(at: members.count - 1)
                try! CallManager.makeGroupVideoCall(membersJid, groupID: groupId) { [weak self] (isSuccess, message) in
                    if isSuccess == false {
                        let errorMessage = message?.description ?? emptyString()
                        AppAlert.shared.showAlert(view: self!, title: "", message: errorMessage, buttonTitle: "Okay")
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
        print("onRemoteVideoTrackAdded", userId)
        print("onRemoteVideoTrackAddedOneToOne", CallManager.isOneToOneCall())
        executeOnMainThread {
            self.outgoingCallView?.tileCollectionView?.performBatchUpdates {
                if !CallManager.isOneToOneCall() {
//                    if let index = self.findIndexOfUser(jid: userId) {
//                        let speakingMember = self.members[index]
//                        self.members.remove(at: index)
//                        self.members.insert(speakingMember, at: self.members.count - 1)
//
//                        let sourceIndex = IndexPath(item: index, section: 0)
//                        let destinationIndex = IndexPath(item:  self.members.count - 2, section: 0)
//                        self.outgoingCallView?.tileCollectionView.performBatchUpdates({
//                            self.outgoingCallView?.tileCollectionView.moveItem(at: sourceIndex, to: destinationIndex)
//                        })
//                    }
                    self.setMuteStatusText()
                }

                self.updateMuteStatusOfUser(userId: userId)
                if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (self.members.count == 1 || self.members.count == 2))  {
                    if self.members.first?.jid == userId{
                        self.members.first?.videoTrack = track
                    }
                    self.outgoingCallView?.remoteUserVideoView.isHidden = false
                    self.addRemoteTrackToView()
                } else {
                    executeOnMainThread {
                        self.setupTileViewConstraints(isRemoveUser: false)
                        self.outgoingCallView?.tileCollectionView.reloadData()
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.members.forEach { member in
                            self.addGroupTracks(jid: member.jid)
                        }
                    }

                    self.outgoingCallView?.remoteUserVideoView.isHidden = false
                    self.addRemoteTrackToView()
                    
//                    if let index = self.findIndexOfUser(jid: userId){
//                        self.fullScreenUser = self.members[index]
//                    }
                }
                self.setVideoBtnIcon()
                self.outgoingCallView?.tileCollectionView.reloadData()
            }
            if let index = self.findIndexOfUser(jid: userId), self.showGridView{
                self.outgoingCallView?.tileCollectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
            }
        }
    }
    
    func onLocalVideoTrackAdded(userId: String, videoTrack: RTCVideoTrack) {
        print("###T #meet #call onLocalVideoTrackAdded() : \(userId)")
        updateMuteStatusOfUser(userId: userId)
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
//                            if let collectionView = self.collectionView{
//                                self.outgoingCallView?.OutGoingCallBG.isHidden = true
//                                self.collectionView.isHidden = false
//                                if collectionView.numberOfItems(inSection: 0) == 0{
//                                    self.collectionView?.isHidden = false
//                                    self.collectionView?.reloadData()
//                                }
//                            }
                            //self.addGroupTracks(jid: userId)
                            //self.addlocalTrackToView(videoTrack: videoTrack)
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
           // if self.outgoingCallView != nil {
                if let localView = self.outgoingCallView?.remoteUserVideoView {
                    self.outgoingCallView?.remoteUserVideoView.isHidden = false
//                    self.localRenderer.removeFromSuperview()
//                    localView.willRemoveSubview(self.localRenderer)
                    #if arch(arm64)
                    let localRen = RTCMTLVideoView(frame: .zero)
                    #else
                    let localRen = RTCEAGLVideoView(frame: .zero)
                    #endif
//                    self.localRenderer = localRen
//                    self.localRenderer.frame = CGRect(x: 0, y: 0, width: localView.bounds.width, height: localView.bounds.height)
//                    localView.addSubview(self.localRenderer)
                    localRen.frame = CGRect(x: 0, y: 0, width: localView.bounds.width, height: localView.bounds.height)
                    localView.addSubview(localRen)
                    videoTrack.add(localRen)
                }
         //   }
        }
    }
    
    func addRemoteTrackToView() {
        guard members.count > 1 else { return }
        var userJID = members[members.count - 2].jid
        guard userJID != AppUtils.getMyJid() else { return }
        if (members[members.count - 2].callStatus != .connected) {
            
            let firstMember = members.first(where: {$0.callStatus == .connected})
            userJID = firstMember?.jid
        }
        
        if let remoteView = self.outgoingCallView?.remoteUserVideoView, let jid = CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (members.count == 1 || members.count == 2)) ? members.first?.jid : userJID, let videoTrack = CallManager.getRemoteVideoTrack(jid: jid) {
            
            for view in self.outgoingCallView?.remoteUserVideoView?.subviews ?? [] {
                view.removeFromSuperview()
            }
            
            videoTrack.remove(self.remoteRenderer)
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
            if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (members.count == 1 || members.count == 2)) {
                self.members.first?.videoTrack = videoTrack
            }else {
                if members.count > 2 {
                    self.members[members.count - 2].videoTrack = videoTrack
                    self.fullScreenUser = self.members[members.count - 2]
                }
            }
            
            showHideCallBackgroundProfiles(hide: showGridView ? true : members.count > 2 ? members[members.count - 2].isVideoMuted ? false : true : true)
            setMuteStatusText()
            validateReconnectingStatus()
        }
    }
    
    func addMyInfoToMembersArray(videoTrack: RTCVideoTrack?) {
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
       // callMember.isVideoMuted = CallManager.getMuteStatus(jid: AppUtils.getMyJid(), isAudioStatus: false) //CallManager.getCallType() == .Audio
        callMember.isVideoMuted = CallManager.getMuteStatus(jid: user.jid, isAudioStatus: false) //CallManager.getCallType() == .Audio
        callMember.isVideoTrackAdded = false
       // remoteImage = remoteUserProfile?.image ?? user.image
        if let index = findIndexOfUser(jid: user.jid){
            return index
        }else {
            members.insert(callMember, at:  members.count >= 2 ? (members.count - 2) : 0 ) //0
            setupTileViewConstraints(isRemoveUser: false)
            return 0
        }
    }
    
    func onVideoTrackAdded(userJid: String) {
        
    }
    
    func getDisplayName(IncomingUser :[String], incomingUserName: String, metaData: [CallMetadata]) -> [String] {
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
                    userString.append(pd?.name ?? "User")
                }
            }
            print("#names \(userString)")
        }
            return userString
    }
    
    func getGroupName(_ groupId : String) {
        
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
    
//    func sendCallMessage( groupCallDetails : GroupCallDetails , users: [String], invitedUsers: [String]) {
//        try? FlyMessenger.sendCallMessage(for: groupCallDetails, users : users , inviteUsers: invitedUsers) { isSuccess, flyError, flyData in
//            var data  = flyData
//            if isSuccess {
//                print(data.getMessage() as? String ?? "")
//            } else{
//                print(data.getMessage() as! String)
//            }
//        }
//    }
    
    func socketConnectionEstablished() {
        
    }
    
    func onCallStatusUpdated(callStatus: CALLSTATUS, userId: String) {
        print("STEP #call onCallStatusUpdated \(callStatus.rawValue) userJid : \(userId) memersCount : \(members.count)")
        addUsers(callStatus: callStatus, userId: userId)
        CallUIViewController.refreshDelegate?.refreshCallLog()
        currentCallStatus = callStatus
        updateMuteStatusOfUser(userId: userId)
        DispatchQueue.main.async { [weak self] in

//            if userId == AppUtils.getMyJid() && (callStatus != .RECONNECTING && callStatus != .RECONNECTED && callStatus != .ON_HOLD && callStatus != .ON_RESUME && callStatus != .DISCONNECTED) {
//                return
//            }

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
                    self?.showHideDuration(hide: true)
                    self?.getContactNames()
                }
                if CallManager.isOneToOneCall() {
                    self?.setupTopViewConstraints()
                } else if (self?.isOnCall ?? false) {
                    self?.addUpdateCallUsersWithStatus(userJid: userId, status: .ringing, reload: true)
                }
                
            case .ATTENDED:
                print("#STA= #callStatus onCallStatus ====  .ATTENDED \(userId) ")
                self?.setHoldText(isShow: false)
                if !(self?.isOnCall ?? true){
                    self?.myCallStatus = .attended
                }
                self?.showHideCallAgainView(show: false, status: "Connecting")
                self?.seconds = -1
                if CallManager.getCallDirection() == .Incoming {
                    for (memberJid,status) in CallManager.getCallUsersWithStatus() {
                        self?.addUpdateCallUsersWithStatus(userJid: memberJid, status: self?.convertCallStatus(status: status) ?? .calling)
                    }
                }
                if self?.outgoingCallView != nil {
                    if CallManager.isOneToOneCall()  {
                        if CallManager.getCallType() == .Audio {
                            self?.showOneToOneAudioCallUI()
                        } else {
                            self?.showOneToOneVideoCallUI()
                        }
                        
                    }else{
                        if CallManager.getCallMode() != .MEET {
                            self?.showGroupCallUI()
                        }
                    }
//                    self?.outgoingCallView?.tileCollectionView.isHidden = false
//                    self?.outgoingCallView?.tileCollectionView.reloadData()
                    
                    self!.outgoingCallView?.removeGestureRecognizer(self!.tapGesture)
                    self!.outgoingCallView?.addGestureRecognizer(self!.tapGesture)
                }
                AudioManager.shared().stopPlayingTone()
            case .CONNECTED:
                print("#STA= #callStatus onCallStatus ====  .CONNECTED \(userId) ")
                //self?.callHoldLabel.removeFromSuperview()
                if CallManager.getCallType() == .Video && !(AudioManager.shared().getAllAvailableAudioInput().contains(where: {$0.type == .bluetooth || $0.type == .headset})) {
                    self?.outgoingCallView?.speakerButton.isHidden = true
                } else {
                    self?.outgoingCallView?.speakerButton.isHidden = false
                    print("#CONNECTED  Speaker ON")
                }
                self?.setHoldText(isShow: false)
                print("#callStatus onCallStatus ==== \(userId) Connected")
                if ((self?.audioPlayer) != nil) {
                    if ((self?.audioPlayer?.isPlaying) != nil) {
                        self?.audioPlayer?.stop()
                    }
                    self?.audioPlayer = nil
                }
                print("#call CONNECTED : \(userId)")
                if CallManager.getCallStatus(userId: AppUtils.getMyJid()) != .RECONNECTING{
                    self?.myCallStatus = .connected
                    self?.updateCallStatus(status:"Connected")
                    self?.showHideCallAgainView(show: false, status: "Connected")
                }
                let status = self?.convertCallStatus(status: CallManager.getCallStatus(userId: userId) ?? .CONNECTED) ?? CallStatus.connected
                _ = self?.updateCallStatus(jid:  userId.isEmpty ? AppUtils.getMyJid() : userId, status: status)
                self?.enableButtons(buttons:self?.outgoingCallView?.videoButton, isEnable: true)
                self?.showHideParticipantButton(hide : false)
                self?.showHideMenuButton(hide: false)
                self?.outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = false
                self?.outgoingCallView?.OutGoingPersonLabel.isHidden = false
                self?.getContactNames()
                self?.outgoingCallView?.imageTop.constant = 28
                self?.enableDisableUserInteractionFor(view: self?.outgoingCallView?.AttendingBottomView, isDisable: false)
                if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (self?.members.count == 1 || self?.members.count == 2)) {
                    _ = self?.validateAndAddMember(jid: userId, with: status)
                    if CallManager.getCallType() == .Video {
                        self?.addOneToOneLocalTracks()
                        self?.setVideoBtnIcon()
                        self?.outgoingCallView?.imageHeight.constant = 100
                        if CallManager.getCallMode() != .MEET {
                            self?.showConnectedVideoCallOneToOneUI()
                        }
                    }else{
                        self?.showOneToOneAudioCallUI()
                    }
                } else {
                    _ = self?.validateAndAddMember(jid: userId, with: status)
                    if self?.checkIfGroupCallUiIsVisible() ?? false { self?.showGroupCallUI() }
                    //_ = self?.requestForVideoTrack(jid: userId)
                    self?.addGroupTracks(jid: AppUtils.getMyJid())
//                    _ = self?.updateMuteStatus(jid: userId, isMute: false, isAudio: CallManager.getCallType() == .Audio)
                    if CallManager.getCallStatus(userId:  userId.isEmpty ? AppUtils.getMyJid() : userId ) == .ON_HOLD{
                        self?.addUpdateCallUsersWithStatus(userJid: userId, status: .onHold, reload: true)
                    }else{
                        self?.addUpdateCallUsersWithStatus(userJid: userId, status: .connected, reload: true)
                    }
                    self?.outgoingCallView?.audioMuteStackView.isHidden = true
                }
                
                self?.outgoingCallView?.tileCollectionView.isHidden = false
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
//                    self?.outgoingCallView?.tileCollectionView.reloadData()
//                }
                  
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
                
//                let audioMuteStatus = CallManager.isRemoteAudioMuted(userId)
//                let vidooMuteStatus = CallManager.isRemoteVideoMuted(userId)
//                print("userJid mute status : \(userId)")
//                self?.onMuteStatusUpdated(muteEvent: (audioMuteStatus == true) ? MuteEvent.ACTION_REMOTE_AUDIO_MUTE : MuteEvent.ACTION_REMOTE_AUDIO_UN_MUTE, userId: userId)
//                self?.onMuteStatusUpdated(muteEvent: (vidooMuteStatus == true) ? MuteEvent.ACTION_REMOTE_VIDEO_MUTE : MuteEvent.ACTION_REMOTE_VIDEO_UN_MUTE , userId: userId)
//                FlyLogWriter.sharedInstance.writeText("#call UI .CONNECTED => \(userId) \(self?.members.count)")
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
//                    print("#callStatus CONNECTED")
//                    if !CallManager.isOneToOneCall() && CallManager.getCallType() == .Video && self?.members.count ?? 0 > 2 {
//                            for member in self!.members.map({$0.jid!}) {
//                                self?.addGroupTracks(jid: member)
//                            }
//                    }
//                }
                self?.validateReconnectingStatus()
                UIApplication.shared.isIdleTimerDisabled = true
            case .DISCONNECTED:
                print("#STA= #callStatus onCallStatus ====  .DISCONNECTED \(userId) ")
//                if (self?.callType == .Video || CallManager.getCallType() == .Video) && !(AudioManager.shared().getAllAvailableAudioInput().contains(where: {$0.type == .bluetooth || $0.type == .headset})) {
//                    self?.outgoingCallView?.speakerButton.isHidden = true
//                } else {
//                    self?.outgoingCallView?.speakerButton.isHidden = false
//                }
                //self?.outgoingCallView?.speakerButton.isHidden = true
                self?.outgoingCallView?.speakerButton.setImage(UIImage(named: "IconSpeakerOff" ), for: .normal)

                if (self?.myCallStatus == .tryagain) { return }
                
                if userId.isEmpty || userId == AppUtils.getMyJid() {
                    executeOnMainThread {
                        self?.dismissWithDelay()
                        self?.onCallAction(callAction: CallAction.ACTION_LOCAL_HANGUP, userId: AppUtils.getMyJid())
                    }
                }else {
                    if let index = self?.findIndexOfUser(jid: userId) {
                        self?.removeDisConnectedUser(userIndex: index)
                    }
//                    if (self?.members.count ?? 0) > 1  && !CallManager.isOneToOneCall(){
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                            for member in self!.members.map({$0.jid!}) {
//                                self?.addGroupTracks(jid: member)
//                            }
//                        }
//                    }
                }
                self?.setHoldText(isShow: false)
                self?.validateReconnectingStatus()
                if CallManager.getAllCallUsersList().count == 0 {
                    self?.dismissWithDelay()
                    self?.onCallAction(callAction: CallAction.ACTION_LOCAL_HANGUP, userId: AppUtils.getMyJid())
                }
               // self?.callHoldLabel.removeFromSuperview()
               
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
                    
                    if userId == self?.fullScreenUser.jid {
                        self?.updateCallStatus(status:  CallStatus.onHold.rawValue)
                    }else{
                        self?.updateCallStatus(status:  CallStatus.connected.rawValue)
                    }
                }
                self?.validateReconnectingStatus()
                FlyLogWriter.sharedInstance.writeText("#call UI .ON_HOLD => \(userId) \(self?.members.count)")
            case .ON_RESUME:
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
                    self?.updateCallStatus(status: CallStatus.connected.rawValue)
                    self?.myCallStatus = .connected
                }else{
                    self?.updateCallStatus(status: CallStatus.connected.rawValue)
                    self?.myCallStatus = .connected
                    if !CallManager.getMuteStatus(jid: userId, isAudioStatus: false) && userId != AppUtils.getMyJid() {
                        print("#callStatusRE ON_RESUME If")
                        self?.onCallAction(callAction: .ACTION_REMOTE_VIDEO_ADDED, userId: userId)
                    }else{
                        print("#callStatusRE ON_RESUME ELSE")
                        self?.reloadCollectionViewForIndex(index: indexValue)
                    }
                }
                
                if CallManager.getCallMode() == .MEET && self?.members.count ?? 0 > 2 {
                    self?.outgoingCallView?.tileCollectionView.reloadData()
                }
                self?.outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = false
                self?.showHideDuration(hide: false)
               // self?.callHoldLabel.removeFromSuperview()
                
                self?.setHoldText(isShow: false)
                FlyLogWriter.sharedInstance.writeText("#call UI .ON_RESUME => \(userId) \(self?.members.count) videoMute => \(CallManager.getMuteStatus(jid: userId, isAudioStatus: false))")
            case .USER_JOINED:
                if CallManager.getCallMode() == .MEET {
                    if (self?.members.count ?? 0) > 1{
                        self?.outgoingCallView?.qualityIcon.isHidden = true
                    }
                    if let index = self?.findIndexOfUser(jid: userId) {
                        return
                    }
                    if let contact = ChatManager.getContact(jid: userId), let self = self,userId.isNotEmpty{
                        AppAlert.shared.showToast(message:"\(self.getNameStringWithGroupName(userNames: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))) joined")
                    }
                }
            case .USER_LEFT:
                if let contact = ChatManager.getContact(jid: userId), let self = self,userId.isNotEmpty{
                    if let index = self.findIndexOfUser(jid: userId) {
                        AppAlert.shared.showToast(message:"\(getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType)) left")
                    }
                }
                if let index = self?.findIndexOfUser(jid: userId) {
                    self?.removeDisConnectedUser(userIndex: index)
                }
                self?.getContactNames()
                if CallManager.getCallMode() == .MEET && self?.members.count ?? 0 > 1 {
                    self?.outgoingCallView?.tileCollectionView.reloadData()
                }
                if CallManager.getCallMode() == .MEET && (self?.members.count ?? 0) == 1 {
                    self?.outgoingCallView?.qualityIcon.isHidden = CallManager.getCallConnectionQuality() != .poor
                }
            case .INVITE_CALL_TIME_OUT:
                print("")
            case .CALL_TIME_OUT:
                print("#call CALL_TIME_OUT  \(self?.isOnCall ?? false)")
                if (self?.isOnCall ?? false) || CallManager.isCallConnected() {
                    self?.isOnCall = CallManager.isCallConnected()
                    if userId.isEmpty || userId == AppUtils.getMyJid() {
                        let timedOutUsers = userId.components(separatedBy: ",")
                        if (self?.members.count ?? 0) - timedOutUsers.count > 1 {
                            self?.removeUnavailableUsers(removedUsers: timedOutUsers)
                        } else {
                            if CallManager.getCallMode() != .MEET {
                                executeOnMainThread {
                                    self?.dismissWithDelay()
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
                        }
                    }else{
                        self?.myCallStatus = .tryagain
                        self?.showHideCallAgainView(show: true, status: "Unavailable, Try again later")
                    }
                }
            case .RECONNECTING:
                print("#STA= #callStatus onCallStatus ====  .RECONNECTING \(userId)  \(self?.members.compactMap({$0.jid})) ||  \(self?.outgoingCallView?.tileCollectionView.numberOfItems(inSection: 0))")
                if CallManager.isCallConnected() {
                    self?.showHideParticipantButton(hide:  userId == AppUtils.getMyJid())
                    self?.showHideMenuButton(hide: userId == AppUtils.getMyJid())
                }
                self?.outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = !CallManager.isOneToOneCall()
                self?.updateCallStatus(jid: userId, status : .reconnecting)
                if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (self?.members.count == 1 || self?.members.count == 2)) {
                    if (self?.isOnCall ?? false) && userId ==  AppUtils.getMyJid(){
                        self?.myCallStatus = .reconnecting
                    }
                    if let contact = ChatManager.getContact(jid: userId.lowercased()), userId != AppUtils.getMyJid(){
                        let status = "\(getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType)) Reconnecting"
                        self?.updateCallStatus(status: status)
                    }else{
                        self?.updateCallStatus(status: "\(userId == AppUtils.getMyJid() ? "" : userId) Reconnecting")
                    }
                    self?.outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = false
                    self?.outgoingCallView?.tileCollectionView.reloadData()
                }else if self?.members.count ?? 0 > 2 {
                    self?.updateCallStatus(jid: userId, status: .reconnecting)
                }
                self?.validateReconnectingStatus()
                if userId == AppUtils.getMyJid(){
                    self?.showHideQualityView(show: false)
                }
            case .RECONNECTED:
                print("#STA= #callStatus onCallStatus ====  .RECONNECTED \(userId) \(CallManager.getCallStatus(userId: userId)?.rawValue) 1-1 => \(CallManager.isOneToOneCall())  \((self?.isOnCall ?? false))")
                if !CallManager.isCallConnected(){
                    if CallManager.getCallMode() == .MEET{
                        //self?.collectionView?.reloadData()
                    }
                    return
                }
                self?.updateCallStatus(jid: userId, status: .connected)
                if CallManager.getCallType() == .Video {
                    self?.addRemoteTrackToView()
                }
                if CallManager.isOneToOneCall() && (self?.members.count == 2){
                    if (self?.isOnCall ?? false){
                        self?.myCallStatus =  self?.isCallOnHoldForOneToCall() ?? false ?  CallStatus.onHold : CallStatus.connected
                    }
                }else{
                    if (self?.isOnCall ?? false){
                        self?.myCallStatus = .connected
                    }
                }
                
                if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (self?.members.count == 1 || self?.members.count == 2))   {
                    if CallManager.getCallType() == .Audio {
                        self?.showOneToOneAudioCallUI()
                    } else {
                        self?.showOneToOneVideoCallUI()
                        self?.addRemoteTrackToView()
                        
                        if self?.members.first?.isVideoMuted ?? false{
                            self?.outgoingCallView?.remoteUserVideoView.isHidden = true
                            self?.showHideCallBackgroundProfiles(hide: self?.showGridView ?? false ? true : false)
                        }
                       
                        if self?.members.last?.isVideoMuted ?? false{
                            //self?.onVideoMute(status:true)
                        }
                        self?.setMuteStatusText()
                        self?.outgoingCallView?.tileCollectionView.reloadData()
                    }
                    
                }else{
                    self?.showGroupCallUI()
                    self?.addRemoteTrackToView()

                    
                    let remoteVideoMuted =  self?.members[(self?.members.count ?? 0) - 2].isVideoMuted
                    self?.outgoingCallView?.remoteUserVideoView.isHidden = remoteVideoMuted ?? false ? true : false
                    
                    self?.showHideCallBackgroundProfiles(hide: self?.showGridView ?? false ? true : remoteVideoMuted ?? false ? false : true)
                    
                    self?.setMuteStatusText()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.outgoingCallView?.tileCollectionView.reloadData()
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                        print("#callStatus RECONNECTED")
                        if !CallManager.isOneToOneCall() && CallManager.getCallType() == .Video && self?.members.count ?? 0 > 2 {
                                for member in self!.members.map({$0.jid!}) {
                                    self?.addGroupTracks(jid: member)
                                }
                        }
                    }
                }
                self?.setupTileViewConstraints(isRemoveUser: false)
                
                self?.showHideParticipantButton(hide: !CallManager.isCallConnected())
                self?.showHideMenuButton(hide: !CallManager.isCallConnected())
                self?.validateReconnectingStatus()
                if CallManager.getCallConnectionQuality() == .poor && CallManager.isCallConnected(){
                    self?.didQualityUpdated(quality: .poor)
                }
            case .CALLING_10S:
                print("")
            case .CALLING_AFTER_10S:
                print("Call Status ===> \(callStatus.rawValue)")
                self?.updateCallStatus(status: callStatus.rawValue)

            @unknown default:
                break
            }
        }
        //Added for UI not shown properly for Audio and Video calls in Same time call scenario
        executeOnMainThread { [weak self] in
            if callStatus != .DISCONNECTED {
                self?.setActionIconsAfterMaximize()
                self?.outgoingCallView?.tileCollectionView.reloadData()
            }
        }
    }
    
    
    @IBAction func addParticipant(sender: UIButton?){
        
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
        executeOnMainThread {
            switch callStatus {
            case .CONNECTING:
                _ = self.validateAndAddMember(jid: userId, with: .connecting)
            case .RINGING:
                _ = self.validateAndAddMember(jid: userId, with: .ringing)
            case .ATTENDED:
                _ = self.validateAndAddMember(jid: userId, with: .connecting)
            case .CONNECTED:
                _ = self.validateAndAddMember(jid: userId, with: .connected)
            case .DISCONNECTED:
                _ = self.validateAndAddMember(jid: userId, with: .disconnected)
            case .ON_HOLD:
                _ = self.validateAndAddMember(jid: userId, with: .onHold)
            case .ON_RESUME:
                break
            case .USER_JOINED:
                break
            case .USER_LEFT:
                break
            case .INVITE_CALL_TIME_OUT:
                break
            case .CALL_TIME_OUT:
                break
            case .RECONNECTING:
                _ = self.validateAndAddMember(jid: userId, with: .reconnecting)
            case .RECONNECTED:
                _ = self.validateAndAddMember(jid: userId, with: .reconnected)
            case .CALLING:
                _ = self.validateAndAddMember(jid: userId, with: .calling)
            case .CALLING_10S:
                break
            case .CALLING_AFTER_10S:
                break
            @unknown default:
                _ = self.validateAndAddMember(jid: userId, with: .tryagain)
            }
        }
    }

    func popupView() {
        
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
    
    @objc func transformTileToGrid(sender: UIControl?){
        
        removePopupView()
        showHideMenu = true
        showGridView = !showGridView
        
        if showGridView {
            outgoingCallView?.outGoingAudioCallImageView.isHidden = true
            outgoingCallView?.audioCallMutedIcon.isHidden = true
            outgoingCallView?.audioWaveView.isHidden = true
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
                        outgoingCallView?.remoteUserVideoView.isHidden = remoteVideoMuted ? true : false
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
                    outgoingCallView?.audioWaveView.isHidden = remoteVideoMuted ? true : false
                    outgoingCallView?.remoteUserVideoView.isHidden = remoteVideoMuted ? true : false
                    showHideCallBackgroundProfiles(hide: remoteVideoMuted ? false : true)
                    
                    setMuteStatusText()
                }
                outgoingCallView?.reconnectingLable?.isHidden = false
                validateReconnectingStatus()
                if fullScreenUser.callStatus == .onHold{
                    updateCallStatus(status: CallStatus.onHold.rawValue)
                }
            }
        }
        autoreleasepool {
            isTapped = false
            let top = CGAffineTransform(translationX: 0, y: showGridView ? 0 : -20)
            self.outgoingCallView?.AttendingBottomView.transform = top
            self.outgoingCallView?.tileCollectionView.transform = top
            
            transformTileAndGridConstraints()
    //        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self.outgoingCallView?.tileCollectionView.reloadData()
    //        }
            
            if !CallManager.isOneToOneCall() {
                for member in members {
                    outgoingCallView?.tileCollectionView?.performBatchUpdates {
                        addGroupTracks(jid: member.jid)
                    }
                }
            }
        }
    }
    
    func validateReconnectionStatusForGroupCall(){
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
                            updateReconnectingLabel(reconnectingUserId: reconnectingUserId)
                        }
                    }else if firstUser.callStatus == .onHold || lastUser.callStatus == .onHold{
                        updateCallStatus(status: CallStatus.onHold.rawValue)
                    }else{
                        updateCallStatus(status: CallStatus.connected.rawValue)
                    }
                }
            }else{
                validateReconnectionStatusForGroupCall()
            }
        }else{
            outgoingCallView?.reconnectingLable?.text = emptyString()
        }
    }

    func updateReconnectingLabel(reconnectingUserId : String){
        if let contact = ChatManager.getContact(jid: reconnectingUserId.lowercased()), reconnectingUserId != AppUtils.getMyJid() {
            let status = "\(getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType)) Reconnecting"
            updateCallStatus(status: status)
        }else {
            updateCallStatus(status: "\(reconnectingUserId == AppUtils.getMyJid() ? "" : reconnectingUserId) Reconnecting")
        }
    }

    func findIndexOfUser(jid : String) -> Int? {
        return members.firstIndex { $0.jid == jid }
    }
    
    func onCallAction(callAction: CallAction, userId: String) {

        print("#oncallcation \(callAction), \(userId)")
        
        if callAction == CallAction.ACTION_LOCAL_HANGUP {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)){
                self.dismissCallUI()
            }
        } else if callAction == CallAction.ACTION_REMOTE_VIDEO_ADDED {
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

            if CallManager.getAllCallUsersList().count == 0 {
                executeOnMainThread {
                    self.dismissWithDelay(callStatus: "User Busy")
                }
            } else {
                if let index = findIndexOfUser(jid: userId) {
                    removeDisConnectedUser(userIndex: index)
                }
            }
            if CallManager.isCallConnected() {
                self.addRemoteTrackToView()
            }
        }
        else if callAction == CallAction.ACTION_VIDEO_CALL_CONVERSION_ACCEPTED {
            print("#switch ACTION_VIDEO_CALL_CONVERSION_ACCEPTED me :\(isCallConversionRequestedByMe) remote: \(isCallConversionRequestedByRemote)  isVideo: \(CallManager.getCallType().rawValue)")
            showHideCallBackgroundProfiles(hide: true)
            CallManager.setCallType(callType: .Video)
            CallManager.muteVideo(false)
            members.first?.isVideoMuted = false
            isVideoMuted = false
            switchLoaclandRemoteViews()
            showOneToOneVideoCallUI()
            showHideDuration(hide: false)
            setVideoBtnIcon()
            resetConversionTimer()
            //localProfileImageView.removeFromSuperview()
            AudioManager.shared().autoReRoute()
        }
        else if callAction == CallAction.ACTION_VIDEO_CALL_CONVERSION_REJECTED {
            print("#switch onCallAction \(callAction.rawValue)")
            // Call conversion is declined by the user
            if let remoteMember = members.last {
                AppAlert.shared.showToast(message: remoteMember.name.isEmpty ? "Request declined" : "Request declined by \(remoteMember.name)")
            }
            CallManager.setCallType(callType: .Audio)
            isCallConversionRequestedByMe = false
            isCallConversionRequestedByRemote = false
            resetConversionTimer()
            CallManager.disableVideo()
            isVideoMuted = true
            setVideoBtnIcon()
            showOneToOneAudioCallUI()
        }
        else if callAction == CallAction.ACTION_VIDEO_CALL_CONVERSION {
            print("#switch onCallAction \(callAction.rawValue) me :\(isCallConversionRequestedByMe) remote: \(isCallConversionRequestedByRemote)  isVideo: \(CallManager.getCallType().rawValue)")
            // Call conversion is requested to the user
            if overlayShown {
                self.callViewTapGestureAction(UITapGestureRecognizer())
            }
            isCallConversionRequestedByRemote = true
            alertController?.dismiss(animated: true, completion:nil)
            showCallConversionConfirmationRequest()
            //let _ = requestForVideoTrack(jid: nil)
        }
        else if callAction == CallAction.CHANGE_TO_AUDIO_CALL {
            print("#switch onCallAction \(callAction.rawValue) me :\(isCallConversionRequestedByMe) remote: \(isCallConversionRequestedByRemote)  isVideo: \(CallManager.getCallType().rawValue)")
            isLocalViewSwitched = false
            if VideoCallConversionTimer != nil, let remoteMember = members.last {
                AppAlert.shared.showToast(message: remoteMember.name.isEmpty ? "No response" : "No response from \(remoteMember.name)")
            }
            alertController?.dismiss(animated: true, completion: nil)
            CallManager.setCallType(callType: .Audio)
            resetConversionTimer()
            showOneToOneAudioCallUI()
            removeRemoteOneToOneLocalTracks()
            AudioManager.shared().autoReRoute()
            self.callType = .Audio
        }
        else if callAction == CallAction.ACTION_INVITE_USERS {
            print("#UI menmenersCount before \(members.count)")
            for userJid in userId.components(separatedBy: ",") {
                addUpdateCallUsersWithStatus(userJid: userJid, status: convertCallStatus(status: CallManager.getCallStatus(userId: userJid) ?? .CALLING), reload: true, skipTracks: true)
            }
            print("#UI menmenersCount after \(members.count)")
            showGroupCallUI()
            if !reloadForInVite{
                for member in members.map({$0.jid!}) {
                    addGroupTracks(jid: member)
                }
            }
            updateActionsUI()
            self.outgoingCallView?.cameraButton.isHidden = isVideoMuted
        }
        else if callAction == CallAction.ACTION_REMOTE_ENGAGED {
            if CallManager.isOneToOneCall() && isOnCall && (CallManager.getCallConnectedUsersList()?.count ?? 0) == 0 {
                executeOnMainThread {
                    self.dismissWithDelay(callStatus: "Call Engaged")
                }
            }else{
                if let index = findIndexOfUser(jid: userId){
                    removeDisConnectedUser(userIndex: index)
                }
            }
            AppAlert.shared.showToast(message: "Call Engaged")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.outgoingCallView?.tileCollectionView.reloadData()
            }
        }

//        executeOnMainThread { [weak self] in
//            if (self?.callType == .Video || CallManager.getCallType() == .Video) && !(AudioManager.shared().getAllAvailableAudioInput().contains(where: {$0.type == .bluetooth || $0.type == .headset})) {
//                self?.outgoingCallView?.speakerButton.isHidden = true
//            } else {
//                self?.outgoingCallView?.speakerButton.isHidden = false
//            }
//        }
    }
    
    func onMuteStatusUpdated(muteEvent: MuteEvent, userId: String) {
        updateMuteStatusOfUser(userId: userId)
        print("#call onMuteStatusUpdated \(muteEvent) \(userId)")
        switch muteEvent {
        case .ACTION_REMOTE_AUDIO_MUTE:
            if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (members.count == 1 || members.count == 2)) {
                members.first?.isAudioMuted = true
                setMuteStatusText()
                if showGridView {
                    //outgoingCallView?.tileCollectionView.reloadData()
                    if let cell = self.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: 0, section: 0)) as? TileCell{
                        self.showHideSpeakingAnimation(isShow: false, cell: cell, isMuted:true)
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
                if showGridView {
                   // outgoingCallView?.tileCollectionView.reloadData()
                    if let cell = self.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: 0, section: 0)) as? TileCell{
                        self.showHideSpeakingAnimation(isShow: true, cell: cell, isMuted:false)
                    }
                    
                }
            } else {
                updateMuteStatus(jid: userId, isMute: false, isAudio: true)
                setMuteStatusText()
            }
        case .ACTION_REMOTE_VIDEO_MUTE:
            executeOnMainThread { [self] in
                if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (members.count == 1 || members.count == 2)) {
                    members.first?.isVideoMuted = true
                    setMuteStatusText()
                    removeRemoteOneToOneLocalTracks()

                    if isLocalViewSwitched {
                        isLocalViewSwitched = false
                        outgoingCallView?.tileCollectionView.reloadData()
                    }
                    addRemoteTrackToView()

    //                for recognizer in outgoingCallView?.tileCollectionView.gestureRecognizers ?? [] {
    //                    outgoingCallView?.tileCollectionView.removeGestureRecognizer(recognizer)
    //                }


                    if showGridView { reloadCollectionViewForIndex(index: 0) }
                        getContactNames()
                    showHideCallBackgroundProfiles(hide: showGridView ? true : false)
                        setupTopViewConstraints()
                } else {

                    updateMuteStatus(jid: userId, isMute: true, isAudio: false)
                    setMuteStatusText()
                    updateRemoteViewForMuteAndUnmute()
                    let index = findIndexOfUser(jid: userId)
                    if members.count > 2 {
                        if members[members.count - 2].callStatus == .connected && index == members.count - 2 {
                            showHideCallBackgroundProfiles(hide: showGridView ? true : false)
                        }
                    }
                    if showGridView { outgoingCallView?.tileCollectionView.reloadData() }
                }
            }
        case .ACTION_REMOTE_VIDEO_UN_MUTE:
            if CallManager.isOneToOneCall() || (CallManager.getCallMode() == .MEET && (members.count == 1 || members.count == 2)) {
                //outgoingCallView?.contentView.backgroundColor = .clear
                members.first?.isVideoMuted = false
                setMuteStatusText()
                addRemoteTrackToView()
                outgoingCallView?.remoteUserVideoView.isHidden = false
                
                if !(members.last?.isVideoMuted ?? false) && !(members.first?.isVideoMuted ?? false) {
                    
                    videoTapGesture = UITapGestureRecognizer(target: self, action: #selector(smallVideoTileTapped(_:)))
                    outgoingCallView?.tileCollectionView?.addGestureRecognizer(videoTapGesture)
                }
                
                if showGridView { outgoingCallView?.tileCollectionView.reloadData() }
                
                    getContactNames()
                    showHideCallBackgroundProfiles(hide: true)
                    setupTopViewConstraints()
            } else {
                
                updateMuteStatus(jid: userId, isMute: false, isAudio: false)
                setMuteStatusText()
                updateRemoteViewForMuteAndUnmute()
                if members.count > 0 {
                    let index = findIndexOfUser(jid: userId)
                    let remoteVideoMuted = members[members.count - 2].isVideoMuted
                    if !remoteVideoMuted && index == members.count - 2 {
                        addRemoteTrackToView()
                    }
                    outgoingCallView?.remoteUserVideoView.isHidden = remoteVideoMuted ? true : false
                }
                if showGridView { outgoingCallView?.tileCollectionView.reloadData() }
            }
        case .ACTION_LOCAL_AUDIO_MUTE:
            isAudioMuted = true
            outgoingCallView?.audioButton.setImage(UIImage(named: isAudioMuted ? "IconAudioOn" :  "IconAudioOff" ), for: .normal)
            if (CallManager.getCallMode() == .MEET && members.count == 1){ setMuteStatusText() }
        case .ACTION_LOCAL_AUDIO_UN_MUTE:
            isAudioMuted = false
            outgoingCallView?.audioButton.setImage(UIImage(named: isAudioMuted ? "IconAudioOn" :  "IconAudioOff" ), for: .normal)
            if (CallManager.getCallMode() == .MEET && members.count == 1){ setMuteStatusText() }
            
        case .ACTION_LOCAL_VIDEO_MUTE:
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
    
    func validateAndAddMember(jid: String? = nil, with status: CallStatus = .calling) -> Bool {
        
        if members.isEmpty || !members.contains(where: {$0.jid == AppUtils.getMyJid()}) {
            //addMyInfoToMembersArray(requestTrack: CallManager.getCallType() == .Video)
            addMyInfoToMembersArray(videoTrack: nil)
        }
        
        if let jid = jid, jid != AppUtils.getMyJid() {
            if !(members.contains{$0.jid == jid} ) {
                let profileDetails = ProfileDetails(jid: jid)
                _ = addRemoteMembers(for: profileDetails, with: status)
                if let index = findIndexOfUser(jid: jid) {
                    members[index].isVideoMuted = CallManager.isRemoteVideoMuted(jid)
                    members[index].isAudioMuted = CallManager.isRemoteAudioMuted(jid)
                }
                if !CallManager.isOneToOneCall(){
                    outgoingCallView?.tileCollectionView?.reloadData()
                }
                return true
            }else {
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
        return false
    }
    
    func removeAllMembers() {
        //clearAllTrackViews()
        members.removeAll()
        executeOnMainThread {
            //self.outgoingCallView?.tileCollectionView.reloadData()
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
            }else if CallManager.getCallStatus(userId: jid) == .RECONNECTING{
                members[index].callStatus = .reconnecting
            }else{
                members[index].callStatus = status
            }
            updateUsersDetails(index: index, userid: jid)
        }
    }
    
    func updateUsersDetails(index: Int, userid: String) {
        print("#call updateUsersDetails \(userid)")
            if !CallManager.isOneToOneCall() && self.outgoingCallView?.tileCollectionView != nil && !(CallManager.getCallMode() == .MEET && (members.count == 1 || members.count == 2)) {
            if (index == members.count - 2 && !showGridView) { return }
            let isLastRow = (index == members.count - 1)
            let member = members[index]
            if let tileCell = self.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? TileCell {
                if member.callStatus == .reconnecting || (!isLastRow && member.callStatus != .connected) || member.callStatus == .onHold || (isLastRow && CallManager.isCallOnHold()){
                    tileCell.foreGroundView.isHidden = false
                    tileCell.statusLable.text = member.callStatus.rawValue.capitalized
                    tileCell.audioIconImageView.isHidden = true
                }else{
                    tileCell.foreGroundView.isHidden = true
                    tileCell.statusLable.textColor = UIColor(hexString: "#FFFFFF")
                    //tileCell.profileName.font = AppFont.Regular.size(14)
                    tileCell.audioIconImageView.isHidden = false
                    showHideSpeakingAnimation(isShow: !member.isAudioMuted, cell: tileCell, isMuted: member.isAudioMuted)
                }
                //tileCell.audioIconImageView.isHidden = false
                tileCell.audioIconImageView.image = (member.isAudioMuted) ? UIImage(systemName: "mic.slash.fill") : UIImage(named: "audio_lvl_one")
            }
        }
    }
    
    func updateVideoMuteStatus(index: Int, userid: String, isMute : Bool) {
        print("#CR func updateVideoMuteStatus \(userid)")
            if !CallManager.isOneToOneCall() && self.outgoingCallView?.tileCollectionView != nil && !(CallManager.getCallMode() == .MEET && (members.count == 1 || members.count == 2)) {
                if members.count != outgoingCallView.tileCollectionView.numberOfItems(inSection: 0){
                    outgoingCallView?.tileCollectionView?.reloadData()
                }else{
                    self.outgoingCallView?.tileCollectionView?.performBatchUpdates {
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
                            members[index].isVideoMuted = isMute
                        }
                    }
            }
        }
    }
    
    func reloadCollectionViewForIndex(index: Int?) {
        DispatchQueue.main.async { [weak self] in
            if let itemIndex =  index, self?.outgoingCallView?.tileCollectionView?.numberOfItems(inSection: 0) ?? 0 > index ?? -1, self?.outgoingCallView?.tileCollectionView?.isHidden == false {
                print("#callStatus #reloadCollectionViewForIndex \(itemIndex) \(self?.members[itemIndex].jid)")
                let indexPath = IndexPath(item: itemIndex, section: 0)
                self?.outgoingCallView?.tileCollectionView?.reloadItems(at: [indexPath])
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
                var oneToOneUsers : [CallMember] = []
                //releaseTrackViewBy(memberIndex: userIndex)
                members.remove(at: userIndex)
                let indexPath =  IndexPath(item: userIndex, section: 0)
                
                if CallManager.getCallMode() == .MEET || (outgoingCallView?.tileCollectionView?.isHidden == false && (outgoingCallView?.tileCollectionView.numberOfItems(inSection: 0) ?? 0) > 2){
//                    outgoingCallView?.tileCollectionView?.deleteItems(at: [indexPath])
                    executeOnMainThread {
                        self.outgoingCallView?.tileCollectionView.reloadData()
                    }
                }
                
                showHideParticipantButton(hide : !isOnCall)
                showHideMenuButton(hide: !isOnCall)
                if !isOnCall{
                    //getContactNames()
                     if CallManager.getAllCallUsersList().count <= 1 {
                        if CallManager.getCallMode() != .MEET {
                            executeOnMainThread {
                                self.dismissWithDelay()
                            }
                        }
                    }
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
//                    if CallManager.getCallType() == .Video {
//                        showConnectedVideoCallOneToOneUI()
//                    }
                    
                    if CallManager.getCallType() == .Audio && (members.first?.isVideoMuted ?? true && members.last?.isVideoMuted ?? true) {
                        CallManager.muteVideo(true)
                        showOneToOneAudioCallUI()
                        if isTapped{
                            SingleTapGesturTapped(UITapGestureRecognizer())
                        }
                    } else {
                        
                        showOneToOneVideoCallUI()
                        showHideDuration(hide: false)
                        switchLoaclandRemoteViews()
                        setupTileViewConstraints(isRemoveUser: false)
                        
                        if members.first?.callStatus != .connected {
                            removeRemoteOneToOneLocalTracks()
                            setupTopViewConstraints()
                            showHideCallBackgroundProfiles(hide: showGridView ? true : false)
                        }
                        
                        if members.first?.isVideoMuted ?? false {
                            setupTopViewConstraints()
                            showHideCallBackgroundProfiles(hide: showGridView ? true : false)
                        }else{
                            showHideCallBackgroundProfiles(hide: true)
                        }
                        
                        if CallManager.getCallType() == .Video && !(AudioManager.shared().getAllAvailableAudioInput().contains(where: {$0.type == .bluetooth || $0.type == .headset})) {
                            self.outgoingCallView?.speakerButton.isHidden = true
                        } else {
                            self.outgoingCallView?.speakerButton.isHidden = false
                        }
                    }
                    updateCallStatus(status: isCallOnHoldForOneToCall() ? CallStatus.onHold.rawValue : convertCallStatus(status: CallManager.getCallStatus(userId: (members.first?.jid)!) ?? .CALLING).rawValue)
                    oneToOneUsers.removeAll()
                    setMuteStatusText()
                    getContactNames()
                    outgoingCallView?.tileCollectionView.reloadData()
                    
                    if CallManager.getCallType() == .Video && members.first?.callStatus != .connected {
                        if let contact = ChatManager.profileDetaisFor(jid:members.first?.jid ?? ""){
                            outgoingCallView?.outGoingAudioCallImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), jid: contact.jid)
                            
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
                        outgoingCallView?.remoteUserVideoView.isHidden = false
                    }
                    setupTileViewConstraints(isRemoveUser: true)
                }
            }else if CallManager.getAllCallUsersList().count <= 1 {
                if CallManager.getCallMode() != .MEET {
                    executeOnMainThread {
                        self.dismissWithDelay()
                    }
                }
            }else{
                members.remove(at: userIndex)
                validateReconnectingStatus()
            }
        }
        self.validateReconnectingStatus()
        self.getContactNames()
    }
    
    func addUpdateCallUsersWithStatus(userJid: String, status : CallStatus, reload: Bool = false, skipTracks : Bool = false)  {
        
        let isNewUser = validateAndAddMember(jid: userJid, with: status)
        
            if (isOnCall || !(outgoingCallView?.tileCollectionView?.isHidden ?? false)) {
                print("#UI #addUpdateCallUsersWithStatus \(userJid) \(status.rawValue)")
                if isNewUser {
                    if reload {
                        insertUsersToCollectionView(userIndex: (members.count - 1 ), userJid: userJid)
                    } //add new user before local user
                } else {
                    updateCallStatus(jid: userJid, status: status)
                }
                if !skipTracks{
                    outgoingCallView?.tileCollectionView?.reloadData()
                    for member in members {
                        outgoingCallView?.tileCollectionView?.performBatchUpdates {
                            addGroupTracks(jid: member.jid)
                        }
                    }
                }
            }
    }
    
    func insertUsersToCollectionView(userIndex: Int, userJid: String) {
        
        if outgoingCallView?.tileCollectionView?.numberOfItems(inSection: 0) == 0 {
            outgoingCallView?.tileCollectionView.reloadData()
        }else{
            outgoingCallView?.audioMuteStackView.isHidden = true
            executeOnMainThread {
                self.outgoingCallView?.tileCollectionView.reloadItems(at: [IndexPath(item: userIndex, section: 0)])
                self.outgoingCallView?.tileCollectionView.reloadData()
            }
        }
        validateReconnectingStatus()
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
                getContactNames()
                
                if CallManager.isOneToOneCall() && myCallStatus == .reconnecting {
                    updateCallStatus(status: "Reconnecting")
                }
            }
        }
        
        setupTileViewConstraints(isRemoveUser: true)
    }
    
    func checkIfGroupCallUiIsVisible() -> Bool {
        return outgoingCallView?.tileCollectionView?.isHidden ?? false
    }

    func updateMuteStatusOfUser(userId: String) {
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
        view?.isUserInteractionEnabled = !isDisable
    }
    
    func setVideoBtnIcon()  {
        
        print("#meet #btn setVideoBtnIcon \(CallManager.isVideoMuted()) || Local \(isVideoMuted)")
        var image = "ic_video_inactive"
        if CallManager.isOneToOneCall() && CallManager.getCallType() == .Audio && (isVideoMuted && members.first?.isVideoMuted ?? false) {
            image = "ic_video_inactive"
        }else{
            let isVideoTrackAvaialable = members.last?.videoTrack != nil
            if isVideoMuted && isVideoTrackAvaialable {
                image = "ic_video_inactive"
            } else if isVideoTrackAvaialable || !isVideoMuted  {
                image = "ic_video_active"
            }
        }
        outgoingCallView?.videoButton.setImage(UIImage(named: image ), for: .normal)
    }
    
    func setButtonsActions()  {
        
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
        if CallManager.getCallType() == .Audio && CallManager.isOneToOneCall() {
            setupTopViewConstraints()
        } else {
            if CallManager.getCallType() == .Video {
                outgoingCallView?.viewHeight.constant = 190
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
    }
    
    func getCurrentCallStatusAsString() -> String {
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

// MARK:  Connection Event Delegate Methods
extension CallUIViewController : ConnectionEventDelegate{
    
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

// MARK:  Audio Manager Delegate Methods
extension CallUIViewController : AudioManagerDelegate {
    
    func audioRoutedTo(deviceName: String, audioDeviceType: OutputType) {
        if (callType == .Video || CallManager.getCallType() == .Video) && !(AudioManager.shared().getAllAvailableAudioInput().contains(where: {$0.type == .bluetooth || $0.type == .headset})) {
            outgoingCallView?.speakerButton.isHidden = true
        } else {
            outgoingCallView?.speakerButton.isHidden = false
        }
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


// MARK:  User Speaking validation Methods
extension CallUIViewController {
    
    func onUserSpeaking(userId: String, audioLevel: Int) {
        print("#speak speaking \(userId) : \(audioLevel)")
        // TODO : Commented due to crash issue
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.speakingDictionary[userId] = audioLevel
            self.updateSpeakingUI(userId: userId, isSpeaking: true, audioLevel: audioLevel)
        }
    }
    
    func onUserStoppedSpeaking(userId: String) {
        print("#speak stopped \(userId)")
        speakingDictionary[userId] = -1
        updateSpeakingUI(userId: userId, isSpeaking: false, audioLevel: -1)
    }
    
    func updateSpeakingUI(userId : String, isSpeaking : Bool, audioLevel : Int = 0 ){
        if (!CallManager.isOneToOneCall() && !(CallManager.getCallMode() == .MEET && members.count == 2)) || (CallManager.getCallMode() == .MEET && members.count > 2)  {
            if getCallStatusOf(userId: userId) != .connected{
                return
            }
            if let index = findIndexOfUser(jid: userId) {
                
                if (index == members.count - 2 && !showGridView) { return }
                
                if let cell = outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? TileCell{
                    if isSpeaking {
                        
                        self.showHideSpeakingAnimation(isShow: isSpeaking, cell: cell, isMuted: members[index].isAudioMuted)
                        
                        if userId == AppUtils.getMyJid() && members[index].isAudioMuted { cell.audioIconImageView.image =  UIImage(systemName: "mic.slash.fill") }
                        
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
                                    outgoingCallView?.tileCollectionView.reloadData()
                                    let getmember = members[members.count - 3]
                                    print("getmember \(getmember.name) \(getmember.isAudioMuted)")
                                    updateUsersDetails(index: (members.count - 3), userid: emptyString())
                                   
                                    setMuteStatusText()
                                    getContactNames()
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
                                    outgoingCallView?.remoteUserVideoView.isHidden = remoteVideoMuted ? true : false
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
                
                if let cell = self.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: (self.showGridView) ? 1 : 0, section: 0)) as? TileCell{
                    self.showHideSpeakingAnimation(isShow: isSpeaking, cell: cell, isMuted: self.members.last?.isAudioMuted ?? false)
                }
            }
        }
    }
    
    func showHideSpeakingAnimation(isShow: Bool, cell: TileCell, isMuted: Bool) {
        if isShow && !isMuted {
            let imageArray = [UIImage(named: "audio_lvl_one")!,UIImage(named: "audio_lvl_two")!,UIImage(named: "audio_lvl_three")!,UIImage(named: "audio_lvl_four")!,UIImage(named: "audio_lvl_five")!]
            cell.audioIconImageView.animationImages = imageArray
            cell.audioIconImageView.animationDuration = 0.5
            cell.audioIconImageView.startAnimating()
            
        }else {
            cell.audioIconImageView.stopAnimating()
            cell.audioIconImageView.image = (isMuted) ? UIImage(systemName: "mic.slash.fill") : UIImage(named: "audio_lvl_one")
        }
    }
}

extension CallUIViewController: particpantsAddDelegate {
    func participantsAdded(profiles: [String]) {
        CallManager.inviteUsersToOngoingCall(profiles) { isSuccess, error in
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
        if let localTrack = members.last?.videoTrack {
            addVideoTrack(to: UIView(), isLocal: true, track: localTrack)
        }
    }
    
    func addGroupTracks(jid: String) {
        if let index = self.findIndexOfUser(jid: jid), !((members.count - 2) < 0 ) {
            if (members[members.count - 2].callStatus != .connected && !showGridView){ return }
            let member = self.members[index]
            if let collectionView = self.outgoingCallView?.tileCollectionView {
                executeOnMainThread {
                    if self.members.count != collectionView.numberOfItems(inSection: 0){
                        collectionView.reloadData()
                    }else{
                        collectionView.performBatchUpdates {
                            print("#call addGroupTracks \(jid)")
                            if let groupCell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? TileCell, let track = CallManager.getRemoteVideoTrack(jid: jid) {
                                if let videoView = groupCell.videoBaseView {
                                    
                                    track.remove(member.videoTrackView)
                                    member.videoTrackView.removeFromSuperview()
                                    videoView.willRemoveSubview(member.videoTrackView)
                                }
                                
                            #if arch(arm64)
                                let localRen = RTCMTLVideoView(frame: .zero)
                            #else
                                let localRen = RTCEAGLVideoView(frame: .zero)
                            #endif
                                if let baseView = groupCell.videoBaseView  {
                                    member.videoTrackView = localRen
                                    member.videoTrackView.frame = CGRect(x: 0, y: 0, width: baseView.bounds.width, height: baseView.bounds.height)
                                    baseView.addSubview(member.videoTrackView)
                                    if jid == AppUtils.getMyJid() {
                                        if !member.isVideoMuted {
                                            //let track = CallManager.getRemoteVideoTrack(jid: jid)
                                            track.add(member.videoTrackView)
                                        }
                                    } else {
                                        if !member.isVideoMuted {
                                            //let videoTrack = CallManager.getRemoteVideoTrack(jid: jid)
                                            track.add(member.videoTrackView)
                                        }
                                    }
                                    
                                }
                               
                            }
                        }
                    }
                }
            }
        }else{
            print("#crash issue fixed")
        }
    }
    
    func switchLoaclandRemoteViews() {
        if isLocalViewSwitched {
            if let remoteView = outgoingCallView?.remoteUserVideoView {
                if let remoteTrack = CallManager.getRemoteVideoTrack(jid: members.first!.jid) {
                    members.first?.videoTrack = remoteTrack
                    addVideoTrack(to: UIView(), isLocal: true, track: remoteTrack)
                }
                if let localTrack =  CallManager.getRemoteVideoTrack(jid: members.last!.jid) {
                    members.last?.videoTrack = localTrack
                    addVideoTrack(to: remoteView, isLocal: false, track: localTrack)
                    addSwitchedRemoteTrackToView(localView: remoteView, isLocal: false)
                }
            }
        } else {
            if let remoteView = outgoingCallView?.remoteUserVideoView {
                if let localTrack = CallManager.getRemoteVideoTrack(jid: members.last!.jid)  {
                    members.last?.videoTrack = localTrack
                    addVideoTrack(to: UIView(), isLocal: true, track: localTrack)
                    addSwitchedRemoteTrackToView(localView: UIView(), isLocal: true)
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
//            self.localRenderer.removeFromSuperview()
//            view.willRemoveSubview(self.localRenderer)
//            self.localRenderer = localRen
//            localRenderer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
//            view.addSubview(localRenderer)
//            track.add(localRenderer)
            
            if let collectionView = outgoingCallView?.tileCollectionView {
                executeOnMainThread {
                    if self.members.count != collectionView.numberOfItems(inSection: 0){
                        collectionView.reloadData()
                    }else{
                        collectionView.performBatchUpdates {
                            if let tileCell = collectionView.cellForItem(at: IndexPath(item: self.showGridView ? 1 : 0, section: 0)) as? TileCell {
                                if let member = (self.isLocalViewSwitched) ? self.members.first : self.members.last {
                                    if let videoView = tileCell.videoBaseView {
                                        
                                        track.remove(member.videoTrackView)
                                        member.videoTrackView.removeFromSuperview()
                                        videoView.willRemoveSubview(member.videoTrackView)
                                    }
                            #if arch(arm64)
                                    let localRen = RTCMTLVideoView(frame: .zero)
                            #else
                                    let localRen = RTCEAGLVideoView(frame: .zero)
                            #endif
                                    if let baseView = tileCell.videoBaseView {
                                        member.videoTrackView = localRen
                                        member.videoTrackView.frame = CGRect(x: 0, y: 0, width: baseView.bounds.width, height: baseView.bounds.height)
                                        track.add(member.videoTrackView)
                                        baseView.addSubview(member.videoTrackView)
                                    }
                                }
                            }
                        }
                        
                    }
                }
            }
        } else {
            track.remove(self.remoteRenderer)
            self.remoteRenderer.removeFromSuperview()
            view.willRemoveSubview(self.remoteRenderer)
            self.remoteRenderer = localRen
            remoteRenderer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
            view.addSubview(remoteRenderer)
            track.add(remoteRenderer)
            
           if showGridView {
                if let collectionView = outgoingCallView?.tileCollectionView {
                    executeOnMainThread {
                        collectionView.performBatchUpdates {
                            if let tileCell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? TileCell {
                                if let member = self.members.first {
                                    if let videoView = tileCell.videoBaseView {
                                        track.remove(member.videoTrackView)
                                        member.videoTrackView.removeFromSuperview()
                                        videoView.willRemoveSubview(member.videoTrackView)
                                    }
                                    #if arch(arm64)
                                    let localRen = RTCMTLVideoView(frame: .zero)
                                    #else
                                    let localRen = RTCEAGLVideoView(frame: .zero)
                                    #endif
                                    if let baseView = tileCell.videoBaseView {
                                        member.videoTrackView = localRen
                                        member.videoTrackView.frame = CGRect(x: 0, y: 0, width: baseView.bounds.width, height: baseView.bounds.height)
                                        track.add(member.videoTrackView)
                                        baseView.addSubview(member.videoTrackView)
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
        if let remoteView = self.outgoingCallView?.remoteUserVideoView {
            self.remoteRenderer.removeFromSuperview()
            remoteView.willRemoveSubview(self.remoteRenderer)
        }
    }
    
    func oneToOneVideoViewTransforms(){
        if let remoteView = outgoingCallView?.remoteUserVideoView {
            if isBackCamera {
                if isLocalViewSwitched{
                    remoteView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }else{
                    //callHoldLabel.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }
            }else{
                if isLocalViewSwitched{
                    remoteView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                   // callHoldLabel.isHidden = true
                }else{
//                    callHoldLabel.isHidden = false
//                    callHoldLabel.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                }
            }
        }
    }
    func setHoldText(isShow: Bool) {
//        if let localView = outgoingCallView?.localUserVideoView {
//            if isShow {
//                if !localView.subviews.contains(callHoldLabel) {
//                    callHoldLabel = UILabel(frame: CGRect(x: 0, y: 0, width: localView.bounds.width, height: localView.bounds.height))
//                    self.callHoldLabel.isHidden = false
//                    callHoldLabel.textAlignment = .center
//                    callHoldLabel.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
//                    callHoldLabel.font = .systemFont(ofSize: 14)
//                    callHoldLabel.textColor = .white
//                    callHoldLabel.text = "Call on hold"
//                    localView.addSubview(callHoldLabel)
//                } else {
//                    self.callHoldLabel.isHidden = false
//                }
//            } else {
//                self.callHoldLabel.isHidden = true
//                localView.willRemoveSubview(callHoldLabel)
//                callHoldLabel.removeFromSuperview()
//            }
//        }
    }
    
    @objc func smallVideoTileTapped(_ sender: UITapGestureRecognizer) {
        
        showHideMenu = true
        removePopupView()
        
        if (!showGridView && (!(members.last?.isVideoMuted ?? false) && !(members.first?.isVideoMuted ?? false))) {
            
            switchVideoViews.onNext(true)
            
        }else {
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
        getContactNames()
        outgoingCallView?.tileCollectionView?.reloadData()
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
    
    func updateCallStatus(status : String = emptyString()){
        if !CallManager.isCallConnected() && status.contains("Reconnecting")  {
            return
        }
        if CallManager.getCallMode() == .MEET {
            outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = true
            outgoingCallView?.reconnectingLable?.isHidden = false
            let threeDot = status.contains("Reconnecting") ? "..." : ""
            outgoingCallView?.reconnectingLable?.text = ((status.contains("Reconnecting") || status == "Call on Hold") && !showGridView) ? "\(status)\(threeDot)" : ""
        }else{
            if (status == "Trying to connect" || status == "Unavailable, Try again later" || status == "Ringing" || status == "Disconnected" || status == "User Seems to be Offline, Trying to Connect" || status == "Connecting") {
                outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = false
                getContactNames()
                outgoingCallView?.OutGoingPersonLabel.isHidden = false
                outgoingCallView?.OutGoingPersonLabel.text  =  status == "User Seems to be Offline, Trying to Connect" ? "User Seems to be Offline,\n Trying to Connect\n" : status
                outgoingCallView?.OutGoingPersonLabel.numberOfLines = 0
                showHideDuration(hide:true)
            }else {
                
                outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = false
                if !status.contains("Reconnecting"){
                    outgoingCallView?.OutgoingRingingStatusLabel?.text = (status == "Connected" || status == "Call on Hold" || status == "Calling") ? "" : (status == "" ? getNameStringWithGroupName(userNames: "") : status)
                }
                let threeDot = status.contains("Reconnecting") ? "..." : ""
                outgoingCallView?.reconnectingLable?.isHidden = !((status.contains("Reconnecting") || status == "Call on Hold") && !showGridView)
                outgoingCallView?.reconnectingLable?.text = ((status.contains("Reconnecting") || status == "Call on Hold") && !showGridView) ? "\(status)\(threeDot)" : ""
                showHideDuration(hide: (status == "Disconnected" || status == "Connecting" || status.isEmpty) ? true : false)
            }
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
    
    func updateRemoteViewForMuteAndUnmute(){
        
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
    
    func showRippleView() {
        
        rippleView = PulsingHaloLayer()
        rippleView.position = CGPoint(x: (outgoingCallView?.audioWaveView.frame.width ?? 0)/2, y:  (outgoingCallView?.audioWaveView.frame.height ?? 0)/2)
        rippleView.radius = 80
        rippleView.haloLayerNumber = 5
        rippleView.backgroundColor = UIColor.lightGray.cgColor
        rippleView.start()
        outgoingCallView?.audioWaveView.layer.addSublayer(rippleView)
    }
    
    func setupTopViewConstraints() {
        
        outgoingCallView?.imageHeight.constant = 100
        outgoingCallView?.viewHeight.constant = 190
        outgoingCallView?.imageTop.constant = 28
    }
    
    func showHideCallBackgroundProfiles(hide: Bool) {
        print("###T showHideCallBackgroundProfiles Hide \(hide)")
        outgoingCallView?.outGoingAudioCallImageView.isHidden = hide
        outgoingCallView?.audioWaveView.isHidden = hide
        outgoingCallView?.OutGoingCallBG.isHidden = hide
        outgoingCallView?.OutGoingCallBG.image = (hide) ? nil : UIImage(named: "AudioCallBG")
        
    }
    
    func showHideMenuButton(hide : Bool){
        if CallManager.getCallMode() == .MEET{
            outgoingCallView?.menuButton.isHidden = false
        }else{
            outgoingCallView?.menuButton.isHidden = hide
        }
    }
    
    func setupTileViewConstraints(isRemoveUser: Bool) {
        if isRemoveUser{
            outgoingCallView?.tileCollectionWidth.constant = members.count <= 2 ? 110 : self.view.frame.size.width - 30
        }else{
            outgoingCallView?.tileCollectionWidth.constant = ((CallManager.isOneToOneCall() || members.count == 2) || (CallManager.getCallMode() == .MEET && members.count <= 2)) ? 110 : self.view.frame.size.width - 30
        }
    }
    
    func transformTileAndGridConstraints() {
        let collectionHeight = CGFloat(160)
        if showGridView{
            
            self.view.backgroundColor = .black
            
            flowLayout.scrollDirection = .vertical
            outgoingCallView?.tileCollectionView.collectionViewLayout = flowLayout
            outgoingCallView?.tileCollectionView.backgroundColor = .black
            
            outgoingCallView?.tileCollectionView.showsVerticalScrollIndicator = true
            
            outgoingCallView?.tileCollectionHeight?.constant = safeAreaHeight
            outgoingCallView?.tileCollectionTop.constant = 0
            outgoingCallView?.tileCollectionTrailing.constant = 0
            outgoingCallView?.tileCollectionLeading.isActive = true
            
        }else{
            
            self.view.backgroundColor = UIColor(hexString: "151F32")
            
            flowLayout.scrollDirection = .horizontal
            outgoingCallView?.tileCollectionView.collectionViewLayout = flowLayout
            outgoingCallView?.tileCollectionView.backgroundColor = .clear
            
            outgoingCallView?.tileCollectionView.showsVerticalScrollIndicator = false
            
            outgoingCallView?.tileCollectionHeight?.constant = collectionHeight
            outgoingCallView?.tileCollectionTop.constant = safeAreaHeight - ((outgoingCallView?.AttendingBottomView.frame.height ?? 0) + collectionHeight + 25)
            outgoingCallView?.tileCollectionTrailing.constant = -15
            outgoingCallView?.tileCollectionLeading.isActive = false
            
        }
        
//        outgoingCallView?.tileCollectionView.collectionViewLayout.invalidateLayout()
//        outgoingCallView?.tileCollectionView.layoutIfNeeded()
//        outgoingCallView?.tileCollectionView.layoutSubviews()
    }
    
    func showHideMultipleProfileImages(isConnected: Bool) {
        
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
                    outgoingCallView?.audioWaveView.isHidden = true
//                }
            }
        }
    }
}


extension CallUIViewController : MobileCallActionDelegate {
    func whileIncoming() {
        if outgoingCallView != nil { // check this condition if ui is presented
//            clearViews()
//            showHideCallAgainView(show: false, status: "")
//            dismiss(animated: true, completion: nil)
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
        print("#quality #sl \(quality.rawValue) ")
        if !CallManager.isCallConnected(){
            return
        }
        if qualityToastShown && quality != .poor{
            qualityToastShown = false
        }
        self.showHideQualityView(show: quality == .poor)
    }
    
    func showHideQualityView(show : Bool, fromTimer : Bool = false) {
        if qualityTimer == nil && show && !qualityToastShown {
            outgoingCallView?.qualityView?.closeView.addGestureRecognizer(closeGesture)
            qualityTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(qualityViewCloseTapped(_:)), userInfo: nil, repeats: false)
            outgoingCallView?.timerLable.isHidden = false
            qualityToastShown = true
            CallUIViewController.isQualityToastShowing = true
            executeOnMainThread {
                self.outgoingCallView?.qualityView?.isHidden = false
            }
        }else if show{
            executeOnMainThread {
                self.updateQualityInCollectionView()
                if CallManager.getCallMode() == .MEET && self.members.count == 1 && CallManager.getCallConnectionQuality() == .poor{
                    self.outgoingCallView?.qualityIcon.isHidden = false
                }
            }
        }else if !show{
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
        let index = self.getLastIndexInCollectionView()
        if let myCell = self.outgoingCallView?.tileCollectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? TileCell, CallManager.isCallConnected(){
            myCell.qualityView.isHidden = false
            print("#sl CELL :\(myCell.profileName.text)  INDEX : \(index)")
        }
    }
    
    @objc func qualityViewCloseTapped(_ sender: UITapGestureRecognizer) {
        outgoingCallView?.qualityView?.closeView.removeGestureRecognizer(closeGesture)
        qualityTimer?.invalidate()
        qualityTimer = nil
        self.showHideQualityView(show: false, fromTimer: true)
        
    }
    
    func getLastIndexInCollectionView() -> Int {
        if let items = self.outgoingCallView?.tileCollectionView?.numberOfItems(inSection: 0){
            return items - 1
        }
        return 0
    }
}
