//
//  WebSettingsCell.swift
//  MirrorflyUIkit
//
//  Created by John on 20/01/22.
//

import UIKit

class WebSettingsCell: UITableViewCell {

    @IBOutlet weak var topDividerHeight: NSLayoutConstraint!
    @IBOutlet weak var loginTime: UILabel?
    @IBOutlet weak var browserName: UILabel?
    @IBOutlet weak var browserIcon: UIImageView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
