//
//  ButtonExtension.swift
//  MirrorflyUIkit
//
//  Created by User on 16/08/21.
//

import Foundation
import UIKit

extension UIButton {
    //Set cornor radius based on width or height
    func setCornorRadius() {
        self.layer.cornerRadius = self.frame.height/2
        self.layer.masksToBounds = true
    }

    //Set title color
    func textColor(color: UIColor) {
        self.setTitleColor(color, for: .normal)
    }
    
    //Set button border with color
    func setBorderwithColor(borderColor: UIColor, textColor: UIColor, backGroundColor: UIColor, borderWidth: CGFloat) {
        self.setTitleColor(textColor, for: .normal)
        self.layer.borderColor = borderColor.cgColor
        self.backgroundColor = backGroundColor
        self.layer.borderWidth = borderWidth
    }
    
    //To set automation identifier
    func setAutomationIdentifier(label: String = "", id: String) {
        self.accessibilityLabel = label.isEmpty ? titleLabel?.text : label
        self.accessibilityIdentifier = id
    }
}
