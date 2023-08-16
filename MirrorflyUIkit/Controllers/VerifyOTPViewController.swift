//  VerifyOTPViewController.swift
//  MirrorFly
//  Created by User on 18/05/21.
import Foundation
import UIKit
import FirebaseAuth
import MirrorFlySDK
import IQKeyboardManagerSwift


class VerifyOTPViewController: UIViewController
{
    //Outlets
    @IBOutlet weak var txtFirst: UITextField!
    @IBOutlet weak var txtSecond: UITextField!
    @IBOutlet weak var txtThird: UITextField!
    @IBOutlet weak var txtForth: UITextField!
    @IBOutlet weak var txtFifth: UITextField!
    @IBOutlet weak var txtSixth: UITextField!
    @IBOutlet weak var verifyOtp: UILabel!
    @IBOutlet weak var verifyTxt: UILabel!
    @IBOutlet weak var otpTimerLbl: UILabel!
    @IBOutlet weak var changeNumber: UIButton!
    @IBOutlet weak var verifyotp: UIButton!
    @IBOutlet weak var resendOtp: UIButton!
    
    public var verificationId = ""
    var secondsRemaining = otpTimer
    var timer: Timer?
    public var mobileNumber = ""
    var getMobileNumber: String = ""
    var isAuthorizedSuccess: Bool = false
    let chatManager = ChatManager.shared
    private var verifyOTPViewModel : VerifyOTPViewModel!
    private var otpViewModel : OTPViewModel!
    var currentBackgroundDate = Date()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setUpStatusBar()
        configureDefaults()
        handleBackgroundAndForground()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        chatManager.connectionDelegate = nil
        NotificationCenter.default.removeObserver(self)
        IQKeyboardManager.shared.enable = true
    }
    
    // MARK:- Functions
    func setupUI() {
        // Initial View setup
        verifyOtp.font = UIFont.font20px_appBold()
        verifyTxt.font = UIFont.font14px_appLight()
        txtFirst.font = UIFont.font16px_appSemibold()
        txtSecond.font = UIFont.font16px_appSemibold()
        txtThird.font = UIFont.font16px_appSemibold()
        txtForth.font = UIFont.font16px_appSemibold()
        txtFifth.font = UIFont.font16px_appSemibold()
        txtSixth.font = UIFont.font16px_appSemibold()
        otpTimerLbl.font = UIFont.font12px_appRegular()
        changeNumber.titleLabel?.font = UIFont.font14px_appRegular()
        resendOtp.titleLabel?.font = UIFont.font14px_appRegular()
        verifyotp.titleLabel?.font = UIFont.font16px_appSemibold()
        IQKeyboardManager.shared.enable = false
    }
    func configureDefaults() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appCameToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        self.otpTimerLbl.text = "01:30"
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
        chatManager.connectionDelegate = self
        verifyOTPViewModel =  VerifyOTPViewModel()
        otpViewModel = OTPViewModel()
    }
    
    @objc func appMovedToBackground() {
        self.currentBackgroundDate = Date()
    }
    
    @objc func appCameToForeground() {
        self.stopTimer()
        let difference = Int(Date().timeIntervalSince(currentBackgroundDate)) //self.currentBackgroundDate.timeIntervalSince(NSDate() as Date)
        print(difference)
        print(self.secondsRemaining)
        isAuthorizedSuccess = false
        if secondsRemaining  > Int(difference) {
            self.secondsRemaining = secondsRemaining - difference
            print(  secondsRemaining - Int(difference))
            self.otpTimerLbl.text = "\(Utility.timeString(time: TimeInterval(self.secondsRemaining)))"
            self.sheduletimer()
        }else {
            self.otpTimerLbl.text = "00:00"
        }
    }
    func sheduletimer() {
        resendOtp.setTitleColor( .lightGray, for: .normal)
        resendOtp.isUserInteractionEnabled = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {  [weak self] (Timer) in
            if self?.secondsRemaining ?? 0 > 0 {
                self?.otpTimerLbl.text = Utility.timeString(time: TimeInterval(self?.secondsRemaining ?? 0))
                self?.secondsRemaining -= 1
            } else {
                self?.otpTimerLbl.text = "00:00"
                self?.stopTimer()
            }
        }
    }
     func stopTimer () {
        resendOtp.setTitleColor( .black, for: .normal)
        resendOtp.isUserInteractionEnabled = true
        //self.otpTimerLbl.text = "00:00"
        timer?.invalidate()
    }
    
    func clearTextFields() {
        txtFirst.text = ""
        txtSecond.text = ""
        txtThird.text = ""
        txtForth.text = ""
        txtFifth.text = ""
        txtSixth.text = ""
    }
    
    func closeKeyboard() {
        self.view.endEditing(true)
    }
    
    func verifyUser(userData: VerifyUserModel) {
        self.stopLoading()
        let localGoogleToken = Utility.getStringFromPreference(key: googleToken)
        if userData.verifyUserData?.deviceToken == nil {
            registration(isForceRegister: false)
        }else if localGoogleToken != userData.verifyUserData?.deviceToken
        {
            let localGoogleToken = Utility.getStringFromPreference(key: googleToken)
            if userData.verifyUserData?.deviceToken != localGoogleToken {
                AppAlert.shared.showAlert(view: self, title: alert, message: loginAlert, buttonOneTitle: noButton, buttonTwoTitle: yesButton)
                AppAlert.shared.onAlertAction = { (result) ->
                    Void in
                    if result == 1 {
                        self.registration(isForceRegister: false)
                    }else {
                        self.popView()
                    }
                }
            }
        }else {
            self.registration(isForceRegister: false)
        }
    }
    
    
    func showAlreadyLoggedIn() {
        AppAlert.shared.showAlert(view: self, title: nil, message: youWantToLogout, buttonOneTitle: noButton, buttonTwoTitle: yesButton)
        AppAlert.shared.onAlertAction = { [weak self] (result)  ->
            Void in
            if result == 1 {
                self?.requestLogout()
            }else {
                
            }
        }
    }
    
    func requestLogout() {
        startLoading(withText: pleaseWait)
         ChatManager.logoutApi { [weak self] isSuccess, flyError, flyData in
            if isSuccess {
                print("requestLogout Logout api isSuccess")
                self?.registration(isForceRegister: false)
            }else{
                print("Logout api error : \(String(describing: flyError))")
                self?.stopLoading()
            }
        }
    }
    
    func registration(isForceRegister: Bool) {
        self.startLoading(withText: pleaseWait)
        let mobile = Utility.removeCharFromString(string: self.mobileNumber, char: "+")
        verifyOTPViewModel.registration(uniqueIdentifier: mobile, isForceRegister: isForceRegister) { [weak self] (result, error) in
            
            if error != nil {
                self?.stopLoading()
                if let errorMsg  = error {
                    if errorMsg == userBlocked {
                        self?.navigateToBlockedScreen()
                    }
                    else if errorMsg.contains("405") {
                        
                        let message = AppUtils.shared.getErrorMessage(description: errorMsg)
                        
                        AppAlert.shared.showAlert(view: self!, title: alert, message: message, buttonOneTitle: cancel, buttonTwoTitle: continueButton)
                        
                        AppAlert.shared.onAlertAction = { [weak self] (result) ->
                            Void in
                            if result == 1 {
                                self?.registration(isForceRegister: true)
                            } else if result == 0{
                                self?.popView()
                            }
                        }
                    }
                    else {
                         AppAlert.shared.showToast(message: errorMsg)
                    }
                    
                }
            } else {
                self?.stopLoading()
                guard let userPassword = result?["password"] as? String else{
                    return
                }
                guard let userName = result?["username"] as? String else{
                    return
                }
                guard let profileUpdateStatus = result?["isProfileUpdated"] as? Int else{
                    return
                }
                ChatManager.updateAppLoggedIn(isLoggedin: true)
                Utility.saveInPreference(key: isLoggedIn, value: true)
                Utility.saveInPreference(key: username, value: userName)
                Utility.saveInPreference(key: password, value: userPassword)
//                FlyDefaults.myXmppPassword = userPassword
//                FlyDefaults.myXmppUsername = userName
//                FlyDefaults.myMobileNumber = self?.getMobileNumber ?? ""
                CommonDefaults.isProfileUpdated = profileUpdateStatus == 1
                AppAlert.shared.showToast(message: SuccessMessage.successAuth)
                self?.isAuthorizedSuccess = true
                self?.verifyOTPViewModel.initializeChatCredentials()
                self?.startLoading(withText: pleaseWait)
            }
        }
    }
    
    func navigateToBlockedScreen() {
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "BlockedByAdminViewController") as! BlockedByAdminViewController
        UIApplication.shared.keyWindow?.rootViewController =  UINavigationController(rootViewController: initialViewController)
        UIApplication.shared.keyWindow?.makeKeyAndVisible()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Identifiers.otpNextToProfile {
            let profileView = segue.destination as! ProfileViewController
            profileView.getMobileNumber = getMobileNumber
        }
    }
    // MARK:- Button Actions
    
    @IBAction func changeNumber(_ sender: Any) {
        closeKeyboard()
        popView()
    }
    
    @IBAction func resendOtp(_ sender: Any) {
        closeKeyboard()
        //Request SMS
        if !mobileNumber.isEmpty {
            if NetworkReachability.shared.isConnected {
                startLoading(withText: resendOtpTxt)
                clearTextFields()
                otpViewModel.requestOtp(phoneNumber: mobileNumber)  { [weak self] (verificationID, error) in
                    
                    if let error = error {
                        self?.stopLoading()
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
                    DispatchQueue.main.async { [weak self] in
                        self?.stopTimer()
                        self?.stopLoading()
                        self?.secondsRemaining = otpTimer
                        self?.sheduletimer()
                        AppAlert.shared.showToast(message: SuccessMessage.successOTP)
                    }
                    if let verificationId = verificationID {
                        self?.verificationId = verificationId
                    }
                }
            }else {
                AppAlert.shared.showAlert(view: self, title: warning, message: ErrorMessage.noInternet, buttonTitle: okayButton)
            }
        }
    }
    
    @IBAction func verifyOtp(_ sender: Any) {
        
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
                            }
                            return
                        }
                        self?.stopTimer()
                        DispatchQueue.main.async { [weak self] in
                            self?.registration(isForceRegister: true)
                        }
                        
                    }
                }else {
                    AppAlert.shared.showAlert(view: self, title: warning, message: ErrorMessage.noInternet, buttonTitle: okayButton)
                }
            }else if verificationCode.count == 0 {
                AppAlert.shared.showAlert(view: self, title: warning, message: ErrorMessage.enterOtp, buttonTitle: okayButton)
            }
            else {
                AppAlert.shared.showAlert(view: self, title: warning, message: ErrorMessage.otpMismatch, buttonTitle: okayButton)
            }
        }
    }
    
    
}

