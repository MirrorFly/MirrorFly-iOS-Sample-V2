//
//  MessageInfoViewController.swift
//  MirrorflyUIkit
//
//  Created by John on 10/10/22.
//

import UIKit
import MirrorFlySDK
import AVKit
import QuickLook

class MessageInfoViewController: BaseViewController {
    
    @IBOutlet weak var messageInfoTableView: UITableView!
    var chatMessage : ChatMessage? = nil
    let messageInfoViewModel = MessageInfoViewModel()
    
    var seenUserCount = 0
    var deliveredUserCount = 0
    var totalParticipantCount = 0
    
    var groupMessagedeliveredList = [MessageReceipt]()
    var groupMessageSeenlList = [MessageReceipt]()
    
    var isDeliveredExpanded = false
    var isSeenExpanded = false
    var pageDismissClosure:(()-> ())?
    private var audioPlayer : AVAudioPlayer = AVAudioPlayer()
    var audioCell : AudioSender? = nil
    var isAudioPaused = false
    var updater : CADisplayLink! = nil
    var profileDetails: ProfileDetails!
    
    var messageDelegate : MessageDelegate? = nil
    
    var refreshDelegate : RefreshChatDelegate? = nil
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeMessageInfo()
        intializeUI()
        audioPermission()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
    }
    
    private func intializeUI() {
        navigationBar.backgroundColor = Color.color_F2F2F2
        setUpStatusBar()
        registerNibs()
        messageInfoTableView.delegate = self
        messageInfoTableView.dataSource = self
    }
    
    func audioPermission() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default,options: [.defaultToSpeaker,.allowBluetooth,.allowAirPlay])
            
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
        }
    }
    
    private func initializeMessageInfo() {
        guard let message = chatMessage else {
            return
        }
        
        let groupDeliveredInfo =  messageInfoViewModel.groupMessageDeliveredList(messageId: message.messageId, groupId: message.chatUserJid)
        let groupSeenInfo = messageInfoViewModel.groupMessageSeenList(messageId: message.messageId, groupId: message.chatUserJid)
        
        deliveredUserCount = groupDeliveredInfo.deliveredCount
        groupMessagedeliveredList = isDeliveredExpanded ? messageInfoViewModel.sortListByName(receiptList: groupDeliveredInfo.deliveredParticipantList)  : []
        
        seenUserCount = groupSeenInfo.seenCount
        groupMessageSeenlList = isSeenExpanded ? messageInfoViewModel.sortListByName(receiptList: groupSeenInfo.seenParticipantList) : []
        
        totalParticipantCount = groupSeenInfo.totalParticipatCount
        messageInfoTableView.reloadData()
    }
    
    @IBAction func didTapBack(_ sender: Any) {
        refreshDelegate?.refresh()
        self.navigationController?.popViewController(animated: true)
    }
    
    func registerNibs() {
        messageInfoTableView.register(UINib(nibName: Identifiers.chatViewTextOutgoingCell , bundle: .main), forCellReuseIdentifier: Identifiers.chatViewTextOutgoingCell)
        messageInfoTableView.register(UINib(nibName: Identifiers.chatViewLocationOutgoingCell , bundle: .main), forCellReuseIdentifier: Identifiers.chatViewLocationOutgoingCell)
        messageInfoTableView.register(UINib(nibName: Identifiers.chatViewContactOutgoingCell , bundle: .main), forCellReuseIdentifier: Identifiers.chatViewContactOutgoingCell)
        messageInfoTableView.register(UINib(nibName: Identifiers.scheduledMeetingSenderCell,
                                                 bundle: .main), forCellReuseIdentifier: Identifiers.scheduledMeetingSenderCell)
        messageInfoTableView.register(UINib(nibName: Identifiers.audioSender , bundle: .main), forCellReuseIdentifier: Identifiers.audioSender)
        messageInfoTableView.register(UINib(nibName: Identifiers.imageSender , bundle: .main), forCellReuseIdentifier: Identifiers.imageSender)
        messageInfoTableView.register(UINib(nibName: Identifiers.videoOutgoingCell , bundle: .main), forCellReuseIdentifier: Identifiers.videoOutgoingCell)
        messageInfoTableView.register(UINib(nibName: Identifiers.senderDocumenCell,
                                            bundle: .main), forCellReuseIdentifier: Identifiers.senderDocumenCell)
        messageInfoTableView.register(UINib(nibName: Identifiers.messageInfoDivider,
                                            bundle: .main), forCellReuseIdentifier: Identifiers.messageInfoDivider)
        messageInfoTableView.register(UINib(nibName: Identifiers.singleMessageInfoCell,
                                            bundle: .main), forCellReuseIdentifier: Identifiers.singleMessageInfoCell)
        messageInfoTableView.register(UINib(nibName: Identifiers.groupDividerCell,
                                            bundle: .main), forCellReuseIdentifier: Identifiers.groupDividerCell)
        messageInfoTableView.register(UINib(nibName: Identifiers.groupHeaderCell,
                                            bundle: .main), forCellReuseIdentifier: Identifiers.groupHeaderCell)
        messageInfoTableView.register(UINib(nibName: Identifiers.inforDeliveredCell,
                                            bundle: .main), forCellReuseIdentifier: Identifiers.inforDeliveredCell)
        messageInfoTableView.register(UINib(nibName: Identifiers.notDelivered,
                                            bundle: .main), forCellReuseIdentifier: Identifiers.notDelivered)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        refreshDelegate = nil
        stopDisplayLink()
        audioPlayer.stop()
    }
}

