//
//  FingerPrintPINViewController.swift
//  MirrorflyUIkit
//
//  Created by Ramakrishnan on 22/11/22.
//

import UIKit
import LocalAuthentication
import MirrorFlySDK

class FingerPrintPINViewController: ShareKitBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        handleBackgroundAndForground()
    }

    func daysBetween(start: Date, end: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: start, to: end).day!
    }
    
    override func viewWillAppear(_ animated: Bool) {
        authenticationWithTouchID()
    }
    
    override func willCometoForeground() {
        authenticationWithTouchID()
    }

    func authenticationWithTouchID() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify yourself!"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [weak self] success, authenticationError in
                print("\(TAG) #### evaluatePolicy \(success) \(authenticationError.debugDescription)")
                DispatchQueue.main.async {
                    if success {
                        CommonDefaults.showAppLock = false
                        let initialViewController = SharekitShareToViewController(nibName: "SharekitShareToViewController", bundle: nil)
                        self?.navigationController?.setNavigationBarHidden(true, animated: true)
                        self?.navigationController?.pushViewController(initialViewController, animated: false)
                    } else {
                        guard let error = authenticationError else {
                            return
                        }
                        self?.evaluateAuthenticationError(errorCode: error._code)
                    }
                }
            }
        } else {
            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.fingerPrintIsNotRegisteredinDevice)
            let initialViewController = AuthenticationPINViewController(nibName: "AuthenticationPINViewController", bundle: nil)
            initialViewController.noFingerprintAdded = true
            self.navigationController?.pushViewController(initialViewController, animated: false)
        }
    }

    func evaluateAuthenticationError(errorCode: Int) {
        switch errorCode {
        case LAError.authenticationFailed.rawValue:
            navigateToAuthentication()
            CommonDefaults.faceOrFingerAuthenticationFails = true
        case LAError.userCancel.rawValue:
            navigateToAuthentication()
        case LAError.userFallback.rawValue:
            //FlyDefaults.faceOrFingerAuthenticationFails = true
            navigateToAuthentication()
        default:
            break
        }
    }

    func navigateToAuthentication() {
        let initialViewController = AuthenticationPINViewController(nibName: "AuthenticationPINViewController", bundle: nil)
        initialViewController.fingerPrintLogin = true
        self.navigationController?.pushViewController(initialViewController, animated: false)
    }


}
