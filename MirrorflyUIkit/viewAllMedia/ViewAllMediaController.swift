//
//  ViewAllMediaController.swift
//  MirrorflyUIkit
//
//  Created by John on 31/10/22.
//

import UIKit
import MirrorFlySDK
import AVKit
import QuickLook
import SwiftLinkPreview

enum SectionType: String {
    case media = "media"
    case document = "document"
    case link = "link"
}

class ViewAllMediaController: BaseViewController {
    // Common variables
    @IBOutlet weak var baseContainerView: UIView!
    @IBOutlet weak var noMediaView: UIView!
    @IBOutlet weak var noMediaInfoLabel: UILabel!
    var jid : String = ""
    @IBOutlet weak var segmentControl: UISegmentedControl!
    let viewModel = ViewAllMediaViewModel()
    
    // Media variables
    var mediaChatMessages = [[ChatMessage]]()
    @IBOutlet weak var collectionView: UICollectionView!
    let leftAndRightPadding: CGFloat = 3.0
    let numberOfItemsPerRow: CGFloat = 4.0
    
    
    //Docs variables
    var docChatMessages = [[ChatMessage]]()
    @IBOutlet weak var docLinkTableView: UITableView!
    var docMessage : ChatMessage? = nil
    var showDocument : Bool = true
    
    //Links Variables
    var linkModels = [[LinkModel]]()
    
    var availableFeatures = ChatManager.getAvailableFeatures()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpStatusBar()
        
        handleBackgroundAndForground()
        
        intializeMediaUI()
        initializeDocLinkUI()
       
        getMediaMessages()
        getDocumentMessages()
        getLinkMessages()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
        
        availableFeatures = ChatManager.getAvailableFeatures()
    }
    
    
    @IBAction func switchView(_ sender: UISegmentedControl) {
        let index =  sender.selectedSegmentIndex
        if index == 0 {
            handleNoMediaMessage(sectionType: .media)
        } else if index == 1 {
            showDocument = true
            handleNoMediaMessage(sectionType: .document)
        } else if index == 2 {
            showDocument = false
            handleNoMediaMessage(sectionType: .link)
        }
    }
    
    @IBAction func didTapBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ChatManager.shared.messageEventsDelegate = self
        FlyMessenger.shared.messageEventsDelegate = self
        ChatManager.shared.availableFeaturesDelegate = self
        if segmentControl.selectedSegmentIndex == 0 {
            getMediaMessages()
        } else if segmentControl.selectedSegmentIndex == 1 {
            getDocumentMessages()
            handleNoMediaMessage(sectionType: .document)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ChatManager.shared.messageEventsDelegate = nil
        ChatManager.shared.availableFeaturesDelegate = nil
        FlyMessenger.shared.messageEventsDelegate = nil
    }
    
    override func willCometoForeground() {
        getLinkMessages()
    }
}

// To hanlde no media or no documetns or no links
extension ViewAllMediaController {
    private func handleNoMediaMessage(sectionType : SectionType){
        switch sectionType {
            case .media:
                intializeMediaUI()
                docLinkTableView.isHidden = true
                collectionView.isHidden = mediaChatMessages.isEmpty
                noMediaView.isHidden = !mediaChatMessages.isEmpty
                noMediaInfoLabel.text = noMediaFound
               
                collectionView.reloadData()
                
            case .document:
                collectionView.isHidden = true
                docLinkTableView.isHidden = docChatMessages.isEmpty
                noMediaView.isHidden = !docChatMessages.isEmpty
                noMediaInfoLabel.text = noDocumentFound
                docLinkTableView.reloadData()
                
            case .link:
               handleLink()
        }
    }
    
    private func handleLink() {
        collectionView.isHidden = true
        docLinkTableView.isHidden = linkModels.isEmpty
        noMediaView.isHidden = !linkModels.isEmpty
        noMediaInfoLabel.text = noLinkFound
        docLinkTableView.reloadData()
    }
}