extension MessageInfoViewController : UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 8
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 || section == 1 || section == 2 || section == 3 || section == 5 || section == 6 {
            return 1
        } else if section == 4 {
            if groupMessagedeliveredList.isEmpty && isDeliveredExpanded{
                return 1
            } else {
                return groupMessagedeliveredList.count
            }
        } else if section == 7 {
            if groupMessageSeenlList.isEmpty && isSeenExpanded {
                return 1
            } else {
                return groupMessageSeenlList.count
            }
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell : ChatViewParentMessageCell!
        let section = indexPath.section
        if section == 0 {
            if let message = chatMessage {
                switch(message.messageType) {
                case .text, .meet:

                    cell = tableView.dequeueReusableCell(withIdentifier: message.messageType == .text ? Identifiers.chatViewTextOutgoingCell : Identifiers.scheduledMeetingSenderCell, for: indexPath) as? ChatViewParentMessageCell
                    //cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatViewTextOutgoingCell, for: indexPath) as? ChatViewParentMessageCell
                    cell.starredMessageView?.isHidden = true
                    cell = cell?.getCellFor(message, at: indexPath, isShowForwardView: false, profileDetails: profileDetails)
                    cell.selectionStyle = .none
                    cell?.contentView.backgroundColor = .clear
                    cell.senderStackView?.isHidden = true
                    cell.isAllowSwipe = false
                    return cell
                    
                case.location:
                    cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatViewLocationOutgoingCell, for: indexPath) as? ChatViewParentMessageCell
                    cell.starredMessageView?.isHidden = true
                    cell = cell.getCellFor(message, at: indexPath, isShowForwardView: false, profileDetails: profileDetails)
                    cell.locationOutgoingView?.isUserInteractionEnabled = true
                    cell.selectionStyle = .none
                    cell?.contentView.backgroundColor = .clear
                    cell.quickForwardView?.isHidden = true
                    cell.isAllowSwipe = false
                    cell.senderStackView?.isHidden = true
                    return cell
                    
                case .contact:
                    cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatViewContactOutgoingCell, for: indexPath) as? ChatViewParentMessageCell
                    cell.starredMessageView?.isHidden = true
                    cell = cell.getCellFor(message, at: indexPath, isShowForwardView: false, profileDetails: profileDetails)
                    cell.selectionStyle = .none
                    cell?.contentView.backgroundColor = .clear
                    cell.isAllowSwipe = false
                    cell.quickForwardView?.isHidden = true
                    cell.senderStackView?.isHidden = true
                    return cell
                    
                case .audio:
                    var cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.audioSender, for: indexPath) as? AudioSender
                    cell?.starredMessageView?.isHidden = true
                    cell = cell?.getCellFor(message, at: indexPath, isPlaying: false, audioClosureCallBack: { [weak self] (sliderValue)  in
                        
                    }, isShowForwardView: false, isDeleteMessageSelected: false)
                    cell?.playButton?.addTarget(self, action: #selector(playAudio), for: .touchUpInside)
                    cell?.selectionStyle = .none
                    cell?.contentView.backgroundColor = .clear
                    cell?.audioPlaySlider?.addTarget(self, action: #selector(audioPlaySliderAction(sender:)), for: .valueChanged)
                    audioCell = cell
                    cell?.isAllowSwipe = false
                    cell?.fwdViw?.isHidden = true
                    cell?.senderStackView?.isHidden = true
                    return cell ?? UITableViewCell()
                    
                case .image, .video:
                    var cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.videoOutgoingCell, for: indexPath) as! ChatViewVideoOutgoingCell
                    cell = cell.getCellFor(message, at: indexPath, isShowForwardView: false, isDeleteMessageSelected: false, profileDetails: profileDetails)!
                    cell.starredMessageView?.isHidden = true
                    cell.playButton.addTarget(self, action: #selector(playVideo), for: .touchUpInside)
                    cell.selectionStyle = .none
                    cell.contentView.backgroundColor = .clear
                    cell.forwardView?.isHidden = true
                    cell.quickFwdBtn?.isHidden = true
                    cell.quickfwdView?.isHidden = true
                    cell.isAllowSwipe = false
                    cell.senderStackView?.isHidden = true
                    return cell
                    
                case .document:
                    var cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.senderDocumenCell,
                                                             for: indexPath) as! SenderDocumentsTableViewCell
                    cell.starredMessageView?.isHidden = true
                    cell = cell.getCellFor(message, at: indexPath, isShowForwardView: false,isDeletedMessageSelected: false)!
                    cell.viewDocumentButton?.addTarget(self, action: #selector(viewDocument), for: .touchUpInside)
                    cell.selectionStyle = .none
                    cell.contentView.backgroundColor = .clear
                    cell.forwardButton?.isHidden = true
                    cell.fwdButton?.isHidden = true
                    cell.isAllowSwipe = false
                    cell.senderStackView?.isHidden = true
                    return cell
                default:
                    return UITableViewCell()
                }
            }
        } else if section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.messageInfoDivider,
                                                     for: indexPath) as! MessageInfoDivider
            cell.selectionStyle = .none
            return cell
        } else if section == 2 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.singleMessageInfoCell,
                                                     for: indexPath) as! SingleMessageInfoCell
            if let message = chatMessage, message.messageChatType == .singleChat  {
                if message.messageStatus == .seen {
                    let seenReceipt = messageInfoViewModel.getSingleChatSeenStatus(messageId: message.messageId)
                    let deliveredReceipt = messageInfoViewModel.getSingleChatDeliveredStatus(messageId: message.messageId)
                    cell.labelReadTime.text = DateFormatterUtility.shared.milliSecondsToMessageInfoDateFormat(milliSec: seenReceipt?.time ?? 0)
                    cell.labelDeliveredTime.text = DateFormatterUtility.shared.milliSecondsToMessageInfoDateFormat(milliSec: deliveredReceipt?.time ?? 0)
                } else if message.messageStatus == .delivered {
                    let deliveredReceipt = messageInfoViewModel.getSingleChatDeliveredStatus(messageId: message.messageId)
                    cell.labelReadTime.text = yourMessageIsNotRead
                    cell.labelDeliveredTime.text = DateFormatterUtility.shared.milliSecondsToMessageInfoDateFormat(milliSec: deliveredReceipt?.time ?? 0)
                } else if message.messageStatus == .acknowledged {
                    cell.labelReadTime.text = yourMessageIsNotRead
                    cell.labelDeliveredTime.text = messageSentNotDelivered
                }
            }
            cell.selectionStyle = .none
            return cell
        } else if section == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.groupHeaderCell,
                                                     for: indexPath) as! GroupHeaderCell
            handleGroupHeader(isSeen: false, cell: cell)
            return cell
        } else if section == 4 {
            if groupMessagedeliveredList.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.notDelivered,
                                                         for: indexPath) as! NotDeliveredCell
                cell.notDeliveredImage.image = UIImage(named: ImageConstant.ic_info_not_delivered)
                cell.selectionStyle = .none
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.inforDeliveredCell,
                                                         for: indexPath) as! DeliveredCell
                hanldeGroupUserCell(cell: cell, messageReceipt: groupMessagedeliveredList[indexPath.row])
                cell.seperatorLine.isHidden = (indexPath.row == groupMessagedeliveredList.count - 1)
                cell.selectionStyle = .none
                return cell
            }
            
        } else if section == 5 {
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.groupDividerCell,
                                                     for: indexPath) as! GroupDividerCell
            cell.selectionStyle = .none
            return cell
        } else if section == 6 {
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.groupHeaderCell,
                                                     for: indexPath) as! GroupHeaderCell
            handleGroupHeader(isSeen: true, cell: cell)
            return cell
        } else if section == 7 {
            
            if groupMessageSeenlList.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.notDelivered,
                                                         for: indexPath) as! NotDeliveredCell
                cell.notDeliveredImage.image = UIImage(named: ImageConstant.ic_info_not_read)
                cell.selectionStyle = .none
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.inforDeliveredCell,
                                                         for: indexPath) as! DeliveredCell
                hanldeGroupUserCell(cell: cell, messageReceipt: groupMessageSeenlList[indexPath.row])
                cell.seperatorLine.isHidden = (indexPath.row == groupMessageSeenlList.count - 1)
                cell.selectionStyle = .none
                return cell
            }
            
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = indexPath.section
        if let chatMessage = chatMessage {
            if chatMessage.messageChatType == .singleChat && (section == 0 || section == 1 || section == 2) {
                return UITableView.automaticDimension
            } else if chatMessage.messageChatType == .groupChat, section != 2 {
                return UITableView.automaticDimension
            } else {
                return 0.0
            }
        }
        
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let message = chatMessage else { return }
        let section = indexPath.section
        if section == 0 {
            switch message.messageType {
            case .location:
                let storyboard = UIStoryboard.init(name: Storyboards.chat, bundle: nil)
                let locationVC = storyboard.instantiateViewController(withIdentifier: Identifiers.locationViewController) as! LocationViewController
                locationVC.latitude = message.locationChatMessage?.latitude
                locationVC.longitude = message.locationChatMessage?.longitude
                locationVC.isForView = true
                navigationController?.pushViewController(locationVC, animated: true)
                
            case .image:
                let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: Identifiers.imagePreview) as! ImagePreview
                controller.jid = message.chatUserJid
                controller.messageId = message.messageId
                navigationController?.pushViewController(controller, animated: true)
                controller.navigationController?.navigationBar.isHidden = false
            case .video:
                playVideo()
            case .document:
                viewDocument()
            default:
                return
            }
        } else if section == 3 {
            isDeliveredExpanded = isDeliveredExpanded ? false : true
            initializeMessageInfo()
        } else if section == 6 {
            isSeenExpanded = isSeenExpanded ? false : true
            initializeMessageInfo()
        }
    }
}

