//
//  ImageSender.swift
//  MirrorflyUIkit
//
//  Created by User on 02/09/21.
//

import UIKit
import MirrorFlySDK
import NicoProgress
import GoogleMaps
import MapKit

protocol ShowMailComposeDelegate {
    func showMailComposer(mail: String)
}

class SenderImageCell: BaseTableViewCell {
    @IBOutlet weak var imgHight: NSLayoutConstraint?
    @IBOutlet weak var uploadView: UIView?
    @IBOutlet weak var retryLab: UILabel?
    @IBOutlet weak var retryButton: UIButton?
    
    @IBOutlet weak var overlayImage: UIImageView?
    @IBOutlet weak var captionTop: NSLayoutConstraint?
    @IBOutlet weak var cellView: UIView?
    @IBOutlet weak var imageContainer: UIImageView?
    @IBOutlet weak var sentTime: UILabel?
    @IBOutlet weak var msgStatus: UIImageView?
    @IBOutlet weak var fwdView: UIView?
    @IBOutlet weak var fwdButton: UIButton?
    @IBOutlet weak var process: UIImageView?
    @IBOutlet weak var nicoProgressBar: UIView!
    @IBOutlet weak var progressView: UIView?
    @IBOutlet weak var caption: UILabel?
    @IBOutlet weak var captionBottomCons: NSLayoutConstraint?
    
    @IBOutlet weak var downloadButton: UIButton?
    @IBOutlet weak var downloadView: UIView?
    // Reply View
    @IBOutlet weak var bubbleImageView: UIImageView?
    @IBOutlet weak var replyTextLabel: UILabel?
    @IBOutlet weak var userLabel: UILabel?
    @IBOutlet weak var messageTypeView: UIView?
    @IBOutlet weak var messageTypeIcon: UIImageView?
    @IBOutlet weak var mediaImageView: UIImageView?
    @IBOutlet weak var replyVuew: UIView?
    @IBOutlet weak var imageContainerTopCons: NSLayoutConstraint?
    @IBOutlet weak var chatLocationMapView: GMSMapView?
    @IBOutlet weak var replyWithMediaCons: NSLayoutConstraint?
    @IBOutlet weak var replyWithoutMediaCons: NSLayoutConstraint?
    
