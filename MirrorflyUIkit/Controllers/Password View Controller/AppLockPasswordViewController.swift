//
//  AppLockPasswordViewController.swift
//  UiKitQa
//
//  Created by Ramakrishnan on 08/11/22.
//

import UIKit
import MirrorFlySDK

class AppLockPasswordViewController: UIViewController, UITextFieldDelegate {
    
    var appLockPassword : String?
    
    var fingerPINisOn : Bool = false

    var isFromPrivateChat: Bool = false
    var isChangePin: Bool = false
    var isFromPrivateRecentChat: Bool = false

    var privateChatDelegate: PrivateChatDelegate?
    
    @IBOutlet weak var scrollview: UIScrollView!
    
    @IBOutlet weak var enterNewPassword: UITextField!
    
    @IBOutlet weak var confirmNewPassword: UITextField!
    
    @IBOutlet weak var newPasswordShown: UIButton!
    
    @IBOutlet weak var confirmPasswordShown: UIButton!
    
    @IBOutlet weak var enterNewImageView: UIImageView!
    
    @IBOutlet weak var confirmNewImageView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyUIchanges()
    }
    
    func applyUIchanges(){
        self.enterNewPassword.delegate = self
        self.confirmNewPassword.delegate = self
        self.enterNewPassword.isSecureTextEntry = true
        self.confirmNewPassword.isSecureTextEntry = true
        enterNewPassword.defaultTextAttributes.updateValue(10,forKey: NSAttributedString.Key.kern)
        confirmNewPassword.defaultTextAttributes.updateValue(10,forKey: NSAttributedString.Key.kern)
    }
    
    @IBAction func BackButttonClick(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func viewPassword(_ sender: Any) {
        if let button = sender as? UIButton {
            addButtonRipple(button: button)
        }
        self.enterNewPassword.isSecureTextEntry = !self.enterNewPassword.isSecureTextEntry
        self.enterNewImageView.image = self.enterNewPassword.isSecureTextEntry ? UIImage(named: ImageConstant.hide_Password) :  UIImage(named: ImageConstant.showeye_password)
    }
    
    @IBAction func viewPasswordConfirm(_ sender: Any) {
        if let button = sender as? UIButton {
            addButtonRipple(button: button)
        }
        self.confirmNewPassword.isSecureTextEntry = !self.confirmNewPassword.isSecureTextEntry
        self.confirmNewImageView.image = self.confirmNewPassword.isSecureTextEntry ? UIImage(named: ImageConstant.hide_Password) :  UIImage(named: ImageConstant.showeye_password)
    }
    
    
    
    @IBAction func saveButtonClick(_ sender: Any) {
        view.endEditing(true)
        if updateNewpassword() == false {
            return
        }
        else if enterNewPassword.text ?? "" == confirmNewPassword.text ?? "" {
            print("saved")
            if isFromPrivateChat {
                CommonDefaults.appLockPassword = confirmNewPassword.text ?? ""
                CommonDefaults.passwordAuthenticationAttemps = 0
            } else {
                if fingerPINisOn == true{
                    CommonDefaults.appFingerprintenable = true
                }
                CommonDefaults.appLockPassword = confirmNewPassword.text ?? ""
                CommonDefaults.passwordAuthenticationAttemps = 0
                if !isChangePin {
                    CommonDefaults.appLockenable = true
                    CommonDefaults.appLockPasswordDate = Date()
                }
            }
            self.showToastWithMessage(message: SuccessMessage.PINsetsuccessfully)
            self.navigationController?.popViewController(animated: true)
            if !isChangePin {
                self.privateChatDelegate?.onPasswordSet()
            } else {
                self.privateChatDelegate?.pinChanged()
            }
        }
    }
    
    func updateNewpassword() -> Bool {
        if enterNewPassword.text == "" {
            self.showToastWithMessage(message: ErrorMessage.enterthePIN)
            return  false
        }
        if confirmNewPassword.text == "" {
            self.showToastWithMessage(message: ErrorMessage.enterconfirmPIN)
            return false
        }
        if (enterNewPassword.text?.count ?? 0) < 4 {
            self.showToastWithMessage(message: ErrorMessage.enterValidPIN)
            return false
        } else if (confirmNewPassword.text?.count ?? 0) < 4 {
            self.showToastWithMessage(message: ErrorMessage.enterValidPIN)
            return false
        }
        else if enterNewPassword.text != confirmNewPassword.text{
            self.showToastWithMessage(message: ErrorMessage.passwordShouldbeSame)
            return false
        }
        else if enterNewPassword.text == CommonDefaults.appLockPassword {
            self.showToastWithMessage(message: ErrorMessage.oldPINnewPINsholdnotSame)
            return false
        }
        return true
    }
    
    func showToastWithMessage(message: String) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AppAlert.shared.showToast(message: message)
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = 4
        if textField.text == enterNewPassword.text{
            print("enterNewPassword.text")
        }
        else if textField.text == confirmNewPassword.text{
            print("confirmNewPassword.text")
        }
        let currentString =  (textField.text ?? "") as NSString
        let newString = currentString.replacingCharacters(in: range, with: string)
        
        if range.length == 1 && textField.isSecureTextEntry && newString.count > 0 {
            textField.text = newString.substring(to: newString.count)
            return false
        }
        
        return newString.count <= maxLength
    }
    
    
}
