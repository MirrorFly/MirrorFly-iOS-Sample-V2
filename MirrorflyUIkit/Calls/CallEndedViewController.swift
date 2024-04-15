//
//  CallEndedViewController.swift
//  MirrorflyUIkit
//
//  Created by MohanRaj on 22/05/23.
//

import UIKit

class CallEndedViewController: UIViewController {

    @IBOutlet weak var logoImage: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var subTitleLabel: UILabel!
    
    @IBOutlet weak var returnChatButton: UIButton!
    
    var errorMessage = ""
    
    var isInvalidLink = false
    
    var isFromCallLog = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupUI()
    }
    
    func setupUI() {
        
        logoImage.image = isInvalidLink ? UIImage(named: "icon_invalid_link") :  UIImage(named: "icon_call_ended")
        titleLabel.text = isInvalidLink ? "Invalid link" : "Call Ended!"
        subTitleLabel.isHidden = isInvalidLink ? true : false
        subTitleLabel.text = errorMessage
        returnChatButton.isHidden = isInvalidLink ? false : true
    
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        
        for controller in self.navigationController!.viewControllers as Array {
            if controller.isKind(of: ChatViewParentController.self) || (controller.isKind(of: MainTabBarController.self)  && isFromCallLog){
                self.navigationController!.popToViewController(controller, animated: true)
                break
            }
        }
    }
    
    @IBAction func backToChatAction(_ sender: Any) {
        
        for controller in self.navigationController!.viewControllers as Array {
            if controller.isKind(of: ChatViewParentController.self) {
                self.navigationController!.popToViewController(controller, animated: true)
                break
            }
        }
    }
    
}
