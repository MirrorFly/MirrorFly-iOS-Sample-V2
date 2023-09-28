//
//  TextFieldExtension.swift
//  MirrorflyUIkit
//
//  Created by Gowtham on 07/09/23.
//

import Foundation
import UIKit

extension UITextField {
    
    //To set automation identifier
    func setAutomationIdentifier(label: String, id: String) {
        self.accessibilityLabel = label
        self.accessibilityIdentifier = id
    }
}

extension UISearchBar {
    
    //To set automation identifier
    func setAutomationIdentifier(label: String, id: String) {
        self.accessibilityLabel = label
        self.accessibilityIdentifier = id
    }
}
