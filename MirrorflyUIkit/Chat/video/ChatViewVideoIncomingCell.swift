//
//  ChatViewVideoIncomingCell.swift
//  MirrorflyUIkit
//
//  Created by User on 24/09/21.
//

import UIKit
import MirrorFlySDK
import MapKit
import GoogleMaps
import NicoProgress
import SDWebImage

class ChatViewVideoIncomingCell: BaseTableViewCell {
   
    @IBOutlet weak var bubbleImageTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var videoTimeLabel: UILabel!
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var imageContainer: UIImageView!
    @IBOutlet weak var reecivedTime: UILabel!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var timeOverlay: UIImageView!
    @IBOutlet weak var closeImageView: UIImageView!
    @IBOutlet weak var progressLoader: UIView!
    @IBOutlet weak var progressButton: UIButton!
    @IBOutlet weak var downloadView: UIView!
    @IBOutlet weak var downloadImageView: UIImageView!
    @IBOutlet weak var fileSizeLabel: UILabel!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var caption: UILabel!
    @IBOutlet weak var captionViewHolder: UIStackView?
    @IBOutlet weak var favImageView: UIImageView?
    @IBOutlet weak var captionTime: UILabel?
    @IBOutlet weak var forwardButton: UIButton?
    @IBOutlet weak var forwardView: UIView?
    @IBOutlet weak var videoTimingContainer: UIStackView!
    @IBOutlet weak var senderNameView: UIView!
    @IBOutlet weak var senderGroupNameLabel: GroupReceivedMessageHeader!
    @IBOutlet weak var playButton: UIButton!
    
    // Reply Outlet
    @IBOutlet weak var mapView: UIView?
    @IBOutlet weak var mediaImageView: UIImageView?
    @IBOutlet weak var replyTextLabel: UILabel?
    @IBOutlet weak var messageIconView: UIView?
    @IBOutlet weak var messageTypeIcon: UIImageView?
    @IBOutlet weak var replyUserLabel: UILabel?
    @IBOutlet weak var replyView: UIView?
    @IBOutlet weak var bubbleImageView: UIImageView?
    @IBOutlet weak var replyWithMediaCons: NSLayoutConstraint?
    @IBOutlet weak var replyWithoutMediaCOns: NSLayoutConstraint?
    
    // Forward Outlet
    @IBOutlet weak var forwardImageView: UIImageView?
    @IBOutlet weak var quickForwardView: UIView?
    @IBOutlet weak var forwardLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var bubbleLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var quickForwardButton: UIButton?
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyViewHeight: NSLayoutConstraint!
    @IBOutlet weak var captionView: UIView!
    
    @IBOutlet weak var captionFavImageView: UIImageView?
    @IBOutlet weak var starredMessageView: UIView?
    @IBOutlet weak var senderTimeLabel: UILabel?
    @IBOutlet weak var senderTextLabel: UILabel?
    @IBOutlet weak var senderProfileImageView: UIImageView?
    @IBOutlet weak var senderStackView: UIStackView?
    
    @IBOutlet weak var sendToLabel: UILabel?
    @IBOutlet weak var bubbleImageBottomView: NSLayoutConstraint?
    
