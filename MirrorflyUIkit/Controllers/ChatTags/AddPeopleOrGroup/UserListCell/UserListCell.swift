//
//  UserListCell.swift
//  MirrorflyUIkit
//
//  Created by MohanRaj on 13/02/23.
//

import UIKit
import MirrorFlySDK

class UserListCell: UITableViewCell {
    
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var checkBoxImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    func setUserListDetails(recentChat: RecentChat,color: UIColor) {
        
        titleLabel?.text = getUserName(jid: recentChat.jid,name: recentChat.profileName, nickName: recentChat.nickName, contactType: (recentChat.isDeletedUser ? .deleted :  recentChat.isItSavedContact ? .live : .unknown))

        if !recentChat.isDeletedUser || !(IS_LIVE && ENABLE_CONTACT_SYNC && recentChat.isItSavedContact == false) {
            checkBoxImage?.image = recentChat.isSelected ?  UIImage(named: ImageConstant.selected_user) : UIImage(named: ImageConstant.select_user)
            setImage(imageURL: recentChat.profileImage ?? "", name: getUserName(jid: recentChat.jid, name: recentChat.profileName, nickName: recentChat.nickName, contactType: recentChat.isItSavedContact ? .live : .unknown), color: color , recentChat: recentChat)
            checkBoxImage?.isHidden = false
        }else{
            profileImage?.sd_setImage(with: nil, placeholderImage: UIImage(named: ImageConstant.ic_profile_placeholder)!)
            checkBoxImage?.isHidden = true
        }
        if getisBlockedMe(jid: recentChat.jid) || (IS_LIVE && ENABLE_CONTACT_SYNC && recentChat.isItSavedContact == false) {
            profileImage?.sd_setImage(with: nil, placeholderImage: UIImage(named: ImageConstant.ic_profile_placeholder)!)
        }
        
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
