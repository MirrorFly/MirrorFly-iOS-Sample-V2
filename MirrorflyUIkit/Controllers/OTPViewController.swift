//
//  OtpViewController.swift
//  MirrorflyUIkit
//
//  Created by User on 17/08/21.
//

import UIKit
import FirebaseAuth
import MirrorFlySDK
import PhoneNumberKit
import SafariServices

class OTPViewController: UIViewController {
    
    @IBOutlet weak var scroller: UIScrollView!
    @IBOutlet weak var pgHeader: UILabel!
    @IBOutlet weak var pgTxt: UILabel!
    @IBOutlet weak var mobileNumber: UITextField!
    @IBOutlet weak var countryCode: UILabel!
    @IBOutlet weak var getOtpBtn: UIButton!
    public var countryArray = [Country]()
    @IBOutlet weak var termsAndConditionLabel: UILabel!
    @IBOutlet weak var privacyPolicyLabel: UILabel!
    @IBOutlet weak var countryPickerButton: UIButton!
    public  var otpViewModel : OTPViewModel!
    let chatmanager = ChatManager.shared
    var countryRegion = ""
    
    private var verifyOTPViewModel : VerifyOTPViewModel!
    let chatManager = ChatManager.shared
    var isAuthorizedSuccess: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        termsAndConditionLabel.attributedText = NSAttributedString(string: "Terms and Conditions,", attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
        privacyPolicyLabel.attributedText = NSAttributedString(string: "Privacy Policy.", attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
        termsAndConditionLabel.textColor = UIColor(named: "buttonColor")
        privacyPolicyLabel.textColor = UIColor(named: "buttonColor")
        setupUI()
        configureDefaults()
        setupAutomation()
    }
    
    // MARK: Automation Setup
    func setupAutomation() {
        countryPickerButton.setAutomationIdentifier(label: countryPickerString, id: countryPickerBtnAM)
        mobileNumber.setAutomationIdentifier(label: numTextString, id: numTextAM)
        getOtpBtn.setAutomationIdentifier(id: getOtpBtnAM)
    }
    
    // MARK:- Functions
    func setupUI() {
        pgHeader.font = UIFont.font23px_appHeavy()
        pgTxt.font = UIFont.font14px_appLight()
        mobileNumber.font = UIFont.font15px_appMedium()
        countryCode.font = UIFont.font15px_appRegular()
        getOtpBtn.titleLabel?.font = UIFont.font16px_appSemibold()
        
        let tncTap = UITapGestureRecognizer(target: self, action: #selector(goToTermsAndConditionsWebPage))
        termsAndConditionLabel.isUserInteractionEnabled = true
        termsAndConditionLabel.addGestureRecognizer(tncTap)
        
        let privacyTap = UITapGestureRecognizer(target: self, action: #selector(goToPrivacyPolicyWebPage))
        privacyPolicyLabel.isUserInteractionEnabled = true
        privacyPolicyLabel.addGestureRecognizer(privacyTap)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        Utility.saveInPreference(key: "safeAreaHeight", value: "\(view.safeAreaLayoutGuide.layoutFrame.height)")
        Utility.saveInPreference(key: "safeAreaWidth", value: "\(view.safeAreaLayoutGuide.layoutFrame.width)")
    }
    
    func configureDefaults() {
        scroller.delegate = self
        otpViewModel =  OTPViewModel()
        mobileNumber.delegate = self
        otpViewModel.getCountryData(completionHandler: { (countryArray) in
            if let countries = countryArray, countries.count > 0 {
                self.countryArray  = countries
                DispatchQueue.main.async { [weak self] in
                    let countryCode = Locale.current.regionCode
                    if let country = self?.countryArray.first(where: {$0.code == countryCode}) {
                        self?.countryRegion = country.code
                        self?.countryCode.text = country.dial_code
                    } else {
                        self?.countryCode.text = self?.countryArray[0].dial_code
                        self?.countryRegion = self?.countryArray[0].code ?? ""
                    }
                }
            }
        })
        verifyOTPViewModel =  VerifyOTPViewModel()
    }
    
    // MARK:- Button Actions
    
    @IBAction func countryPicker(_ sender: Any) {
        self.closeKeyboard()
        let storyboard : UIStoryboard = UIStoryboard(name: Storyboards.main, bundle: nil)
        let country = storyboard.instantiateViewController(withIdentifier: Identifiers.countryPicker) as! CountryPickerViewController
        country.countryArray = countryArray
        country.delegate = self
        self.navigationController?.pushViewController(country, animated: true)
    }
    
    @IBAction func getOtp(_ sender: Any) {
        
            self.closeKeyboard()
        let phoneNumberKit = PhoneNumberKit()
        guard let mobileNumberText = mobileNumber.text else {
            return
        }
        if !mobileNumberText.isEmpty, let mobileNumber = mobileNumber.text, let countryCode = countryCode.text {
            let phoneNumber = countryCode + mobileNumber
            if mobileNumber.count >= minimumMobileNumber {
                if phoneNumberKit.isValidPhoneNumber(phoneNumber) {
                    if mobileNumber.isValidMobileNumber(mobileNumber: mobileNumber) {
                        if NetworkReachability.shared.isConnected {
                            startLoading(withText: pleaseWait)
                            //Request SMS
                            if SKIP_OTP_VERIFICATION {
                                registration(isForceRegister: true, phoneNumber: phoneNumber)
                            } else {
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
                                            AppAlert.shared.showToast(message: SuccessMessage.successOTP)
                                            let vc = UIStoryboard.init(name: Storyboards.main, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.verifyOTPViewController) as? VerifyOTPViewController
                                            vc?.verificationId = verificationId
                                            vc?.mobileNumber = phoneNumber
                                            vc?.getMobileNumber = countryCode + " " + mobileNumber
                                            self?.navigationController?.pushViewController(vc!, animated: true)
                                            self?.mobileNumber.text = ""
                                        }
                                        
                                    }
                                }
                            }
                        }else {
                        AppAlert.shared.showAlert(view: self, title: warning, message: ErrorMessage.noInternet, buttonTitle: okayButton)
                        }
                    }else {
                    AppAlert.shared.showAlert(view: self, title: warning, message: ErrorMessage.validphoneNumber, buttonTitle: okayButton)
                    }
                }else {
                AppAlert.shared.showAlert(view: self, title: warning, message: ErrorMessage.validphoneNumber, buttonTitle: okayButton)
                }
            } else {
            AppAlert.shared.showAlert(view: self, title: warning, message: ErrorMessage.shortMobileNumber, buttonTitle: okayButton)
            }
        }else {
            if mobileNumberText.isEmpty{
                AppAlert.shared.showAlert(view: self, title: warning, message: ErrorMessage.enterMobileNumber, buttonTitle: okayButton)
            }else{
                AppAlert.shared.showAlert(view: self, title: warning, message: ErrorMessage.validphoneNumber, buttonTitle: okayButton)
            }
        }
    }
    
