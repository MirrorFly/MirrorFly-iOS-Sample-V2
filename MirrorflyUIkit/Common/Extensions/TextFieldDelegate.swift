//
//  TextFieldDelegate.swift
//  MirrorflyUIkit
//
//  Created by User on 16/09/21.
//

import Foundation
import UIKit

protocol CustomTextFieldDelegate: UITextFieldDelegate {
    func textField(_ textField: UITextField, didDeleteBackwardAnd wasEmpty: Bool)
}

class CustomTextField: UITextField {
    override func deleteBackward() {
        text = ""
        let wasEmpty = text == nil || text! == ""

        // then perform normal behavior
        super.deleteBackward()

        // now, notify delegate (if existent)
        (delegate as? CustomTextFieldDelegate)?.textField(self, didDeleteBackwardAnd: wasEmpty)
    }
}
