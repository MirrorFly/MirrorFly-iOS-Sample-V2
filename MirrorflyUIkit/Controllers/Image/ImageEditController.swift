//
//  ImageEditController.swift
//  MirrorflyUIkit
//
//  Created by User on 01/09/21.
//

import UIKit
import Photos
import BSImagePicker
import AVKit
import Tatsi
import MirrorFlySDK
import GrowingTextViewHandler_Swift

protocol EditImageDelegate: class {
    func sendMedia(media : [MediaData])
}

class ImageEditController: UIViewController {
    @IBOutlet weak var addImage: UIImageView?
    @IBOutlet weak var addMoreButton: UIButton?
    @IBOutlet weak var deleteViw: UIView!
    @IBOutlet weak var addmore: UIView!
    @IBOutlet weak var captionTxt: MentionTextView!
    @IBOutlet weak var botomCollection: UICollectionView!
    @IBOutlet weak var topCollection: UICollectionView!
    @IBOutlet weak var captionHeightCons: NSLayoutConstraint?
    @IBOutlet weak var keyboardView: UIView?
    @IBOutlet weak var keyboardTopCons: NSLayoutConstraint?
    @IBOutlet weak var captionBottomCons: NSLayoutConstraint?
    @IBOutlet weak var TopViewCons: NSLayoutConstraint?
    @IBOutlet weak var captionViewTopCons: NSLayoutConstraint?
    @IBOutlet weak var bottomCollectionCons: NSLayoutConstraint?
    
    @IBOutlet weak var captionBaseBottom: NSLayoutConstraint!
    
    var growingTextViewHandler:GrowingTextViewHandler?
    public var tempImageAray = [ImageData]()
    public var imageAray = [ImageData]()
    public var mediaData = [MediaData]()
    public var selectedAssets = [PHAsset]()
    public var currentSelectedAssets = [PHAsset]()
    public var currentDeSelectedAssets = [PHAsset]()
    var imageEditIndex = Int() {
        didSet {
            print("imageEditIndex", imageEditIndex)
            captionTxt.resetMentionTextView()
        }
    }
    var botmImageIndex = Int()
    weak var delegate: EditImageDelegate? = nil
    var profileName = ""
    var captionText: String?
    var textMentioned = [String]()
    public var iscamera = false
    var mediaProcessed = [String]()
    var id : String = emptyString()
    var isKeyboardDisabled: Bool? = false
    
