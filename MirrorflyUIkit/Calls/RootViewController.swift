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
    var callViewController : CallUIViewController?
    
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
    
    func getDisplayName(IncomingUser :[String], incomingUserName: String, metaData: [CallMetadata]) -> [String] {
        return self.callViewController?.getDisplayName(IncomingUser: IncomingUser, incomingUserName: incomingUserName, metaData: metaData) ?? []
    }
    
    func socketConnectionEstablished() {
        
    }
    
    func onCallStatusUpdated(callStatus: CALLSTATUS, userId: String) {
        print("#root onCallStatusUpdated \(callStatus.rawValue) userJid : \(userId)")
        
        
        DispatchQueue.main.async { [weak self] in
            
            switch callStatus {
            case .ATTENDED:
                if userId == AppUtils.getMyJid(){
                    CallManager.callUiDelegate?.uiPresented()
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
                            presentedViewController.dismiss(animated: false)
                        }
                    }
                    let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
                    if  let navigationController = window?.rootViewController as? UINavigationController {
                        if CallManager.getCallDirection() == .Incoming &&  (navigationController.presentedViewController?.isKind(of: CallUIViewController.self) == false || navigationController.presentedViewController == nil){
                            if let callController = self?.callViewController {
                                callController.members.removeAll()
                                callController.modalPresentationStyle = .fullScreen
                                let navigationStack = UINavigationController(rootViewController: callController)
                                navigationStack.setNavigationBarHidden(true, animated: false)
                                navigationStack.modalPresentationStyle = .fullScreen
                                window?.rootViewController?.present(navigationStack, animated: true, completion: {
                                })
                            }
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
            callViewController = UIStoryboard(name: "Call", bundle: nil).instantiateViewController(withIdentifier: "CallUIViewController") as? CallUIViewController
        }
        CallManager.setMyInfo(name: ContactManager.getMyProfile().name, imageUrl: ContactManager.getMyProfile().image)
        if let callViewController = callViewController {
            CallManager.setCallViewController(callViewController)
        }
        CallManager.setCallEventsDelegate(delegate:  RootViewController.sharedInstance)

    }
}