    func closeKeyboard() {
        self.view.endEditing(true)
    }
    
    @objc func goToTermsAndConditionsWebPage(sender:UITapGestureRecognizer){
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        let url = URL(string: "https://www.mirrorfly.com/terms-and-conditions.php")
        let vc = SFSafariViewController(url: url!, configuration: config)
        present(vc, animated: true)
    }
    
    @objc func goToPrivacyPolicyWebPage(sender:UITapGestureRecognizer){
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        let url = URL(string: "https://www.mirrorfly.com/privacy-policy.php")
        let vc = SFSafariViewController(url: url!, configuration: config)
        present(vc, animated: true)
    }
   
}

extension OTPViewController:  UIScrollViewDelegate {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        closeKeyboard()
    }
}

extension OTPViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var returnValue = true
        guard let text = textField.text else { return true }
        print(text)
        let newLength = text.count + string.count - range.length
                let allowedCharacters = CharacterSet(charactersIn:"0123456789")
                let characterSet = CharacterSet(charactersIn: string)
        let length = newLength <= maximumMobileNumber
        let allowedChar = allowedCharacters.isSuperset(of: characterSet)
        if length, allowedChar{
            returnValue = true
        }else{
            returnValue = false
        }
        return returnValue
    }
}

extension OTPViewController: CountryPickerDelegate {
    func selectedCountry(country: Country) {
        countryCode.text = country.dial_code
    }
}

/**
 To skip otp verification
 */
extension OTPViewController {
    func registration(isForceRegister: Bool, phoneNumber : String) {
        self.startLoading(withText: pleaseWait)
        let mobile = Utility.removeCharFromString(string: phoneNumber, char: "+")
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
                                self?.registration(isForceRegister: true, phoneNumber: phoneNumber)
                            } else if result == 0{
                               // self?.popView()
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
                self?.chatManager.connectionDelegate = self
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
}

extension OTPViewController : ConnectionEventDelegate {
    func onConnected() {
        if isAuthorizedSuccess == true {
            //            self.performSegue(withIdentifier: Identifiers.otpNextToProfile, sender: nil)
            chatManager.connectionDelegate = nil
            if let vc = UIStoryboard.init(name: Storyboards.backupRestore, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.restoreViewController) as? RestoreViewController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func onDisconnected() {
        
    }
    
    func onConnectionFailed(error: FlyError) {
        
    }
    
    func onReconnecting() {
        
    }
    

}

