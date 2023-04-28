//
//  AppLockTableViewCell.swift
//  UiKitQa
//
//  Created by Ramakrishnan on 08/11/22.
//

import UIKit

class AppLockTableViewCell: UITableViewCell {

   
    @IBOutlet weak var uiswitchoutlet: UISwitch!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var helpTextLabel: UILabel!
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var helpTextView: UIView!
    @IBOutlet weak var ChooseLangugaeLabel: UILabel!
    @IBOutlet weak var defaultLanguageLabel: UILabel!
    @IBOutlet weak var doubleTapLabel: UILabel!
    @IBOutlet weak var formaImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
