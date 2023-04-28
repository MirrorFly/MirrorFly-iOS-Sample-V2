//
//  SearchRecentChatTableViewCell.swift
//  MirrorflyUIkit
//
//  Created by User on 14/09/21.
//

import UIKit

class SearchRecentChatTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImageButton: UIButton!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userMessageLabel: UILabel!
    @IBOutlet weak var chatTimeLabel: UILabel!
    @IBOutlet weak var countView: UIView!
    @IBOutlet weak var countLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
