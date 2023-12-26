//
//  PreviewViewController .swift
//  MirrorflyShareKit
//
//  Created by Sowmiya on 01/03/23.
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

class ShareKitPreviewController : ShareKitBaseViewController {
    @IBOutlet weak var addImage: UIImageView?
    @IBOutlet weak var addMoreButton: UIButton?
    @IBOutlet weak var deleteViw: UIView!
    @IBOutlet weak var addmore: UIView!
    @IBOutlet weak var captionTxt: UITextView?
    @IBOutlet weak var botomCollection: UICollectionView!
    @IBOutlet weak var topCollection: UICollectionView!
    @IBOutlet weak var captionHeightCons: NSLayoutConstraint?
    @IBOutlet weak var keyboardView: UIView?
    @IBOutlet weak var keyboardTopCons: NSLayoutConstraint?
    @IBOutlet weak var captionBottomCons: NSLayoutConstraint?
    @IBOutlet weak var TopViewCons: NSLayoutConstraint?
    @IBOutlet weak var captionViewTopCons: NSLayoutConstraint?
    @IBOutlet weak var bottomCollectionCons: NSLayoutConstraint?
    var loader: (UIView,UIActivityIndicatorView,UILabel)?
    var growingTextViewHandler:GrowingTextViewHandler?
    public var tempImageAray = [ImageData]()
    public var imageAray = [ImageData]()
    public var mediaData = [MediaData]()
    public var selectedAssets = [PHAsset]()
    public var currentSelectedAssets = [PHAsset]()
    public var currentDeSelectedAssets = [PHAsset]()

    public var selectedURL = [URL]()
    public var selectedScreenShot = [UIImage]()

    var imageEditIndex = Int()
    var botmImageIndex = Int()
    weak var delegate: ShareEditImageDelegate? = nil
    var shareDelegate: ShareKitDelegate? = nil
    var profileName = ""
    var captionText: String?
    public var iscamera = false
    var mediaProcessed = [String]()
    var id : String = emptyString()
    var isKeyboardDisabled: Bool? = false

    var jids = [String]()
    let dispatchGroup = DispatchGroup()
    let sendDispatchGroup = DispatchGroup()
    
