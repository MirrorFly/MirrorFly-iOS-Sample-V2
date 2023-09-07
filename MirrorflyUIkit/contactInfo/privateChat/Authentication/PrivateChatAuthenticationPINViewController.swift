//
//  AuthenticationPINViewController.swift
//  UiKitQa
//
//  Created by Ramakrishnan on 09/11/22.
//

import UIKit
import FirebaseAuth
import MirrorFlySDK
import PhoneNumberKit
import SafariServices
import SwiftUI

class PrivateChatAuthenticationPINViewController: BaseViewController, UITextFieldDelegate {
    
    var pinInput = ""
    var phoneNumber = ""
    var login : Bool = false
    var logout : Bool = false
    var fingerPrintLogin : Bool = false
    var fingerPrintLogout : Bool = false
    var fingerPrintEnable : Bool = false
    var noFingerprintAdded : Bool = false
    var  disableBothPIN : Bool = false

    var isResetByFailedAttempts = false
    var authenticationFails = true
    
    public var verificationId = ""
    var isAuthorizedSuccess: Bool = false
    var secondsRemaining = passwordResetTimer
    var timer: Timer?
    var currentBackgroundDate = Date()

    var isFromPrivateChat: Bool = false
    var isFromPrivateRecentChat: Bool = false
    var privateChatDelegate: PrivateChatDelegate?
    var isFromSearchSelect: Bool = false
    var isFromNotificationSelect: Bool = false
    var isFromContactScreen: Bool = false
    var isFromForward: Bool = false
    var isFromGroupInfo: Bool = false
    var isFromContactInfo: Bool = false
    
    public var verifyOTPViewModel : VerifyOTPViewModel!
    public var otpViewModel : OTPViewModel!
    
    var array = ["1","2","3","4","5","6","7","8","9","","0", "CLEAR"]
    
    @IBOutlet weak var resendHideView: UIView!
    
    @IBOutlet weak var resendOTP: UIButton!
    
    @IBOutlet weak var initialmainView: UIView!
    
    @IBOutlet weak var forgotpinBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var hideForgotView: UIView!
    
    @IBOutlet weak var forgotButtonoutlet: UIButton!
    
    @IBOutlet weak var txtFirst: UITextField!
    @IBOutlet weak var txtSecond: UITextField!
    @IBOutlet weak var txtThird: UITextField!
    @IBOutlet weak var txtForth: UITextField!
    @IBOutlet weak var txtFifth: UITextField!
    @IBOutlet weak var txtSixth: UITextField!
    
    @IBOutlet weak var timeout: UILabel!
    
    @IBOutlet weak var collectionview: UICollectionView!
    
    @IBOutlet weak var pinEnteredcollectionview: UICollectionView!

