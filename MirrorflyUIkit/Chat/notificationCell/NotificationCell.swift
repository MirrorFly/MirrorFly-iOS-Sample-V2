//
//  NotificationCell.swift
//  MirrorflyUIkit
//
//  Created by John on 26/11/21.
//

import UIKit

class NotificationCell: UITableViewCell {
    
    @IBOutlet weak var notificationLabel: UILabel!
    
    @IBOutlet weak var background: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        background.layer.cornerRadius = 13
        background.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
