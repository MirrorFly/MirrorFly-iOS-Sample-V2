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

        
        let profileDetails = groupInfoViewModel.checkContactType(participantJid: groupInfo.memberJid)
        if profileDetails?.mobileNumber == "" {
            nameLabel.text = "Deleted User"
            nickNameLabel.text = ""
            userImageView?.image = UIImage(named: "ic_profile_placeholder") ?? UIImage()
        } else {
            nameLabel.text = userName
            statusLabel.text = groupInfo.profileDetail?.status
            setUsersImage(userName: userName, groupInfo: groupInfo)
            
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
            let isBlockedMyAdmin = profileDetails?.isBlockedByAdmin ?? false
            
            if profileDetails?.contactType == .deleted || blockedMe || isBlockedMyAdmin || (IS_LIVE && ENABLE_CONTACT_SYNC && profileDetails?.isItSavedContact == false && groupInfo.memberJid != FlyDefaults.myJid){
                userImageView?.image = UIImage(named: "ic_profile_placeholder") ?? UIImage()
                statusLabel.text = ""
            }
            if profileDetails?.isItSavedContact == false {
                userImageView?.image = UIImage(named: "ic_profile_placeholder") ?? UIImage()
            }

            if groupInfo.memberJid == FlyDefaults.myJid {
                nameLabel.text = "You"
                nickNameLabel.text = ""
                setUsersImage(userName: FlyDefaults.myName, groupInfo: groupInfo)
            }
        }
        
    }
    
    func setUsersImage(userName: String, groupInfo: GroupParticipantDetail) {
        
        if let profileDetail = groupInfo.profileDetail {
            let profileImage = profileDetail.thumbImage.isEmpty ? profileDetail.image : profileDetail.thumbImage
            if profileImage.isEmpty {
                userImageView?.image = ChatUtils.getPlaceholder(name: userName, userColor: ChatUtils.getColorForUser(userName: userName), userImage: userImageView)
            } else {
                userImageView?.loadFlyImage(imageURL: profileImage, name: userName,
                                            chatType: profileDetail.profileChatType,
                                            jid: profileDetail.jid)
            }
        }
    }
}
