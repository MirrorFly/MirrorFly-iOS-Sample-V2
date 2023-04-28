//
//  ChangeAppLockViewController.swift
//  UiKitQa
//
//  Created by Ramakrishnan on 08/11/22.
//

import UIKit
import MirrorFlySDK

class ChangeAppLockViewController: UIViewController, UITextFieldDelegate {
    
        
    @IBOutlet weak var scrollview: UIScrollView!
    
    @IBOutlet weak var enterOldPassword: UITextField!
    
    @IBOutlet weak var enterNewPassword: UITextField!
    
    @IBOutlet weak var confirmNewPassword: UITextField!
    
    @IBOutlet weak var oldPasswordShown: UIButton!
    
    @IBOutlet weak var newPasswordShown: UIButton!
    
    @IBOutlet weak var confirmPasswordShown: UIButton!
    
    @IBOutlet weak var oldImageView: UIImageView!
    
    @IBOutlet weak var ennterNewImage: UIImageView!
    
    @IBOutlet weak var enterConfirmImage: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyUIchanges()
    }
    
    func applyUIchanges(){
        self.enterOldPassword.delegate = self
        self.enterNewPassword.delegate = self
        self.confirmNewPassword.delegate = self
        self.enterNewPassword.isSecureTextEntry = true
        self.confirmNewPassword.isSecureTextEntry = true
        self.enterOldPassword.isSecureTextEntry = true
        enterNewPassword.defaultTextAttributes.updateValue(10,forKey: NSAttributedString.Key.kern)
        confirmNewPassword.defaultTextAttributes.updateValue(10,forKey: NSAttributedString.Key.kern)
        
        enterOldPassword.defaultTextAttributes.updateValue(10,forKey: NSAttributedString.Key.kern)


        
    }
    @IBAction func BackButttonClick(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func viewOldPassword(_ sender: Any) {
        if let button = sender as? UIButton {
            addButtonRipple(button: button)
        }
        viewPassword(textField: self.enterOldPassword, imageView: self.oldImageView)

    }
    
    @IBAction func viewNewPassword(_ sender: Any) {
        if let button = sender as? UIButton {
            addButtonRipple(button: button)
        }
        viewPassword(textField:  self.enterNewPassword, imageView: self.ennterNewImage)

    }
    
    @IBAction func viewPasswordConfirm(_ sender: Any) {
        if let button = sender as? UIButton {
            addButtonRipple(button: button)
        }
        viewPassword(textField:  self.confirmNewPassword, imageView: self.enterConfirmImage)

    }
    
    func viewPassword(textField : UITextField, imageView: UIImageView) {
        textField.isSecureTextEntry = !textField.isSecureTextEntry
        imageView.image = textField.isSecureTextEntry ? UIImage(named: ImageConstant.hide_Password) : UIImage(named: ImageConstant.showeye_password)
    }
    
    @IBAction func saveButtonClick(_ sender: Any) {
        if changePassword() == false {
            return
        }
        if enterOldPassword.text == FlyDefaults.appLockPassword &&  enterNewPassword.text == confirmNewPassword.text{
            FlyDefaults.appLockPassword = confirmNewPassword.text ?? ""
            FlyDefaults.appLockPasswordDate = Date()
            print(confirmNewPassword.text ?? "")
            FlyDefaults.appFingerprintenable = false
            self.showToastWithMessage(message: SuccessMessage.pinChangedSuccessfully)
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = 4
        if textField.text == enterOldPassword.text{
            print("enterOldPassword.text")
        }
        else if textField.text == enterNewPassword.text{
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
    
    func changePassword() -> Bool {
        view.endEditing(true)
        if enterNewPassword.text == nil || enterNewPassword.text == "" && confirmNewPassword.text == nil || confirmNewPassword.text == "" && enterOldPassword.text == nil || enterOldPassword.text == "" {
            self.showToastWithMessage(message: ErrorMessage.invalidOLDPIN)
            return false
        }
        if enterOldPassword.text == nil || enterOldPassword.text == "" {
            self.showToastWithMessage(message: ErrorMessage.enterthePIN)
            return false
        }
        if enterNewPassword.text == nil || enterNewPassword.text == "" {
            self.showToastWithMessage(message: ErrorMessage.enternewPIN)
            return false
        }
        if confirmNewPassword.text == nil || confirmNewPassword.text == "" {
            self.showToastWithMessage(message: ErrorMessage.enterconfirmPIN)
            return false
        }
        if (enterOldPassword.text?.count ?? 0) < 4 {
            self.showToastWithMessage(message: ErrorMessage.enterValidPIN)
            return false
        }
        if (enterNewPassword.text?.count ?? 0) < 4 {
            self.showToastWithMessage(message: ErrorMessage.enterValidPIN)
            return false
        }
        if (confirmNewPassword.text?.count ?? 0) < 4 {
            self.showToastWithMessage(message: ErrorMessage.enterValidPIN)
            return false
        }
        if enterOldPassword.text != FlyDefaults.appLockPassword{
            self.showToastWithMessage(message: ErrorMessage.invalidOLDPIN)
            return false
        }
        
        if confirmNewPassword.text != enterNewPassword.text {
            self.showToastWithMessage(message: ErrorMessage.passwordShouldbeSame)
            return false
        }
        if enterOldPassword.text == enterNewPassword.text {
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
}