    //Translated Outlet
    @IBOutlet weak var translatedCaptionLabel: UILabel!
    var imageGeasture: UITapGestureRecognizer!

    
    var videoGesture: UITapGestureRecognizer!
    var message : ChatMessage?
    var selectedForwardMessage: [SelectedMessages]? = []
    var refreshDelegate: RefreshBubbleImageViewDelegate? = nil
    var isStarredMessagePage: Bool? = false
    var newProgressBar: ProgressBar!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupUI()
    }
    
    func setupUI() {
        videoGesture = UITapGestureRecognizer()
        imageContainer.addGestureRecognizer(videoGesture)
        newProgressBar = ProgressBar(frame: CGRect(x: 0, y: 0, width: progressLoader.frame.width, height: progressLoader.frame.height))
        newProgressBar.primaryColor = .white
        newProgressBar.bgColor = .clear
        progressLoader.addSubview(newProgressBar)
        caption.font = UIFont.font12px_appRegular()
        fileSizeLabel.font = UIFont.font12px_appSemibold()
        progressView.layer.cornerRadius = 4
        downloadView.layer.cornerRadius = 4
        starredMessageView?.roundCorners(corners: [.topLeft, .bottomLeft, .topRight], radius: 5.0)
        baseView.roundCorners(corners: [.topLeft, .bottomLeft, .topRight], radius: 5.0)
        imageContainer.layer.cornerRadius = 5.0
        imageContainer.clipsToBounds = true
        emptyView.layer.cornerRadius = 5.0
        imageGeasture = UITapGestureRecognizer()
        imageContainer?.addGestureRecognizer(imageGeasture)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func setSelectView(selected: Bool) {
         if selected {
         self.backgroundColor = .lightGray
         }else {
             self.backgroundColor = .clear
         }
    }
    
    @IBAction func canceldownload(_ sender: Any) {
        downloadView.isHidden = false
    }
    
    func showHideStarredMessageView() {
        starredMessageView?.isHidden = isStarredMessagePage == true ? false : true
        bubbleImageTopConstraint?.isActive = isStarredMessagePage == true ? false : true
        senderStackView?.isHidden = isStarredMessagePage == true ? false : true
        bubbleImageBottomView?.constant = isStarredMessagePage == true ? 10 : 3
    }
    
    func setUserProfileInfo(message: ChatMessage?,isBlocked: Bool) {
        let getProfileDetails = ChatManager.profileDetaisFor(jid: message?.chatUserJid ?? "")
        let senderProfileDetails = ChatManager.profileDetaisFor(jid: message?.senderUserJid ?? "")
        sendToLabel?.text = message?.messageChatType == .singleChat ? "You" : getUserName(jid : getProfileDetails?.jid ?? "" ,name: getProfileDetails?.name ?? "", nickName: getProfileDetails?.nickName ?? "", contactType: getProfileDetails?.contactType ?? .local)
        senderTextLabel?.text = getUserName(jid : senderProfileDetails?.jid ?? "" ,name: senderProfileDetails?.name ?? "", nickName: senderProfileDetails?.nickName ?? "", contactType: senderProfileDetails?.contactType ?? .local)
        
        let timeStamp =  message?.messageSentTime
        senderTimeLabel?.text = String(describing: DateFormatterUtility.shared.convertMillisecondsToSentTime(milliSeconds: timeStamp ?? 0.0))
        senderProfileImageView?.makeRounded()
        let contactColor = getColor(userName: getUserName(jid: senderProfileDetails?.jid ?? "",name: senderProfileDetails?.name ?? "", nickName: senderProfileDetails?.nickName ?? "", contactType: senderProfileDetails?.contactType ?? .local))
        setImage(imageURL: senderProfileDetails?.image ?? "", name: getUserName(jid: senderProfileDetails?.jid ?? "", name: senderProfileDetails?.name ?? "", nickName: senderProfileDetails?.nickName ?? "", contactType: senderProfileDetails?.contactType ?? .local), color: contactColor, chatType: senderProfileDetails?.profileChatType ?? .singleChat, jid: senderProfileDetails?.jid ?? "")
    }
    
    private func getisBlockedMe(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlockedMe ?? false
    }
    
    func setImage(imageURL: String, name: String, color: UIColor, chatType : ChatType,jid: String) {
        if !getisBlockedMe(jid: jid) || !(IS_LIVE && ENABLE_CONTACT_SYNC && ContactManager.shared.getUserProfileDetails(for: jid)?.isItSavedContact == false) {
            senderProfileImageView?.loadFlyImage(imageURL: imageURL, name: name, chatType: chatType, jid: jid)
        } else {
            senderProfileImageView?.image = UIImage(named: ImageConstant.ic_profile_placeholder)!
        }
    }
    

    func getCellFor(_ message: ChatMessage?, at indexPath: IndexPath?,isShowForwardView: Bool?,isDeleteMessageSelected: Bool?, fromChat: Bool = false, isMessageSearch: Bool = false, searchText: String = "", profileDetails: ProfileDetails) -> ChatViewVideoIncomingCell? {

        currentIndexPath = nil
        currentIndexPath = indexPath
        replyTextLabel?.text = ""
        replyUserLabel?.text = ""
        translatedCaptionLabel?.text = ""
        captionViewHolder?.spacing = CommonDefaults.isTranlationEnabled && message?.isMessageTranslated ?? false ? 10 : 0
        // Starred Messages
        // Starred Messages
        if let captionTxt = message?.mediaChatMessage?.mediaCaptionText, captionTxt == "" {
            favImageView?.isHidden =  message!.isMessageStarred ? false : true
            captionFavImageView?.isHidden = true
        } else {
            captionFavImageView?.isHidden =  message!.isMessageStarred ? false : true
            favImageView?.isHidden = true
        }
        showHideForwardView(message: message, isDeletedSelected: isDeleteMessageSelected, isShowForwardView: isShowForwardView)
        if selectedForwardMessage?.filter({$0.chatMessage.messageId == message?.messageId}).first?.isSelected == true {
            forwardImageView?.image = UIImage(named: "forwardSelected")
            forwardImageView?.isHidden = false
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 0.0)
        } else {
            //forwardImageView?.image = UIImage(named: "")
            forwardImageView?.isHidden = true
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
        }
        
        if message?.mediaChatMessage?.mediaDownloadStatus == .downloaded && !(isShowForwardView ?? false) {
            quickForwardView?.isHidden = false
            quickForwardButton?.isHidden = false
            isAllowSwipe = true
        } else {
            quickForwardView?.isHidden = true
            quickForwardButton?.isHidden = true
            isAllowSwipe = false
        }

        // Reply view elements and its data
       if(message!.isReplyMessage) {
            replyView?.isHidden = false
          let getReplymessage =  message?.replyParentChatMessage?.messageTextContent
           let replyMessage = FlyMessenger.getMessageOfId(messageId: message?.replyParentChatMessage?.messageId ?? "")
           if message?.replyParentChatMessage?.isMessageDeleted == true || message?.replyParentChatMessage?.isMessageRecalled == true || replyMessage == nil {
               replyTextLabel?.text = "Original message not available"
           } else {
               messageIconView?.isHidden = true
               replyTextLabel?.attributedText = ChatUtils.getAttributedMessage(message: getReplymessage ?? "", searchText: searchText, isMessageSearch: isMessageSearch, isSystemBlue: false)
               mapView?.isHidden = true
               if replyMessage?.mediaChatMessage != nil {
                   messageTypeIcon?.isHidden = false
                   
                   switch replyMessage?.mediaChatMessage?.messageType {
                   case .image:
                       messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderCamera" : "receiverCamera")
                       if let thumImage = replyMessage?.mediaChatMessage?.mediaThumbImage {
                           let converter = ImageConverter()
                           let image =  converter.base64ToImage(thumImage)
                           mediaImageView?.image = image
                           mediaImageView?.isHidden = false
                           let message = replyMessage?.mediaChatMessage?.mediaCaptionText
                           let mentionedUsersIds = replyMessage?.mentionedUsersIds ?? []
                           let isMessageSentByMe = replyMessage?.isMessageSentByMe ?? false
                           if message?.isEmpty ?? false {
                               replyTextLabel?.text = replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized
                           } else {
                               if !mentionedUsersIds.isEmpty {
                                   if profileDetails.profileChatType == .groupChat {
                                       replyTextLabel?.attributedText = ChatUtils.getMentionTextContent(message: message ?? "", uiLabel: replyTextLabel, isMessageSentByMe: isMessageSentByMe, mentionedUsers: mentionedUsersIds)
                                   } else {
                                       replyTextLabel?.text = ChatUtils.convertMentionUser(message: message ?? "", mentionedUsersIds: mentionedUsersIds).replacingOccurrences(of: "`", with: "")
                                   }
                               } else {
                                   replyTextLabel?.text = !(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized
                               }
                           }
                          // replyTextLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : "Photo"
                       }
                       replyWithoutMediaCOns?.isActive = false
                       replyWithMediaCons?.isActive = true
                   case .audio:
                       ChatUtils.setIconForAudio(imageView: messageTypeIcon, chatMessage: message)
                       let duration = Int(replyMessage?.mediaChatMessage?.mediaDuration ?? 0)
                       replyTextLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized.appending(" (\(FlyUtils.secondsToDurationInString(seconds: Double(duration / 1000))))")
                       replyWithoutMediaCOns?.isActive = false
                       replyWithMediaCons?.isActive = true
                   case .video:
                       messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderVideo" : "video")
                       if let thumImage = replyMessage?.mediaChatMessage?.mediaThumbImage {
                           let converter = ImageConverter()
                           let image =  converter.base64ToImage(thumImage)
                           mediaImageView?.image = image
                           mediaImageView?.isHidden = false
                           let message = replyMessage?.mediaChatMessage?.mediaCaptionText
                           let mentionedUsersIds = replyMessage?.mentionedUsersIds ?? []
                           let isMessageSentByMe = replyMessage?.isMessageSentByMe ?? false
                           if message?.isEmpty ?? false {
                               replyTextLabel?.text = replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized
                           } else {
                               if !mentionedUsersIds.isEmpty {
                                   if profileDetails.profileChatType == .groupChat {
                                       replyTextLabel?.attributedText = ChatUtils.getMentionTextContent(message: message ?? "", uiLabel: replyTextLabel, isMessageSentByMe: isMessageSentByMe, mentionedUsers: mentionedUsersIds)
                                   } else {
                                       replyTextLabel?.text = ChatUtils.convertMentionUser(message: message ?? "", mentionedUsersIds: mentionedUsersIds).replacingOccurrences(of: "`", with: "")
                                   }
                               } else {
                                   replyTextLabel?.text = !(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized
                               }
                           }
                           //replyTextLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized
                       }
                       replyWithoutMediaCOns?.isActive = false
                       replyWithMediaCons?.isActive = true
                       
                   case .document:
                       messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "document" : "document")
                       checkFileType(url: replyMessage?.mediaChatMessage?.mediaFileUrl ?? "", typeImageView: mediaImageView)
                       mediaImageView?.isHidden = false
                       replyTextLabel?.text = replyMessage?.mediaChatMessage?.mediaFileName.capitalized
                       replyWithoutMediaCOns?.isActive = false
                       replyWithMediaCons?.isActive = true
                   default:
                       messageIconView?.isHidden = true
                       replyWithoutMediaCOns?.isActive = true
                       replyWithMediaCons?.isActive = false
                       mediaImageView?.isHidden = true
                   }
                   
               } else if replyMessage?.locationChatMessage != nil {
                   mapView?.isHidden = false
                   replyTextLabel?.text = "Location"
                   mediaImageView?.isHidden = true
                   mapView?.isUserInteractionEnabled = false
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "map" : "receivedMap")
                   guard let latitude = replyMessage?.locationChatMessage?.latitude else {
                       return nil
                   }
                   guard let longitude = replyMessage?.locationChatMessage?.longitude  else {
                       return nil
                   }
                   
                   AppUtils.shared.fetchStaticMapImage(latitude: latitude, longitude: longitude, zoomLevel: "16", size: CGSize(width: mapView?.bounds.width ?? 250, height: mapView?.bounds.height ?? 250)) { [self] mapImage in
                       let mapImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: mapView?.bounds.width ?? 250, height: mapView?.bounds.height ?? 250))
                       mapImageView.image = mapImage
                       mapView?.addSubview(mapImageView)
                   }
                   
//                   mapView?.camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 16.0, bearing: 360.0, viewingAngle: 15.0)
//                   
//                   DispatchQueue.main.async
//                   { [self] in
//                       // 2. Perform UI Operations.
//                       var position = CLLocationCoordinate2DMake(latitude,longitude)
//                       var marker = GMSMarker(position: position)
//                       marker.map = mapView
//                   }
                   replyWithoutMediaCOns?.isActive = false
                   replyWithMediaCons?.isActive = true
                   messageIconView?.isHidden = false
               } else if replyMessage?.contactChatMessage != nil {
                   replyTextLabel?.attributedText = ChatUtils.setAttributeString(name: replyMessage?.contactChatMessage?.contactName)
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderContact" : "receiverContact")
                   messageIconView?.isHidden = false
                   mediaImageView?.isHidden = true
                   replyWithoutMediaCOns?.isActive = true
                   replyWithMediaCons?.isActive = false
               } else if replyMessage?.meetChatMessage != nil {
                   replyTextLabel?.text = DateFormatterUtility.shared.getSchduleMeetingDate(date: replyMessage?.meetChatMessage?.scheduledDateTime ?? 0)
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "video_link" : "video_link")
                   messageIconView?.isHidden = false
                   replyWithoutMediaCOns?.isActive = false
                   replyWithMediaCons?.isActive = true
                   mediaImageView?.image = UIImage(named: "app_icon")
                   mediaImageView?.isHidden = false
                   mediaImageView?.contentMode = .center
               } else {
                   mediaImageView?.isHidden = true
                   replyWithoutMediaCOns?.isActive = true
                   replyWithMediaCons?.isActive = false
               }
           }
        let isSentByMe = replyMessage?.isMessageSentByMe ?? false
        if isSentByMe {
            replyUserLabel?.text = you.localized
        }
        else {
            replyUserLabel?.text = getUserName(jid: replyMessage?.chatUserJid ?? "" ,name: replyMessage?.senderUserName ?? "",
                                               nickName: replyMessage?.senderNickName ?? "", contactType: (replyMessage?.isDeletedUser ?? false) ? .deleted : (replyMessage?.isSavedContact ?? false) ? .live : .unknown)
        }
           ChatUtils.setDeletedReplyMessage(chatMessage: replyMessage, messageIconView: messageIconView, messageTypeIcon: messageTypeIcon, replyTextLabel: replyTextLabel, mediaImageView: mediaImageView, mediaImageViewWidthCons: nil, replyMessageIconWidthCons: nil, replyMessageIconHeightCons: nil)
    }
        else {
            replyView?.isHidden = true
        }
        
        ChatUtils.setReceiverBubbleBackground(imageView: bubbleImageView)
        
        self.message = message
        
        if message?.messageChatType == .groupChat {
            senderGroupNameLabel.text = ChatUtils.getGroupSenderName(messsage: message)
        }else {
            senderNameView.isHidden = true
        }
        
        if let captionTxt = message?.mediaChatMessage?.mediaCaptionText, captionTxt != "" {
            //ChatUtils.highlight(uilabel: caption, message: captionTxt, searchText: searchText, isMessageSearch: isMessageSearch, isSystemBlue: isStarredMessagePage == true && isMessageSearch ? true : false)
            let messageTxt =  captionTxt
            let mentionedUsersIds = message?.mentionedUsersIds ?? []
            let isMessageSentByMe = message?.isMessageSentByMe ?? false
            if !mentionedUsersIds.isEmpty {
                if profileDetails.profileChatType == .groupChat {
                    caption.attributedText = ChatUtils.getMentionTextContent(message: messageTxt, uiLabel: caption, isMessageSentByMe: isMessageSentByMe, mentionedUsers: mentionedUsersIds, searchedText: searchText)
                } else {
                    caption.text = ChatUtils.convertMentionUser(message: messageTxt, mentionedUsersIds: mentionedUsersIds).replacingOccurrences(of: "`", with: "")
                }
            } else {
                var attributedString : NSMutableAttributedString?
                if fromChat && isMessageSearch {
                    attributedString = NSMutableAttributedString(string: captionTxt)
                    let range = (captionTxt.lowercased() as NSString).range(of: searchText.lowercased())
                    attributedString?.addAttribute(NSAttributedString.Key.backgroundColor, value: Color.highlightColor, range: range)
                    caption.attributedText = attributedString
                } else {
                    caption.text = messageTxt
                }
            }
            timeOverlay.isHidden = true
            reecivedTime.isHidden = true
            captionTime?.isHidden = false
            captionViewHolder?.isHidden = false
            captionView?.isHidden = false
            emptyViewHeight?.constant = 0
        }else{
            timeOverlay.isHidden = false
            reecivedTime.isHidden = false
            captionTime?.isHidden = true
            caption.text = ""
            captionViewHolder?.isHidden = true
            captionView?.isHidden = true
            emptyViewHeight?.constant = 4
        }
        
        if let duration = message?.mediaChatMessage?.mediaDuration {
            videoTimeLabel.text =  FlyUtils.secondsToDurationInString(seconds: Double(duration / 1000))
        } else {
            videoTimeLabel.text = ""
        }
        
        mediaStatus(message: message)
        
        if message?.messageType == .image {
            playButton.isHidden = true
            videoTimingContainer.isHidden = true
        }
        else {
            videoTimingContainer.isHidden = false
        }
        
