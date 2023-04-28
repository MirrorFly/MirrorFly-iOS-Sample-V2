//
//  SettingsTableViewCell.swift
//  MirrorflyUIkit
//
//  Created by user on 28/02/22.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {
    @IBOutlet weak var imgicon: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
