//
//  ChatViewParentMessageCell.swift
//  MirrorflyUIkit
//
//  Created by User on 23/08/21.
//

import UIKit
import MapKit
import GoogleMaps
import Alamofire
import SDWebImage
import MirrorFlySDK

protocol RefreshBubbleImageViewDelegate: class {
    func refreshBubbleImageView(indexPath: IndexPath,isSelected: Bool,title: String?)
}

protocol LinkDelegate: class {
    func pushToJoinCallView(callLink: String)
    func showAlreadyInCallAlert(callLink: String)
}


protocol GestureDelegate: class {
    func replyGesture(_ sender: UITapGestureRecognizer?)
    func translateGesture(_ sender: UITapGestureRecognizer?)
    func locationGesture(_ sender: UITapGestureRecognizer)
    func contactSaveGesture(_ sender: UITapGestureRecognizer)
}

class ChatViewParentMessageCell: BaseTableViewCell {
    
    //Outgoing And Incoming cell -  Basic view and its elements
    @IBOutlet weak var baseView: UIView?
    @IBOutlet weak var bubbleBGView: UIView?
    
    @IBOutlet weak var replyUserLabelWidthCons: NSLayoutConstraint?
    @IBOutlet weak var locationOutgoingView: UIView!
    @IBOutlet weak var favouriteIcon: UIImageView?
    @IBOutlet weak var baseViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var groupMsgNameView: UIView?
    @IBOutlet weak var groupMsgSenderName: GroupReceivedMessageHeader?
    // Text message view and its elements
    @IBOutlet weak var messageLabel: UILabel?
    
    //General -> Favourite,time and status
    @IBOutlet weak var favouriteImageView: UIImageView?
    @IBOutlet weak var textMessageTimeLabel: UILabel?
    @IBOutlet weak var messageStatusImageView: UIImageView?
    @IBOutlet weak var senderProfileImage: UIImageView?
    @IBOutlet weak var senderTimeLabel: UILabel?
    @IBOutlet weak var senderStackView: UIStackView?
    @IBOutlet weak var starredMessageView: UIView?
    @IBOutlet weak var bubbleImageBottomCons: NSLayoutConstraint?
    @IBOutlet weak var bubbleImageTopCons: NSLayoutConstraint?
    @IBOutlet weak var sendFromLabel: UILabel?
    @IBOutlet weak var senderToLabel: UILabel?
    @IBOutlet weak var senderImageView: UIImageView?
    @IBOutlet weak var chatLocationMapView: UIView?
    @IBOutlet weak var mediaLocationMapView: UIView?
    
    // Location message view and its elements
    @IBOutlet weak var locationImageView: UIImageView?
    
    // Contact message view and its elements
    @IBOutlet weak var contactName: UILabel?
    @IBOutlet weak var saveContactButton: UIButton?
    
    // Reply view and its elements
    @IBOutlet weak var replyView: UIView?
    @IBOutlet weak var replyUserLabel: UILabel?
    @IBOutlet weak var replyTextLabel: UILabel?
    @IBOutlet weak var mediaImageView: UIImageView?
    @IBOutlet weak var messageTypeIcon: UIImageView?
    @IBOutlet weak var messageIconView: UIView?
    @IBOutlet weak var replyMessageIconWidthCons: NSLayoutConstraint?
    @IBOutlet weak var replyMessageIconHeightCons: NSLayoutConstraint?
    @IBOutlet weak var mediaImageViewWidthCons: NSLayoutConstraint?
    @IBOutlet weak var replyTextWithImageTrailingCons: NSLayoutConstraint?
    @IBOutlet weak var replyTextLabelTrailingCons: NSLayoutConstraint?
    @IBOutlet weak var replyViewHeightCons: NSLayoutConstraint?
    @IBOutlet weak var replyVIewWithMediaCons: NSLayoutConstraint?
    @IBOutlet weak var replyViewWithoutMediaCons: NSLayoutConstraint?
    
    //MARK -  Incoming cell
    @IBOutlet weak var seperatorLine: UIView?
    @IBOutlet weak var senderNameLabel: UILabel?
    @IBOutlet weak var replyTitleLabel: UILabel?
    @IBOutlet weak var translatedTextLabel: UILabel?
    @IBOutlet weak var stackViewTranslate: UIStackView?
    //@IBOutlet weak var stackViewTimeStamp: UIStackView?
    @IBOutlet weak var stackViewTimeStampTopCons: NSLayoutConstraint?
    @IBOutlet weak var translatedView: UIView?
    @IBOutlet weak var stackViewTranslateTrailingCons: NSLayoutConstraint?
    
    //MARK: Forward
    @IBOutlet weak var forwardImageView: UIImageView?
    @IBOutlet weak var forwardView: UIView?
    @IBOutlet weak var forwardLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var bubbleImageLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var forwardButton: UIButton?
    @IBOutlet weak var quickForwardButton: UIButton?
    @IBOutlet weak var quickForwardView: UIView?
    
    
    @IBOutlet weak var linkView: UIView?
    @IBOutlet weak var receiverLinkView: UIView?

    //Scheduled meeting
    @IBOutlet weak var scheduledMeetingTimeLabel: UILabel?

    weak var refreshDelegate: RefreshBubbleImageViewDelegate? = nil
    var selectedForwardMessage: [SelectedMessages]? = []
    var isDeleteSelected: Bool = false
    var isStarredMessagePage: Bool = false
    var searchText: String?
    
