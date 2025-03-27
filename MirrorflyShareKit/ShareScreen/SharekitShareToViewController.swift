//
//  shareViewController.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya T on 14/12/21.
//

import UIKit
import RxSwift
import Photos
import PhotosUI
import MobileCoreServices
import Contacts
import MirrorFlySDK

protocol SendSelectecUserDelegate {
    func sendSelectedUsers(selectedUsers: [Profile],completion: @escaping (() -> Void))
}

class SharekitShareToViewController: ShareKitBaseViewController {
    @IBOutlet weak var shareToTableView: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl?
    @IBOutlet weak var searchBar: UISearchBar?
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var emptyMessageView: UIView?
    @IBOutlet weak var segmentControlView: UIView?
    @IBOutlet weak var sendButton: UIButton?
    @IBOutlet weak var shareHeaderView: UIView?
    @IBOutlet weak var shareViewHeightCons: NSLayoutConstraint?
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    private var contactViewModel : ContactViewModel?
    private var recentChatViewModel: ShareKitRecentChatViewModel?
    var getRecentChat: [RecentChat] = []
    var getAllRecentChat: [RecentChat] = []
    var filteredContactList =  [ProfileDetails]()
    var allContactsList =  [ProfileDetails]()
    var isSearchEnabled: Bool = false
    var randomColors = [UIColor?]()
    var segmentSelectedIndex: Int? = 0
    var selectedProfiles: [Profile] = []
    var pageDismissClosure:(() -> Void)?
    var selectedUserDelegate: SendSelectecUserDelegate? = nil
    var getProfileDetails: ProfileDetails?
    var shareMessages: [SelectedMessages] = []
    var searchedText : String = emptyString()
    var refreshProfileDelegate: RefreshProfileInfo?
    var fromJid : String? = nil
    var shareModel = ShareKitViewModel()
    var attachments: [NSItemProvider] = [NSItemProvider]()
    var mediaFiles: [MediaData] = []
    var shareKitViewModel = ShareKitViewModel.shared
    var keyboardShown = false
//    let documentShareDispatchGroup = DispatchGroup()
//    let documentProfileShareDispatchGroup = DispatchGroup()
//    let contactShareDispatchGroup = DispatchGroup()
//    let dispatchGroup = DispatchGroup()
//    let sendDispatchGroup = DispatchGroup()
//    var isProcessing = true

    let child = SpinnerViewController()

    var totalPages = 2
    var totalUsers = 0
    var nextPage = 1
    var searchTotalPages = 2
    var searchTotalUsers = 0
    var searchNextPage = 1
    var isLoadingInProgress = false
    var searchTerm = emptyString()
    let disposeBag = DisposeBag()
    let searchSubject = PublishSubject<String>()
    var internetObserver = PublishSubject<Bool>()
    var selectedJids = [String]()
    var loadingCompleted = false
    var isFirstPageLoaded = false{
       didSet {
           print("value \(isFirstPageLoaded)")
       }
   }

    var messageIDs = [String]()
    var uploadedMessageIDs = [String]()
    var shareMediaCount = Int()
    var isXmppConnected = false

    var uploadingMessages = [String]()
    var forwardingMessages = [String]()
    var totalMessages = 0

    var sendingMessagesCount = Int()

