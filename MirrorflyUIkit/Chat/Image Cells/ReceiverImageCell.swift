//
//  ImageReceiverCell.swift
//  MirrorflyUIkit
//
//  Created by User on 03/09/21.
//

import UIKit
import MirrorFlySDK
import NicoProgress
import GoogleMaps
import MapKit

class ReceiverImageCell: BaseTableViewCell {
    @IBOutlet weak var captionBotom: NSLayoutConstraint?
    @IBOutlet weak var captionTop: NSLayoutConstraint?
    @IBOutlet weak var close: UIImageView!
    @IBOutlet weak var progressBar: UIView!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var imageContainer: UIImageView!
    @IBOutlet weak var caption: UILabel!
    @IBOutlet weak var reecivedTime: UILabel!
    @IBOutlet weak var fwdView: UIView!
    @IBOutlet weak var fwdIcon: UIButton!
    @IBOutlet weak var filseSize: UILabel!
    @IBOutlet weak var downloadView: UIView!
    @IBOutlet weak var downloadImg: UIImageView!
    @IBOutlet weak var downoadButton: UIButton!
    @IBOutlet weak var progrssButton: UIButton!
    @IBOutlet weak var timeTopCons: NSLayoutConstraint?
    var imageGeasture: UITapGestureRecognizer!
    @IBOutlet weak var groupSenderNameLabel: GroupReceivedMessageHeader!
    @IBOutlet weak var bubbleImageTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var replyTrailingWithMediaCons: NSLayoutConstraint?
    @IBOutlet weak var replyTrailingCons: NSLayoutConstraint?
    
    @IBOutlet weak var overlayImage: UIImageView!
    
    @IBOutlet weak var replyView: UIView?
    @IBOutlet weak var messageTypeIconView: UIView?
    @IBOutlet weak var messageTypeIcon: UIImageView?
    @IBOutlet weak var chatMapView: UIView?
    @IBOutlet weak var mediaImageView: UIImageView?
    @IBOutlet weak var replyTextLabel: UILabel?
    @IBOutlet weak var replyUserLabel: UILabel?
    @IBOutlet weak var bubbleImageView: UIImageView?
    @IBOutlet weak var receivedTimeBottomcons: NSLayoutConstraint?
    @IBOutlet weak var senderNameContainer: UIView!
    //Translation View
    @IBOutlet weak var translatedTextLabel: UILabel?
    @IBOutlet weak var captionStackView: UIStackView!
    @IBOutlet weak var captionViewBottomCons: NSLayoutConstraint?
    @IBOutlet weak var timestampBottomCons: NSLayoutConstraint?
    // Forward Outlet
    @IBOutlet weak var forwardImageView: UIImageView?
    @IBOutlet weak var forwardView: UIView?
    @IBOutlet weak var forwardLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var bubbleImageLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var forwardButton: UIButton?
    var composeMailDelegate: ShowMailComposeDelegate?
    var receivedMediaMessages: [ChatMessage]? = []
    var message : ChatMessage?
    var refreshDelegate: RefreshBubbleImageViewDelegate? = nil
    var selectedForwardMessage: [SelectedMessages]? = []
    