    var isDisablePin = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        textfieldBackgroundcolour()
        configureDefaults()
        handleBackgroundAndForground()
        didMoveToBackground()
        willCometoForeground()
        CallViewController.dismissDelegate = self
    }

    override func viewDidDisappear(_ animated: Bool) {
        CallViewController.dismissDelegate = nil
    }

    func showAlerts() {
        if CommonDefaults.showAppLock {
            if CommonDefaults.passwordAuthenticationAttemps > 5 {
                showfailedAttempsActionAlert()
            } else if !isFromPrivateChat && !isFromPrivateRecentChat {
                if daysBetween(start: CommonDefaults.appLockPasswordDate, end: Date()) > 31-5 && daysBetween(start: CommonDefaults.appLockPasswordDate, end: Date()) < 31 {
                    if CommonDefaults.pinChangeAlertShownDate != Date().xmppDateString {
                        showChangePinAlert()
                    }
                } else if daysBetween(start: CommonDefaults.appLockPasswordDate, end: Date()) >= 31 {
                    showPinActionAlert()
                }
            }
        }
    }

    func showPinActionAlert() {

        let values : [String] = AppLockActions.allCases.map { $0.rawValue }
        var actions = [(String, UIAlertAction.Style)]()
        values.forEach { title in
            if title == AppLockActions.forgotPin.rawValue {
                actions.append((title, UIAlertAction.Style.destructive))
            } else {
                actions.append((title, UIAlertAction.Style.default))
            }

        }
        AppActionSheet.shared.showActionSeet(title : "", message: "Your current PIN has been expired. Please set a new PIN to continue further", showCancel: false, actions: actions, style: .alert, sheetCallBack: { [weak self] didCancelTap, tappedTitle in
            if !didCancelTap {
                switch tappedTitle {
                case AppLockActions.changePin.rawValue:
                    self?.isDisablePin = false
                    let vc = ChangeAppLockViewController(nibName:Identifiers.changeAppLockViewController, bundle: nil)
                    self?.navigationController?.pushViewController(vc, animated: false)
                case AppLockActions.forgotPin.rawValue:
                    self?.isDisablePin = false
                    self?.forgotbutton(tappedTitle)
                case AppLockActions.disablePin.rawValue:
                    self?.isDisablePin = true
                    AppAlert.shared.showToast(message: "Enter current pin to disable pin and fingerprint")
                default:
                    print(" \(tappedTitle)")
                }
            } else {
                print("createGroup Cancel")
            }
        })

    }

    func showfailedAttempsActionAlert() {

        let alertViewController = UIAlertController.init(title: "Invalid PIN, Generate OTP to your registered mobile number", message:"" , preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { [weak self] (action) in
            
        }
        let blockAction = UIAlertAction(title: "Generate OTP", style: .default) { [weak self] (action) in
            
            self?.clearTextFields()
            self?.timeout.text = "01:00"
            self?.secondsRemaining = passwordResetTimer
            self?.resendHideView.isHidden = true
            self?.timeout.isHidden = false
            self?.forgotPassword()
            self?.isResetByFailedAttempts = true
            
        }
        alertViewController.addAction(cancelAction)
        alertViewController.addAction(blockAction)
        present(alertViewController, animated: true)
    }

    func showChangePinAlert() {
        CommonDefaults.pinChangeAlertShownDate = Date().xmppDateString

        let values : [String] = ["Change PIN", "OK"]
        var actions = [(String, UIAlertAction.Style)]()
        values.forEach { title in
            actions.append((title, UIAlertAction.Style.default))
        }

        AppActionSheet.shared.showActionSeet(title : "", message: "Your PIN will be expired in \(31 - daysBetween(start: CommonDefaults.appLockPasswordDate, end: Date())) day(s)", showCancel: false, actions: actions, style: .alert, sheetCallBack: { [weak self] didCancelTap, tappedTitle in
            if !didCancelTap {
                switch tappedTitle {
                case "Change PIN":
                    let vc = ChangeAppLockViewController(nibName:Identifiers.changeAppLockViewController, bundle: nil)
                    self?.navigationController?.pushViewController(vc, animated: false)
                default:
                    print(" \(tappedTitle)")
                }
            } else {
                print("createGroup Cancel")
            }
        })
    }

    func daysBetween(start: Date, end: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: start, to: end).day!
    }

    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        showAlerts()
    }
    
    func setupUI() {
        resendOTP.titleLabel?.font = UIFont.font14px_appRegular()
        txtFirst.font = UIFont.font16px_appSemibold()
        txtSecond.font = UIFont.font16px_appSemibold()
        txtThird.font = UIFont.font16px_appSemibold()
        txtForth.font = UIFont.font16px_appSemibold()
        txtFifth.font = UIFont.font16px_appSemibold()
        txtSixth.font = UIFont.font16px_appSemibold()
        
        txtFirst.tag = 1
        txtSecond.tag = 2
        txtThird.tag = 3
        txtForth.tag = 4
        txtFifth.tag = 5
        txtSixth.tag = 6
        
        hideForgotView.clipsToBounds = true
        hideForgotView.layer.cornerRadius = 15
        hideForgotView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        self.initialmainView.backgroundColor = UIColor.clear
        if fingerPrintLogin == true || login == true{
            self.forgotButtonoutlet.isHidden = false
        }
        else if fingerPrintLogout == true || logout == true || disableBothPIN == true || fingerPrintEnable == true {
            self.forgotButtonoutlet.isHidden = true
        }
        txtFirst.delegate = self
        txtSecond.delegate = self
        txtThird.delegate = self
        txtForth.delegate = self
        txtFifth.delegate = self
        txtSixth.delegate = self
        txtFirst.textContentType = .oneTimeCode
        txtSecond.textContentType = .none
        txtThird.textContentType = .none
        txtForth.textContentType = .none
        txtFifth.textContentType = .none
        txtSixth.textContentType = .none
    }
    
    func textfieldBackgroundcolour(){
        txtFirst.backgroundColor = UIColor.white
        txtSecond.backgroundColor = UIColor.white
        txtThird.backgroundColor = UIColor.white
        txtForth.backgroundColor = UIColor.white
        txtFifth.backgroundColor = UIColor.white
        txtSixth.backgroundColor = UIColor.white
    }
    
    func configureDefaults(){
        
        self.timeout.text = "01:00"
        sheduletimer()
        txtFirst.textContentType = .username
        txtSecond.textContentType = .username
        txtThird.textContentType = .username
        txtForth.textContentType = .username
        txtFifth.textContentType = .username
        txtSixth.textContentType = .username
        txtFirst.delegate = self
        txtSecond.delegate = self
        txtThird.delegate = self
        txtForth.delegate = self
        txtFifth.delegate = self
        txtSixth.delegate = self
        verifyOTPViewModel =  VerifyOTPViewModel()
        otpViewModel = OTPViewModel()
        phoneNumber = ContactManager.getMyProfile().mobileNumber
        
        self.collectionview.register(UINib(nibName:Identifiers.authenticationPINCollectionViewCell, bundle: .main), forCellWithReuseIdentifier:Identifiers.authenticationPINCollectionViewCell)
        
        self.pinEnteredcollectionview.register(UINib(nibName: Identifiers.pinEnteredCollectionViewCell, bundle: .main), forCellWithReuseIdentifier: Identifiers.pinEnteredCollectionViewCell)
        self.collectionview.delegate = self
        self.collectionview.dataSource = self
        self.pinEnteredcollectionview.delegate = self
        self.pinEnteredcollectionview.dataSource = self
    }
    
    func clearTextFields() {
        txtFirst.text = ""
        txtSecond.text = ""
        txtThird.text = ""
        txtForth.text = ""
        txtFifth.text = ""
        txtSixth.text = ""
    }
    
    @objc override func didMoveToBackground() {
        self.currentBackgroundDate = Date()
        
    }
    
    @objc override func willCometoForeground() {
        showAlerts()
        self.stopTimer()
        let difference = Int(Date().timeIntervalSince(currentBackgroundDate))
        print(difference)
        print(self.secondsRemaining)
        isAuthorizedSuccess = false
        if secondsRemaining  > Int(difference) {
            self.secondsRemaining = secondsRemaining - difference
            print(  secondsRemaining - Int(difference))
            self.timeout.text = "\(Utility.timeString(time: TimeInterval(self.secondsRemaining)))"
            self.sheduletimer()
        }else {
            self.timeout.text = ""
        }
    }
    
    
    func sheduletimer() {
        self.resendHideView.isHidden = true
        self.timeout.isHidden = false
        resendOTP.setTitleColor (Color.resendButtonDisable, for: .normal)
        resendOTP.isUserInteractionEnabled = false
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {  [weak self] (Timer) in
            if self?.secondsRemaining ?? 0 > 0 {
                self?.timeout.text = Utility.timeString(time: TimeInterval(self?.secondsRemaining ?? 0))
                self?.secondsRemaining -= 1
            } else {
                self?.timeout.text = ""
                self?.stopTimer()
            }
        }
    }
    
    func stopTimer () {
        self.timeout.isHidden = true
        self.resendHideView.isHidden = false
        resendOTP.setTitleColor( Color.resendButtonActivation, for: .normal)
        resendOTP.isUserInteractionEnabled = true
        timer?.invalidate()
    }
    override func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func closeKeyboard() {
        self.view.endEditing(true)
    }
    
    @objc override func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            forgotpinBottomConstraint.constant = keyboardSize.height - (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0)
        }
    }
    
    @objc override func keyboardWillHide(notification: NSNotification) {
        forgotpinBottomConstraint.constant = 0
    }
    
    
    
    
    @IBAction func cancelButton(_ sender: Any) {
        clearTextFields()
        stopTimer()
        stopLoading()
        self.timeout.text = "01:00"
        secondsRemaining = passwordResetTimer
        resendHideView.isHidden = true
        timeout.isHidden = false
        
        self.initialmainView.backgroundColor = UIColor.clear
        self.hideForgotView.isHidden = true
    }
    
    @IBAction func resendOTPtapped(_ sender: Any) {
        closeKeyboard()
        //Request SMS
        if !phoneNumber.isEmpty {
            if NetworkReachability.shared.isConnected {
                startLoading(withText: resendOtpTxt)
                clearTextFields()
                textfieldBackgroundcolour()
                otpViewModel.requestOtp(phoneNumber: phoneNumber)  { [weak self] (verificationID, error) in
                    
                    if let error = error {
                        self?.stopLoading()
                        DispatchQueue.main.async {
                            let authError = error as NSError?
                            if (authError?.code == AuthErrorCode.tooManyRequests.rawValue) {
                                AppAlert.shared.showToast(message: ErrorMessage.otpAttempts)
                            }
                        }
                        return
                    }
                    DispatchQueue.main.async { [weak self] in
                        self?.stopTimer()
                        self?.stopLoading()
                        self?.secondsRemaining = passwordResetTimer
                        self?.sheduletimer()
                        AppAlert.shared.showToast(message: SuccessMessage.successOTP)
                        
                    }
                    if let verificationId = verificationID {
                        self?.verificationId = verificationId
                    }
                }
            }else {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
        }
    }
    
    
    @IBAction func verifyOTPtapped(_ sender: Any) {
        closeKeyboard()
        
        if  let txtFirst = txtFirst.text,  let txtSecond = txtSecond.text,  let txtThird = txtThird.text,  let txtForth = txtForth.text,  let txtFifth = txtFifth.text,  let txtSixth = txtSixth.text {
            let verificationCode = txtFirst + txtSecond + txtThird + txtForth + txtFifth + txtSixth
            if verificationCode.count == 6 {
                if NetworkReachability.shared.isConnected {
                    startLoading(withText: pleaseWait)
                    verifyOTPViewModel.verifyOtp(verificationId: verificationId, verificationCode: verificationCode) {[weak self]  (authResult, error) in
                        if let error = error {
                            let authError = error as NSError
                            DispatchQueue.main.async { [weak self] in
                                self?.stopLoading()
                                if authError.code == AuthErrorCode.invalidVerificationCode.rawValue{
                                    AppAlert.shared.showToast(message: ErrorMessage.invalidOtp)
                                }else if authError.code == AuthErrorCode.sessionExpired.rawValue {
                                    AppAlert.shared.showToast(message: ErrorMessage.sessionExpired)
                                }
                                self?.clearTextFields()
                                self?.textfieldBackgroundcolour()
                            }
                            return
                        }
                        self?.stopTimer()
                        DispatchQueue.main.async { [weak self] in
                            self?.stopLoading()
                            self?.clearTextFields()
                            self?.stopTimer()
                            self?.timeout.text = "01:00"
                            self?.secondsRemaining = passwordResetTimer
                            self?.resendHideView.isHidden = true
                            self?.timeout.isHidden = false
                            self?.hideForgotView.isHidden = true
                            self?.initialmainView.backgroundColor = UIColor.clear
                            let vc = AppLockPasswordViewController(nibName: "AppLockPasswordViewController", bundle: nil)
                            vc.isFromPrivateChat = self?.isFromPrivateChat ?? false
                            vc.isFromPrivateRecentChat = self?.isFromPrivateRecentChat ?? false
                            vc.isChangePin = true
                            vc.privateChatDelegate = self
                            self?.navigationController?.pushViewController(vc, animated: true)
                        }
                        
                     
                       
                        
                       
                        
                    }
                }else {
                    AppAlert.shared.showToast(message: ErrorMessage.noInternet)
                }
            }else if verificationCode.count == 0 {
                AppAlert.shared.showToast(message: ErrorMessage.enterOtp)
            }
            else {
                AppAlert.shared.showToast(message: ErrorMessage.otpMismatch)
            }
        }
    }
    
    //PIN VALIDATION
    func validateAppPIN() {
        if pinInput != CommonDefaults.appLockPassword  {
            if CommonDefaults.passwordAuthenticationAttemps > 4 {
                showfailedAttempsActionAlert()
            }
        }
        
        if pinInput == CommonDefaults.appLockPassword  {
            CommonDefaults.appBackgroundTime = Date()
            if isResetByFailedAttempts && !isFromPrivateRecentChat && !isFromPrivateChat && !isFromContactScreen && !isFromForward && !isFromContactInfo && !isFromGroupInfo {
                if CommonDefaults.showAppLock {
                    self.popToRootView()
                } else {
                    self.popToView()
                }
                CommonDefaults.showAppLock = false
                CommonDefaults.faceOrFingerAuthenticationFails = false
            } else if isDisablePin {
                CommonDefaults.appLockenable = false
                CommonDefaults.appFingerprintenable = false
                if CommonDefaults.showAppLock {
                    self.popToRootView()
                } else {
                    self.popToView()
                }
                CommonDefaults.showAppLock = false
                CommonDefaults.faceOrFingerAuthenticationFails = false
            } else {
                if login == true {
                    CommonDefaults.appLockenable = true
                }
                else if logout == true{
                    CommonDefaults.appLockenable = false
                    CommonDefaults.appFingerprintenable = false
                    requestLogout()
                }
                else if CommonDefaults.appLockenable == true {
                    if  disableBothPIN == true {
                        CommonDefaults.appLockenable = false
                        CommonDefaults.appFingerprintenable = false
                    }
                    else if fingerPrintEnable == true{
                        CommonDefaults.appFingerprintenable = true
                        CommonDefaults.appLockenable = true
                    }
                }

                if CommonDefaults.appFingerprintenable == true && CommonDefaults.appLockenable == true {
                    if fingerPrintLogin == true {
                        CommonDefaults.appFingerprintenable = true
                        CommonDefaults.appLockenable = true
                    }
                    else if fingerPrintLogout == true  {
                        CommonDefaults.appFingerprintenable = false
                    }
                }
                if isFromPrivateChat {
                    if let controllers = self.navigationController?.viewControllers {
                        for controller in controllers {
                            if controller.isKind(of: PrivateChatEnableController.self) {
                                self.navigationController?.popToViewController(controller, animated: true)
                                NotificationCenter.default.post(name: Notification.Name("PrivateChatEnable"), object: nil)
                                privateChatDelegate?.onPasswordSet()
                            }
                        }
                    }
                } else if isFromPrivateRecentChat {
                    self.navigationController?.popToRootViewController(animated: true)
                    NotificationCenter.default.post(name: Notification.Name("PrivateRecentChatAuthenticated"), object: nil)
                    privateChatDelegate?.onPrivateChatAuthenticated()
                }
                else if CommonDefaults.privateChatOnChatScreen {
                    if CommonDefaults.appFingerprintenable {
                        if let viewControllers: [UIViewController] = self.navigationController?.viewControllers as? [UIViewController] {
                            self.navigationController?.popToViewController(viewControllers[viewControllers.count - 3], animated: false)
                        }
                    } else {
                        self.navigationController?.popViewController(animated: false)
                    }
                    CommonDefaults.privateChatOnChatScreen = false
                }
                else if isFromNotificationSelect {
                    if isFromPrivateChat {
                        self.navigationController?.popToRootViewController(animated: true)
                    } else {
                        if CommonDefaults.appFingerprintenable {
                            if let viewControllers: [UIViewController] = self.navigationController?.viewControllers as? [UIViewController] {
                                self.navigationController?.popToViewController(viewControllers[viewControllers.count - 3], animated: true)
                            }
                        } else {
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                } else if pushNotificationSelected {
                    if CommonDefaults.appFingerprintenable {
                        if let viewControllers: [UIViewController] = self.navigationController?.viewControllers as? [UIViewController] {
                            self.navigationController?.popToViewController(viewControllers[viewControllers.count - 3], animated: false)
                        }
                    } else {
                        self.navigationController?.popViewController(animated: false)
                    }
                    pushNotificationSelected = false
                } else if CommonDefaults.showPrivateLockRecent {
                    if CommonDefaults.appFingerprintenable {
                        if let viewControllers: [UIViewController] = self.navigationController?.viewControllers as? [UIViewController] {
                            self.navigationController?.popToViewController(viewControllers[viewControllers.count - 3], animated: false)
                        }
                    } else {
                        self.navigationController?.popViewController(animated: false)
                    }
                    CommonDefaults.showPrivateLockRecent = false
                } else if isFromContactScreen || isFromSearchSelect || isFromForward || isFromGroupInfo || isFromContactInfo {
                    if CommonDefaults.appFingerprintenable {
                        if let viewControllers: [UIViewController] = self.navigationController?.viewControllers as? [UIViewController] {
                            self.navigationController?.popToViewController(viewControllers[viewControllers.count - 3], animated: false)
                        }
                    } else {
                        self.navigationController?.popViewController(animated: false)
                    }
                }
                else {
                    if fingerPrintLogin || noFingerprintAdded{
                        if noFingerprintAdded == true{
                            CommonDefaults.appFingerprintenable = false
                        }
                        if CommonDefaults.showAppLock {
                            self.popToRootView()
                        } else {
                            self.popToView()
                        }
                        CommonDefaults.showAppLock = false
                        CommonDefaults.faceOrFingerAuthenticationFails = false
                    } else {
                        
                        if CommonDefaults.showAppLock {
                            self.popToRootView()
                        } else {
                            self.popToView()
                        }
                        CommonDefaults.showAppLock = false
                        CommonDefaults.faceOrFingerAuthenticationFails = false
                    }
                }
            }
        }
        else {
            CommonDefaults.passwordAuthenticationAttemps+=1
            AppAlert.shared.showToast(message: ErrorMessage.validateAppLock)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.pinInput = ""
            self?.pinEnteredcollectionview.reloadData()
        }
    }
    
    func popToRootView() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            CommonDefaults.passwordAuthenticationAttemps = 0
            self?.navigationController?.popToRootViewController(animated: false)
            self?.dismiss(animated: false)
            self?.presentingViewController?.dismiss(animated: false)
        }
    }
    
    func popToView() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            CommonDefaults.passwordAuthenticationAttemps = 0
            self?.navigationController?.popViewController(animated: true)
            self?.dismiss(animated: false)
        }
    }
    
    @IBAction func forgotbutton(_ sender: Any) {
        forgotPassword()
    }

    func forgotPassword() {
        phoneNumber = "+" + ContactManager.getMyProfile().mobileNumber
        if NetworkReachability.shared.isConnected {
            startLoading(withText: pleaseWait)
            //Request SMS
            otpViewModel.requestOtp(phoneNumber: phoneNumber) {
                (verificationID, error) in
                if let error = error {
                    self.stopLoading()
                    DispatchQueue.main.async {
                        let authError = error as NSError?
                        if (authError?.code == AuthErrorCode.tooManyRequests.rawValue) {
                            AppAlert.shared.showToast(message: ErrorMessage.otpAttempts)
                        }else if (authError?.code == AuthErrorCode.invalidPhoneNumber.rawValue) {
                            AppAlert.shared.showToast(message: ErrorMessage.validphoneNumber)
                        }
                    }
                    return
                }
                if let verificationId = verificationID {
                    DispatchQueue.main.async { [weak self] in
                        self?.stopLoading()
                        self?.stopTimer()
                        self?.sheduletimer()
                        AppAlert.shared.showToast(message: SuccessMessage.successOTP)
                        self?.initialmainView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
                        self?.hideForgotView.isHidden = false
                        self?.verificationId = verificationID ?? ""
                        print(verificationID)
                        
                    }
                    
                }
            }
        }
        
    }
}