extension MessageInfoViewController {
    private func hanldeGroupUserCell(cell : DeliveredCell, messageReceipt : MessageReceipt) {
        if let profileDetail = messageReceipt.profileDetails {
            let userName = getUserName(jid: profileDetail.jid, name: profileDetail.name, nickName: profileDetail.nickName, contactType: profileDetail.contactType)
            if profileDetail.mobileNumber == "" {
                cell.userNameLabel.text = ""
            } else {
                cell.userNameLabel.text = userName
                cell.userImage.loadFlyImage(imageURL:profileDetail.image, name: userName, jid: profileDetail.jid)
            }
        } else {
            cell.userNameLabel.text = ""
        }
        
        cell.deliveredTimeLabel.text = messageInfoViewModel.getMessageDeliveredDate(deliveryTime: messageReceipt.time)
        
    }
    
    private func handleGroupHeader(isSeen : Bool, cell : GroupHeaderCell) {
        if isSeen {
            cell.deliveredLabel.text = "Read by \(seenUserCount) of \(totalParticipantCount)"
            cell.addOrRemoveImage.image = UIImage(named: isSeenExpanded ? ImageConstant.ic_info_remove : ImageConstant.ic_info_add)
        } else {
            cell.deliveredLabel.text = "Delivered to \(deliveredUserCount) of \(totalParticipantCount)"
            cell.addOrRemoveImage.image = UIImage(named: isDeliveredExpanded ? ImageConstant.ic_info_remove : ImageConstant.ic_info_add)
        }
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.white
        cell.selectedBackgroundView = bgColorView
    }
    
