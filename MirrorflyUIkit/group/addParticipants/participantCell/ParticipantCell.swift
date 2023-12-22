//
//  ParticipantCell.swift
//  MirrorflyUIkit
//
//  Created by John on 23/11/21.
//

import UIKit
import MirrorFlySDK
import SDWebImage

class ParticipantCell: UITableViewCell {

    @IBOutlet weak var removeIcon: UIButton?
    @IBOutlet weak var emptyView: UIView?
    @IBOutlet weak var removeButton: UIImageView?
    @IBOutlet weak var checkBoxImageView: UIImageView?
    @IBOutlet weak var statusUILabel: UILabel?
    @IBOutlet weak var nameUILabel: UILabel?
    @IBOutlet weak var contactImageView: UIImageView?
    @IBOutlet weak var receiverMessageTypeImageView: UIImageView?
    @IBOutlet weak var receiverMessageTypeView: UIView?
    @IBOutlet weak var statusImage: UIImageView?
    @IBOutlet weak var statusView: UIView?
    @IBOutlet weak var statusImageCons: NSLayoutConstraint?
    @IBOutlet weak var statusViewTralingCons: NSLayoutConstraint?
    @IBOutlet weak var receivedMessageTrailingCons: NSLayoutConstraint?
    override func awakeFromNib() {
        super.awakeFromNib()
        initialSetUp()
    }
    
    func initialSetUp() {
        contactImageView?.makeRounded()
    }
    
    // MARK: SetContactInformation
    func hideLastMessageContentInfo() {
        statusImage?.isHidden = true
        receiverMessageTypeView?.isHidden = true
        statusImageCons?.constant = 0
        receivedMessageTrailingCons?.constant = 0
        statusViewTralingCons?.constant = 0
    }
    
