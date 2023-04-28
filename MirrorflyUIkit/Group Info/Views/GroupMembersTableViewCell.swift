//
//  GroupMembersTableViewCell.swift
//  MirrorflyUIkit
//
//  Created by Prabakaran M on 03/03/22.
//

import UIKit
import MirrorFlySDK
import SDWebImage

class GroupMembersTableViewCell: UITableViewCell {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var nickNameLabel: UILabel!
    @IBOutlet weak var adminLabel: UILabel!
    var isAdminMember: Bool = false
    
    var profileDetails: ProfileDetails!
    let groupInfoViewModel = GroupInfoViewModel()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.separatorInset = UIEdgeInsets(top: 0, left: 64, bottom: 0, right: 19)
        userImageView.layer.cornerRadius = 20
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    func getGroupInfo(groupInfo: GroupParticipantDetail) {
        nickNameLabel.text = ""
        
        let userName = getUserName(jid : groupInfo.profileDetail?.jid ?? "", name: groupInfo.profileDetail?.name ?? "",
                                   nickName: groupInfo.profileDetail?.nickName ?? "",
                                   contactType: groupInfo.profileDetail?.contactType ?? .unknown)
        nameLabel.text = userName
        statusLabel.text = groupInfo.profileDetail?.status
        setUsersImage(userName: userName, groupInfo: groupInfo)
        
        if groupInfo.memberJid == FlyDefaults.myJid {
            nameLabel.text = "You"
            nickNameLabel.text = ""
            setUsersImage(userName: FlyDefaults.myName, groupInfo: groupInfo)
        }
        
        let profileDetails = groupInfoViewModel.checkContactType(participantJid: groupInfo.memberJid)
        self.profileDetails = profileDetails
        
        if self.profileDetails?.contactType == .unknown {
            nickNameLabel.text = ("\("~")\(groupInfo.profileDetail?.name ?? "")")
        }
        
        if groupInfo.isAdminMember == true {
            adminLabel.text = "Admin"
        } else {
            adminLabel.text = ""
        }
        
        let blockedMe = profileDetails?.isBlockedMe ?? false
        
        if profileDetails?.contactType == .deleted || blockedMe {
            userImageView?.image = UIImage(named: "ic_profile_placeholder") ?? UIImage()
            statusLabel.text = ""
        }
    }
    
    func setUsersImage(userName: String, groupInfo: GroupParticipantDetail) {
        
        let urlString = "\(FlyDefaults.baseURL)\(media)/\(groupInfo.profileDetail?.image ?? "")?mf=\(FlyDefaults.authtoken)"
        let imageURL = URL(string: urlString)
        var placeholderImage: UIImage
        
        if (imageURL != nil) {
            placeholderImage = ChatUtils.getPlaceholder(name: userName, userColor: ChatUtils.getColorForUser(userName: userName),
                                                        userImage: userImageView)
            userImageView?.sd_setImage(with: imageURL, placeholderImage: placeholderImage)
        } else {
            userImageView?.loadFlyImage(imageURL: groupInfo.profileDetail?.image ?? "", name: userName,
                                        chatType: groupInfo.profileDetail?.profileChatType ?? .singleChat,
                                        jid: groupInfo.profileDetail?.jid ?? "")
        }
    }
}
