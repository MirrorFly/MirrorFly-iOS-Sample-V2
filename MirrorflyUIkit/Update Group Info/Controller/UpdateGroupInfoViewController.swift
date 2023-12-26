//
//  UpdateGroupInfoViewController.swift
//  MirrorflyUIkit
//
//  Created by Prabakaran M on 07/03/22.
//

import UIKit

protocol UpdateGroupNameDelegate: class {
    func updatedGroupName(groupName: String)
}

class UpdateGroupInfoViewController: UIViewController {
    
    var groupName = ""
    var updatedGroupName = ""
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var clearTextButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    weak var delegate: UpdateGroupNameDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateUI()
    }
    
    // MARK: - UpdateUI
    
    private func updateUI() {
        setUpStatusBar()
        textField.delegate = self
        textField.text = groupName
        clearTextButton.layer.cornerRadius = 16
    }
    
    // MARK: - User Intractions
    
    @IBAction func closeButtonAction(sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func saveButtonAction(sender: UIButton) {
        if textField.text == "" {
            AppAlert.shared.showToast(message: enterGroupName)
        } else {
            delegate?.updatedGroupName(groupName: updatedGroupName.isEmpty ? groupName : updatedGroupName)
            navigationController?.popViewController(animated: true)
            // AppAlert.shared.showToast(message: "Group name changed successfully")
        }
    }
    
    @IBAction func clearTextButton(sender: UIButton) {
        textField.text = ""
    }
}

extension UpdateGroupInfoViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = groupName
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updatedGroupName = textField.text ?? ""
        delegate?.updatedGroupName(groupName: updatedGroupName)
        
    }
}

extension UITextField {
    func clearClicked(sender: UIButton) {
        text = ""
    }
}