//        if let thumImage = message?.mediaChatMessage?.mediaThumbImage {
//            ChatUtils.setThumbnail(imageContainer: imageContainer, base64String: thumImage)
//        }
        if (message?.messageType == .image && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded) {
            if let localPath = message?.mediaChatMessage?.mediaFileName {
                if let directoryURL: URL = FlyUtils.getGroupContainerIDPath() {
                    let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Image", isDirectory: true)
                    let fileURL: URL = folderPath.appendingPathComponent(localPath)
                    if FileManager.default.fileExists(atPath: fileURL.relativePath) {
                        let data = NSData(contentsOf: fileURL)
                        let image = UIImage(data: data! as Data)
                        imageContainer?.image = image
                    }
                }
            }
            else {
                if let thumImage = message?.mediaChatMessage?.mediaThumbImage {
                    ChatUtils.setThumbnail(imageContainer: imageContainer, base64String: thumImage)
                }
            }
        }
        else {
        if let thumImage = message?.mediaChatMessage?.mediaThumbImage {
            ChatUtils.setThumbnail(imageContainer: imageContainer, base64String: thumImage)
        }
        }
        
        guard let timeStamp =  message?.messageSentTime else {
            return self
        }
        let receivedTime = DateFormatterUtility.shared.convertMillisecondsToTime(milliSeconds: timeStamp).getTimeFormat()
        self.reecivedTime.text = receivedTime.uppercased()
        self.captionTime?.text = (message?.isMessageEdited ?? false) ? "Edited \(receivedTime.uppercased())" : receivedTime.uppercased()
        
        //MARK: - Populating the Incoming Cell with the translated message
        
        if (message!.isMessageTranslated && CommonDefaults.isTranlationEnabled) {
            guard let chatMessage = message else {return self }
            print(chatMessage.mediaChatMessage?.mediaCaptionText)
            print(chatMessage.translatedMessageTextContent)
            caption!.text = chatMessage.mediaChatMessage?.mediaCaptionText ?? ""
            translatedCaptionLabel!.text = chatMessage.translatedMessageTextContent
        }
        return self
    }
    
    func showHideForwardView(message : ChatMessage?,isDeletedSelected: Bool?,isShowForwardView: Bool?) {
        if isDeletedSelected ?? false {
            // Forward view elements and its data
            forwardView?.isHidden = (isShowForwardView == false || message?.mediaChatMessage?.mediaDownloadStatus == .downloading) ? true : false
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
            forwardLeadingCons?.constant = (isShowForwardView == false || message?.mediaChatMessage?.mediaDownloadStatus == .downloading) ? 0 : 20
            bubbleLeadingCons?.constant = (isShowForwardView == false || message?.mediaChatMessage?.mediaDownloadStatus == .downloading) ? 0 : 10
            forwardButton?.isHidden = (isShowForwardView == false || message?.mediaChatMessage?.mediaDownloadStatus == .downloading) ? true : false
        } else {
            // Forward view elements and its data
            forwardView?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded && message?.isMessageRecalled == false) ? false : true
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
            forwardLeadingCons?.constant = (isShowForwardView == true && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded && message?.isMessageRecalled == false) ? 20 : 0
            bubbleLeadingCons?.constant = (isShowForwardView == true && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded && message?.isMessageRecalled == false) ? 10 : 0
            forwardButton?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded && message?.isMessageRecalled == false) ? false : true
        }
    }
    
    func mediaStatus(message : ChatMessage?) {
        switch message?.mediaChatMessage?.mediaDownloadStatus {
        case .not_downloaded:
            downloadView.isHidden = false
            downloadButton.isHidden = false
            progressView.isHidden = true
            progressLoader.isHidden = true
            newProgressBar.isHidden = true
            playButton.isHidden = true
            fileSizeLabel.isHidden = false
            if let fileSize = message?.mediaChatMessage?.mediaFileSize{
                fileSizeLabel.text = "\(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))"
            }else {
                fileSizeLabel.text = ""
            }
        case .failed:
            downloadView.isHidden = false
            downloadButton.isHidden = false
            progressView.isHidden = true
            progressLoader.isHidden = true
            newProgressBar.isHidden = true
            playButton.isHidden = true
            fileSizeLabel.isHidden = false
            if let fileSize = message?.mediaChatMessage?.mediaFileSize{
                fileSizeLabel.text = "\(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))"
            }else {
                fileSizeLabel.text = ""
            }
        case .downloading:
            downloadView.isHidden = true
            downloadButton.isHidden = true
            progressLoader.isHidden = false
            fileSizeLabel.isHidden = true
            progressLoader.isHidden = false
            if progressLoader.subviews.isEmpty{
                progressLoader.addSubview(newProgressBar)
            }
            newProgressBar.setProg(per: CGFloat(message?.mediaChatMessage?.mediaProgressStatus ?? 0))
            newProgressBar.isHidden = false
            progressView.isHidden = false
            playButton.isHidden = true
        case .downloaded:
            if let localPath = message?.mediaChatMessage?.mediaLocalStoragePath, message?.messageType == .image {
                if FileManager.default.fileExists(atPath: localPath) {
                    let url = URL.init(fileURLWithPath: localPath)
                    let data = NSData(contentsOf: url as URL)
                    let image = UIImage(data: data! as Data)
                    imageContainer.image = image
                }
            }
            downloadView.isHidden = true
            downloadButton.isHidden = true
            progressView.isHidden = true
            progressLoader.isHidden = true
            newProgressBar.isHidden = true
            fileSizeLabel.isHidden = true
            playButton.isHidden = false
        default:
            downloadView.isHidden = false
            downloadButton.isHidden = false
            progressView.isHidden = true
            progressLoader.isHidden = true
            newProgressBar.isHidden = true
            fileSizeLabel.isHidden = true
            playButton.isHidden = true
            if let fileSize = message?.mediaChatMessage?.mediaFileSize{
                fileSizeLabel.text = "\(fileSize.byteSize)"
            }else {
                fileSizeLabel.text = ""
            }
        }
        //delete media
    }
}
extension UILabel {

    func highlight(searchedText: String?, color: UIColor = Color.color_3276E2 ?? UIColor.systemBlue) {
        guard let txtLabel = self.text?.lowercased(), let searchedText = searchedText?.lowercased() else {
            return
        }

        let attributeTxt = NSMutableAttributedString(string: txtLabel)
        let range: NSRange = attributeTxt.mutableString.range(of: searchedText, options: .caseInsensitive)

        attributeTxt.addAttribute(NSAttributedString.Key.backgroundColor, value: color, range: range)

        self.attributedText = attributeTxt
    }

}