    @objc func playVideo() {
        executeOnMainThread { [weak self] in
            let videoUrl = URL(fileURLWithPath: self?.chatMessage?.mediaChatMessage?.mediaLocalStoragePath ?? "")
            let player = AVPlayer(url: videoUrl)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            self?.present(playerViewController, animated: true) {
                playerViewController.player!.play()
            }
        }
    }
    
    @objc func viewDocument() {
        let previewController = QLPreviewController()
        previewController.dataSource = self
        present(previewController, animated: true)
    }
    
    @objc func checkForProfileUpdate(userJid : String, profileDetail : ProfileDetails) {
        var deliveredProfiles = groupMessagedeliveredList.filter({$0.profileDetails?.jid == userJid})
        if deliveredProfiles.count > 0 {
            deliveredProfiles[0].profileDetails = profileDetail
            initializeMessageInfo()
        }
        
        var seenProifles = groupMessageSeenlList.filter({$0.profileDetails?.jid == userJid})
        if seenProifles.count > 0 {
            seenProifles[0].profileDetails = profileDetail
            initializeMessageInfo()
        }
    }
}

// playing audio section
extension MessageInfoViewController {
    //MARK:- Play by name
    @objc func playAudio() {
        
        guard let audioFileName = chatMessage?.mediaChatMessage?.mediaFileName else {
            return
        }
        guard let audioCell = audioCell else {
            return
        }
        
        if audioPlayer.isPlaying {
            audioPlayer.pause()
            audioCell.playIcon?.image = UIImage(named: ImageConstant.ic_play)
            isAudioPaused = true
            return
        }
        
        if isAudioPaused {
            audioPlayer.play()
            isAudioPaused = false
            audioCell.playIcon?.image = UIImage(named: ImageConstant.ic_audio_pause)
            return
        }
        
        let fileURL = ChatUtils.getAudioURL(audioFileName: audioFileName)
        if FileManager.default.fileExists(atPath: fileURL.relativePath) {
            audioPlayer.prepareToPlay()
            do {
                
                let data = try Data(contentsOf: fileURL)
                audioPlayer = try! AVAudioPlayer(data: data as Data)
                
                audioCell.playIcon?.image = UIImage(named: ImageConstant.ic_audio_pause)
                audioCell.audioPlaySlider?.maximumValue = Float(audioPlayer.duration)
                
                audioPlayer.currentTime = TimeInterval(audioCell.audioPlaySlider?.value ?? 0.0)
                audioPlayer.delegate = self
                audioPlayer.play()
                
                isAudioPaused = false
                
                updater = CADisplayLink(target: self, selector: #selector( trackAudio))
                updater.frameInterval = 1
                updater.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
                
            } catch {
                print("play(with name:), ",error.localizedDescription)
            }
        } else {
            print("File Does not Exist")
            return
        }
    }
    
    func stopDisplayLink() {
        updater?.invalidate()
        updater = nil
    }
    
    @objc func trackAudio() {
        guard let audioCell = audioCell else {
            return
        }
        let curnTime = audioPlayer.currentTime
        let duration = audioPlayer.duration
        let normalizedTime = Float(curnTime * 100.0 / duration)
        print(normalizedTime)
        print(curnTime)
        print(duration)
        let min = Int(curnTime / 60)
        let sec = Int(curnTime.truncatingRemainder(dividingBy: 60))
        let totalTimeString = String(format: "%02d:%02d", min, sec)
        print(totalTimeString)
        
        audioCell.autioDuration?.text = totalTimeString
        audioCell.audioPlaySlider?.value = Float(audioPlayer.currentTime)
        
    }
    
    @objc func audioPlaySliderAction(sender: UISlider) {
        
        guard let audioCell = audioCell else { return }
        
        audioPlayer.currentTime = TimeInterval(sender.value)
        audioCell.autioDuration?.text = "\(TimeInterval(sender.value).minuteSecondMS)"
        
        if isAudioPaused || audioPlayer.isPlaying {
            return
        }
        
        guard let audioFileName = chatMessage?.mediaChatMessage?.mediaFileName else {
            return
        }
        
        let fileURL = ChatUtils.getAudioURL(audioFileName: audioFileName)
        if FileManager.default.fileExists(atPath: fileURL.relativePath) {
            audioPlayer.prepareToPlay()
            do {
                
                let data = try Data(contentsOf: fileURL)
                audioPlayer = try! AVAudioPlayer(data: data as Data)
                audioCell.audioPlaySlider?.maximumValue = Float(audioPlayer.duration)
                
            } catch {
                print("play(with name:), ",error.localizedDescription)
            }
        }
    }
    
}

//MARK:- AVAudioPlayer Delegate functions
extension MessageInfoViewController: AVAudioPlayerDelegate{
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        debugLog("playing finish")
        isAudioPaused = false
        stopDisplayLink()
        audioPlayer.stop()
        guard let audioCell = audioCell else {
            return
        }
        audioCell.playIcon?.image = UIImage(named: ImageConstant.ic_play)
        audioCell.audioPlaySlider?.value = 0.0
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        debugLog(error?.localizedDescription ?? "Error occured while encoding player")
    }
}

