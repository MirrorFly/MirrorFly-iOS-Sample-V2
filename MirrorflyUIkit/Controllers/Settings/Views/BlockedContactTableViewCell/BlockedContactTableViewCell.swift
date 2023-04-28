//
//  BlockedContactTableViewCell.swift
//  UiKitQa
//
//  Created by Amose Vasanth on 24/11/22.
//

import UIKit
import MirrorFlySDK

class BlockedContactTableViewCell: UITableViewCell {

    
    @IBOutlet weak var userNameLabel: UILabel?
    @IBOutlet weak var profileImageView: UIImageView? {
        didSet {
            profileImageView?.setCircleView()
        }
    }
    @IBOutlet weak var userContactLabel: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    private func getColor(userName : String) -> UIColor {
        return ChatUtils.getColorForUser(userName: userName)
    }

    func setupCell(contact: ProfileDetails) {
        let name = FlyUtils.getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType)
        userNameLabel?.text = name
        userContactLabel?.text = contact.mobileNumber
        let profileImage = contact.thumbImage.isEmpty ? contact.image : contact.thumbImage
        profileImageView?.loadFlyImage(imageURL: profileImage, name: name, jid: contact.jid, validateBlock: false)
    }
    
}
