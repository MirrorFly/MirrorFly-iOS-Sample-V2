//
//  ShareKitAlert.swift
//  MirrorflyUIkit
//
//  Created by John on 17/02/23.
//

import Foundation
import UIKit

class ShareKitAlert {
    
    //Singleton class
    static let shared = ShareKitAlert()

    
    
    var alert : UIAlertController? = nil

    //Simple Alert view
    func showToast(controller : UIViewController, message : String, position: MFToastPosition = .bottom){
        //let toast = Toast(text: message)
        //toast.show()
        let toastLabel = UILabel()
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        toastLabel.padding = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        toastLabel.numberOfLines = 0
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.font = UIFont.font12px_appRegular()
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        controller.view.addSubview(toastLabel)
        NSLayoutConstraint.activate([
            toastLabel.leftAnchor.constraint(greaterThanOrEqualTo: controller.view.leftAnchor, constant: 15),
            toastLabel.rightAnchor.constraint(lessThanOrEqualTo: controller.view.rightAnchor, constant: -15),
            toastLabel.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.bottomAnchor, constant: position == .bottom ?  -20 : -(UIScreen.main.bounds.height/2))
        ])
        UIView.animate(withDuration: 5.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
        
    }
    
    func showAlert(view: UIViewController, buttonTitle: String, completionHandler : @escaping (Int) -> Void) {

        let alert = UIAlertController(title: "", message: "", preferredStyle: UIAlertController.Style.alert)
        //okButton Action
        let okButton = UIAlertAction(title: buttonTitle, style: UIAlertAction.Style.default) {
            (result : UIAlertAction) -> Void in
            view.dismiss(animated: true, completion: nil)
            completionHandler(0)
        }
        okButton.setValue(ShareKitColor.color_3276E2!, forKey: "titleTextColor")
        alert.addAction(okButton)
        DispatchQueue.main.async {
            view.present(alert, animated: true, completion: nil)
        }
     
    }
    
    //Simple Alert view with button one
    func showAlert(view: UIViewController, title: String, message: String, buttonTitle: String, completionHandler : @escaping (Int) -> Void) {

        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        //okButton Action
        let okButton = UIAlertAction(title: buttonTitle, style: UIAlertAction.Style.default) {
            (result : UIAlertAction) -> Void in
            view.dismiss(animated: true, completion: nil)
            completionHandler(0)
        }
        okButton.setValue(ShareKitColor.color_3276E2!, forKey: "titleTextColor")
        alert.addAction(okButton)
        DispatchQueue.main.async {
            view.present(alert, animated: true, completion: nil)
        }
     
    }
}