    let backgroundQueue = DispatchQueue.init(label: "mediaQueue")
    var mentionView: UIView!
    var mentionTableView: UITableView!
    var groupMembers = [GroupParticipantDetail]()
    var searchGroupMembers = [GroupParticipantDetail]()
    var getProfileDetails: ProfileDetails!
    var isMention = false 
    var mentionSearch = ""
    var mentionRange: NSRange!
    var mentionRanges: [(String, NSRange)] = []
    var mentionUsersList: [String] = []
    var mentionBaseHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        captionTxt?.inputAccessoryView = UIView()
        captionTxt?.inputAccessoryView?.tintColor = .clear
        keyboardView = captionTxt?.inputAccessoryView
        DispatchQueue.main.async { [weak self] in
            self?.startLoading(withText: "Processing")
        }
        backgroundQueue.async { [weak self] in
            _ = self?.getAssetsImageInfo(assets: self!.selectedAssets)
        }
        searchGroupMembers = groupMembers.filter({$0.profileDetail?.isBlockedByAdmin == false || $0.memberJid != AppUtils.getMyJid()}).sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
        setupUI()
    }
    
    private func checkForSlowMotionVideo() {
        imageAray.enumerated().forEach { (index, imageData) in
            if imageData.isVideo {
                if let phAsset = imageData.phAsset {
                    print("#media iteration  \(index)")
                    MediaUtils.processVideo(phAsset: phAsset) { [weak self]  phAsset, status, url, isSlowMo  in
                        switch status {
                        case .processing:
                            DispatchQueue.main.async { [weak self] in
                                self?.startLoading(withText: processingVideo)
                            }
                            break
                        case .success:
                            if let processedURL = url {
                                self?.imageAray[index].processedVideoURL = processedURL
                                self?.imageAray[index].isSlowMotion = isSlowMo
                            }
                            let unProcessedvideos = self?.imageAray.filter { item in
                                item.isVideo
                            }.filter { item in
                                item.processedVideoURL == nil
                            }
                            DispatchQueue.main.async { [weak self] in
                                print("#media unProcessedvideos count \(unProcessedvideos?.count ?? 0)")
                                if (unProcessedvideos?.count ?? -1) == 0{
                                    self?.stopLoading()
                                }
                            }
                            break
                        case .failed:
                            fallthrough
                        @unknown default:
                            DispatchQueue.main.async { [weak self] in
                                self?.stopLoading()
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        navigationController?.navigationBar.isHidden = false
        NotificationCenter.default.removeObserver(self, name:UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name:UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        GroupManager.shared.groupDelegate = self
        ContactManager.shared.profileDelegate = self
        ChatManager.shared.adminBlockDelegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        textMentioned.removeAll()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isMention {
            if searchGroupMembers.isEmpty {
                mentionBaseHeight.constant = 0
                mentionTableView.frame = .zero
            } else {
                let groupHeight = CGFloat(searchGroupMembers.count * 70)
                let groupCustomHeight = CGFloat(topCollection.bounds.height/1.8)
                print("groupHeight \(groupHeight) groupCustomHeight \(groupCustomHeight)")
                mentionBaseHeight.constant = groupHeight > groupCustomHeight ? groupCustomHeight : groupHeight
                mentionTableView.frame = CGRect(x: 0, y: 0, width: mentionView.bounds.size.width, height: mentionView.bounds.size.height)
            }
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let value = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let newHeight: CGFloat
            if #available(iOS 11.0, *) {
                newHeight = value.height - view.safeAreaInsets.bottom - 50
            } else {
                newHeight = value.height
            }
            self.captionViewTopCons?.isActive = false
            self.captionBottomCons?.constant = newHeight

        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        self.captionBottomCons?.constant = 10
        self.captionViewTopCons?.isActive = true

    }
    
    func setupUI() {
        showHideDeleteView()
        showHideAddMoreOption()
        if iscamera {
            addmore.isHidden = true
            deleteViw.isHidden = true
        }
        botomCollection.isPagingEnabled = true
        setDefault()
        captionTxt?.delegate = self
        captionTxt?.font = UIFont.font12px_appRegular()
        captionTxt?.textContainerInset = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)
//        if textMentioned.isEmpty {
//            captionTxt?.text = (captionText?.isNotEmpty ?? false) ? captionText : addCaption
//        } else {
//            var dataArray = [String]()
//            let message = ChatUtils.convertMentionUser(message: captionText ?? "", mentionedUsersIds: textMentioned)
//            dataArray.append(message)
//            dataArray.append(textMentioned.joined(separator: ","))
//            self.captionTxt?.convertAndInsert(to: dataArray, with: NSRange(location: 0, length: 0))
//        }
        captionTxt?.textColor = Color.captionTxt
        captionTxt?.layer.cornerRadius = 20
        captionTxt?.clipsToBounds = true
        growingTextViewHandler = GrowingTextViewHandler(textView: captionTxt ?? UITextView(), heightConstraint: captionHeightCons ?? NSLayoutConstraint())
        growingTextViewHandler?.minimumNumberOfLines = chatTextMinimumLines
        growingTextViewHandler?.maximumNumberOfLines = chatTextMaximumLines
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: (topCollection?.frame.size.width ?? 0.0), height: (topCollection?.frame.size.width ?? 0.0))
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        topCollection?.collectionViewLayout = layout
        topCollection?.isPagingEnabled = true
        let layout2: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout2.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout2.itemSize = CGSize(width: 50, height: 50)
        layout2.minimumInteritemSpacing = 10
        layout2.minimumLineSpacing = 2
        layout2.scrollDirection = .horizontal
        layout2.footerReferenceSize = CGSize(width: 300, height: 50)
        botomCollection!.collectionViewLayout = layout2
        topCollection?.reloadData()
        botomCollection.reloadData()
        addMentionView()
    }
    
    func addMentionView() {
        mentionView = UIView()
        mentionView.isHidden = true
        mentionView.backgroundColor = .white
        mentionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mentionView)
        
        if let textView = captionTxt {
            mentionView.bottomAnchor.constraint(equalTo: textView.topAnchor, constant: -5).isActive = true
        }
        mentionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        mentionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        mentionBaseHeight = mentionView.heightAnchor.constraint(equalToConstant: 200)
        mentionBaseHeight.isActive = true
        self.mentionView.layoutIfNeeded()
        self.view.layoutIfNeeded()
        
        mentionTableView = UITableView(frame: .zero)
        mentionTableView.translatesAutoresizingMaskIntoConstraints = false
        mentionTableView.frame = CGRect(x: 0, y: 0, width: mentionView.bounds.size.width, height: mentionView.bounds.size.height)
        mentionTableView.register(UINib(nibName: "MentionTableViewCell",
                                        bundle: .main), forCellReuseIdentifier: "MentionTableViewCell")
        mentionTableView.delegate = self
        mentionTableView.dataSource = self
        mentionTableView.estimatedRowHeight = UITableView.automaticDimension
        mentionView.addSubview(mentionTableView)

    }
    
    private func showHideDeleteView() {
        deleteViw.isHidden = selectedAssets.count == 1 ? true : false
    }
    
    private func showHideAddMoreOption() {
        addMoreButton?.isUserInteractionEnabled = selectedAssets.count == 10 ? false : true
        addMoreButton?.alpha = selectedAssets.count == 10 ? 0.4 : 1.0
        addImage?.alpha = selectedAssets.count == 10 ? 0.4 : 1.0
    }
    
    @objc func appMovedToBackground() {
        closeKeyboard()
    }
    
    @objc func appMovedToForeground() {
        if isKeyboardDisabled == false {
            captionTxt?.becomeFirstResponder()
            mentionView.isHidden = !isMention
            mentionSearch = mentionRanges.compactMap({$0.0}).joined(separator: "")
            if mentionSearch.isNotEmpty {
                let sortedMembers = groupMembers.filter({$0.profileDetail?.isBlockedByAdmin == false || $0.memberJid != AppUtils.getMyJid()}).sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
                let getGroupMembers = sortedMembers.filter{ $0.displayName.lowercased().contains(mentionSearch.lowercased())}
                searchGroupMembers = getGroupMembers
                mentionTableView.reloadData()
            }
        }
    }
    
    @IBAction func addMoreImages(_ sender: Any) {
        isKeyboardDisabled = true
        view.endEditing(true)
        addMoreImages()
    }
    
    @IBAction func sendAction(_ sender: Any) {
        view.endEditing(true)
        mentionView.isHidden = true
        if let captionText = captionTxt {
            view.endEditing(true)
        }
        DispatchQueue.main.async { [weak self] in
            self?.startLoading( withText: "Compressing 1 of \((self?.imageAray.count ?? 0)!)")
        }
        print("#media : ImageEditController sendAction \(imageAray.count)")
        mediaProcessed = imageAray.compactMap({ data in
            data.fileName
        })
        mediaData.removeAll()
        backgroundQueue.async{ [weak self] in
            self?.imageAray.enumerated().forEach { (index, item) in
                print("#media : ImageEditController \(index) \(item.caption)  \(item.fileName) \(item.mediaType) \(item.fileSize) ")
                if item.isVideo{
                    if let processedVideoURL = item.processedVideoURL, !item.inProgress{
                        print("#media size before \(item.fileSize)")
                        self?.imageAray[index].inProgress = true
                        MediaUtils.compressVideo(videoURL:processedVideoURL) { [weak self] isSuccess, url, fileName, fileKey, fileSize , duration in
                            if let compressedURL = url{
                                print("#media size before \(item.fileSize)")
                                self?.imageAray[index].isCompressed = true
                                _ = self?.mediaProcessed.popLast()
                                var media = MediaData()
                                media.mediaType = .video
                                media.fileURL = compressedURL
                                media.fileName = fileName
                                media.fileSize = fileSize
                                media.fileKey = fileKey
                                media.duration = duration
                                media.base64Thumbnail = self?.imageAray[index].base64Image ?? emptyString()
                                media.caption = self?.imageAray[index].caption ?? emptyString()
                                media.mentionedUsers = self?.imageAray[index].mentionedUsers ?? []
                                self?.mediaData.append(media)
                                self?.backToConversationScreen()
                            }
                        }
                    }
                }else{
                    print("#media size before \(item.fileSize)")
                    if let (data, fileName ,localFilePath,fileKey,fileSize) = MediaUtils.compressImage(imageData : item.mediaData!){
                        print("#media size after \(fileSize)")
                        self?.imageAray[index].isCompressed = true
                        var media = MediaData()
                        media.mediaType = .image
                        media.fileURL = localFilePath
                        media.fileName = fileName
                        media.fileSize = fileSize
                        media.fileKey = fileKey
                        media.base64Thumbnail = self?.imageAray[index].base64Image ?? emptyString()
                        media.caption = self?.imageAray[index].caption ?? emptyString()
                        media.mentionedUsers = self?.imageAray[index].mentionedUsers ?? []
                        self?.mediaData.append(media)
                    }
                    
                    _ =  self?.mediaProcessed.popLast()
                    self?.backToConversationScreen()
                }
                
            }
        }
    }
    
    
    public func backToConversationScreen(){
        FlyMessenger.saveUnsentMessage(id: id, message: emptyString())
        DispatchQueue.main.async { [weak self] in
            print("#media : ImageEditController backToConversationScreen  \(self!.imageAray.count)")
            self?.stopLoading()
            if self?.mediaProcessed.isEmpty ?? false{
                self?.navigationController?.popViewController(animated: true)
//                self?.delegate?.selectedImages(images: self?.imageAray ?? [])
                self?.delegate?.sendMedia(media: self?.mediaData ?? [])
            }else{
                self?.startLoading(withText: "Compressing \((self?.imageAray.filter{$0.isCompressed == true}.count ?? 1) + 1) of \((self?.imageAray.count ?? 0)!)")
            }
        }
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        if imageAray.count > 0 {
            if imageEditIndex < imageAray.count {
                self.selectedAssets.remove(at: imageEditIndex)
                imageAray.remove(at: imageEditIndex)
            } else {
                if imageAray.count > 0 {
                    botmImageIndex = imageEditIndex - 1
                    self.botomCollection.reloadData()
                }
            }
            topCollection?.reloadData()
            topCollection?.performBatchUpdates(nil, completion: {
                (result) in
                self.refresh()
                self.showHideDeleteView()
                self.showHideAddMoreOption()
                self.setCaption()
            })
            self.botomCollection.reloadData()
        }
    }
    
    @IBAction func close(_ sender: Any) {
        popView()
    }
    
    func PHAssetForFileURL(url: URL) -> PHAsset? {
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.version = .current
        imageRequestOptions.deliveryMode = .fastFormat
        imageRequestOptions.resizeMode = .fast
        imageRequestOptions.isSynchronous = true

        let fetchResult = PHAsset.fetchAssets(with: nil)
        var index = 0
        while index < fetchResult.count {
            if let asset = fetchResult[index] as? PHAsset {
                var found = false
                PHImageManager.default().requestImageData(for: asset,
                    options: imageRequestOptions) { (_, _, _, info) in
                    if let urlkey = info?["PHImageFileURLKey"] as? NSURL {
                        if urlkey.absoluteString! == url.absoluteString {
                                found = true
                            }
                        }
                }
                if (found) {
                    index += 1
                    return asset
                }
            }
        }

        return nil
    }
    
    func addMoreImages() {
        currentSelectedAssets.removeAll()
        currentDeSelectedAssets.removeAll()
        let imagePicker = ImagePickerController(selectedAssets: selectedAssets)
        imagePicker.settings.theme.selectionStyle = .numbered
        imagePicker.settings.fetch.assets.supportedMediaTypes = [.image,.video]
        imagePicker.settings.selection.max = 10
        imagePicker.settings.preview.enabled = true
        presentImagePicker(imagePicker, select: { [weak self] (asset) in
            // User selected an asset. Do something with it. Perhaps begin processing/upload?
            if let strongSelf = self {
                if  let assetName = asset.value(forKey: "filename") as? String {
                    let fileExtension = URL(fileURLWithPath: assetName).pathExtension
                    if ChatUtils.checkImageFileFormat(format: fileExtension) {
                        var imageSize = ChatUtils.getImageSize(asset: asset)
                        imageSize = imageSize/(1024*1024)
                        print("image size: ",imageSize)
                        if imageSize >= Float(10) {
                            AppAlert.shared.showToast(message: ErrorMessage.largeImageFile)
                            imagePicker.deselect(asset: asset)
                        } else {
                            strongSelf.selectedAssets.append(asset)
                            strongSelf.currentSelectedAssets.append(asset)
                        }
                    } else if asset.mediaType == PHAssetMediaType.video {
                        if MediaUtils.isVideoLimit(asset: asset, videoLimit: 30) {
                            strongSelf.selectedAssets.append(asset)
                            strongSelf.currentSelectedAssets.append(asset)
                        } else {
                            AppAlert.shared.showToast(message: ErrorMessage.largeVideoFile)
                            imagePicker.deselect(asset: asset)
                        }
                    } else {
                        AppAlert.shared.showToast(message: fileformat_NotSupport)
                    }
                }
            }
            if imagePicker.selectedAssets.count > 9 {
                AppAlert.shared.showToast(message: ErrorMessage.restrictedMoreImages)
            }
        }, deselect: { [weak self] (asset) in
            // User deselected an asset. Cancel whatever you did when asset was selected.
            if let strongSelf = self {
                strongSelf.selectedAssets.enumerated().forEach { index , element in
                    if element == asset {
                        strongSelf.currentDeSelectedAssets.append(element)
                        strongSelf.selectedAssets.remove(at: index)
                    }
                }
            }
        }, cancel: { [weak self] (assets) in
            // User canceled selection.
            self?.isKeyboardDisabled = false
            self?.currentSelectedAssets.forEach({ asset in
                self?.selectedAssets.enumerated().forEach({ (index,element) in
                    if element == asset {
                        self?.selectedAssets.remove(at: index)
                    }
                })
            })
            self?.currentDeSelectedAssets.forEach({ asset in
                self?.selectedAssets.append(asset)
            })
            if self?.selectedAssets.count == 0 {
                self?.popView()
            }
        }, finish: { [weak self] (assets) in
            if let strongSelf = self {
                strongSelf.currentSelectedAssets.removeAll()
                strongSelf.currentDeSelectedAssets.removeAll()
                strongSelf.isKeyboardDisabled = false
                strongSelf.tempImageAray = strongSelf.imageAray
                strongSelf.imageAray.removeAll()
                DispatchQueue.main.async { [weak self] in
                    self?.startLoading(withText: "Processing")
                }
                self?.backgroundQueue.async { [weak self] in
                    _ = self?.getAssetsImageInfo(assets: assets)
                    DispatchQueue.main.async {
                        if !strongSelf.iscamera {
                            strongSelf.botomCollection.reloadData()
                        }
                        strongSelf.setDefault()
                        strongSelf.refresh()
                        strongSelf.showHideDeleteView()
                        strongSelf.showHideAddMoreOption()
                    }
                }
                
            }
        })
    }
    
    func setDefault() {
        imageEditIndex = 0
        setCaption()
        botmImageIndex = 0
    }
    
    func refresh ()
    {
        if self.imageAray.count != 0
        {
            var visibleRect = CGRect()
            visibleRect.origin = topCollection.contentOffset
            visibleRect.size = topCollection.bounds.size
            let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
            if let indexPath = topCollection.indexPathForItem(at: visiblePoint)
            {
                self.imageEditIndex = indexPath.row
                let nxtimgDta = imageAray[imageEditIndex]
                botmImageIndex = imageEditIndex
                self.captionTxt?.text = nxtimgDta.caption
                captionTxt?.text = (nxtimgDta.caption?.isNotEmpty ?? false) ? nxtimgDta.caption : addCaption
            }
        }
    }
    
    func getAssetThumbnail(assets: [PHAsset]) -> [ImageData]
    {
        var arrayOfImages = [ImageData]()
        for asset in assets {
        if  let assetName = asset.value(forKey: "filename") as? String {
                let fileExtension = URL(fileURLWithPath: assetName).pathExtension
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.version = .original
            options.isSynchronous = true
            manager.requestImageData(for: asset, options: options) { data, _, _, _ in
            if asset.mediaType == PHAssetMediaType.image {
                if let data = data {
                    if  let  img = UIImage(data: data) {
                        if ChatUtils.checkImageFileFormat(format: fileExtension) {
                            let imageDetail: ImageData = ImageData(image: img, caption: nil, isVideo: false, phAsset: nil, isSlowMotion: false)
                            arrayOfImages.append(imageDetail)
                        }
                    }
                }
            } else if asset.mediaType == PHAssetMediaType.video {
                if let data = data {
                  if  let  image = UIImage(data: data) {
                      let imageDetail: ImageData = ImageData(image: image, caption: nil, isVideo: true, phAsset: asset, isSlowMotion: false)
                    arrayOfImages.append(imageDetail)
                    }
                }
            }
                
            } } else {
            arrayOfImages.removeAll()
            break
        }
    }
        return arrayOfImages
    }
    
    func popView() {
        navigationController?.popViewController(animated: true)
        selectedAssets = []
        captionTxt?.text = ""
    }
    
    func closeKeyboard() {
        self.view.endEditing(true)
    }
}

extension ImageEditController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == topCollection {
        return imageAray.count
        }else{
            if iscamera {
                return   0
            }else{
                return imageAray.count
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == topCollection {
        let noOfCellsInRow = 1

        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout

        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))

        let size = Int((view.bounds.width))
            let height = Int((view.bounds.height))

        return CGSize(width: size, height: height)
        }else {
        return CGSize(width: 50, height: 50)
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == topCollection {
            let cell:EditImageCell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.editImageCell, for: indexPath) as! EditImageCell
            let imgeDetail = imageAray[indexPath.row]
            cell.cellImage?.contentMode = .scaleAspectFit
            cell.cellImage?.image = imgeDetail.image
            cell.playButton?.isHidden = true
            print("ImageEditorController \(imgeDetail.isVideo)")
            if imgeDetail.isVideo {
                cell.playButton?.isHidden = false
            }
            cell.playButton?.tag = indexPath.row
            cell.playButton?.addTarget(self, action: #selector(onVideoPlay(sender:)), for: .touchUpInside)
            return cell
        }else{
            let cell:ListImageCell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.listImageCell, for: indexPath) as! ListImageCell
            let imgeDetail = imageAray[indexPath.row]
            cell.cellImage.contentMode = .scaleAspectFill
            cell.cellImage.image = imgeDetail.image
            if botmImageIndex == indexPath.row {
                cell.setBorder()
            }else {
                cell.removeBorder()
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == botomCollection {
            topCollection?.scrollToItem(at: indexPath, at: .left, animated: true)
            imageEditIndex = indexPath.row
            botmImageIndex = indexPath.row
            botomCollection.reloadData()
            topCollection.layoutIfNeeded()
            let rect = topCollection.layoutAttributesForItem(at:indexPath)?.frame
            topCollection.scrollRectToVisible(rect!, animated: true)
            setCaption()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionView.elementKindSectionFooter:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "EditImageFoorterView", for: indexPath) as! EditImageFoorterView
            footerView.name.text = profileName
            return footerView
            
        default:
            fatalError("Unexpected element kind")
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !isMention {
            captionText = ""
            var visibleRect = CGRect()
            visibleRect.origin = topCollection.contentOffset
            visibleRect.size = topCollection.bounds.size
            let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
            captionTxt?.endEditing(true)
            guard let indexPath = topCollection.indexPathForItem(at: visiblePoint) else { return }
            self.imageEditIndex = indexPath.row
            botmImageIndex = indexPath.row
            botomCollection.reloadData()
            setCaption()
            searchGroupMembers = mentionArrayFilter().sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
        }
    }
    
    func setCaption() {
        if imageEditIndex < imageAray.count && !(imageAray.isEmpty) {
            let imgDetail = imageAray[imageEditIndex]
            if let caption = imgDetail.caption, caption != "" {
                if imgDetail.mentionedUsers.isEmpty {
                    executeOnMainThread {
                        self.captionTxt?.text = imgDetail.caption
                    }
                } else {
                    executeOnMainThread {
                        self.captionTxt?.text = ""
                        self.captionTxt?.textColor = Color.captionTxt
                        var dataArray = [String]()
                        let message = ChatUtils.convertMentionUser(message: caption, mentionedUsersIds: imgDetail.mentionedUsers)
                        dataArray.append(message)
                        dataArray.append(imgDetail.mentionedUsers.joined(separator: ","))
                        self.captionTxt?.convertAndInsert(to: dataArray, with: NSRange(location: 0, length: 0))
                    }
//                    captionTxt?.attributedText = ChatUtils.getMentionTextContent(message: caption, isMessageSentByMe: true, mentionedUsers: imgDetail.mentionedUsers)
                }
                setCaptionHeightCons()
            } else{
                executeOnMainThread {
                    self.captionTxt?.textColor = Color.captionTxt
                    if self.textMentioned.isEmpty {
                        self.captionTxt?.text = (self.captionText?.isNotEmpty ?? false) ? self.captionText : addCaption
                        self.imageAray[self.imageEditIndex].caption = (self.captionText?.isNotEmpty ?? false) ? self.captionText : ""
                    } else {
                        var dataArray = [String]()
                        let message = ChatUtils.convertMentionUser(message: self.captionText ?? "", mentionedUsersIds: self.textMentioned)
                        dataArray.append(message)
                        dataArray.append(self.textMentioned.joined(separator: ","))
                        self.captionTxt?.convertAndInsert(to: dataArray, with: NSRange(location: 0, length: 0))
                        self.imageAray[self.imageEditIndex].caption = self.captionTxt.mentionText
                        self.imageAray[self.imageEditIndex].mentionedUsers = self.textMentioned
                        self.textMentioned.removeAll()
                    }
                    self.setCaptionHeightCons()
                }
            }
        }
    }
    
    private func setCaptionHeightCons() {
        executeOnMainThread {
            let sizeToFitIn = CGSize(width: self.captionTxt?.bounds.size.width ?? 0.0, height: CGFloat(MAXFLOAT))
            let newSize = self.captionTxt?.sizeThatFits(sizeToFitIn)
            self.captionHeightCons?.constant = newSize?.height ?? 0.0
        }
    }
    
    private func addKeyboardConstraints() {
        //keyboardTopCons?.isActive = true
        //captionBottomCons?.isActive = false
        //TopViewCons?.isActive = false
        //captionViewTopCons?.isActive = false
        //bottomCollectionCons?.isActive = true
    }
    
    private func removeKeyboardConstraints() {
        //keyboardTopCons?.isActive = false
        //captionBottomCons?.isActive = true
        //TopViewCons?.isActive = true
        //captionViewTopCons?.isActive = true
        //bottomCollectionCons?.isActive = false
    }
}

extension ImageEditController : UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        addKeyboardConstraints()
        if textView == captionTxt {
            if textView.textColor == UIColor.darkGray {
                textView.textColor = UIColor.black
                if textView.text == addCaption {
                    textView.text = ""
                }
            }
        }
        if captionTxt?.text.contains(addCaption) == true {
            textView.text = captionTxt?.text.replacingOccurrences(of: addCaption, with: "")
        }
        if getProfileDetails.profileChatType == .groupChat && textView.text.last == "@" {
            mentionView.isHidden = false
            viewDidLayoutSubviews()
        }
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if textView.text.utf16.count > textView.selectedRange.location && isMention {
            textView.selectedRange = NSRange(location: (mentionRange.location+mentionRanges.count+1), length: 0)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {

        if text.trim().utf16.count > 1 && !isMention {
            return clipboardCopyAction(textView, shouldChangeTextIn: range, replacementText: text)
        } else if text.trim().count > 1 && isMention{
            mentionView.isHidden = true
            resetGroupMention()
            mentionTableView.reloadData()
            self.viewDidLayoutSubviews()
            return clipboardCopyAction(textView, shouldChangeTextIn: range, replacementText: text)
        }
        if getProfileDetails.profileChatType == .groupChat {
            mentionshouldChangeTextIn(textView, shouldChangeTextIn: range, replacementText: text)
        }

        if imageEditIndex == 0 {
            captionText = nil
        }
        if let character = text.first, character.isNewline {
            textView.resignFirstResponder()
            removeKeyboardConstraints()
            return false
        }
        if text.count > 1024 {
            textView.text = String(text.prefix(1024))
            self.perform(#selector(self.getHintsFromTextField), with: textView, afterDelay: 0.5)
            return false
        }
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        return numberOfChars <= 1024
    }
    
    func clipboardCopyAction(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let clipBoardStrings = UIPasteboard.general.strings, !clipBoardStrings.isEmpty, getProfileDetails.profileChatType == .groupChat {
            if "\(clipBoardStrings.joined(separator: " ").utf16)" != "\(text.trim().utf16)" {
                if getProfileDetails.profileChatType == .groupChat {
                    self.captionTxt.shouldChangeTextIn(textView, shouldChangeTextIn: range, replacementText: text)
                }
                return true
            } else {
                if clipBoardStrings.count == 2 {
                    captionTxt.convertAndInsert(to: clipBoardStrings, with: range)
                    UIPasteboard.general.strings = []
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
                        let endPosition = self.captionTxt.endOfDocument
                        self.captionTxt.selectedTextRange = self.captionTxt.textRange(from: endPosition, to: endPosition)
                    })
                    return false
                } else {
                    if getProfileDetails.profileChatType == .groupChat {
                        self.captionTxt.shouldChangeTextIn(textView, shouldChangeTextIn: range, replacementText: text)
                    }
                    return true
                }
            }
        } else if let clipBoardStrings = UIPasteboard.general.strings, !clipBoardStrings.isEmpty, getProfileDetails.profileChatType == .singleChat {
            if "\(clipBoardStrings.joined(separator: " ").utf16)" != "\(text.trim().utf16)" {
                if getProfileDetails.profileChatType == .groupChat {
                    self.captionTxt.shouldChangeTextIn(textView, shouldChangeTextIn: range, replacementText: text)
                }
                return true
            } else {
                return true
            }
        }
        if getProfileDetails.profileChatType == .groupChat {
            self.captionTxt.shouldChangeTextIn(textView, shouldChangeTextIn: range, replacementText: text)
        }
        return true
    }
    
    func setGroupmention(range: NSRange) {
        resetGroupMention()
        searchGroupMembers = groupMembers.sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() }).filter({$0.memberJid != AppUtils.getMyJid() || $0.profileDetail?.isBlockedByAdmin == false})
        mentionTableView.reloadData()
        isMention = true
        mentionRange = range
        self.view.bringSubviewToFront(mentionView)
        self.viewDidLayoutSubviews()
        mentionView.isHidden = false
    }
    
    func resetGroupMention() {
        mentionSearch = ""
        mentionRange = nil
        isMention = false
    }
    @objc func getHintsFromTextField(textView: UITextView) {
        textView.selectedRange = NSRange(location: textView.text.count, length: 1)
    }
    func textViewDidChange(_ textView: UITextView) {
        if textView == captionTxt {
            let sizeToFitIn = CGSize(width: captionTxt?.bounds.size.width ?? 0.0, height: CGFloat(MAXFLOAT))
            let newSize = captionTxt?.sizeThatFits(sizeToFitIn)
            if newSize?.height ?? 0.0 <= 110 {
                captionHeightCons?.constant = newSize?.height ?? 0.0
            } else {
                captionHeightCons?.constant = 110
                captionTxt?.isScrollEnabled = true
            }
        }
        if getProfileDetails.profileChatType == .groupChat && !isMention {
            captionTxt?.textDidChange(textView, isCaption: true)
            setMentionedUsers()
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        removeKeyboardConstraints()
        captionTxt?.textViewEnd()
        if textView == captionTxt {
            if textView.text.isEmpty {
                captionTxt?.text = (captionText?.isNotEmpty ?? false) ? captionText : addCaption
            }else {
                var imgDetail = imageAray[imageEditIndex]
                if getProfileDetails.profileChatType == .groupChat {
                   // setMentionedUsers()
                } else {
                    imgDetail.caption = textView.text == addCaption ? "" : textView.text.trim()
                    imageAray[imageEditIndex] = imgDetail
                }
               // textView.textColor = textView.text == addCaption ? UIColor.clear : Color.captionTxt
            }
        }
    }
    
    func setMentionedUsers() {
        var imgDetail = imageAray[imageEditIndex]
        imgDetail.caption = captionTxt?.text == addCaption ? "" : captionTxt?.mentionText?.trim()
        imgDetail.mentionedUsers = captionTxt?.mentionedUsers ?? []
        imgDetail.mentionedRange = captionTxt?.selectedRange ?? NSRange(location: 0, length: 0)
        imageAray[imageEditIndex] = imgDetail
    }
    
    func resetMention() {
        isMention = false
        mentionSearch = ""
        mentionRange = nil
        mentionRanges.removeAll()
        getGroupMember()
    }
}

extension ImageEditController {
    @objc func onVideoPlay(sender: UIButton) {
        print("indexPath.row: onVideoPlay")
        let index = sender.tag
        print("indexPath.row: \(index)")
        let imageDetail = imageAray[index]
        playVideo(view: self, phAsset: imageDetail.phAsset)
    }
    
    func playVideo (view:UIViewController, phAsset: PHAsset?) {
        guard (phAsset!.mediaType == PHAssetMediaType.video) else {
            print("Not a valid video media type")
            return
        }
        
        PHCachingImageManager().requestAVAsset(forVideo: phAsset!, options: nil) { (asset, audioMix, args) in
            if let _ = asset as? AVComposition {
                let options = PHVideoRequestOptions()
                options.isNetworkAccessAllowed = true
                PHCachingImageManager().requestPlayerItem(forVideo: phAsset!, options: options) { (playerItem, info) in
                    DispatchQueue.main.async {
                        let player = AVPlayer(playerItem: playerItem)
                        let playerViewController = AVPlayerViewController()
                        playerViewController.player = player
                        view.present(playerViewController, animated: true) {
                            playerViewController.player!.play()
                        }
                    }
                }
            } else {
                let asset = asset as! AVURLAsset
                DispatchQueue.main.async {
                    let player = AVPlayer(url: asset.url)
                    let playerViewController = AVPlayerViewController()
                    playerViewController.player = player
                    view.present(playerViewController, animated: true) {
                        playerViewController.player!.play()
                    }
                }
            }
        }
    }
    
    func getAssetsImageInfo(assets: [PHAsset]){
        var isSuccess = true
        if assets.count > 0 {
            for asset in assets {
                if isSuccess {
                    if let (fileName, data, size, image, thumbImage,isVideo) = MediaUtils.getAssetsImageInfo(asset: asset), let fileExtension =  URL(string: fileName)?.pathExtension{
                        if isVideo {
                            print("#media : ImageEditController getAssetsImageInfo VIDEO \(fileName) ")
                            
                            let videoAsset = tempImageAray.filter({$0.fileName == fileName})
                            if videoAsset.count > 0 {
                                imageAray.append(videoAsset[0])
                            } else {
                                imageAray.append(ImageData(image: image, caption: nil, isVideo: true, phAsset: asset, isSlowMotion: false, mediaData : data,fileName : fileName, base64Image : MediaUtils.convertImageToBase64String(img: thumbImage) ,fileExtension : fileExtension,fileSize: size))
                            }
                        }else{
                            if MediaUtils.checkMediaFileFormat(format:fileExtension){
                                print("#media : ImageEditController getAssetsImageInfo IMAGE \(fileName) ")
                                
                                let imageAsset = tempImageAray.filter({$0.fileName == fileName})
                                if imageAsset.count > 0 {
                                    imageAray.append(imageAsset[0])
                                } else {
                                    imageAray.append(ImageData(image: image, caption: nil, isVideo: false, isSlowMotion: false,mediaData : data, fileName : fileName, base64Image : MediaUtils.convertImageToBase64String(img: thumbImage), fileExtension : fileExtension, fileSize: size))
                                }
                            }
                        }
                    }
                }else {
                    imageAray.removeAll()
                    break
                }
            }
            checkForSlowMotionVideo()
            self.setCaption()
            DispatchQueue.main.async { [weak self] in
                print("#media : ImageEditController reload collectionviews")
                self?.stopLoading()
                self?.topCollection?.reloadData()
                self?.botomCollection.reloadData()
            }
        }
        
    }
}
extension ImageEditController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchGroupMembers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "MentionTableViewCell", for: indexPath) as? MentionTableViewCell {
            if let profileDetail = searchGroupMembers[indexPath.row].profileDetail {
                let placeholder = UIImage(named: "ic_profile_placeholder") ?? UIImage()
                if profileDetail.contactType == .deleted || profileDetail.isBlockedMe || profileDetail.isBlockedByAdmin || (IS_LIVE && ENABLE_CONTACT_SYNC && profileDetail.isItSavedContact == false){
                    cell.userImageView.image = placeholder
                } else {
                    let imageUrl = searchGroupMembers[indexPath.row].profileDetail?.image ?? ""
                    cell.userImageView.sd_setImage(with: ChatUtils.getUserImaeUrl(imageUrl: imageUrl),
                                                   placeholderImage: placeholder)
                }
            }
            cell.userNameLabel.text = searchGroupMembers[indexPath.row].displayName
            cell.selectionStyle = .none
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selected = searchGroupMembers[indexPath.row].profileDetail?.name, let Jid = searchGroupMembers[indexPath.row].profileDetail?.jid {
            if let userId = try? FlyUtils.getIdFromJid(jid: Jid) {
                if let lastRange = mentionRanges.last {
                    captionTxt?.text = captionTxt?.text.replacing("", range: NSRange(location: mentionRange.location, length: ((lastRange.1.location+lastRange.1.length) - mentionRange.location)))
                } else {
                    captionTxt?.text = captionTxt?.text.replacing("", range: NSRange(location: mentionRange.location, length: 1))
                }
                captionTxt?.insert(to: selected, userId: userId, isCaption: true)
                mentionView.isHidden = true
                resetMention()
                setMentionedUsers()
            }
        }
    }
    
}

