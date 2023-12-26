//
//  ArchiveChatTableViewCell.swift
//  UiKitQa
//
//  Created by Amose Vasanth on 31/10/22.
//

import UIKit

class ArchiveChatTableViewCell: UITableViewCell {

    @IBOutlet weak var archiveChatImage: UIImageView!
    @IBOutlet weak var archiveTextLabel: UILabel!
    @IBOutlet weak var chatCountLabel: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