    override func viewDidLoad() {
        super.viewDidLoad()
        setViewModelData()
        handleBackgroundAndForground()
        contactViewModel =  ContactViewModel()
        recentChatViewModel = ShareKitRecentChatViewModel()
        configTableView()
        loadChatList()
        //setUpStatusBar()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        searchSubject.throttle(.milliseconds(25), scheduler: MainScheduler.instance).distinctUntilChanged().subscribe { [weak self] term in
            self?.searchTerm = term
            self?.filteredContactList.removeAll()
            self?.allContactsList.removeAll()
            self?.shareToTableView.reloadData()
            self?.getUsersList(pageNo: 1, pageSize: 20, searchTerm: term)
        } onError: { error in } onCompleted: {} onDisposed: {}.disposed(by: disposeBag)
        internetObserver.throttle(.seconds(4), latest: false ,scheduler: MainScheduler.instance).subscribe { [weak self] event in
            switch event {
            case .next(let data):
                print("#contact next ")
                guard let self = self else{
                    return
                }
                if data {
                    self.resumeLoading()
                }
            case .error(let error):
                print("#contactSync error \(error.localizedDescription)")
            case .completed:
                print("#contactSync completed")
            }
            
        }.disposed(by: disposeBag)

    }
    
    @objc override func keyboardWillShow(notification: NSNotification) {
        keyboardShown = true
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            shareToTableView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height + (shareToTableView?.rowHeight ?? 0.0) + 30, right: 0)
        }
    }
    
    @objc override func keyboardWillHide(notification: NSNotification) {
        keyboardShown = false
        shareToTableView?.contentInset = .zero
    }
    
    func checkMessageValidation(messages: [String]) {
        var isMessageExist: [String] = []
        shareMessages.forEach { shareMessage in
            isMessageExist += messages.filter({$0 == shareMessage.chatMessage.messageId})
        }
        if isMessageExist.count > 0 {
            DispatchQueue.main.async { [self] in
                ShareKitAlert.shared.showToast(controller: self, message: "Your selected message is no longer available")
                self.pageDismissClosure?()
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    // MARK: ConfigTableView
    private func configTableView() {
            searchBar?.delegate = self
            shareToTableView?.rowHeight = UITableView.automaticDimension
            shareToTableView?.estimatedRowHeight = 130
            shareToTableView?.delegate = self
            shareToTableView?.dataSource = self
            shareToTableView?.separatorStyle = .none
        let nib = UINib(nibName: Identifiers.participantCell, bundle: Bundle.main)
        shareToTableView?.register(nib, forCellReuseIdentifier: Identifiers.participantCell)
//        let recentChatNib = UINib(nibName: Identifiers.recentChatCell, bundle: .main)
//        shareToTableView?.register(recentChatNib, forCellReuseIdentifier: Identifiers.recentChatCell)
        if let tv = shareToTableView{
            tv.contentSize = CGSize(width: tv.frame.size.width, height: tv.contentSize.height);
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        sendButton?.isEnabled = false
        sendButton?.alpha = 0.4

        if !selectedProfiles.isEmpty {
            sendButton?.isEnabled = true
            sendButton?.alpha = 1
        }

        NotificationCenter.default.addObserver(self, selector: #selector(networkChange(_:)),name:Notification.Name(NetStatus.networkNotificationObserver),object: nil)
    }
    
    @objc override func willCometoForeground() {
        if !ENABLE_CONTACT_SYNC && segmentSelectedIndex == 0{
            resetDataAndFetchUsersList()
        }
    }
    
    //MARK: API Call
    private func loadChatList() {
        getRecentChatList()
        getContactList()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setDelegate()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ContactManager.shared.profileDelegate = nil
        ChatManager.shared.messageEventsDelegate = nil
        ChatManager.shared.adminBlockDelegate = nil
        FlyMessenger.shared.messageEventsDelegate = nil
        ChatManager.shared.connectionDelegate = nil
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NetStatus.networkNotificationObserver), object: nil)
    }

    func setDelegate() {
        ContactManager.shared.profileDelegate = self
        ChatManager.shared.adminBlockDelegate = self
        ChatManager.shared.messageEventsDelegate = self
        FlyMessenger.shared.messageEventsDelegate = self
        GroupManager.shared.groupDelegate = self
        ChatManager.shared.connectionDelegate = self
    }

    func checkMemberOfGroup(index: Int,recentChat: RecentChat) -> Bool? {
        if recentChat.profileType == .groupChat && !isParticipantExist(jid: recentChat.jid).doesExist {
            return true
        }
        return false
    }
    
    func isParticipantExist(jid: String) -> (doesExist : Bool, message : String) {
        guard let myJid = try? FlyUtils.getMyJid() else {
            ShareKitUtility.shared.exitApp()
            return (false,emptyString())
        }
        return GroupManager.shared.isParticiapntExistingIn(groupJid: jid, participantJid: myJid)
    }
    
    func getLastMesssage() -> [ChatMessage]? {
        var chatMessage: [ChatMessage] = []
        let filteredObj = isSearchEnabled == true ? getRecentChat.filter({$0.lastMessageType == .video || $0.lastMessageType == .image}) : getAllRecentChat.filter({$0.lastMessageType == .video || $0.lastMessageType == .image})
        if filteredObj.count > 0 {
            filteredObj.forEach { (element) in
                chatMessage.append(getMessages(messageId: element.lastMessageId))
            }
        }
        return chatMessage
    }
    
    func getMessages(messageId: String) -> ChatMessage {
        var lastChatMessage : ChatMessage?
        recentChatViewModel?.getMessageOfId(messageId: messageId, completionHandler: { chatMessage in
            lastChatMessage = chatMessage
        })
        return lastChatMessage ?? ChatMessage()
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        DispatchQueue.main.async { [weak self] in
            self?.pageDismissClosure?()
            self?.closeShareKit()
        }
    }
    
    @IBAction func sendButtonTapped(_ sender: Any) {
        if NetworkReachability.shared.isConnected {
            shareMedia()
            //shareAttachments()
        } else {
            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.noInternet)
        }
    }

    func addLoader() {
        addChild(child)
        child.view.frame = view.frame
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }

    func removeLoader() {
        self.child.willMove(toParent: nil)
        self.child.view.removeFromSuperview()
        self.child.removeFromParent()
    }

    func closeShareKit() {
        removeLoader()
        messageIDs = []
        selectedJids = []
        ChatManager.disconnect()
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    func shareMedia() {

        let mediaCount = self.shareKitViewModel.handledAssets.count + self.shareKitViewModel.handledURL.count + self.shareKitViewModel.handledScreenShot.count
        let docFilesCount = self.shareKitViewModel.listOfMediaData?.filter({ $0.mediaType == .document || $0.mediaType == .audio }).count
        sendingMessagesCount = mediaCount + (docFilesCount ?? 0)

        if let files = self.shareKitViewModel.invaildMediaFiles, files.count > 0 {
            var invalidFiles = files
            let initialViewController = QuickSharePopupViewController(nibName: "QuickSharePopupViewController", bundle: nil)
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            //invalidFiles.indices.forEach{ invalidFiles[$0].thumbImage = invalidFiles[$0].image == nil ? UIImage(data: UIImage(data: try! Data(contentsOf: invalidFiles[$0].url ?? URL(fileURLWithPath: "")))?.jpegData(compressionQuality: 0.1) ?? Data()) : invalidFiles[$0].image}
            initialViewController.mediaFiles = invalidFiles
            initialViewController.shareDelegate = self
            initialViewController.modalPresentationStyle = .overCurrentContext
            self.navigationController?.present(initialViewController, animated: true)
        }
        else if !self.shareKitViewModel.handledAssets.isEmpty || !self.shareKitViewModel.handledURL.isEmpty || !self.shareKitViewModel.handledScreenShot.isEmpty {
            if let initialViewController = UIStoryboard(name: "MainInterface", bundle: nil).instantiateViewController(withIdentifier: "ShareKitPreviewController") as? ShareKitPreviewController {
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                initialViewController.mediaData = []
                initialViewController.delegate = self
                initialViewController.shareDelegate = self
                initialViewController.jids = self.selectedProfiles.compactMap( { $0.jid })
                initialViewController.selectedAssets = self.shareKitViewModel.handledAssets
                initialViewController.selectedURL = self.shareKitViewModel.handledURL
                initialViewController.selectedScreenShot = self.shareKitViewModel.handledScreenShot
                initialViewController.modalPresentationStyle = .overCurrentContext
                self.navigationController?.pushViewController(initialViewController, animated: true)
            }
        } else {
            addLoader()
            shareAttachments()
        }
    }

    func shareAttachments() {
        if let files = self.shareKitViewModel.invaildMediaFiles, files.count > 0 {
            var invalidFiles = files

            let initialViewController = QuickSharePopupViewController(nibName: "QuickSharePopupViewController", bundle: nil)
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            invalidFiles.indices.forEach{ invalidFiles[$0].thumbImage = UIImage(data: UIImage(data: try! Data(contentsOf: invalidFiles[$0].url ?? URL(fileURLWithPath: "")))?.jpegData(compressionQuality: 0.1) ?? Data()) }
            initialViewController.mediaFiles = invalidFiles
            initialViewController.shareDelegate = self
            initialViewController.modalPresentationStyle = .overCurrentContext
            self.navigationController?.present(initialViewController, animated: true)
        } else {
            let files = self.shareKitViewModel.listOfMediaData?.filter({ $0.mediaType == .document || $0.mediaType == .audio })
            if let documents = files, documents.count > 0 {
                documents.forEach { file in
                    switch file.mediaType {
                    case .document:
                        var profilesList = self.selectedProfiles
                        if !profilesList.isEmpty {
                            let profile = profilesList.first!
                            let documentParams = FileMessageParams(fileUrl: file.fileURL, fileName: file.fileName, fileKey: file.fileKey)
                            FlyMessenger.sendMediaFileMessage(messageParams: FileMessage(toId: profile.jid, messageType: .document, fileMessage: documentParams)) { isSuccess, _, message in
                                self.messageIDs.append(message?.messageId ?? "")
                                self.uploadingMessages.append(message?.messageId ?? "")
                                if isSuccess {
                                    print("#shareKitUpload document send \(self.isXmppConnected) \(message?.messageId ?? "")")
                                }
                            }
                        }
                        break
                    case .audio:
                        var profilesList = self.selectedProfiles
                        if !profilesList.isEmpty {
                            let profile = profilesList.first!
                            let audioParams = FileMessageParams(fileUrl: file.fileURL, fileName: file.fileName,fileSize: file.fileSize, duration: file.duration, fileKey: file.fileKey)
                            FlyMessenger.sendMediaFileMessage(messageParams: FileMessage(toId: profile.jid, messageType: .audio, fileMessage: audioParams)) { isSuccess, _, message in
                                self.messageIDs.append(message?.messageId ?? "")
                                self.uploadingMessages.append(message?.messageId ?? "")
                                if isSuccess {
                                    print("#shareKitUpload audio send \(self.isXmppConnected) \(message?.messageId ?? "")")
                                }
                            }
                        }
                    default:
                        break
                    }
                }
            } else if let contacts = self.shareKitViewModel.contactsList, contacts.count > 0 {
                if let contact = contacts.first {
                    let detail = self.parseContact(contact: contact)
                    if let initialViewController = UIStoryboard(name: "MainInterface", bundle: nil).instantiateViewController(withIdentifier: "ShareContactViewController") as? ShareContactViewController {
                        self.navigationController?.setNavigationBarHidden(true, animated: true)
                        initialViewController.getContactDetails = detail
                        initialViewController.jids = self.selectedProfiles.compactMap( { $0.jid })
                        initialViewController.modalPresentationStyle = .overCurrentContext
                        self.navigationController?.present(initialViewController, animated: true)
                    }
                }
            } else if self.shareKitViewModel.locationList.count > 0 {
                self.shareKitViewModel.locationList.forEach { location in
                    self.selectedProfiles.forEach { profile in
                        let messageParams = TextMessage(toId: profile.jid, messageText : location)
                        FlyMessenger.sendTextMessage(messageParams: messageParams) { _, _, _ in
                        }
                    }
                }
                self.closeShareKit()
            } else if self.shareKitViewModel.textList.count > 0 {
                self.shareKitViewModel.textList.forEach { text in
                    self.selectedProfiles.forEach { profile in
                        let messageParams = TextMessage(toId: profile.jid, messageText : text)
                        FlyMessenger.sendTextMessage(messageParams: messageParams) { _, _, _ in
                        }
                    }
                }
                self.closeShareKit()
            }
        }
    }

    func setViewModelData() {
        let attachments = (self.extensionContext?.inputItems.first as? NSExtensionItem)?.attachments ?? []
        if attachments.isEmpty {
            ShareKitAlert.shared.showToast(controller: self, message: "No files to share")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.closeShareKit()
            }
        } else if attachments.count > 10 {
            ShareKitAlert.shared.showToast(controller: self, message: "Can't share more than 10 media files")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.closeShareKit()
            }
        } else {
            executeOnMainThread { [self] in
                self.addLoader()
            }
            self.shareKitViewModel.clearModel()
            shareKitViewModel.delegate = self
            shareKitViewModel.loadData(attachments: attachments) { [weak self] in
                guard let self else { return }
                self.shareKitViewModel.getAsset {
                    self.removeLoader()
                }
            }
        }
    }

    func parseContact(contact: CNContact) -> [ContactDetails] {

        var contactDetails = [ContactDetails]()
        var contactNumber: [String] = []
        var contactStatus: [String] = []
        var contactLabel: [String] = []

        guard let contactName = CNContactFormatter.string(from: contact, style: .fullName) else {
            return []
        }
        contactNumber = []
        contactStatus = []
        contactLabel = []
        for number in contact.phoneNumbers {
            guard let mobileNumber = number.value.value(forKey: "digits") as? String else {
                return []
            }

            if number.label != nil {
                if let label : String? = CNLabeledValue<NSString>.localizedString(forLabel: number.label!){
                    contactLabel.append(label ?? "")
                } else {
                    contactLabel.append("")
                }
            } else {
                contactLabel.append("")
            }

            contactNumber.append(mobileNumber)
            contactStatus.append(contactSelect)
        }
        var imageData : Data?
        if contact.imageDataAvailable {
            imageData = contact.imageData
        }

        if contactNumber.count > 0 {
            contactDetails = [ContactDetails.init(contactName: contactName, contactNumber: contactNumber, contactLabel: contactLabel, status:  contactStatus, imageData: imageData)]
        }
        else {
            ShareKitAlert.shared.showToast(controller: self, message: noContactNumberAlert)
        }
        return contactDetails
    }

    func navigation() {
        let initialViewController = QuickSharePopupViewController(nibName: "QuickSharePopupViewController", bundle: nil)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        initialViewController.mediaFiles = shareModel.invaildMediaFiles ?? []
        self.present(initialViewController, animated: true)
    }
    
    @IBAction func SegmentControlValueChanged(_ sender: UISegmentedControl) {
        segmentSelectedIndex = sender.selectedSegmentIndex

        if segmentSelectedIndex == 1 {
            shareToTableView?.reloadData()
            //getRecentChatList(withArchive: true)
        } else {
            shareToTableView?.reloadData()
            //getRecentChatList()
        }

        if isLoadingInProgress && segmentSelectedIndex == 0 {
            initalLoader()
        }
        
        self.shareToTableView.tableFooterView?.isHidden = (segmentSelectedIndex != 0 && isLoadingInProgress) ? true : false
    }
    
    private func hideEmptyMessage() {
        emptyMessageView?.isHidden = true
        descriptionLabel?.isHidden = true
    }
    
    private func showEmptyMessage() {
        emptyMessageView?.isHidden = false
        descriptionLabel?.isHidden = false
        activityIndicator.isHidden = true
        if segmentSelectedIndex == 0 && !ENABLE_CONTACT_SYNC {
            if NetworkReachability.shared.isConnected{
                if isFirstPageLoaded && loadingCompleted{
                    descriptionLabel?.text = "No Contacts Found"
                }else{
                    descriptionLabel?.text = ""
                }
            }else{
                descriptionLabel?.text = ErrorMessage.noInternet
            }
        }else{
            descriptionLabel?.text = "No results found"
        }
        
    }
    
    private func showHideEmptyMessage(totalCount: Int?) {
        if totalCount ?? 0 == 0 {
            showEmptyMessage()
        } else {
            hideEmptyMessage()
        }
    }
    
    private func handleEmptyViewWhileSearch() {
        switch segmentSelectedIndex {
        case 0:
            showHideEmptyMessage(totalCount: isSearchEnabled == true ? filteredContactList.count : allContactsList.count)
        case 1:
            showHideEmptyMessage(totalCount: isSearchEnabled == true ? getRecentChat.filter({$0.profileType == .groupChat}).count : getAllRecentChat.filter({$0.profileType == .groupChat}).count)
        case 2:
            showHideEmptyMessage(totalCount: isSearchEnabled == true ? getRecentChat.count : getAllRecentChat.count)
        default:
            break
        }
    }
    
    private func refreshMessages() {
        isSearchEnabled = false
        searchBar?.resignFirstResponder()
        searchBar?.setShowsCancelButton(false, animated: true)
        searchBar?.text = ""
        searchTerm = emptyString()
        shareToTableView?.reloadData()
    }
    
    func networkMonitor() {
        if !NetworkReachability.shared.isConnected {
            executeOnMainThread { [weak self] in
                self?.sendButton?.isEnabled = false
            }
        }
        NetworkReachability.shared.netStatusChangeHandler = { [weak self] in
            print("networkMonitor \(NetworkReachability.shared.isConnected)")
            if !NetworkReachability.shared.isConnected {
                executeOnMainThread {
                    self?.sendButton?.isEnabled = false
                }
            } else {
                self?.sendButton?.isEnabled = true
            }
        }
    }
    
    func initalLoader() {
        emptyMessageView?.isHidden = false
        descriptionLabel?.isHidden = true
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
}

extension SharekitShareToViewController : ShareKitDelegate {

    func onError(description: String) {
        self.removeLoader()
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            ShareKitAlert.shared.showToast(controller: strongSelf, message: description)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.closeShareKit()
        }
    }
    
    func removeData() {
        shareKitViewModel.invaildMediaFiles?.forEach { file in
            shareKitViewModel.handledAssets.forEach { asset in
                let status = file.url?.lastPathComponent.components(separatedBy: ".").first == (PHAssetResource.assetResources(for: asset).first?.originalFilename ?? "").components(separatedBy: ".").first
                if status {
                    shareKitViewModel.handledAssets.removeAll { asset in
                        file.url?.lastPathComponent.components(separatedBy: ".").first == (PHAssetResource.assetResources(for: asset).first?.originalFilename ?? "").components(separatedBy: ".").first
                    }
                }
            }
            shareKitViewModel.handledURL.forEach { url in
                let status = file.url?.lastPathComponent.components(separatedBy: ".").first == url.lastPathComponent.components(separatedBy: ".").first
                if status {
                    shareKitViewModel.handledURL.removeAll { url in
                        file.url?.lastPathComponent.components(separatedBy: ".").first == url.lastPathComponent.components(separatedBy: ".").first
                    }
                }
            }
        }
        shareKitViewModel.invaildMediaFiles?.removeAll()

        if shareKitViewModel.handledAssets.isEmpty && self.shareKitViewModel.listOfMediaData?.isEmpty ?? false {
            self.closeShareKit()
        }
    }
}

