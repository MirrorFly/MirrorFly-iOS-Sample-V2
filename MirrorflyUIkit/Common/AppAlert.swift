//
//  AppAlert.swift
//  MirrorflyUIkit
//
//  Created by User on 12/08/21.
//

import Foundation
import UIKit
import Toaster

class AppAlert: NSObject {

    //Singleton class
    static let shared = AppAlert()

    //MARK: - Delegate
    var onAlertAction : ((Int)->Void)?
    
    var alert : UIAlertController? = nil

    //Simple Alert view
    func showToast(message : String){
         let toast = Toast(text: message)
         toast.show()
    }
    
    func showToastWithDuration(message : String, duration: Double){
        let toast = Toast(text: message, duration: duration)
         toast.show()
    }
    func showAlert(view: UIViewController, buttonTitle: String) {

        let alert = UIAlertController(title: "", message: "", preferredStyle: UIAlertController.Style.alert)
        //okButton Action
        let okButton = UIAlertAction(title: buttonTitle, style: UIAlertAction.Style.default) {
            (result : UIAlertAction) -> Void in
            view.dismiss(animated: true, completion: nil)
            self.onAlertAction?(0)
        }
        okButton.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
        alert.addAction(okButton)
        DispatchQueue.main.async {
            view.present(alert, animated: true, completion: nil)
        }
     
    }
    
    //Simple Alert view with button one
    func showAlert(view: UIViewController, title: String, message: String, buttonTitle: String) {

        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        //okButton Action
        let okButton = UIAlertAction(title: buttonTitle, style: UIAlertAction.Style.default) {
            (result : UIAlertAction) -> Void in
            view.dismiss(animated: true, completion: nil)
            self.onAlertAction?(0)
        }
        okButton.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
        alert.addAction(okButton)
        DispatchQueue.main.async {
            view.present(alert, animated: true, completion: nil)
        }
     
    }

    //Simple Alert view with two button
    func showAlert(view: UIViewController, title: String? = nil, message: String, buttonOneTitle: String? = cancelUppercase.localized, buttonTwoTitle: String, buttonOneColor: UIColor? = nil, buttonTwoColor: UIColor? = nil, cancelWhenTapOutside : Bool = false, showSecondButton: Bool = true){
        alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)

        //Button One Action
        let buttonOne = UIAlertAction(title: buttonOneTitle, style: UIAlertAction.Style.default)  {
            (result : UIAlertAction) -> Void in
            //Cancel Action
            self.onAlertAction?(0)
            view.dismiss(animated: true, completion: nil)
        }
        if let buttonOneColor = buttonOneColor {
            buttonOne.setValue(buttonOneColor, forKey: "titleTextColor")
        } else {
            buttonOne.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
        }
        //Button Two Action
        let buttonTwo = UIAlertAction(title: buttonTwoTitle,
                                      style: UIAlertAction.Style.default)
        {
            (result : UIAlertAction) -> Void in
            self.onAlertAction?(1)
        }
        
        if let buttonTwoColor = buttonTwoColor {
            buttonTwo.setValue(buttonTwoColor, forKey: "titleTextColor")
        } else {
            buttonTwo.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
        }
        
        alert?.addAction(buttonOne)
        if showSecondButton {
            alert?.addAction(buttonTwo)
        }

        DispatchQueue.main.async {
            if let alert = self.alert {
                view.present(alert, animated: true) {
                    if cancelWhenTapOutside {
                        alert.view.superview?.isUserInteractionEnabled = true
                        alert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.alertControllerBackgroundTapped)))
                    }
                }
            }
        }
    }
    
    @objc private func alertControllerBackgroundTapped()
    {
        alert?.dismiss(animated: true, completion: nil)
    }
    
    /// Contact access permission if user disabeld in device Settings
    
    func contactAccess(view: UIViewController, title: String, message: String, settingstitle: String, cancelTitle: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: settingstitle, style: UIAlertAction.Style.default, handler: { action in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                })
            }
        }))
        
        alert.addAction(UIAlertAction(title: cancelTitle, style: UIAlertAction.Style.default, handler: nil))
        
        DispatchQueue.main.async {
            view.present(alert, animated: true, completion: nil)
        }
    }
}