    weak var linkDelegate: LinkDelegate? = nil
    weak var gestureDelegate: GestureDelegate? = nil

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        textMessageTimeLabel?.font = UIFont.font9px_appLight()
        starredMessageView?.roundCorners(corners: [.topLeft, .bottomLeft, .topRight], radius: 5.0)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
        // Configure the view for the selected state
    }
    
    func showHideStarredMessageView() {
        starredMessageView?.isHidden = isStarredMessagePage == true ? false : true
        baseViewTopConstraint?.isActive = isStarredMessagePage == true ? false : true
        bubbleImageTopCons?.isActive = isStarredMessagePage == true ? false : true
        senderStackView?.isHidden = isStarredMessagePage == true ? false : true
        bubbleImageBottomCons?.constant = isStarredMessagePage == true ? 10 : 3
    }
    
    func hideGroupMsgNameView() {
        groupMsgNameView?.isHidden = true
        groupMsgSenderName?.text = ""
    }

    func setupReplyGesture() {
        //Reply tap gesture
        let  textReplyTap = UITapGestureRecognizer(target: self, action: #selector(self.replyViewTapGesture(_:)))
        replyView?.addGestureRecognizer(textReplyTap)
        textReplyTap.delegate = self
    }

    func setupTranslateGesture() {
        //Translate tap gesture
        if CommonDefaults.isTranlationEnabled {
            let  tap = UITapGestureRecognizer(target: self, action: #selector(self.translationLanguage(_:)))
            tap.numberOfTapsRequired = 2
            self.addGestureRecognizer(tap)
        }
    }

    func setupLocationGesture() {
        //Location tap gesture
        let senderGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onLocationMessage(sender:)))
        locationOutgoingView?.isUserInteractionEnabled = true
        locationOutgoingView?.addGestureRecognizer(senderGestureRecognizer)
        let receiverGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onLocationMessage(sender:)))
        locationImageView?.isUserInteractionEnabled = true
        locationImageView?.addGestureRecognizer(receiverGestureRecognizer)
    }

    func setupContactGesture() {
        //Contact save gesture
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onsaveContact(sender:)))
        saveContactButton?.addGestureRecognizer(gestureRecognizer)
    }

    @objc func replyViewTapGesture(_ sender: UITapGestureRecognizer? = nil) {
        gestureDelegate?.replyGesture(sender)
    }

    @objc func translationLanguage(_ sender: UITapGestureRecognizer? = nil) {
        gestureDelegate?.translateGesture(sender)
    }

    @objc func onLocationMessage(sender: UITapGestureRecognizer) {
        gestureDelegate?.locationGesture(sender)
    }

    @objc func onsaveContact(sender: UITapGestureRecognizer) {
        gestureDelegate?.contactSaveGesture(sender)
    }

    func setUserProfileInfo(message: ChatMessage?,isBlocked: Bool) {
        let getProfileDetails = ChatManager.profileDetaisFor(jid: message?.chatUserJid ?? "")
        let senderProfileDetails = ChatManager.profileDetaisFor(jid: message?.senderUserJid ?? "")
        if !(message?.isMessageSentByMe ?? false) {
            senderToLabel?.text = message?.messageChatType == .singleChat ? "You" : getUserName(jid : getProfileDetails?.jid ?? "" ,name: getProfileDetails?.name ?? "", nickName: getProfileDetails?.nickName ?? "", contactType: getProfileDetails?.contactType ?? .local)
            sendFromLabel?.text = getUserName(jid : senderProfileDetails?.jid ?? "" ,name: senderProfileDetails?.name ?? "", nickName: senderProfileDetails?.nickName ?? "", contactType: senderProfileDetails?.contactType ?? .local)
            senderImageView?.image = UIImage(named: "Receiver")
        } else {
            sendFromLabel?.text = message?.isMessageSentByMe == true ? "You" : message?.senderUserName
            senderToLabel?.text = getUserName(jid : getProfileDetails?.jid ?? "" ,name: getProfileDetails?.name ?? "", nickName: getProfileDetails?.nickName ?? "", contactType: getProfileDetails?.contactType ?? .local)
            senderImageView?.image = UIImage(named: "Sender")
        }
        let timeStamp =  message?.messageSentTime
        senderTimeLabel?.text = String(describing: DateFormatterUtility.shared.convertMillisecondsToSentTime(milliSeconds: timeStamp ?? 0.0))
        senderProfileImage?.makeRounded()
        let contactColor = getColor(userName: getUserName(jid: senderProfileDetails?.jid ?? "",name: senderProfileDetails?.name ?? "", nickName: senderProfileDetails?.nickName ?? "", contactType: senderProfileDetails?.contactType ?? .local))
        let profileImage = (senderProfileDetails?.thumbImage.isEmpty ?? true) ? senderProfileDetails?.image : senderProfileDetails?.thumbImage
        setImage(imageURL: profileImage ?? "", name: getUserName(jid: senderProfileDetails?.jid ?? "", name: senderProfileDetails?.name ?? "", nickName: senderProfileDetails?.nickName ?? "", contactType: senderProfileDetails?.contactType ?? .local), color: contactColor, chatType: senderProfileDetails?.profileChatType ?? .singleChat, jid: senderProfileDetails?.jid ?? "")
    }
    
    private func getisBlockedMe(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlockedMe ?? false
    }
    
    func setImage(imageURL: String, name: String, color: UIColor, chatType : ChatType,jid: String) {
        if !getisBlockedMe(jid: jid) || !(IS_LIVE && ENABLE_CONTACT_SYNC && ContactManager.shared.getUserProfileDetails(for: jid)?.isItSavedContact == false) {
            senderProfileImage?.loadFlyImage(imageURL: imageURL, name: name, chatType: chatType, jid: jid)
        } else if chatType == .groupChat {
            senderProfileImage?.image = UIImage(named: ImageConstant.ic_group_small_placeholder)!
        }
    }
    
    func getCellFor(_ message: ChatMessage?, at indexPath: IndexPath?,isShowForwardView: Bool?, fromChat: Bool = false, isMessageSearch: Bool = false, searchText: String = "", profileDetails: ProfileDetails) -> ChatViewParentMessageCell? {
        if let replyMessage = message?.isReplyMessage {
            replyView?.isHidden = !replyMessage
        } else {
            replyView?.isHidden = true
        }
        currentIndexPath = nil
        currentIndexPath = indexPath
        replyViewHeightCons?.isActive = true
        replyTextLabel?.text = ""
        replyUserLabel?.text = ""
        translatedTextLabel?.text = ""
        
        linkView?.isHidden = true
        receiverLinkView?.isHidden = true

        // Forward view elements and its data
        bubbleImageLeadingCons?.constant = (isShowForwardView == true) ? 10 : 0
        stackViewTimeStampTopCons?.constant = CommonDefaults.isTranlationEnabled && message?.isMessageTranslated ?? false ? 5 : -2
       // stackViewTimeStampTopCons?.constant = message!.isMessageTranslated ? 5 : 0
        stackViewTranslateTrailingCons?.constant = CommonDefaults.isTranlationEnabled && message!.isMessageTranslated ? 0 : 20
        
        if selectedForwardMessage?.filter({$0.chatMessage.messageId == message?.messageId}).first?.isSelected == true {
            forwardImageView?.image = UIImage(named: "forwardSelected")
            forwardImageView?.isHidden = false
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 0.0)
        } else {
           // forwardImageView?.image = UIImage(named: "")
            forwardImageView?.isHidden = true
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
        }
        
        if (message?.messageStatus == .notAcknowledged || message?.messageStatus == .sent || isShowForwardView == true || isStarredMessagePage == true) {
            quickForwardView?.isHidden = true
            quickForwardButton?.isHidden = true
            isAllowSwipe = false
        } else {
            quickForwardView?.isHidden = false
            quickForwardButton?.isHidden = false
            isAllowSwipe = true
        }
        
        if !(isShowForwardView ?? false) || (isDeleteSelected == false && message?.isMessageRecalled == true) {
            forwardView?.isHidden = true
            forwardButton?.isHidden = true
            forwardLeadingCons?.constant = 0
        } else {
            forwardView?.isHidden = false
            forwardButton?.isHidden = false
            forwardLeadingCons?.constant = 20
        }
        
        // Favorite message icon
        if(message!.isMessageStarred) {
            favouriteIcon?.isHidden = false
            favouriteImageView?.isHidden = false
        }
        else {
            favouriteIcon?.isHidden = true
            favouriteImageView?.isHidden = true
        }
        mediaLocationMapView?.isHidden = true
        
        
        // Reply view elements and its data
       let isReplyMessage = message?.isReplyMessage ?? false
        if isReplyMessage, let replyParentChatMessage = message?.replyParentChatMessage {
           replyTextLabelTrailingCons?.constant = 10
          // let replyMessage = FlyMessenger.getMessageOfId(messageId: message?.replyParentChatMessage?.messageId ?? "")
           if message?.replyParentChatMessage?.isMessageRecalled == true || message?.replyParentChatMessage?.isMessageDeleted == true  {
               replyTextLabel?.text = "Original message not available"
               mediaImageView?.isHidden = true
               messageIconView?.isHidden = true
               mediaImageViewWidthCons?.constant = 0
               replyMessageIconWidthCons?.constant = 0
               replyMessageIconHeightCons?.isActive = false
               replyTextWithImageTrailingCons?.isActive = false
               replyTextLabelTrailingCons?.isActive = true
               replyVIewWithMediaCons?.isActive = false
               replyViewWithoutMediaCons?.isActive = true
           } else {
               let getReplymessage =  message?.replyParentChatMessage?.messageTextContent
//           replyViewHeightCons?.isActive = (getReplymessage?.count ?? 0 > 20) ? false : true
               if (profileDetails.profileChatType == .groupChat || isStarredMessagePage), !replyParentChatMessage.mentionedUsersIds.isEmpty {
                   replyTextLabel?.attributedText = ChatUtils.getMentionTextContent(message: replyParentChatMessage.messageTextContent, isMessageSentByMe: replyParentChatMessage.isMessageSentByMe, mentionedUsers: replyParentChatMessage.mentionedUsersIds, searchedText: searchText)
               } else {
                   replyTextLabel?.attributedText = ChatUtils.getAttributedMessage(message: getReplymessage ?? "", searchText: searchText, isMessageSearch: isMessageSearch,isSystemBlue: false)
               }
           //replyTextLabel?.text = ChatUtils.getMentionTextContent(message: getReplymessage ?? "", uiLabel: replyTextLabel, isMessageSentByMe: replyMessage?.isMessageSentByMe ?? false, mentionedUsers: replyMessage?.mentionedUsersIds ?? []).string
               if replyParentChatMessage.mediaChatMessage != nil {
               mediaImageViewWidthCons?.constant = 50
               replyMessageIconWidthCons?.constant = 12
               replyMessageIconHeightCons?.isActive = true
               replyTextWithImageTrailingCons?.isActive = true
               replyTextLabelTrailingCons?.isActive = false
                   switch replyParentChatMessage.mediaChatMessage?.messageType {
               case .image:
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderCamera" : "receiverCamera")
                       if let localPath = replyParentChatMessage.mediaChatMessage?.mediaFileName {
                       if let directoryURL: URL = FlyUtils.getGroupContainerIDPath() {
                           let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Image", isDirectory: true)
                           let fileURL: URL = folderPath.appendingPathComponent(localPath)
                           if FileManager.default.fileExists(atPath:fileURL.relativePath) && (replyParentChatMessage.mediaChatMessage?.mediaDownloadStatus == .downloaded || replyParentChatMessage.mediaChatMessage?.mediaUploadStatus == .uploaded) {
                               let data = NSData(contentsOf: fileURL)
                               let image = UIImage(data: data! as Data)
                               mediaImageView?.image = image
                               mediaImageView?.isHidden = false
                               messageIconView?.isHidden = false
                               //replyTextLabel?.text = !(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false) ? replyMessage?.mediaChatMessage?.mediaCaptionText : "Photo"
                               let message = replyParentChatMessage.mediaChatMessage?.mediaCaptionText
                               if message?.isEmpty ?? false {
                                   replyTextLabel?.text = replyParentChatMessage.mediaChatMessage?.messageType.rawValue.capitalized
                               } else {
                                   if profileDetails.profileChatType == .groupChat {
                                       replyTextLabel?.text = ChatUtils.getMentionTextContent(message: message ?? "", uiLabel: replyTextLabel, isMessageSentByMe: replyParentChatMessage.isMessageSentByMe ?? false, mentionedUsers: replyParentChatMessage.mentionedUsersIds ?? []).string
                                   } else {
                                       replyTextLabel?.text = ChatUtils.convertMentionUser(message: message ?? "", mentionedUsersIds: replyParentChatMessage.mentionedUsersIds ?? []).replacingOccurrences(of: "`", with: "")
                                   }
                               }
                           }else {
                               if let thumImage = replyParentChatMessage.mediaChatMessage?.mediaThumbImage {
                                   let converter = ImageConverter()
                                   let image =  converter.base64ToImage(thumImage)
                                   mediaImageView?.image = image
                                   mediaImageView?.isHidden = false
                                   messageIconView?.isHidden = false
                                  // replyTextLabel?.text = !(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false) ? replyMessage?.mediaChatMessage?.mediaCaptionText : "Photo"
                                   let message = replyParentChatMessage.mediaChatMessage?.mediaCaptionText
                                   if message?.isEmpty ?? false {
                                       replyTextLabel?.text = replyParentChatMessage.mediaChatMessage?.messageType.rawValue.capitalized
                                   } else {
                                       if profileDetails.profileChatType == .groupChat {
                                           replyTextLabel?.text = ChatUtils.getMentionTextContent(message: message ?? "", uiLabel: replyTextLabel, isMessageSentByMe: replyParentChatMessage.isMessageSentByMe , mentionedUsers: replyParentChatMessage.mentionedUsersIds ).string
                                       } else {
                                           replyTextLabel?.text = ChatUtils.convertMentionUser(message: message ?? "", mentionedUsersIds: replyParentChatMessage.mentionedUsersIds ).replacingOccurrences(of: "`", with: "").replacingOccurrences(of: "`", with: "")
                                       }
                                   }
                               }
                           }
                       }
                   } else {
                       if let thumImage = replyParentChatMessage.mediaChatMessage?.mediaThumbImage {
                           let converter = ImageConverter()
                           let image =  converter.base64ToImage(thumImage)
                           mediaImageView?.image = image
                           mediaImageView?.isHidden = false
                           messageIconView?.isHidden = false
                           //replyTextLabel?.text = !(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false) ? replyMessage?.mediaChatMessage?.mediaCaptionText : "Photo"
                           let message = replyParentChatMessage.mediaChatMessage?.mediaCaptionText
                           if message?.isEmpty ?? false {
                               replyTextLabel?.text = replyParentChatMessage.mediaChatMessage?.messageType.rawValue.capitalized
                           } else {
                               if profileDetails.profileChatType == .groupChat {
                                   replyTextLabel?.text = ChatUtils.getMentionTextContent(message: message ?? "", uiLabel: replyTextLabel, isMessageSentByMe: replyParentChatMessage.isMessageSentByMe , mentionedUsers: replyParentChatMessage.mentionedUsersIds ).string
                               } else {
                                   replyTextLabel?.text = ChatUtils.convertMentionUser(message: message ?? "", mentionedUsersIds: replyParentChatMessage.mentionedUsersIds ).replacingOccurrences(of: "`", with: "").replacingOccurrences(of: "`", with: "")
                               }
                           }
                       }
                   }
                   replyVIewWithMediaCons?.isActive = true
                   replyViewWithoutMediaCons?.isActive = false
               case .audio:
                   mediaImageView?.isHidden = true
                   messageIconView?.isHidden = false
                   ChatUtils.setIconForAudio(imageView: messageTypeIcon, chatMessage: nil, replyParentMessage: message?.replyParentChatMessage)
                   let duration = Int(replyParentChatMessage.mediaChatMessage?.mediaDuration ?? 0)
                   let message = replyParentChatMessage.mediaChatMessage?.mediaCaptionText
                   if message?.isEmpty ?? false {
                       replyTextLabel?.text = replyParentChatMessage.mediaChatMessage?.messageType.rawValue.capitalized.appending(" (\(duration.msToSeconds.minuteSecondMS))")
                   } else {
                       if profileDetails.profileChatType == .groupChat {
                           replyTextLabel?.text = ChatUtils.getMentionTextContent(message: message ?? "", uiLabel: replyTextLabel, isMessageSentByMe: replyParentChatMessage.isMessageSentByMe , mentionedUsers: replyParentChatMessage.mentionedUsersIds ).string
                       } else {
                           replyTextLabel?.text = ChatUtils.convertMentionUser(message: message ?? "", mentionedUsersIds: replyParentChatMessage.mentionedUsersIds ).replacingOccurrences(of: "`", with: "")
                       }
                   }
//                   replyTextLabel?.text = !(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized.appending(" (\(duration.msToSeconds.minuteSecondMS))")
                   replyVIewWithMediaCons?.isActive = false
                   replyViewWithoutMediaCons?.isActive = true
               case .video:
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderVideo" : "video")
                   if let thumImage = replyParentChatMessage.mediaChatMessage?.mediaThumbImage {
                       let converter = ImageConverter()
                       let image =  converter.base64ToImage(thumImage)
                       mediaImageView?.image = image
                       mediaImageView?.isHidden = false
                       messageIconView?.isHidden = false
                      // replyTextLabel?.text = !(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized
                       let message = replyParentChatMessage.mediaChatMessage?.mediaCaptionText
                       if message?.isEmpty ?? false {
                           replyTextLabel?.text = replyParentChatMessage.mediaChatMessage?.messageType.rawValue.capitalized
                       } else {
                           if profileDetails.profileChatType == .groupChat {
                               replyTextLabel?.text = ChatUtils.getMentionTextContent(message: message ?? "", uiLabel: replyTextLabel, isMessageSentByMe: replyParentChatMessage.isMessageSentByMe , mentionedUsers: replyParentChatMessage.mentionedUsersIds ).string
                           } else {
                               replyTextLabel?.text = ChatUtils.convertMentionUser(message: message ?? "", mentionedUsersIds: replyParentChatMessage.mentionedUsersIds ).replacingOccurrences(of: "`", with: "")
                           }
                       }
                   }
                   replyVIewWithMediaCons?.isActive = true
                   replyViewWithoutMediaCons?.isActive = false
                   
                   //// - Need to check thumbnail image
               case .document:
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "document" : "document")
                   checkFileType(url: replyParentChatMessage.mediaChatMessage?.mediaFileUrl ?? "", typeImageView: mediaImageView)
                   mediaImageView?.contentMode = .scaleAspectFill
                   mediaImageView?.isHidden = false
                   messageIconView?.isHidden = false
                   replyTextLabel?.text = replyParentChatMessage.mediaChatMessage?.mediaFileName.capitalized
                   replyVIewWithMediaCons?.isActive = true
                   replyViewWithoutMediaCons?.isActive = false
               default:
                   messageIconView?.isHidden = true
                   mediaImageViewWidthCons?.constant = 0
                   replyMessageIconWidthCons?.constant = 0
                   replyMessageIconHeightCons?.isActive = false
                   mediaImageView?.isHidden = true
                   replyTextWithImageTrailingCons?.isActive = false
                   replyTextLabelTrailingCons?.isActive = true
                   replyVIewWithMediaCons?.isActive = false
                   replyViewWithoutMediaCons?.isActive = true
               }
           } else if replyParentChatMessage.locationChatMessage != nil {
               mediaImageView?.isHidden = true
               mediaLocationMapView?.isHidden = false
               replyTextLabel?.text = "Location"
               guard let latitude = replyParentChatMessage.locationChatMessage?.latitude else {
                   return nil
               }
               guard let longitude = replyParentChatMessage.locationChatMessage?.longitude  else {
                   return nil
               }
               
               
               AppUtils.shared.fetchStaticMapImage(latitude: latitude, longitude: longitude, zoomLevel: "16", size: CGSize(width: 52, height: 52)) { [self] mapImage in
                   let mapImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 52, height: 52))
                   mapImageView.image = mapImage
                   mediaLocationMapView?.addSubview(mapImageView)
               }