// Docs functions
extension ViewAllMediaController {
    private func initializeDocLinkUI() {
        docLinkTableView.delegate = self
        docLinkTableView.dataSource = self
        docLinkTableView.register(UINib(nibName: Identifiers.documentCell, bundle: nil), forCellReuseIdentifier: Identifiers.documentCell)
        docLinkTableView.register(UINib(nibName: Identifiers.linkCell, bundle: nil), forCellReuseIdentifier: Identifiers.linkCell)
        docLinkTableView.register(UINib(nibName: Identifiers.headerSectionCell, bundle: nil), forHeaderFooterViewReuseIdentifier: Identifiers.headerSectionCell)
        docLinkTableView.register(UINib(nibName: Identifiers.footerSectionCell, bundle: nil), forHeaderFooterViewReuseIdentifier: Identifiers.footerSectionCell)
    }
    
    private func getDocumentMessages() {
        viewModel.getDocumentMessage(jid: jid) { isSuccess,error,data  in
            
            if !isSuccess {
                let message = AppUtils.shared.getErrorMessage(description: error?.description ?? "")
                AppAlert.shared.showAlert(view: self, title: "" , message: message, buttonTitle: "OK")
                return
            }
            var result = data
            if let chatMessages = result.getData() as? [[ChatMessage]] {
                self.docChatMessages = chatMessages
            }
        }
    }
}

// Media functions
extension ViewAllMediaController {
    private func intializeMediaUI() {
        // Do any additional setup after loading the view.
        collectionView.delegate = self
        collectionView.dataSource = self
        let collectionViewWidth = collectionView.frame.width
        let itmeWidth = ((collectionViewWidth - leftAndRightPadding) / numberOfItemsPerRow)
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.footerReferenceSize = CGSize(width: collectionView.frame.width, height: 50)
        layout.itemSize = CGSize(width: itmeWidth, height: itmeWidth)
    }
    
    private func getMediaMessages() {
        viewModel.getVideoAudioImageMessage(jid: jid) { [weak self] isSuccess,error,data  in
            
            if !isSuccess {
                let message = AppUtils.shared.getErrorMessage(description: error?.description ?? "")
                AppAlert.shared.showAlert(view: self!, title: "" , message: message, buttonTitle: "OK")
                return
            }
            var result = data
            if let chatMessages = result.getData() as? [[ChatMessage]] {
               
                self?.mediaChatMessages = chatMessages
                executeOnMainThread {
                    self?.handleNoMediaMessage(sectionType: .media)
                }
            }
        }
    }
}

