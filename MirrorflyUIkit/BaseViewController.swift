//
//  BaseViewController.swift
//  MirrorflyUIkit
//
//  Created by John on 08/08/22.
//

import Foundation
import UIKit
import MirrorFlySDK

public protocol MessageDelegate {
    func whileUpdatingMessageStatus(messageId: String, chatJid: String, status: MessageStatus)
    func whileUpdatingTheirProfile(for jid: String, profileDetails: ProfileDetails)
}

public protocol RefreshChatDelegate {
    func refresh()
}

public func print(items: Any..., separator: String = " ", terminator: String = "\n") {
    let output = items.map { "*\($0)" }.joined(separator: separator)
    Swift.print(output, terminator: terminator)
}

class BaseViewController : UIViewController {
    
    private let TAG = "BaseViewController"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CallManager.setMobileCallActionDelegate(delegate: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        CallManager.setMobileCallActionDelegate(delegate: nil)
    }
    
    func disableIdleTimer(disable : Bool) {
        UIApplication.shared.isIdleTimerDisabled = disable
    }
    
    func keyboardShowHide() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        print("keyboardWillShow")
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        print("keyboardWillHide")
    }
    
    func requestLogout() {
        startLoading(withText: pleaseWait)
        
        ChatManager.logoutApi { [weak self] isSuccess, flyError, flyData in
            
            if isSuccess {
                CommonDefaults.appLockPassword = ""
                CommonDefaults.appLockenable = false
                CommonDefaults.appFingerprintenable = false

                ChatManager.getPrivateChatList { isSuccess, error, data in
                    if let list = data["data"] as? [RecentChat] {
                        for chat in list {
                            ChatManager.setPrivateChat(jid: chat.jid, isPrivate: false)
                        }
                    }
                }

                UIApplication.shared.applicationIconBadgeNumber = 0
                self?.stopLoading()
                Utility.saveInPreference(key: isProfileSaved, value: false)
                Utility.saveInPreference(key: isLoggedIn, value: false)
                ChatManager.disconnect()
                ChatManager.resetXmppResource()
                var controller : OTPViewController?
                if #available(iOS 13.0, *) {
                    controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "OTPViewController")
                } else {
                   
                    controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "OTPViewController") as? OTPViewController
                }
                let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
                if let navigationController = window?.rootViewController  as? UINavigationController, let otpViewController = controller {
                    navigationController.popToRootViewController(animated: false)
                    navigationController.pushViewController(otpViewController, animated: false)
                }
                

            }else{
                print("Logout api error : \(String(describing: flyError))")
                self?.stopLoading()
            }
        }
    }

}


/**
 * General call action Delegate to detect from mobile (other applications)
 * It is not used to application call actions
 */
extension BaseViewController : MobileCallActionDelegate {
    @objc func didCallAnswered() {
        print("\(TAG) didCallAnswered")
    }
    
    @objc func whileDialing() {
        print("\(TAG) whileDialing")
    }
    
    @objc func didCallDisconnected() {
        print("\(TAG) didCallDisconnected")
    }
    
    @objc func whileIncoming() {
        print("\(TAG) whileIncoming")
    }
}