//               mediaLocationMapView?.camera = GMSCameraPosition.camera(withLatitude: replyMessage?.locationChatMessage?.latitude ?? 0.0, longitude: replyMessage?.locationChatMessage?.longitude ?? 0.0, zoom: 16.0, bearing: 360.0, viewingAngle: 15.0)
//               mediaLocationMapView?.isUserInteractionEnabled = false
//               DispatchQueue.main.async
//               { [self] in
//                   // 2. Perform UI Operations.
//                   let position = CLLocationCoordinate2DMake(replyMessage?.locationChatMessage?.latitude ?? 0.0,replyMessage?.locationChatMessage?.longitude ?? 0.0)
//                   let marker = GMSMarker(position: position)
//                   marker.map = mediaLocationMapView
//               }
               replyVIewWithMediaCons?.isActive = true
               replyViewWithoutMediaCons?.isActive = false
               messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "map" : "receivedMap")
               messageIconView?.isHidden = false
               mediaImageViewWidthCons?.constant = 50
               replyMessageIconWidthCons?.constant = 12
               replyMessageIconHeightCons?.isActive = true
               replyTextWithImageTrailingCons?.isActive = true
               replyTextLabelTrailingCons?.isActive = false
           } else if replyParentChatMessage.contactChatMessage != nil {
               mediaImageView?.isHidden = true
               replyTextLabel?.attributedText = ChatUtils.setAttributeString(name: replyParentChatMessage.contactChatMessage?.contactName)
               messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderContact" : "receiverContact")
               messageIconView?.isHidden = false
               mediaImageViewWidthCons?.constant = 0
               replyMessageIconWidthCons?.constant = 12
               replyMessageIconHeightCons?.isActive = true
               replyTextWithImageTrailingCons?.isActive = false
               replyTextLabelTrailingCons?.isActive = true
               replyVIewWithMediaCons?.isActive = false
               replyViewWithoutMediaCons?.isActive = true
           }else if replyParentChatMessage.meetChatMessage != nil {
               replyTextLabel?.text = DateFormatterUtility.shared.getSchduleMeetingDate(date: replyParentChatMessage.meetChatMessage?.scheduledDateTime ?? 0)
               messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "video_link" : "video_link")
               mediaImageView?.contentMode = .center
               mediaImageView?.isHidden = false
               mediaImageView?.image = UIImage(named: "app_icon")
               mediaImageViewWidthCons?.constant = 50
               messageIconView?.isHidden = false
               replyMessageIconWidthCons?.constant = 12
               replyMessageIconHeightCons?.isActive = true
               replyTextWithImageTrailingCons?.isActive = false
               replyTextLabelTrailingCons?.isActive = true
               replyTextLabelTrailingCons?.constant = 50
               replyVIewWithMediaCons?.isActive = false
               replyViewWithoutMediaCons?.isActive = true
           } else {
               mediaImageView?.isHidden = true
               messageIconView?.isHidden = true
               mediaImageViewWidthCons?.constant = 0
               replyMessageIconWidthCons?.constant = 0
               replyMessageIconHeightCons?.isActive = false
               replyTextWithImageTrailingCons?.isActive = false
               replyTextLabelTrailingCons?.isActive = true              
               replyVIewWithMediaCons?.isActive = false
               replyViewWithoutMediaCons?.isActive = true
           }
       }
            if(replyParentChatMessage.isMessageSentByMe) {
            replyUserLabel?.text = you.localized
        }
        else {
            let name = getUserName(jid: replyParentChatMessage.chatUserJid , name: replyParentChatMessage.senderUserName , nickName: replyParentChatMessage.senderNickName , contactType: (replyParentChatMessage.isDeletedUser ?? false) ? .deleted : (message?.isSavedContact ?? false) ? .live : .unknown)
            replyUserLabel?.text = name
        }
            if replyParentChatMessage.isMessageDeleted || replyParentChatMessage.isMessageRecalled == true {
                setMessageNotAvailableLabel()
            }
