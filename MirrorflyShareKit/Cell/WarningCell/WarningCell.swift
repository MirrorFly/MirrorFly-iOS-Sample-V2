//
//  WarningCell.swift
//  MirrorflyShareKit
//
//  Created by Sowmiya on 06/03/23.
//

import UIKit

class WarningCell: UITableViewCell {
    @IBOutlet weak var TitleLabel: UILabel?
    @IBOutlet weak var fileSizeLabel: UILabel?
    @IBOutlet weak var durationLabel: UILabel?
    @IBOutlet weak var fileTypeLabel: UILabel?
    @IBOutlet weak var mediaFile: UIImageView?
    @IBOutlet weak var errorLabel: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        mediaFile?.roundCorners(corners: [.topLeft,.topRight,.bottomLeft,.bottomRight], radius: 5.0)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
