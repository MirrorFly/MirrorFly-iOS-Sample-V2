//
//  RootViewController.swift
//  MirrorFlyiOS-SDK
//
//  Created by User on 16/07/21.
//

import Foundation
import UIKit
import MirrorFlySDK
import LocalAuthentication

@objc class RootViewController : NSObject {
    public static var sharedInstance = RootViewController()
    var callViewController : CallViewController?
    
    override init() {
        super.init()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension RootViewController : CallManagerDelegate {

    func onRemoteVideoTrackAdded(userId: String, track: RTCVideoTrack) {
        callViewController?.onRemoteVideoTrackAdded(userId: userId, track: track)
    }
    
    
    func onUserSpeaking(userId: String, audioLevel: Int) {
        callViewController?.onUserSpeaking(userId: userId, audioLevel: audioLevel)
    }
    
    func onUserStoppedSpeaking(userId: String) {
        callViewController?.onUserStoppedSpeaking(userId: userId)

    }
    
    func getGroupName(_ groupId: String) {
        callViewController?.getGroupName(groupId)
    }
    
    func onVideoTrackAdded(userJid: String) {
        
    }
    
    func getDisplayName(IncomingUser :[String]) {
        DispatchQueue.main.async { [weak self] in
            self?.callViewController?.getDisplayName(IncomingUser: IncomingUser)
        }
        
    }
    
    func socketConnectionEstablished() {
        
    }
    
    func onCallStatusUpdated(callStatus: CALLSTATUS, userId: String) {
        print("#root onCallStatusUpdated \(callStatus.rawValue) userJid : \(userId)")
        
        
        DispatchQueue.main.async { [weak self] in
            if userId == AppUtils.getMyJid() && (callStatus != .RECONNECTING && callStatus != .RECONNECTED) {
                return
            }
            
            switch callStatus {
            case .ATTENDED:

                if (CommonDefaults.appLockenable || CommonDefaults.appFingerprintenable) {
                    let secondsDifference = Calendar.current.dateComponents([.minute, .second], from: CommonDefaults.appBackgroundTime, to: Date())
                    if secondsDifference.second ?? 0 > 32 || secondsDifference.minute ?? 0 > 0 {
                        CommonDefaults.showAppLock = true
                        CommonDefaults.appLockOnPrivateChat = false
                        CommonDefaults.privateChatOnChatScreen = false
                    }
                }

                if let topController = UIApplication.shared.keyWindow?.rootViewController {
                    if let presentedViewController = topController.presentedViewController {
                        if presentedViewController.isKind(of: UIAlertController.self) {
                            presentedViewController.dismiss(animated: false)
                        }
                    }
                }
                let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
                if  let navigationController = window?.rootViewController as? UINavigationController {
                    if CallManager.getCallDirection() == .Incoming &&  (navigationController.presentedViewController?.isKind(of: CallViewController.self) == false || navigationController.presentedViewController == nil){
                        if let callController = self?.callViewController {
                            callController.modalPresentationStyle = .overFullScreen
                            let navigationStack = UINavigationController(rootViewController: callController)
                            navigationStack.setNavigationBarHidden(true, animated: true)
                            navigationStack.modalPresentationStyle = .overFullScreen
                            window?.rootViewController?.present(navigationStack, animated: true, completion: {
                            })
                        }
                    }
                }
            case .CONNECTED:
                print("CALL CONNECTED")
            case .DISCONNECTED:
                print("CALL DISCONNECTED")
            case .ON_HOLD:
                print("")
            case .ON_RESUME:
                print("")
            case .USER_JOINED:
                print("")
            case .USER_LEFT:
                print("")
            case .INVITE_CALL_TIME_OUT:
                print("")
            case .CALL_TIME_OUT:
                print("")
            case .RECONNECTING:
                print("")
            case .RECONNECTED:
                print("")
            case .CALLING_10S:
                print("")
            case .CALLING_AFTER_10S:
                print("")
            case .CONNECTING:
                print("")
            case .RINGING:
                print("")
            case .CALLING:
                print("")
            case .ATTENDED:
                print("")
            }
            
            self?.callViewController?.onCallStatusUpdated(callStatus: callStatus, userId: userId)
        }
    }
    
    func onCallAction(callAction: CallAction, userId: String) {
        callViewController?.onCallAction(callAction: callAction, userId: userId)
    }
    
    func onLocalVideoTrackAdded(userId: String, videoTrack: RTCVideoTrack) {
        callViewController?.onLocalVideoTrackAdded(userId: userId, videoTrack: videoTrack)
    }
    
    func onMuteStatusUpdated(muteEvent: MuteEvent, userId: String) {
        callViewController?.onMuteStatusUpdated(muteEvent: muteEvent, userId: userId)
    }
    
}

extension RootViewController {
    
    public func initCallSDK(){
        if callViewController == nil {
            callViewController = UIStoryboard(name: "Call", bundle: nil).instantiateViewController(withIdentifier: "CallViewController") as? CallViewController
        }
        
        do {
            try CallManager.initCallSDK()
        }
        catch(let error ) {
            var iceServerList = [RTCIceServer]()
            let iceServer = RTCIceServer.init(urlStrings: ["turn:stun.contus.us:3478"], username: "contus", credential: "SAE@admin")
            iceServerList.append(iceServer)
            let iceServer1 = RTCIceServer.init(urlStrings: ["stun:stun.l.google.com:19302"], username: "", credential: "")
            iceServerList.append(iceServer1)
            try? CallSDK.Builder.setUserId(id: AppUtils.getMyJid())
                .setDomainBaseUrl(baseUrl: "https://api-beta.mirrorfly.com/api/v1/")
                .setSignalSeverUrl(url: "https://signal-beta.mirrorfly.com/")
                .setJanusSeverUrl(url: "wss://janus.mirrorfly.com")
                .setAppGroupContainerID(containerID: CONTAINER_ID)
                .setICEServersList(iceServers: iceServerList)
                .setCallDelegate(delegate: RootViewController.sharedInstance)
                .setCallViewController(viewController: callViewController!)
                .buildAndInitialize()
        }
        CallManager.setMyInfo(name: ContactManager.getMyProfile().name, imageUrl: ContactManager.getMyProfile().image)
        if let callViewController = callViewController {
            CallManager.setCallViewController(callViewController)
        }
        CallManager.setCallEventsDelegate(delegate:  RootViewController.sharedInstance)
        
    }
}