extension MessageInfoViewController  {
    // override func derived from base view controller
    override func onMessageReceived(message: ChatMessage, chatJid: String) {
        super.onMessageReceived(message: message, chatJid: chatJid)
       // messageDelegate?.whileReceivingMessage(chatMessage: message, chatUserJid: chatJid)
    }
    
    override func onMessageStatusUpdated(messageId: String, chatJid: String, status: MessageStatus) {
        super.onMessageStatusUpdated(messageId: messageId, chatJid: chatJid, status: status)
        if chatMessage?.messageId == messageId {
            chatMessage?.messageStatus = status
            executeOnMainThread { [weak self] in
                self?.initializeMessageInfo()
            }
        }
        messageDelegate?.whileUpdatingMessageStatus(messageId: messageId, chatJid: chatJid, status: status)
    }
    
    override func onMediaStatusUpdated(message: ChatMessage) {
        super.onMediaStatusUpdated(message: message)
        
    }
    
    override func onMediaStatusFailed(error: String, messageId: String, errorCode: Int) {
        super.onMediaStatusFailed(error: error, messageId: messageId, errorCode: errorCode)
    }
    
    override func onMediaProgressChanged(message: ChatMessage, progressPercentage: Float) {
        super.onMediaProgressChanged(message: message, progressPercentage: progressPercentage)
    }
    