// TableViewDelegate
extension SharekitShareToViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmentSelectedIndex {
        case 0:
            return isSearchEnabled == true ? filteredContactList.count : allContactsList.count
        case 1:
            return isSearchEnabled == true ? getRecentChat.filter({$0.profileType == .groupChat}).count : getAllRecentChat.filter({$0.profileType == .groupChat}).count
        case 3:
           return 0
        case 2:
            return isSearchEnabled == true ? getRecentChat.count : getAllRecentChat.count
        default:
            return 0
        }
    }
    
    private func getBlocked(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlocked ?? false
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.participantCell, for: indexPath) as? ShareKitParticipantCell) {
            switch segmentSelectedIndex {
            case 0:
                let contactDetails = isSearchEnabled == true ? filteredContactList[indexPath.row] : allContactsList[indexPath.row]
                if getBlocked(jid: contactDetails.jid) {
                    cell.contentView.alpha = 0.6
                } else {
                    cell.contentView.alpha = 1.0
                }
                cell.nameUILabel?.text = FlyUtils.getUserName(jid: contactDetails.jid, name: contactDetails.name, nickName: contactDetails.nickName, contactType: contactDetails.contactType)
                cell.statusUILabel?.text = contactDetails.status
                let hashcode = FlyUtils.getUserName(jid: contactDetails.jid, name: contactDetails.name, nickName: contactDetails.nickName, contactType: contactDetails.contactType).hashValue
                let color = randomColors[abs(hashcode) % randomColors.count]
                FlyLog.DLog(param1: "#Contact colors", param2: "\(contactDetails.name), \(color)")
                let image = contactDetails.thumbImage == "" ? contactDetails.image ?? "" : contactDetails.thumbImage ?? ""
                cell.setImage(imageURL: image, name: FlyUtils.getUserName(jid: contactDetails.jid, name: contactDetails.name, nickName: contactDetails.nickName, contactType: contactDetails.contactType), color: color ?? .gray, profile: contactDetails)
                //cell.setImage(imageURL: contactDetails.image, name: getUserName(jid: contactDetails.jid, name: contactDetails.name, nickName: contactDetails.nickName, contactType: contactDetails.isItSavedContact ? .live : .unknown), color: color ?? .gray, chatType: contactDetails.profileChatType, jid: contactDetails.jid)
                cell.checkBoxImageView?.image = selectedJids.contains(contactDetails.jid) ?  UIImage(named: ImageConstant.ic_checked) : UIImage(named: ImageConstant.ic_check_box)
                cell.setTextColorWhileSearch(searchText: searchTerm, profileDetail: contactDetails)
                cell.statusUILabel?.isHidden = false
                cell.removeButton?.isHidden = true
                cell.removeIcon?.isHidden = true
                cell.hideLastMessageContentInfo()
                showHideEmptyMessage(totalCount: isSearchEnabled == true ? filteredContactList.count : allContactsList.count)
            case 1:
                let recentChatDetails = isSearchEnabled == true ? getRecentChat.filter({$0.profileType == .groupChat && $0.isBlockedByAdmin == false })[indexPath.row] : getAllRecentChat.filter({$0.profileType == .groupChat && $0.isBlockedByAdmin == false})[indexPath.row]
                let hashcode = recentChatDetails.profileName.hashValue
                let color = randomColors[abs(hashcode) % randomColors.count]
                cell.setRecentChatDetails(recentChat: recentChatDetails, color: color ?? .gray)
                cell.showLastMessageContentInfo()
                cell.statusUILabel?.isHidden = false
                cell.removeButton?.isHidden = true
                cell.removeIcon?.isHidden = true
                let chatMessage = recentChatDetails.lastMessageContent.trim()
                if recentChatDetails.isMentionedUser, chatMessage.isNotEmpty {
                    let message = ShareKitUtility.shared.getMentionTextContent(message: recentChatDetails.lastMessageContent, isMessageSentByMe: recentChatDetails.isLastMessageSentByMe, mentionedUsers: recentChatDetails.mentionedUsersIds)
                    if recentChatDetails.lastMessageType == .text || recentChatDetails.lastMessageType == .notification || recentChatDetails.lastMessageType == .autoText {
                        cell.statusUILabel?.text = message.string
                    } else {
                        cell.receiverMessageTypeView?.isHidden = false
                        cell.statusUILabel?.text = message.string + (recentChatDetails.lastMessageType?.rawValue ?? "")
                    }
                } else {
                    if recentChatDetails.lastMessageType == .text || recentChatDetails.lastMessageType == .notification || recentChatDetails.lastMessageType == .autoText {
                        cell.statusUILabel?.text = recentChatDetails.lastMessageContent
                    } else  {
                        cell.receiverMessageTypeView?.isHidden = false
                        cell.statusUILabel?.text = recentChatDetails.lastMessageContent + (recentChatDetails.lastMessageType?.rawValue ?? "")
                    }
                }
                if ChatManager.isPrivateChat(jid: recentChatDetails.jid) {
                    cell.statusUILabel?.text = ""
                }
                showHideEmptyMessage(totalCount: isSearchEnabled == true ? getRecentChat.filter({$0.profileType == .groupChat}).count : getAllRecentChat.filter({$0.profileType == .groupChat}).count)
            case 3:
                showHideEmptyMessage(totalCount: 0)
            case 2:
                let recentChatDetails = isSearchEnabled == true ? getRecentChat[indexPath.row] : getAllRecentChat[indexPath.row]
                if getBlocked(jid: recentChatDetails.jid) {
                    cell.contentView.alpha = 0.6
                } else {
                    cell.contentView.alpha = 1.0
                }
                let hashcode = recentChatDetails.profileName.hashValue
                let color = randomColors[abs(hashcode) % randomColors.count]
                cell.setRecentChatDetails(recentChat: recentChatDetails, color: color ?? .gray)
                cell.showLastMessageContentInfo()
                cell.receiverMessageTypeView?.isHidden = true
                let chatMessage = recentChatDetails.lastMessageContent.trim()
                if recentChatDetails.isMentionedUser, chatMessage.isNotEmpty {
                    let message = ShareKitUtility.shared.getMentionTextContent(message: recentChatDetails.lastMessageContent, isMessageSentByMe: recentChatDetails.isLastMessageSentByMe, mentionedUsers: recentChatDetails.mentionedUsersIds)
                    if recentChatDetails.lastMessageType == .text || recentChatDetails.lastMessageType == .notification || recentChatDetails.lastMessageType == .autoText {
                        cell.statusUILabel?.text = message.string
                    } else {
                        cell.receiverMessageTypeView?.isHidden = false
                        cell.statusUILabel?.text = message.string + (recentChatDetails.lastMessageType?.rawValue ?? "")
                    }
                } else {
                    if recentChatDetails.lastMessageType == .text || recentChatDetails.lastMessageType == .notification || recentChatDetails.lastMessageType == .autoText {
                        cell.statusUILabel?.text = recentChatDetails.lastMessageContent
                    } else  {
                        cell.receiverMessageTypeView?.isHidden = false
                        cell.statusUILabel?.text = recentChatDetails.lastMessageContent + (recentChatDetails.lastMessageType?.rawValue ?? "")
                    }
                }
                cell.statusUILabel?.isHidden = false
                cell.removeButton?.isHidden = true
                cell.removeIcon?.isHidden = true
                if ChatManager.isPrivateChat(jid: recentChatDetails.jid) {
                    cell.statusUILabel?.text = ""
                }
                showHideEmptyMessage(totalCount: isSearchEnabled == true ? getRecentChat.count : getAllRecentChat.count)
            default:
                break
            }
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !NetworkReachability.shared.isConnected {
            self.sendButton?.isEnabled = false
            self.sendButton?.alpha = 0.4
            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.noInternet)
        } else {
            switch segmentSelectedIndex {
            case 0:
                switch isSearchEnabled  {
                case true:
                    if getBlocked(jid: filteredContactList[indexPath.row].jid) {
                        showBlockUnblockConfirmationPopUp(jid: filteredContactList[indexPath.row].jid, name: filteredContactList[indexPath.row].nickName)
                        return
                    }
                    var profile = Profile()
                    profile.profileName = filteredContactList[indexPath.row].name
                    profile.jid = filteredContactList[indexPath.row].jid
                    profile.isSelected = !(profile.isSelected ?? false)
                    saveUserToDatabase(jid: profile.jid)
                    if selectedProfiles.filter({$0.jid == profile.jid}).count == 0  && selectedProfiles.count < 5 {
                        checkUserBusyStatusEnabled(self, jid: profile.jid) { [weak self] status in
                            executeOnMainThread {
                                if status {
                                    self?.getRecentChat.filter({$0.jid == profile.jid}).first?.isSelected = true
                                    self?.filteredContactList[indexPath.row].isSelected = true
                                    self?.selectedProfiles.append(profile)
                                    self?.selectedJids = self?.selectedProfiles.compactMap { profile in profile.jid } ?? []
                                    self?.sendButton?.isEnabled = self?.selectedProfiles.count == 0 ? false : true
                                    self?.sendButton?.alpha = self?.selectedProfiles.count == 0 ? 0.4 : 1.0
                                }
                                self?.shareToTableView?.reloadRows(at: [indexPath], with: .none)
                            }
                        }
                    } else if selectedProfiles.filter({$0.jid == filteredContactList[indexPath.row].jid}).count > 0 {
                        selectedProfiles.enumerated().forEach({ (index,item) in
                            if item.jid == filteredContactList[indexPath.row].jid {
                                if index <= selectedProfiles.count {
                                    getRecentChat.filter({$0.jid == filteredContactList[indexPath.row].jid}).first?.isSelected = false
                                    filteredContactList[indexPath.row].isSelected = false
                                    selectedProfiles.remove(at: index)
                                    selectedJids = selectedProfiles.compactMap { profile in profile.jid }
                                }
                            }
                        })
                    } else {
                        ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.restrictedShareUsers, position: keyboardShown ? .center : .bottom)
                    }
                    let cell: ShareKitParticipantCell = tableView.cellForRow(at: indexPath) as! ShareKitParticipantCell
                    tableView.beginUpdates()
                    cell.checkBoxImageView?.image = filteredContactList[indexPath.row].isSelected ?  UIImage(named: ImageConstant.ic_checked) : UIImage(named: ImageConstant.ic_check_box)
                    tableView.endUpdates()
                    //shareToTableView?.reloadRows(at: [indexPath], with: .none)
                case false:
                    if getBlocked(jid: allContactsList[indexPath.row].jid) {
                        showBlockUnblockConfirmationPopUp(jid: allContactsList[indexPath.row].jid, name: allContactsList[indexPath.row].nickName)
                        return
                    }
                    var profile = Profile()
                    profile.profileName = allContactsList[indexPath.row].name
                    profile.jid = allContactsList[indexPath.row].jid
                    profile.isSelected = !(profile.isSelected ?? false)
                    saveUserToDatabase(jid: profile.jid)
                    if selectedProfiles.filter({$0.jid == profile.jid}).count == 0  && selectedProfiles.count < 5 {
                        checkUserBusyStatusEnabled(self, jid: profile.jid) { [weak self] status in
                            executeOnMainThread {
                                if status {
                                    self?.getAllRecentChat.filter({$0.jid == profile.jid}).first?.isSelected = true
                                    self?.allContactsList[indexPath.row].isSelected = true
                                    self?.selectedProfiles.append(profile)
                                    self?.selectedJids = self?.selectedProfiles.compactMap { profile in profile.jid } ?? []
                                    self?.sendButton?.isEnabled = self?.selectedProfiles.count == 0 ? false : true
                                    self?.sendButton?.alpha = self?.selectedProfiles.count == 0 ? 0.4 : 1.0
                                }
                                self?.shareToTableView?.reloadRows(at: [indexPath], with: .none)
                            }
                        }
                    } else if selectedProfiles.filter({$0.jid == allContactsList[indexPath.row].jid}).count > 0 {
                        selectedProfiles.enumerated().forEach({ (index,item) in
                            if item.jid == allContactsList[indexPath.row].jid {
                                if index <= selectedProfiles.count {
                                    getAllRecentChat.filter({$0.jid == allContactsList[indexPath.row].jid}).first?.isSelected = false
                                    allContactsList[indexPath.row].isSelected = false
                                    selectedProfiles.remove(at: index)
                                    selectedJids = selectedProfiles.compactMap { profile in profile.jid }
                                }
                            }
                        })
                    } else {
                        ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.restrictedShareUsers, position: keyboardShown ? .center : .bottom)
                    }
                    let cell: ShareKitParticipantCell = tableView.cellForRow(at: indexPath) as! ShareKitParticipantCell
                    tableView.beginUpdates()
                    cell.checkBoxImageView?.image = allContactsList[indexPath.row].isSelected ?  UIImage(named: ImageConstant.ic_checked) : UIImage(named: ImageConstant.ic_check_box)
                    tableView.endUpdates()
                    //shareToTableView?.reloadRows(at: [indexPath], with: .none)
                }
            case 1:
                switch isSearchEnabled  {
                case true:
                    if checkMemberOfGroup(index: indexPath.row, recentChat: getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row]) == true {
                        ShareKitAlert.shared.showToast(controller: self, message: youCantSelectTheGroup)
                        return
                    }
                    var profile = Profile()
                    profile.profileName = getRecentChat.filter({$0.profileType == .groupChat && $0.isBlockedByAdmin == false})[indexPath.row].profileName
                    profile.jid = getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid
                    profile.isSelected = !(profile.isSelected ?? false)
                    saveUserToDatabase(jid: profile.jid)
                    if selectedProfiles.filter({$0.jid == getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).count == 0  && selectedProfiles.count < 5 {
                        getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].isSelected = true
                        getRecentChat.filter({$0.jid ==  getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).first?.isSelected = true
                        selectedProfiles.append(profile)
                        selectedJids = selectedProfiles.compactMap { profile in profile.jid }
                    } else if selectedProfiles.filter({$0.jid == getRecentChat.filter({$0.profileType == .groupChat && $0.isBlockedByAdmin == false})[indexPath.row].jid}).count > 0 {
                        selectedProfiles.enumerated().forEach({ (index,item) in
                            if item.jid == getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid {
                                if index <= selectedProfiles.count {
                                    getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].isSelected = false
                                    getRecentChat.filter({$0.jid ==  getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).first?.isSelected = false
                                    selectedProfiles.remove(at: index)
                                    selectedJids = selectedProfiles.compactMap { profile in profile.jid }
                                }
                            }
                        })
                    } else {
                        ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.restrictedShareUsers, position: keyboardShown ? .center : .bottom)
                    }
                    let cell: ShareKitParticipantCell = tableView.cellForRow(at: indexPath) as! ShareKitParticipantCell
                    tableView.beginUpdates()
                    cell.checkBoxImageView?.image = getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].isSelected ?  UIImage(named: ImageConstant.ic_checked) : UIImage(named: ImageConstant.ic_check_box)
                    tableView.endUpdates()
                    //shareToTableView?.reloadRows(at: [indexPath], with: .none)
                case false:
                    if checkMemberOfGroup(index: indexPath.row, recentChat: getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row]) == true {
                        ShareKitAlert.shared.showToast(controller: self, message: youCantSelectTheGroup)
                        return
                    }
                    var profile = Profile()
                    profile.profileName = getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].profileName
                    profile.jid = getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid
                    profile.isSelected = !(profile.isSelected ?? false)
                    saveUserToDatabase(jid: profile.jid)
                    if selectedProfiles.filter({$0.jid == getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).count == 0  && selectedProfiles.count < 5 {
                        getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].isSelected = true
                        getAllRecentChat.filter({$0.jid ==  getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).first?.isSelected = true
                        selectedProfiles.append(profile)
                        selectedJids = selectedProfiles.compactMap { profile in profile.jid }
                    } else if selectedProfiles.filter({$0.jid == getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).count > 0 {
                        selectedProfiles.enumerated().forEach({ (index,item) in
                            if item.jid == getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid {
                                if index <= selectedProfiles.count {
                                    getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].isSelected = false
                                    getAllRecentChat.filter({$0.jid ==  getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).first?.isSelected = false
                                    selectedProfiles.remove(at: index)
                                    selectedJids = selectedProfiles.compactMap { profile in profile.jid }
                                }
                            }
                        })
                    } else {
                        ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.restrictedShareUsers, position: keyboardShown ? .center : .bottom)
                    }
                    let cell: ShareKitParticipantCell = tableView.cellForRow(at: indexPath) as! ShareKitParticipantCell
                    tableView.beginUpdates()
                    cell.checkBoxImageView?.image = getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].isSelected ?  UIImage(named: ImageConstant.ic_checked) : UIImage(named: ImageConstant.ic_check_box)
                    tableView.endUpdates()
