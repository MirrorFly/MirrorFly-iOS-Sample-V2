//
//  RecentChatTableViewCell.swift
//  MirrorflyUIkit
//
//  Created by User on 14/09/21.
//

import UIKit
import SDWebImage
import MirrorFlySDK

class RecentChatTableViewCell: UITableViewCell {
    @IBOutlet weak var profileImageButton: UIButton?
    @IBOutlet weak var profileImageView: UIImageView?
    @IBOutlet weak var userNameLabel: UILabel?
    @IBOutlet weak var userMessageLabel: UILabel?
    @IBOutlet weak var chatTimeLabel: UILabel?
    @IBOutlet weak var countView: UIView?
    @IBOutlet weak var countLabel: UILabel?
    @IBOutlet weak var statusImage: UIImageView?
    @IBOutlet weak var statusView: UIView?
    @IBOutlet weak var receiverMessageTypeImageView: UIImageView?
    @IBOutlet weak var pinImageView: UIImageView! {
        didSet {
            pinImageView.image = UIImage(named: "pushpin")?.withHorizontallyFlippedOrientation()
        }
    }
    @IBOutlet weak var muteImageView: UIImageView!
    @IBOutlet weak var archivedStatusLabel: UILabel! {
        didSet {
            archivedStatusLabel.isHidden = true
            archivedStatusLabel.cornerRadius(radius: 3, width: 0.3, color: Color.muteSwitchColor)
        }
    }
    @IBOutlet weak var senderNameLabel: UILabel?
    @IBOutlet weak var statusImageCons: NSLayoutConstraint?
    @IBOutlet weak var receiverMessageTypeView: UIView?
    @IBOutlet weak var statusViewTralingCons: NSLayoutConstraint?
    @IBOutlet weak var receivedMessageTrailingCons: NSLayoutConstraint?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupProfileImageUI()
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView?.image = nil
        userMessageLabel?.attributedText = NSMutableAttributedString(string: "", attributes: [:])
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func setupProfileImageUI() {
        profileImageView?.setCircleView()
    }
    
    private func getIsBlockedByMe(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlockedMe ?? false
    }
    
    private func getisBlockedMe(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlockedMe ?? false
    }
    
    func getPlaceholder(name: String , color: UIColor)->UIImage {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let ipimage = IPImage(text: trimmedName, radius: Double(profileImageView?.frame.size.height ?? 0.0), font: UIFont.font32px_appBold(), textColor: nil, color: color)
        let placeholder = ipimage.generateInitialImage()
        return placeholder ?? #imageLiteral(resourceName: "ic_profile_placeholder")
    }
    
    func imageWith(name: String?,color: UIColor) -> UIImage? {
           let frame = CGRect(x: 0, y: 0, width: 50, height: 50)
           let nameLabel = UILabel(frame: frame)
           nameLabel.textAlignment = .center
           nameLabel.backgroundColor = color
           nameLabel.textColor = .white
           nameLabel.font = UIFont.boldSystemFont(ofSize: 20)
           var initials = ""
        if let initialsArray = name?.components(separatedBy: " ") {
               if let firstWord = initialsArray.first {
                   if let firstLetter = firstWord.first {
                       initials += String(firstLetter).capitalized }
               }
               if initialsArray.count > 1, let lastWord = initialsArray.last {
                   if let lastLetter = lastWord.first { initials += String(lastLetter).capitalized
                   }
               }
           } else {
               return nil
           }
           nameLabel.text = initials
           UIGraphicsBeginImageContext(frame.size)
           if let currentContext = UIGraphicsGetCurrentContext() {
               nameLabel.layer.render(in: currentContext)
               let nameImage = UIGraphicsGetImageFromCurrentImageContext()
               return nameImage
           }
           return nil
       }
    