//        ChatUtils.setDeletedReplyMessage(chatMessage: replyMessage, messageIconView: messageIconView, messageTypeIcon: messageTypeIcon, replyTextLabel: replyTextLabel, mediaImageView: mediaImageView, mediaImageViewWidthCons: mediaImageViewWidthCons, replyMessageIconWidthCons: replyMessageIconWidthCons, replyMessageIconHeightCons: replyMessageIconHeightCons)
    }
        else {
            mediaImageViewWidthCons?.constant = 0
            replyMessageIconWidthCons?.constant = 0
            replyMessageIconHeightCons?.isActive = false
            replyTextWithImageTrailingCons?.isActive = false
            replyTextLabelTrailingCons?.isActive = true
            if isReplyMessage {
                setMessageNotAvailableLabel()
            }
        }
        
        //Bubble View
        if (message!.isMessageSentByMe) {
            ChatUtils.setSenderBubbleBackground(imageView: bubbleBGView)
        }
        else {
            ChatUtils.setReceiverBubbleBackground(imageView: bubbleBGView)
            if message?.messageChatType == .groupChat {
                if let nameLabel = groupMsgSenderName {
                    nameLabel.text = ChatUtils.getGroupSenderName(messsage: message)
                }
            } else {
                groupMsgNameView?.isHidden = true
                groupMsgSenderName?.isHidden = true
            }
        }
        
        // Message acknowledgement status
            messageStatusImageView?.isAccessibilityElement = true
        if(message!.isMessageSentByMe) {
            messageStatusImageView?.isHidden = false
            switch message?.messageStatus {
            case .sent:
                messageStatusImageView?.image = UIImage.init(named: ImageConstant.ic_hour)
                messageStatusImageView?.accessibilityLabel = sent.localized
                break
            case .acknowledged:
                messageStatusImageView?.image = UIImage.init(named: ImageConstant.ic_sent)
                messageStatusImageView?.accessibilityLabel = acknowledged.localized
                break
            case .delivered:
                messageStatusImageView?.image = UIImage.init(named: ImageConstant.ic_delivered)
                messageStatusImageView?.accessibilityLabel = delivered.localized
                break
            case .seen:
                messageStatusImageView?.image = UIImage.init(named: ImageConstant.ic_seen)
                messageStatusImageView?.accessibilityLabel = seen.localized
                break
            case .received:
                messageStatusImageView?.image = UIImage.init(named: ImageConstant.ic_delivered)
                messageStatusImageView?.accessibilityLabel = delivered.localized
                break
            default:
                messageStatusImageView?.image = UIImage.init(named: ImageConstant.ic_hour)
                messageStatusImageView?.accessibilityLabel = notAcknowledged.localized
                break
            }
        }
        else {
            messageStatusImageView?.isHidden = true
         //   self.seperatorLine.isHidden = true
        }
        // Message time
        guard let timeStamp =  message?.messageSentTime else {
            return self
        }
        textMessageTimeLabel?.isAccessibilityElement =  true
        textMessageTimeLabel?.accessibilityLabel = Utility.currentMillisecondsToTime(milliSec: timeStamp)
        textMessageTimeLabel?.accessibilityLabel = DateFormatterUtility.shared.currentMillisecondsToLocalTime(milliSec: timeStamp)
       // textMessageTimeLabel?.text = DateFormatterUtility.shared.currentMillisecondsToLocalTime(milliSec: timeStamp)
        if (message?.isMessageEdited ?? false) {
            textMessageTimeLabel?.text = "Edited \(DateFormatterUtility.shared.currentMillisecondsToLocalTime(milliSec: timeStamp))"
        } else {
            textMessageTimeLabel?.text = DateFormatterUtility.shared.currentMillisecondsToLocalTime(milliSec: timeStamp)
        }
        
        self.isAccessibilityElement = true
        self.accessibilityLabel = message?.messageId
        favouriteImageView?.accessibilityLabel = message?.messageId
        bubbleBGView?.isAccessibilityElement =  true
        
        switch  message?.messageType {
        case .text, .meet, .autoText:
            if let label = messageLabel {
                let textMessage = message?.messageTextContent
                messageLabel?.attributedText = processTextMessage(message: (message?.messageType == .text || message?.messageType == .autoText) ? textMessage ?? "" : message?.meetChatMessage?.link ?? "", uiLabel: label, fromChat: fromChat, isMessageSearch: isMessageSearch, searchText: searchText, isMessageSentByMe: message?.isMessageSentByMe ?? false, mentionedUsers: message?.mentionedUsersIds ?? [], profileDetails: profileDetails)
                print("message label width = \(messageLabel?.frame.size.width)")

            }
            if let meetTimeLabel = scheduledMeetingTimeLabel {
                scheduledMeetingTimeLabel?.text = DateFormatterUtility.shared.getSchduleMeetingDate(date: message?.meetChatMessage?.scheduledDateTime ?? 0)
            }
        case .location:
            
            guard let latitude = message?.locationChatMessage?.latitude else {
                return nil
            }
            guard let longitude = message?.locationChatMessage?.longitude  else {
                return nil
            }
            
            AppUtils.shared.fetchStaticMapImage(latitude: latitude, longitude: longitude, zoomLevel: "16", size: CGSize(width: chatLocationMapView?.bounds.width ?? 250, height: chatLocationMapView?.bounds.height ?? 250)) { [self] mapImage in
                let mapImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: chatLocationMapView?.bounds.width ?? 250, height: chatLocationMapView?.bounds.height ?? 250))
                mapImageView.image = mapImage
                chatLocationMapView?.addSubview(mapImageView)
            }
            
