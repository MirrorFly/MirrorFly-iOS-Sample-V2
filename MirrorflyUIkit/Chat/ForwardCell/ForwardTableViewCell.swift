//
//  ForwardTableViewCell.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya T on 14/12/21.
//

import UIKit

class ForwardTableViewCell: UITableViewCell {
    @IBOutlet weak var checkBoxImageView: UIImageView?
    @IBOutlet weak var checkBoxView: UIView?
    @IBOutlet weak var decriptionLabel: UILabel?
    @IBOutlet weak var usernameLabel: UILabel?
    @IBOutlet weak var profileImageView: UIImageView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}