    var newProgressBar: ProgressBar!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupUI()
    }
    
    func setupUI() {
    imageGeasture = UITapGestureRecognizer()
    imageContainer.addGestureRecognizer(imageGeasture)
    //progressBar?.transition(to: .determinate(percentage: 30.0))
    caption.font = UIFont.font12px_appRegular()
    filseSize.font = UIFont.font12px_appSemibold()
    progressView.layer.cornerRadius = 5
    cellView.roundCorners(corners: [.topLeft, .bottomLeft, .topRight], radius: 5.0)
        imageContainer.layer.cornerRadius = 5.0
        imageContainer.clipsToBounds = true
        newProgressBar = ProgressBar(frame: CGRect(x: 0, y: 0, width: progressBar.frame.width, height: progressBar.frame.height))
        newProgressBar.primaryColor = .white
        newProgressBar.bgColor = .clear
        cellView.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 10.0)
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
    
    func getCellFor(_ message: ChatMessage?, at indexPath: IndexPath?,isShowForwardView: Bool?) -> ReceiverImageCell? {
        currentIndexPath = indexPath
        chatMapView?.isHidden = true
        replyTextLabel?.text = ""
        replyUserLabel?.text = ""
        translatedTextLabel?.text = ""
        
        // Forward view elements and its data
        forwardView?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded) ? false : true
        forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
        forwardLeadingCons?.constant = (isShowForwardView == true && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded) ? 20 : 0
        bubbleImageLeadingCons?.constant = (isShowForwardView == true && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded) ? 10 : 0
        forwardButton?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded) ? false : true
    
        if selectedForwardMessage?.filter({$0.chatMessage.messageId == message?.messageId}).first?.isSelected == true {
            forwardImageView?.image = UIImage(named: "forwardSelected")
            forwardImageView?.isHidden = false
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 0.0)
        } else {
           // forwardImageView?.image = UIImage(named: "")
            forwardImageView?.isHidden = true
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
        }
        
        if (message?.mediaChatMessage?.mediaDownloadStatus == .downloaded && isShowForwardView == false) {
            fwdView?.isHidden = false
            fwdIcon?.isHidden = false
        } else {
            fwdView?.isHidden = true
            fwdIcon?.isHidden = true
        }
        
        isAllowSwipe = message?.messageStatus == .notAcknowledged ? false : true
        
        // Reply view elements and its data
       if(message?.isReplyMessage == true) {
            replyView?.isHidden = false
           let getReplymessage =  message?.replyParentChatMessage?.messageTextContent
           let replyMessage = FlyMessenger.getMessageOfId(messageId: message?.replyParentChatMessage?.messageId ?? "")
           messageTypeIconView?.isHidden = true
           replyTextLabel?.text = getReplymessage
           if replyMessage?.mediaChatMessage != nil {
               messageTypeIconView?.isHidden = false
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
                   replyTrailingCons?.isActive = false
                   replyTrailingWithMediaCons?.isActive = true
               case .audio:
                   ChatUtils.setIconForAudio(imageView: messageTypeIcon, chatMessage: message)
                   let duration = Int(replyMessage?.mediaChatMessage?.mediaDuration ?? 0)
                   replyTextLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized.appending(" (\(duration.msToSeconds.minuteSecondMS))")
                   replyTrailingCons?.isActive = true
                   replyTrailingWithMediaCons?.isActive = false
               case .video:
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderVideo" : "video")
                   if let thumImage = replyMessage?.mediaChatMessage?.mediaThumbImage {
                       let converter = ImageConverter()
                       let image =  converter.base64ToImage(thumImage)
                       mediaImageView?.image = image
                       mediaImageView?.isHidden = false
                       replyTextLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized
                       replyTrailingCons?.isActive = false
                       replyTrailingWithMediaCons?.isActive = true
                   }
               case .document:
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "document" : "document")
                   checkFileType(url: replyMessage?.mediaChatMessage?.mediaFileUrl ?? "", typeImageView: mediaImageView)
                   replyTextLabel?.text = replyMessage?.mediaChatMessage?.mediaFileName.capitalized
                   replyTrailingCons?.isActive = false
                   replyTrailingWithMediaCons?.isActive = true
               default:
                   replyTrailingCons?.isActive = true
                   replyTrailingWithMediaCons?.isActive = false
                   messageTypeIconView?.isHidden = true
               }
               
           } else if replyMessage?.locationChatMessage != nil {
               chatMapView?.isHidden = false
               replyTextLabel?.text = "Location"
               chatMapView?.isUserInteractionEnabled = false
               messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "map" : "receivedMap")
               guard let latitude = replyMessage?.locationChatMessage?.latitude else {
                   return nil
               }
               guard let longitude = replyMessage?.locationChatMessage?.longitude  else {
                   return nil
               }
               
               AppUtils.shared.fetchStaticMapImage(latitude: latitude, longitude: longitude, zoomLevel: "16", size: CGSize(width: chatMapView?.bounds.width ?? 250, height: chatMapView?.bounds.height ?? 250)) { [self] mapImage in
                   let mapImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: chatMapView?.bounds.width ?? 250, height: chatMapView?.bounds.height ?? 250))
                   mapImageView.image = mapImage
                   chatMapView?.addSubview(mapImageView)
               }
               