extension ImageEditController: GroupEventsDelegate {
    func didAddNewMemeberToGroup(groupJid: String, newMemberJid: String, addedByMemberJid: String) {
        getGroupMember()
    }
    
    func didRemoveMemberFromGroup(groupJid: String, removedMemberJid: String, removedByMemberJid: String) {
        getGroupMember()
    }
    
    func didFetchGroupProfile(groupJid: String) {
        
    }
    
    func didUpdateGroupProfile(groupJid: String) {
        
    }
    
    func didMakeMemberAsAdmin(groupJid: String, newAdminMemberJid: String, madeByMemberJid: String) {
        
    }
    
    func didRemoveMemberFromAdmin(groupJid: String, removedAdminMemberJid: String, removedByMemberJid: String) {
        
    }
    
    func didDeleteGroupLocally(groupJid: String) {
        
    }
    
    func didLeftFromGroup(groupJid: String, leftUserJid: String) {
        
    }
    
    func didCreateGroup(groupJid: String) {
        
    }
    
    func didFetchGroups(groups: [MirrorFlySDK.ProfileDetails]) {
        
    }
    
    func didFetchGroupMembers(groupJid: String) {
        getGroupMember()
    }
    
    func didReceiveGroupNotificationMessage(message: MirrorFlySDK.ChatMessage) {
        
    }
    
    
}

