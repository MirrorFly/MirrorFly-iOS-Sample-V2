//
//  NotificationSoundTableViewCell.swift
//  UiKitQa
//
//  Created by Ramakrishnan on 21/10/22.
//

import UIKit

class NotificationSoundTableViewCell: UITableViewCell {

    @IBOutlet weak var songTitleLabel: UILabel!
    
    @IBOutlet weak var imageoutlet: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
       
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
