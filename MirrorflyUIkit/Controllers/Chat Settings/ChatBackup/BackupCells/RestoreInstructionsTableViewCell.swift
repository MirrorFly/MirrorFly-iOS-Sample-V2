//
//  RestoreInstructionsTableViewCell.swift
//  MirrorflyUIkit
//
//  Created by Gowtham on 22/11/22.
//

import UIKit

class RestoreInstructionsTableViewCell: UITableViewCell {

    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var infoImageView: UIImageView!
    @IBOutlet weak var infoLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}
