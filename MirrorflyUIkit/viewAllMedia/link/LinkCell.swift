//
//  LinkCell.swift
//  MirrorflyUIkit
//
//  Created by John on 05/12/22.
//

import UIKit

class LinkCell: UITableViewCell {
    
    @IBOutlet weak var outerView: UIView!
    @IBOutlet weak var topView: UIView!
    
    @IBOutlet weak var linkImage: UIImageView!
    @IBOutlet weak var linkIcon: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var domainLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var nextIcon: UIImageView!
    @IBOutlet weak var urlStackView: UIStackView!
    @IBOutlet weak var bottomView: UIView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        outerView.roundCorners(corners: [.allCorners], radius: 6)
        topView.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 6)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
