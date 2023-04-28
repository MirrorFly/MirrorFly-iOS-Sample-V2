//
//  NotificationToneListCell.swift
//  MirrorflyUIkit
//
//  Created by Amose Vasanth on 29/12/22.
//

import UIKit

class NotificationToneListCell: UITableViewCell {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var toneNameLabel: UILabel!
    @IBOutlet weak var selectedImageView: UIImageView!

    @IBOutlet weak var seperatorLine: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