extension ImageEditController: ProfileEventsDelegate {
    func userCameOnline(for jid: String) {
        
    }
    
    func userWentOffline(for jid: String) {
        
    }
    
    func userProfileFetched(for jid: String, profileDetails: MirrorFlySDK.ProfileDetails?) {
        
    }
    
    func myProfileUpdated() {
        
    }
    
    func usersProfilesFetched() {
        
    }
    
    func blockedThisUser(jid: String) {
        
    }
    
    func unblockedThisUser(jid: String) {
        
    }
    
    func usersIBlockedListFetched(jidList: [String]) {
        
    }
    
    func usersBlockedMeListFetched(jidList: [String]) {
        
    }
    
    func userUpdatedTheirProfile(for jid: String, profileDetails: MirrorFlySDK.ProfileDetails) {
        
    }
    
    func userBlockedMe(jid: String) {
        if let member = searchGroupMembers.filter({$0.memberJid == jid}).first {
            if let profile = ChatManager.profileDetaisFor(jid: jid) {
                member.profileDetail = profile
                mentionTableView.reloadData()
            }
        }
    }
    
    func userUnBlockedMe(jid: String) {
        if let member = searchGroupMembers.filter({$0.memberJid == jid}).first {
            if let profile = ChatManager.profileDetaisFor(jid: jid) {
                member.profileDetail = profile
                mentionTableView.reloadData()
            }
        }
    }
    
