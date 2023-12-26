//
//  ContactInfoCell.swift
//  MirrorflyUIkit
//
//  Created by John on 28/01/22.
//

import UIKit

class ContactInfoCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var icon: UIImageView?
    @IBOutlet weak var contentLabel: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
