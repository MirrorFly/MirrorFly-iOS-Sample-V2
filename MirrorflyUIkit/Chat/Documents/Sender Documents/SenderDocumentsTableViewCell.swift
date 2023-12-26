//
//  SenderDocumentsTableViewCell.swift
//  UiKitQa
//
//  Created by Prabakaran M on 17/05/22.
//

import UIKit
import MirrorFlySDK
import NicoProgress
import GoogleMaps
import MapKit
import SDWebImage

class SenderDocumentsTableViewCell: BaseTableViewCell {

    @IBOutlet weak var bubbleImageView: UIImageView?
    @IBOutlet weak var cellBaseView: UIView?
    @IBOutlet weak var documenTypeView: UIView?
    @IBOutlet weak var documentNameLabel: UILabel?
    @IBOutlet weak var documetTypeImage: UIImageView?
    @IBOutlet weak var sentTimeLabel: UILabel?
    @IBOutlet weak var messageStatusImage: UIImageView?
    @IBOutlet weak var nicoProgressBar: UIView!
    
    //StarredMessages
    @IBOutlet weak var favImageView: UIImageView?
    @IBOutlet weak var senderImageview: UIImageView?
    @IBOutlet weak var senderTimeLabel: UILabel?
    @IBOutlet weak var senderStackView: UIStackView?
    @IBOutlet weak var starredMessageView: UIView?
    @IBOutlet weak var bubbleImageBottomCons: NSLayoutConstraint?
    @IBOutlet weak var bubbleImageTopCons: NSLayoutConstraint?
    @IBOutlet weak var bubbleTopContentViewCons: NSLayoutConstraint?
    @IBOutlet weak var sendToLabel: UILabel?
    @IBOutlet weak var sendFromLabel: UILabel?
    @IBOutlet weak var fwdButton: UIButton?
    @IBOutlet weak var doctNameTrailingWithoutImageCons: NSLayoutConstraint?
    @IBOutlet weak var documentNameTrailingCons: NSLayoutConstraint?
    @IBOutlet weak var viewDocumentButton: UIButton?
    @IBOutlet weak var documentSizeLabel: UILabel?
    @IBOutlet weak var uploadButton: UIButton?
    @IBOutlet weak var uploadView: UIView?
    @IBOutlet weak var uploadCancelImage: UIImageView?
    @IBOutlet weak var uploadImageView: UIImageView?
    @IBOutlet weak var replyView: UIView?
    @IBOutlet weak var replyTypeIconImageView: UIImageView?
    @IBOutlet weak var replyUserNameLabel: UILabel?
    @IBOutlet weak var replyTypeLabel: UILabel?
    @IBOutlet weak var replyTypeImageView: UIImageView?
    @IBOutlet weak var mediaMapView: UIView?
    @IBOutlet weak var replyMediaImageWidthCons: NSLayoutConstraint?
    // Forward Outlet
    @IBOutlet weak var forwardImageView: UIImageView?
    @IBOutlet weak var forwardView: UIView?
    @IBOutlet weak var forwardButton: UIButton?
    @IBOutlet weak var replyMessageIconWidth: NSLayoutConstraint?
    
    var isUploading: Bool? = false
    var newProgressBar: ProgressBar!
    var isShowAudioLoadingIcon: Bool? = false
    
    var selectedForwardMessage: [SelectedMessages]? = []
    var message: ChatMessage?
    //MARK: StarredMessage local variable
    var isStarredMessagePage: Bool? = false
    
    var refreshDelegate: RefreshBubbleImageViewDelegate? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setupUI() {
        sentTimeLabel?.font = UIFont.font9px_appLight()
        replyView?.roundCorners(corners: [.topLeft, .topRight], radius: 5.0)
        cellBaseView?.roundCorners(corners: [.topLeft, .bottomLeft, .topRight], radius: 5.0)
        newProgressBar = ProgressBar(frame: CGRect(x: 0, y: 0, width: nicoProgressBar.frame.width, height: nicoProgressBar.frame.height))
        newProgressBar.primaryColor = .gray
        newProgressBar.bgColor = .clear
    }
    
    func setSelectView(selected: Bool) {
        if selected {
            self.backgroundColor = .lightGray
        } else {
            self.backgroundColor = .clear
        }
    }
    