// link functions
extension ViewAllMediaController {
    private func getLinkMessages() {
        viewModel.getLinkMessage(jid: jid) { [weak self] isSuccess,error,data  in
            
            if !isSuccess {
                let message = AppUtils.shared.getErrorMessage(description: error?.description ?? "")
                AppAlert.shared.showAlert(view: self!, title: "" , message: message, buttonTitle: "OK")
                return
            }
            
            var result = data
            if let linkModel = result.getData() as? [[LinkModel]] {
                
                self?.linkModels = linkModel
                self?.viewModel.processLink(linkModelList: linkModel) { linkModel in
                    let section = linkModel.section
                    let row = linkModel.row
                    self?.linkModels[section][row] = linkModel
                    if let showDoc =  self?.showDocument, !showDoc {
                        let indexPath = IndexPath(row: row, section: section)
                        executeOnMainThread {
                            if self?.segmentControl.selectedSegmentIndex == 2 {
                                self?.docLinkTableView.reloadRows(at: [indexPath], with: .none)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func didTapUrl(sender: UITapGestureRecognizer){
        if !NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            return
        }
        guard let urlString = sender.accessibilityHint else {
            return
        }
        AppUtils.shared.openURLInBrowser(urlString: urlString)
    }
    
    @objc func highlightLinkInChat(sender: UITapGestureRecognizer) {
        guard let messageId = sender.accessibilityHint else {
            return
        }
        let viewControllers = self.navigationController!.viewControllers
        for viewController in viewControllers
        {
            if viewController is ChatViewParentController
            {
                let chatController = viewController as! ChatViewParentController
                _ = self.navigationController?.popToViewController(chatController, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    chatController.highlightMessage(messageId: messageId)
                }
               
                break
                
            }
        }
    }
}

// CollectionView To handle Media
extension ViewAllMediaController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return mediaChatMessages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaChatMessages[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.mediaCell, for: indexPath) as! MediaCell
        let chatMessage = mediaChatMessages[indexPath.section][indexPath.row]
        
        cell.mediaImage.image = viewModel.getImage(chatMessage: chatMessage)
        
        switch chatMessage.messageType {
        case .image:
            hanldeCell(isAudio: false, cell: cell)
            cell.playIcon.isHidden = true
        case .video:
            hanldeCell(isAudio: false, cell: cell)
        case .audio:
            hanldeCell(isAudio: true, cell: cell)
            cell.audioDuration.text = viewModel.getMediaDuration(duration : chatMessage.mediaChatMessage?.mediaDuration ?? 0)
            if chatMessage.mediaChatMessage?.audioType == AudioType.recording {
                cell.centerAudioIcon.image =  UIImage(named: ImageConstant.ic_mic_white)
            } else {
                cell.centerAudioIcon.image = UIImage(named: ImageConstant.ic_white_headphone)
            }
        default:
            debugPrint("Media No Type")
        }
        return cell
        
    }
    
    func hanldeCell(isAudio : Bool, cell : MediaCell) {
        cell.audioView.isHidden = !isAudio
        cell.mediaImage.isHidden = isAudio
        cell.playIcon.isHidden = isAudio
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let sectionHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Identifiers.mediaSectionHeader, for: indexPath) as! SectionHeaderView
            let chatMessage = mediaChatMessages[indexPath.section][0]
            sectionHeaderView.monthLabel.text = viewModel.getTimeStampForHeader(chatMessage: chatMessage)
            return sectionHeaderView
        case UICollectionView.elementKindSectionFooter:
            let sectionFooterView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Identifiers.mediaSectionFooter, for: indexPath) as! SectionFooterView
            sectionFooterView.mediaCountLabel.text = viewModel.getMediaCount(chatMessages: mediaChatMessages)
            return sectionFooterView
            
        default:
            return UICollectionReusableView()
        }
       
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if section == (mediaChatMessages.count - 1) {
            return CGSize(width: collectionView.frame.width, height: 50)
        } else {
            return .zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let message = mediaChatMessages[indexPath.section][indexPath.row]
        switch message.messageType {
        case .image, .video, .audio:
            let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: Identifiers.imagePreview) as! ImagePreview
            controller.jid = message.chatUserJid
            controller.messageId = message.messageId
            navigationController?.pushViewController(controller, animated: true)
            controller.navigationController?.navigationBar.isHidden = false
        default:
            debugPrint("Media No Type")
        }
    
    }
    
}

// To handle plying video and audio
extension ViewAllMediaController {
    func playVideo(chatMessage : ChatMessage?) {
        if let videoUrl = viewModel.getVideoUrl(chatMessage: chatMessage) {
            play(url: videoUrl)
        }
    }
    
    func playAudio(chatMessage : ChatMessage) {
        if let audioUrl = viewModel.getAudioUrl(chatMessage: chatMessage) {
            play(url: audioUrl)
        }
    }
    