extension PrivateChatAuthenticationPINViewController: UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionview == collectionView {
            return array.count
        }
        else {
            return 4
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        if collectionview == collectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AuthenticationPINCollectionViewCell", for: indexPath) as! AuthenticationPINCollectionViewCell
            cell.labeloutlet.text = array[indexPath.row]
            if cell.labeloutlet.text == ""{
                cell.labeloutlet.backgroundColor = .clear
            }
            if cell.labeloutlet.text == "CLEAR"{
                cell.labeloutlet.text = ""
                cell.labeloutlet.backgroundColor = .clear
                cell.labeloutlet.setImage(image: UIImage(named: ImageConstant.remove_PIN)!, with: "")
            }
            cell.labeloutlet.layer.cornerRadius = 27
            cell.labeloutlet.clipsToBounds = true
            
            return cell
        }
        else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PINenteredCollectionViewCell", for: indexPath) as! PINenteredCollectionViewCell
            if pinInput.count > indexPath.item  {
                cell.passwordImage.image = UIImage(named: ImageConstant.otppinDatk)
            }
            else {
                cell.passwordImage.image = UIImage(named: ImageConstant.otpPin)
            }
            if (pinInput.count == 4 && indexPath.item == 3){
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    self?.validateAppPIN()
                }
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionview == collectionView {
            return CGSize(width: collectionview.frame.size.width/4, height: collectionview.frame.size.height/5 + 5)
        }
        else{
            return CGSize(width: 30, height: 40)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionview == collectionView {
            print(array[indexPath.row])
            if indexPath.row != 11 && indexPath.row != 9{
                let text = array[indexPath.row]
                if (pinInput.count < 4) {
                    pinInput.append(text)
                }
                print("pinInput",pinInput)
            }
            
            if indexPath.row == 11 {
                pinInput = String(pinInput.dropLast())
                print("Removing PIN",pinInput)
                
            }
            
            self.pinEnteredcollectionview.reloadData()
        }
        
    }
    
}