    func showHideStarredMessageView() {
        starredMessageView?.isHidden = isStarredMessagePage == true ? false : true
        bubbleImageTopCons?.isActive = isStarredMessagePage == true ? false : true
        senderStackView?.isHidden = isStarredMessagePage == true ? false : true
        bubbleImageBottomCons?.constant = isStarredMessagePage == true ? 10 : 3
    }

    func setUserProfileInfo(message: ChatMessage?,isBlocked: Bool) {
        let getProfileDetails = ChatManager.profileDetaisFor(jid: message?.chatUserJid ?? "")
        let senderProfileDetails = ChatManager.profileDetaisFor(jid: message?.senderUserJid ?? "")
        sendFromLabel?.text = "You"
        sendToLabel?.text = getUserName(jid : getProfileDetails?.jid ?? "" ,name: getProfileDetails?.name ?? "", nickName: getProfileDetails?.nickName ?? "", contactType: getProfileDetails?.contactType ?? .local)
        
        let timeStamp =  message?.messageSentTime
        senderTimeLabel?.text = String(describing: DateFormatterUtility.shared.convertMillisecondsToSentTime(milliSeconds: timeStamp ?? 0.0))
        senderImageview?.makeRounded()
        let contactColor = getColor(userName: getUserName(jid: senderProfileDetails?.jid ?? "",name: senderProfileDetails?.name ?? "", nickName: senderProfileDetails?.nickName ?? "", contactType: senderProfileDetails?.contactType ?? .local))
        setImage(imageURL: senderProfileDetails?.image ?? "", name: getUserName(jid: senderProfileDetails?.jid ?? "", name: senderProfileDetails?.name ?? "", nickName: senderProfileDetails?.nickName ?? "", contactType: senderProfileDetails?.contactType ?? .local), color: contactColor, chatType: senderProfileDetails?.profileChatType ?? .singleChat, jid: senderProfileDetails?.jid ?? "")
    }
    
    private func getisBlockedMe(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlockedMe ?? false
    }
    
    func setImage(imageURL: String, name: String, color: UIColor, chatType : ChatType,jid: String) {
        if !getisBlockedMe(jid: jid) || !(IS_LIVE && ENABLE_CONTACT_SYNC && ContactManager.shared.getUserProfileDetails(for: jid)?.isItSavedContact == false) {
            senderImageview?.loadFlyImage(imageURL: imageURL, name: name, chatType: chatType, jid: jid)
        } else {
            senderImageview?.image = UIImage(named: ImageConstant.ic_profile_placeholder)!
        }
    }
    

