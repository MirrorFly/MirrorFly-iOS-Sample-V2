//
//  ForceUpdateAlert.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya on 30/01/23.
//

import Foundation
import UIKit

class ForceUpdateAlertViewController : UIViewController, OnUpdateNeededListener {
    
    @IBOutlet weak var updateNowButton: UIButton?
    @IBOutlet weak var forceUpdateView: UIView?
    @IBOutlet weak var forceDescription: UILabel?
    @IBOutlet weak var forceTitle: UILabel?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        forceUpdateView?.roundCorners(corners: [.bottomLeft,.topLeft, .bottomRight,.topRight], radius: 10)
        setForceUpdateTitleDescription()
    }
    
    func setForceUpdateTitleDescription() {
        let forceUpdateChecker = ForceUpdateChecker(listener: self)
        forceTitle?.text = forceUpdateChecker.setTitleAndDescription().0
        forceDescription?.text = forceUpdateChecker.setTitleAndDescription().1
    }
    
    @IBAction func updateNowAction(_ sender: UIButton) {
        if let url = URL(string: "https://apps.apple.com/us/app/mirror-fly/id1442769177") {
            UIApplication.shared.open(url)
        }
    }
    
    func onUpdateNeeded(updateUrl: String) {
        
    }
    
    func onNoUpdateNeeded() {
        
    }
}
