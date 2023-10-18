//
//  CHatTextView.swift
//  MirrorflyUIkit
//
//  Created by User on 23/08/21.
//

import UIKit
import MapKit
import GoogleMaps
import MirrorFlySDK

class ChatTextView: UIView, UITextViewDelegate {
    @IBOutlet weak var messageTypeView: UIView?
    @IBOutlet weak var mediaMessageImageView: UIImageView?
    @IBOutlet weak var messageTypeLabel: UILabel?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var closeButton: UIButton?
    @IBOutlet weak var messageTypeImage: UIImageView?
    @IBOutlet weak var closeView: UIView?
    @IBOutlet weak var contentView: UIView?
    @IBOutlet weak var innerView: UIView?
    @IBOutlet weak var closeImage: UIImageView?
    @IBOutlet weak var messageTypeWidthCons: NSLayoutConstraint?
    @IBOutlet weak var spacierView: UIView?
    @IBOutlet weak var mapView: GMSMapView?
    @IBOutlet weak var contactNameLabel: UILabel?
    @IBOutlet weak var cannotSendMessageView: UIView?
    @IBOutlet weak var blockedMessageLabel: UILabel!
    
    @IBOutlet weak var audioHiddenRecordButton: UIButton!
    @IBOutlet weak var audioRecordView: UIView?
    @IBOutlet weak var audioRecordButton: UIButton!
    @IBOutlet weak var audioRecordingInfoView: UIView!
    @IBOutlet weak var audioDurationMicIcon: UIButton!
    @IBOutlet weak var audioDurationLabel: UILabel!
    @IBOutlet weak var audioCancelButton: UIButton!
    @IBOutlet weak var audioSlideCancelView: UIStackView!
    @IBOutlet weak var audioSendButton: UIButton!
    @IBOutlet weak var audioDurationLeading: NSLayoutConstraint!
    @IBOutlet weak var audioDurionMicLeading: NSLayoutConstraint!
    @IBOutlet weak var audioSlideViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var audioButton: UIButton!
    @IBOutlet weak var audioSlideViewWidth: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupUI() {
        innerView?.layer.cornerRadius = 3.0
        innerView?.backgroundColor = Color.previewInnerBgColor
        contentView?.backgroundColor = Color.previewContentBgColor
        contentView?.roundCorners(corners: [.topRight,.bottomRight], radius: 3.0)
        closeView?.makeCircleView(borderColor: UIColor.white.cgColor, borderWidth: 1.0)
    }
    
