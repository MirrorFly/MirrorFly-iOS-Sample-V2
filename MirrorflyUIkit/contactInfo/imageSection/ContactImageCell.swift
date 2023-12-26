//
//  ContactImageTableViewCell.swift
//  MirrorflyUIkit
//
//  Created by John on 28/01/22.
//

import UIKit

protocol ContactImageCellDelegate: class {
    func updatedGroupName(groupName: String)
}

class ContactImageCell: UITableViewCell {
    @IBOutlet weak var backButton: UIButton?
    @IBOutlet weak var onlineStatus: UILabel?
    @IBOutlet weak var userNameLabel: UILabel?
    @IBOutlet weak var editTextField: UITextField!
    @IBOutlet weak var editButton: UIButton?
    @IBOutlet weak var editProfileButton: UIButton?
    @IBOutlet weak var userImage: UIImageView?
    
    weak var delegate: ContactImageCellDelegate? = nil
    let groupCreationViewModel = GroupCreationViewModel()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        editTextField.delegate = self
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

extension ContactImageCell: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.updatedGroupName(groupName: textField.text ?? "")
    }
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        
        var tempString : String = string
              if string.count > 25 {
                  tempString = tempString.substring(to: 25)
                  textField.text = tempString
              }
              let count = groupCreationViewModel.calculateTextLength(startingLength: textField.text?.count ?? 0, lengthToAdd: tempString.count, lengthToReplace: range.length)
              let countToDisplay = groupNameCharLimit - count
              return groupCreationViewModel.textLimit(existingText: textField.text ?? "", newText: tempString, limit: groupNameCharLimit);
    }
}
