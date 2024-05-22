//
//  AudioReceiver.swift
//  MirrorflyUIkit
//
//  Created by User on 31/08/21.

import UIKit
import MirrorFlySDK
import AVFoundation
import NicoProgress
import GoogleMaps
import MapKit
import SDWebImage

class AudioReceiver: BaseTableViewCell, AVAudioPlayerDelegate {
    @IBOutlet weak var timeView: UIView?
    @IBOutlet weak var audioView: UIView?
    @IBOutlet weak var fwdViw: UIView?
    @IBOutlet weak var fwdIcon: UIImageView?
    @IBOutlet weak var fwdBtn: UIButton?
    @IBOutlet weak var slider: UISlider?
    @IBOutlet weak var audioDuration: UILabel?
    @IBOutlet weak var playBtn: UIButton?
    @IBOutlet weak var recvTime: UILabel?
    @IBOutlet weak var playView: UIView?
    @IBOutlet weak var nicoProgressBar: UIView!
    @IBOutlet weak var favImageView: UIImageView?
    @IBOutlet weak var audioReceiverImage: UIImageView?
    @IBOutlet weak var playImage: UIImageView?
    @IBOutlet weak var download: UIImageView?
    @IBOutlet weak var downloadButton: UIButton?
    
    // Reply Outlet
    @IBOutlet weak var mapView: UIView?
    @IBOutlet weak var mediaMessageImageView: UIImageView?
    @IBOutlet weak var messageTypeIconView: UIView?
    @IBOutlet weak var messageTypeIcon: UIImageView?
    @IBOutlet weak var replyUserLabel: UILabel?
    @IBOutlet weak var replyView: UIView?
    @IBOutlet weak var bubbleImageView: UIImageView?
    @IBOutlet weak var replyTextLabel: UILabel?
    @IBOutlet weak var replyWithMediaCons: NSLayoutConstraint?
    @IBOutlet weak var replyWithOutMediaCons: NSLayoutConstraint?
    
    // Forward Outlet
    @IBOutlet weak var forwardImageView: UIImageView?
    @IBOutlet weak var forwardView: UIView?
    @IBOutlet weak var forwardLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var bubbleLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var forwardButton: UIButton?

    @IBOutlet weak var senderNameContainer: UIView?
    @IBOutlet weak var senderNameLabel: UILabel?
    @IBOutlet weak var bubbleImageViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var senderStackView: UIStackView?
    @IBOutlet weak var bubbleImageBottomView: NSLayoutConstraint?
    @IBOutlet weak var senderTextLabel: UILabel?
    @IBOutlet weak var senderTimeLabel: UILabel?
    @IBOutlet weak var senderProfileImage: UIImageView?
    @IBOutlet weak var starredMessageView: UIView?
    @IBOutlet weak var senderToLabel: UILabel?
    
