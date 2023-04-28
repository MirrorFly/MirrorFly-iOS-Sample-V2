//
//  SingleMessageInfoCell.swift
//  MirrorflyUIkit
//
//  Created by John on 17/10/22.
//

import UIKit

class SingleMessageInfoCell: UITableViewCell {

    @IBOutlet weak var labelDeliveredTime: UILabel!
    @IBOutlet weak var labelReadTime: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
