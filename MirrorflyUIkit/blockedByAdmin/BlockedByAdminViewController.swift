//
//  BlockedByAdminViewController.swift
//  UiKitQa
//
//  Created by John on 18/04/22.
//

import UIKit

class BlockedByAdminViewController: UIViewController {

    @IBOutlet weak var emailLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailLabel.underLine(text: adminEmail)
    }
    
    @IBAction func didTapOkButton(_ sender: Any) {
        var controller : OTPViewController?
        if #available(iOS 13.0, *) {
            controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "OTPViewController")
        } else {
            // Fallback on earlier versions
            controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "OTPViewController") as? OTPViewController
        }
        let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if let navigationController = window?.rootViewController  as? UINavigationController, let otpViewController = controller {
            navigationController.popToRootViewController(animated: false)
            navigationController.navigationBar.isHidden = true
            navigationController.pushViewController(otpViewController, animated: false)
        }
    }
    
}
