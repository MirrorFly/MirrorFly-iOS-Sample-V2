//
//  ViewAllMediaCell.swift
//  MirrorflyUIkit
//
//  Created by John on 28/01/22.
//

import UIKit

class ViewAllMediaCell: UITableViewCell {

    @IBOutlet weak var nextImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