    let backgroundQueue = DispatchQueue.init(label: "mediaQueue")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loader = Helper.getLoaderViews(view: self.view)
        // Do any additional setup after loading the view.
        captionTxt?.inputAccessoryView = UIView()
        captionTxt?.inputAccessoryView?.tintColor = .clear
        keyboardView = captionTxt?.inputAccessoryView
        DispatchQueue.main.async { [weak self] in
            self?.startLoadingIndicator(view: self?.view ?? UIView(), blurView: self?.loader?.0 ?? UIView(), activityIndicatorView: self?.loader?.1 ?? UIActivityIndicatorView(), label: self?.loader?.2 ?? UILabel(), withText: "Processing")
        }
        backgroundQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.getAssetsImageInfo(assets: strongSelf.selectedAssets, urls: strongSelf.selectedURL, images: strongSelf.selectedScreenShot)
        }
        hideKeyboardWhenTappedAround()
        setupUI()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardframeChanged),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )

    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc func keyboardframeChanged(notification: NSNotification) {
        if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue{
            let keyboardHeight = 260 - frame.cgRectValue.height
            addKeyboardConstraints(changeHeight: keyboardHeight)
        }
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
                                self?.startLoadingIndicator(view: self?.view ?? UIView(), blurView: self?.loader?.0 ?? UIView(), activityIndicatorView: self?.loader?.1 ?? UIActivityIndicatorView(),label: self?.loader?.2 ?? UILabel(), withText: processingVideo)
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
                                    self?.stopLoadingIndicator(view: self?.view ?? UIView(), blurView: self?.loader?.0 ?? UIView(), activityIndicatorView: self?.loader?.1 ?? UIActivityIndicatorView(), label: self?.loader?.2 ?? UILabel())
                                }
                            }
                            break
                        case .failed:
                            fallthrough
                        @unknown default:
                            DispatchQueue.main.async { [weak self] in
                                self?.stopLoadingIndicator(view: self?.view ?? UIView(), blurView: self?.loader?.0 ?? UIView(), activityIndicatorView: self?.loader?.1 ?? UIActivityIndicatorView(), label: self?.loader?.2 ?? UILabel())
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
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        navigationController?.navigationBar.isHidden = false
        NotificationCenter.default.removeObserver(self, name:UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name:UIApplication.willEnterForegroundNotification, object: nil)
        shareDelegate = nil
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
        captionTxt?.text = (captionText?.isNotEmpty ?? false) ? captionText : addCaption
        captionTxt?.textColor = ShareKitColor.captionTxt
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
    }
    
    private func showHideDeleteView() {
        deleteViw.isHidden = (selectedAssets.count + selectedURL.count + selectedScreenShot.count) == 1 ? true : false
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
        }
    }
    
    @IBAction func addMoreImages(_ sender: Any) {
    }
    
    @IBAction func sendAction(_ sender: Any) {
        view.endEditing(true)
        if let captionText = captionTxt {
            captionTxt?.resignFirstResponder()
            textViewDidEndEditing(captionText)
        }
        DispatchQueue.main.async { [self] in
            self.startLoadingIndicator(view: self.view ?? UIView(), blurView: self.loader?.0 ?? UIView(), activityIndicatorView: self.loader?.1 ?? UIActivityIndicatorView(), label: self.loader?.2 ?? UILabel(), withText: "Compressing 1 of \((self.imageAray.count ))")
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
                        MediaUtils.compressVideoFile(videoURL: processedVideoURL, mediaQuality: .medium) { [weak self] isSuccess, url, fileName, fileKey, fileSize , duration, error  in
                            if isSuccess {
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
                                    self?.mediaData.append(media)
                                    self?.backToConversationScreen()
                                }
                            } else {
                                DispatchQueue.main.async { [weak self] in
                                    self?.popView()
                                    self?.shareDelegate?.onError(description: error ?? "")
                                }
//                                DispatchQueue.main.async { [weak self] in
//                                    guard let strongSelf = self else { return }
//                                    strongSelf.stopLoadingIndicator(view: strongSelf.view ?? UIView(), blurView: strongSelf.loader?.0 ?? UIView(), activityIndicatorView: strongSelf.loader?.1 ?? UIActivityIndicatorView(), label: strongSelf.loader?.2 ?? UILabel())
//                                    self?.shareDelegate?.onError(description: error ?? "")
//                                }
                            }
                        }
                    }
                }else{
                    print("#media size before \(item.fileSize)")
                    MediaUtils.compressImageFile(imageData: item.mediaData!, mediaQuality: .medium) { [weak self] isSucess, data, fileName, localFilePath, fileKey, fileSize, errorMessage  in
                        print("#media size after \(fileSize)")
                        if isSucess {
                            self?.imageAray[index].isCompressed = true
                            var media = MediaData()
                            media.mediaType = .image
                            media.fileURL = localFilePath
                            media.fileName = fileName
                            media.fileSize = fileSize
                            media.fileKey = fileKey
                            media.base64Thumbnail = self?.imageAray[index].base64Image ?? emptyString()
                            media.caption = self?.imageAray[index].caption ?? emptyString()
                            self?.mediaData.append(media)
                        } else {
                            DispatchQueue.main.async { [weak self] in
                                self?.popView()
                                self?.shareDelegate?.onError(description: errorMessage ?? "")
                            }
                        }
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
            guard let self else { return }
            print("#media : ImageEditController backToConversationScreen  \(self.imageAray.count)")
            self.stopLoading()
            if self.mediaProcessed.isEmpty {
                self.delegate?.sendMedia(mediaData: self.mediaData )
                self.navigationController?.popViewController(animated: true)
            }else{
                self.startLoadingIndicator(view: self.view ?? UIView(), blurView: self.loader?.0 ?? UIView(), activityIndicatorView: self.loader?.1 ?? UIActivityIndicatorView(), label: self.loader?.2 ?? UILabel(), withText: "Compressing \((self.imageAray.filter{$0.isCompressed == true}.count ) + 1) of \((self.imageAray.count ))")
            }
        }
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        if imageAray.count > 0 {
            if imageEditIndex < imageAray.count {
                let value = imageAray[imageEditIndex]
                self.selectedURL.removeAll { url in
                    url.lastPathComponent == value.fileName
                }
                self.selectedAssets.removeAll { asset in
                    (PHAssetResource.assetResources(for: asset).first?.originalFilename ?? "") == value.fileName
                }
                self.selectedScreenShot.removeAll { asset in
                    asset.description == value.fileName
                }
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
                        if ShareChatUtils.checkImageFileFormat(format: fileExtension) {
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
        selectedURL = []
        selectedScreenShot = []
    }
    
    func closeKeyboard() {
        self.view.endEditing(true)
    }
}

extension ShareKitPreviewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
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
            autoreleasepool {
//                if let asset = imageAray[indexPath.row].phAsset {
//                    let manager = PHImageManager.default()
//                    let option = PHImageRequestOptions()
//                    option.isSynchronous = true
//                    option.version = .current
//                    manager.requestImage(for: asset, targetSize: CGSize(width: cell.cellImage?.bounds.width ?? 100, height: cell.cellImage?.bounds.height ?? 100), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
//                        cell.cellImage?.image = result
//                    })
//                } else {
//                    cell.cellImage?.image = ShareMediaUtils.resizeImage(image: imgeDetail.image ?? UIImage(), targetSize: CGSize(width: cell.cellImage?.bounds.width ?? 300, height: cell.cellImage?.bounds.height ?? 300))
//                }
                if imgeDetail.isVideo {
                    cell.cellImage?.image = imgeDetail.image
                } else {
                    if let url = imgeDetail.fileURL {
                        cell.cellImage?.image = ShareMediaUtils.downsample(imageAt: url, to: cell.cellImage?.bounds.size ?? CGSize(width: 400, height: 400))
                    } else {
                        cell.cellImage?.image = imgeDetail.image
                    }
                }
            }
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
            autoreleasepool {
//                if let asset = imageAray[indexPath.row].phAsset {
//                    let manager = PHImageManager.default()
//                    let option = PHImageRequestOptions()
//                    option.isSynchronous = true
//                    manager.requestImage(for: asset, targetSize: CGSize(width: cell.cellImage?.bounds.width ?? 100, height: cell.cellImage?.bounds.height ?? 100), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
//                        cell.cellImage?.image = result
//                    })
//                } else {
//                    cell.cellImage.image = ShareMediaUtils.resizeImage(image: imgeDetail.image ?? UIImage(), targetSize: CGSize(width: 100, height: 100))
//                }
                if imgeDetail.isVideo {
                    cell.cellImage?.image = imgeDetail.image
                } else {
                    if let url = imgeDetail.fileURL {
                        cell.cellImage?.image = ShareMediaUtils.downsample(imageAt: url, to: cell.cellImage?.bounds.size ?? CGSize(width: 400, height: 400))
                    } else {
                        cell.cellImage?.image = imgeDetail.image
                    }
                }
            }
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
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "EditImageSharedFoorterView", for: indexPath) as! EditImageSharedFoorterView
            footerView.name.text = profileName
            return footerView
            
        default:
            fatalError("Unexpected element kind")
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var visibleRect = CGRect()
        visibleRect.origin = topCollection.contentOffset
        visibleRect.size = topCollection.bounds.size
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        captionTxt?.endEditing(true)
        setCaption()
        guard let indexPath = topCollection.indexPathForItem(at: visiblePoint) else { return }
        self.imageEditIndex = indexPath.row
        botmImageIndex = indexPath.row
        botomCollection.reloadData()
        setCaption()
    }
    
    func setCaption() {
        if imageEditIndex < imageAray.count && !(imageAray.isEmpty) {
            let imgDetail = imageAray[imageEditIndex]
            if let caption = imgDetail.caption, caption != "" {
                captionTxt?.text = imgDetail.caption
                captionTxt?.textColor = ShareKitColor.captionTxt
                setCaptionHeightCons()
            } else{
                captionTxt?.text = (captionText?.isNotEmpty ?? false && imageEditIndex == 0) ? captionText : addCaption
                captionTxt?.textColor = ShareKitColor.captionTxt
                setCaptionHeightCons()
            }
        }
    }
    
    private func setCaptionHeightCons() {
        let sizeToFitIn = CGSize(width: captionTxt?.bounds.size.width ?? 0.0, height: CGFloat(MAXFLOAT))
        let newSize = captionTxt?.sizeThatFits(sizeToFitIn)
        captionHeightCons?.constant = newSize?.height ?? 0.0
    }
    
    private func addKeyboardConstraints(defaultHeight : CGFloat = -15, changeHeight: CGFloat = 0) {
        keyboardTopCons?.constant = defaultHeight + changeHeight
        keyboardTopCons?.isActive = true
        captionBottomCons?.isActive = false
        TopViewCons?.isActive = false
        captionViewTopCons?.isActive = false
        bottomCollectionCons?.isActive = true
    }
    
    private func removeKeyboardConstraints() {
        keyboardTopCons?.isActive = false
        captionBottomCons?.isActive = true
        TopViewCons?.isActive = true
        captionViewTopCons?.isActive = true
        bottomCollectionCons?.isActive = false
    }
}