    func getCellFor(_ message: ChatMessage?, at indexPath: IndexPath?, isShowForwardView: Bool?,isDeletedMessageSelected: Bool?, fromChat: Bool = false, isMessageSearch: Bool = false, searchText: String = "") -> SenderDocumentsTableViewCell? {

        currentIndexPath = nil
        currentIndexPath = indexPath
        let mediaUrl = message?.mediaChatMessage?.mediaFileUrl
        checkFileType(urlExtension: ((mediaUrl?.isEmpty ?? false ? (message?.mediaChatMessage?.mediaLocalStoragePath.components(separatedBy: ".").last as? String) : mediaUrl?.components(separatedBy: ".").last) ?? ""), typeImageView: documetTypeImage)
        viewDocumentButton?.isHidden = message?.mediaChatMessage?.mediaUploadStatus == .uploaded && isShowForwardView == false ? false : true
        showHideForwardView(message: message, isShowForwardView: isShowForwardView, isDeletedMessageSelected: isDeletedMessageSelected)
        
        if selectedForwardMessage?.filter({$0.chatMessage.messageId == message?.messageId}).first?.isSelected == true {
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 0.0)
            forwardImageView?.image = UIImage(named: "forwardSelected")
            forwardImageView?.isHidden = false
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 0.0)
        } else {
            forwardImageView?.image = UIImage(named: "")
            forwardImageView?.isHidden = true
            forwardButton?.isSelected = !(forwardButton?.isSelected ?? false)
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
        }
        isAllowSwipe = ( message?.mediaChatMessage?.mediaUploadStatus == .uploaded || message?.mediaChatMessage?.mediaDownloadStatus == .downloaded ) ? true : false
        
        if message?.isCarbonMessage == true {
            if isDeletedMessageSelected == false {
                if  (message?.mediaChatMessage?.mediaDownloadStatus == .downloaded && isShowForwardView == true) {
                    forwardView?.isHidden = false
                    forwardButton?.isHidden = false
                } else {
                    forwardView?.isHidden = true
                    forwardButton?.isHidden = true
                }
            }
        } else {
            if isDeletedMessageSelected == false {
                if  (message?.mediaChatMessage?.mediaUploadStatus == .uploaded && isShowForwardView == true) {
                    forwardView?.isHidden = false
                    forwardButton?.isHidden = false
                } else {
                    forwardView?.isHidden = true
                    forwardButton?.isHidden = true
                }
            }
        }
        
        if  ((!(message?.isCarbonMessage ?? true) && message?.mediaChatMessage?.mediaUploadStatus != .uploaded) || ( message?.isCarbonMessage ?? false && message?.mediaChatMessage?.mediaDownloadStatus != .downloaded ) || isShowForwardView == true || isStarredMessagePage == true) {
            fwdButton?.isHidden = true
        } else {
            fwdButton?.isHidden = false
        }
        
        // Starred Messages
        favImageView?.isHidden =  (message?.isMessageStarred ?? false) ? false : true
        
        /// - Handling Reply Messages
        
        if(message?.isReplyMessage ?? false) {
            documenTypeView?.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 5)
            replyView?.isHidden = false
            let getReplymessage = message?.replyParentChatMessage?.messageTextContent
            let replyMessage = FlyMessenger.getMessageOfId(messageId: message?.replyParentChatMessage?.messageId ?? "")
            mediaMapView?.isHidden = true
            replyTypeImageView?.isHidden = true
            if replyMessage?.isMessageSentByMe == true {
                replyUserNameLabel?.text = you.localized
            } else {
                replyUserNameLabel?.text = getUserName(jid: replyMessage?.senderUserJid ?? "", name: replyMessage?.senderUserName ?? "",
                                                       nickName: replyMessage?.senderNickName ?? "",
                                                       contactType: replyMessage?.isSavedContact == true ? .live : .unknown)
            }
            if message?.replyParentChatMessage?.isMessageDeleted == true || message?.replyParentChatMessage?.isMessageRecalled == true || replyMessage == nil {
                replyTypeLabel?.text = "Original message not available"
                replyMessageIconWidth?.constant = 0
                replyMediaImageWidthCons?.constant = 0
                replyTypeIconImageView?.isHidden = true
            } else {
                replyTypeLabel?.attributedText = ChatUtils.getAttributedMessage(message: getReplymessage ?? "", searchText: searchText, isMessageSearch: isMessageSearch, isSystemBlue: false)
            checkFileType(url: replyMessage?.mediaChatMessage?.mediaFileUrl ?? "", typeImageView: replyTypeImageView)
                replyMessageIconWidth?.constant = 0
            if replyMessage?.mediaChatMessage != nil {
                replyMessageIconWidth?.constant = 15
                replyTypeIconImageView?.isHidden = false
                switch replyMessage?.mediaChatMessage?.messageType {
                case .image:
                    replyTypeIconImageView?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderCamera" : "receiverCamera")
                    if let thumImage = replyMessage?.mediaChatMessage?.mediaThumbImage {
                        let converter = ImageConverter()
                        let image =  converter.base64ToImage(thumImage)
                        replyTypeImageView?.image = image
                        replyTypeImageView?.isHidden = false
                        replyMediaImageWidthCons?.constant = 50
                        replyTypeLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : "Photo"
                    }
                    mediaMapView?.isHidden = true
                case .audio:
                    let duration = Int(replyMessage?.mediaChatMessage?.mediaDuration ?? 0)
                    ChatUtils.setIconForAudio(imageView: replyTypeIconImageView, chatMessage: message)
                    replyTypeLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized.appending(" (\(duration.msToSeconds.minuteSecondMS))")
                    replyTypeImageView?.isHidden = true
                    replyMediaImageWidthCons?.constant = 0
                    mediaMapView?.isHidden = true
                case .video:
                    replyTypeIconImageView?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderVideo" : "video")
                    replyTypeImageView?.isHidden = false
                    replyMediaImageWidthCons?.constant = 50
                    if let thumImage = message?.replyParentChatMessage?.mediaChatMessage?.mediaThumbImage {
                        let converter = ImageConverter()
                        let image =  converter.base64ToImage(thumImage)
                        replyTypeImageView?.image = image
                        replyTypeLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized
                    }
                    mediaMapView?.isHidden = true
                case .document:
                    replyTypeIconImageView?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "document" : "document")
                    checkFileType(url: replyMessage?.mediaChatMessage?.mediaFileUrl ?? "", typeImageView: replyTypeImageView)
                    replyTypeLabel?.text = replyMessage?.mediaChatMessage?.mediaFileName
                    replyTypeImageView?.isHidden = false
                    replyMediaImageWidthCons?.constant = 50
                    mediaMapView?.isHidden = true
                default:
                    replyTypeImageView?.isHidden = true
                    replyMediaImageWidthCons?.constant = 0
                    replyUserNameLabel?.isHidden = true
                    replyTypeLabel?.isHidden = true
                    replyTypeIconImageView?.isHidden = true
                    mediaMapView?.isHidden = true
                    replyMessageIconWidth?.constant = 0
                }
            } else if replyMessage?.locationChatMessage != nil {
                replyMessageIconWidth?.constant = 15
                replyTypeLabel?.text = "Location"
                //                chatMapView?.isUserInteractionEnabled = false
                replyTypeIconImageView?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "map" : "receivedMap")
                guard let latitude = replyMessage?.locationChatMessage?.latitude else {
                    return nil
                }
                guard let longitude = replyMessage?.locationChatMessage?.longitude  else {
                    return nil
                }
                
                AppUtils.shared.fetchStaticMapImage(latitude: latitude, longitude: longitude, zoomLevel: "16", size: CGSize(width: mediaMapView?.bounds.width ?? 250, height: mediaMapView?.bounds.height ?? 250)) { [self] mapImage in
                    let mapImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: mediaMapView?.bounds.width ?? 250, height: mediaMapView?.bounds.height ?? 250))
                    mapImageView.image = mapImage
                    mediaMapView?.addSubview(mapImageView)
                }
                