    // Forward Outlet
    @IBOutlet weak var forwardImageView: UIImageView?
    @IBOutlet weak var forwardView: UIView?
    @IBOutlet weak var forwardLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var forwardButton: UIButton?
    var composeMailDelegate: ShowMailComposeDelegate?
    var sendMediaMessages: [ChatMessage]? = []
    var newProgressBar: ProgressBar!
    var imageGeasture: UITapGestureRecognizer!
    var isUploading: Bool? = false
    var message : ChatMessage?
    var selectedForwardMessage: [SelectedMessages]? = []
    var refreshDelegate: RefreshBubbleImageViewDelegate? = nil
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupUI()
    }
    func setupUI() {
        retryLab?.text = retry
        imageGeasture = UITapGestureRecognizer()
        imageContainer?.addGestureRecognizer(imageGeasture)
        caption?.font = UIFont.font12px_appRegular()
        progressView?.layer.cornerRadius = 5
        uploadView?.layer.cornerRadius = 5
        cellView?.roundCorners(corners: [.topLeft, .bottomLeft, .topRight], radius: 5.0)
        imageContainer?.layer.cornerRadius = 5.0
        imageContainer?.clipsToBounds = true
        newProgressBar = ProgressBar(frame: CGRect(x: 0, y: 0, width: nicoProgressBar.frame.width, height: nicoProgressBar.frame.height))
        newProgressBar.primaryColor = .white
        newProgressBar.bgColor = .clear
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
    
    func getCellFor(_ message: ChatMessage?, at indexPath: IndexPath?,isShowForwardView: Bool?) -> SenderImageCell? {
        currentIndexPath = nil
        currentIndexPath = indexPath
        if let captionTxt = message?.mediaChatMessage?.mediaCaptionText, captionTxt != "" {
            captionTop?.constant = 7
            caption?.attributedText = processTextMessage(message: captionTxt, uiLabel: caption ?? UILabel())
            overlayImage?.isHidden = true
            captionBottomCons?.constant = 12
           
        }else{
            captionTop?.constant = 5
            caption?.text = ""
            overlayImage?.isHidden = false
            captionBottomCons?.constant = 1
           
        }
        // Forward view elements and its data
        forwardView?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaUploadStatus == .uploaded) ? false : true
        forwardLeadingCons?.constant = (isShowForwardView == true && message?.mediaChatMessage?.mediaUploadStatus == .uploaded) ? 20 : 0
        forwardButton?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaUploadStatus == .uploaded) ? false : true
    
        if selectedForwardMessage?.filter({$0.chatMessage.messageId == message?.messageId}).first?.isSelected == true {
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 0.0)
            forwardImageView?.image = UIImage(named: "forwardSelected")
            forwardImageView?.isHidden = false
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 0.0)
        } else {
           // forwardImageView?.image = UIImage(named: "")
            forwardImageView?.isHidden = true
            forwardButton?.isSelected = !(forwardButton?.isSelected ?? false)
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
        }
        if message?.isCarbonMessage == true {
            if  (message?.mediaChatMessage?.mediaDownloadStatus == .not_downloaded || message?.mediaChatMessage?.mediaDownloadStatus == .failed || message?.mediaChatMessage?.mediaDownloadStatus == .downloading || message?.messageStatus == .notAcknowledged || message?.messageStatus == .sent || isShowForwardView == true) {
                fwdView?.isHidden = true
                fwdButton?.isHidden = true
                isAllowSwipe = false
            } else {
                fwdView?.isHidden = false
                fwdButton?.isHidden = false
                isAllowSwipe = true
            }
        } else {
            if  (message?.mediaChatMessage?.mediaUploadStatus == .not_uploaded  || message?.mediaChatMessage?.mediaUploadStatus == .failed || message?.mediaChatMessage?.mediaUploadStatus == .uploading || message?.messageStatus == .notAcknowledged || message?.messageStatus == .sent || isShowForwardView == true) {
                fwdView?.isHidden = true
                fwdButton?.isHidden = true
                isAllowSwipe = false
            } else {
                fwdView?.isHidden = false
                fwdButton?.isHidden = false
                isAllowSwipe = true
            }
        }
        
        // Reply view elements and its data
       if(message!.isReplyMessage) {
            replyVuew?.isHidden = false
            let getReplymessage =  message?.replyParentChatMessage?.messageTextContent
           let replyMessage = FlyMessenger.getMessageOfId(messageId: message?.replyParentChatMessage?.messageId ?? "")
           imageContainerTopCons?.constant = 3
           messageTypeView?.isHidden = true
           chatLocationMapView?.isHidden = true
           replyTextLabel?.text = getReplymessage
           if replyMessage?.mediaChatMessage != nil {
               messageTypeView?.isHidden = false
               switch replyMessage?.mediaChatMessage?.messageType {
               case .image:
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderCamera" : "receiverCamera")
                   if let thumImage = replyMessage?.mediaChatMessage?.mediaThumbImage {
                       let converter = ImageConverter()
                       let image =  converter.base64ToImage(thumImage)
                       mediaImageView?.image = image
                       mediaImageView?.isHidden = false
                       replyTextLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : "Photo"
                   }
                   replyWithMediaCons?.isActive = true
                   replyWithoutMediaCons?.isActive = false
               case .audio:
                   ChatUtils.setIconForAudio(imageView: messageTypeIcon, chatMessage: message)
                   let duration = Int(replyMessage?.mediaChatMessage?.mediaDuration ?? 0)
                   replyTextLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized.appending(" (\(duration.msToSeconds.minuteSecondMS))")
                   mediaImageView?.isHidden = true
                   replyWithMediaCons?.isActive = false
                   replyWithoutMediaCons?.isActive = true
               case .video:
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderVideo" : "video")
                   if let thumImage = replyMessage?.mediaChatMessage?.mediaThumbImage {
                       let converter = ImageConverter()
                       let image =  converter.base64ToImage(thumImage)
                       mediaImageView?.image = image
                       mediaImageView?.isHidden = false
                       replyTextLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized
                   }
                   replyWithMediaCons?.isActive = true
                   replyWithoutMediaCons?.isActive = false
               case .document:
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "document" : "document")
                   replyTextLabel?.text = replyMessage?.mediaChatMessage?.mediaFileName.capitalized
                   replyWithMediaCons?.isActive = true
                   replyWithoutMediaCons?.isActive = false
                   checkFileType(url: replyMessage?.mediaChatMessage?.mediaFileUrl ?? "", typeImageView: mediaImageView)
                   mediaImageView?.isHidden = false
               default:
                   messageTypeView?.isHidden = true
                   replyWithMediaCons?.isActive = false
                   replyWithoutMediaCons?.isActive = true
               }
               
           } else if replyMessage?.locationChatMessage != nil {
               chatLocationMapView?.isHidden = false
               replyTextLabel?.text = "Location"
               messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "map" : "receivedMap")
               guard let latitude = replyMessage?.locationChatMessage?.latitude else {
                   return nil
               }
               guard let longitude = replyMessage?.locationChatMessage?.longitude  else {
                   return nil
               }
               replyWithMediaCons?.isActive = true
               replyWithoutMediaCons?.isActive = false
               chatLocationMapView?.isUserInteractionEnabled = false
               chatLocationMapView?.camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 16.0, bearing: 360.0, viewingAngle: 15.0)
      
               DispatchQueue.main.async
               { [self] in
                   // 2. Perform UI Operations.
                   let position = CLLocationCoordinate2DMake(latitude,longitude)
                   let marker = GMSMarker(position: position)
                   marker.map = chatLocationMapView
               }
               messageTypeView?.isHidden = false
           } else if replyMessage?.contactChatMessage != nil {
                   replyTextLabel?.attributedText = ChatUtils.setAttributeString(name: replyMessage?.contactChatMessage?.contactName)
               messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderContact" : "receiverContact")
               messageTypeView?.isHidden = false
               replyWithMediaCons?.isActive = false
               replyWithoutMediaCons?.isActive = true
           } else {
               mediaImageView?.isHidden = true
               replyWithMediaCons?.isActive = false
               replyWithoutMediaCons?.isActive = true
           }
           let isSentByMe = replyMessage?.isMessageSentByMe ?? false
        if isSentByMe {
            userLabel?.text = you.localized
        }
        else {
            userLabel?.text = getUserName(jid: replyMessage?.senderUserJid ?? "" ,name: replyMessage?.senderUserName ?? "",
                                          nickName: replyMessage?.senderNickName ?? "", contactType: (replyMessage?.isDeletedUser ?? false) ? .deleted : (replyMessage?.isSavedContact ?? false) ? .live : .unknown)
        }
    }
        else {
            imageContainerTopCons?.constant = 0
            replyVuew?.isHidden = true
        }
        
        ChatUtils.setSenderBubbleBackground(imageView: bubbleImageView)
        
        self.message = message
        if message?.isCarbonMessage == false {
            if message?.mediaChatMessage?.mediaUploadStatus == .not_uploaded {
                if let thumbImage = message?.mediaChatMessage?.mediaThumbImage {
                    ChatUtils.setThumbnail(imageContainer: imageContainer ?? UIImageView(), base64String: thumbImage)
                    if ((sendMediaMessages?.count ?? 0) > 0 && (sendMediaMessages?.filter({$0.messageId == message?.messageId}).count ?? 0) > 0) {
                        print("sender",sendMediaMessages?.count)
                        nicoProgressBar.addSubview(newProgressBar)
                        uploadView?.isHidden = true
                        progressView?.isHidden = false
                        retryButton?.isHidden = false
                    } else {
                        print("sender",sendMediaMessages?.count)
                        newProgressBar.removeFromSuperview()
                        retryButton?.isHidden = false
                        uploadView?.isHidden = false
                        progressView?.isHidden = true
                    }
                }
            } else if message?.mediaChatMessage?.mediaUploadStatus == .uploading {
                if let thumbImage = message?.mediaChatMessage?.mediaThumbImage {
                    ChatUtils.setThumbnail(imageContainer: imageContainer ?? UIImageView(), base64String: thumbImage)
                    nicoProgressBar.addSubview(newProgressBar)
                    progressView?.isHidden = false
                    uploadView?.isHidden = true
                    retryButton?.isHidden = false
                }
            } else if message?.mediaChatMessage?.mediaUploadStatus == .uploaded {
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
                } else {
                    if let thumbImage = message?.mediaChatMessage?.mediaThumbImage {
                        ChatUtils.setThumbnail(imageContainer: imageContainer ?? UIImageView(), base64String: thumbImage)
                    }
                }
                retryButton?.isHidden = true
                newProgressBar.removeFromSuperview()
                progressView?.isHidden = true
                uploadView?.isHidden = true
            } else {
                if let thumbImage = message?.mediaChatMessage?.mediaThumbImage {
                    ChatUtils.setThumbnail(imageContainer: imageContainer ?? UIImageView(), base64String: thumbImage)
                    newProgressBar.removeFromSuperview()
                    progressView?.isHidden = true
                    retryButton?.isHidden = true
                    uploadView?.isHidden = true
                }
            }
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
            } else {
                if let thumbImage = message?.mediaChatMessage?.mediaThumbImage {
                    ChatUtils.setThumbnail(imageContainer: imageContainer ?? UIImageView(), base64String: thumbImage)
                }
            }
        } else {
            if message?.mediaChatMessage?.mediaDownloadStatus == .not_downloaded || message?.mediaChatMessage?.mediaDownloadStatus == .failed || message?.messageStatus == .sent {
                if let thumbImage = message?.mediaChatMessage?.mediaThumbImage {
                    ChatUtils.setThumbnail(imageContainer: imageContainer ?? UIImageView(), base64String: thumbImage)
                    if ((sendMediaMessages?.count ?? 0) > 0 && (sendMediaMessages?.filter({$0.messageId == message?.messageId}).count ?? 0) > 0) {
                        print("sender",sendMediaMessages?.count)
                        nicoProgressBar.addSubview(newProgressBar)
                        uploadView?.isHidden = true
                        progressView?.isHidden = false
                        retryButton?.isHidden = false
                    } else {
                        print("sender",sendMediaMessages?.count)
                        newProgressBar.removeFromSuperview()
                        retryButton?.isHidden = false
                        uploadView?.isHidden = false
                        progressView?.isHidden = true
                    }
                }
            } else if message?.mediaChatMessage?.mediaDownloadStatus == .downloading {
                if let thumbImage = message?.mediaChatMessage?.mediaThumbImage {
                    ChatUtils.setThumbnail(imageContainer: imageContainer ?? UIImageView(), base64String: thumbImage)
                    nicoProgressBar.addSubview(newProgressBar)
                    progressView?.isHidden = false
                    uploadView?.isHidden = true
                    retryButton?.isHidden = false
                }
            } else if message?.mediaChatMessage?.mediaDownloadStatus == .downloaded {
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
                } else {
                    if let thumbImage = message?.mediaChatMessage?.mediaThumbImage {
                        ChatUtils.setThumbnail(imageContainer: imageContainer ?? UIImageView(), base64String: thumbImage)
                    }
                }
                retryButton?.isHidden = true
                newProgressBar?.removeFromSuperview()
                progressView?.isHidden = true
                uploadView?.isHidden = true
            } else {
                if let thumbImage = message?.mediaChatMessage?.mediaThumbImage {
                    ChatUtils.setThumbnail(imageContainer: imageContainer ?? UIImageView(), base64String: thumbImage)
                    newProgressBar?.removeFromSuperview()
                    progressView?.isHidden = true
                    retryButton?.isHidden = true
                    uploadView?.isHidden = true
                }
            }
        }
            let status = message?.messageStatus
            if status == .acknowledged || status == .received || status == .delivered || status == .seen {
                uploadView?.isHidden = true
                progressView?.isHidden = true
                newProgressBar?.removeFromSuperview()
                retryButton?.isHidden = true
            }
       

        switch message?.messageStatus {
        case .notAcknowledged:
            msgStatus?.image = UIImage(named: ImageConstant.ic_hour)
            msgStatus?.accessibilityLabel = notAcknowledged.localized
        case .sent:
            msgStatus?.image = UIImage(named: ImageConstant.ic_hour)
            msgStatus?.accessibilityLabel = sent.localized
        case .acknowledged:
            msgStatus?.image = UIImage(named: ImageConstant.ic_sent)
            msgStatus?.accessibilityLabel = acknowledged.localized
        case .delivered:
            msgStatus?.image = UIImage(named: ImageConstant.ic_delivered)
           msgStatus?.accessibilityLabel = delivered.localized
        case .seen:
            msgStatus?.image = UIImage(named: ImageConstant.ic_seen)
            msgStatus?.accessibilityLabel = seen.localized
        case .received:
            msgStatus?.image = UIImage(named: ImageConstant.ic_delivered)
            msgStatus?.accessibilityLabel = delivered.localized
        default:
            msgStatus?.image = UIImage(named: ImageConstant.ic_hour)
            msgStatus?.accessibilityLabel = notAcknowledged.localized
        }
        // Message time
        guard let timeStamp =  message?.messageSentTime else {
            return self
        }
        sentTime?.text = DateFormatterUtility.shared.currentMillisecondsToLocalTime(milliSec: timeStamp)
        self.layoutIfNeeded()
        self.layoutSubviews()
        return self
    }
    
    func setImageCell(_ message: ChatMessage?) {
        switch message?.mediaChatMessage?.mediaUploadStatus {
        case .not_uploaded:
            progressView?.isHidden = false
            nicoProgressBar.addSubview(newProgressBar)
            retryButton?.isHidden = false
            uploadView?.isHidden = true
        case .uploading:
            progressView?.isHidden = false
            nicoProgressBar.addSubview(newProgressBar)
            retryButton?.isHidden = false
            uploadView?.isHidden = true
        case .uploaded:
            progressView?.isHidden = false
            nicoProgressBar.addSubview(newProgressBar)
            retryButton?.isHidden = false
            uploadView?.isHidden = true
        default:
           break
        }
    }
    
    func processTextMessage(message : String, uiLabel : UILabel) -> NSMutableAttributedString? {
        var attributedString : NSMutableAttributedString?
        
        if !message.isEmpty {
            attributedString = NSMutableAttributedString(string: message)
            let gestureRecognizer = UITapGestureRecognizer()
            let textArray = message.trim().split(separator: " ")
            
            
            for (index, tempText) in textArray.enumerated() {
                print("processTextMessage index \(index) item \(tempText)")
                print("processTextMessage tempText \(tempText)")
                 let text = String(tempText).trim()
                 if text.isNumber && text.count >= 6 && text.count <= 13 {
                     print("processTextMessage isNumber \(tempText)")
                     let numberRange = (message as NSString).range(of: text)
                     attributedString?.addAttribute(NSAttributedString.Key.underlineStyle,value: NSUnderlineStyle.single.rawValue, range: numberRange)
                     gestureRecognizer.view?.isUserInteractionEnabled = true
                     gestureRecognizer.addTarget(self, action: #selector(didTapTextLabel(sender:)))
                     uiLabel.addGestureRecognizer(gestureRecognizer)
                 } else if text.trim().verifyisUrl(urlString: text) {
                     print("processTextMessage text.isURL \(tempText)")
                     let urlRange = (message as NSString).range(of: text)
                     attributedString?.addAttribute(NSAttributedString.Key.underlineStyle,value: NSUnderlineStyle.single.rawValue, range: urlRange)
                     gestureRecognizer.view?.isUserInteractionEnabled = true
                     gestureRecognizer.addTarget(self, action: #selector(didTapTextLabel(sender:)))
                     uiLabel.addGestureRecognizer(gestureRecognizer)
                 } else if text.trim().isValidEmail(email: text) {
                     let urlRange = (message as NSString).range(of: text)
                        attributedString?.addAttribute(NSAttributedString.Key.underlineStyle,value: NSUnderlineStyle.single.rawValue, range: urlRange)
                     gestureRecognizer.view?.isUserInteractionEnabled = true
                     gestureRecognizer.addTarget(self, action: #selector(didTapTextLabel(sender:)))
                     uiLabel.addGestureRecognizer(gestureRecognizer)
                 }
                 
                 print("processTextMessage After else \(tempText)")
            }
            
            for tempText in textArray {
                let text = String(tempText)
                if text.isNumber && text.count >= 6 && text.count <= 13 {
                    let numberRange = (message as NSString).range(of: text)
                    attributedString?.addAttribute(NSAttributedString.Key.underlineStyle,value: NSUnderlineStyle.single.rawValue, range: numberRange)
                    gestureRecognizer.view?.isUserInteractionEnabled = true
                    gestureRecognizer.addTarget(self, action: #selector(didTapTextLabel(sender:)))
                    uiLabel.addGestureRecognizer(gestureRecognizer)
                } else if text.verifyisUrl(urlString: text) {
                    if text.isURL {
                        let urlRange = (message as NSString).range(of: text)
                        attributedString?.addAttribute(NSAttributedString.Key.underlineStyle,value: NSUnderlineStyle.single.rawValue, range: urlRange)
                        gestureRecognizer.view?.isUserInteractionEnabled = true
                        gestureRecognizer.addTarget(self, action: #selector(didTapTextLabel(sender:)))
                        uiLabel.addGestureRecognizer(gestureRecognizer)
                    }
                } else if text.isValidEmail(email: text) {
                    let urlRange = (message as NSString).range(of: text)
                    attributedString?.addAttribute(NSAttributedString.Key.underlineStyle,value: NSUnderlineStyle.single.rawValue, range: urlRange)
                    gestureRecognizer.view?.isUserInteractionEnabled = true
                    gestureRecognizer.addTarget(self, action: #selector(didTapTextLabel(sender:)))
                    uiLabel.addGestureRecognizer(gestureRecognizer)
                }
            }
        } else {
            attributedString = NSMutableAttributedString(string: message)
        }
        return attributedString
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
                        
                    } else if text.verifyisUrl(urlString: text) {
                        let textRange = (tempName as NSString).range(of: text)
                        if(sender.didTapAttributedTextInLabel(label: textUILabel, inRange: textRange)) {
                            print("didTapTextLabel isURL \(text)")
                            AppUtils.shared.openURLInBrowser(urlString: text)
                            break
                        }
                    } else if text.isValidEmail(email: text) {
                        composeMailDelegate?.showMailComposer(mail: text)
                    }
                }
            }
        }
        
    }
}