extension PrivateChatAuthenticationPINViewController:  CustomTextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == txtSixth {
            txtSixth?.becomeFirstResponder()
        }
        if textField == txtFifth {
            txtFifth?.becomeFirstResponder()
        }
        if textField == txtForth {
            txtForth?.becomeFirstResponder()
        }
        if textField == txtThird {
            txtThird?.becomeFirstResponder()
        }
        if textField == txtSecond {
            txtSecond?.becomeFirstResponder()
        }
        if textField == txtFirst {
            txtFirst?.becomeFirstResponder()
        }
    }
    
    func textField(_ textField: UITextField, didDeleteBackwardAnd wasEmpty: Bool) {
        if wasEmpty {
            if textField == txtSixth {
                txtFifth?.becomeFirstResponder()
            }
            if textField == txtFifth {
                txtForth?.becomeFirstResponder()
            }
            if textField == txtForth {
                txtThird?.becomeFirstResponder()
            }
            if textField == txtThird {
                txtSecond?.becomeFirstResponder()
            }
            if textField == txtSecond {
                txtFirst?.becomeFirstResponder()
            }
            if textField == txtFirst {
                txtFirst?.resignFirstResponder()
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string.isEmpty {
            if textField == txtSixth {
                txtFifth?.becomeFirstResponder()
            }
            if textField == txtFifth {
                txtForth?.becomeFirstResponder()
            }
            if textField == txtForth {
                txtThird?.becomeFirstResponder()
            }
            if textField == txtThird {
                txtSecond?.becomeFirstResponder()
            }
            if textField == txtSecond {
                txtFirst?.becomeFirstResponder()
            }
            if textField == txtFirst {
                txtFirst?.resignFirstResponder()
            }
            textField.text? = string
            return false
        }
        if Int(string) == nil {
            return false
        }
        if string.count == 6 {
            let otpCode = string
            txtFirst.text = String(otpCode[otpCode.startIndex])
            txtSecond.text = String(otpCode[otpCode.index(otpCode.startIndex, offsetBy: 1)])
            txtThird.text = String(otpCode[otpCode.index(otpCode.startIndex, offsetBy: 2)])
            txtForth.text = String(otpCode[otpCode.index(otpCode.startIndex, offsetBy: 3)])
            txtFifth.text = String(otpCode[otpCode.index(otpCode.startIndex, offsetBy: 4)])
            txtSixth.text = String(otpCode[otpCode.index(otpCode.startIndex, offsetBy: 5)])
            
            DispatchQueue.main.async { [weak self] in
                self?.dismissKeyboard()
            }
        }
        if string.count == 1 {
            if (textField.text?.count ?? 0) == 1 {
                if (txtFirst.text?.count ?? 0) == 1 {
                    if (txtSecond.text?.count ?? 0) == 1 {
                        if (txtThird.text?.count ?? 0) == 1 {
                            if (txtForth.text?.count ?? 0) == 1 {
                                if (txtFifth.text?.count ?? 0) == 1 {
                                    if (txtSixth.text?.count ?? 0) == 1 {
                                        
                                        print("Textfield full")
                                        
                                        if (txtFirst.text?.count ?? 0) == 1 && textField.tag == 1 {
                                            txtFirst.text = string
                                            return false
                                        }else if (txtSecond.text?.count ?? 0) == 1 && textField.tag == 2 {
                                            txtSecond.text = string
                                            return false
                                        }else if (txtThird.text?.count ?? 0) == 1 && textField.tag == 3 {
                                            txtThird.text = string
                                            return false
                                        }else if (txtForth.text?.count ?? 0) == 1 && textField.tag == 4 {
                                            txtForth.text = string
                                            return false
                                        }else if (txtFifth.text?.count ?? 0) == 1 && textField.tag == 5 {
                                            txtFifth.text = string
                                            return false
                                        }else if (txtSixth.text?.count ?? 0) == 1 && textField.tag == 6 {
                                            txtSixth.text = string
                                            return false
                                        }else {
                                            return false
                                        }
                                        
                                    }else {
                                        txtSixth.text = string
                                        DispatchQueue.main.async { [weak self] in
                                            self?.dismissKeyboard()
                                        }
                                        return false
                                    }
                                }else{
                                    txtFifth.text = string
                                    return false
                                }
                            }else{
                                txtForth.text = string
                                return false
                            }
                        }else{
                            txtThird.text = string
                            return false
                        }
                    }else{
                        txtSecond.text = string
                        return false
                    }
                } else {
                    txtFirst.text = string
                    return false
                }
            }
        }
        guard let textFieldText = textField.text,
              let rangeOfTextToReplace = Range(range, in: textFieldText) else {
            return false
        }
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        
        
        if count == 1{
            if textField == txtFirst{
                DispatchQueue.main.async { [weak self] in
                    self?.txtSecond.becomeFirstResponder()
                }
                
            }else if textField == txtSecond{
                DispatchQueue.main.async { [weak self] in
                    self?.txtThird.becomeFirstResponder()
                }
                
            }else if textField == txtThird{
                DispatchQueue.main.async { [weak self] in
                    self?.txtForth.becomeFirstResponder()
                }
                
            }else if textField == txtForth{
                DispatchQueue.main.async { [weak self] in
                    self?.txtFifth.becomeFirstResponder()
                }
                
            }else if textField == txtFifth {
                DispatchQueue.main.async { [weak self] in
                    self?.txtSixth.becomeFirstResponder()
                }
                
            }else {
                DispatchQueue.main.async { [weak self] in
                    self?.dismissKeyboard()
                }
            }
        }
        
        return count <= 1
    }
    
}

extension PrivateChatAuthenticationPINViewController: CallDismissDelegate {
    func onCallControllerDismissed() {
        showAlerts()
    }
}

extension PrivateChatAuthenticationPINViewController: PrivateChatDelegate {
    func onPasswordSet() {

    }

    func onPrivateChatAlertSelected(option: String) {

    }

    func onPrivateChatAuthenticated() {

    }

    func pinChanged() {
        privateChatDelegate?.pinChanged()
    }

}