//                mediaMapView?.camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 16.0, bearing: 360.0, viewingAngle: 15.0)
//                mediaMapView?.isUserInteractionEnabled = false
//                DispatchQueue.main.async
//                { [self] in
//                    // 2. Perform UI Operations.
//                    let position = CLLocationCoordinate2DMake(replyMessage?.locationChatMessage?.latitude ?? 0.0,replyMessage?.locationChatMessage?.longitude ?? 0.0)
//                    let marker = GMSMarker(position: position)
//                    marker.map = mediaMapView
//                }
                replyTypeIconImageView?.isHidden = false
                replyTypeImageView?.isHidden = true
                replyMediaImageWidthCons?.constant = 50
                mediaMapView?.isHidden = false
                
            } else if replyMessage?.contactChatMessage != nil {
                replyMessageIconWidth?.constant = 15
                replyTypeLabel?.attributedText = ChatUtils.setAttributeString(name: replyMessage?.contactChatMessage?.contactName)
                replyTypeIconImageView?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderContact" : "receiverContact")
                replyTypeIconImageView?.isHidden = false
                replyTypeImageView?.isHidden = true
                mediaMapView?.isHidden = true
            } else if replyMessage?.meetChatMessage != nil {
                replyMessageIconWidth?.constant = 12
                replyTypeIconImageView?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "video_link" : "video_link")
                replyTypeLabel?.text = DateFormatterUtility.shared.getSchduleMeetingDate(date: replyMessage?.meetChatMessage?.scheduledDateTime ?? 0)
                replyTypeImageView?.isHidden = false
                replyMediaImageWidthCons?.constant = 50
                mediaMapView?.isHidden = true
                replyTypeImageView?.image = UIImage(named: "app_icon")
                replyTypeImageView?.contentMode = .center
                replyTypeImageView?.isHidden = false
            }
            }
        } else {
            documenTypeView?.roundCorners(corners: [.topLeft, .bottomLeft, .topRight, .bottomRight], radius: 5.0)
            replyView?.isHidden = true
            replyTypeIconImageView?.isHidden = true
            mediaMapView?.isHidden = true
            replyMessageIconWidth?.constant = 0
        }
        
        /// Carbon Messages Handler
        updateMediaStatus(message: message, indexPath: indexPath)
        
        let status = message?.messageStatus
        if status == .acknowledged || status == .received || status == .delivered || status == .seen {
            newProgressBar.removeFromSuperview()
        }
        
        ChatUtils.setSenderBubbleBackground(imageView: bubbleImageView)
        
        switch message?.messageStatus {
        case .notAcknowledged:
            messageStatusImage?.image = UIImage(named: ImageConstant.ic_hour)
            messageStatusImage?.accessibilityLabel = notAcknowledged.localized
        case .sent:
            messageStatusImage?.image = UIImage(named: ImageConstant.ic_hour)
            messageStatusImage?.accessibilityLabel = sent.localized
        case .acknowledged:
            messageStatusImage?.image = UIImage(named: ImageConstant.ic_sent)
            messageStatusImage?.accessibilityLabel = acknowledged.localized
        case .delivered:
            messageStatusImage?.image = UIImage(named: ImageConstant.ic_delivered)
            messageStatusImage?.accessibilityLabel = delivered.localized
        case .seen:
            messageStatusImage?.image = UIImage(named: ImageConstant.ic_seen)
            messageStatusImage?.accessibilityLabel = seen.localized
        case .received:
            messageStatusImage?.image = UIImage(named: ImageConstant.ic_delivered)
            messageStatusImage?.accessibilityLabel = delivered.localized
        default:
            messageStatusImage?.image = UIImage(named: ImageConstant.ic_hour)
            messageStatusImage?.accessibilityLabel = notAcknowledged.localized
        }
        
        guard let timeStamp =  message?.messageSentTime else {
            return self
        }
        
        if let fileSize = message?.mediaChatMessage?.mediaFileSize{
            documentSizeLabel?.text = "\(fileSize.byteSize)"
        } else {
            documentSizeLabel?.text = ""
        }
        if (isStarredMessagePage == true || isMessageSearch == true) {
            ChatUtils.highlight(uilabel: documentNameLabel ?? UILabel(), message: message?.mediaChatMessage?.mediaFileName ?? "", searchText: searchText, isMessageSearch: isMessageSearch, isSystemBlue: isStarredMessagePage == true && isMessageSearch == true ? true : false)
        } else {
            documentNameLabel?.text = message?.mediaChatMessage?.mediaFileName
        }
        sentTimeLabel?.text = DateFormatterUtility.shared.currentMillisecondsToLocalTime(milliSec: timeStamp)
        self.layoutIfNeeded()
        self.layoutSubviews()
        
        return self
    }
    
    func updateMediaStatus(message: ChatMessage?, indexPath: IndexPath?) {
        
        if message?.isCarbonMessage == false {
            if message?.mediaChatMessage?.mediaUploadStatus == .not_uploaded {
                uploadCancelImage?.isHidden = false
                uploadCancelImage?.image = UIImage(named: ImageConstant.ic_upload)
                uploadButton?.isHidden = false
                newProgressBar.removeFromSuperview()
                documentNameTrailingCons?.isActive = true
                doctNameTrailingWithoutImageCons?.isActive = false
            } else if message?.mediaChatMessage?.mediaUploadStatus == .failed {
                uploadCancelImage?.isHidden = false
                uploadCancelImage?.image = UIImage(named: ImageConstant.ic_upload)
                uploadButton?.isHidden = false
                newProgressBar.removeFromSuperview()
                documentNameTrailingCons?.isActive = true
                doctNameTrailingWithoutImageCons?.isActive = false
            } else if message?.mediaChatMessage?.mediaUploadStatus == .uploading {
                uploadCancelImage?.image = UIImage(named: ImageConstant.ic_uploadCancel)
                uploadButton?.isHidden = false
                uploadImageView?.isHidden = true
                uploadCancelImage?.isHidden = false
                nicoProgressBar.isHidden = false
                if nicoProgressBar.subviews.isEmpty{
                    nicoProgressBar.addSubview(newProgressBar)
                }
                newProgressBar.setProg(per: CGFloat(message?.mediaChatMessage?.mediaProgressStatus ?? 0))
                documentNameTrailingCons?.isActive = true
                doctNameTrailingWithoutImageCons?.isActive = false
            } else if message?.mediaChatMessage?.mediaUploadStatus == .uploaded {
                documentNameTrailingCons?.isActive = false
                doctNameTrailingWithoutImageCons?.isActive = true
                newProgressBar.removeFromSuperview()
                uploadCancelImage?.isHidden = true
                uploadImageView?.isHidden = true
                uploadButton?.isHidden = true
                
            } else if message?.mediaChatMessage?.mediaUploadStatus == .not_available {
                uploadCancelImage?.isHidden = false
                uploadCancelImage?.image = (isShowAudioLoadingIcon == true && indexPath == IndexPath(row: 0, section: 0)) ? UIImage(named: ImageConstant.ic_uploadCancel) : UIImage(named: "download")
                uploadButton?.isHidden = (isShowAudioLoadingIcon == true && indexPath == IndexPath(row: 0, section: 0)) ? true : false
                newProgressBar.removeFromSuperview()
            } else {
                newProgressBar.removeFromSuperview()
                uploadCancelImage?.isHidden = true
                uploadImageView?.isHidden = true
                uploadButton?.isHidden = true
                documentNameTrailingCons?.isActive = false
                doctNameTrailingWithoutImageCons?.isActive = true
            }
        } else {
            if message?.mediaChatMessage?.mediaDownloadStatus == .not_downloaded || message?.messageStatus == .sent {
                uploadCancelImage?.isHidden = false
                uploadCancelImage?.image =  UIImage(named: "download")
                uploadButton?.isHidden = false
            } else if message?.mediaChatMessage?.mediaDownloadStatus == .failed  {
                uploadCancelImage?.isHidden = false
                uploadCancelImage?.image = UIImage(named: "download")
                uploadButton?.isHidden = false
            } else if message?.mediaChatMessage?.mediaDownloadStatus == .downloading {
                uploadCancelImage?.image = UIImage(named: ImageConstant.ic_uploadCancel)
                uploadCancelImage?.isHidden = false
                uploadButton?.isHidden = false
                nicoProgressBar.addSubview(newProgressBar)
                
            } else if message?.mediaChatMessage?.mediaDownloadStatus == .downloaded {
//                if let localPath = message?.mediaChatMessage?.mediaFileName {
//                    if let directoryURL: URL = FlyUtils.getGroupContainerIDPath() {
//                        let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Document", isDirectory: true)
//                        let fileURL: URL = folderPath.appendingPathComponent(localPath)
//                        if FileManager.default.fileExists(atPath: fileURL.relativePath) {
//                            let data = NSData(contentsOf: fileURL)
//                            let image = UIImage(data: data! as Data)
//                            bubbleImageView?.image = image
//                        }
//                    }
//                }
                uploadCancelImage?.isHidden = true
                newProgressBar.removeFromSuperview()
                
            } else {
                newProgressBar.removeFromSuperview()
            }
        }
    }
    
    func showHideForwardView(message: ChatMessage?, isShowForwardView: Bool?,isDeletedMessageSelected: Bool?) {
        if isDeletedMessageSelected == true {
            // Forward view elements and its data
            forwardView?.isHidden = (isShowForwardView == false || message?.mediaChatMessage?.mediaUploadStatus == .uploading)  || (message?.isMessageRecalled == true) ? true : false
            forwardButton?.isHidden = (isShowForwardView == false || message?.mediaChatMessage?.mediaUploadStatus == .uploading)  || (message?.isMessageRecalled == true) ? true : false
        } else {
            // Forward view elements and its data
            forwardView?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaUploadStatus == .uploaded && message?.isMessageRecalled == false) ? false : true
            forwardButton?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaUploadStatus == .uploaded && message?.isMessageRecalled == false) ? false : true
        }
    }
    
    func startUpload() {
        uploadCancelImage?.isHidden = false
        uploadCancelImage?.image = UIImage(named: ImageConstant.ic_uploadCancel)
        nicoProgressBar.isHidden = false
        if nicoProgressBar.subviews.isEmpty{
            nicoProgressBar.addSubview(newProgressBar)
        }
        newProgressBar.setProg(per: CGFloat(message?.mediaChatMessage?.mediaProgressStatus ?? 0))
    }
    
    func stopUpload() {
        uploadCancelImage?.isHidden = false
        uploadCancelImage?.image = UIImage(named: ImageConstant.ic_upload)
        nicoProgressBar.isHidden = true
        newProgressBar.removeFromSuperview()
    }
    
    func stopDownload() {
        uploadCancelImage?.isHidden = false
        uploadCancelImage?.image = UIImage(named: "Download")
        nicoProgressBar.isHidden = true
        newProgressBar.removeFromSuperview()
    }
}

