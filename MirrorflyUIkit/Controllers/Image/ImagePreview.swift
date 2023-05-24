//  ImagePreview.swift
//  MirrorflyUIkit
//  Created by User on 03/09/21.


import UIKit
import MirrorFlySDK
import AVKit

class ImagePreview: UIViewController  {
    
    @IBOutlet weak var imageList: UICollectionView!
    @IBOutlet weak var videoPlayButton: UIButton?
    var availableFeatures = ChatManager.getAvailableFeatures()
    
 
    func shareMedia(media: MediaChatMessage?) {
        var type = String()
        
        switch media?.messageType {
        case .audio:
            type = "Audio"
        case .video:
            type = "Video"
        case .image:
            type = "Image"
        case .document:
            type = "Document"
        default:
            return
        }
        
        let localPath = FlyUtils.getGroupContainerIDPath()!.appendingPathComponent("FlyMedia/\(type)/\(media?.mediaFileName ?? "")")
        let activityItems: [Any] = [localPath]
        let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        activityController.popoverPresentationController?.sourceView = view
        activityController.popoverPresentationController?.sourceRect = view.frame
        self.present(activityController, animated: true, completion: nil)
    }
    

    public var imageAray = [ChatMessage]()
    var isimgLoad = false
    var imageIndex = 0
    var jid = ""
    var messageId = String()
    var currentIndexPath: IndexPath = IndexPath()
    var refreshDataDelegate:RefreshMessagesDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
     setupUI()
        // Do any additional setup after loading the view.
    congfigureDefaults()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        availableFeatures = ChatManager.getAvailableFeatures()
        ChatManager.shared.availableFeaturesDelegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ChatManager.shared.messageEventsDelegate = self
        FlyMessenger.shared.messageEventsDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        navigationController?.setNavigationBarHidden(true, animated: true)
        ChatManager.shared.availableFeaturesDelegate = nil
        ChatManager.shared.messageEventsDelegate = nil
        FlyMessenger.shared.messageEventsDelegate = nil
    }
    
    func setupUI() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: imageList.frame.size.width, height: imageList.frame.size.width)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        imageList!.collectionViewLayout = layout
        imageList.isPagingEnabled = false
        imageList.isScrollEnabled = availableFeatures.isViewAllMediasEnabled ? true : false
    }
    
    func congfigureDefaults() {
        getImages()
    }
    
    func getImages() {
        imageAray  =  FlyMessenger.getMediaMessagesOf(jid: jid).filter({($0.mediaChatMessage?.messageType == .image || $0.messageType == .video || $0.messageType == .audio) && ($0.mediaChatMessage?.mediaDownloadStatus == .downloaded || $0.mediaChatMessage?.mediaUploadStatus == .uploaded) && $0.isMessageRecalled == false && $0.isMessageDeleted == false})
        if imageAray.count > 0 {
            if let selelctedImage = imageAray.filter({$0.mediaChatMessage?.messageType == .image || $0.messageType == .video || $0.messageType == .audio}).first(where: { $0.messageId == messageId }) {
                imageIndex = imageAray.firstIndex(of: selelctedImage) ?? 0
                setTitle()
            }else{
               setTitle()
            }
        
        }
        imageList.reloadData()
    }
    
    @objc func didTapPlayButton(sender : UIButton) {
        let row = sender.tag
        let message = imageAray[row]
        if message.messageType == .video {
            let videoUrl = URL(fileURLWithPath: message.mediaChatMessage?.mediaLocalStoragePath ?? "")
            playVideo(view: self, asset: videoUrl)
        } else if message.messageType == .audio {
            playAudio(chatMessage: message)
        }
        
    }
    
    func playVideo (view:UIViewController, asset:URL) {
        DispatchQueue.main.async {
            let player = AVPlayer(url: asset)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            view.present(playerViewController, animated: true) {
                playerViewController.player!.play()
            }
        }
    }
    
    func playAudio(chatMessage : ChatMessage) {
        let audioUrl = ChatUtils.getAudioURL(audioFileName: chatMessage.mediaChatMessage?.mediaFileName ?? "")
        executeOnMainThread { [weak self] in
            let player = AVPlayer(url: audioUrl)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            self?.present(playerViewController, animated: true) {
                playerViewController.player!.play()
                
            }
        }
    }
    
    func setTitle() {
        let imgeDetail = imageAray[imageIndex]
        self.navigationItem.setRightBarButton(UIBarButtonItem(image: UIImage(named: "ic_sharemedia"), style: .plain, target: self, action: #selector(shareMediaAction)), animated: true)
        if imgeDetail.isMessageSentByMe {
            self.title = sentMedia
        }else{
            self.title = receivedMedia
        }
    }
    
    @objc func shareMediaAction() {
        shareMedia(media: imageAray[imageIndex].mediaChatMessage)

    }
}
                                                  
extension ImagePreview: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
    {
    if isimgLoad == false
    {
    isimgLoad = true
    imageList.scrollToItem(at:IndexPath(item: imageIndex, section: 0), at: .right, animated: false)
        imageList.isPagingEnabled = true
    }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let noOfCellsInRow = 1

        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout

        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))

        let size = Int((view.bounds.width))
        let height = (Int((view.bounds.height)) / 2 + 50)

        return CGSize(width: size, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        imageAray.filter({$0.messageType == .image || $0.messageType == .video || $0.messageType == .audio}).count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell:ImageCell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.imageCell, for: indexPath) as! ImageCell
        if imageAray.count > indexPath.row {
            let imgeDetail = imageAray[indexPath.row]
            currentIndexPath = indexPath
            if imgeDetail.messageType == .image || imgeDetail.messageType == .video || imgeDetail.messageType == .audio {
                cell.videoPlayButton?.tag = indexPath.row
                cell.videoPlayButton?.addTarget(self, action: #selector(didTapPlayButton(sender:)),
                                                for: .touchUpInside)
                cell.audioButton?.tag = indexPath.row
                cell.audioButton?.addTarget(self, action: #selector(didTapPlayButton(sender:)),
                                                for: .touchUpInside)
                cell.cellImage.contentMode = .scaleAspectFit
                cell = cell.getCellFor(imgeDetail, at: indexPath)!
                cell.audioButton.isHidden = imgeDetail.messageType == .audio ? false : true
                cell.audioImage.isHidden = imgeDetail.messageType == .audio ? false : true
                cell.videoPlayButton?.isHidden = (imgeDetail.messageType == .video || imgeDetail.messageType == .audio) ? false : true
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
    
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var visibleRect = CGRect()
        visibleRect.origin = imageList.contentOffset
        visibleRect.size = imageList.bounds.size
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        guard let indexPath = imageList.indexPathForItem(at: visiblePoint) else { return }
        imageIndex = indexPath.row
        setTitle()
    }
}

