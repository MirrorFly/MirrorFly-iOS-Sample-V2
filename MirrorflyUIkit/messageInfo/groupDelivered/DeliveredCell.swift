//
//  DeliveredCell.swift
//  MirrorflyUIkit
//
//  Created by John on 17/10/22.
//

import UIKit

class DeliveredCell: UITableViewCell {

    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var deliveredTimeLabel: UILabel!
    @IBOutlet weak var seperatorLine: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        userImage.layer.cornerRadius =  27.5
        userImage.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
