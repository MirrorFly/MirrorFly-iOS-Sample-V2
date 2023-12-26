//
//  MuteNotificationCell.swift
//  MirrorflyUIkit
//
//  Created by John on 28/01/22.
//

import UIKit

class MuteNotificationCell: UITableViewCell {

    @IBOutlet weak var muteSwitch: UISwitch? {
        didSet {
            muteSwitch?.onTintColor = Color.muteSwitchColor
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