    // MARK: SetTextColor whileSearch
    func setTextColorWhileSearch(searchText: String,recentChat: RecentChat) {
        let name = getUserName(jid: recentChat.jid,name: recentChat.profileName , nickName: recentChat.nickName, contactType: (recentChat.isDeletedUser ? .deleted :  recentChat.isItSavedContact ? .live : .unknown))
        if let range = name.capitalized.range(of: searchText.trim().capitalized, options: [.caseInsensitive, .diacriticInsensitive]) {
            let convertedRange = NSRange(range, in: name.capitalized)
            let attributedString = NSMutableAttributedString(string: name.capitalized)
            attributedString.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.systemBlue], range: convertedRange)
            userNameLabel?.attributedText = attributedString
        } else {
            userNameLabel?.text = name
            userNameLabel?.textColor = Color.userNameTextColor
        }
    }
    
    func setLastContentTextColor(searchText: String,recentChat: RecentChat, caption : String = "", searchMessage: ChatMessage? = nil) {
        let editMesssage = ChatManager.getMessageOfId(messageId: recentChat.lastMessageId)?.editedTextContent ?? emptyString()
        var recentMessage = editMesssage.isEmpty ? recentChat.lastMessageContent.trim() : editMesssage.trim()
        var captionText = caption
        if !recentChat.mentionedUsersIds.isEmpty && searchText.isNotEmpty {
            recentMessage = ChatUtils.convertNormalMentionUser(message: recentMessage, mentionedUsersIds: recentChat.mentionedUsersIds)
        } else if let searchMessage = searchMessage, !searchMessage.mentionedUsersIds.isEmpty {
            recentMessage = ChatUtils.convertNormalMentionUser(message: recentMessage, mentionedUsersIds: searchMessage.mentionedUsersIds)
        }
        
        if let getsearchMessage = searchMessage, !getsearchMessage.mentionedUsersIds.isEmpty {
            captionText = ChatUtils.convertNormalMentionUser(message: caption, mentionedUsersIds: getsearchMessage.mentionedUsersIds)
        } else if let searchMessage = searchMessage, !searchMessage.mentionedUsersIds.isEmpty {
            captionText = ChatUtils.convertNormalMentionUser(message: caption, mentionedUsersIds: searchMessage.mentionedUsersIds)
        }
        
        if let range = recentMessage.capitalized.range(of: searchText.trim().capitalized, options: [.caseInsensitive, .diacriticInsensitive]) {
            let convertedRange = NSRange(range, in: recentMessage.capitalized)
            let attributedString = NSMutableAttributedString(string: recentMessage.capitalized)
            attributedString.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.systemBlue], range: convertedRange)
            userMessageLabel?.attributedText = attributedString
        } else if captionText.isNotEmpty {
            print("captionText===>", captionText)
            if let range = captionText.capitalized.range(of: searchText.trim().capitalized, options: [.caseInsensitive, .diacriticInsensitive]) {
                let convertedRange = NSRange(range, in: captionText.capitalized)
                let attributedString = NSMutableAttributedString(string: captionText.capitalized)
                attributedString.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.systemBlue], range: convertedRange)
                userMessageLabel?.attributedText = attributedString
            }
        } else {
            userMessageLabel?.textColor = Color.userStatusTextColor
            if recentChat.isMentionedUser, recentMessage.isNotEmpty {
                if recentChat.profileType == .groupChat {
                    userMessageLabel?.attributedText = ChatUtils.getMentionTextContent(message: recentMessage, uiLabel: userMessageLabel, isMessageSentByMe: recentChat.isLastMessageSentByMe, mentionedUsers: recentChat.mentionedUsersIds)
                } else {
                    userMessageLabel?.text = ChatUtils.convertMentionUser(message: recentMessage, mentionedUsersIds: recentChat.mentionedUsersIds).replacingOccurrences(of: "`", with: "")
                }
            } else {
                userMessageLabel?.text = recentMessage
            }
        }
    }

    
    // MARK: SetContactInformation
    func setContactInfo(recentChat: RecentChat,color : UIColor) {
        countView?.isHidden = true
        statusImage?.isHidden = true
        receiverMessageTypeView?.isHidden = true
        chatTimeLabel?.isHidden = true
        statusImageCons?.constant = 0
        receivedMessageTrailingCons?.constant = 0
        statusViewTralingCons?.constant = 0
        let profileImage = ((recentChat.profileThumbImage?.isEmpty ?? true) ? recentChat.profileImage : recentChat.profileThumbImage) ?? ""
        let userName = getUserName(jid: recentChat.jid,name: recentChat.profileName, nickName: recentChat.nickName, contactType: recentChat.isItSavedContact ? .live : .unknown)
        if profileImage.isEmpty && recentChat.profileType == .singleChat {
            profileImageView?.image = getPlaceholder(name: userName, color: getColor(userName: userName))
        } else {
            profileImageView?.loadFlyImage(imageURL: profileImage, name: userName,
                                           chatType: recentChat.profileType, jid: recentChat.jid, isBlockedByAdmin: recentChat.isBlockedByAdmin, validateBlock: false)
        }
    }
    
    // MARK: Set ChatTimeColor
    func setChatTimeTextColor(lastMessageTime: Double,unreadCount: Int?) {
        let date = DateFormatterUtility.shared.convertMillisecondsToDateTime(milliSeconds: lastMessageTime)
        let secondsAgo = Int(Date().timeIntervalSince(date))
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let oneDay = 1 * day
        if (secondsAgo < oneDay && (unreadCount ?? 0) > 0) {
            chatTimeLabel?.textColor = Color.recentChaTimeBlueColor
        } else {
            chatTimeLabel?.textColor = Color.recentChatDateTimeColor
        }
    }
    
    func setRecentChatMessage(recentChatMessage: RecentChat,color : UIColor,chatMessage: ChatMessage?,senderName: String, fromArchive: Bool, forSearch : Bool = false) {
        countLabel?.isHidden = false
        receivedMessageTrailingCons?.constant = 5
        statusViewTralingCons?.constant = 5
        statusImageCons?.constant = 7
        senderNameLabel?.textColor = Color.primaryTextColor
        if recentChatMessage.profileType == .groupChat && senderName.isNotEmpty && (!(chatMessage?.isMessageSentByMe ?? false)) && recentChatMessage.lastMessageType != .notification && !forSearch  && !(chatMessage?.isMessageDeleted ?? false) {
            senderNameLabel?.text =  "\(senderName): "
            senderNameLabel?.isHidden = false
        } else {
            senderNameLabel?.isHidden = true
        }
        pinImageView.isHidden = !recentChatMessage.isChatPinned
        muteImageView.isHidden = !recentChatMessage.isMuted
        archivedStatusLabel.isHidden = !recentChatMessage.isChatArchived

//        if fromArchive {
//            muteImageView.isHidden = true
//        }
        let profileImage = ((recentChatMessage.profileThumbImage?.isEmpty ?? true) ? recentChatMessage.profileImage : recentChatMessage.profileThumbImage) ?? ""
        let userName = getUserName(jid: recentChatMessage.jid,name: recentChatMessage.profileName, nickName: recentChatMessage.nickName, contactType: recentChatMessage.isItSavedContact ? .live : .unknown)
        if profileImage.isEmpty && recentChatMessage.profileType == .singleChat {
            profileImageView?.image = getPlaceholder(name: userName, color: getColor(userName: userName))
        } else {
            profileImageView?.loadFlyImage(imageURL: profileImage, name: userName,
                                           chatType: recentChatMessage.profileType, jid: recentChatMessage.jid, isBlockedByAdmin: recentChatMessage.isBlockedByAdmin, validateBlock: false)
        }
        
        if recentChatMessage.isBlockedMe || getisBlockedMe(jid: recentChatMessage.jid) || recentChatMessage.isBlockedByAdmin || (IS_LIVE && ENABLE_CONTACT_SYNC) && recentChatMessage.isItSavedContact == false {
            profileImageView?.backgroundColor =  Color.groupIconBackgroundGray
            let placeHolder = recentChatMessage.isGroup ? UIImage(named: "ic_groupPlaceHolder") :  UIImage(named: "ic_profile_placeholder")
            profileImageView?.sd_setImage(with: nil, placeholderImage: placeHolder ?? UIImage())
        }
        
        let messageTime = recentChatMessage.lastMessageTime
        //chatMessage?.messageChatType == .singleChat ? recentChatMessage.lastMessageTime : DateFormatterUtility.shared.getGroupMilliSeconds(milliSeconds: recentChatMessage.lastMessageTime)
      
        chatTimeLabel?.text = (recentChatMessage.lastMessageId == "" || (chatMessage?.isMessageDeleted ?? false)) ? "" : String().fetchMessageDate(for: messageTime)
        countLabel?.text = recentChatMessage.unreadMessageCount > 99 ? "99+" : String(recentChatMessage.unreadMessageCount)
        chatTimeLabel?.isHidden = false
        countView?.isHidden = (recentChatMessage.unreadMessageCount > 0) ? false : true
        //Update for Chat Read/Unread
        countView?.isHidden = !recentChatMessage.isConversationUnRead
        countLabel?.isHidden = !recentChatMessage.isConversationUnRead || recentChatMessage.unreadMessageCount == 0

        statusImage?.isHidden = (recentChatMessage.isLastMessageSentByMe == true) ? false : true
        statusView?.isHidden = (recentChatMessage.isLastMessageSentByMe == true) ? false : true
        receiverMessageTypeView?.isHidden = false
        contentView.backgroundColor = recentChatMessage.isSelected == true ? Color.recentChatSelectionColor : .clear
        
            switch recentChatMessage.lastMessageType {
            case .text:
                receiverMessageTypeView?.isHidden = true
            case .contact:
                receiverMessageTypeImageView?.image = UIImage(named: ImageConstant.ic_rccontact)
            case .image:
                receiverMessageTypeImageView?.image = UIImage(named: ImageConstant.ic_rcimage)
            case .location:
                receiverMessageTypeImageView?.image = UIImage(named: ImageConstant.ic_rclocation)
            case .audio:
                if chatMessage?.mediaChatMessage?.audioType == AudioType.recording {
                    ChatUtils.setIconForAudio(imageView: receiverMessageTypeImageView, chatMessage: chatMessage)
                } else {
                    receiverMessageTypeImageView?.image = UIImage(named: ImageConstant.ic_rcaudio)
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
        if recentChatMessage.lastMessageType != .notification {
            switch recentChatMessage.isLastMessageSentByMe {
            case true:
                // show hide sent and received msg status
                switch recentChatMessage.lastMessageStatus {
                case .notAcknowledged:
                    statusImage?.image = UIImage(named: ImageConstant.ic_hour)
                    break
                case .sent:
                    switch recentChatMessage.lastMessageType {
                    case .video, .audio, .image,.text,.contact, .document:
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
        } else {
            statusView?.isHidden = true
        }
        
        
        // show send messageType
        switch recentChatMessage.lastMessageType {
        case .text:
            if recentChatMessage.lastMessageContent.isEmpty == true {
                statusImage?.isHidden = true
            }
            break
        case .video, .image,.audio,.contact,.location:
            let mentionedUsersIds = chatMessage?.mentionedUsersIds ?? []
            if let mediaMessage = chatMessage?.mediaChatMessage {
                let captionText = mediaMessage.mediaCaptionEditedText.isEmpty ? mediaMessage.mediaCaptionText : mediaMessage.mediaCaptionEditedText
                if !mentionedUsersIds.isEmpty, captionText.trim().isNotEmpty {
                    let isMessageSentByMe = chatMessage?.isMessageSentByMe ?? false
                    if recentChatMessage.profileType == .groupChat {
                        userMessageLabel?.attributedText = ChatUtils.getMentionTextContent(message: captionText, uiLabel: userMessageLabel, isMessageSentByMe: isMessageSentByMe, mentionedUsers: mentionedUsersIds)
                    } else {
                        userMessageLabel?.text = ChatUtils.convertMentionUser(message: captionText, mentionedUsersIds: mentionedUsersIds).replacingOccurrences(of: "`", with: "")
                    }
                } else {
                    userMessageLabel?.text = (captionText.trim().isNotEmpty) ? captionText : recentChatMessage.lastMessageType?.rawValue.capitalized
                }
            }
           // userMessageLabel?.text = (chatMessage?.mediaChatMessage?.mediaCaptionText.trim().isNotEmpty ?? false) ? chatMessage?.mediaChatMessage?.mediaCaptionText : recentChatMessage.lastMessageType?.rawValue.capitalized
        case .document:
            userMessageLabel?.text = "Document"
        case .meet:
            let mentionedUsersIds = chatMessage?.mentionedUsersIds ?? []
            if !mentionedUsersIds.isEmpty, (chatMessage?.meetChatMessage?.scheduledDateTime != 0) {
                let message = DateFormatterUtility.shared.getSchduleMeetingDate(date: chatMessage?.meetChatMessage?.scheduledDateTime ?? 0)
                let isMessageSentByMe = chatMessage?.isMessageSentByMe ?? false
                if recentChatMessage.profileType == .groupChat {
                    userMessageLabel?.attributedText = ChatUtils.getMentionTextContent(message: message, uiLabel: userMessageLabel, isMessageSentByMe: isMessageSentByMe, mentionedUsers: mentionedUsersIds)
                } else {
                    userMessageLabel?.text = ChatUtils.convertMentionUser(message: message, mentionedUsersIds: mentionedUsersIds).replacingOccurrences(of: "`", with: "")
                }
            } else {
                userMessageLabel?.text = "Scheduled on " + (((chatMessage?.meetChatMessage?.scheduledDateTime != 0) ? DateFormatterUtility.shared.getSchduleMeetingDate(date: chatMessage?.meetChatMessage?.scheduledDateTime ?? 0) : recentChatMessage.lastMessageType?.rawValue.capitalized) ?? "")
            }
        default:
            break
        }
        if recentChatMessage.isLastMessageRecalledByUser {
            userMessageLabel?.text = recentChatMessage.isLastMessageSentByMe ? senderDeletedMessage : receiverDeletedMessage
            statusView?.isHidden = true
            receiverMessageTypeView?.isHidden = true
            if recentChatMessage.profileType == .groupChat && !recentChatMessage.isLastMessageSentByMe {
                senderNameLabel?.isHidden = false
            } else {
                senderNameLabel?.isHidden = true
            }
        }
    }
}
