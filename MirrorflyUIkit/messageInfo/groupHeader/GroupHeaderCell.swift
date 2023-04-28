//
//  GroupHeaderCell.swift
//  MirrorflyUIkit
//
//  Created by John on 17/10/22.
//

import UIKit

class GroupHeaderCell: UITableViewCell {

    @IBOutlet weak var addOrRemoveImage: UIImageView!
    @IBOutlet weak var circleImage: UIImageView!
    
    @IBOutlet weak var deliveredLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        circleImage.layer.cornerRadius = 12.5
        circleImage.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