    override func onMessagesClearedOrDeleted(messageIds: Array<String>) {
        super.onMessagesClearedOrDeleted(messageIds: messageIds)
    }
    
    override func onMessagesDeletedforEveryone(messageIds: Array<String>) {
        super.onMessagesDeletedforEveryone(messageIds: messageIds)
    }
    
    override func showOrUpdateOrCancelNotification() {
        super.showOrUpdateOrCancelNotification()
    }
    
    override func onMessagesCleared(toJid: String, deleteType: String?) {
        super.onMessagesCleared(toJid: toJid, deleteType: deleteType)
    }
    
    override func setOrUpdateFavourite(messageId: String, favourite: Bool, removeAllFavourite: Bool) {
        super.setOrUpdateFavourite(messageId: messageId, favourite: favourite, removeAllFavourite: removeAllFavourite)
        if chatMessage?.messageId == messageId {
            chatMessage?.isMessageStarred = favourite
            messageInfoTableView?.reloadData()
            pageDismissClosure?()
        }
    }
    
    override func onMessageTranslated(message: ChatMessage, jid: String) {
        super.onMessageTranslated(message: message, jid: jid)
    }
    
    override func clearAllConversationForSyncedDevice() {
        super.clearAllConversationForSyncedDevice()
    }
}
// For viewing doucument
// MARK - Text Delegate
extension MessageInfoViewController : QLPreviewControllerDataSource {
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard let chatMessage = chatMessage else {
            fatalError()
        }
        
        guard let mediaLocalStoragePath = chatMessage.mediaChatMessage?.mediaLocalStoragePath else {
            fatalError()
        }
        
        guard let mediaLocalStorageUrl: URL? = URL(fileURLWithPath: mediaLocalStoragePath) else {
            fatalError()
        }
        
        let preview = CustomPreviewItem(url: mediaLocalStorageUrl, title: chatMessage.mediaChatMessage?.mediaFileName)
        
        return preview
    }
    
}

extension MessageInfoViewController : MessageDelegate {
    func whileUpdatingMessageStatus(messageId: String, chatJid: String, status: MirrorFlySDK.MessageStatus) {
        if chatMessage?.messageId == messageId {
            chatMessage?.messageStatus = status
            executeOnMainThread { [weak self] in
                self?.initializeMessageInfo()
            }
        }
    }
    
    func whileUpdatingTheirProfile(for jid: String, profileDetails: MirrorFlySDK.ProfileDetails) {
        executeOnMainThread { [weak self] in
            self?.checkForProfileUpdate(userJid: jid, profileDetail: profileDetails)
        }
    }
    
}