    var selectedForwardMessage: [SelectedMessages]? = []
    var message : ChatMessage?
    weak var refreshDelegate: RefreshBubbleImageViewDelegate?
    weak var gestureDelegate: GestureDelegate? = nil
    var audioPlayer:AVAudioPlayer?
    var updater : CADisplayLink! = nil
    typealias AudioCallBack = (_ sliderValue : Float) -> Void
        var audioCallBack: AudioCallBack? = nil
    var isStarredMessagePage: Bool? = false
    var newProgressBar: ProgressBar!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupUI()
    }

    func setupReplyGesture() {
        //Reply tap gesture
        let  textReplyTap = UITapGestureRecognizer(target: self, action: #selector(self.replyViewTapGesture(_:)))
        replyView?.addGestureRecognizer(textReplyTap)
        textReplyTap.delegate = self
    }

    @objc func replyViewTapGesture(_ sender: UITapGestureRecognizer? = nil) {
        gestureDelegate?.replyGesture(sender)
    }

    func setupUI() {
        recvTime?.font = UIFont.font9px_appLight()
        audioDuration?.font = UIFont.font8px_appLight()
        contentView.clipsToBounds = true
        audioView?.clipsToBounds = true
        timeView?.clipsToBounds = true
        audioView?.roundCorners(corners: [.topLeft, .topRight], radius: 8.0)
        timeView?.roundCorners(corners: [.topLeft, .topRight, .bottomRight], radius: 8.0)
        starredMessageView?.roundCorners(corners: [.topLeft, .bottomLeft, .topRight], radius: 5.0)
        var thumbImage = UIImage(named: ImageConstant.ic_slider)
        let size = getCGSize(width: 15, height: 15)
        thumbImage = thumbImage?.scaleToSize(newSize: size)
        slider?.setThumbImage(thumbImage, for: UIControl.State.normal)
        slider?.minimumValue = 0
        slider?.maximumValue = 100
        audioReceiverImage?.image = UIImage(named: ImageConstant.ic_music)
        newProgressBar = ProgressBar(frame: CGRect(x: 0, y: 0, width: nicoProgressBar.frame.width, height: nicoProgressBar.frame.height))
        newProgressBar.primaryColor = .white
        newProgressBar.bgColor = .clear
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func trackAudio() {
        if let curnTime = audioPlayer?.currentTime {
            if let duration = audioPlayer?.duration {
      let normalizedTime = Float(curnTime * 100.0 / duration)
                slider?.value = normalizedTime
                print(normalizedTime)
                print(curnTime)
                print(duration)
                    let min = Int(curnTime / 60)
                    let sec = Int(curnTime.truncatingRemainder(dividingBy: 60))
                    let totalTimeString = String(format: "%02d:%02d", min, sec)
                audioDuration?.text = totalTimeString
                   print(totalTimeString)
            }
        }
    }
    
    @IBAction func fwdAction(_ sender: Any) {
        
    }
    

    func hideSenderGroupName() {
        senderNameContainer?.isHidden = true
        senderNameLabel?.text = ""
    }
    
    func showHideStarredMessageView() {
        starredMessageView?.isHidden = isStarredMessagePage == true ? false : true
        bubbleImageViewTopConstraint?.isActive = isStarredMessagePage == true ? false : true
        senderStackView?.isHidden = isStarredMessagePage == true ? false : true
        bubbleImageBottomView?.constant = isStarredMessagePage == true ? 10 : 3
    }

    func setUserProfileInfo(message: ChatMessage?,isBlocked: Bool) {
        var getProfileDetails = ChatManager.profileDetaisFor(jid: message?.chatUserJid ?? "")
        var senderProfileDetails = ChatManager.profileDetaisFor(jid: message?.senderUserJid ?? "")
        senderProfileImage?.makeRounded()
        senderToLabel?.text = message?.messageChatType == .singleChat ? "You" : getUserName(jid : getProfileDetails?.jid ?? "" ,name: getProfileDetails?.name ?? "", nickName: getProfileDetails?.nickName ?? "", contactType: getProfileDetails?.contactType ?? .local)
        senderTextLabel?.text = getUserName(jid : senderProfileDetails?.jid ?? "" ,name: senderProfileDetails?.name ?? "", nickName: senderProfileDetails?.nickName ?? "", contactType: senderProfileDetails?.contactType ?? .local)
    
        let timeStamp =  message?.messageSentTime
        senderTimeLabel?.text = String(describing: DateFormatterUtility.shared.convertMillisecondsToSentTime(milliSeconds: timeStamp ?? 0.0))
        let contactColor = getColor(userName: getUserName(jid: senderProfileDetails?.jid ?? "",name: senderProfileDetails?.name ?? "", nickName: senderProfileDetails?.nickName ?? "", contactType: senderProfileDetails?.contactType ?? .local))
        setImage(imageURL: senderProfileDetails?.image ?? "", name: getUserName(jid: senderProfileDetails?.jid ?? "", name: senderProfileDetails?.name ?? "", nickName: senderProfileDetails?.nickName ?? "", contactType: senderProfileDetails?.contactType ?? .local), color: contactColor, chatType: senderProfileDetails?.profileChatType ?? .singleChat, jid: senderProfileDetails?.jid ?? "")
    }
    
    private func getisBlockedMe(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlockedMe ?? false
    }
    
    func setImage(imageURL: String, name: String, color: UIColor, chatType : ChatType,jid: String) {
        if !getisBlockedMe(jid: jid) || !(IS_LIVE && ENABLE_CONTACT_SYNC && ContactManager.shared.getUserProfileDetails(for: jid)?.isItSavedContact == false){
            senderProfileImage?.loadFlyImage(imageURL: imageURL, name: name, chatType: chatType, jid: jid)
        } else {
            senderProfileImage?.image = UIImage(named: ImageConstant.ic_profile_placeholder)!
        }
    }
    
 
    func getCellFor(_ message: ChatMessage?, at indexPath: IndexPath?,isPlaying: Bool,audioClosureCallBack : @escaping AudioCallBack,isShowForwardView: Bool?,isDeletedMessageSelected: Bool?, fromChat: Bool = false, isMessageSearch: Bool = false, searchText: String = "") -> AudioReceiver? {

        currentIndexPath = nil
        currentIndexPath = indexPath
        audioCallBack = audioClosureCallBack

        // Starred Messages
        favImageView?.isHidden =  message!.isMessageStarred ? false : true
        showHideForwardView(message: message, isShowForwardView: isShowForwardView, isDeletedMessageSelected: isDeletedMessageSelected)

        if selectedForwardMessage?.filter({$0.chatMessage.messageId == message?.messageId}).first?.isSelected == true {
            forwardImageView?.image = UIImage(named: "forwardSelected")
            forwardImageView?.isHidden = false
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 0.0)
        } else {
           // forwardImageView?.image = UIImage(named: "")
            forwardImageView?.isHidden = true
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
        }
        
        if message?.messageChatType == .groupChat {
            senderNameLabel?.text = ChatUtils.getGroupSenderName(messsage: message)
        } else {
            senderNameLabel?.isHidden = true
            senderNameContainer?.isHidden = true
        }
        
        if message?.mediaChatMessage?.mediaDownloadStatus == .downloaded && !(isShowForwardView ?? false) {
            fwdViw?.isHidden = false
            fwdBtn?.isHidden = false
            isAllowSwipe = true
        } else {
            fwdViw?.isHidden = true
            fwdBtn?.isHidden = true
            isAllowSwipe = true
        }
        
        if message?.mediaChatMessage?.audioType == AudioType.recording {
            audioReceiverImage?.image = UIImage(named: ImageConstant.ic_audio_recorded)
            audioReceiverImage?.backgroundColor = .clear
        } else {
            audioReceiverImage?.contentMode = .center
            audioReceiverImage?.image = UIImage(named: ImageConstant.ic_sender_audio)
            audioReceiverImage?.backgroundColor = Color.color_97A5C7
            audioReceiverImage?.layer.cornerRadius = (audioReceiverImage?.bounds.width ?? 0)/2
        }
        
        // Reply view elements and its data
       if(message?.isReplyMessage ?? false) {
           replyView?.isHidden = false
            let getReplymessage =  message?.replyParentChatMessage?.messageTextContent
           let replyMessage = FlyMessenger.getMessageOfId(messageId: message?.replyParentChatMessage?.messageId ?? "")
           if message?.replyParentChatMessage?.isMessageDeleted == true || message?.replyParentChatMessage?.isMessageRecalled == true || replyMessage == nil {
               replyTextLabel?.text = "Original message not available"
               mapView?.isHidden = true
           } else {
               mapView?.isHidden = true
               replyTextLabel?.attributedText = ChatUtils.getAttributedMessage(message: getReplymessage ?? "", searchText: searchText, isMessageSearch: isMessageSearch, isSystemBlue: false)
               if replyMessage?.mediaChatMessage != nil {
                   switch replyMessage?.mediaChatMessage?.messageType {
                   case .image:
                       messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderCamera" : "receiverCamera")
                       if let thumImage = message?.replyParentChatMessage?.mediaChatMessage?.mediaThumbImage {
                           let converter = ImageConverter()
                           let image =  converter.base64ToImage(thumImage)
                           mediaMessageImageView?.image = image
                           messageTypeIconView?.isHidden = false
                           replyTextLabel?.text = (!(message?.replyParentChatMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? message?.replyParentChatMessage?.mediaChatMessage?.mediaCaptionText : "Photo"
                       }
                       replyWithMediaCons?.isActive = true
                       replyWithOutMediaCons?.isActive = false
                   case .audio:
                       ChatUtils.setIconForAudio(imageView: messageTypeIcon, chatMessage: nil, replyParentMessage: message?.replyParentChatMessage)
                       let duration = Int(message?.replyParentChatMessage?.mediaChatMessage?.mediaDuration ?? 0)
                       replyTextLabel?.text = (!(message?.replyParentChatMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? message?.replyParentChatMessage?.mediaChatMessage?.mediaCaptionText : message?.replyParentChatMessage?.mediaChatMessage?.messageType.rawValue.capitalized.appending(" (\(duration.msToSeconds.minuteSecondMS))")
                       messageTypeIconView?.isHidden = false
                       replyWithMediaCons?.isActive = false
                       replyWithOutMediaCons?.isActive = true
                   case .video:
                       messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderVideo" : "video")
                       messageTypeIconView?.isHidden = false
                       if let thumImage = message?.replyParentChatMessage?.mediaChatMessage?.mediaThumbImage {
                           let converter = ImageConverter()
                           let image =  converter.base64ToImage(thumImage)
                           mediaMessageImageView?.image = image
                           replyTextLabel?.text = (!(message?.replyParentChatMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? message?.replyParentChatMessage?.mediaChatMessage?.mediaCaptionText : message?.replyParentChatMessage?.mediaChatMessage?.messageType.rawValue.capitalized
                       }
                       replyWithMediaCons?.isActive = true
                       replyWithOutMediaCons?.isActive = false
                   case .document:
                       messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "document" : "document")
                       replyTextLabel?.text = replyMessage?.mediaChatMessage?.mediaFileName.capitalized
                       checkFileType(url: replyMessage?.mediaChatMessage?.mediaFileUrl ?? "", typeImageView: mediaMessageImageView)
                       messageTypeIconView?.isHidden = false
                       replyWithMediaCons?.isActive = true
                       replyWithOutMediaCons?.isActive = false
                   default:
                       messageTypeIconView?.isHidden = true
                       replyWithMediaCons?.isActive = true
                       replyWithOutMediaCons?.isActive = false
                   }
                   
               } else if replyMessage?.locationChatMessage != nil {
                   mapView?.isHidden = false
                   replyTextLabel?.text = "Location"
                   mapView?.isUserInteractionEnabled = false
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "map" : "receivedMap")
                   messageTypeIconView?.isHidden = false
                   guard let latitude = message?.replyParentChatMessage?.locationChatMessage?.latitude else {
                       return nil
                   }
                   guard let longitude = message?.replyParentChatMessage?.locationChatMessage?.longitude  else {
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
                   replyWithMediaCons?.isActive = true
                   replyWithOutMediaCons?.isActive = false
               } else if replyMessage?.contactChatMessage != nil {
                   replyTextLabel?.attributedText = ChatUtils.setAttributeString(name: message?.replyParentChatMessage?.contactChatMessage?.contactName)
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderContact" : "receiverContact")
                   messageTypeIconView?.isHidden = false
                   replyWithMediaCons?.isActive = true
                   replyWithOutMediaCons?.isActive = false
               } else if replyMessage?.meetChatMessage != nil {
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "video_link" : "video_link")
                   replyTextLabel?.text = DateFormatterUtility.shared.getSchduleMeetingDate(date: replyMessage?.meetChatMessage?.scheduledDateTime ?? 0)
                   replyWithMediaCons?.isActive = true
                   mediaMessageImageView?.isHidden = false
                   mediaMessageImageView?.image = UIImage(named: "app_icon")
                   mediaMessageImageView?.contentMode = .center
                   replyWithMediaCons?.isActive = true
                   replyWithOutMediaCons?.isActive = false
               } else {
                   messageTypeIconView?.isHidden = true
                   replyWithMediaCons?.isActive = true
                   replyWithOutMediaCons?.isActive = false
               }
           }
        if(message?.replyParentChatMessage?.isMessageSentByMe ?? false) {
            replyUserLabel?.text = you.localized
        } else {
            replyUserLabel?.text = getUserName(jid: replyMessage?.senderUserJid ?? "" ,name: replyMessage?.senderUserName ?? "",
                                               nickName: replyMessage?.senderNickName ?? "", contactType: (replyMessage?.isDeletedUser ?? false) ? .deleted : (replyMessage?.isSavedContact ?? false) ? .live : .unknown)
        }
           ChatUtils.setDeletedReplyMessage(chatMessage: replyMessage, messageIconView: messageTypeIconView, messageTypeIcon: messageTypeIcon, replyTextLabel: replyTextLabel, mediaImageView: mediaMessageImageView, mediaImageViewWidthCons: nil, replyMessageIconWidthCons: nil, replyMessageIconHeightCons: nil)
    }
        else {
            replyView?.isHidden = true
        }
        
        ChatUtils.setReceiverBubbleBackground(imageView: bubbleImageView)
        
        self.message = message
        self.currentIndexPath = indexPath
        let duration = Int(message?.mediaChatMessage?.mediaDuration ?? 0)
            audioDuration?.text = FlyUtils.secondsToDurationInString(seconds:  Double(duration / 1000) )
        switch message?.mediaChatMessage?.mediaDownloadStatus {
        case .not_downloaded:
            download?.image = UIImage(named: ImageConstant.ic_download)
            download?.isHidden = false
            playImage?.isHidden = true
            nicoProgressBar?.isHidden = true
            playBtn?.isHidden = true
            downloadButton?.isHidden = false
            newProgressBar.removeFromSuperview()
            slider?.isUserInteractionEnabled = false
        case .failed:
            download?.image = UIImage(named: ImageConstant.ic_download)
            download?.isHidden = false
            playImage?.isHidden = true
            nicoProgressBar?.isHidden = true
            playBtn?.isHidden = true
            downloadButton?.isHidden = false
            newProgressBar.removeFromSuperview()
            slider?.isUserInteractionEnabled = false
        case .downloading:
            download?.image = UIImage(named: ImageConstant.ic_download_cancel)
            playBtn?.isHidden = true
            downloadButton?.isHidden = false
            download?.isHidden = false
            playImage?.isHidden = true
            nicoProgressBar?.isHidden = false
            if nicoProgressBar.subviews.isEmpty{
                self.nicoProgressBar.addSubview(self.newProgressBar)
            }
            newProgressBar.setProg(per: CGFloat(message?.mediaChatMessage?.mediaProgressStatus ?? 0))
            slider?.isUserInteractionEnabled = false
        case .downloaded:
            playImage?.image = isPlaying ? UIImage(named: ImageConstant.ic_audio_pause_gray) : UIImage(named: ImageConstant.ic_play_dark)
            download?.isHidden = true
            playBtn?.isHidden = false
            downloadButton?.isHidden = true
            playImage?.isHidden = false
            nicoProgressBar?.isHidden = true
            newProgressBar.removeFromSuperview()
            slider?.isUserInteractionEnabled = true
        default:
            download?.image = UIImage(named: ImageConstant.ic_download)
            download?.isHidden = false
            playImage?.isHidden = true
            playBtn?.isHidden = true
            downloadButton?.isHidden = false
            nicoProgressBar?.isHidden = true
            newProgressBar.removeFromSuperview()
            slider?.isUserInteractionEnabled = false
        }
        guard let timeStamp =  message?.messageSentTime else {
            return self
        }
        self.recvTime?.text = DateFormatterUtility.shared.currentMillisecondsToLocalTime(milliSec: timeStamp)

        return self
    }
    
    func stopDisplayLink() {
        updater?.invalidate()
        updater = nil
     }
    
    @IBAction func sliderButtonAction(_ sender: Any) {
        print("sliderValueChanged \(slider?.value ?? 0)")
                if audioCallBack != nil {
                    audioCallBack!(slider?.value ?? 0)
                }
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
           playImage?.image = UIImage(named: ImageConstant.ic_play_dark)
        player.stop()
        stopDisplayLink()
}
    
    func showHideForwardView(message: ChatMessage?,isShowForwardView: Bool?,isDeletedMessageSelected: Bool?) {
        if isDeletedMessageSelected ?? false {
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
    
    func startDownload() {
        DispatchQueue.main.async { [weak self] in
            guard let self else {return}
            self.download?.image = UIImage(named: ImageConstant.ic_download_cancel)
            self.playBtn?.isHidden = true
            self.downloadButton?.isHidden = false
            self.download?.isHidden = false
            self.playImage?.isHidden = true
            self.slider?.isUserInteractionEnabled = false
            if self.nicoProgressBar.subviews.isEmpty{
                self.nicoProgressBar.addSubview(self.newProgressBar)
            }
            self.newProgressBar.setProg(per: CGFloat(self.message?.mediaChatMessage?.mediaProgressStatus ?? 0))
        }
    }
    
    func stopDownload() {
        DispatchQueue.main.async { [weak self] in
            self?.download?.image = UIImage(named: ImageConstant.ic_download)
            self?.download?.isHidden = false
            self?.playImage?.isHidden = true
            self?.newProgressBar.removeFromSuperview()
            self?.playBtn?.isHidden = true
            self?.downloadButton?.isHidden = false
            self?.slider?.isUserInteractionEnabled = false
        }
    }
}