extension ImagePreview : RefreshMessagesDelegate {
    func refreshMessages(messageIds: Array<String>) {
        messageIds.forEach { messageId in
            if imageAray.count > 0 {
                if imageAray[currentIndexPath.row].messageId == messageId {
                    imageAray.remove(at: currentIndexPath.row)
                    imageList?.reloadData()
                }
            }
        }
    }
}

extension ImagePreview : MessageEventsDelegate {
    func onMessageReceived(message: MirrorFlySDK.ChatMessage, chatJid: String) {
        
    }
    
    func onMessageStatusUpdated(messageId: String, chatJid: String, status: MirrorFlySDK.MessageStatus) {
        
    }
    
    func onMediaStatusUpdated(message: MirrorFlySDK.ChatMessage) {
        
    }
    
    func onMediaStatusFailed(error: String, messageId: String, errorCode: Int) {
        
    }
    
    func onMediaProgressChanged(message: MirrorFlySDK.ChatMessage, progressPercentage: Float) {
        
    }
    
    func onMessagesClearedOrDeleted(messageIds: Array<String>) {
        
    }
    
    func onMessagesDeletedforEveryone(messageIds: Array<String>) {
        messageIds.forEach { messageId in
            if imageAray[currentIndexPath.row].messageId == messageId {
                imageAray.remove(at: currentIndexPath.row)
                imageList?.reloadData()
            }
        }
    }
    
    func showOrUpdateOrCancelNotification() {
        
    }
    
    func onMessagesCleared(toJid: String, deleteType: String?) {
        
    }
    
    func setOrUpdateFavourite(messageId: String, favourite: Bool, removeAllFavourite: Bool) {
        
    }
    
    func onMessageTranslated(message: MirrorFlySDK.ChatMessage, jid: String) {
        
    }
    func clearAllConversationForSyncedDevice() {}
}

extension ImagePreview : AvailableFeaturesDelegate {
    
    func didUpdateAvailableFeatures(features: AvailableFeaturesModel) {
        
        availableFeatures = features
        
        let tabCount =  MainTabBarController.tabBarDelegagte?.currentTabCount()
        
        if (!(features.isGroupCallEnabled || features.isOneToOneCallEnabled) && tabCount == 5) {
            MainTabBarController.tabBarDelegagte?.removeTabAt(index: 2)
        }else {
            
            if ((features.isGroupCallEnabled || features.isOneToOneCallEnabled) && tabCount ?? 0 < 5){
                MainTabBarController.tabBarDelegagte?.resetTabs()
            }
        }
        imageList.isScrollEnabled = availableFeatures.isViewAllMediasEnabled ? true : false
    }

}