//                    shareToTableView?.reloadRows(at: [indexPath], with: .none)
                }
            case 3:
                break
            case 2:
                switch isSearchEnabled  {
                case true:
                    if checkMemberOfGroup(index: indexPath.row, recentChat: getRecentChat[indexPath.row]) == true {
                        ShareKitAlert.shared.showToast(controller: self, message: youCantSelectTheGroup)
                        return
                    }
                    if getBlocked(jid: getRecentChat[indexPath.row].jid) {
                        showBlockUnblockConfirmationPopUp(jid: getRecentChat[indexPath.row].jid, name: getRecentChat[indexPath.row].nickName)
                        return
                    }
                    var profile = Profile()
                    profile.profileName = getRecentChat[indexPath.row].profileName
                    profile.jid = getRecentChat[indexPath.row].jid
                    profile.isSelected = !(profile.isSelected ?? false)
                    saveUserToDatabase(jid: profile.jid)
                    if selectedProfiles.filter({$0.jid == getRecentChat[indexPath.row].jid}).count == 0 && selectedProfiles.count < 5 {
                        checkUserBusyStatusEnabled(self, jid: profile.jid) { [weak self] status in
                            executeOnMainThread {
                                if status {
                                    self?.getRecentChat[indexPath.row].isSelected = true
                                    self?.filteredContactList.filter({$0.jid == self?.getRecentChat[indexPath.row].jid}).first?.isSelected = true
                                    self?.selectedProfiles.append(profile)
                                    self?.selectedJids = self?.selectedProfiles.compactMap { profile in profile.jid } ?? []
                                    self?.sendButton?.isEnabled = self?.selectedProfiles.count == 0 ? false : true
                                    self?.sendButton?.alpha = self?.selectedProfiles.count == 0 ? 0.4 : 1.0
                                }
                                self?.shareToTableView?.reloadRows(at: [indexPath], with: .none)
                            }
                            
                        }
                    } else if selectedProfiles.filter({$0.jid == getRecentChat[indexPath.row].jid}).count > 0 {
                        selectedProfiles.enumerated().forEach({ (index,item) in
                            if item.jid == getRecentChat[indexPath.row].jid {
                                if index <= selectedProfiles.count {
                                    getRecentChat[indexPath.row].isSelected = false
                                    filteredContactList.filter({$0.jid == getRecentChat[indexPath.row].jid}).first?.isSelected = false
                                    selectedProfiles.remove(at: index)
                                    selectedJids = selectedProfiles.compactMap { profile in profile.jid }
                                }
                            }
                        })
                    } else {
                        ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.restrictedShareUsers, position: keyboardShown ? .center : .bottom)
                    }
                    let cell: ShareKitParticipantCell = tableView.cellForRow(at: indexPath) as! ShareKitParticipantCell
                    tableView.beginUpdates()
                    cell.checkBoxImageView?.image = getRecentChat[indexPath.row].isSelected ?  UIImage(named: ImageConstant.ic_checked) : UIImage(named: ImageConstant.ic_check_box)
                    tableView.endUpdates()
                    //shareToTableView?.reloadRows(at: [indexPath], with: .none)
                case false:
                    if checkMemberOfGroup(index: indexPath.row, recentChat: getAllRecentChat[indexPath.row]) == true {
                        ShareKitAlert.shared.showToast(controller: self, message: youCantSelectTheGroup)
                        return
                    }
                    if getBlocked(jid: getAllRecentChat[indexPath.row].jid) {
                        showBlockUnblockConfirmationPopUp(jid: getAllRecentChat[indexPath.row].jid,name: getAllRecentChat[indexPath.row].nickName)
                        return
                    }
                    var profile = Profile()
                    profile.profileName = getAllRecentChat[indexPath.row].profileName
                    profile.jid = getAllRecentChat[indexPath.row].jid
                    profile.isSelected = !(profile.isSelected ?? false)
                    if selectedProfiles.filter({$0.jid == getAllRecentChat[indexPath.row].jid}).count == 0  && selectedProfiles.count < 5 {
                        checkUserBusyStatusEnabled(self, jid: profile.jid) { [weak self] status in
                            executeOnMainThread {
                                if status {
                                    self?.getAllRecentChat[indexPath.row].isSelected = true
                                    self?.allContactsList.filter({$0.jid == self?.getAllRecentChat[indexPath.row].jid}).first?.isSelected = true
                                    self?.selectedProfiles.append(profile)
                                    self?.selectedJids = self?.selectedProfiles.compactMap { profile in profile.jid } ?? []
                                    self?.sendButton?.isEnabled = self?.selectedProfiles.count == 0 ? false : true
                                    self?.sendButton?.alpha = self?.selectedProfiles.count == 0 ? 0.4 : 1.0
                                }
                                self?.shareToTableView?.reloadRows(at: [indexPath], with: .none)
                            }
                        }
                    } else if selectedProfiles.filter({$0.jid == getAllRecentChat[indexPath.row].jid}).count > 0 {
                        selectedProfiles.enumerated().forEach({ (index,item) in
                            if item.jid == getAllRecentChat[indexPath.row].jid {
                                if index <= selectedProfiles.count {
                                    getAllRecentChat[indexPath.row].isSelected = false
                                    allContactsList.filter({$0.jid == getAllRecentChat[indexPath.row].jid}).first?.isSelected = false
                                    selectedProfiles.remove(at: index)
                                    selectedJids = selectedProfiles.compactMap { profile in profile.jid }
                                }
                            }
                        })
                    } else {
                        ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.restrictedShareUsers, position: keyboardShown ? .center : .bottom)
                    }
                    let cell: ShareKitParticipantCell = tableView.cellForRow(at: indexPath) as! ShareKitParticipantCell
                    tableView.beginUpdates()
                    cell.checkBoxImageView?.image = getAllRecentChat[indexPath.row].isSelected ?  UIImage(named: ImageConstant.ic_checked) : UIImage(named: ImageConstant.ic_check_box)
                    tableView.endUpdates()
                    //shareToTableView?.reloadRows(at: [indexPath], with: .none)
                }
            default:
                break
            }
            sendButton?.isEnabled = selectedProfiles.count == 0 ? false : true
            sendButton?.alpha = selectedProfiles.count == 0 ? 0.4 : 1.0
        }
    }
}