extension VerifyOTPViewController: UITextFieldDelegate, CustomTextFieldDelegate {
    
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
        if string.count == 6 {
            let otpCode = string
            txtFirst.text = String(otpCode[otpCode.startIndex])
            txtSecond.text = String(otpCode[otpCode.index(otpCode.startIndex, offsetBy: 1)])
            txtThird.text = String(otpCode[otpCode.index(otpCode.startIndex, offsetBy: 2)])
            txtForth.text = String(otpCode[otpCode.index(otpCode.startIndex, offsetBy: 3)])
            txtFifth.text = String(otpCode[otpCode.index(otpCode.startIndex, offsetBy: 4)])
            txtSixth.text = String(otpCode[otpCode.index(otpCode.startIndex, offsetBy: 6)])
            
            DispatchQueue.main.async { [weak self] in
                self?.dismissKeyboard()
            }
        }
        if string.count == 1 {
            if (textField.text?.count ?? 0) == 1 && textField.tag == 0 {
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
    
    override func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func popView() {
        self.navigationController?.popViewController(animated: true)
    }
}

extension VerifyOTPViewController : ConnectionEventDelegate {
    
    func onConnectionFailed(error: FlyError) {
        stopLoading()
    }
    
    func onReconnecting() {
        
    }
    
    func onConnected() {
        if isAuthorizedSuccess == true {
//            self.performSegue(withIdentifier: Identifiers.otpNextToProfile, sender: nil)
            if let vc = UIStoryboard.init(name: Storyboards.backupRestore, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.restoreViewController) as? RestoreViewController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
//            guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: FlyConstants.iCloudContainerId) else {
//                self.performSegue(withIdentifier: Identifiers.otpNextToProfile, sender: nil)
//                return
//            }
//            var backupCloudFileURL = containerURL.appendingPathComponent("Documents")
//            backupCloudFileURL = backupCloudFileURL.appendingPathComponent("Mirrorfly-\(FlyDefaults.myXmppUsername).txt")
//            if FileManager.default.fileExists(atPath: containerURL.path) {
//
//            }
        }
    }
    func onDisconnected() {
        print("Xmmpp DisConnected")
    }
    
}
