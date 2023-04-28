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

class AuthenticationPINViewController: ShareKitBaseViewController, UITextFieldDelegate {
    
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
    
    public var verifyOTPViewModel : ShareVerifyOTPViewModel!
    public var otpViewModel : ShareOTPViewModel!
    
    var array = ["1","2","3","4","5","6","7","8","9","","0", "CLEAR"]
    
    @IBOutlet weak var resendHideView: UIView!
    
    @IBOutlet weak var resendOTP: UIButton!
    
    @IBOutlet weak var initialmainView: UIView!
    
    @IBOutlet weak var forgotpinBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var hideForgotView: UIView!
    
    @IBOutlet weak var forgotButtonoutlet: UIButton! {
        didSet {
            forgotButtonoutlet.isHidden = true
        }
    }
    
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

//        if FlyDefaults.showAppLock {
//            if FlyDefaults.passwordAuthenticationAttemps > 5 {
//                showfailedAttempsActionAlert()
//            } else if daysBetween(start: FlyDefaults.appLockPasswordDate, end: Date()) > 31-5 {
//                if FlyDefaults.pinChangeAlertShownDate != Date().xmppDateString {
//                    showChangePinAlert()
//                }
//            } else if daysBetween(start: FlyDefaults.appLockPasswordDate, end: Date()) > 31 {
//                showPinActionAlert()
//            }
//        }

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
        ShareKitActionSheet.shared.showActionSeet(view: self, title : "", message: "Your current PIN has been expired. Please set a new PIN to continue further", showCancel: false, actions: actions, style: .alert, sheetCallBack: { [weak self] didCancelTap, tappedTitle in
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
                    ShareKitAlert.shared.showToast(controller: self ?? UIViewController(), message: "Enter current pin to disable pin and fingerprint")
                default:
                    print(" \(tappedTitle)")
                }
            } else {
                print("createGroup Cancel")
            }
        })

    }

    func showfailedAttempsActionAlert() {
        let values : [String] = ["Cancel", "Generate OTP"]
        var actions = [(String, UIAlertAction.Style)]()
        values.forEach { title in
            actions.append((title, UIAlertAction.Style.default))
        }

        ShareKitActionSheet.shared.showActionSeet(view: self, title : "", message: "Invalid PIN, Generate OTP to your registered mobile number", showCancel: false, actions: actions, style: .alert, sheetCallBack: { [weak self] didCancelTap, tappedTitle in
            if !didCancelTap {
                switch tappedTitle {
                case "Generate OTP":
                    self?.clearTextFields()
                    self?.timeout.text = "01:00"
                    self?.secondsRemaining = passwordResetTimer
                    self?.resendHideView.isHidden = true
                    self?.timeout.isHidden = false
                    self?.forgotPassword()
                    self?.isResetByFailedAttempts = true
                default:
                    print(" \(tappedTitle)")
                }
            } else {
                print("createGroup Cancel")
            }
        })
    }

    func showChangePinAlert() {
        FlyDefaults.pinChangeAlertShownDate = Date().xmppDateString

        let values : [String] = ["Change PIN", "OK"]
        var actions = [(String, UIAlertAction.Style)]()
        values.forEach { title in
            actions.append((title, UIAlertAction.Style.default))
        }

        ShareKitActionSheet.shared.showActionSeet(view: self, title : "", message: "Your PIN will be expired in \(31 - daysBetween(start: FlyDefaults.appLockPasswordDate, end: Date())) day(s)", showCancel: false, actions: actions, style: .alert, sheetCallBack: { [weak self] didCancelTap, tappedTitle in
            if !didCancelTap {
                switch tappedTitle {
                case "Change PIN":
                    let vc = ChangeAppLockViewController(nibName: Identifiers.changeAppLockViewController, bundle: nil)
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
    }
    
    func setupUI() {
        resendOTP.titleLabel?.font = UIFont.font14px_appRegular()
        txtFirst.font = UIFont.font16px_appSemibold()
        txtSecond.font = UIFont.font16px_appSemibold()
        txtThird.font = UIFont.font16px_appSemibold()
        txtForth.font = UIFont.font16px_appSemibold()
        txtFifth.font = UIFont.font16px_appSemibold()
        txtSixth.font = UIFont.font16px_appSemibold()
        hideForgotView.clipsToBounds = true
        hideForgotView.layer.cornerRadius = 15
        hideForgotView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        self.initialmainView.backgroundColor = UIColor.clear
        if fingerPrintLogin == true || login == true{
            //self.forgotButtonoutlet.isHidden = false
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
        verifyOTPViewModel =  ShareVerifyOTPViewModel()
        otpViewModel = ShareOTPViewModel()
        phoneNumber = FlyDefaults.myMobileNumber
        
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
        self.stopTimer()
        let difference = Int(Date().timeIntervalSince(currentBackgroundDate))
        print(difference)
        print(self.secondsRemaining)
        isAuthorizedSuccess = false
        if secondsRemaining  > Int(difference) {
            self.secondsRemaining = secondsRemaining - difference
            print(  secondsRemaining - Int(difference))
            self.timeout.text = "\(ShareKitUtility.timeString(time: TimeInterval(self.secondsRemaining)))"
            self.sheduletimer()
        }else {
            self.timeout.text = ""
        }
    }
    
    
    func sheduletimer() {
        self.resendHideView.isHidden = true
        self.timeout.isHidden = false
        resendOTP.setTitleColor (ShareKitColor.resendButtonDisable, for: .normal)
        resendOTP.isUserInteractionEnabled = false
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {  [weak self] (Timer) in
            if self?.secondsRemaining ?? 0 > 0 {
                self?.timeout.text = ShareKitUtility.timeString(time: TimeInterval(self?.secondsRemaining ?? 0))
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
        resendOTP.setTitleColor( ShareKitColor.resendButtonActivation, for: .normal)
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
            forgotpinBottomConstraint.constant = keyboardSize.height - self.view.safeAreaInsets.bottom
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
                startLoading(view: self, withText: resendOtpTxt)
                clearTextFields()
                textfieldBackgroundcolour()
                otpViewModel.requestOtp(phoneNumber: phoneNumber)  { [weak self] (verificationID, error) in
                    
                    if let error = error {
                        self?.stopLoading()
                        DispatchQueue.main.async {
                            let authError = error as NSError?
                            if (authError?.code == AuthErrorCode.tooManyRequests.rawValue) {
                                ShareKitAlert.shared.showToast(controller: self ?? UIViewController(), message: ErrorMessage.otpAttempts)
                            }
                        }
                        return
                    }
                    DispatchQueue.main.async { [weak self] in
                        self?.stopTimer()
                        self?.stopLoading()
                        self?.secondsRemaining = passwordResetTimer
                        self?.sheduletimer()
                        ShareKitAlert.shared.showToast(controller: self ?? UIViewController(), message: SuccessMessage.successOTP)
                        
                    }
                    if let verificationId = verificationID {
                        self?.verificationId = verificationId
                    }
                }
            }else {
                ShareKitAlert.shared.showAlert(view: self, title: warning, message: ErrorMessage.noInternet, buttonTitle: okayButton, completionHandler: { _ in
                })
            }
        }
    }
    
    
    @IBAction func verifyOTPtapped(_ sender: Any) {
        closeKeyboard()
        
        if  let txtFirst = txtFirst.text,  let txtSecond = txtSecond.text,  let txtThird = txtThird.text,  let txtForth = txtForth.text,  let txtFifth = txtFifth.text,  let txtSixth = txtSixth.text {
            let verificationCode = txtFirst + txtSecond + txtThird + txtForth + txtFifth + txtSixth
            if verificationCode.count == 6 {
                if NetworkReachability.shared.isConnected {
                    startLoading(view: self, withText: pleaseWait)
                    verifyOTPViewModel.verifyOtp(verificationId: verificationId, verificationCode: verificationCode) {[weak self]  (authResult, error) in
                        if let error = error {
                            let authError = error as NSError
                            DispatchQueue.main.async { [weak self] in
                                self?.stopLoading()
                                if authError.code == AuthErrorCode.invalidVerificationCode.rawValue{
                                    ShareKitAlert.shared.showToast(controller: self ?? UIViewController(), message: ErrorMessage.invalidOtp)
                                }else if authError.code == AuthErrorCode.sessionExpired.rawValue {
                                    ShareKitAlert.shared.showToast(controller: self ?? UIViewController(), message: ErrorMessage.sessionExpired)
                                }
                                self?.clearTextFields()
                                self?.textfieldBackgroundcolour()
                            }
                            return
                        }
                        self?.stopTimer()
                        DispatchQueue.main.async { [weak self] in
                            self?.stopLoading()
                            self?.hideForgotView.isHidden = true
                            self?.initialmainView.backgroundColor = UIColor.clear
                            let vc = AppLockPasswordViewController(nibName: "AppLockPasswordViewController", bundle: nil)
                            self?.navigationController?.pushViewController(vc, animated: true)
                        }
                        
                    }
                }else {
                    ShareKitAlert.shared.showAlert(view: self, title: warning, message: ErrorMessage.noInternet, buttonTitle: okayButton, completionHandler: {_ in
                                    
                    })
                }
            }else if verificationCode.count == 0 {
                ShareKitAlert.shared.showAlert(view: self, title: warning, message: ErrorMessage.enterOtp, buttonTitle: okayButton, completionHandler: {_ in
                    
                })
            }
            else {
                ShareKitAlert.shared.showAlert(view: self, title: warning, message: ErrorMessage.otpMismatch, buttonTitle: okayButton, completionHandler: {_ in
                    
                })
            }
        }
    }
    
    //PIN VALIDATION
    func validateAppPIN() {
        if FlyDefaults.passwordAuthenticationAttemps > 4 {
            showfailedAttempsActionAlert()
        }

        if pinInput == FlyDefaults.appLockPassword  {
            if isResetByFailedAttempts {
//                if FlyDefaults.showAppLock {
//                    self.navigationController?.popToRootViewController(animated: false)
//                } else {
//                    self.navigationController?.popViewController(animated: true)
//                }
                FlyDefaults.showAppLock = false
                FlyDefaults.faceOrFingerAuthenticationFails = false
            } else if isDisablePin {
                FlyDefaults.appLockenable = false
                FlyDefaults.appFingerprintenable = false
                if FlyDefaults.showAppLock {
                    self.navigationController?.popToRootViewController(animated: false)
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
                FlyDefaults.showAppLock = false
                FlyDefaults.faceOrFingerAuthenticationFails = false
            } else {
                if login == true {
                    FlyDefaults.appLockenable = true
                }
                else if logout == true{
                    FlyDefaults.appLockenable = false
                    requestLogout()
                }
                else if FlyDefaults.appLockenable == true {
                    if  disableBothPIN == true {
                        FlyDefaults.appLockenable = false
                        FlyDefaults.appFingerprintenable = false
                    }
                    else if fingerPrintEnable == true{
                        FlyDefaults.appFingerprintenable = true
                        FlyDefaults.appLockenable = true
                    }
                }

                if FlyDefaults.appFingerprintenable == true && FlyDefaults.appLockenable == true {
                    if fingerPrintLogin == true {
                        FlyDefaults.appFingerprintenable = true
                        FlyDefaults.appLockenable = true
                    }
                    else if fingerPrintLogout == true  {
                        FlyDefaults.appFingerprintenable = false
                    }
                }
                if fingerPrintLogin || noFingerprintAdded{
                    if noFingerprintAdded == true{
                        FlyDefaults.appFingerprintenable = false
                    }
                    FlyDefaults.showAppLock = false
                    FlyDefaults.faceOrFingerAuthenticationFails = false
                    let initialViewController = SharekitShareToViewController(nibName: "SharekitShareToViewController", bundle: nil)
                    self.navigationController?.setNavigationBarHidden(true, animated: true)
                    self.navigationController?.pushViewController(initialViewController, animated: false)
                } else {
                    FlyDefaults.showAppLock = false
                    FlyDefaults.faceOrFingerAuthenticationFails = false
                    let initialViewController = SharekitShareToViewController(nibName: "SharekitShareToViewController", bundle: nil)
                    self.navigationController?.setNavigationBarHidden(true, animated: true)
                    self.navigationController?.pushViewController(initialViewController, animated: false)
                }
            }
        }
        else {
            //FlyDefaults.passwordAuthenticationAttemps+=1
            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.validateAppLock)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.pinInput = ""
            self?.pinEnteredcollectionview.reloadData()
        }
    }
    
    @IBAction func forgotbutton(_ sender: Any) {
        forgotPassword()
    }

    func forgotPassword() {
        phoneNumber = "+"+FlyDefaults.myMobileNumber
        if NetworkReachability.shared.isConnected {
            startLoading(view: self, withText: pleaseWait)
            //Request SMS
            otpViewModel.requestOtp(phoneNumber: phoneNumber) {
                (verificationID, error) in
                if let error = error {
                    self.stopLoading()
                    DispatchQueue.main.async {
                        let authError = error as NSError?
                        if (authError?.code == AuthErrorCode.tooManyRequests.rawValue) {
                            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.otpAttempts)
                        }else if (authError?.code == AuthErrorCode.invalidPhoneNumber.rawValue) {
                            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.validphoneNumber)
                        }
                    }
                    return
                }
                if let verificationId = verificationID {
                    DispatchQueue.main.async { [weak self] in
                        self?.stopLoading()
                        self?.stopTimer()
                        self?.sheduletimer()
                        ShareKitAlert.shared.showToast(controller: self ?? UIViewController(), message: SuccessMessage.successOTP)
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

extension AuthenticationPINViewController: UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
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
                validateAppPIN()
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
                if (pinInput.count <= 4) {
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

extension AuthenticationPINViewController:  CustomTextFieldDelegate {
    
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
            if (textField.text?.count ?? 0) == 1 && textField.tag == 0 {
                if (txtFirst.text?.count ?? 0) == 1 {
                    if (txtSecond.text?.count ?? 0) == 1 {
                        if (txtThird.text?.count ?? 0) == 1 {
                            if (txtForth.text?.count ?? 0) == 1 {
                                if (txtFifth.text?.count ?? 0) == 1 {
                                    txtSixth.text = string
                                    DispatchQueue.main.async { [weak self] in
                                        self?.dismissKeyboard()
                                    }
                                    return false
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