// SearchBar Delegate Method
extension SharekitShareToViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("#SEarch \(searchText)")
        if searchText.trim().count > 0 {
            searchedText = searchText
            isSearchEnabled = true
            getRecentChat = searchedText.isEmpty ? getAllRecentChat : getAllRecentChat.filter({ recentChat -> Bool in
                return (recentChat.profileName.capitalized.range(of: searchedText.trim().capitalized, options: [.caseInsensitive, .diacriticInsensitive]) != nil && recentChat.isDeletedUser == false) ||
                (recentChat.lastMessageContent.capitalized.range(of: searchedText.trim().capitalized, options: [.caseInsensitive, .diacriticInsensitive]) != nil && recentChat.isDeletedUser == false)
            })
            if ENABLE_CONTACT_SYNC || segmentSelectedIndex != 0 {
                filteredContactList = searchedText.isEmpty ? allContactsList : allContactsList.filter({ contact -> Bool in
                    return contact.name.capitalized.range(of: searchedText.trim().capitalized, options: [.caseInsensitive, .diacriticInsensitive]) != nil
                })
                handleEmptyViewWhileSearch()
            }else{
                let searchString = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !searchString.isEmpty || self.searchTerm != searchString{
                    resetParams()
                    self.showHideEmptyMessage(totalCount: 0)
                    searchSubject.onNext(searchString.lowercased())
                }
            }
        } else {
            searchedText = emptyString()
            isSearchEnabled = false
            getRecentChatList()
            if ENABLE_CONTACT_SYNC{
                self.searchTerm = emptyString()
                getContactList()
            }else{
                if self.searchTerm != searchText{
                    resetParams()
                    self.showHideEmptyMessage(totalCount: 0)
                    searchSubject.onNext(emptyString())
                }
            }
        }
        handleEmptyViewWhileSearch()
        shareToTableView?.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        segmentControlView?.isHidden = true
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        refreshMessages()
        if !ENABLE_CONTACT_SYNC{
            resetDataAndFetchUsersList()
        }
        segmentControlView?.isHidden = false
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        segmentControlView?.isHidden = true
    }
}

// getChatList Method
extension SharekitShareToViewController {
    private func getContactList() {
        if ENABLE_CONTACT_SYNC {
            contactViewModel?.getContacts(fromServer: false) { [weak self] (contacts, error)  in
                if error != nil {
                    return
                }
                if let weakSelf = self {
                    if  let  contactsList = contacts {
                        weakSelf.allContactsList.removeAll()
                        weakSelf.filteredContactList.removeAll()
                        weakSelf.allContactsList = contactsList
                        weakSelf.allContactsList = weakSelf.allContactsList.sorted { $0.name.capitalized < $1.name.capitalized }
                        
                        weakSelf.allContactsList.enumerated().forEach { (index,contact) in
                            if  weakSelf.selectedProfiles.filter({$0.jid == contact.jid}).count > 0 {
                                weakSelf.allContactsList[index].isSelected = (weakSelf.selectedProfiles.filter({$0.jid == contact.jid}).first?.isSelected ?? false)
                            }
                        }
                        
                        weakSelf.filteredContactList.enumerated().forEach { (index,contact) in
                            if  weakSelf.selectedProfiles.filter({$0.jid == contact.jid}).count > 0 {
                                weakSelf.filteredContactList[index].isSelected = (weakSelf.selectedProfiles.filter({$0.jid == contact.jid}).first?.isSelected ?? false)
                            }
                        }
                        weakSelf.shareToTableView?.reloadData()
                        
                    }
                }
            }
            handleEmptyViewWhileSearch()
        }else{
            resetDataAndFetchUsersList()
        }
        
    }
    
    func getRecentChatList(withArchive: Bool = false) {
        if withArchive {
            recentChatViewModel?.getRecentChatListWithArchive(isBackground: false, completionHandler: { [weak self] recentChatList in
                if let weakSelf = self {
                    weakSelf.getRecentChat = recentChatList?.filter({$0.isBlockedByAdmin == false}) ?? []
                    weakSelf.getAllRecentChat = weakSelf.getRecentChat

                    weakSelf.getAllRecentChat.enumerated().forEach { (index,contact) in
                        if  weakSelf.selectedProfiles.filter({$0.jid == contact.jid}).count > 0 {
                            weakSelf.getAllRecentChat[index].isSelected = (weakSelf.selectedProfiles.filter({$0.jid == contact.jid}).first?.isSelected ?? false)
                        }
                    }

                    weakSelf.getRecentChat.enumerated().forEach { (index,contact) in
                        if  weakSelf.selectedProfiles.filter({$0.jid == contact.jid}).count > 0 {
                            weakSelf.getRecentChat[index].isSelected = (weakSelf.selectedProfiles.filter({$0.jid == contact.jid}).first?.isSelected ?? false)
                        }
                    }
                }
            })
            randomColors = Utility.shared.setRandomColors(totalCount: getRecentChat.count)
            if isSearchEnabled == false {
                shareToTableView?.reloadData()
            }
            handleEmptyViewWhileSearch()
        } else {
            recentChatViewModel?.getRecentChatList(isBackground: false, completionHandler: { [weak self] recentChatList in
                if let weakSelf = self {
                    weakSelf.getRecentChat = recentChatList?.filter({$0.isBlockedByAdmin == false}) ?? []
                    weakSelf.getAllRecentChat = weakSelf.getRecentChat

                    weakSelf.getAllRecentChat.enumerated().forEach { (index,contact) in
                        if  weakSelf.selectedProfiles.filter({$0.jid == contact.jid}).count > 0 {
                            weakSelf.getAllRecentChat[index].isSelected = (weakSelf.selectedProfiles.filter({$0.jid == contact.jid}).first?.isSelected ?? false)
                        }
                    }

                    weakSelf.getRecentChat.enumerated().forEach { (index,contact) in
                        if  weakSelf.selectedProfiles.filter({$0.jid == contact.jid}).count > 0 {
                            weakSelf.getRecentChat[index].isSelected = (weakSelf.selectedProfiles.filter({$0.jid == contact.jid}).first?.isSelected ?? false)
                        }
                    }
                }
            })
            randomColors = Utility.shared.setRandomColors(totalCount: getRecentChat.count)
            if isSearchEnabled == false {
                shareToTableView?.reloadData()
            }
            handleEmptyViewWhileSearch()
        }
    }
}

extension SharekitShareToViewController : ProfileEventsDelegate {
    func userCameOnline(for jid: String) {
        
    }
    
    func userWentOffline(for jid: String) {
        
    }
    
    func userProfileFetched(for jid: String, profileDetails: ProfileDetails?) {
        
    }
    
    func myProfileUpdated() {
        
    }
    
    func usersProfilesFetched() {
        DispatchQueue.main.async { [weak self] in
            if ENABLE_CONTACT_SYNC{
                self?.getContactList()
            }
            //self?.getRecentChatList()
            if let uiSearchBar = self?.searchBar, self?.isSearchEnabled ?? false{
                self?.searchBar(uiSearchBar, textDidChange: self?.searchedText ?? emptyString())
            }
            if let fromJid = self?.fromJid,let pd = ContactManager.shared.getUserProfileDetails(for: fromJid){
                self?.refreshProfileDelegate?.refreshProfileDetails(profileDetails: pd)
            }
        }
    }
    
    func blockedThisUser(jid: String) {
        
    }
    
    func unblockedThisUser(jid: String) {
        
    }
    
    func usersIBlockedListFetched(jidList: [String]) {
        
    }
    
    func usersBlockedMeListFetched(jidList: [String]) {
        
    }
    
    func userBlockedMe(jid: String) {
        loadChatList()
    }
    
    func userUnBlockedMe(jid: String) {
        loadChatList()
    }
    
    func hideUserLastSeen() {
        
    }
    
    func getUserLastSeen() {
        
    }
    