//               chatMapView?.camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 16.0, bearing: 360.0, viewingAngle: 15.0)
//               
//               DispatchQueue.main.async { [self] in
//                   // 2. Perform UI Operations.
//                   let position = CLLocationCoordinate2DMake(latitude,longitude)
//                   let marker = GMSMarker(position: position)
//                   marker.map = chatMapView
//               }
               replyTrailingCons?.isActive = false
               replyTrailingWithMediaCons?.isActive = true
               messageTypeIconView?.isHidden = false
           } else if replyMessage?.contactChatMessage != nil {
                   replyTextLabel?.attributedText = ChatUtils.setAttributeString(name: replyMessage?.contactChatMessage?.contactName)
               messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderContact" : "receiverContact")
               messageTypeIconView?.isHidden = false
               replyTrailingCons?.isActive = true
               replyTrailingWithMediaCons?.isActive = false
           } else {
               mediaImageView?.isHidden = true
               replyTrailingCons?.isActive = true
               replyTrailingWithMediaCons?.isActive = false
           }
        if(replyMessage?.isMessageSentByMe ?? false) {
            replyUserLabel?.text = you.localized
        }
        else {
            replyUserLabel?.text = getUserName(jid: replyMessage?.senderUserJid ?? "" ,name: replyMessage?.senderUserName ?? "",
                                               nickName: replyMessage?.senderNickName ?? "", contactType: (replyMessage?.isDeletedUser ?? false) ? .deleted : (replyMessage?.isSavedContact ?? false) ? .live : .unknown)
        }
    }
        else {
            replyView?.isHidden = true
        }
        
        //Bubble View
        ChatUtils.setReceiverBubbleBackground(imageView: bubbleImageView)
        
        self.message = message
        
        if message?.messageChatType == .groupChat {
            groupSenderNameLabel.text = ChatUtils.getGroupSenderName(messsage: message)
        } else {
            groupSenderNameLabel.isHidden = true
            senderNameContainer.isHidden = true
        }
        if let captionTxt = message?.mediaChatMessage?.mediaCaptionText, captionTxt != "" {
            caption.attributedText = processTextMessage(message: message?.mediaChatMessage?.mediaCaptionText ?? "", uiLabel: caption)
            receivedTimeBottomcons?.constant = 0
            timeTopCons?.isActive = true
            captionTop?.constant = 8
            captionBotom?.constant = -7
            timeTopCons?.constant = 0
            overlayImage.isHidden = true
        }else{
            timeTopCons?.isActive = false
            timeTopCons?.constant = 0
            captionTop?.constant = 0
            captionBotom?.constant = 0
            receivedTimeBottomcons?.constant = 0
            caption.text = ""
            overlayImage.isHidden = false
        }
        if message?.mediaChatMessage?.mediaDownloadStatus == .not_downloaded {
            if let thumbImage = message?.mediaChatMessage?.mediaThumbImage {
                ChatUtils.setThumbnail(imageContainer: imageContainer ?? UIImageView(), base64String: thumbImage)
                if ((receivedMediaMessages?.count ?? 0) > 0 && (receivedMediaMessages?.filter({$0.messageId == message?.messageId}).count ?? 0) > 0) {
                    progressBar.addSubview(newProgressBar)
//                    progressBar?.transition(to: .indeterminate)
                    downoadButton?.isHidden = true
                    downloadView?.isHidden = true
                    progressView?.isHidden = false
                    progrssButton?.isHidden = false
                    close.isHidden = false
                } else {
                    newProgressBar.removeFromSuperview()
                    downoadButton?.isHidden = false
                    downloadView?.isHidden = false
                    progressView?.isHidden = true
                    progrssButton?.isHidden = true
                    close.isHidden = true
                }
                if let fileSiz = message?.mediaChatMessage?.mediaFileSize{
                    filseSize.text = "\(fileSiz.byteSize)"
                } else {
                    filseSize.text = ""
                }
       }
    } else if message?.mediaChatMessage?.mediaDownloadStatus == .downloading {
            if let thumbImage = message?.mediaChatMessage?.mediaThumbImage {
                ChatUtils.setThumbnail(imageContainer: imageContainer ?? UIImageView(), base64String: thumbImage)
            }
        progressBar.addSubview(newProgressBar)
            progressView.isHidden = false
            progrssButton.isHidden = false
            downoadButton.isHidden = true
            downloadView.isHidden = true
//            progressBar?.transition(to: .indeterminate)
            filseSize.text = ""
            close.isHidden = false
    } else if message?.mediaChatMessage?.mediaDownloadStatus == .downloaded {
            if let localPath = message?.mediaChatMessage?.mediaFileName {
                if let directoryURL: URL = FlyUtils.getGroupContainerIDPath() {
                    let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Image", isDirectory: true)
                    let fileURL: URL = folderPath.appendingPathComponent(localPath)
                    if FileManager.default.fileExists(atPath: fileURL.relativePath) {
                        let data = NSData(contentsOf: fileURL)
                        let image = UIImage(data: data! as Data)
                        imageContainer.image = image
                    }
                }
            } else {
                if let thumbImage = message?.mediaChatMessage?.mediaThumbImage {
                    ChatUtils.setThumbnail(imageContainer: imageContainer ?? UIImageView(), base64String: thumbImage)
                }
            }
            progressView.isHidden = true
            progrssButton.isHidden = true
            downoadButton.isHidden = true
            downloadView.isHidden = true
            filseSize.text = ""
            close.isHidden = true
        } else {
            if let thumbImage = message?.mediaChatMessage?.mediaThumbImage {
                ChatUtils.setThumbnail(imageContainer: imageContainer ?? UIImageView(), base64String: thumbImage)
            }
                downloadView.isHidden = false
                downoadButton.isHidden = false
                progrssButton.isHidden = true
            newProgressBar.removeFromSuperview()
                progressView.isHidden = true
                if let fileSiz = message?.mediaChatMessage?.mediaFileSize{
                filseSize.text = "\(fileSiz)"
                }else {
                    filseSize.text = ""
                }
                close.isHidden = true
        }
        guard let timeStamp =  message?.messageSentTime else {
            return self
        }
        self.reecivedTime.text = DateFormatterUtility.shared.currentMillisecondsToLocalTime(milliSec: timeStamp)
        
    //MARK: - Populating the Incoming Cell with the translated message
        
        if (message!.isMessageTranslated && CommonDefaults.isTranlationEnabled) {
            translatedTextLabel?.isHidden = false
            guard let chatMessage = message else {return self }
            print(chatMessage.mediaChatMessage?.mediaCaptionText)
            print(chatMessage.translatedMessageTextContent)
            caption!.text = chatMessage.mediaChatMessage?.mediaCaptionText ?? ""
            translatedTextLabel?.text = chatMessage.translatedMessageTextContent
            captionViewBottomCons?.constant = -20
            timestampBottomCons?.constant = -2
            captionStackView.spacing = 3
        } else {
            captionViewBottomCons?.constant = caption.text?.isEmpty ?? false ? 12 : -10
            timestampBottomCons?.constant = caption.text?.isEmpty ?? false ? -8 : -5
            captionStackView.spacing = 0
        }

   
        return self
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



