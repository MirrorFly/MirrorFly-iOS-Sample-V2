//
//  FingerPrintPINViewController.swift
//  MirrorflyUIkit
//
//  Created by Ramakrishnan on 22/11/22.
//

import UIKit
import LocalAuthentication
import MirrorFlySDK

class PrivateChatFingerPrintPINViewController: BaseViewController {

    var isSystemCancel = false
    var isFromPrivateRecentChat: Bool = false
    var isFromPrivateChat: Bool = false
    var isFromContactScreen: Bool = false
    var privateChatDelegate: PrivateChatDelegate?

    var isFromSearchSelect: Bool = false
    var isFromNotificationSelect: Bool = false
    var isFromForward: Bool = false
    var isFromGroupInfo: Bool = false

    var isFromContactInfo: Bool = false

    @IBOutlet weak var descriptionLabel: UILabel! {
        didSet {
            if LAContext().biometricType == .none {
                descriptionLabel.text = emptyString()
                return
            }
            descriptionLabel.text = LAContext().biometricType == .faceID ? "Place your Face ID" : "Place your thumb on the home button"
        }
    }
    @IBOutlet weak var fingerPrintImage: UIImageView! {
        didSet {
            if LAContext().biometricType == .none {
                fingerPrintImage.isHidden = true
                return
            }
            fingerPrintImage.isHidden = LAContext().biometricType == .faceID
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        handleBackgroundAndForground()
        authenticationWithTouchID()
        CallUIViewController.dismissDelegate = self
    }

    override func viewDidDisappear(_ animated: Bool) {
        CallUIViewController.dismissDelegate = nil
    }

    func showAlert() {
        AppAlert.shared.showAlert(view: self,
                                  title: tooManyFailedAttempts,
                                  message: settingsNavigateMessage,
                                  buttonOneTitle: openSettingsMessage,
                                  buttonTwoTitle: cancelUppercase,
                                  showSecondButton: false)
        AppAlert.shared.onAlertAction = { (result) -> Void in
            if result == 0 {
                guard let profileUrl = URL(string : "App-Prefs:") else { return }
                UIApplication.shared.open(profileUrl, options: [:], completionHandler: nil)
            }
        }
    }

    func daysBetween(start: Date, end: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: start, to: end).day!
    }

    func authenticationWithTouchID() {
        let context = LAContext()
        var error: NSError?
        CommonDefaults.permissionAlertShown = false
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify yourself!"
            self.isSystemCancel = false
            CommonDefaults.permissionAlertShown = true
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [weak self] success, authenticationError in
                CommonDefaults.permissionAlertShown = false
                DispatchQueue.main.async {
                    if success {
                        if self?.isFromPrivateChat ?? false {
                            self?.navigationController?.popViewController(animated: true)
                            self?.privateChatDelegate?.onPasswordSet()
                        } else if self?.isFromPrivateRecentChat ?? false {
                            self?.navigationController?.popViewController(animated: true)
                            self?.privateChatDelegate?.onPrivateChatAuthenticated()
                        } else if (self?.isFromSearchSelect ?? false) || (self?.isFromNotificationSelect ?? false) || pushNotificationSelected {
                            self?.navigationController?.popViewController(animated: true)
                            pushNotificationSelected = false
                        } else if CommonDefaults.privateChatOnChatScreen || (self?.isFromContactScreen ?? false) || (self?.isFromForward ?? false) || (self?.isFromGroupInfo ?? false) || (self?.isFromContactInfo ?? false) {
                            CommonDefaults.privateChatOnChatScreen = false
                            self?.navigationController?.popViewController(animated: true)
                        } else if CommonDefaults.showPrivateLockRecent {
                            self?.navigationController?.popViewController(animated: true)
                            CommonDefaults.showPrivateLockRecent = false
                        } else {
                            if self?.daysBetween(start: CommonDefaults.appLockPasswordDate, end: Date()) ?? 0 >= 31 {
                                let initialViewController = PrivateChatAuthenticationPINViewController(nibName: "PrivateChatAuthenticationPINViewController", bundle: nil)
                                initialViewController.isFromPrivateChat = self?.isFromPrivateChat ?? false
                                initialViewController.noFingerprintAdded = true
                                self?.navigationController?.pushViewController(initialViewController, animated: false)
                            } else {
                                CommonDefaults.showAppLock = false
                                CommonDefaults.passwordAuthenticationAttemps = 0
                                self?.navigationController?.popToRootViewController(animated: false)
                                self?.dismiss(animated: false)
                            }
                        }
                    } else {
                        guard let error = authenticationError else {
                            return
                        }
                        self?.evaluateAuthenticationError(errorCode: error._code)
                    }
                }
            }
        } else {
            evaluateAuthenticationError(errorCode: error?._code ?? 0)
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
        case LAError.biometryLockout.rawValue:
            isSystemCancel = true
            showAlert()
            break
        case LAError.systemCancel.rawValue:
            isSystemCancel = true
        case LAError.biometryNotEnrolled.rawValue:
            AppAlert.shared.showToast(message: ErrorMessage.fingerPrintIsNotRegisteredinDevice)
            navigateToAuthentication(isNotEnrolled: true)
        case LAError.biometryNotAvailable.rawValue:
            AppAlert.shared.showToast(message: ErrorMessage.fingerPrintIsNotRegisteredinDevice)
            navigateToAuthentication(isNotEnrolled: true)
        default:
            break
        }
    }

    func navigateToAuthentication(isNotEnrolled: Bool = false) {
        isSystemCancel = false
        let initialViewController = PrivateChatAuthenticationPINViewController(nibName: "PrivateChatAuthenticationPINViewController", bundle: nil)
        initialViewController.fingerPrintLogin = true
        initialViewController.isFromPrivateChat = isFromPrivateChat
        initialViewController.isFromPrivateRecentChat = isFromPrivateRecentChat
        initialViewController.isFromSearchSelect = isFromSearchSelect
        initialViewController.isFromNotificationSelect = isFromNotificationSelect
        initialViewController.isFromContactScreen = isFromContactScreen
        initialViewController.isFromForward = isFromForward
        initialViewController.isFromGroupInfo = isFromGroupInfo
        initialViewController.isFromContactInfo = isFromContactInfo
        if isNotEnrolled {
            initialViewController.noFingerprintAdded = true
        }
        if let _ = self.navigationController {
            self.navigationController?.pushViewController(initialViewController, animated: false)
        } else {
            initialViewController.modalPresentationStyle = .fullScreen
            self.present(initialViewController, animated: false)
        }
    }


}



extension PrivateChatFingerPrintPINViewController: CallDismissDelegate {
    func onCallControllerDismissed() {
        showAlert()
    }
}