    func userDeletedTheirProfile(for jid : String, profileDetails:ProfileDetails){
        
        if let indexOfAllContactList = allContactsList.firstIndex(where: {$0.jid == jid}){
            allContactsList.remove(at: indexOfAllContactList)
            if segmentSelectedIndex == 0 && !isSearchEnabled{
                shareToTableView?.reloadData()
                if let index = selectedProfiles.firstIndex(where: {$0.jid == jid}){
                    selectedProfiles.remove(at: index)
                    sendButton?.isEnabled = selectedProfiles.count == 0 ? false : true
                    sendButton?.alpha = selectedProfiles.count == 0 ? 0.4 : 1.0
                }
            }
        }
        if let indexOfFilteredList = filteredContactList.firstIndex(where: {$0.jid == jid}){
            filteredContactList.remove(at: indexOfFilteredList)
            if segmentSelectedIndex == 0 && isSearchEnabled{
                shareToTableView?.reloadData()
                if let index = selectedProfiles.firstIndex(where: {$0.jid == jid}){
                    selectedProfiles.remove(at: index)
                    sendButton?.isEnabled = selectedProfiles.count == 0 ? false : true
                    sendButton?.alpha = selectedProfiles.count == 0 ? 0.4 : 1.0
                }
            }
        }
        if let indexOfRecentChat = getRecentChat.firstIndex(where: {$0.jid == jid}){
            getRecentChat[indexOfRecentChat].nickName = profileDetails.nickName
            getRecentChat[indexOfRecentChat].profileName = profileDetails.name
            getRecentChat[indexOfRecentChat].isItSavedContact = false
            getRecentChat[indexOfRecentChat].isSelected = false
            getRecentChat[indexOfRecentChat].isDeletedUser = true
            getRecentChat[indexOfRecentChat].profileImage = emptyString()
            if segmentSelectedIndex == 3  && isSearchEnabled {
                let indexPath = IndexPath(item: indexOfRecentChat, section: 0)
                shareToTableView?.reloadRows(at: [indexPath], with: .fade)
                if let index = selectedProfiles.firstIndex(where: {$0.jid == jid}){
                    selectedProfiles.remove(at: index)
                    sendButton?.isEnabled = selectedProfiles.count == 0 ? false : true
                    sendButton?.alpha = selectedProfiles.count == 0 ? 0.4 : 1.0
                }
            }
        }
        if let indexOfAllRecentChat = getAllRecentChat.firstIndex(where: {$0.jid == jid}){
            getAllRecentChat[indexOfAllRecentChat].nickName = profileDetails.nickName
            getAllRecentChat[indexOfAllRecentChat].profileName = profileDetails.name
            getAllRecentChat[indexOfAllRecentChat].isItSavedContact = false
            getAllRecentChat[indexOfAllRecentChat].isSelected = false
            getAllRecentChat[indexOfAllRecentChat].isDeletedUser = true
            getAllRecentChat[indexOfAllRecentChat].profileImage = emptyString()
            if segmentSelectedIndex == 3 && !isSearchEnabled {
                let indexPath = IndexPath(item: indexOfAllRecentChat, section: 0)
                shareToTableView?.reloadRows(at: [indexPath], with: .fade)
                if let index = selectedProfiles.firstIndex(where: {$0.jid == jid}){
                    selectedProfiles.remove(at: index)
                    sendButton?.isEnabled = selectedProfiles.count == 0 ? false : true
                    sendButton?.alpha = selectedProfiles.count == 0 ? 0.4 : 1.0
                }
            }
        }
        refreshProfileDelegate?.refreshProfileDetails(profileDetails: profileDetails)
    }
    
func userUpdatedTheirProfile(for jid: String, profileDetails: ProfileDetails) {
    print("userUpdatedTheirProfile \(jid)")
    switch segmentSelectedIndex {
    case 0:
        let profileDatas =  isSearchEnabled == true ? filteredContactList.filter({ ($0.jid.contains(jid)) }) : allContactsList.filter({ ($0.jid.contains(jid)) })
        if profileDatas.count > 0, let profileData = profileDatas.first  {
            if isSearchEnabled == true {
                if  let index = filteredContactList.firstIndex(of: profileData) {
                    filteredContactList[index].image = profileDetails.image
                    filteredContactList[index].name = profileDetails.name
                    filteredContactList[index].status = profileDetails.status
            }
            } else {
                    if  let index = allContactsList.firstIndex(of: profileData) {
                        allContactsList[index].image = profileDetails.image
                        allContactsList[index].name = profileDetails.name
                        allContactsList[index].status = profileDetails.status
                }
            }
                let profile = ["jid": profileDetails.jid, "name": profileDetails.name, "image": profileDetails.image, "status": profileDetails.status]
                NotificationCenter.default.post(name: Notification.Name(Identifiers.ncProfileUpdate), object: nil, userInfo: profile as [AnyHashable : Any])
                shareToTableView?.reloadData()
            }
    case 1:
        let profileDatas =  isSearchEnabled == true ? getRecentChat.filter({$0.profileType == .groupChat}).filter({ ($0.jid.contains(jid)) }) : getAllRecentChat.filter({$0.profileType == .groupChat}).filter({ ($0.jid.contains(jid)) })
        if profileDatas.count > 0, let profileData = profileDatas.first {
            if isSearchEnabled == true {
                if  let index = getRecentChat.filter({$0.profileType == .groupChat}).firstIndex(of: profileData) {
                    getRecentChat.filter({$0.profileType == .groupChat})[index].profileImage = profileDetails.image
                    getRecentChat.filter({$0.profileType == .groupChat})[index].profileName = profileDetails.name
                }
            } else {
                    if  let index = getAllRecentChat.filter({$0.profileType == .groupChat}).firstIndex(of: profileData) {
                        getAllRecentChat.filter({$0.profileType == .groupChat})[index].profileImage = profileDetails.image
                        getAllRecentChat.filter({$0.profileType == .groupChat})[index].profileName = profileDetails.name
                }
            }
                let profile = ["jid": profileDetails.jid, "name": profileDetails.name, "image": profileDetails.image, "status": profileDetails.status]
                NotificationCenter.default.post(name: Notification.Name(Identifiers.ncProfileUpdate), object: nil, userInfo: profile as [AnyHashable : Any])
                shareToTableView?.reloadData()
            }
    case 2:
        let profileDatas =  isSearchEnabled == true ? getRecentChat : getAllRecentChat
        if profileDatas.count > 0, let profileData = profileDatas.first  {
            if isSearchEnabled == true {
                if  let index = getRecentChat.firstIndex(of: profileData) {
                    getRecentChat[index].profileImage = profileDetails.image
                    getRecentChat[index].profileName = profileDetails.name
                }
            } else {
                    if  let index = getAllRecentChat.firstIndex(of: profileData) {
                        getAllRecentChat[index].profileImage = profileDetails.image
                        getAllRecentChat[index].profileName = profileDetails.name
                }
            }
                let profile = ["jid": profileDetails.jid, "name": profileDetails.name, "image": profileDetails.image, "status": profileDetails.status]
                NotificationCenter.default.post(name: Notification.Name(Identifiers.ncProfileUpdate), object: nil, userInfo: profile as [AnyHashable : Any])
                shareToTableView?.reloadData()
            }
        default:
            break
        }
    }
}

extension SharekitShareToViewController : GroupEventsDelegate {
    func didRevokedAdminAccess(groupJid: String, revokedAdminMemberJid: String, revokedByMemberJid: String) {
    }
    
    func didAddNewMemeberToGroup(groupJid: String, newMemberJid: String, addedByMemberJid: String) {
        
    }
    
    func didRemoveMemberFromGroup(groupJid: String, removedMemberJid: String, removedByMemberJid: String) {
        
    }
    
    func didMakeMemberAsAdmin(groupJid: String, newAdminMemberJid: String, madeByMemberJid: String) {
        
    }
    
    func didDeleteGroupLocally(groupJid: String) {
        
    }
    
    func didLeftFromGroup(groupJid: String, leftUserJid: String) {
        
    }
    
    func didCreateGroup(groupJid: String) {
        
    }
    
    func didFetchGroups(groups: [ProfileDetails]) {
        
    }
    
    func didFetchGroupMembers(groupJid: String) {
        
    }
    
    func didReceiveGroupNotificationMessage(message: ChatMessage) {
        
    }
    
    func didFetchGroupProfile(groupJid: String) {
        print("RecentChatViewController didGroupProfileFetch \(groupJid)")
        DispatchQueue.main.async { [weak self] in
            self?.loadChatList()
            if let uiSearchBar = self?.searchBar, self?.isSearchEnabled ?? false{
                self?.searchBar(uiSearchBar, textDidChange: self?.searchedText ?? emptyString())
            }
        }
    }
    
    func didUpdateGroupProfile(groupJid: String) {
        let array = isSearchEnabled == true ? getRecentChat.filter({$0.profileType == .groupChat}) : getAllRecentChat.filter({$0.profileType == .groupChat})
        
        let group = GroupManager.shared.getAGroupFromLocal(groupJid: groupJid)
        DispatchQueue.main.async { [weak self] in
            array.enumerated().forEach { (index, element) in
                if element.jid == groupJid {
                    if self?.isSearchEnabled == true {
                        self?.getRecentChat[index].profileName = (group?.name ?? group?.nickName) ?? ""
                        self?.getRecentChat[index].profileImage = group?.image
                    } else {
                        self?.getAllRecentChat[index].profileName = (group?.name ?? group?.nickName) ?? ""
                        self?.getAllRecentChat[index].profileImage = group?.image
                    }
                    self?.shareToTableView?.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                }
            }
        }
    }
}

// MessageEventDelegate
extension SharekitShareToViewController : MessageEventsDelegate {
    func onChatCleared(toJid: String, chatClearType: MirrorFlySDK.ChatClearType) {
        
    }
    
    func onMessageDeleted(toJid: String, messageIds: [String], messageDeleteType: MirrorFlySDK.MessageDeleteType) {
        
    }
    
    func onAllChatsCleared() {
        
    }
    
    func onMessageEdited(message: MirrorFlySDK.ChatMessage) {
        
    }
    
    func onMediaStatusFailed(error: String, messageId: String) {

    }
    
  
    func onMessageTranslated(message: ChatMessage, jid: String) {
        
    }
    
    func onMessageStatusUpdated(messageId: String, chatJid: String, status: MessageStatus) {
        print("#shareKitUpload onMessageStatusUpdated \(isXmppConnected) \(status) \(messageId)")
        var canExit = false
        //if isXmppConnected {
        uploadedMessageIDs.removeAll { id in
            if id == messageId && (status == .acknowledged) {
                print("#shareKitUpload onMessageStatusUpdated acknowledged \(messageId) \(status)")
                canExit = true
                totalMessages+=1
                return true
            }
            return false
        }
        forwardingMessages.removeAll { id in
            if id == messageId && (status == .acknowledged) {
                print("#shareKitUpload onMessageStatusUpdated forwarded acknowledged \(messageId) \(status)")
                canExit = true
                totalMessages+=1
                return true
            }
            return false
        }
        print("#shareKitUpload onMessageStatusUpdated \(uploadedMessageIDs.count), \(forwardingMessages.count), \(totalMessages), \(messageIDs.count)")
        if uploadedMessageIDs.isEmpty && canExit && forwardingMessages.isEmpty && totalMessages == messageIDs.count {
            print("#shareKitUpload onMessageStatusUpdated connected exit")
            self.closeShareKit()
        }
        if isSearchEnabled == false {
            refreshMessages()
        }
    }
    