    func hideUserLastSeen() {
        
    }
    
    func getUserLastSeen() {
        
    }
    
    func userDeletedTheirProfile(for jid: String, profileDetails: MirrorFlySDK.ProfileDetails) {
        getGroupMember()
    }
    
    
}

extension ImageEditController: AdminBlockDelegate {
    func didBlockOrUnblockContact(userJid: String, isBlocked: Bool) {
        getGroupMember()
    }
    
    func didBlockOrUnblockSelf(userJid: String, isBlocked: Bool) {
        
    }
    
    func didBlockOrUnblockGroup(groupJid: String, isBlocked: Bool) {
        
    }
    
}

extension ImageEditController {
    func getGroupMember() {
        if getProfileDetails.profileChatType == .groupChat {
            groupMembers = [GroupParticipantDetail]()
            groupMembers =  GroupManager.shared.getGroupMemebersFromLocal(groupJid: getProfileDetails.jid).participantDetailArray.filter({$0.memberJid != AppUtils.getMyJid()})
            print("getGrouMember \(groupMembers.count)")
            searchGroupMembers = mentionArrayFilter().sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
            mentionTableView.reloadData()
//            let sortedMembers = groupMembers.filter({$0.memberJid != FlyDefaults.myJid || $0.profileDetail?.isBlockedByAdmin == false}).sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
//            let getGroupMembers = mentionSearch.isEmpty ? sortedMembers : sortedMembers.filter{ $0.displayName.lowercased().contains(mentionSearch.lowercased())}.sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
//            if searchGroupMembers != getGroupMembers {
//                searchGroupMembers = getGroupMembers
//                mentionTableView.reloadData()
//            }
        }
    }
    