    func setSenderReceiverMessage(message: ChatMessage, contactType : ContactType =  .unknown) {
        mapView?.isHidden = true
        contactNameLabel?.isHidden = true
        titleLabel?.text = message.isMessageSentByMe ? "You" : getUserName(jid: message.senderUserJid, name: message.senderUserName, nickName: message.senderNickName, contactType: contactType)
        messageTypeImage?.isHidden = message.messageType == .text || message.isMessageRecalled == true ? true : false
        if message.messageType == .image || message.messageType == .video || message.messageType == .location {
            let thumbImage = message.mediaChatMessage?.mediaThumbImage ?? ""
            if let mediaMessage = ChatManager.getMessageOfId(messageId: message.messageId) {
                if mediaMessage.isMessageSentByMe {
                    if mediaMessage.mediaChatMessage?.mediaUploadStatus == .uploaded {
                        if let localPath = mediaMessage.mediaChatMessage?.mediaFileName {
                            if let directoryURL: URL = FlyUtils.getGroupContainerIDPath() {
                                let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Image", isDirectory: true)
                                let fileURL: URL = folderPath.appendingPathComponent(localPath)
                                if FileManager.default.fileExists(atPath: fileURL.relativePath) {
                                    do {
                                        let data = try Data(contentsOf: fileURL)
                                        let image = UIImage(data: data)
                                        mediaMessageImageView?.backgroundColor = .white
                                        mediaMessageImageView?.image = image
                                    } catch let error {
                                        print("Error loading image : \(error)")
                                    }
                                } else {
                                    if let thumImage = message.mediaChatMessage?.mediaThumbImage {
                                        ChatUtils.setThumbnail(imageContainer: mediaMessageImageView ?? UIImageView(), base64String: thumImage)
                                    }
                                }
                            }
                        }
                    } else {
                        let converter = ImageConverter()
                        let image =  converter.base64ToImage(thumbImage)
                        mediaMessageImageView?.image = image
                    }
                } else {
                    if mediaMessage.mediaChatMessage?.mediaDownloadStatus == .downloaded {
                        if let localPath = mediaMessage.mediaChatMessage?.mediaFileName {
                            if let directoryURL: URL = FlyUtils.getGroupContainerIDPath() {
                                let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Image", isDirectory: true)
                                let fileURL: URL = folderPath.appendingPathComponent(localPath)
                                if FileManager.default.fileExists(atPath: fileURL.relativePath) {
                                    do {
                                        let data = try Data(contentsOf: fileURL)
                                        let image = UIImage(data: data)
                                        mediaMessageImageView?.backgroundColor = .white
                                        mediaMessageImageView?.image = image
                                    } catch let error {
                                        print("Error loading image : \(error)")
                                    }
                                }else {
                                    if let thumImage = message.mediaChatMessage?.mediaThumbImage {
                                        ChatUtils.setThumbnail(imageContainer: mediaMessageImageView ?? UIImageView(), base64String: thumImage)
                                    }
                                }
                            }
                        }
                    } else {
                        let converter = ImageConverter()
                        let image =  converter.base64ToImage(thumbImage)
                        mediaMessageImageView?.image = image
                    }
                }
            }
            //mediaMessageImageView?.contentMode = .redraw
            mediaMessageImageView?.isHidden = false
        } else {
            mediaMessageImageView?.isHidden = true
        }
        if message.isMessageDeleted == true || message.isMessageRecalled == true {
            mediaMessageImageView?.isHidden = true
        }
        
        let isMessageSentByMe = message.isMessageSentByMe
        let mentionedUsers = message.mentionedUsersIds
        
        if message.isMessageRecalled == true || message.isMessageDeleted == true {
            messageTypeLabel?.text = "Original message not available"
            messageTypeWidthCons?.constant = 0
            spacierView?.isHidden = true
        } else {
            switch message.messageType {
            case .text:
                if !mentionedUsers.isEmpty {
                    let replyMessage = message.messageTextContent
                    messageTypeLabel?.text = ChatUtils.getMentionTextContent(message: replyMessage, uiLabel: messageTypeLabel, isMessageSentByMe: isMessageSentByMe, mentionedUsers: mentionedUsers).string
                } else {
                    messageTypeLabel?.text = message.messageTextContent
                }
                messageTypeWidthCons?.constant = 0
                spacierView?.isHidden = true
            case .image:
                if !mentionedUsers.isEmpty, let replyMessage = message.mediaChatMessage?.mediaCaptionText, replyMessage.isNotEmpty {
                    messageTypeLabel?.text = ChatUtils.getMentionTextContent(message: replyMessage, uiLabel: messageTypeLabel, isMessageSentByMe: isMessageSentByMe, mentionedUsers: mentionedUsers).string
                } else {
                    let replyMessage = message.mediaChatMessage?.mediaCaptionText
                    messageTypeLabel?.text = !(replyMessage?.isEmpty ?? false) ? message.mediaChatMessage?.mediaCaptionText : "Photo"
                }
                messageTypeWidthCons?.constant = 13
                spacierView?.isHidden = false
            case .audio:
                let duration = Int(message.mediaChatMessage?.mediaDuration ?? 0)
                messageTypeLabel?.text =  "\(duration.msToSeconds.minuteSecondMS) Audio"
                messageTypeWidthCons?.constant = 13
                spacierView?.isHidden = false
            case .contact:
                let messageType = message.messageType.rawValue.capitalized
                messageTypeLabel?.text =  message.isMessageSentByMe ? "\(message.messageType.rawValue.capitalized): " : "\(messageType): "
                contactNameLabel?.isHidden = false
                contactNameLabel?.text = message.contactChatMessage?.contactName
                messageTypeWidthCons?.constant = 13
                spacierView?.isHidden = false
            case .document:
                let mediaFileName = message.mediaChatMessage?.mediaFileName.capitalized
                messageTypeLabel?.text = mediaFileName
                messageTypeWidthCons?.constant = 13
                spacierView?.isHidden = false
            case .video:
                let replyMessage = message.mediaChatMessage?.mediaCaptionText
                messageTypeLabel?.text = !(replyMessage?.isEmpty ?? false) ? message.mediaChatMessage?.mediaCaptionText : message.messageType.rawValue.capitalized
                messageTypeWidthCons?.constant = 12
                spacierView?.isHidden = false
            case .meet:
                messageTypeLabel?.text = DateFormatterUtility.shared.getSchduleMeetingDate(date: message.meetChatMessage?.scheduledDateTime ?? 0)
                messageTypeWidthCons?.constant = 0
                spacierView?.isHidden = true
            default:
                messageTypeLabel?.text = message.messageType.rawValue.capitalized
                messageTypeWidthCons?.constant = 12
                spacierView?.isHidden = false
            }
        }
       
            switch message.messageType {
            case .image:
                messageTypeImage?.image = UIImage(named: "senderCamera")
            case .video:
                messageTypeImage?.image = UIImage(named: "senderVideo")
            case .audio:
                if message.mediaChatMessage?.audioType == AudioType.file {
                    messageTypeImage?.image = UIImage(named: "audio")
                } else {
                    messageTypeImage?.image = UIImage(named: ImageConstant.ic_audio_filled)
                }
            case .contact:
                messageTypeImage?.image = UIImage(named: "senderContact")
            case .location:
                messageTypeImage?.image = UIImage(named: "map")
            case .meet:
                messageTypeImage?.image = UIImage(named: "meet")
            case .document:
                checkFileType(url: message.mediaChatMessage?.mediaLocalStoragePath ?? "", typeImageView: messageTypeImage)
            default:
                break
            }
            
            if message.locationChatMessage != nil {
                if message.isMessageDeleted == true || message.isMessageRecalled == true {
                    mapView?.isHidden = true
                } else {
                    mapView?.isHidden = false
                }
                
                guard let latitude = message.locationChatMessage?.latitude else {
                    return
                }
                guard let longitude = message.locationChatMessage?.longitude  else {
                    return
                }
                
                mapView?.camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 16.0, bearing: 360.0, viewingAngle: 15.0)
                
                DispatchQueue.main.async { [self] in
                    // 2. Perform UI Operations.
                    let position = CLLocationCoordinate2DMake(latitude,longitude)
                    let marker = GMSMarker(position: position)
                    marker.map = mapView
                }
            }
    }
}