    func onMediaStatusUpdated(message: ChatMessage) {
        var canExit = false
        if message.mediaChatMessage != nil && message.mediaChatMessage?.mediaUploadStatus == .uploaded {
            if messageIDs.contains(message.messageId) {
                uploadedMessageIDs.append(message.messageId)
                //totalMessages+=1

                print("#shareKitUpload onMediaStatusUpdated uploaded \(message.messageId), \(totalMessages)")

                uploadingMessages.removeAll { id in
                    if id == message.messageId {
                        print("#shareKitUpload onMediaStatusUpdated uploadingMessage")
                        canExit = true
                        return true
                    }
                    return false
                }
                var profilesList = self.selectedProfiles
                profilesList.removeFirst()
                let jids = profilesList.compactMap({ $0.jid })
                if !jids.isEmpty {
                    ChatManager.forwardMessages(messageIdList: [message.messageId], toJidList: jids, chatType: (self.getProfileDetails?.profileChatType ?? .singleChat), completionHandler: {isSuccess,error,data in
                        var data = data
                        if let messageId = (data.getData() as? ChatMessage)?.messageId {
                            self.messageIDs.append(messageId)
                            self.forwardingMessages.append(messageId)
                            //self.totalMessages+=1
                            print("#shareKitUpload forward \(messageId), \(message.messageId)")
                        }
                    })
                }
            }
        }
        if !isXmppConnected {
            if uploadingMessages.isEmpty && canExit {
                print("#shareKitUpload onMediaStatusUpdated disconnect exit")
                if self.selectedProfiles.count > 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.closeShareKit()
                    }
                } else {
                    self.closeShareKit()
                }
            }
            if isSearchEnabled == false {
                refreshMessages()
            }
        }

    }
    
    func onMediaStatusFailed(error: String, messageId: String, errorCode: Int) {
        print("#shareKitUpload onMediaStatusFailed \(messageId) \(errorCode)")
        var canExit = false
        uploadingMessages.removeAll { id in
            if id == messageId {
                canExit = true
                return true
            }
            return false
        }
        if uploadingMessages.isEmpty && canExit {
            ShareKitAlert.shared.showToast(controller: self, message: "Media upload failed. Please check your internet connection or try again later")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.closeShareKit()
            }
        }
    }
    
    func onMediaProgressChanged(message: ChatMessage, progressPercentage: Float) {
        child.label.text = "processing files \((sendingMessagesCount-uploadingMessages.count)+1) of \(sendingMessagesCount) \n \(Int(progressPercentage))% completed"
    }
    
    func onMessagesClearedOrDeleted(messageIds: Array<String>) {
        loadChatList()
    }
    
    func onMessagesDeletedforEveryone(messageIds: Array<String>) {
        checkMessageValidation(messages: messageIds)
    }
    
    func showOrUpdateOrCancelNotification() {}
    
    func onMessagesCleared(toJid: String, deleteType: String?) {}
    
    func setOrUpdateFavourite(messageId: String, favourite: Bool, removeAllFavourite: Bool) {}
    
    func onMessageReceived(message: ChatMessage, chatJid: String) {
        if isSearchEnabled == false {
            loadChatList()
        } else {
            refreshMessages()
        }
    }
    
    func clearAllConversationForSyncedDevice() {}
}

extension SharekitShareToViewController : AdminBlockDelegate {
    func didBlockOrUnblockContact(userJid: String, isBlocked: Bool) {
        checkUserForAdminBlocking(jid: userJid, isBlocked: isBlocked)
    }
    
    func didBlockOrUnblockSelf(userJid: String, isBlocked: Bool) {
    
    }
    
    func didBlockOrUnblockGroup(groupJid: String, isBlocked: Bool) {
        checkUserForAdminBlocking(jid: groupJid, isBlocked: isBlocked)
        let messages = shareMessages.filter({$0.chatMessage.chatUserJid == groupJid})
        if isBlocked && messages.count > 0 {
            self.navigationController?.navigationBar.isHidden = false
            self.navigationController?.popToRootViewController(animated: true)
            executeOnMainThread { [self] in
                self.stopLoading()
                ShareKitAlert.shared.showToast(controller: self, message: groupNoLongerAvailable)
            }
        }
    }

}

// To handle Admin Blocked user

extension SharekitShareToViewController {
    func checkUserForAdminBlocking(jid : String, isBlocked : Bool) {
        if isBlocked{
            filteredContactList = removeAdminBlockedContact(profileList: filteredContactList, jid: jid, isBlockedByAdmin: isBlocked)
            allContactsList = removeAdminBlockedContact(profileList: allContactsList, jid: jid, isBlockedByAdmin: isBlocked)
            getRecentChat = removeAdminBlockedRecentChat(recentChatList: getRecentChat, jid: jid, isBlockedByAdmin: isBlocked)
            getAllRecentChat = removeAdminBlockedRecentChat(recentChatList: getAllRecentChat, jid: jid, isBlockedByAdmin: isBlocked)
        } else {
            getRecentChat = checkAndAddRecentChat(recentChatList: getRecentChat, jid: jid, isBlockedByAdmin: isBlocked)
            getAllRecentChat = checkAndAddRecentChat(recentChatList: getAllRecentChat, jid: jid, isBlockedByAdmin: isBlocked)
            if !FlyUtils.isValidGroupJid(groupJid: jid) {
                allContactsList = addUnBlockedContact(profileList: allContactsList, jid: jid, isBlockedByAdmin: isBlocked)
                filteredContactList = addUnBlockedContact(profileList: filteredContactList, jid: jid, isBlockedByAdmin: isBlocked)
            }
        }
        executeOnMainThread { [weak self] in
            self?.shareToTableView?.reloadData()
        }
        
    }
}

extension SharekitShareToViewController : UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if ENABLE_CONTACT_SYNC {
            return
        }
        
        if segmentSelectedIndex != 0 {
            return
        }
        
        let position  = scrollView.contentOffset.y
         if position > shareToTableView.contentSize.height-200 - scrollView.frame.size.height {
             if isPaginationCompleted(){
                 print("#fetch Pagination Done")
                 return
             }
            shareToTableView.tableFooterView = createTableFooterView()
            if !isLoadingInProgress{
                isLoadingInProgress = true
                getUsersList(pageNo: searchTerm.isEmpty ? nextPage : searchNextPage, pageSize: 20, searchTerm: searchTerm)
            }
        }
    }
    
    public func isPaginationCompleted() -> Bool {
        if searchTerm.isEmpty{
            if (totalPages < nextPage) || allContactsList.count == totalUsers || loadingCompleted  {
                return true
            }
        }else{
            if (searchTotalPages < searchNextPage) || filteredContactList.count == searchTotalUsers || loadingCompleted  {
                return true
            }
        }
        return false
    }
    
    
    public func getUsersList(pageNo : Int = 1, pageSize : Int =  40, searchTerm : String){
        print("#fetch request \(pageNo) \(pageSize) \(searchTerm) \(isFirstPageLoaded)")
        if pageNo == 1{
            isFirstPageLoaded = false
            initalLoader()
        }
        if !NetworkReachability.shared.isConnected{
            ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.noInternet)
            return
        }
        isLoadingInProgress = true
        ContactManager.shared.getUsersList(pageNo: pageNo, pageSize: pageSize, search: searchTerm) { [weak self] isSuccess, flyError, flyData in
            guard let self = self else {
                return
            }
            if isSuccess{
                var data = flyData
                var profilesCount = 0
                if pageNo == 1{
                    self.isFirstPageLoaded = true
                }
                if let profileArray = data.getData() as? [ProfileDetails]{
                    self.removeDuplicates(profileDetails: profileArray)
                    self.setSelectedUsers(users: profileArray)
                    if searchTerm.isEmpty{
                        if pageNo == 1{
                            self.allContactsList.removeAll()
                        }
                        self.allContactsList.append(contentsOf: profileArray)
                    }else{
                        if pageNo == 1{
                            self.filteredContactList.removeAll()
                        }
                        self.filteredContactList.append(contentsOf: profileArray)
                    }
                    profilesCount = profileArray.count
                }
                if searchTerm.isEmpty{
                    if profilesCount >= pageSize{
                        self.nextPage += 1
                    }else{
                        self.loadingCompleted = true
                    }
                    self.totalPages = data["totalPages"] as? Int ?? 1
                    self.totalUsers = data["totalRecords"] as? Int ?? 1
                    print("#fetch response \(self.totalPages) \(self.nextPage) \(self.totalUsers) \(self.allContactsList.count) \(self.searchTerm)")
                }else{
                    if profilesCount >= pageSize{
                        self.searchNextPage += 1
                    }else{
                        self.loadingCompleted = true
                    }
                    self.searchTotalPages = data["totalPages"] as? Int ?? 1
                    self.searchTotalUsers = data["totalRecords"] as? Int ?? 1
                    print("#fetch response search \(pageNo) \(self.searchTotalPages) \(self.searchNextPage) \(self.searchTotalUsers) \(self.filteredContactList.count) \(self.searchTerm)")
                }
                self.shareToTableView.tableFooterView = nil
                self.shareToTableView.reloadData()
                self.showHideEmptyMessage(totalCount: self.searchTerm.isEmpty ? self.allContactsList.count : self.filteredContactList.count)
            }else{
                if !NetworkReachability.shared.isConnected{
                    ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.noInternet)
                }else{
                    var data = flyData
                    if let message = data.getMessage() as? String{
                        print(message)
                    }
                }
            }
            self.isLoadingInProgress = false
        }
    }
    
    public func resetParams(){
        totalPages = 2
        totalUsers = 1
        nextPage = 1
        searchTotalPages = 2
        searchTotalUsers = 1
        searchNextPage = 1
        isLoadingInProgress = false
        loadingCompleted = false
        isFirstPageLoaded = false
    }
    
    public func resetDataAndFetchUsersList(){
        resetParams()
        filteredContactList.removeAll()
        allContactsList.removeAll()
        shareToTableView.reloadData()
        getUsersList(pageNo: 1, pageSize: 20, searchTerm: searchTerm)
    }
    
    public func setSelectedUsers(users: [ProfileDetails]){
        for item in allContactsList{
            item.isSelected = selectedJids.contains(item.jid)
        }
    }
    
    public func saveUserToDatabase(jid : String){
        if let index = allContactsList.firstIndex { pd in pd.jid == jid}, index > -1{
            ContactManager.shared.saveUser(profileDetails: allContactsList[index], saveAs: .live)
        } else if let index = filteredContactList.firstIndex { pd in pd.jid == jid}, index > -1{
            ContactManager.shared.saveUser(profileDetails: filteredContactList[index], saveAs: .live)
        }
    }
    
    public func createTableFooterView() -> UIView {
        let spinner = UIActivityIndicatorView(style: .gray)
        spinner.startAnimating()
        spinner.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: shareToTableView.bounds.size.width, height: CGFloat(64))
        return spinner
    }
    
    @objc func networkChange(_ notification: NSNotification) {
        DispatchQueue.main.async { [weak self] in
            let isNetworkAvailable = notification.userInfo?[NetStatus.isNetworkAvailable] as? Bool ?? false
            self?.internetObserver.on(.next(isNetworkAvailable))
        }
        
    }
    
    func  resumeLoading()  {
        if !ENABLE_CONTACT_SYNC{
            if isLoadingInProgress || !isPaginationCompleted() {
                print("#internet nextPage => \(self.nextPage)")
                self.getUsersList(pageNo: self.searchTerm.isEmpty ? self.nextPage : self.searchNextPage, pageSize: 20, searchTerm: self.searchTerm)
            }
        }
    }
    
    func removeDuplicates(profileDetails : [ProfileDetails])  {
        let userIds = profileDetails.compactMap{$0.jid}
        filteredContactList.removeAll { pd in
            userIds.contains(pd.jid)
        }
        allContactsList.removeAll { pd in
            userIds.contains(pd.jid)
        }
    }
    
}