    func mentionshouldChangeTextIn(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) {
        if text == " " && (text.count == 1) && isMention {
            mentionRanges.append((text, NSRange(location: range.location, length: text.utf16.count)))
            mentionSearch = mentionRanges.compactMap({$0.0}).joined(separator: "")
            searchGroupMembers = mentionSearch.isEmpty ? mentionArrayFilter().sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() }) : mentionArraySearchFilter().sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
            self.viewDidLayoutSubviews()
            mentionTableView.reloadData()
        } else if text.trim().utf16.isEmpty {
            if isMention, text != "@" {
                mentionRanges = mentionRanges.filter({ $0.1 != range})
                mentionSearch = mentionRanges.compactMap({$0.0}).joined(separator: "")
                let textviewString: String = "\(textView.text.trim().utf16)"
                if mentionSearch.isEmpty, textviewString.substringFromNSRange(range) == "@" {
                    resetGroupMention()
                    mentionView.isHidden = true
                    self.viewDidLayoutSubviews()
                } else {
                    searchGroupMembers = mentionSearch.isEmpty ? mentionArrayFilter().sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() }) : mentionArraySearchFilter().sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
                    updateGroupmention()
                }
            } else {
                searchGroupMembers.removeAll()
                self.viewDidLayoutSubviews()
                mentionTableView.reloadData()
            }
        } else {
            if text == "@" && !isMention {
                if range.location == 0 {
                    mentionRange = range
                    setGroupmention(range: range)
                    mentionTableView.reloadData()
                    self.viewDidLayoutSubviews()
                } else if textView.text.substringFromNSRange(NSRange(location: range.location-1, length: 1)) == " " {
                    mentionRange = range
                    setGroupmention(range: range)
                    mentionTableView.reloadData()
                    self.viewDidLayoutSubviews()
                }
            } else if isMention && text != "@" {
                mentionRanges.append((text, NSRange(location: range.location, length: text.utf16.count)))
                mentionSearch = mentionRanges.compactMap({$0.0}).joined(separator: "")
                searchGroupMembers = mentionArraySearchFilter().sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
                updateGroupmention()
            } else if text == "@" && isMention {
                if textView.text.substringFromNSRange(NSRange(location: range.location-1, length: 1)) == " " {
                    mentionRange = range
                    setGroupmention(range: range)
                    mentionTableView.reloadData()
                    self.viewDidLayoutSubviews()
                } else {
                    searchGroupMembers.removeAll()
                    self.viewDidLayoutSubviews()
                    resetGroupMention()
                }
            }
        }
        captionTxt.shouldChangeTextIn(textView, shouldChangeTextIn: range, replacementText: text)
    }
    
    func updateGroupmention() {
        if searchGroupMembers.isEmpty {
            self.viewDidLayoutSubviews()
        } else {
            mentionTableView.reloadData()
            self.viewDidLayoutSubviews()
        }
    }
    
//    func setGroupmention(range: NSRange) {
//        resetGroupMention()
//        searchGroupMembers = mentionArrayFilter().sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
//        mentionTableView.reloadData()
//        isMention = true
//        mentionRange = range
//        self.view.bringSubviewToFront(mentionBaseView)
//        self.viewDidLayoutSubviews()
//        mentionBaseView.isHidden = false
//    }
//    
//    func resetGroupMention() {
//        mentionSearch = ""
//        mentionRange = nil
//        mentionRanges.removeAll()
//        isMention = false
//    }
    
    func mentionArrayFilter() -> [GroupParticipantDetail] {
        groupMembers.filter({ $0.memberJid != AppUtils.getMyJid() && $0.profileDetail?.isBlockedByAdmin == false })
    }
    
    func mentionArraySearchFilter() -> [GroupParticipantDetail] {
        groupMembers.filter({ $0.displayName.lowercased().contains(mentionSearch.lowercased()) && $0.memberJid != AppUtils.getMyJid() && $0.profileDetail?.isBlockedByAdmin == false })
    }
    
}
