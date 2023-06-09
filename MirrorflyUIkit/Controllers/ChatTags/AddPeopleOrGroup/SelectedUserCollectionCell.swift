//
//  SelectedUserCollectionCell.swift
//  MirrorflyUIkit
//
//  Created by MohanRaj on 10/02/23.
//

import UIKit
import MirrorFlySDK

class SelectedUserCollectionCell: UICollectionViewCell {
    
    
    @IBOutlet weak var profileImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setImage(imageURL: String, name: String, color: UIColor , recentChat : RecentChat) {
        let urlString = "\(FlyDefaults.baseURL + "" + media + "/" + imageURL + "?mf=" + "" + FlyDefaults.authtoken)"
        var url = URL(string: urlString)
        var placeHolder = UIImage()
        if recentChat.profileType == .groupChat {
            placeHolder = UIImage(named: ImageConstant.ic_group_small_placeholder)!
        }else if recentChat.isDeletedUser || getisBlockedMe(jid: recentChat.jid) || (IS_LIVE && ENABLE_CONTACT_SYNC && recentChat.isItSavedContact == false) {
            placeHolder = UIImage(named: ImageConstant.ic_profile_placeholder)!
            url = nil
        }else {
            placeHolder = getPlaceholder(name: name, color: color)
        }
        profileImage?.sd_setImage(with: url, placeholderImage: placeHolder)
    }
    
    private func getisBlockedMe(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlockedMe ?? false
    }
    
    func getPlaceholder(name: String , color: UIColor)->UIImage {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let ipimage = IPImage(text: trimmedName, radius: Double(profileImage?.frame.size.height ?? 0.0), font: UIFont.font32px_appBold(), textColor: nil, color: color)
        let placeholder = ipimage.generateInitialImage()
        return placeholder ?? #imageLiteral(resourceName: "ic_profile_placeholder")
    }

}