extension ShareKitPreviewController : UITextViewDelegate {
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
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if imageEditIndex == 0 {
            captionText = nil
        }
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
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
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        removeKeyboardConstraints()
        if textView == captionTxt {
            if textView.text.isEmpty {
                captionTxt?.text = (captionText?.isNotEmpty ?? false) ? captionText : addCaption
            }else {
                if imageAray.count > 0 {
                    var imgDetail = imageAray[imageEditIndex]
                    imgDetail.caption = textView.text == addCaption ? "" : textView.text.trim()
                    // textView.textColor = textView.text == addCaption ? UIColor.clear : Color.captionTxt
                    imageAray[imageEditIndex] = imgDetail
                }
            }
        }
    }
}

extension ShareKitPreviewController {
    @objc func onVideoPlay(sender: UIButton) {
        print("indexPath.row: onVideoPlay")
        let index = sender.tag
        print("indexPath.row: \(index)")
        let imageDetail = imageAray[index]
        if let detail = imageDetail.processedVideoURL {
            playVideo(view: self, url: detail)
        } else {
            playVideo(view: self, phAsset: imageDetail.phAsset)
        }
    }

    func playVideo (view:UIViewController, url: URL?) {
        guard let videoURL = url else {
            return
        }
        let player = AVPlayer(url: videoURL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        view.present(playerViewController, animated: true) {
            playerViewController.player!.play()
        }
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
    
    func getAssetsImageInfo(assets: [PHAsset], urls: [URL], images: [UIImage]) {
        var isSuccess = true
        if assets.count > 0 || urls.count > 0 || images.count > 0 {
            for asset in assets {
                if isSuccess {
                    if let (fileName, data, size, image, thumbImage,isVideo) = MediaUtils.getAssetsImageInfo(asset: asset), let fileExtension =  URL(string: fileName)?.pathExtension{
                        if isVideo {
                            print("#media : ImageEditController getAssetsImageInfo VIDEO \(fileName) ")
                            
                            let videoAsset = tempImageAray.filter({$0.fileName == fileName})
                            if videoAsset.count > 0 {
                                imageAray.append(videoAsset[0])
                            } else {
                                let thumbnail = ShareMediaUtils.resizeImage(image: image, imageUrl: nil, targetSize: CGSize(width: image.size.width/2, height: image.size.height/2))
                                imageAray.append(ImageData(image: image,thumbImage: thumbnail, caption: nil, isVideo: true, phAsset: asset, isSlowMotion: false, mediaData : data,fileName : fileName, base64Image : MediaUtils.convertImageToBase64(img: thumbImage) ,fileExtension : fileExtension,fileSize: size))
                            }
                        }else{
                            if MediaUtils.checkMediaFileFormat(format:fileExtension){
                                print("#media : ImageEditController getAssetsImageInfo IMAGE \(fileName) ")
                                
                                let imageAsset = tempImageAray.filter({$0.fileName == fileName})
                                if imageAsset.count > 0 {
                                    imageAray.append(imageAsset[0])
                                } else {
                                    let thumbnail = ShareMediaUtils.resizeImage(image: image, imageUrl: nil, targetSize: CGSize(width: image.size.width/2, height: image.size.height/2))
                                    imageAray.append(ImageData(image: image,thumbImage: thumbnail, caption: nil, isVideo: false, phAsset: asset, isSlowMotion: false,mediaData : data, fileName : fileName, base64Image : MediaUtils.convertImageToBase64(img: thumbImage), fileExtension : fileExtension, fileSize: size))
                                }
                            }
                        }
                    }
                }else {
                    imageAray.removeAll()
                    break
                }
            }
            for url in urls {
                if let (fileName, data, size, image, thumbImage,isVideo) = MediaUtils.getAssetsImageInfo(url: url) {
                    if isVideo {
                        print("#media : ImageEditController getAssetsImageInfo VIDEO \(fileName), \(data), \(image), \(thumbImage) ")
                        let videoAsset = tempImageAray.filter({$0.fileName == fileName})
                        if videoAsset.count > 0 {
                            imageAray.append(videoAsset[0])
                        } else {
                            imageAray.append(ImageData(image: image, thumbImage: thumbImage, caption: nil, isVideo: true, phAsset: PHAsset(), isSlowMotion: false, processedVideoURL: url, mediaData : data,fileName : fileName, base64Image : MediaUtils.convertImageToBase64(img: thumbImage) ,fileExtension : url.pathExtension,fileSize: size))
                        }
                    }else{
                        let imageAsset = tempImageAray.filter({$0.fileName == fileName})
                        if imageAsset.count > 0 {
                            imageAray.append(imageAsset[0])
                        } else {
                            autoreleasepool {
                                imageAray.append(ImageData(image: image,thumbImage: thumbImage, caption: nil, isVideo: false, isSlowMotion: false,mediaData : data, fileName : fileName, base64Image : MediaUtils.convertImageToBase64(img: thumbImage), fileExtension : url.pathExtension, fileSize: size, fileURL: url))
                            }
                        }
                    }
                }
            }
            for image in images {
                if isSuccess {
                    if let (fileName, data, size, image, thumbImage,isVideo) = self.getAssetsFromScreenshotImageInfo(asset: image) {
                        let thumbnail = ShareMediaUtils.resizeImage(image: image, imageUrl: nil, targetSize: CGSize(width: image.size.width/2, height: image.size.height/2))
                            imageAray.append(ImageData(image: image,thumbImage: thumbnail, caption: nil, isVideo: false, isSlowMotion: false,mediaData : data, fileName : fileName, base64Image : MediaUtils.convertImageToBase64(img: thumbImage), fileExtension : "png", fileSize: size))
                    }
                }else {
                    imageAray.removeAll()
                    break
                }
            }
            checkForSlowMotionVideo()
            DispatchQueue.main.async { [weak self] in
                print("#media : ImageEditController reload collectionviews")
                self?.stopLoadingIndicator(view: self?.view ?? UIView(), blurView: self?.loader?.0 ?? UIView(), activityIndicatorView: self?.loader?.1 ?? UIActivityIndicatorView(), label: self?.loader?.2 ?? UILabel())
                self?.topCollection?.reloadData()
                self?.botomCollection.reloadData()
            }
        }
        
    }

    public  func getAssetsFromScreenshotImageInfo(asset : UIImage) -> (String,Data,Double,UIImage, UIImage,Bool)? {
        var imageData : Data? =  nil
        let fileName : String =  asset.description
        let thumbnail = ShareMediaUtils.resizeImage(image: asset, imageUrl: nil, targetSize: CGSize(width: asset.size.width, height: asset.size.height)) ?? UIImage()

         var imageSize = 0.0
        if let data:Data = asset.pngData(){
            imageData = data
            imageSize = Double(data.count)
        }
        if imageData == nil{
            return nil
        }else{
            return (fileName, imageData!, imageSize, asset , thumbnail ,false)
        }
    }
}