//            chatLocationMapView?.camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 16.0, bearing: 360.0, viewingAngle: 15.0)
//   
//            DispatchQueue.main.async
//            { [self] in
//                // 2. Perform UI Operations.
//                var position = CLLocationCoordinate2DMake(latitude,longitude)
//                let marker = GMSMarker(position: position)
//                marker.map = chatLocationMapView
//            }
            
           break
        case .contact:
            if isMessageSearch == true || isStarredMessagePage {
                ChatUtils.highlight(uilabel: contactName ?? UILabel(), message: message?.contactChatMessage?.contactName ?? "", searchText: searchText, isMessageSearch: isMessageSearch, isSystemBlue: isStarredMessagePage == true && isMessageSearch == true ? true : false)
            } else {
                contactName?.attributedText =  ChatUtils.getAttributedMessage(message: message?.contactChatMessage?.contactName ?? "", searchText: searchText, isMessageSearch: isMessageSearch,isSystemBlue: isStarredMessagePage == true && isMessageSearch == true ? true : false)
            }
            break
        
        default:
            break
            
        }
        
        //MARK: - Populating the Incoming Cell with the translated message
        
        if (message!.isMessageTranslated && CommonDefaults.isTranlationEnabled) {
            guard let chatMessage = message,let messageLabeltemp = messageLabel, let translatedTextLabeltemp = translatedTextLabel else {return self }
            let textMessage = message?.messageTextContent 
            messageLabel?.attributedText = processTextMessage(message: textMessage ?? "", uiLabel: messageLabeltemp, fromChat: fromChat, isMessageSearch: isMessageSearch, searchText: searchText, isMessageSentByMe: message?.isMessageSentByMe ?? false, mentionedUsers: message?.mentionedUsersIds ?? [], profileDetails: profileDetails)
            translatedTextLabel?.attributedText = processTextMessage(message: chatMessage.translatedMessageTextContent , uiLabel: translatedTextLabeltemp, fromChat: fromChat, isMessageSearch: isMessageSearch, searchText: searchText, isMessageSentByMe: message?.isMessageSentByMe ?? false, mentionedUsers: message?.mentionedUsersIds ?? [], profileDetails: profileDetails)

        }
        return self
    }
    
    func setMessageNotAvailableLabel() {
        replyTextLabel?.text = "Original message not available"
        messageIconView?.isHidden = true
        messageTypeIcon?.isHidden = true
        mediaImageView?.isHidden = true
        mediaImageViewWidthCons?.constant = 0
        replyMessageIconWidthCons?.constant = 0
        replyMessageIconHeightCons?.isActive = false
    }
    
    @objc func didTapTextLabel(sender: UITapGestureRecognizer){
        if let textUILabel = sender.view as? UILabel {
            let tempName = (textUILabel).text ?? ""
            if !tempName.isEmpty {
                let textArray = tempName.split(separator: " ")
                for tempText in textArray {
                    let text = String(tempText)
                    if text.isNumber && text.count >= 6 && text.count <= 13 {
                        let textRange = (tempName as NSString).range(of: text)
                        if(sender.didTapAttributedTextInLabel(label: textUILabel, inRange: textRange)) {
                            print("didTapTextLabel isNumber \(text)")
                            AppUtils.shared.callPhoneNumber(phoneNumber: text)
                            break
                        }
                        
                    } else if text.isURL {
                        
                        let textRange = (tempName as NSString).range(of: text)
                        
                        if(sender.didTapAttributedTextInLabel(label: textUILabel, inRange: textRange)) {
                            
                            if text.contains(WEB_LOGIN_URL) {
                                
                                if !CallManager.isOngoingCall() && !CallManager.isAlreadyOnAnotherCall() {
                                    
                                    linkDelegate?.pushToJoinCallView(callLink: text)
                                }else {
                                    linkDelegate?.showAlreadyInCallAlert(callLink: text)
                                }
                            }else {
                                AppUtils.shared.openURLInBrowser(urlString: text)
                                
                            }
                            break
                        }
                    }
                }
            }
        }
        
    }

    func processTextMessage(message : String, uiLabel : UILabel, fromChat: Bool = false, isMessageSearch: Bool = false, searchText: String = "", isMessageSentByMe: Bool, mentionedUsers: [String], profileDetails: ProfileDetails) -> NSMutableAttributedString? {
        
        uiLabel.isUserInteractionEnabled = true
        var attributedString : NSMutableAttributedString?
        if !message.isEmpty {
            attributedString = NSMutableAttributedString(string: message)
            
            let linkDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            
            if let detector = linkDetector {
                let matches = detector.matches(in: message, options: .reportCompletion, range: NSRange(location: 0, length : message.utf16.count))
                for match in matches {
                    attributedString?.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.systemBlue], range: match.range)
                    attributedString?.addAttribute(.underlineStyle,
                                                   value: NSUnderlineStyle.single.rawValue,
                                                   range: match.range)
                    if message.contains(WEB_LOGIN_URL) {
                        if(isMessageSentByMe) {
                            linkView?.isHidden = false
                        }else {
                            receiverLinkView?.isHidden = false
                        }
                    }
                }
            }
            
            let numTypes: NSTextCheckingResult.CheckingType = .phoneNumber
            
            let phoneNumberDetector = try? NSDataDetector(types: numTypes.rawValue)
            
            if let phoneNumberDetector = phoneNumberDetector {
                let matches = phoneNumberDetector.matches(in: message, options: .reportCompletion, range: NSMakeRange(0, message.count))
                for match in matches {
                    if let urlString = match.phoneNumber?.lowercased(), urlString.count >= 6 && urlString.count <= 13 {
                        let range = (message.lowercased() as NSString).range(of: urlString )
                        attributedString?.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.systemBlue], range: range)
                        attributedString?.addAttribute(.underlineStyle,
                                                       value: NSUnderlineStyle.single.rawValue,
                                                       range: range)
                        
                    }
                }
            }
            
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapTextLabel(sender:)))
            uiLabel.addGestureRecognizer(gestureRecognizer)
            
            if !mentionedUsers.isEmpty {
                if profileDetails.profileChatType == .groupChat {
                    attributedString = ChatUtils.getMentionTextContent(message: message, uiLabel: uiLabel, isMessageSentByMe: isMessageSentByMe, mentionedUsers: mentionedUsers, searchedText: searchText)
                } else {
                    attributedString = NSMutableAttributedString(string: ChatUtils.convertMentionUser(message: message, mentionedUsersIds: mentionedUsers).replacingOccurrences(of: "`", with: ""))
                }
            } else {
                if fromChat && isMessageSearch {
                    let range = (message.lowercased() as NSString).range(of: searchText.lowercased())
                    attributedString?.addAttribute(NSAttributedString.Key.backgroundColor, value: Color.highlightColor, range: range)
                }
            }
        } else {
            attributedString = NSMutableAttributedString(string: message)
        }
        return attributedString
        
    }
    
    func getCallLinkID(callLink: String) -> String {
        
        return (callLink.components(separatedBy: "/").last ?? "")
    }
}

