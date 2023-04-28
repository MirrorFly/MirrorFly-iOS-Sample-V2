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

    private let displayStatusChangedCallback: CFNotificationCallback = { _, cfObserver, cfName, _, _ in
        guard let lockState = cfName?.rawValue as String? else {return}
        if (lockState == "com.apple.springboard.lockcomplete") {
            ShareViewController().handleDisplayStatus()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}

//Check User Login
extension ShareViewController {

    func handleDisplayStatus() {
        if (FlyDefaults.appLockenable || FlyDefaults.appFingerprintenable) {
            FlyDefaults.showAppLock = true
        }
        exit(0)
    }

    @objc func handleBackgroundStatus() {
        if (FlyDefaults.appLockenable || FlyDefaults.appFingerprintenable) {
            FlyDefaults.showAppLock = true
        }
        exit(0)
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
        if FlyDefaults.showAppLock {
            if FlyDefaults.appFingerprintenable  && FlyDefaults.appLockenable {
                if !FlyDefaults.faceOrFingerAuthenticationFails {
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
            } else if FlyDefaults.appLockenable && FlyDefaults.appFingerprintenable == false {
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
        //Screen lock notifications
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),     //center
            Unmanaged.passUnretained(self).toOpaque(),     // observer
            displayStatusChangedCallback,     // callback
            "com.apple.springboard.lockcomplete" as CFString,     // event name
            nil,     // object
            .deliverImmediately)

        NotificationCenter.default.addObserver(self, selector: #selector(handleBackgroundStatus), name: UIApplication.didEnterBackgroundNotification, object: nil)

    }
}