    func play(url : URL) {
        executeOnMainThread { [weak self] in
            let player = AVPlayer(url: url)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            self?.present(playerViewController, animated: true) {
                playerViewController.player!.play()
                
            }
        }
    }
}

// Table view for Document
extension ViewAllMediaController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: Identifiers.footerSectionCell ) as! FooterSectionCell
        footerView.titleLabel.text = showDocument ? viewModel.getDocumentCount(chatMessage: docChatMessages) : viewModel.getLinkCount(linkModels: linkModels)
        return footerView
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: Identifiers.headerSectionCell ) as! HeaderSectionCell
        let chatMessage = showDocument ? docChatMessages[section][0] : linkModels[section][0].linkMessage.chatMessage
        headerView.titleLabel.text = viewModel.getTimeStampForHeader(chatMessage: chatMessage)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == (showDocument ? (docChatMessages.count - 1) : (linkModels.count - 1)) {
            return 50
        } else {
            return .zero
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return showDocument ? docChatMessages.count : linkModels.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return showDocument ? docChatMessages[section].count : linkModels[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showDocument {
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.documentCell,
                                                     for: indexPath) as! DocumentTableViewCell
            let chatMessage = docChatMessages[indexPath.section][indexPath.row]
            let docuMessage = chatMessage.mediaChatMessage
            checkFileType(url: docuMessage?.mediaFileUrl ?? "", typeImageView: cell.icon)
            cell.nameLabel.text = docuMessage?.mediaFileName ?? ""
            cell.fileSizeLabel.text = viewModel.getDocumentFileSize(chatMessage: chatMessage)
            cell.dateLabel.text = viewModel.getDocumentDate(chatMessage: chatMessage)
            cell.selectedBackgroundView = getCellBackground()
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.linkCell,
                                                     for: indexPath) as! LinkCell
            let linkModel = linkModels[indexPath.section][indexPath.row]
            
            cell.titleLabel.text = linkModel.title
            cell.descriptionLabel.text = linkModel.description
            cell.domainLabel.text = linkModel.domain 
            cell.urlLabel.text = linkModel.linkMessage.link
            
            cell.linkImage.sd_setImage(with: URL(string: linkModel.image))
            
            cell.linkIcon.isHidden = !linkModel.image.isEmpty
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapUrl(sender:)))
            tapGestureRecognizer.accessibilityHint = linkModel.linkMessage.link
            cell.topView.addGestureRecognizer(tapGestureRecognizer)

            let chatGesture = UITapGestureRecognizer(target: self, action: #selector(highlightLinkInChat(sender: )))
            chatGesture.accessibilityHint = linkModel.linkMessage.chatMessage.messageId
            cell.bottomView.addGestureRecognizer(chatGesture)
            
            cell.selectedBackgroundView = getCellBackground()
            return cell
        }
        
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if showDocument {
            docMessage = docChatMessages[indexPath.section][indexPath.row]
            viewDocument()
        }
    }
    
    func getCellBackground() -> UIView {
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.white
        return bgColorView
    }
    
    
}

// For viewing doucument
extension ViewAllMediaController : QLPreviewControllerDataSource {
    
    private func viewDocument() {
        let previewController = QLPreviewController()
        previewController.dataSource = self
        present(previewController, animated: true)
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard let docMessage = docMessage else {
            fatalError()
        }
        
        guard let mediaLocalStoragePath = docMessage.mediaChatMessage?.mediaLocalStoragePath else {
            fatalError()
        }
        
        guard let mediaLocalStorageUrl: URL? = URL(fileURLWithPath: mediaLocalStoragePath) else {
            fatalError()
        }
        
        let preview = CustomPreviewItem(url: mediaLocalStorageUrl, title: docMessage.mediaChatMessage?.mediaFileName)
        
        return preview
    }
    
}

// Message event delegate
extension ViewAllMediaController : MessageEventsDelegate {
    func onMessageReceived(message: ChatMessage, chatJid: String) {
        print("View All media : onMessageReceived  \(message.chatUserJid)")
        if chatJid == jid {
            viewModel.whileReceivingNewMessage(chatMessage: message) { [weak self] linkModel in
                if let weakSelf = self {
                    var tempLinkModel = linkModel
                    if weakSelf.linkModels.count > 0 {
                        let rowCount = weakSelf.linkModels[0].count
                        tempLinkModel.row = rowCount
                        tempLinkModel.section = 0
                        weakSelf.linkModels[0].insert(tempLinkModel, at: 0)
                        if weakSelf.segmentControl.selectedSegmentIndex == 2 {
                            weakSelf.docLinkTableView.reloadData()
                        }
                    } else {
                        tempLinkModel.row = 0
                        tempLinkModel.section = 0
                        weakSelf.linkModels.append([tempLinkModel])
                        weakSelf.handleLink()
                    }
                }
               
            }
        }
    }
    
    func onMessageStatusUpdated(messageId: String, chatJid: String, status: MessageStatus) {
        
    }
    