extension UITapGestureRecognizer {
    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange, edgeInset: UIEdgeInsets? = nil) -> Bool {
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)
        
        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        let alignment = label.textAlignment ?? .center
        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = CGSize(width: label.bounds.width - (edgeInset?.left ?? 0) - (edgeInset?.right ?? 0), height: label.bounds.height - (edgeInset?.top
                                                                                                                                            ?? 0) - (edgeInset?.bottom ?? 0))
        textContainer.size = labelSize
        
        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        if alignment == .left {
            xOffset = (edgeInset?.left ?? 0) - textBoundingBox.origin.x
            yOffset = (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y + (edgeInset?.top ?? 0)
        } else if alignment == .right {
            xOffset = label.bounds.width - (edgeInset?.right ?? 0) - labelSize.width - textBoundingBox.origin.x
            yOffset = (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y + (edgeInset?.top ?? 0)
        } else {
            xOffset = (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x + (edgeInset?.left ?? 0)
            yOffset = (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y + (edgeInset?.top ?? 0)
        }
        let textContainerOffset = CGPoint(
            x: xOffset,
            y: yOffset
        )
        let locationOfTouchInTextContainer = CGPoint(
            x: locationOfTouchInLabel.x - textContainerOffset.x,
            y: locationOfTouchInLabel.y - textContainerOffset.y
        )
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        return NSLocationInRange(indexOfCharacter, targetRange)
    }
}

