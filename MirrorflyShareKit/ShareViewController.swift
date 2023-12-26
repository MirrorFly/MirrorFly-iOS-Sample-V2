//
//  ShareViewController.swift
//  MirrorflyShareKit
//
//  Created by John on 17/02/23.
//

import UIKit
import MirrorFlySDK
import Firebase

class ShareViewController: ShareKitBaseViewController {
    let shareKitViewModel = ShareKitViewModel.shared
    var attachments: [NSItemProvider] = [NSItemProvider]()

    override func viewDidLoad() {
        super.viewDidLoad()
        registerforDeviceLockNotification()
        checkForLogin()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}

//Check User Login
extension ShareViewController {

    @objc func handleBackgroundStatus() {
        if let controller = self.navigationController?.topViewController {
            if !(controller is FingerPrintPINViewController) {
                if (CommonDefaults.appLockenable || CommonDefaults.appFingerprintenable) {
                    CommonDefaults.showAppLock = true
                }
                exit(0)
            }
        }
    }
    
    private func checkForLogin() {
        if !shareKitViewModel.isLoggedIn() {
            ShareKitAlert.shared.showAlert(view: self, title: pleaseLogIn, message: needToLogIntoMirrorFly, buttonTitle: ok) { number in
                ShareKitUtility.shared.exitApp()
            }
        } else {
            ChatManager.connect()
            checkForAppLock()
        }
    }
}

// Check For AppLock
extension ShareViewController {
    
    private func checkForAppLock() {
        if CommonDefaults.showAppLock {
            if CommonDefaults.appFingerprintenable  && CommonDefaults.appLockenable {
                if !CommonDefaults.faceOrFingerAuthenticationFails {
                    let initialViewController = FingerPrintPINViewController(nibName: "FingerPrintPINViewController", bundle: nil)
                    self.navigationController?.setNavigationBarHidden(true, animated: true)
                    self.navigationController?.pushViewController(initialViewController, animated: false)
                } else {
                    let initialViewController = AuthenticationPINViewController(nibName: "AuthenticationPINViewController", bundle: nil)
                    initialViewController.login = true
                    initialViewController.modalPresentationStyle = .fullScreen
                    self.navigationController?.setNavigationBarHidden(true, animated: true)
                    self.navigationController?.pushViewController(initialViewController, animated: false)
                }
            } else if CommonDefaults.appLockenable && CommonDefaults.appFingerprintenable == false {
                let initialViewController = AuthenticationPINViewController(nibName: "AuthenticationPINViewController", bundle: nil)
                initialViewController.login = true
                initialViewController.modalPresentationStyle = .fullScreen
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                self.navigationController?.pushViewController(initialViewController, animated: false)
            }
        } else {
            if attachments.count > 10 {
                ShareKitAlert.shared.showToast(controller: self, message: "_Can't share more than 10 media files_")
            } else {
                let initialViewController = SharekitShareToViewController(nibName: "SharekitShareToViewController", bundle: nil)
                initialViewController.attachments = attachments
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                self.navigationController?.pushViewController(initialViewController, animated: false)
            }
        }
    }
}

extension ShareViewController {
    func registerforDeviceLockNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleBackgroundStatus), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleBackgroundStatus), name: UIApplication.willResignActiveNotification, object: nil)

    }
}
