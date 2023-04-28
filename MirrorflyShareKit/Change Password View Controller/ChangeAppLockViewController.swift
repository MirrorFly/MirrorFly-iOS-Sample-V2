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
        viewPassword(textField: self.enterOldPassword, imageView: self.oldImageView)

    }
    
    @IBAction func viewNewPassword(_ sender: Any) {
        viewPassword(textField:  self.enterNewPassword, imageView: self.ennterNewImage)

    }
    
    @IBAction func viewPasswordConfirm(_ sender: Any) {
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
            ShareKitAlert.shared.showToast(controller: self, message: SuccessMessage.PINsetsuccessfully)
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

        return newString.count <= maxLength
    }
    
    func changePassword() -> Bool {
        if enterNewPassword.text == nil || enterNewPassword.text == "" && confirmNewPassword.text == nil || confirmNewPassword.text == "" && enterOldPassword.text == nil || enterOldPassword.text == "" {
            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.invalidOLDPIN)
            return false
        }
        if enterNewPassword.text == nil || enterNewPassword.text == "" && confirmNewPassword.text == nil || confirmNewPassword.text == "" {
            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.enterthePIN)
            return false
        }
        if enterOldPassword.text == nil || enterOldPassword.text == "" {
            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.enterthePIN)
            return false
        }
        if enterNewPassword.text == nil || enterNewPassword.text == "" {
            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.enternewPIN)
            return false
        }
        if confirmNewPassword.text == nil || confirmNewPassword.text == "" {
            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.enterconfirmPIN)
            return false
        }
        if (enterOldPassword.text?.count ?? 0) < 4 {
            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.enterValidPIN)
            return false
        }
        if (enterNewPassword.text?.count ?? 0) < 4 {
            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.enterValidPIN)
            return false
        }
        if (confirmNewPassword.text?.count ?? 0) < 4 {
            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.enterValidPIN)
            return false
        }
        if enterOldPassword.text != FlyDefaults.appLockPassword{
            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.invalidOLDPIN)
            return false
        }
        
        if confirmNewPassword.text != enterNewPassword.text {
            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.passwordShouldbeSame)
            return false
        }
        if enterOldPassword.text == enterNewPassword.text {
            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.oldPINnewPINsholdnotSame)
            return false
        }
        
        return true
    }
}
