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
        self.enterNewPassword.isSecureTextEntry = !self.enterNewPassword.isSecureTextEntry
        self.enterNewImageView.image = self.enterNewPassword.isSecureTextEntry ? UIImage(named: ImageConstant.hide_Password) :  UIImage(named: ImageConstant.showeye_password)
    }
    
    @IBAction func viewPasswordConfirm(_ sender: Any) {
        self.confirmNewPassword.isSecureTextEntry = !self.confirmNewPassword.isSecureTextEntry
        self.confirmNewImageView.image = self.confirmNewPassword.isSecureTextEntry ? UIImage(named: ImageConstant.hide_Password) :  UIImage(named: ImageConstant.showeye_password)
    }
    
    
    @IBAction func saveButtonClick(_ sender: Any) {
        if updateNewpassword() == false {
            return
        }
        else if enterNewPassword.text ?? "" == confirmNewPassword.text ?? "" {
            print("saved")
            if fingerPINisOn == true{
                FlyDefaults.appFingerprintenable = true
            }
            FlyDefaults.appLockenable = true
            FlyDefaults.appLockPassword = confirmNewPassword.text ?? ""
            FlyDefaults.appLockPasswordDate = Date()
            FlyDefaults.passwordAuthenticationAttemps = 0
            ShareKitAlert.shared.showToast(controller: self, message: SuccessMessage.PINsetsuccessfully)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func updateNewpassword() -> Bool {
        if enterNewPassword.text == "" || confirmNewPassword.text == "" {
            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.enterthePIN)
            return  false
        }
        if (enterNewPassword.text?.count ?? 0) < 4 {
            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.enterValidPIN)
            return false
        } else if (confirmNewPassword.text?.count ?? 0) < 4 {
            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.enterValidPIN)
            return false
        }
        else if enterNewPassword.text != confirmNewPassword.text{
            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.passwordShouldbeSame)
            return false
        }
        else if enterNewPassword.text == FlyDefaults.appLockPassword {
            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.oldPINnewPINsholdnotSame)
            return false
        }
        return true
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
        
        return newString.count <= maxLength
    }
    
    
}
