//
//  CustomChatTagsCell.swift
//  MirrorflyUIkit
//
//  Created by MohanRaj on 15/02/23.
//

import UIKit

class CustomChatTagsCell: UITableViewCell {

    @IBOutlet weak var deleteTagButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var arrowImg: UIImageView!
    @IBOutlet weak var removeTagView: UIView!
    @IBOutlet weak var arrowWidth: NSLayoutConstraint!
    @IBOutlet weak var arrowHeight: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        deleteTagButton.titleLabel?.isHidden = true
        deleteTagButton?.isHidden = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
