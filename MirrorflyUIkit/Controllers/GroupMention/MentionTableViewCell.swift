//
//  MentionTableViewCell.swift
//  UiKitQa
//
//  Created by Gowtham on 21/12/22.
//

import UIKit

class MentionTableViewCell: UITableViewCell {

    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var nickNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        userImageView.setCircleView()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