    func onMediaStatusUpdated(message: ChatMessage) {
        if jid == message.chatUserJid {
            if message.messageType == .document {
                if docChatMessages.count > 0 {
                    docChatMessages[0].insert(message, at: 0)
                    if segmentControl.selectedSegmentIndex == 1 {
                        executeOnMainThread { [weak self] in
                            self?.docLinkTableView.reloadData()
                        }
                      
                    }
                } else {
                    getDocumentMessages()
                    showDocument = true
                    handleNoMediaMessage(sectionType: .document)
                }
            } else {
                if mediaChatMessages.count > 0 {
                    mediaChatMessages[0].insert(message, at: 0)
                    if segmentControl.selectedSegmentIndex == 0 {
                        executeOnMainThread { [weak self] in
                            self?.collectionView.reloadData()
                        }
                    }
                } else {
                    executeOnMainThread { [weak self] in
                        self?.intializeMediaUI()
                    }
                    getMediaMessages()
                }
            }
        }
        
    }
    
    func onMediaStatusFailed(error: String, messageId: String, errorCode: Int) {
        
    }
    
    func onMediaProgressChanged(message: ChatMessage, progressPercentage: Float) {
        
    }
    
    func onMessagesClearedOrDeleted(messageIds: Array<String>) {
        handleMessageClearedOrDelete(messageIds: messageIds)
    }
    
    func onMessagesDeletedforEveryone(messageIds: Array<String>) {
        handleMessageClearedOrDelete(messageIds: messageIds)
    }
    
    func showOrUpdateOrCancelNotification() {
        
    }
    
    func onMessagesCleared(toJid: String, deleteType: String?) {
        if toJid == jid {
           clearMessage()
        }
    }
    
    func setOrUpdateFavourite(messageId: String, favourite: Bool, removeAllFavourite: Bool) {
        
    }
    
    func onMessageTranslated(message: ChatMessage, jid: String) {
        
    }
    
    func clearAllConversationForSyncedDevice() {}
    
    
}

// To handle message delete and clear

extension ViewAllMediaController {
    func handleMessageClearedOrDelete(messageIds : Array<String>) {
        if viewModel.checkToMessageDelete(messageIds: messageIds, jid: jid) {
            if segmentControl.selectedSegmentIndex == 0 {
                mediaChatMessages = viewModel.removeDeletedOrCleardMessages(chatMessages: mediaChatMessages, messaeIds: messageIds)
                collectionView.reloadData()
            } else if segmentControl.selectedSegmentIndex == 1 {
                docChatMessages = viewModel.removeDeletedOrCleardMessages(chatMessages: docChatMessages, messaeIds: messageIds)
                docLinkTableView.reloadData()
            } else if segmentControl.selectedSegmentIndex == 2 {
                linkModels = viewModel.removeDeletedOrCleardLinkMessages(linkModels: linkModels, messaeIds: messageIds)
                docLinkTableView.reloadData()
            }
        }
    }
    
    func clearMessage() {
        mediaChatMessages.removeAll()
        docChatMessages.removeAll()
        linkModels.removeAll()
        docLinkTableView.reloadData()
        collectionView.reloadData()
    }
}

extension ViewAllMediaController : AvailableFeaturesDelegate {
    
    func didUpdateAvailableFeatures(features: AvailableFeaturesModel) {
        
        availableFeatures = features
        
        let tabCount =  MainTabBarController.tabBarDelegagte?.currentTabCount()
        
        if (!(availableFeatures.isGroupCallEnabled || availableFeatures.isOneToOneCallEnabled) && tabCount == 5) {
            MainTabBarController.tabBarDelegagte?.removeTabAt(index: 2)
        }else {
            
            if ((availableFeatures.isGroupCallEnabled || availableFeatures.isOneToOneCallEnabled) && tabCount ?? 0 < 5){
                MainTabBarController.tabBarDelegagte?.resetTabs()
            }
            
        }
        
        if !(availableFeatures.isViewAllMediasEnabled) {
            self.navigationController?.popViewController(animated: true)
        }
    }
}


