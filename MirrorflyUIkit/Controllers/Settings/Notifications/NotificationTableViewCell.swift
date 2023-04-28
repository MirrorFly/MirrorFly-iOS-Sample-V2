//
//  NotificationTableViewCell.swift
//  UiKitQa
//
//  Created by Ramakrishnan on 19/10/22.
//

import UIKit

class NotificationTableViewCell: UITableViewCell {

   
    @IBOutlet weak var titlelabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
       
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}