extension SharekitShareToViewController {
    private func showBlockUnblockConfirmationPopUp(jid: String,name: String) {
        //showConfirmationAlert
        let alertViewController = UIAlertController.init(title: getBlocked(jid: jid) ? "Unblock?" : "Block?" , message: (getBlocked(jid: jid) ) ? "Unblock \(getProfileDetails?.nickName ?? "")?" : "Block \(self.getProfileDetails?.nickName ?? "")?", preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] (action) in
            self?.dismiss(animated: true,completion: nil)
        }
        let blockAction = UIAlertAction(title: getBlocked(jid: jid) ? ChatActions.unblock.rawValue : ChatActions.block.rawValue, style: .default) { [weak self] (action) in
            if !(self?.getBlocked(jid: jid) ?? false) {
                self?.blockUser(jid:jid, name: name)
            } else {
                self?.UnblockUser(jid:jid, name: name)
            }
        }
        alertViewController.addAction(cancelAction)
        alertViewController.addAction(blockAction)
        alertViewController.preferredAction = cancelAction
        present(alertViewController, animated: true)
    }
    
    //MARK: BlockUser
    private func blockUser(jid: String?,name: String?) {
        do {
            try ContactManager.shared.blockUser(for: jid ?? "") { isSuccess, error, data in
                if isSuccess {
                    executeOnMainThread { [self] in
                        self.loadChatList()
                        ShareKitAlert.shared.showToast(controller: self, message: "\(name ?? "") has been Blocked")
                    }
                }else{
                    let message = Utility.shared.getErrorMessage(description: error?.description ?? "")
                    ShareKitAlert.shared.showAlert(view: self, title: "" , message: message, buttonTitle: "OK") {_ in }
                    return
                }
            }
        } catch let error as NSError {
            print("block user error: \(error)")
        }
    }
    
    //MARK: UnBlockUser
    private func UnblockUser(jid: String?,name: String?) {
        do {
            try ContactManager.shared.unblockUser(for: jid ?? "") { isSuccess, error, data in
                if isSuccess {
                    executeOnMainThread { [self] in
                        self.loadChatList()
                        ShareKitAlert.shared.showToast(controller: self, message: "\(name ?? "") has been Unblocked")
                    }
                }else {
                    let message = Utility.shared.getErrorMessage(description: error?.description ?? "")
                    ShareKitAlert.shared.showAlert(view: self, title: "" , message: message, buttonTitle: "OK") {_ in }
                    return
                }
            }
        } catch let error as NSError {
            print("block user error: \(error)")
        }
    }
}

extension SharekitShareToViewController {

    func checkUserBusyStatusEnabled(_ controller: UIViewController, jid: String, completion: @escaping (Bool)->()) {
        if ChatManager.shared.isBusyStatusEnabled() && ContactManager.shared.getUserProfileDetails(for: jid)?.profileChatType == .singleChat {
            let longTextMessage = """
            Disable busy Status.
            Do you want to continue?
            """
            
//            "Disable busy Status. Do you want to continue?"
            let alertController = UIAlertController.init(title: nil , message: longTextMessage, preferredStyle: .alert)
            let shareAction = UIAlertAction(title: "Yes", style: .default) {_ in
                if NetStatus.shared.isConnected {
                    ChatManager.shared.enableDisableBusyStatus(!ChatManager.shared.isBusyStatusEnabled()) {isSuccess,error,data in
                        completion(isSuccess)
                    }
                } else {
                    ShareKitAlert.shared.showToast(controller: self, message: ErrorMessage.noInternet)
                }
            }
            let cancelAction = UIAlertAction(title: "No", style: .cancel) { [weak controller] (action) in
                controller?.dismiss(animated: true,completion: nil)
                completion(false)
            }
            shareAction.setValue(ShareKitColor.primaryAppColor!, forKey: "titleTextColor")
            cancelAction.setValue(ShareKitColor.primaryAppColor!, forKey: "titleTextColor")
            alertController.addAction(cancelAction)
            alertController.addAction(shareAction)
            executeOnMainThread { [weak controller] in
                controller?.present(alertController, animated: true)
            }
        } else {
            completion(true)
        }
    }
}

extension SharekitShareToViewController {
    func removeAdminBlockedContact(profileList : [ProfileDetails], jid : String, isBlockedByAdmin : Bool) -> [ProfileDetails]{
        var tempProfileList = profileList
        if tempProfileList.isEmpty {
            return tempProfileList
        }

        tempProfileList.filter({$0.jid == jid}).first?.isBlockedByAdmin = isBlockedByAdmin
        tempProfileList = tempProfileList.filter({!$0.isBlockedByAdmin}).sorted { FlyUtils.getUserName(jid: $0.jid, name: $0.name, nickName: $0.nickName, contactType: $0.contactType).capitalized < FlyUtils.getUserName(jid: $1.jid, name: $1.name, nickName: $1.nickName, contactType: $1.contactType).capitalized }

        return tempProfileList
    }

    func addUnBlockedContact(profileList:  [ProfileDetails], jid: String, isBlockedByAdmin : Bool) -> [ProfileDetails]{
        var tempProfileList = profileList
        if tempProfileList.isEmpty {
            return tempProfileList
        }

        if let _ = tempProfileList.filter({$0.jid == jid}).first {
            return tempProfileList
        }

        if let profile = ChatManager.profileDetaisFor(jid: jid) {
            tempProfileList.append(profile)
        }

        tempProfileList = tempProfileList.sorted { FlyUtils.getUserName(jid: $0.jid, name: $0.name, nickName: $0.nickName, contactType: $0.contactType).capitalized < FlyUtils.getUserName(jid: $1.jid, name: $1.name, nickName: $1.nickName, contactType: $1.contactType).capitalized }

        return tempProfileList
    }

    func checkAndAddRecentChat(recentChatList : [RecentChat], jid : String, isBlockedByAdmin : Bool) -> [RecentChat] {
        var tempRecent = recentChatList
        if tempRecent.isEmpty {
            return tempRecent
        }

        if let _ = tempRecent.filter({$0.jid == jid}).first {
            return tempRecent
        }

        if let recent = ChatManager.getRechtChat(jid: jid) {
            tempRecent.append(recent)
        }

        return tempRecent
    }

    func removeAdminBlockedRecentChat(recentChatList : [RecentChat], jid : String, isBlockedByAdmin : Bool) -> [RecentChat] {
        var tempRecent = recentChatList
        if tempRecent.isEmpty {
            return tempRecent
        }

        tempRecent.filter({$0.jid == jid}).first?.isBlockedByAdmin = isBlockedByAdmin
        tempRecent = tempRecent.filter({!$0.isBlockedByAdmin})

        return tempRecent
    }
}

extension SharekitShareToViewController: ShareEditImageDelegate {

    func sendMedia(mediaData: [MirrorFlySDK.MediaData]) {
        setDelegate()
        let profilesList = selectedProfiles.compactMap({ $0.jid })
        if !mediaData.isEmpty {
            self.addLoader()
            mediaData.forEach { media in
                if media.mediaType == .video {
                    var profilesList = self.selectedProfiles
                    if !profilesList.isEmpty {
                        let profile = profilesList.first!
                        if let url = media.fileURL {
                            let mediaParams = FileMessageParams(fileUrl: media.fileURL, fileName: media.fileName, caption: media.caption,fileSize: media.fileSize, duration: media.duration, thumbImage: media.base64Thumbnail, fileKey: media.fileKey)
                            FlyMessenger.sendMediaFileMessage(messageParams: FileMessage(toId: profile.jid, messageType: .video, fileMessage: mediaParams)) { isSuccess, error, message in
                                self.messageIDs.append(message?.messageId ?? "")
                                self.uploadingMessages.append(message?.messageId ?? "")
                                if isSuccess {
                                    print("#shareKitUpload video send \(self.isXmppConnected) \(message?.messageId ?? "")")
                                }
                            }
                        }
                    }
                } else if media.mediaType == .image {
                    var profilesList = self.selectedProfiles
                    if !profilesList.isEmpty {
                        let profile = profilesList.first!
                        if let url = media.fileURL {
                            let mediaParams = FileMessageParams(fileUrl: media.fileURL, fileName: media.fileName, caption: media.caption,fileSize: media.fileSize, duration: media.duration, thumbImage: media.base64Thumbnail, fileKey: media.fileKey)
                            FlyMessenger.sendMediaFileMessage(messageParams: FileMessage(toId: profile.jid, messageType: .image, fileMessage: mediaParams)) { isSuccess, error, message in
                                self.messageIDs.append(message?.messageId ?? "")
                                self.uploadingMessages.append(message?.messageId ?? "")
                                if isSuccess {
                                    print("#shareKitUpload image send \(self.isXmppConnected) \(message?.messageId ?? "")")
                                }
                            }
                        }
                    }
                }
            }
        }
        shareAttachments()
    }
    
}

class SpinnerViewController: UIViewController {
    var spinner = UIActivityIndicatorView(style: .whiteLarge)
    var label = UILabel()

    override func loadView() {
        view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.7)

        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = "processing files"
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        view.addSubview(spinner)
        view.addSubview(label)


        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 10).isActive = true
        label.widthAnchor.constraint(equalToConstant: 250).isActive = true
    }
}

extension SharekitShareToViewController: ConnectionEventDelegate {
    func onConnectionNotAuthorized() {
        
    }
    
    
    func onConnectionFailed(error: FlyError) {
        
    }
    
    func onReconnecting() {
        
    }
    
    func onConnected() {
        print("#shareKitUpload onConnected")
        isXmppConnected = true
    }

    func onDisconnected() {
        print("#shareKitUpload onDisconnected")
        isXmppConnected = false
        if uploadingMessages.isEmpty {
            closeShareKit()
        }
    }

}
