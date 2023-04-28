//
//  ShareKitBaseViewController.swift
//  MirrorflyUIkit
//
//  Created by John on 17/02/23.
//

import UIKit
import MirrorFlySDK


class ShareKitBaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
//    override func isContentValid() -> Bool {
//        // Do validation of contentText and/or NSExtensionContext attachments here
//        return true
//    }
//
//    override func didSelectPost() {
//        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
//
//        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
//        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
//    }
//
//    override func configurationItems() -> [Any]! {
//        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
//        return []
//    }
    
    func handleBackgroundAndForground() {
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(didMoveToBackground), name: UIScene.willDeactivateNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(willCometoForeground), name: UIScene.willEnterForegroundNotification, object: nil)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(didMoveToBackground), name: UIApplication.willResignActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(willCometoForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        }
    }
    
    @objc func didMoveToBackground() {
        print("UIViewController moved to background")
        
    }
    
    @objc func willCometoForeground() {
        print("UIViewController appComestoForeground")
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        print("keyboardWillShow")
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        print("keyboardWillHide")
    }
    
    func keyboardShowHide() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func requestLogout() {
        startLoading(view: self , withText: pleaseWait)
        
        ChatManager.logoutApi { [weak self] isSuccess, flyError, flyData in
            guard let self else { return }
            if isSuccess {
                FlyDefaults.appLockPassword = ""
                FlyDefaults.appLockenable = false
                FlyDefaults.hideLastSeen = false
                self.stopLoading()
                Utility.saveInPreference(key: isProfileSaved, value: false)
                Utility.saveInPreference(key: isLoggedIn, value: false)
                ChatManager.disconnect()
                ChatManager.resetXmppResource()
//                var controller : OTPViewController?
//                if #available(iOS 13.0, *) {
//                    controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "OTPViewController")
//                } else {
//
//                    controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "OTPViewController") as? OTPViewController
//                }
//                let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
//                if let navigationController = window?.rootViewController  as? UINavigationController, let otpViewController = controller {
//                    navigationController.popToRootViewController(animated: false)
//                    navigationController.pushViewController(otpViewController, animated: false)
//                }
//

            }else{
                print("Logout api error : \(String(describing: flyError))")
                self.stopLoading()
            }
        }
    }

}