    func showLastMessageContentInfo() {
        receivedMessageTrailingCons?.constant = 5
        statusViewTralingCons?.constant = 5
        statusImageCons?.constant = 7
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func setImage(imageURL: String, name: String, color: UIColor, chatType : ChatType,jid: String) {
        if !getisBlockedMe(jid: jid) || !(IS_LIVE && ENABLE_CONTACT_SYNC && ContactManager.shared.getUserProfileDetails(for: jid)?.isItSavedContact == false) {
            contactImageView?.loadFlyImage(imageURL: imageURL, name: name, chatType: chatType, jid: jid)
        } else {
            contactImageView?.image = UIImage(named: ImageConstant.ic_profile_placeholder)!
            statusUILabel?.text = ""
        }
    }
    
    func getPlaceholder(name: String , color: UIColor)->UIImage {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let ipimage = IPImage(text: trimmedName, radius: Double(contactImageView?.frame.size.height ?? 0.0), font: UIFont.font32px_appBold(), textColor: nil, color: color)
        let placeholder = ipimage.generateInitialImage()
        return placeholder ?? #imageLiteral(resourceName: "ic_profile_placeholder")
    }
    
    private func getisBlockedMe(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlockedMe ?? false
    }
    
    func setTextColorWhileSearch(searchText: String,profileDetail: ProfileDetails) {
        let tempSearchText = searchText.trim()
        let name = getUserName(jid: profileDetail.jid,name: profileDetail.name, nickName: profileDetail.nickName, contactType: profileDetail.contactType)
        if let range = name.range(of: tempSearchText, options: [.caseInsensitive, .diacriticInsensitive]) {
            let convertedRange = NSRange(range, in: name)
            let attributedString = NSMutableAttributedString(string: name.capitalized)
            attributedString.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.systemBlue], range: convertedRange)
            nameUILabel?.attributedText = attributedString
        } else {
            nameUILabel?.text = name.capitalized
            nameUILabel?.textColor = Color.userNameTextColor
        }
    }
    
    func setImage(imageURL: String, name: String, color: UIColor , recentChat : RecentChat) {
        let urlString = ChatManager.getImageUrl(imageName: imageURL)
        var url = URL(string: urlString)
        var placeHolder = UIImage()
        if recentChat.profileType == .groupChat {
            placeHolder = UIImage(named: ImageConstant.ic_group_small_placeholder)!
        }else if recentChat.isDeletedUser || getisBlockedMe(jid: recentChat.jid) || (IS_LIVE && ENABLE_CONTACT_SYNC && recentChat.isItSavedContact == false) {
            placeHolder = UIImage(named: ImageConstant.ic_profile_placeholder)!
            url = nil
            statusUILabel?.text = ""
        }else {
            placeHolder = getPlaceholder(name: name, color: color)
        }
        contactImageView?.sd_setImage(with: url, placeholderImage: placeHolder)
    }
    
    func setImage(imageURL: String, name: String, color: UIColor , profile : ProfileDetails) {
        let urlString = ChatManager.getImageUrl(imageName: imageURL)
        var url = URL(string: urlString)
        var placeHolder = UIImage()
        if profile.profileChatType == .groupChat {
            placeHolder = UIImage(named: ImageConstant.ic_group_small_placeholder)!
        }else if profile.contactType == .deleted || getisBlockedMe(jid: profile.jid) || (IS_LIVE && ENABLE_CONTACT_SYNC && profile.isItSavedContact == false){
            placeHolder = UIImage(named: ImageConstant.ic_profile_placeholder)!
            url = nil
            statusUILabel?.text = ""
        }else {
            placeHolder = getPlaceholder(name: name, color: color)
        }
        contactImageView?.sd_setImage(with: url, placeholderImage: placeHolder)
    }
    
    func setRecentChatDetails(recentChat: RecentChat,color: UIColor) {
        nameUILabel?.text = getUserName(jid: recentChat.jid,name: recentChat.profileName, nickName: recentChat.nickName, contactType: (recentChat.isDeletedUser ? .deleted :  recentChat.isItSavedContact ? .live : .unknown))
        if recentChat.isLastMessageRecalledByUser {
            statusUILabel?.text = recentChat.isLastMessageSentByMe ? senderDeletedMessage : receiverDeletedMessage
        } else {
            statusUILabel?.text = recentChat.lastMessageContent
        }
       
        if !recentChat.isDeletedUser || !(IS_LIVE && ENABLE_CONTACT_SYNC && recentChat.isItSavedContact == false) {
            checkBoxImageView?.image = recentChat.isSelected ?  UIImage(named: ImageConstant.ic_checked) : UIImage(named: ImageConstant.ic_check_box)
            setImage(imageURL: recentChat.profileImage ?? "", name: getUserName(jid: recentChat.jid, name: recentChat.profileName, nickName: recentChat.nickName, contactType: recentChat.isItSavedContact ? .live : .unknown), color: color , recentChat: recentChat)
            checkBoxImageView?.isHidden = false
        }else{
            contactImageView?.sd_setImage(with: nil, placeholderImage: UIImage(named: ImageConstant.ic_profile_placeholder)!)
            checkBoxImageView?.isHidden = true
        }
        if getisBlockedMe(jid: recentChat.jid) {
            contactImageView?.sd_setImage(with: nil, placeholderImage: UIImage(named: ImageConstant.ic_profile_placeholder)!)
        }

        removeButton?.isHidden = true
        statusUILabel?.isHidden = false
        statusImage?.isHidden = (recentChat.isLastMessageSentByMe == true) ? false : true
        statusView?.isHidden = (recentChat.isLastMessageSentByMe == true) ? false : true
        receiverMessageTypeView?.isHidden = false
        
            switch recentChat.lastMessageType {
            case .text, .autoText:
                receiverMessageTypeView?.isHidden = true
            case .contact:
                receiverMessageTypeImageView?.image = UIImage(named: ImageConstant.ic_rccontact)
            case .image:
                receiverMessageTypeImageView?.image = UIImage(named: ImageConstant.ic_rcimage)
            case .location:
                receiverMessageTypeImageView?.image = UIImage(named: ImageConstant.ic_rclocation)
            case .audio:
                if let chatMessage = ChatManager.getMessageOfId(messageId: recentChat.lastMessageId) {
                    if chatMessage.mediaChatMessage?.audioType == AudioType.recording {
                        ChatUtils.setIconForAudio(imageView: receiverMessageTypeImageView, chatMessage: chatMessage)
                    } else {
                        receiverMessageTypeImageView?.image = UIImage(named: ImageConstant.ic_rcaudio)
                    }
                }
            case .video:
                receiverMessageTypeImageView?.image = UIImage(named: ImageConstant.ic_rcvideo)
            case .document:
                receiverMessageTypeImageView?.image = UIImage(named: ImageConstant.ic_rcdocument)
            case .meet:
                receiverMessageTypeImageView?.image = UIImage(named: ImageConstant.ic_rcmeet)
            default:
                receiverMessageTypeView?.isHidden = true
            }
    
        switch recentChat.isLastMessageSentByMe {
        case true:
            // show hide sent and received msg status
            switch recentChat.lastMessageStatus {
            case .notAcknowledged:
                statusImage?.image = UIImage(named: ImageConstant.ic_hour)
                break
            case .sent:
                switch recentChat.lastMessageType {
                case .video, .audio, .image,.text,.contact , .autoText:
                    statusImage?.image = UIImage(named: ImageConstant.ic_hour)
                default:
                    statusImage?.image = UIImage(named: ImageConstant.ic_sent)
                }
                break
            case .acknowledged:
                statusImage?.image = UIImage(named: ImageConstant.ic_sent)
                break
            case .delivered:
                statusImage?.image = UIImage(named: ImageConstant.ic_delivered)
                break
            case .seen:
                statusImage?.image = UIImage(named: ImageConstant.ic_seen)
                break
            case .received:
                statusImage?.image = UIImage(named: ImageConstant.ic_delivered)
                break
            default:
                statusImage?.image = UIImage(named: ImageConstant.ic_hour)
                break
            }
            case false:
            statusImage?.isHidden = true
        }
    }
}
