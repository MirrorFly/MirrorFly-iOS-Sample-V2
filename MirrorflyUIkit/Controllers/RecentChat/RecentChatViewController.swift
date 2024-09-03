//  ChatViewController.swift
//  MirrorflyUIkit
//  Created by User on 28/08/21.


import UIKit
import Foundation
import MirrorFlySDK
import SDWebImage
import AVKit
import Contacts
import RxSwift

class RecentChatViewController: UIViewController, UIGestureRecognizerDelegate {
   
    @IBOutlet weak var recentChatTableView: UITableView? {
        didSet {
            recentChatTableView?.register(UINib(nibName: Identifiers.ArchiveChatTableViewCell, bundle: nil), forCellReuseIdentifier: Identifiers.ArchiveChatTableViewCell)
        }
    }
    @IBOutlet weak var searchBar: UISearchBar?
    @IBOutlet weak var emptyMessageView: UIView?
    @IBOutlet weak var descriptionMessageText: UILabel?
    @IBOutlet weak var noNewMsgText: UILabel?
    @IBOutlet weak var emptyImage: UIImageView?
    @IBOutlet weak var profilePopupContainer: UIView?
    @IBOutlet weak var username: UILabel?
    @IBOutlet weak var userImage: UIImageView?
    @IBOutlet weak var chatTabBarItem: UITabBarItem?
    @IBOutlet weak var selectionCountLabel: UILabel?
    @IBOutlet weak var multipleSelectionView: UIView?
    @IBOutlet weak var headerView: UIView?
    @IBOutlet weak var deleteChatButton: UIButton?
    @IBOutlet weak var stackView: UIStackView?
    @IBOutlet weak var readUnreadButton: UIButton!
    @IBOutlet weak var pinChatButton: UIButton!
    @IBOutlet weak var muteChatButton: UIButton!
    @IBOutlet weak var archiveChatButton: UIButton!
    @IBOutlet weak var headerBackButton: UIButton!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var createGroupButton: UIButton!
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var audioCallView: UIView!
    @IBOutlet weak var videoCallView: UIView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var chatActionMessageButton: UIButton!
    @IBOutlet weak var chatActionAudioCallButton: UIButton!
    @IBOutlet weak var chatActionVideoCallButton: UIButton!

    @IBOutlet weak var contactFloatView: UIView!
    @IBOutlet weak var contactFloatButton: UIButton!

    var onlyPrivateChatAvailableView = UIView()
    var onlyPrivateChatAvailableViewLabel = UILabel()
    
    @IBOutlet weak var chatTagsCollectionView: UICollectionView!
    var longPressCount = 0
    var isCellLongPressed: Bool? = false
    var getRecentChat: [RecentChat] = []
    var getAllRecentChat: [RecentChat] = []
    var filteredContactList =  [ProfileDetails]()
    var allContactsList =  [ProfileDetails]()
    var unreadMessageChatList: [RecentChat] = []
    var allUnreadMessageChatList: [RecentChat] = []
    var searchedMessages : [SearchMessage] = []
    var isSearchEnabled: Bool = false
    let chatManager = ChatManager.shared
    var currentIndex = -1
    private var contactViewModel : ContactViewModel?
    private var recentChatViewModel: RecentChatViewModel?
    private var selectionRecentChatList: [RecentChat] = []
    private var replyMessageObj: ChatMessage?
    private var replyJid: String?
    private var messageTxt: String?
    var tappedProfile : ProfileDetails? = nil
    var getArchiveChat: [RecentChat] = []
    var getPrivateChats: [RecentChat] = []
    var showArchivedChat = false {
        didSet{
            chatTagsCollectionView.isHidden = self.getChatTags.isEmpty ? true : showArchivedChat
        }
    }
    var showPrivateChat = false {
        didSet{
            chatTagsCollectionView.isHidden = self.getChatTags.isEmpty ? true : showPrivateChat
        }
    }
    var chatPageSize = 40
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
    var isFirstPageLoaded = false
    
    var fetchRecentChatParams : RecentChatListParams? = nil
    var recentChatListBuilder : RecentChatListBuilder? = nil
    var isRecentLoadingDone = false
    var isRecentLoadingInProgress = false
    let backgroundQueue = DispatchQueue(label: "recent")
    var availableFeatures = ChatManager.getAvailableFeatures()
    var getChatTags: [ChatTagsModel] = []
    var fetchMessageListParams = FetchMessageListParams()
    var selectedChatTag: ChatTagsModel! {
        didSet {
            if !isSearchEnabled {
                if  selectedChatTag?.tagId == AppUtils.getMyJid() || selectedChatTag == nil {
                    getRecentChatList()
                } else {
                    getRecentChatForSelectedChatTag(chatTag: selectedChatTag)
                }
                setUpPullForPrivateChat()
                recentChatTableView?.reloadData()
            }
        }
    }
    
    var selectedTagIndex = 0
    let privateChatHeaderHeight = 64
    var privateChatHeaderView = UIView()
    var releaseForPrivateChatHeaderView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
       // getAllChatTags()
        
        selectionCountLabel?.textColor = UIColor(named: "buttonColor")
        contactViewModel =  ContactViewModel()
        recentChatViewModel = RecentChatViewModel()
        fetchRecentChatParams = RecentChatListParams(limit: 20)
        recentChatListBuilder = RecentChatListBuilder(recentChatListParams: fetchRecentChatParams!)
        setupTableviewLongPressGesture()
        handleBackgroundAndForground()
        configTableView()
        NotificationCenter.default.addObserver(self, selector: #selector(self.contactSyncCompleted(notification:)), name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        searchSubject.throttle(.milliseconds(25), scheduler: MainScheduler.instance).distinctUntilChanged().subscribe { [weak self] term in
            self?.searchTerm = term
            self?.filteredContactList.removeAll()
            self?.recentChatTableView?.reloadData()
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
        Utility.saveInPreference(key: isRecentChatLoad, value: false)
    }

    func setUpPullForPrivateChat() {
        if showPrivateChat {
            return
        }
        let privateView = UIView()
        privateView.frame = CGRect(x: 0, y: 0, width: 0, height: privateChatHeaderHeight)
        let headerContentView = UIView(frame: privateChatHeaderView.bounds)
        headerContentView.backgroundColor = Color.color_D0D8EB
        headerContentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let stack = UIStackView(frame: CGRect(x: 8, y: 5, width: headerContentView.bounds.width, height: headerContentView.bounds.height-10))
        stack.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        stack.distribution = .fillProportionally
        stack.axis = .horizontal
        stack.spacing = 10

        let image = UIImageView()
        image.image = UIImage(named: "app_icon")
        image.cornerRadius(radius: 27, width: 0.5, color: .clear)
        image.contentMode = .center
        image.backgroundColor = Color.color_AFBDDF
        let imageViewWidthConstraint = NSLayoutConstraint(item: image, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 54)
        let imageViewHeightConstraint = NSLayoutConstraint(item: image, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 54)
        image.addConstraints([imageViewWidthConstraint, imageViewHeightConstraint])
        stack.addArrangedSubview(image)

        let label = UILabel(frame: headerContentView.bounds)
        label.text = "Private Chats"
        label.font = .init(name: "SFUIDisplay-Medium", size: 16)
        label.textColor = .black
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        stack.addArrangedSubview(label)
        headerContentView.addSubview(stack)
        privateView.addSubview(headerContentView)

        privateView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(privateChatTapped))
        privateView.addGestureRecognizer(tap)

        let releaseView = UIView(frame: privateView.bounds)
        //releaseView = UIView(frame: privateView.bounds)
        releaseView.backgroundColor = Color.color_D0D8EB
        releaseView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let releaseHeaderContentView = UIView(frame: privateView.bounds)
        releaseHeaderContentView.backgroundColor = Color.color_D0D8EB
        releaseHeaderContentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let releaseStack = UIStackView(frame: CGRect(x: 8, y: 0, width: releaseHeaderContentView.bounds.width, height: releaseHeaderContentView.bounds.height))
        releaseStack.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        releaseStack.distribution = .fillProportionally
        releaseStack.axis = .horizontal
        releaseStack.spacing = 10

        let releaseImage = UIImageView()
        releaseImage.image = UIImage(named: "private_down")
        releaseImage.cornerRadius(radius: 27, width: 0.5, color: .clear)
        releaseImage.contentMode = .center
        let releaseImageViewWidthConstraint = NSLayoutConstraint(item: releaseImage, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 54)
        let releaseImageViewHeightConstraint = NSLayoutConstraint(item: releaseImage, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 54)
        releaseImage.addConstraints([releaseImageViewWidthConstraint, releaseImageViewHeightConstraint])
        releaseStack.addArrangedSubview(releaseImage)

        let releaseLabel = UILabel(frame: releaseHeaderContentView.bounds)
        releaseLabel.text = "Release for Private Messages"
        releaseLabel.font = .init(name: "SFUIDisplay-Medium", size: 16)
        releaseLabel.textColor = .black
        releaseLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        releaseStack.addArrangedSubview(releaseLabel)
        releaseHeaderContentView.addSubview(releaseStack)
        releaseView.addSubview(releaseHeaderContentView)

        privateView.addSubview(releaseView)
        privateView.isHidden = true
        releaseView.isHidden = false

        //DispatchQueue(label: "GetPrivatechatList").async { [weak self] in
            ChatManager.getPrivateChatList { isSuccess, error, data in
                if isSuccess {
                    executeOnMainThread {
                        let list = data["data"] as? [RecentChat] ?? []
                        if list.count > 0 {
                            self.recentChatTableView?.tableHeaderView = privateView
                            self.recentChatTableView?.contentInset.top = -1 * privateView.frame.size.height
                        } else {
                            self.recentChatTableView?.tableHeaderView = nil
                            self.recentChatTableView?.contentInset.top = 0
                        }
                    }
                    
                }
            }
        //}

        self.privateChatHeaderView = privateView
        self.releaseForPrivateChatHeaderView = releaseView
    }

    @objc func privateChatTapped(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
        showLockScreen()
    }

    func showLockScreen() {
        if CommonDefaults.appFingerprintenable {
            let vc = PrivateChatFingerPrintPINViewController(nibName: "PrivateChatFingerPrintPINViewController", bundle: nil)
            vc.isFromPrivateRecentChat = true
            vc.privateChatDelegate = self
            self.navigationController?.pushViewController(vc, animated: false)
        } else {
            let vc = PrivateChatAuthenticationPINViewController(nibName:"PrivateChatAuthenticationPINViewController", bundle: nil)
            vc.isFromPrivateRecentChat = true
            vc.privateChatDelegate = self
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func setupDelegate() {
        chatManager.connectionDelegate = self
        ContactManager.shared.profileDelegate = self
        chatManager.messageEventsDelegate = self
        FlyMessenger.shared.messageEventsDelegate = self
        GroupManager.shared.groupDelegate = self
        ChatManager.shared.adminBlockDelegate = self
        chatManager.archiveEventsDelegate = self
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            recentChatTableView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height + (recentChatTableView?.rowHeight ?? 0.0) + 30, right: 0)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        recentChatTableView?.contentInset = .zero
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.privateChatSwitchNotification(notification:)), name: Notification.Name("PrivateChatSwitch"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.methodOfReceivedNotification(notification:)), name: Notification.Name("PrivateChatAlertView"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.privateChatAuthorized(notification:)), name: Notification.Name("PrivateRecentChatAuthenticated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(networkChange(_:)),
                                               name: Notification.Name(NetStatus.networkNotificationObserver), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground),
                                               name: NSNotification.Name(didBecomeActive), object: nil)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        NotificationCenter.default.addObserver(self, selector: #selector(enteredBackGround), name: UIScene.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(permissionAlertNotification), name: Notification.Name(FlyConstants.callPermissionAlertShown), object: nil)
        getRecentChatList()
        getAllChatTags()
        setUpPullForPrivateChat()
        if ENABLE_CONTACT_SYNC{
            getContactList()
        }else{
            resetDataAndFetchUsersList()
        }

        ChatManager.shared.availableFeaturesDelegate = self
        availableFeatures = ChatManager.getAvailableFeatures()
        searchBar?.isHidden = !(availableFeatures.isRecentChatSearchEnabled) ? true : false
        if !CommonDefaults.showAppLock || ChatManager.isPrivateChat(jid: pushChatId ?? "") {
            openChat(jid: pushChatId ?? "")
        }
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        ChatViewParentController.receiveCallModeDelegate = nil
        CallUIViewController.pipModeDelegate = nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupDelegate()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        chatManager.connectionDelegate = nil
        ContactManager.shared.profileDelegate = nil
        ChatManager.shared.messageEventsDelegate = nil
        FlyMessenger.shared.messageEventsDelegate = nil
        GroupManager.shared.groupDelegate = nil
        ChatManager.shared.adminBlockDelegate = nil
        ChatManager.shared.availableFeaturesDelegate = nil
        chatManager.archiveEventsDelegate = nil
        self.recentChatTableView?.tableHeaderView = nil
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NetStatus.networkNotificationObserver), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("PrivateChatAlertView"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("PrivateRecentChatAuthenticated"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(FlyConstants.callPermissionAlertShown), object: nil)
    }

    @objc func willEnterForeground() {
       setUpPullForPrivateChat()
        self.view.removeLaunchSubview()
        self.getRecentChatList()
        self.updateRecentChatsLoading()
    }

    override func willCometoForeground() {
        self.view.removeLaunchSubview()
//        executeInBackground { [weak self] in
        self.getRecentChatList()
        self.updateRecentChatsLoading()
//        }
        setUpPullForPrivateChat()
        if !ENABLE_CONTACT_SYNC && isSearchEnabled{
            resetDataAndFetchUsersList()
        }
        if !CommonDefaults.showAppLock {
            if showPrivateChat && CommonDefaults.appLockOnPrivateChat && !CommonDefaults.showPrivateLockRecent && !pushNotificationSelected {
                showLockScreen()
                CommonDefaults.appLockOnPrivateChat = false
            } else if showPrivateChat && CommonDefaults.appLockOnPrivateChat && !pushNotificationSelected && !CommonDefaults.privateChatOnChatScreen {
                showLockScreen()
            } else {
                let current = UIApplication.shared.keyWindow?.getTopViewController()
                if (current is RecentChatViewController) {
                    openChat(jid: pushChatId ?? "")
                }
            }
        } else {
            let current = UIApplication.shared.keyWindow?.getTopViewController()
            if (current is RecentChatViewController) {
                openChat(jid: pushChatId ?? "")
            }
        }
//        else if showPrivateChat && CommonDefaults.appLockOnPrivateChat && !pushNotificationSelected && !CommonDefaults.privateChatOnChatScreen && CommonDefaults.showPrivateLockChat {
//            showLockScreen()
//        }
        
    }

    override func didMoveToBackground() {
        let current = UIApplication.shared.keyWindow?.getTopViewController()
        if (current is RecentChatViewController) {
            CommonDefaults.appLockOnPrivateChat = showPrivateChat ? true : false
            CommonDefaults.privateChatOnChatScreen = false
            if self.recentChatTableView?.contentInset.top ?? 0 >= 0 {
                self.recentChatTableView?.tableHeaderView = nil
            }
            if showPrivateChat {
                if !CommonDefaults.permissionAlertShown {
                    self.view.addLaunchSubview()
                }
            }
        }
    }
    @objc func enteredBackGround() {
        if showPrivateChat {
            self.view.addLaunchSubview()
        }
    }

    @objc func permissionAlertNotification(notification: Notification) {
        if let status = notification.object as? Bool {
            CommonDefaults.permissionAlertShown = status
        }
    }


    @objc func methodOfReceivedNotification(notification: Notification) {
        updatePrivateChatView()
    }

    @objc func privateChatSwitchNotification(notification: Notification) {
        updatePrivateChatView()
        NotificationCenter.default.removeObserver(self, name: Notification.Name("PrivateChatSwitch"), object: nil)
    }

    @objc func privateChatAuthorized(notification: Notification) {
        updatePrivateChatView()
        recentChatTableView?.reloadData()
    }

    private func configTableView() {
        searchBar?.delegate = self
        recentChatTableView?.estimatedRowHeight = 65.0
        UITableViewHeaderFooterView.appearance().tintColor = Color.recentChatHeaderSectionColor
        profilePopupContainer?.isHidden = true
        recentChatTableView?.delegate = self
        recentChatTableView?.dataSource = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        profilePopupContainer?.addGestureRecognizer(tap)
    }
    
    func setupTableviewLongPressGesture() {
        let longPressGesture:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector( handleCellLongPress))
        longPressGesture.delegate = self
        recentChatTableView?.addGestureRecognizer(longPressGesture)
    }

    @objc func contactSyncCompleted(notification: Notification){
        if let contactSyncState = notification.userInfo?[FlyConstants.contactSyncState] as? String {
            switch ContactSyncState(rawValue: contactSyncState) {
            case .inprogress:
                break
            case .success:
                getRecentChatList()
            case .failed:
                print("contact sync failed")
            case .none:
                print("contact sync failed")
            }
        }
    }
    
    @objc func handleCellLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        searchBar?.resignFirstResponder()
        if gestureRecognizer.state == .began && isSearchEnabled == false {
            let touchPoint = gestureRecognizer.location(in:  recentChatTableView)
            if let indexPath =  recentChatTableView?.indexPathForRow(at: touchPoint) {
                    if let cell =  recentChatTableView?.cellForRow(at: indexPath) as? RecentChatTableViewCell {
                        if selectionRecentChatList.filter({$0.jid == (showArchivedChat ? getArchiveChat[indexPath.row].jid : showPrivateChat ? getPrivateChats[indexPath.row].jid : getRecentChat[indexPath.row].jid) }).count == 0 {
                            cell.contentView.backgroundColor = Color.recentChatSelectionColor
                            isCellLongPressed = true
                            recentChatTableView?.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                            showHideDeleteButton()
                            if showArchivedChat {
                                getArchiveChat[indexPath.row].isSelected = !getArchiveChat[indexPath.row].isSelected
                                selectionRecentChatList.insert(getArchiveChat[indexPath.row], at: 0)
                            } else if showPrivateChat {
                                getPrivateChats[indexPath.row].isSelected = !getPrivateChats[indexPath.row].isSelected
                                selectionRecentChatList.insert(getPrivateChats[indexPath.row], at: 0)
                            } else {
                                getRecentChat[indexPath.row].isSelected = !getRecentChat[indexPath.row].isSelected
                                selectionRecentChatList.insert(getRecentChat[indexPath.row], at: 0)
                            }
                            longPressCount += 1
                            hideHeaderView()
                            selectionCountLabel?.isHidden = false
                        }
                    }
                    if(longPressCount >= 1) {
                        selectionCountLabel?.text =  String( longPressCount)
                    }
                    showHideDeleteButton()
                    recentChatTableView?.allowsMultipleSelection = true
                updatePinIcon()
                updateChatReadIcon()
                updateMuteIcon()
                updateArchiveIcon()
            }
        }
    }

    @objc func imageButtonAction(_ sender:UIButton){
        closeKeyboard()
        let buttonTag = sender.tag
        currentIndex = buttonTag
        if showPrivateChat ? getPrivateChats[currentIndex].isBlockedByAdmin && getPrivateChats[currentIndex].isGroup : showArchivedChat ? getArchiveChat[currentIndex].isBlockedByAdmin && getArchiveChat[currentIndex].isGroup : getRecentChat[currentIndex].isBlockedByAdmin && getRecentChat[currentIndex].isGroup {
            showGroupBlockedView()
        } else if isSearchEnabled == true{
            self.profilePopupContainer?.isHidden = true
        }
        else {
            UIView.transition(with: profilePopupContainer ?? UIView(), duration: 0.5, options: .transitionCrossDissolve, animations: { [weak self] in
                if let weakSelf = self {
                    weakSelf.profilePopupContainer?.isHidden = false
                }
            })
            setProfile()
        }
    }
    
    private func showGroupBlockedView() {
        AppAlert.shared.showAlert(view: self, title: groupNoLongerAvailable, message: "", buttonTitle: okButton)
    }
    
    
    @objc func closeKeyboard() {
        self.view.endEditing(true)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        UIView.transition(with: profilePopupContainer ?? UIView(), duration: 0.5, options: .transitionFlipFromLeft, animations: { [weak self] in
            if let weakSelf = self {
                weakSelf.profilePopupContainer?.isHidden = true
                weakSelf.currentIndex = -1
            }
        })
    }
    
    @objc
    func openContainerImage(sender: UITapGestureRecognizer? = nil) {
        if sender?.view?.tag == 0 {
            return
        }
        if let controller = UIStoryboard.init(name: Storyboards.chat, bundle: Bundle.main).instantiateViewController(withIdentifier: "ViewUserImageController") as? ViewUserImageController {
            let getChatJID = showArchivedChat ? getArchiveChat[currentIndex].jid : getRecentChat[currentIndex].jid
            guard let getRecentChatProfile = ContactManager.shared.getUserProfileDetails(for: getChatJID) else {
                return
            }
            
            let profile = showArchivedChat ? getArchiveChat[currentIndex] : getRecentChat[currentIndex]
            controller.profileDetails?.jid = profile.jid
            controller.profileDetails = getRecentChatProfile
            controller.navigationController?.modalPresentationStyle = .overFullScreen
            profilePopupContainer?.isHidden = true
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    //Recent Chat Actions
    
    @IBAction func message(_ sender: Any) {
        openChat(index:currentIndex)
        profilePopupContainer?.isHidden = true
    }
    
    @IBAction func call(_ sender: Any) {
        
        let profile = showPrivateChat ? getPrivateChats[currentIndex] : showArchivedChat ? getArchiveChat[currentIndex] : getRecentChat[currentIndex]
        let callType = CallType.Audio
        
        if !NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: ErrorMessage.checkYourInternet)
            return
        }
        else if profile.profileType == .singleChat && profile.isBlockedByAdmin && !profile.isDeletedUser {
           return
        }
        
        else {
            
            if CallManager.isAlreadyOnAnotherCall(){
                AppAlert.shared.showToast(message: "You’re already on call, can't make new MirrorFly call")
                return
            }
            
            if !profile.isDeletedUser && profile.isBlocked && profile.profileType == .singleChat && !profile.isBlockedByAdmin {
                AppAlert.shared.showAlert(view: self,
                                          message: unblockTOMakeAudioCall,
                                          buttonOneTitle: unblock,
                                          buttonTwoTitle: cancel)
                AppAlert.shared.onAlertAction = { [weak self] (result) ->
                    Void in
                    if result == 0 {
                        BlockUnblockViewModel.unblockUser(jid: profile.jid) {[weak self] isSuccess, error, data in
                            if isSuccess{
                                RootViewController.sharedInstance.callViewController?.makeCall(usersList: [profile.jid], callType: callType, onCompletion: { isSuccess, message in
                                    if(!isSuccess){
                                        let errorMessage = AppUtils.shared.getErrorMessage(description: message)
                                        AppAlert.shared.showAlert(view: self!, title: "", message: errorMessage, buttonTitle: "Okay")
                                    }
                                })
                            }
                            else {
                                AppAlert.shared.showToast(message: ErrorMessage.checkYourInternet)
                            }
                        }
                    }
                    else {
                        self?.profilePopupContainer?.isHidden = true
                    }
                }
            }
            
            else if  profile.profileType == .singleChat && !profile.isDeletedUser && !profile.isBlocked && !profile.isBlockedByAdmin {
               
                    RootViewController.sharedInstance.callViewController?.makeCall(usersList: [profile.jid], callType: callType, onCompletion: { isSuccess, message in
                        if(!isSuccess){
                            let errorMessage = AppUtils.shared.getErrorMessage(description: message)
                            AppAlert.shared.showAlert(view: self, title: "", message: errorMessage, buttonTitle: "Okay")
                        }
                    })
                }
        }
        profilePopupContainer?.isHidden = true
    }
    
    @IBAction func videoCall(_ sender: Any) {
        
        let profile = showPrivateChat ? getPrivateChats[currentIndex] : showArchivedChat ? getArchiveChat[currentIndex] : getRecentChat[currentIndex]
        let callType = CallType.Video
        
        if !NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: ErrorMessage.checkYourInternet)
            return
        }
        else if profile.profileType == .singleChat && profile.isBlockedByAdmin && !profile.isDeletedUser {
            return
        }
        else {
            
            if CallManager.isAlreadyOnAnotherCall(){
                AppAlert.shared.showToast(message: "You’re already on call, can't make new MirrorFly call")
                return
            }
           
            if !profile.isDeletedUser && profile.isBlocked && profile.profileType == .singleChat && !profile.isBlockedByAdmin {
                AppAlert.shared.showAlert(view: self,
                                          message: unblockToMakeVideocall,
                                          buttonOneTitle: unblock,
                                          buttonTwoTitle: cancel)
                AppAlert.shared.onAlertAction = { [weak self] (result) ->
                    Void in
                    if result == 0 {
                        BlockUnblockViewModel.unblockUser(jid: profile.jid) {[weak self] isSuccess, error, data in
                            if isSuccess{
                                RootViewController.sharedInstance.callViewController?.makeCall(usersList: [profile.jid], callType: callType, onCompletion: { isSuccess, message in
                                    if(!isSuccess){
                                        let errorMessage = AppUtils.shared.getErrorMessage(description: message)
                                        AppAlert.shared.showAlert(view: self!, title: "", message: errorMessage, buttonTitle: "Okay")
                                    }
                                })
                            }
                            else {
                                AppAlert.shared.showToast(message: ErrorMessage.checkYourInternet)
                            }
                        }
                    }
                    else {
                        self?.profilePopupContainer?.isHidden = true
                    }
                }
            }
         else if  profile.profileType == .singleChat && !profile.isDeletedUser && !profile.isBlocked && !profile.isBlockedByAdmin {
                    RootViewController.sharedInstance.callViewController?.makeCall(usersList: [profile.jid], callType: callType, onCompletion: { isSuccess, message in
                        if(!isSuccess){
                            let errorMessage = AppUtils.shared.getErrorMessage(description: message)
                            AppAlert.shared.showAlert(view: self, title: "", message: errorMessage, buttonTitle: "Okay")
                        }
                    })
                }
        }
        
        profilePopupContainer?.isHidden = true
    }
    
    @IBAction func userInfo(_ sender: Any) {
        let profile = showPrivateChat ? getPrivateChats[currentIndex] : showArchivedChat ? getArchiveChat[currentIndex] : getRecentChat[currentIndex]
            if profile.profileType == .singleChat{
                if let vc = UIStoryboard.init(name: Storyboards.chat, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.contactInfoViewController) as? ContactInfoViewController {
                    vc.contactJid = profile.jid
                    vc.navigationController?.modalPresentationStyle = .overFullScreen
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
           
        else if profile.profileType == .groupChat{
            if let vc = UIStoryboard.init(name: Storyboards.chat, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.groupInfoViewController) as? GroupInfoViewController {
                vc.groupID = profile.jid
                vc.currentGroupName = profile.profileName
                vc.navigationController?.modalPresentationStyle = .overFullScreen
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        profilePopupContainer?.isHidden = true
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
       showHeaderView()
        longPressCount = 0
        isCellLongPressed = false
        selectionCountLabel?.text = String(longPressCount)
        clearSelectedColor()
        deSelectSelectionList()
        selectionRecentChatList = []
        recentChatTableView?.reloadData()
    }

    func deSelectSelectionList() {
        let jids = selectionRecentChatList.compactMap{$0.jid}
        if showArchivedChat == true {
            jids.forEach { jid in
                if let index = getArchiveChat.firstIndex(where: {$0.jid == jid}) {
                    getArchiveChat[index].isSelected = false
                }
            }
        } else if showPrivateChat == true {
            jids.forEach { jid in
                if let index = getPrivateChats.firstIndex(where: {$0.jid == jid}) {
                    getPrivateChats[index].isSelected = false
                }
            }
        } else {
            jids.forEach { jid in
                if let index = getRecentChat.firstIndex(where: {$0.jid == jid}) {
                    getRecentChat[index].isSelected = false
                }
            }
        }
    }

    @IBAction func headerArchiveBackAction(_ sender: UIButton) {
        hideArchiveHeader()
        recentChatTableView?.reloadData()
        emptyMessageView?.isHidden = true
        showOnlyPrivateChatAvailableView(isShow: false)
        getAllChatTags()
    }
    
    @IBAction func viewContact(_ sender: Any) {
        navigateTo(identifier: Identifiers.contactViewController)
    }
    @IBAction func createGroup(_ sender: Any) {
        print("createGroup")
        let values : [String] = !(availableFeatures.isGroupChatEnabled) ? [CreateGroupOptions.web.rawValue] : CreateGroupOptions.allCases.map { $0.rawValue }
        var actions = [(String, UIAlertAction.Style)]()
        values.forEach { title in
            actions.append((title, UIAlertAction.Style.default))
        }
        AppActionSheet.shared.showActionSeet(title : "", message: "",actions: actions , sheetCallBack: { [weak self] didCancelTap, tappedTitle in
            if !didCancelTap {
                switch tappedTitle {
                case CreateGroupOptions.createGroup.rawValue:
                    let contactPermissionStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
                    if contactPermissionStatus == .denied {
                        AppAlert.shared.contactAccess(view: self!,
                                                      title: contactAccessTitle,
                                                      message: contactAccessMessage,
                                                      settingstitle: settings,
                                                      cancelTitle: cancelUppercase)
                        ContactSyncManager.updateContactPermission(isSkipped: false)
                    } else {
                        self?.navigateTo(identifier: Identifiers.createNewGroup)
                    }
                    //                case CreateGroupOptions.broadCastList.rawValue:
                    //                        print(" \(tappedTitle)")
                case CreateGroupOptions.web.rawValue:
                    self?.checkCameraPermission()
                default:
                    print(" \(tappedTitle)")
                }
            } else {
                print("createGroup Cancel")
            }
        })
    }
    
    func checkCameraPermission() {
        AppPermissions.shared.checkCameraPermissionAccess(permissionCallBack: { [weak self] authorizationStatus in
            switch authorizationStatus {
            case .denied:
                AppPermissions.shared.presentSettingsForPermission(permission: .camera, instance: self as Any)
                break
            case .restricted:
                break
            case .authorized:
                executeOnMainThread {
                    self?.navigateTo(identifier: Identifiers.qrCodeScaner)
                }
                break
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        executeOnMainThread {
                            self?.navigateTo(identifier: Identifiers.qrCodeScaner)
                        }
                    } else {
                        print("Denied access to")
                    }
                }
                break
            @unknown default:
                print("Permission failed")
            }
        })
        
    }
    
    
    func navigateTo(identifier : String) {
        let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
        if identifier == Identifiers.contactViewController {
            if navigationController?.viewControllers[0] is ContactViewController {
                return
            } else {
                guard let mainTabBarController = storyboard.instantiateViewController(withIdentifier: identifier) as? ContactViewController else { return }
                mainTabBarController.hideNavigationbar = true
                mainTabBarController.replyMessageObj = replyMessageObj
                mainTabBarController.replyJid = replyJid
                mainTabBarController.messageTxt = messageTxt
                mainTabBarController.replyTagDelegate = self
                self.navigationController?.pushViewController(mainTabBarController, animated: true)
            }
        } else if identifier == Identifiers.createNewGroup {
            guard let mainTabBarController = storyboard.instantiateViewController(withIdentifier: identifier) as? NewGroupViewController else { return }
            mainTabBarController.groupCreationDeletgate = self
            self.navigationController?.pushViewController(mainTabBarController, animated: true)
        } else if identifier == Identifiers.qrCodeScaner {
            guard let qrCodeScanner = storyboard.instantiateViewController(withIdentifier: identifier) as? QRCodeScanner else { return }
            self.navigationController?.pushViewController(qrCodeScanner, animated: true)
        }
    }
    
    @IBAction func deleteRecentChatButtonTapped(_ sender: Any) {
        let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: Identifiers.deleteChatAlert) as? DeleteAlertViewController
        controller?.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        let current = UIApplication.shared.keyWindow?.getTopViewController()
        if let deleteAlertViewController = controller {
            current?.present(deleteAlertViewController, animated: false, completion: { [weak self] in
                if self?.selectionRecentChatList.count == 1 {
                    let selectedProfile = self?.selectionRecentChatList.first
                    let name = getUserName(jid: selectedProfile?.jid ?? "", name: selectedProfile?.profileName ?? "", nickName: selectedProfile?.nickName ?? "", contactType: selectedProfile?.isItSavedContact ?? false ? .live : .unknown)
                    let messages = "Delete chat with \"\(name)\"?"
                    controller?.deleteDecriptionLabel?.text = messages
                } else {
                    controller?.deleteDecriptionLabel?.text = "Delete \(self?.selectionRecentChatList.count ?? 0) selected chats?"
                }
                controller?.cancelButton?.addTarget(self, action: #selector(self?.cancelAction(_:)), for: .touchUpInside)
                controller?.deleteButton?.addTarget(self, action: #selector(self?.deleteAction(_:)), for: .touchUpInside)
                controller?.contentStackView?.layer.cornerRadius = 10.0
            })
        }
    }
    
    @objc func deleteAction(_ sender: UIButton) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [weak self] in
            self?.dismiss(animated: true) {
                self?.recentChatViewModel?.deleteRecentChats(jids: self?.selectionRecentChatList.compactMap{$0.jid} ?? [], completionHandler: { isSuccess, error, data in
                    if isSuccess {
                        var flydata = data
//                        if let jid = flydata.getData() as? String, let index = self?.getRecentChat.firstIndex(where: {$0.jid == jid}) {
//                            DispatchQueue.main.async {
//                                self?.getRecentChat.remove(at: index)
//                                self?.recentChatTableView?.reloadData()
//                                self?.getOverallUnreadCount()
//                            }
//                        }
                    }
                })
                let jids = self?.selectionRecentChatList.compactMap{$0.jid} ?? []
                if self?.showArchivedChat == true {
                    jids.forEach { jid in
                        self?.getArchiveChat.removeAll(where: { recent in
                            return recent.jid == jid
                        })
                    }
                } else if self?.showPrivateChat == true {
                    jids.forEach { jid in
                        self?.getPrivateChats.removeAll(where: { recent in
                            return recent.jid == jid
                        })
                    }
                } else {
                    jids.forEach { jid in
                        self?.getRecentChat.removeAll(where: { recent in
                            return recent.jid == jid
                        })
                    }
                }
                self?.getOverallUnreadCount()
                self?.updateChatTagsUserList(jids: self?.selectionRecentChatList.compactMap{$0.jid} ?? [])
                self?.clearSelectedColor()
                self?.showHideEmptyMessage()
                self?.longPressCount = 0
                self?.selectionCountLabel?.isHidden = true
                self?.showHeaderView()
                self?.isCellLongPressed = false
                if self?.getArchiveChat.count == 0 && !(self?.showPrivateChat ?? false) {
                    self?.hideArchiveHeader()
                }
                self?.recentChatTableView?.reloadData()
                self?.selectionRecentChatList = []
            }
        })
    }

    @IBAction func messageReadUnReadAction(_ sender: UIButton) {

        let isRead = isChatRead()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [weak self] in
            self?.dismiss(animated: true) {
                if isRead && !NetworkReachability.shared.isConnected {
                    AppAlert.shared.showToast(message: ErrorMessage.noInternet)
                } else {
                    self?.selectionRecentChatList.forEach { chat in
                        self?.recentChatViewModel?.getChatReadUnread(jids: [chat.jid], isRead: isRead, fullMarkAsRead: true, completionHandler: { isSuccess in
                        })
                        FlyMessenger.shared.deleteUnreadMessageSeparatorOfAConversation(jid: chat.jid)
                    }
                    let jids = self?.selectionRecentChatList.compactMap{$0.jid} ?? []
                    if self?.showArchivedChat == true {
                        jids.forEach { jid in
                            if let index = self?.getArchiveChat.firstIndex(where: {$0.jid == jid}) {
                                if let recent = ChatManager.getRecentChatOf(jid: jid) {
                                    self?.getArchiveChat[index] = recent
                                }
                            }
                        }
                    } else if self?.showPrivateChat == true {
                        jids.forEach { jid in
                            if let index = self?.getPrivateChats.firstIndex(where: {$0.jid == jid}) {
                                if let recent = ChatManager.getRecentChatOf(jid: jid) {
                                    self?.getPrivateChats[index] = recent
                                }
                            }
                        }
                    } else {
                        for jid in jids {
                            if let index = self?.getRecentChat.firstIndex(where: {$0.jid == jid}) {
                                if let recent = ChatManager.getRecentChatOf(jid: jid) {
                                    self?.getRecentChat[index] = recent
                                }
                            }
                        }
                    }
                    AppAlert.shared.showToast(message: "Chat\(self?.selectionRecentChatList.count ?? 0 > 1 ? "s" : "") marked as \(isRead ? "read" : "unread")")
                    self?.longPressCount = 0
                    self?.selectionCountLabel?.isHidden = true
                    self?.showHeaderView()
                    self?.isCellLongPressed = false
                    self?.selectionRecentChatList = []
                    self?.recentChatTableView?.reloadData()
                }
            }
        })

    }

    //Get status whether is read or unread
    func isChatRead() -> Bool {
        for chat in selectionRecentChatList {
            if chat.isConversationUnRead == true {
                return true
            }
        }
        return false
    }

    //Update read/unread icon
    func updateChatReadIcon() {
        readUnreadButton.setImage(isChatRead() ? UIImage(named: "messageRead") : UIImage(named: "messageUnread"), for: .normal)
    }
    

    //Recent chat Pin/Unpin Action
    @IBAction func pinChatAction(_ sender: UIButton) {
        var pinChatList = [RecentChat]()
        let isPin = isPin()
        for chat in self.selectionRecentChatList {
            if isPin {
                if chat.isChatPinned == false {
                    pinChatList.append(chat)
                }
            } else {
                pinChatList.append(chat)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [weak self] in
            self?.dismiss(animated: true) {
                //FlyDefaults.maximumRecentChatPin
                if (ChatManager.recentChatPinnedCount() > 3 || pinChatList.count > 3 || (ChatManager.recentChatPinnedCount() + pinChatList.count) > 3) && isPin {
                    AppAlert.shared.showToast(message: "You can only pin upto 3 chats")
                } else {
                    pinChatList.forEach { pinRecentChat in
                        self?.recentChatViewModel?.getPinChat(jid: pinRecentChat.jid, isPin: isPin, completionHandler: { isSuccess in
                        })
                    }
                    AppAlert.shared.showToast(message: "Chat\(pinChatList.count > 1 ? "s" : "") \(isPin ? "pinned" : "unpinned")")
                }
                self?.longPressCount = 0
                self?.selectionCountLabel?.isHidden = true
                self?.showHeaderView()
                self?.isCellLongPressed = false
                self?.selectionRecentChatList = []
                self?.getRecentChatList()
                self?.recentChatTableView?.reloadData()
            }
        })
    }

    //Get status whether is Pin or Unpin
    func isPin() -> Bool {
        for chat in selectionRecentChatList {
            if chat.isChatPinned == false {
                return true
            }
        }
        return false
    }

    //Update Pin icon
    func updatePinIcon() {
        pinChatButton.setImage(isPin() ? UIImage(named: "push-pin")?.withHorizontallyFlippedOrientation() : UIImage(named: "push-unpin")?.withHorizontallyFlippedOrientation(), for: .normal)
    }

    @IBAction func muteChatAction(_ sender: UIButton) {
        let isMute = isMute()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [weak self] in
            self?.dismiss(animated: true) {
                self?.selectionRecentChatList.forEach { pinRecentChat in
                    self?.recentChatViewModel?.getMuteChat(jid: pinRecentChat.jid, isMute: isMute, completionHandler: { isSuccess in
                    })
                }
                let jids = self?.selectionRecentChatList.compactMap{$0.jid} ?? []
                if self?.showArchivedChat == true {
                    jids.forEach { jid in
                        if let index = self?.getArchiveChat.firstIndex(where: {$0.jid == jid}) {
                            self?.getArchiveChat[index].isMuted = isMute
                            self?.getArchiveChat[index].isSelected = false
                        }
                    }
                } else if self?.showPrivateChat == true {
                    jids.forEach { jid in
                        if let index = self?.getPrivateChats.firstIndex(where: {$0.jid == jid}) {
                            self?.getPrivateChats[index].isMuted = isMute
                            self?.getPrivateChats[index].isSelected = false
                        }
                    }
                } else {
                    jids.forEach { jid in
                        if let index = self?.getRecentChat.firstIndex(where: {$0.jid == jid}) {
                            self?.getRecentChat[index].isMuted = isMute
                            self?.getRecentChat[index].isSelected = false
                        }
                    }
                }
                self?.longPressCount = 0
                self?.selectionCountLabel?.isHidden = true
                self?.showHeaderView()
                self?.isCellLongPressed = false
                self?.selectionRecentChatList = []
                self?.recentChatTableView?.reloadData()
            }
        })
    }

    //Get status whether is mute or Unmute
    func isMute() -> Bool {
        return selectionRecentChatList.filter {$0.isMuted == false }.count > 0 ? true : false
    }

    //Update mute icon
    func updateMuteIcon() {
        muteChatButton.setImage(isMute() ? UIImage(named: "mute") : UIImage(named: "unmute"), for: .normal)
    }

    //Archive chat Action
    @IBAction func ArchiveChatAction(_ sender: UIButton) {

        if !NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: ErrorMessage.checkYourInternet)
            return
        }

        let isArchive = isArchive()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [weak self] in
        self.dismiss(animated: true) {
//                guard let weakSelf = self else { return }
            self.recentChatViewModel?.getArchiveChat(jids: self.selectionRecentChatList.compactMap { $0.jid } , isArchive: isArchive, completionHandler: { isSuccess, error, data in
                    if isSuccess {
                        print("Archivedata---\(data)")
                        AppAlert.shared.showToast(message: (self.selectionRecentChatList.count ) > 1 ? " \(self.selectionRecentChatList.count) chats are \(isArchive ? "archived" : "unarchived")" : "Chat has been \(isArchive ? "archived" : "unarchived")")
                    }
                })
                ChatManager.getArchivedChatList { [weak self] isSuccess, error, data in
                    if isSuccess {
                        print("Archivedata1---\(data)")
                        self?.getArchiveChat = data["data"] as? [RecentChat] ?? []
                        if self?.getArchiveChat.count == 0 {
                            self?.hideArchiveHeader()
                        }
                        executeOnMainThread {
                            self?.recentChatTableView?.reloadData()
                        }
                    }
                }

//                if isArchive && weakSelf.showArchivedChat == false {
//                    (self?.selectionRecentChatList.compactMap { $0.jid } ?? []).forEach { jid in
//                        if let index = weakSelf.getRecentChat.firstIndex(where: { pd in pd.jid == jid }) {
//                            weakSelf.getRecentChat.remove(at: index)
//                            weakSelf.getAllRecentChat = weakSelf.getRecentChat
//                        }
//                    }
//                }

                self.showHideEmptyMessage()
                self.getOverallUnreadCount()
                self.longPressCount = 0
                self.selectionCountLabel?.isHidden = true
                self.showHeaderView()
                self.isCellLongPressed = false
                self.selectionRecentChatList = []
                //self?.getRecentChatList()
                self.recentChatTableView?.reloadData()
            }
//        })
    }

    @objc func cancelAction(_ sender: UIButton) {
        self.dismiss(animated: false, completion: nil)
    }
}

extension RecentChatViewController : UITableViewDataSource ,UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if isSearchEnabled == true {
            return 3
        } else if getRecentChat.count > 0 && getArchiveChat.count > 0 && !showArchivedChat && !showPrivateChat {
            return 2
        } else if getRecentChat.count > 0 || getArchiveChat.count > 0 || showArchivedChat || getPrivateChats.count > 0 || showPrivateChat {
            return 1
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch isSearchEnabled {
        case true:
                switch section {
                case 0:
                    return getRecentChat.count
                case 1:
                    return filteredContactList.count
                case 2:
                    return searchedMessages.count
                default:
                    break
                }
        case false:
            if getRecentChat.count > 0 && getArchiveChat.count > 0 && showArchivedChat == false && showPrivateChat == false {
                switch section {
                case ChatManager.isArchivedSettingsEnabled() ? 0 : 1:
                    return 1
                case ChatManager.isArchivedSettingsEnabled() ? 1 : 0:
                    return getRecentChat.count
                default:
                    break
                }
            } else if getArchiveChat.count > 0 && showArchivedChat == false && showPrivateChat == false {
                return 1
            } else if getArchiveChat.count > 0 && showArchivedChat == true {
                return getArchiveChat.count
            } else if getPrivateChats.count > 0 && showPrivateChat == true {
                return getPrivateChats.count
            } else {
                return getRecentChat.count
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView,heightForHeaderInSection section: Int) -> CGFloat {
        if isSearchEnabled == true {
            switch section {
            case 0:
                return getRecentChat.count > 0 ? 50 : 0
            case 1:
                return filteredContactList.count > 0 ? 50 : 0
            case 2:
                return searchedMessages.count > 0 ? 50 : 0
            default:
                break
            }
        } else {
            return 0
        }
        return 0
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isSearchEnabled == true {
            switch section {
            case 0:
                return getRecentChat.count > 0 ? chatTitle.appending(" (\(getRecentChat.count))") : (filteredContactList.count > 0) ? contactTitle.appending(" (\(filteredContactList.count))") : ""
            case 1:
                return filteredContactList.count > 0 ? contactTitle.appending(" (\(filteredContactList.count))") : ""
            case 2:
                return messageTitle.appending(" (\(searchedMessages.count))")
            default:
                break
            }
        } else {
            return section == 0 ? chatTitle.appending(" (\(getRecentChat.count))") : contactTitle.appending(" (\(filteredContactList.count))")
        }
        return ""
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: RecentChatTableViewCell!
        switch isSearchEnabled {
        case false:
            if getRecentChat.count > 0 && getArchiveChat.count > 0 && showArchivedChat == false && showPrivateChat == false {
                switch indexPath.section {
                case ChatManager.isArchivedSettingsEnabled() ? 0 : 1:
                    let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.ArchiveChatTableViewCell, for: indexPath) as! ArchiveChatTableViewCell
                    let count = ChatManager.isArchivedSettingsEnabled() ? getArchiveChat.filter { chat in return chat.unreadMessageCount > 0 ? true : false }.count : getArchiveChat.count
                    cell.chatCountLabel.isHidden = count == 0 ? true : false
                    cell.chatCountLabel.text = String(count)
                    return cell
                case ChatManager.isArchivedSettingsEnabled() ? 1 : 0:
                    cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.recentChatCell, for: indexPath) as? RecentChatTableViewCell
                    if getRecentChat.count > indexPath.row {
                        let recentChat = getRecentChat[indexPath.row]
                        let name = getUserName(jid: recentChat.jid, name: recentChat.profileName, nickName: recentChat.nickName, contactType: recentChat.isItSavedContact ? .live : .unknown)
                        let color = getColor(userName: name)
                        cell.setTextColorWhileSearch(searchText: searchBar?.text ?? "", recentChat: recentChat)
                        let chatMessage = getMessages(messageId: recentChat.lastMessageId)
                        cell.setLastContentTextColor(searchText: searchBar?.text ?? "", recentChat: recentChat, message: chatMessage)
                        let getGroupSenderName = ChatUtils.getGroupSenderName(messsage: chatMessage)
                        cell.setRecentChatMessage(recentChatMessage: recentChat, color: color, chatMessage: chatMessage, senderName: getGroupSenderName, fromArchive: showArchivedChat)
                        cell.setLastMessageContent(recentChatMessage: recentChat, chatMessage: chatMessage)
                        cell.archivedStatusLabel.isHidden = true
                        cell.profileImageButton?.isUserInteractionEnabled = true
                        cell.profileImageButton?.tag = indexPath.row
                        cell.profileImageButton?.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
                        cell.setChatTimeTextColor(lastMessageTime: recentChat.lastMessageTime, unreadCount: recentChat.unreadMessageCount)
                        return cell
                    }
                default:
                    break
                }
            } else if getArchiveChat.count > 0 && showArchivedChat == false && showPrivateChat == false {
                let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.ArchiveChatTableViewCell, for: indexPath) as! ArchiveChatTableViewCell
                let count = ChatManager.isArchivedSettingsEnabled() ? getArchiveChat.reduce(0, {$0 + $1.unreadMessageCount}) : getArchiveChat.count
                cell.chatCountLabel.isHidden = count == 0 ? true : false
                cell.chatCountLabel.text = String(count)
                return cell
            } else if getArchiveChat.count > 0 && showArchivedChat == true {
                cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.recentChatCell, for: indexPath) as? RecentChatTableViewCell
                if getArchiveChat.count > indexPath.row {
                    let recentChat = getArchiveChat[indexPath.row]
                    let name = getUserName(jid: recentChat.jid, name: recentChat.profileName, nickName: recentChat.nickName, contactType: recentChat.isItSavedContact ? .live : .unknown)
                    let color = getColor(userName: name)
                    cell.setTextColorWhileSearch(searchText: searchBar?.text ?? "", recentChat: recentChat)
                    let chatMessage = getMessages(messageId: recentChat.lastMessageId)
                    cell.setLastContentTextColor(searchText: searchBar?.text ?? "", recentChat: recentChat, message: chatMessage)
                    let getGroupSenderName = ChatUtils.getGroupSenderName(messsage: chatMessage)
                    cell.setRecentChatMessage(recentChatMessage: recentChat, color: color, chatMessage: chatMessage, senderName: getGroupSenderName, fromArchive: showArchivedChat)
                    cell.setLastMessageContent(recentChatMessage: recentChat, chatMessage: chatMessage)
                    cell.archivedStatusLabel.isHidden = true
                    cell.profileImageButton?.tag = indexPath.row
                    cell.profileImageButton?.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
                    cell.setChatTimeTextColor(lastMessageTime: recentChat.lastMessageTime, unreadCount: recentChat.unreadMessageCount)
                    return cell
                }
            } else if showPrivateChat == true {
                cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.recentChatCell, for: indexPath) as? RecentChatTableViewCell
                if getPrivateChats.count > indexPath.row {
                    let recentChat = getPrivateChats[indexPath.row]
                    let name = getUserName(jid: recentChat.jid, name: recentChat.profileName, nickName: recentChat.nickName, contactType: recentChat.isItSavedContact ? .live : .unknown)
                    let color = getColor(userName: name)
                    cell.setTextColorWhileSearch(searchText: searchBar?.text ?? "", recentChat: recentChat)
                    let chatMessage = getMessages(messageId: recentChat.lastMessageId)
                    cell.setLastContentTextColor(searchText: searchBar?.text ?? "", recentChat: recentChat, message: chatMessage)
                    let getGroupSenderName = ChatUtils.getGroupSenderName(messsage: chatMessage)
                    cell.setRecentChatMessage(recentChatMessage: recentChat, color: color, chatMessage: chatMessage, senderName: getGroupSenderName, fromArchive: showArchivedChat)
                    cell.setLastMessageContent(recentChatMessage: recentChat, chatMessage: chatMessage)
                    cell.archivedStatusLabel.isHidden = true
                    cell.profileImageButton?.tag = indexPath.row
                    cell.profileImageButton?.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
                    cell.setChatTimeTextColor(lastMessageTime: recentChat.lastMessageTime, unreadCount: recentChat.unreadMessageCount)
                    return cell
                }
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.recentChatCell, for: indexPath) as? RecentChatTableViewCell
                if getRecentChat.count > indexPath.row {
                    let recentChat = getRecentChat[indexPath.row]
                    let name = getUserName(jid: recentChat.jid, name: recentChat.profileName, nickName: recentChat.nickName, contactType: recentChat.isItSavedContact ? .live : .unknown)
                    let color = getColor(userName: name)
                    cell.setTextColorWhileSearch(searchText: searchBar?.text ?? "", recentChat: recentChat)
                    let chatMessage = getMessages(messageId: recentChat.lastMessageId)
                    cell.setLastContentTextColor(searchText: searchBar?.text ?? "", recentChat: recentChat, message: chatMessage)
                    let getGroupSenderName = ChatUtils.getGroupSenderName(messsage: chatMessage)
                    cell.setRecentChatMessage(recentChatMessage: recentChat, color: color, chatMessage: chatMessage, senderName: getGroupSenderName, fromArchive: showArchivedChat)
                    cell.setLastMessageContent(recentChatMessage: recentChat, chatMessage: chatMessage)
                    cell.archivedStatusLabel.isHidden = true
                    cell.profileImageButton?.isUserInteractionEnabled = true
                    cell.profileImageButton?.tag = indexPath.row
                    cell.profileImageButton?.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
                    cell.setChatTimeTextColor(lastMessageTime: recentChat.lastMessageTime, unreadCount: recentChat.unreadMessageCount)
                    return cell
                }
            }
        case true:
            switch indexPath.section {
            case 0:
                cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.recentChatCell, for: indexPath) as? RecentChatTableViewCell
                if getRecentChat.count > indexPath.row {
                    let recentChat = getRecentChat[indexPath.row]
                    let name = getUserName(jid: recentChat.jid, name: recentChat.profileName, nickName: recentChat.nickName, contactType: recentChat.isItSavedContact ? .live : .unknown)
                    let color = getColor(userName: name)
                    cell.setTextColorWhileSearch(searchText: searchBar?.text ?? "", recentChat: recentChat)
                    let chatMessage = getMessages(messageId: recentChat.lastMessageId)
                    cell.setLastContentTextColor(searchText: searchBar?.text ?? "", recentChat: recentChat, message: chatMessage)
                    let getGroupSenderName = ChatUtils.getGroupSenderName(messsage: chatMessage)
                    cell.setRecentChatMessage(recentChatMessage: recentChat, color: color, chatMessage: chatMessage, senderName: getGroupSenderName, fromArchive: showArchivedChat)
                    cell.setLastMessageContent(recentChatMessage: recentChat, chatMessage: chatMessage)
                    cell.archivedStatusLabel.isHidden = !recentChat.isChatArchived
                    cell.profileImageButton?.isUserInteractionEnabled = false
                    cell.profileImageButton?.tag = indexPath.row
                    if recentChat.isPrivateChat {
                        cell.userMessageLabel?.text = ""
                    }
                   // cell.profileImageButton?.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
                    cell.setChatTimeTextColor(lastMessageTime: recentChat.lastMessageTime, unreadCount: recentChat.unreadMessageCount)
                    return cell
                } else {
                    if filteredContactList.count > indexPath.row {
                        let profile = filteredContactList[indexPath.row]
                        let name = getUserName(jid: profile.jid,name: profile.name, nickName: profile.nickName, contactType: profile.contactType)
                        let recentChat =  RecentChat()
                        recentChat.profileName = profile.name
                        recentChat.nickName = profile.nickName
                        recentChat.lastMessageContent = profile.status
                        recentChat.isItSavedContact = profile.contactType == .live ? true : false
                        recentChat.jid = profile.jid
                        let color = getColor(userName: name)
                        cell.pinImageView.isHidden = true
                        cell.muteImageView.isHidden = true
                        cell.setTextColorWhileSearch(searchText: searchBar?.text ?? "", recentChat: recentChat)
                        cell.setLastContentTextColor(searchText: "", recentChat: recentChat)
                        cell.profileImageButton?.isUserInteractionEnabled = false
                        cell.profileImageButton?.tag = indexPath.row
                       // cell.profileImageButton?.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
                        cell.setContactInfo(recentChat: recentChat, color: color)
                        return cell ?? UITableViewCell()
                    }
                }
            case 1:
                cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.recentChatCell, for: indexPath) as? RecentChatTableViewCell
            if unreadMessageChatList.count > indexPath.row {
                let recentChat = unreadMessageChatList[indexPath.row]
                let name = getUserName(jid: recentChat.jid, name: recentChat.profileName, nickName: recentChat.nickName, contactType: recentChat.isItSavedContact ? .live : .unknown)
                let color = getColor(userName: name)
                cell.setTextColorWhileSearch(searchText: "", recentChat: recentChat)
                let chatMessage = getMessages(messageId: recentChat.lastMessageId)
                cell.setLastContentTextColor(searchText: searchBar?.text ?? "", recentChat: recentChat, message: chatMessage)
                let getGroupSenderName = ChatUtils.getGroupSenderName(messsage: chatMessage)
                cell.archivedStatusLabel.isHidden = true
                cell.setRecentChatMessage(recentChatMessage: recentChat, color: color, chatMessage: chatMessage, senderName: getGroupSenderName, fromArchive: showArchivedChat)
                cell.setLastMessageContent(recentChatMessage: recentChat, chatMessage: chatMessage)
                cell.muteImageView.isHidden = true
                cell.pinImageView.isHidden = true
                cell.profileImageButton?.isUserInteractionEnabled = false
                cell.profileImageButton?.tag = indexPath.row
              //  cell.profileImageButton?.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
                cell.setChatTimeTextColor(lastMessageTime: recentChat.lastMessageTime, unreadCount: recentChat.unreadMessageCount)
                return cell
            } else {
                if filteredContactList.count > indexPath.row {
                    let profile = filteredContactList[indexPath.row]
                    let name = getUserName(jid: profile.jid, name: profile.name, nickName: profile.nickName, contactType: profile.contactType)
                    let recentChat =  RecentChat()
                    recentChat.profileName = profile.name
                    recentChat.nickName = profile.nickName
                    recentChat.profileImage = profile.image
                    recentChat.lastMessageContent = profile.status
                    recentChat.isItSavedContact = profile.contactType == .live ? true : false
                    recentChat.jid = profile.jid
                    recentChat.isDeletedUser = profile.contactType == .deleted
                    let color = getColor(userName: name)
                    cell.archivedStatusLabel.isHidden = true
                    cell.setTextColorWhileSearch(searchText: searchBar?.text ?? "", recentChat: recentChat)
                    cell.setLastContentTextColor(searchText: "", recentChat: recentChat)
                    cell.muteImageView.isHidden = true
                    cell.pinImageView.isHidden = true
                    cell.profileImageButton?.isUserInteractionEnabled = false
                    cell.profileImageButton?.tag = indexPath.row
                   // cell.profileImageButton?.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
                    cell.setContactInfo(recentChat: recentChat, color: color)
                    return cell ?? UITableViewCell()
                }
            }
            case 2:
                cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.recentChatCell, for: indexPath) as? RecentChatTableViewCell
                if searchedMessages.count > indexPath.row {
                    let searchMessage = searchedMessages[indexPath.row]
                    if let chatMessage = ChatManager.getMessageOfId(messageId: searchMessage.messageId) {
                        if let recentChat = ChatManager.getRechtChat(jid: searchMessage.chatUserJid) {
                            
                            recentChat.lastMessageId = chatMessage.messageId
                            recentChat.lastMessageStatus = chatMessage.messageStatus
                            recentChat.lastMessageContent = chatMessage.messageTextContent
                            recentChat.lastMessageTime = chatMessage.messageSentTime
                            recentChat.lastMessageType = chatMessage.messageType
                            recentChat.isLastMessageSentByMe = chatMessage.isMessageSentByMe
                            
                            let name = getUserName(jid: recentChat.jid, name: recentChat.profileName, nickName: recentChat.nickName, contactType: recentChat.isItSavedContact ? .live : .unknown)
                            let color = getColor(userName: name)
                            cell.setTextColorWhileSearch(searchText: searchBar?.text ?? "", recentChat: recentChat)
                            cell.archivedStatusLabel.isHidden = true
                            let chatMessage = getMessages(messageId: recentChat.lastMessageId)
                            let getGroupSenderName = ChatUtils.getGroupSenderName(messsage: chatMessage)
                            cell.setRecentChatMessage(recentChatMessage: recentChat, color: color, chatMessage: chatMessage, senderName: getGroupSenderName, fromArchive: showArchivedChat, forSearch: true)
                            cell.setLastMessageContent(recentChatMessage: recentChat, chatMessage: chatMessage)
                            let caption = chatMessage.messageType == .meet ? chatMessage.meetChatMessage?.link ?? "" :  (chatMessage.mediaChatMessage?.mediaCaptionText ?? "")
                            cell.setLastContentTextColor(searchText: searchBar?.text ?? "", recentChat: recentChat, caption: caption, searchMessage: chatMessage)
                            cell.profileImageButton?.isHidden = true
                            cell.setChatTimeTextColor(lastMessageTime: recentChat.lastMessageTime, unreadCount: recentChat.unreadMessageCount)
                            cell.countLabel?.isHidden = true
                            cell.countView?.isHidden = true
                        }
                    }
                }
                return cell ?? UITableViewCell()
            default:
                break
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch isSearchEnabled {
        case true:
            if indexPath.section == 1 {
                if filteredContactList.count >= indexPath.row{
                    ContactManager.shared.saveUser(profileDetails: filteredContactList[indexPath.row])
                    openContactChat(index: indexPath)
                }
            }  else if indexPath.section == 2 {
                if searchedMessages.count >= indexPath.row {
                    openContactChat(index: indexPath, searchMessageId: searchedMessages[indexPath.row].messageId)
                }
            } else {
                if indexPath.row < getRecentChat.count {
                    getRecentChat[indexPath.row].unreadMessageCount = 0
                    executeOnMainThread { [weak self] in
                        self?.recentChatTableView?.reloadRows(at: [indexPath], with: .none)
                        self?.getOverallUnreadCount()
                    }
                }
                didSelectRow(tableView: tableView, indexPath: indexPath)
            }
        case false:
            switch showArchivedChat {
            case true:
                didSelectRow(tableView: tableView, indexPath: indexPath)
            case false:
                if showPrivateChat {
                    didSelectRow(tableView: tableView, indexPath: indexPath)
                } else {
                    if getRecentChat.count > 0 && getArchiveChat.count > 0 && showArchivedChat == false {
                        switch indexPath.section {
                        case ChatManager.isArchivedSettingsEnabled() ? 0 : 1:
                            if isCellLongPressed == false {
                                updateArchiveChatView()
                                recentChatTableView?.reloadData()
                            }
                        case ChatManager.isArchivedSettingsEnabled() ? 1 : 0:
                            didSelectRow(tableView: tableView, indexPath: indexPath)
                        default:
                            break
                        }
                    } else if getArchiveChat.count > 0 {
                        updateArchiveChatView()
                        recentChatTableView?.reloadData()
                    } else {
                        didSelectRow(tableView: tableView, indexPath: indexPath)
                    }
                }
            }
        }
    }

    func didSelectRow(tableView: UITableView, indexPath: IndexPath) {
        if( isCellLongPressed ?? false) {
            if let cell = tableView.cellForRow(at: indexPath) as? RecentChatTableViewCell {
                if( longPressCount >= 1) {
                    if selectionRecentChatList.filter({$0.jid == (showArchivedChat ? getArchiveChat[indexPath.row].jid : showPrivateChat ? getPrivateChats[indexPath.row].jid : getRecentChat[indexPath.row].jid) }).count == 0 {
                        cell.contentView.backgroundColor = Color.recentChatSelectionColor
                        longPressCount += 1
                        if showArchivedChat {
                            getArchiveChat[indexPath.row].isSelected = !getArchiveChat[indexPath.row].isSelected
                            selectionRecentChatList.insert(getArchiveChat[indexPath.row], at: 0)
                        } else if showPrivateChat {
                            getPrivateChats[indexPath.row].isSelected = !getPrivateChats[indexPath.row].isSelected
                            selectionRecentChatList.insert(getPrivateChats[indexPath.row], at: 0)
                        } else {
                            getRecentChat[indexPath.row].isSelected = !getRecentChat[indexPath.row].isSelected
                            selectionRecentChatList.insert(getRecentChat[indexPath.row], at: 0)
                        }
                        selectionCountLabel?.text = String(longPressCount)
                        updatePinIcon()
                        updateChatReadIcon()
                        updateMuteIcon()
                        updateArchiveIcon()
                    } else {
                        recentChatTableView?.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)
                    }
                } else {
                    hideMultipleSelectionView()
                }
            }
        }
        if !(isCellLongPressed ?? false) {
            if showArchivedChat && (!getArchiveChat.isEmpty && getArchiveChat[indexPath.row].profileType == .groupChat && getArchiveChat[indexPath.row].isBlockedByAdmin) {
                showGroupBlockedView()
            } else if showArchivedChat == false && showPrivateChat == false && (!getRecentChat.isEmpty && getRecentChat[indexPath.row].profileType == .groupChat && getRecentChat[indexPath.row].isBlockedByAdmin) {
                showGroupBlockedView()
            } else if showPrivateChat && (!getPrivateChats.isEmpty && getPrivateChats[indexPath.row].profileType == .groupChat && getPrivateChats[indexPath.row].isBlockedByAdmin) {
                showGroupBlockedView()
            } else if isSearchEnabled == true {
                if !ENABLE_CONTACT_SYNC {
                    if filteredContactList.count != 0 {
                        if filteredContactList.count > indexPath.row{
                            ContactManager.shared.saveUser(profileDetails: filteredContactList[indexPath.row])
                        }
                    }
                }
                openContactChat(index: indexPath)
            } else {
                openChat(index: indexPath.row)
            }
        }
        if selectionRecentChatList.count == 0 {
            hideMultipleSelectionView()
        }
        showHideDeleteButton()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if( isCellLongPressed ?? false) {
            if let cell = tableView.cellForRow(at: indexPath) as? RecentChatTableViewCell {
                if( longPressCount >= 1) {
                    let recentChatJid = showArchivedChat ? getArchiveChat[indexPath.row].jid : showPrivateChat ? getPrivateChats[indexPath.row].jid : getRecentChat[indexPath.row].jid
                        if selectionRecentChatList.filter({$0.jid == recentChatJid}).count > 0 {
                            selectionRecentChatList.enumerated().forEach { (index,selectedRecentChat) in
                                if recentChatJid == selectedRecentChat.jid {
                                    cell.contentView.backgroundColor = .clear
                                    longPressCount -= 1
                                    if showArchivedChat {
                                        getArchiveChat[indexPath.row].isSelected = !getArchiveChat[indexPath.row].isSelected
                                        selectionRecentChatList.remove(at: index)
                                    } else if showPrivateChat {
                                        getPrivateChats[indexPath.row].isSelected = !getPrivateChats[indexPath.row].isSelected
                                        selectionRecentChatList.remove(at: index)
                                    } else {
                                        getRecentChat[indexPath.row].isSelected = !getRecentChat[indexPath.row].isSelected
                                        selectionRecentChatList.remove(at: index)
                                    }
                                    selectionCountLabel?.text = String(longPressCount)
                                    if selectionRecentChatList.count == 0 {
                                        hideMultipleSelectionView()
                                    }
                                    updatePinIcon()
                                    updateChatReadIcon()
                                    updateMuteIcon()
                                    updateArchiveIcon()
                                    return
                                }
                            }
                        }
                } else {
                    hideMultipleSelectionView()
                }
            }
        }
        if selectionRecentChatList.count == 0 {
          clearSelectedColor()
        }
        showHideDeleteButton()
    }
    
    private func hideMultipleSelectionView() {
        longPressCount = 0
        selectionCountLabel?.text = String(longPressCount)
        selectionCountLabel?.isHidden = true
       showHeaderView()
        isCellLongPressed = false
        selectionRecentChatList = []
    }
    
    private func hideHeaderView() {
        multipleSelectionView?.isHidden = false
        headerView?.isHidden = true
    }
    
    private func showHeaderView() {
        multipleSelectionView?.isHidden = true
        headerView?.isHidden = false
    }
    
    private func clearSelectedColor() {
        getRecentChat.enumerated().forEach { (index, element) in
            if let cell =  recentChatTableView?.cellForRow(at: IndexPath(row: index, section: 0)) as? RecentChatTableViewCell {
                getRecentChat[index].isSelected = false
                cell.contentView.backgroundColor = .clear
            }
        }
    }

    func openChat(jid: String) {
        if AppUtils.getMyJid() != jid {
            if let profile = recentChatViewModel?.getRecentChat(jid: jid) {
                let vc = UIStoryboard.init(name: Storyboards.chat, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.chatViewParentController) as? ChatViewParentController
                let profileDetails = ProfileDetails(jid: profile.jid)
                profileDetails.name = profile.profileName
                profileDetails.nickName = profile.nickName
                profileDetails.image = profile.profileImage ?? ""
                profileDetails.profileChatType = profile.profileType
                if profile.isDeletedUser{
                    profileDetails.contactType = .deleted
                }else{
                    profileDetails.contactType = profile.isItSavedContact == true ? .live : .unknown
                }
                profileDetails.isBlockedByAdmin = profile.isBlockedByAdmin
                vc?.getProfileDetails = profileDetails
                let color = getColor(userName: profile.profileName)
                vc?.contactColor = color
                vc?.replyMessagesDelegate = self
                vc?.replyMessageObj = replyMessageObj
                vc?.replyJid = replyJid
                vc?.ismarkMessagesAsRead = true
                vc?.navigationController?.modalPresentationStyle = .overFullScreen
                self.navigationController?.pushViewController(vc!, animated: true)
            }
        }
    }
    
    func openChat(index: Int) {
        let profile = showArchivedChat ? getArchiveChat[index] : showPrivateChat ? getPrivateChats[index] : getRecentChat[index]
        let vc = UIStoryboard(name: Storyboards.chat, bundle: nil).instantiateViewController(withIdentifier: Identifiers.chatViewParentController) as? ChatViewParentController
        //UIStoryboard.init(name: Storyboards.chat, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.chatViewParentController) as? ChatViewParentController
            let profileDetails = ProfileDetails(jid: profile.jid)
            profileDetails.name = profile.profileName
            profileDetails.nickName = profile.nickName
            profileDetails.image = profile.profileImage ?? ""
            profileDetails.profileChatType = profile.profileType
            if profile.isDeletedUser{
                profileDetails.contactType = .deleted
            }else{
                profileDetails.contactType = profile.isItSavedContact == true ? .live : .unknown
            }
            profileDetails.isBlockedByAdmin = profile.isBlockedByAdmin
            vc?.getProfileDetails = profileDetails
            let color = getColor(userName: profile.profileName)
            vc?.contactColor = color
            vc?.replyMessagesDelegate = self
            vc?.replyMessageObj = replyMessageObj
            vc?.replyJid = replyJid
            vc?.ismarkMessagesAsRead = true
            vc?.isFromSearchSelect = isSearchEnabled
            vc?.isFromPrivateChat = showPrivateChat
            vc?.navigationController?.modalPresentationStyle = .overFullScreen
        if let viewControllerToPresent = vc {
            self.navigationController?.pushViewController(viewControllerToPresent, animated: true)
        }
            
    }
    func openContactChat(index: IndexPath, searchMessageId: String = "") {
        let vc = UIStoryboard.init(name: Storyboards.chat, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.chatViewParentController) as? ChatViewParentController
        switch index.section {
        case 0:
            if getRecentChat.count > index.row {
                let profile = getRecentChat[index.row]
                let profileDetails = ProfileDetails(jid: profile.jid)
                profileDetails.name = profile.profileName
                profileDetails.nickName = profile.nickName
                profileDetails.image = profile.profileImage ?? ""
                profileDetails.profileChatType = profile.profileType
                profileDetails.isBlockedByAdmin = profile.isBlockedByAdmin
                vc?.getProfileDetails = profileDetails
                vc?.replyMessagesDelegate = self
                vc?.replyMessageObj = replyMessageObj
                vc?.replyJid = replyJid
                let color = getColor(userName: profile.profileName)
                vc?.contactColor = color
            } else {
                let profile = filteredContactList[index.row]
                let profileDetails = ProfileDetails(jid: profile.jid)
                profileDetails.name = profile.name
                profileDetails.nickName = profile.nickName
                profileDetails.isBlockedByAdmin = profile.isBlockedByAdmin
                vc?.getProfileDetails = profileDetails
                let color = getColor(userName: profile.name)
                vc?.replyMessagesDelegate = self
                vc?.replyMessageObj = replyMessageObj
                vc?.replyJid = replyJid
                vc?.contactColor = color
            }
        case 1:
            if unreadMessageChatList.count > index.row {
                let profile = unreadMessageChatList[index.row]
                let profileDetails = ProfileDetails(jid: profile.jid)
                profileDetails.name = profile.profileName
                profileDetails.nickName = profile.nickName
                profileDetails.isBlockedByAdmin = profile.isBlockedByAdmin
                profileDetails.profileChatType = profile.profileType
                vc?.getProfileDetails = profileDetails
                vc?.replyMessagesDelegate = self
                vc?.replyMessageObj = replyMessageObj
                vc?.replyJid = replyJid
                let color = getColor(userName: profile.profileName)
                vc?.contactColor = color
            } else {
                let profile = filteredContactList[index.row]
                let profileDetails = ProfileDetails(jid: profile.jid)
                profileDetails.name = profile.name
                profileDetails.nickName = profile.nickName
                profileDetails.isBlockedByAdmin = profile.isBlockedByAdmin
                profileDetails.image = profile.image
                vc?.getProfileDetails = profileDetails
                let color = getColor(userName: profile.name)
                vc?.replyMessagesDelegate = self
                vc?.replyMessageObj = replyMessageObj
                vc?.replyJid = replyJid
                vc?.contactColor = color
            }
        case 2:
            let searchMessage = searchedMessages[index.row]
            if let profile = ChatManager.getContact(jid: searchMessage.chatUserJid) {
                vc?.getProfileDetails = profile
                let color = getColor(userName: profile.name)
                vc?.contactColor = color
                vc?.replyMessagesDelegate = self
                vc?.replyMessageObj = replyMessageObj
                vc?.replyJid = replyJid
            }
        default:
            break
        }
        vc?.isFromSearchSelect = isSearchEnabled
        vc?.isStarredMessagePage = false
        vc?.searchMessageId = searchMessageId
        vc?.isFromPrivateChat = showPrivateChat
        navigationController?.modalPresentationStyle = .overFullScreen
        navigationController?.pushViewController(vc!, animated: true)
    }
}

// getChatList Method
extension RecentChatViewController {
    
    private func getColor(userName : String) -> UIColor {
        return ChatUtils.getColorForUser(userName: userName)
    }
    
    private func getContactList() {
        contactViewModel?.getContacts(fromServer: false) { [weak self] (contacts, error)  in
                if error != nil {
                    return
                }
            if let weakSelf = self {
                if  let  contactsList = contacts {
                    weakSelf.allContactsList.removeAll()
                    //weakSelf.filteredContactList.removeAll()
                    weakSelf.allContactsList = contactsList
                    weakSelf.allContactsList = weakSelf.allContactsList.sorted { getUserName(jid: $0.jid,name: $0.name, nickName: $0.nickName, contactType: $0.contactType)  < getUserName(jid: $1.jid,name: $1.name, nickName: $1.nickName, contactType: $1.contactType)  }
                    weakSelf.recentChatTableView?.reloadData()
                }
            }
        }
    }
    
    func getRecentChatList(fromAPI: Bool = false) {
        if selectedChatTag?.tagId == AppUtils.getMyJid() || selectedChatTag == nil {
            recentChatListBuilder?.changeLimit(limit:  getAllRecentChat.isEmpty ? 20 : ((getAllRecentChat.count < 20 ? 20 : getAllRecentChat.count)))
            if ENABLE_CHAT_HISTORY && NetStatus.shared.isConnected && !Utility.getBoolFromPreference(key: isRecentChatLoad) {
                self.startLoading(withText: "")
            }
//            DispatchQueue(label: "RecentchatList", qos: .userInteractive).async { [weak self] in
            self.recentChatListBuilder?.loadRecentChatList(completionHandler: {  [weak self] isSuccess, error, data in
                    self?.stopLoading()
                    DispatchQueue.main.async { [weak self] in
                    var result = data
                    if  let weakSelf = self, let recentChatList = result.getData() as? [RecentChat], isSuccess{
                        //weakSelf.isRecentLoadingDone = false
                        if weakSelf.isSearchEnabled == false {
                            weakSelf.clearChatList()
                            weakSelf.getRecentChat = recentChatList
                            weakSelf.getAllRecentChat = recentChatList
                            Utility.saveInPreference(key: isRecentChatLoad, value: true)
                            if ENABLE_CHAT_HISTORY {
                                //checking limit
                                if weakSelf.getRecentChat.count < 20 {
//                                    executeInBackground {
                                        weakSelf.loadNextSetOfData()
//                                    }
                                }
                            }
                            weakSelf.selectionRecentChatList.enumerated().forEach { (index,selectedRecentChat) in
                                weakSelf.getRecentChat.filter({$0.jid == selectedRecentChat.jid}).first?.isSelected = selectedRecentChat.isSelected
                            }
                        } else {
                            weakSelf.getRecentChat = recentChatList
                            weakSelf.getAllRecentChat = recentChatList

                            weakSelf.getRecentChat = weakSelf.searchBar?.text?.trim().isEmpty ?? false ? weakSelf.getAllRecentChat : weakSelf.getAllRecentChat.filter({ recentChat -> Bool in
                                let name = getUserName(jid: recentChat.jid,name: recentChat.profileName, nickName: recentChat.nickName,contactType: recentChat.isItSavedContact ? .live : .unknown)
                                return (name.range(of: weakSelf.searchBar?.text?.trim() ?? "", options: [.caseInsensitive, .diacriticInsensitive]) != nil && recentChat.isDeletedUser == false)
                            })
                            let archiveSearchChats = weakSelf.getArchiveChat.filter({ recentChat -> Bool in
                                let name = getUserName(jid: recentChat.jid,name: recentChat.profileName, nickName: recentChat.nickName,contactType: recentChat.isItSavedContact ? .live : .unknown)
                                return (name.range(of: weakSelf.searchBar?.text?.trim() ?? "", options: [.caseInsensitive, .diacriticInsensitive]) != nil && recentChat.isDeletedUser == false)
                            })

                            weakSelf.getRecentChat = (weakSelf.getRecentChat + archiveSearchChats).sorted { $0.lastMessageTime > $1.lastMessageTime }
                        }
                        DispatchQueue.main.async { [weak self] in
                            self?.getOverallUnreadCount()
                            if ENABLE_CHAT_HISTORY {
                                weakSelf.getArchiveChatList()
                                weakSelf.getPrivateChatList()
                                self?.recentChatTableView?.reloadData()
                            } else {
                                self?.showHideEmptyMessage()
                                self?.recentChatTableView?.reloadData()
                            }
                        }
                    }
                }

                })
//            }
            if !ENABLE_CHAT_HISTORY {
            DispatchQueue.init(label: "Archive", qos: .userInteractive).async{
                    ChatManager.getArchivedChatList { [weak self] isSuccess, error, data in
                        if isSuccess {
                            self?.getArchiveChat = data["data"] as? [RecentChat] ?? []
                            self?.selectionRecentChatList.enumerated().forEach { (index,selectedRecentChat) in
                                self?.getArchiveChat.filter({$0.jid == selectedRecentChat.jid}).first?.isSelected = selectedRecentChat.isSelected
                            }
                            self?.showHideEmptyMessage()
                        }
                        executeOnMainThread {
                            self?.recentChatTableView?.reloadData()
                        }
                    }
                }

                DispatchQueue.init(label: "PrivateChat").async{
                    ChatManager.getPrivateChatList { [self] isSuccess, error, data in
                        if isSuccess {
                            self.getPrivateChats = data["data"] as? [RecentChat] ?? []

                            if showPrivateChat {
                                self.selectionRecentChatList = self.selectionRecentChatList.filter({ item in self.getPrivateChats.contains(where: { $0.jid == item.jid }) })
                                longPressCount = self.selectionRecentChatList.count
                                selectionCountLabel?.text = String(longPressCount)
                                if self.selectionRecentChatList.count == 0 {
                                    hideMultipleSelectionView()
                                }
                            }
                            self.selectionRecentChatList.enumerated().forEach { (index,selectedRecentChat) in
                                self.getPrivateChats.filter({$0.jid == selectedRecentChat.jid}).first?.isSelected = selectedRecentChat.isSelected
                            }

                            if self.isSearchEnabled {
                                getRecentChat = getRecentChat.filter { chat in
                                    return getPrivateChats.contains { privateChat in
                                        privateChat.jid == chat.jid
                                    }
                                }

                                getRecentChat = searchBar?.text?.trim().isEmpty ?? false ? getAllRecentChat : getAllRecentChat.filter({ recentChat -> Bool in
                                    let name = getUserName(jid: recentChat.jid,name: recentChat.profileName, nickName: recentChat.nickName,contactType: recentChat.isItSavedContact ? .live : .unknown)
                                    return (name.range(of: searchBar?.text?.trim() ?? "", options: [.caseInsensitive, .diacriticInsensitive]) != nil && recentChat.isDeletedUser == false)
                                })
                                let archiveSearchChats = getArchiveChat.filter({ recentChat -> Bool in
                                    let name = getUserName(jid: recentChat.jid,name: recentChat.profileName, nickName: recentChat.nickName,contactType: recentChat.isItSavedContact ? .live : .unknown)
                                    return (name.range(of: searchBar?.text?.trim() ?? "", options: [.caseInsensitive, .diacriticInsensitive]) != nil && recentChat.isDeletedUser == false)
                                })

                                getRecentChat = (getRecentChat + archiveSearchChats).sorted { $0.lastMessageTime > $1.lastMessageTime }

                            }
                            self.showHideEmptyMessage()
                        }
                    }
               }
            }

            if (showArchivedChat && getArchiveChat.count == 0) && !showPrivateChat {
                hideArchiveHeader()
            } else if (showPrivateChat && getPrivateChats.count == 0) {
                //self.recentChatTableView?.tableHeaderView = nil
                //self.recentChatTableView?.contentInset.top = 0
            }
        } else {
            self.selectedChatTag = getChatTags.first(where: {$0.tagId == self.selectedChatTag.tagId})
            if self.selectedChatTag != nil {
                if let index = getChatTags.firstIndex(of: selectedChatTag) {
                    let indexPath = IndexPath(item: index, section: 0)
                    if selectedTagIndex != indexPath.item {
                        self.chatTagsCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    }
                }
                DispatchQueue.main.async { [weak self] in
                    guard let self else {
                        return
                    }
                    if self.isSearchEnabled == false {
                        self.showHideEmptyMessage()
                    }
                    self.getOverallUnreadCount()
                }
            } else {
                self.selectedChatTag = ChatTagsModel(tagId: AppUtils.getMyJid(), tagname: "All", taginfo: "", isRecommentedTag: false, memberIdList: [], currentUserId: AppUtils.getMyJid())
                self.getRecentChatList()
                return
            }
            getRecentChatForSelectedChatTag(chatTag: selectedChatTag)
            DispatchQueue.main.async { [weak self] in
                if self?.isSearchEnabled == false {
                    //self?.recentChatTableView?.reloadData()
                    self?.showHideEmptyMessage()
                }
                self?.getOverallUnreadCount()
            }
            
            DispatchQueue.init(label: "ArchiveChat").async {
                
            ChatManager.getArchivedChatList { [weak self] isSuccess, error, data in
                if isSuccess {
                    self?.getArchiveChat = data["data"] as? [RecentChat] ?? []
                    self?.selectionRecentChatList.enumerated().forEach { (index,selectedRecentChat) in
                        self?.getArchiveChat.filter({$0.jid == selectedRecentChat.jid}).first?.isSelected = selectedRecentChat.isSelected
                    }
                    executeOnMainThread {
                        self?.showHideEmptyMessage()
                        self?.recentChatTableView?.reloadData()
                    }
                }
            }
        }

            DispatchQueue.init(label: "PrivateChat").async {
                ChatManager.getPrivateChatList { [self] isSuccess, error, data in
                    if isSuccess {
                        self.getPrivateChats = data["data"] as? [RecentChat] ?? []
                        
                        if showPrivateChat {
                            self.selectionRecentChatList = self.selectionRecentChatList.filter({ item in self.getPrivateChats.contains(where: { $0.jid == item.jid }) })
                            longPressCount = self.selectionRecentChatList.count
                            selectionCountLabel?.text = String(longPressCount)
                            if self.selectionRecentChatList.count == 0 {
                                executeOnMainThread { [weak self] in
                                    self?.hideMultipleSelectionView()
                                }
                            }
                        }
                        self.selectionRecentChatList.enumerated().forEach { (index,selectedRecentChat) in
                            self.getPrivateChats.filter({$0.jid == selectedRecentChat.jid}).first?.isSelected = selectedRecentChat.isSelected
                        }
                        
                    }
                    executeOnMainThread { [weak self] in
                        self?.showHideEmptyMessage()
                    }
                    }
            }

            if (showArchivedChat && getArchiveChat.count == 0) && !showPrivateChat {
                hideArchiveHeader()
            } else if (showPrivateChat && getPrivateChats.count == 0) {
                //self.recentChatTableView?.tableHeaderView = nil
                //self.recentChatTableView?.contentInset.top = 0
            }
            executeOnMainThread { [weak self] in
                self?.recentChatTableView?.reloadData()
            }
        }
    }

    func getArchiveChatList() {
//        DispatchQueue.init(label: "getarchivechats").async{
            ChatManager.getArchivedChatList { [weak self] isSuccess, error, data in
                if isSuccess {
                    self?.getArchiveChat = data["data"] as? [RecentChat] ?? []
                    self?.selectionRecentChatList.enumerated().forEach { (index,selectedRecentChat) in
                        self?.getArchiveChat.filter({$0.jid == selectedRecentChat.jid}).first?.isSelected = selectedRecentChat.isSelected
                    }
                }
                self?.showHideEmptyMessage()
                executeOnMainThread {
                    self?.recentChatTableView?.reloadData()
                }
            }
//        }
    }

    func getPrivateChatList() {
        DispatchQueue.init(label: "getprivatechats").async{
            ChatManager.getPrivateChatList { [weak self] isSuccess, error, data in
                if isSuccess {
                    self?.getPrivateChats = data["data"] as? [RecentChat] ?? []
                    self?.selectionRecentChatList.enumerated().forEach { (index,selectedRecentChat) in
                        self?.getPrivateChats.filter({$0.jid == selectedRecentChat.jid}).first?.isSelected = selectedRecentChat.isSelected
                    }
                    self?.showHideEmptyMessage()
                }
            }
        }
    }

    func updateRecentChatsLoading() {
        if isSearchEnabled == false {
            showHideEmptyMessage()
        }
        executeOnMainThread { [weak self] in
            self?.getOverallUnreadCount()
            //self?.recentChatTableView?.reloadData()
        }
    }

    func getLastMesssage() -> [ChatMessage]? {

        getRecentChatList()

        var chatMessage: [ChatMessage] = []
        let filteredObj = getRecentChat.filter({$0.lastMessageType == .video || $0.lastMessageType == .image})
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
}

// SearchBar Delegate Method
extension RecentChatViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String){
        if searchText.trim().count > 0 {
            isSearchEnabled = true
            self.recentChatTableView?.tableHeaderView = nil
            self.recentChatTableView?.contentInset.top = 0
            scrollToTableViewTop()
            hideMultipleSelectionView()
            clearSelectedColor()
            getRecentChat = searchText.trim().isEmpty ? getAllRecentChat : getAllRecentChat.filter({ recentChat -> Bool in
                let name = getUserName(jid: recentChat.jid,name: recentChat.profileName, nickName: recentChat.nickName,contactType: recentChat.isItSavedContact ? .live : .unknown)
                return (name.range(of: searchText.trim(), options: [.caseInsensitive, .diacriticInsensitive]) != nil && recentChat.isDeletedUser == false)
            })

            let archiveSearchChats = getArchiveChat.filter({ recentChat -> Bool in
                let name = getUserName(jid: recentChat.jid,name: recentChat.profileName, nickName: recentChat.nickName,contactType: recentChat.isItSavedContact ? .live : .unknown)
                return (name.range(of: searchText.trim(), options: [.caseInsensitive, .diacriticInsensitive]) != nil && recentChat.isDeletedUser == false)
            })

            getRecentChat = (getRecentChat + archiveSearchChats).sorted { $0.lastMessageTime > $1.lastMessageTime }
            //getRecentChat = getRecentChat.sorted { recentChatViewModel?.getRecentChat(jid: $0.jid).pinnedTime ?? 0.0 > recentChatViewModel?.getRecentChat(jid: $1.jid).pinnedTime ?? 0.0 }

            if ENABLE_CONTACT_SYNC {
                filteredContactList = searchText.trim().isEmpty ? removeDuplicateFromContacts(contactList: allContactsList) : removeDuplicateFromContacts(contactList: allContactsList).filter({ contact -> Bool in
                    let name = getUserName(jid: contact.jid,name: contact.name, nickName: contact.nickName, contactType: contact.contactType)
                    return name.range(of: searchText.trim(), options: [.caseInsensitive, .diacriticInsensitive]) != nil
                })
            } else {
                let searchString = searchText.trim()
                if !searchString.isEmpty || self.searchTerm != searchString{
                    resetParams()
                    searchSubject.onNext(searchString.lowercased())
                }
            }
           
        } else {
            isSearchEnabled = false
            //getRecentChatList()
            searchBar.setShowsCancelButton(true, animated: true)
            searchBar.text = ""
            getRecentChat = getAllRecentChat
            getArchiveChatList()
            filteredContactList = []
            searchedMessages = []
            recentChatTableView?.tableFooterView = nil
        }
        recentChatTableView?.reloadData()
        if ENABLE_CONTACT_SYNC {
            showHideEmptyMessage()
        }
        processSearchMessage(searchtext: searchText.trim())
    }
    
    func processSearchMessage(searchtext: String?) {
        DispatchQueue.global(qos: .background).async {
            self.searchedMessages = ChatManager.shared.searchMessage(text: searchtext ?? "").filter { !ChatManager.isPrivateChat(jid: $0.chatUserJid) }
        }
        DispatchQueue.main.async {[weak self] in
            self?.recentChatTableView?.reloadData()
            self?.showHideEmptyMessage()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        //refreshRecentChatMessages()
        isSearchEnabled = false
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.text = ""
        getRecentChat = getAllRecentChat
        getArchiveChatList()
        getPrivateChatList()
        recentChatTableView?.reloadData()
        recentChatTableView?.tableFooterView = nil
        setUpPullForPrivateChat()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
//        scrollToTableViewTop()
//        self.recentChatTableView?.tableHeaderView = nil
//        self.recentChatTableView?.contentInset.top = 0
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func scrollToTableViewTop() {
        self.recentChatTableView?.setContentOffset(.zero, animated: false)
    }
}

// UI Method
extension RecentChatViewController {
    func setProfile() {
        if currentIndex > -1{
            let profile = showPrivateChat ? getPrivateChats[currentIndex] : showArchivedChat ? getArchiveChat[currentIndex] : getRecentChat[currentIndex]
            let urlString = ChatManager.getImageUrl(imageName: profile.profileImage ?? "")
            let isDeletedUser = profile.isDeletedUser
            username?.text = getUserName(jid: profile.jid,name: profile.profileName, nickName: profile.nickName, contactType: isDeletedUser ? .deleted :  (profile.isItSavedContact ? .live : .unknown))
            let url = URL(string: urlString)
            let color = getColor(userName: getUserName(jid: profile.jid,name: profile.profileName, nickName: profile.nickName, contactType: profile.isItSavedContact ? .live : .unknown))
            var placeHolder = UIImage()
            enableOrDisableChatActions(enable: true)
            let isImageEmpty = profile.profileImage?.isEmpty ?? false
            if profile.profileType == .groupChat {
                placeHolder = UIImage(named: ImageConstant.ic_group_placeholder)!
                print("setProfile \(isImageEmpty)")
                if isImageEmpty {
                    userImage?.tag = 0
                    userImage?.backgroundColor = Color.groupIconBackgroundGray
                    self.userImage?.contentMode = .scaleAspectFit
                    userImage?.image = placeHolder
                } else {
                    userImage?.tag = 1
                    userImage?.sd_imageIndicator = SDWebImageActivityIndicator.gray
                    self.userImage?.contentMode = .scaleAspectFit
                    userImage?.sd_setImage(with: url, placeholderImage: placeHolder) {_,responseError,_,_ in
                        if responseError != nil {
                            self.userImage?.contentMode = .scaleAspectFit
                        } else {
                            self.userImage?.contentMode = .scaleAspectFill
                        }
                    }
                }
                videoCallView.isHidden = true
                audioCallView.isHidden = true
                messageView.isHidden = false
                infoView.isHidden = false
            } else {
                videoCallView.isHidden = (!availableFeatures.isOneToOneCallEnabled || profile.isDeletedUser) ? true : false
                audioCallView.isHidden = (!availableFeatures.isOneToOneCallEnabled || profile.isDeletedUser) ? true : false
                messageView.isHidden = false
                infoView.isHidden = false
                placeHolder = getPlaceholder(name: getUserName(jid: profile.jid,name: profile.profileName, nickName: profile.nickName, contactType: profile.isItSavedContact ? .live : .unknown), color: color )
                print("setProfile \(isImageEmpty)")
                if isImageEmpty {
                    userImage?.tag = 0
                    self.userImage?.contentMode = .scaleAspectFill
                    userImage?.image = placeHolder
                } else {
                    userImage?.tag = 1
                    userImage?.sd_imageIndicator = SDWebImageActivityIndicator.gray
                    userImage?.contentMode = .scaleAspectFill
                    userImage?.sd_setImage(with: url, placeholderImage: placeHolder)
                }
            }
            if profile.isDeletedUser || getisBlockedMe(jid: profile.jid) || profile.isBlockedByAdmin || (IS_LIVE && ENABLE_CONTACT_SYNC && profile.isItSavedContact == false){
                userImage?.backgroundColor =  Color.groupIconBackgroundGray
                let placeHolder = profile.isGroup ? UIImage(named: "ic_groupPlaceHolder") :  UIImage(named: "ic_profile_placeholder")
                userImage?.sd_setImage(with: nil, placeholderImage: placeHolder ?? UIImage())
                enableOrDisableChatActions(enable: true)
            }
            
            if (IS_LIVE && ENABLE_CONTACT_SYNC && profile.isItSavedContact == false) && isImageEmpty && !profile.isGroup {
                userImage?.image = UIImage(named: "ic_profile_placeholder")
                userImage?.tag = 0
                userImage?.isUserInteractionEnabled = false
                return
            }
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.openContainerImage(sender:)))
            userImage?.isUserInteractionEnabled = true
            userImage?.addGestureRecognizer(tap)
        }
    }
    
    private func enableOrDisableChatActions(enable : Bool) {
        chatActionVideoCallButton.isEnabled = enable
        chatActionAudioCallButton.isEnabled = enable
    }
    
    private func getBlocked(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlocked ?? false
    }
    
    func getOverallUnreadCount() {
        let overallUnreadCount = getRecentChat.filter({$0.unreadMessageCount > 0}).count
        if overallUnreadCount > 0 {
            chatTabBarItem?.badgeValue =  "\(overallUnreadCount)"
        } else {
            chatTabBarItem?.badgeValue = nil
        }
    }
    
    
    
    private func showHideDeleteButton() {
        
        if !availableFeatures.isDeleteChatEnabled {
            deleteChatButton?.isHidden = true
        }else {
            if selectionRecentChatList.filter({$0.profileType == .groupChat}).count == 0  {
                deleteChatButton?.isHidden = false
            } else {
                
                let groups = selectionRecentChatList.filter({$0.profileType == .groupChat})
                print("groupss count ==> \(groups.count)")
                
                for group in groups {
                    let result = isParticipantExist(groupJid: group.jid)
                    if result.doesExist {
                        deleteChatButton?.isHidden = true
                        return
                    }else{
                        deleteChatButton?.isHidden = false
                    }
                }
            }
        }
    }
    
    func isParticipantExist(groupJid: String) -> (doesExist : Bool, message : String) {
       return GroupManager.shared.isParticiapntExistingIn(groupJid: groupJid, participantJid: AppUtils.getMyJid())
    }
    
    func getPlaceholder(name: String, color: UIColor)->UIImage {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let ipimage = IPImage(text: trimmedName, radius: Double(userImage?.frame.size.height ?? 0.0), font: UIFont.font84px_appBold(), textColor: nil, color: color)
        let placeholder = ipimage.generateInitialSqareImage()
        return placeholder ?? #imageLiteral(resourceName: "ic_profile_placeholder")
    }
    
    private func removeDuplicateFromContacts(contactList: [ProfileDetails]) -> [ProfileDetails] {
        var removeDuplicateList = contactList
            removeDuplicateList.enumerated().forEach({  (index, element) in
                if getRecentChat.filter({$0.jid == element.jid}).count > 0 {
                    if removeDuplicateList.count <= index {
                        removeDuplicateList.remove(at: index)
                        }
                    }
            })
        return removeDuplicateList
    }
    
    private func showHideEmptyMessage() {

        executeOnMainThread { [self] in
            if isSearchEnabled == true {
                emptyMessageView?.isHidden = (getRecentChat.count == 0 && filteredContactList.count == 0 && searchedMessages.count == 0) ? false : true
                emptyImage?.isHidden = true
                noNewMsgText?.isHidden = false
                noNewMsgText?.text = noResultFound
                noNewMsgText?.textColor = .lightGray
                descriptionMessageText?.isHidden = true
                showOnlyPrivateChatAvailableView(isShow: false)
            } else {
                if showPrivateChat {
                    emptyMessageView?.isHidden = getPrivateChats.count == 0 ? false : true
                    emptyImage?.isHidden = false
                    noNewMsgText?.isHidden = false
                    noNewMsgText?.text = noPrivateMessage
                    noNewMsgText?.textColor = .black
                    descriptionMessageText?.isHidden = true
                    showOnlyPrivateChatAvailableView(isShow: false)
                } else if getRecentChat.count == 0 && getArchiveChat.count == 0 && getPrivateChats.count != 0 {
                    emptyMessageView?.isHidden = getPrivateChats.count == 0 ? true : false
                    emptyImage?.isHidden = false
                    noNewMsgText?.isHidden = false
                    noNewMsgText?.text = noPrivateMessage
                    noNewMsgText?.textColor = .black
                    descriptionMessageText?.isHidden = true
                    showOnlyPrivateChatAvailableView(isShow: true)
                } else {
                    emptyMessageView?.isHidden = (getRecentChat.count == 0 && getArchiveChat.count == 0) ? false : true
                    emptyImage?.isHidden = false
                    noNewMsgText?.isHidden = false
                    noNewMsgText?.text = noNewMessage
                    noNewMsgText?.textColor = .black
                    descriptionMessageText?.isHidden = false
                    showOnlyPrivateChatAvailableView(isShow: false)
                }
            }
        }
    }

    func showOnlyPrivateChatAvailableView(isShow: Bool) {

        if isShow {
            if getPrivateChats.count > 0 {
                self.recentChatTableView?.tableHeaderView = nil
            }
        }

        if let bounds = emptyMessageView?.bounds {
            onlyPrivateChatAvailableView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)

            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: 70))
            imageView.image = UIImage(named: "privateChat_enable")
            imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = Color.color_AFBDDF
            imageView.contentMode = .scaleAspectFit
            onlyPrivateChatAvailableView.addSubview(imageView)

            onlyPrivateChatAvailableViewLabel = UILabel(frame: CGRect(x: 0, y: 80, width: bounds.width, height: bounds.height - 70))
            onlyPrivateChatAvailableViewLabel.numberOfLines = 0
            onlyPrivateChatAvailableViewLabel.textAlignment = .center
            onlyPrivateChatAvailableViewLabel.attributedText = attributedText()
            onlyPrivateChatAvailableViewLabel.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(onlyPrivateChatTapped))
            onlyPrivateChatAvailableViewLabel.addGestureRecognizer(tap)
            onlyPrivateChatAvailableView.backgroundColor = .white
            onlyPrivateChatAvailableView.addSubview(onlyPrivateChatAvailableViewLabel)

            if isShow {
                emptyMessageView?.addSubview(onlyPrivateChatAvailableView)
            } else {
                onlyPrivateChatAvailableView.removeFromSuperview()
            }
        }
    }


    @objc func onlyPrivateChatTapped(sender: UITapGestureRecognizer) {
        let textRange = ("All Chats are Locked\n\nUnlock Your Private Chat" as NSString).range(of: "Unlock Your Private Chat")
        if sender.didTapAttributedTextInLabel(label: onlyPrivateChatAvailableViewLabel, inRange: textRange) {
            showLockScreen()
        }
    }

    func attributedText() -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let string = "All Chats are Locked\n\nUnlock Your Private Chat" as NSString
        let attributedString = NSMutableAttributedString(string: string as String, attributes: [NSAttributedString.Key.font:UIFont(name: "SFUIDisplay-Regular", size: 17), .paragraphStyle: paragraph])
        let boldFontAttribute = [NSAttributedString.Key.font: UIFont(name: "SFUIDisplay-Medium", size: 18), NSAttributedString.Key.foregroundColor : Color.primaryAppColor]
        attributedString.addAttributes(boldFontAttribute as [NSAttributedString.Key : Any], range: string.range(of: "Unlock Your Private Chat"))
        return attributedString
    }
    
    private func getisBlockedMe(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlockedMe ?? false
    }
    
    private func clearChatList() {
        getRecentChat.removeAll()
        getAllRecentChat.removeAll()
        unreadMessageChatList.removeAll()
        allUnreadMessageChatList.removeAll()
    }
    
    private func refreshRecentChatMessages() {
        isSearchEnabled = false
        searchBar?.resignFirstResponder()
        searchBar?.setShowsCancelButton(false, animated: true)
        searchBar?.text = ""
        getRecentChatList()
        recentChatTableView?.tableFooterView = nil
    }
}

extension RecentChatViewController : ConnectionEventDelegate {
    func onConnectionFailed(error: FlyError) {
    
    }
    
    func onReconnecting() {
    
    }
    
    func onConnected() {
        if !Utility.getBoolFromPreference(key: "oneTimeSync") {
            print("contactSyncRequest=====>2")
//            ContactSyncManager.shared.syncContacts(){ isSuccess,_,_ in
//                if isSuccess {
//                    print("oneTimeSync", isSuccess)
//                    Utility.saveInPreference(key: "oneTimeSync", value: true)
//                }
//            }

        }
    }
    
    func onDisconnected() {}
    
}

// MessageEventDelegate
extension RecentChatViewController : MessageEventsDelegate {
    
    func onMessageTranslated(message: ChatMessage, jid: String) {
        
    }
    
    func onMessageEdited(message: MirrorFlySDK.ChatMessage) {
        executeOnMainThread {
            FlyLog.DLog(param1: "#messageTextContentRecent=>\(message.messageTextContent)", param2: "")
            switch self.isSearchEnabled {
            case true:
                if !self.searchedMessages.isEmpty {
                    if let _ = self.searchedMessages.firstIndex(where: { $0.messageId == message.messageId}), let searchText = self.searchBar?.text?.trim() {
                        self.searchedMessages = ChatManager.shared.searchMessage(text: searchText).filter { !ChatManager.isPrivateChat(jid: $0.chatUserJid) }
                        self.recentChatTableView?.reloadData()
                    }
                }
            case false:
                if !self.getArchiveChat.isEmpty {
                    if let index = self.getArchiveChat.firstIndex(where: { $0.lastMessageId == message.messageId}) {
                        self.recentChatTableView?.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                    }
                } else if !self.getPrivateChats.isEmpty {
                    if let index = self.getPrivateChats.firstIndex(where: { $0.lastMessageId == message.messageId}) {
                        self.recentChatTableView?.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                    }
                }
            }
            if !self.getRecentChat.isEmpty {
                if let index = self.getRecentChat.firstIndex(where: { $0.lastMessageId == message.messageId}) {
                    if let recentChat = ChatManager.getRechtChat(jid: self.getRecentChat[index].jid) {
                        self.getRecentChat[index] = recentChat
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.recentChatTableView?.reloadDataWithoutScroll()
                    }
                }
            }
        }
    }
    
    func onMessageStatusUpdated(messageId: String, chatJid: String, status: MessageStatus) {
        print("onMessageStatusUpdated \(messageId) \(chatJid) \(status)")
        updateRecentChatFor(jid: chatJid, updateMessageStatus: true)
    }
    
    func onMediaStatusUpdated(message: ChatMessage) {
        
    }
    
    func onMediaStatusFailed(error: String, messageId: String, errorCode: Int) {
        
    }
    
    func onMediaProgressChanged(message: ChatMessage, progressPercentage: Float) {
        
    }
    
    func onMessagesClearedOrDeleted(messageIds: Array<String>) {
        updateRecentChatFor(jid: "", deletedMessageIds: messageIds)
    }
    
    func onMessagesDeletedforEveryone(messageIds: Array<String>) {
        updateRecentChatFor(jid: "", deletedMessageIds: messageIds)
        processSearchMessage(searchtext: self.searchBar?.text)
    }
    
    func showOrUpdateOrCancelNotification() {}
    
    func onMessagesCleared(toJid: String, deleteType: String?) {
        
        if deleteType == "0" {
            updateRecentChatFor(jid: toJid, isDelete: true)
        }
        else {
            if showPrivateChat {
                if let index = getPrivateChats.firstIndex(where: { pd in pd.jid == toJid }) {
                    if let recentChat = ChatManager.getRechtChat(jid: toJid) {
                        getPrivateChats[index] = recentChat
                        recentChatTableView?.reloadData()
                    }
                }
            } else if showArchivedChat {
                if let index = getArchiveChat.firstIndex(where: { pd in pd.jid == toJid }) {
                    if let recentChat = ChatManager.getRechtChat(jid: toJid) {
                        getArchiveChat[index] = recentChat
                        recentChatTableView?.reloadData()
                    }
                }
            } else {
                if let index = getRecentChat.firstIndex(where: { pd in pd.jid == toJid }) {
                    if let recentChat = ChatManager.getRechtChat(jid: toJid) {
                        getRecentChat[index] = recentChat
                        recentChatTableView?.reloadData()
                    }
                }
            }
            self.getOverallUnreadCount()
        }
    }
    
    func setOrUpdateFavourite(messageId: String, favourite: Bool, removeAllFavourite: Bool) {}
    
    func onMessageReceived(message: ChatMessage, chatJid: String) {
        print("onMessageReceived \(message.messageId) \(chatJid)")
        if isSearchEnabled {
            updateRecentChatFor(jid: message.chatUserJid, moveRecent: true)
        } else {
            isSearchEnabled = false
            searchBar?.resignFirstResponder()
            searchBar?.setShowsCancelButton(false, animated: true)
            searchBar?.text = ""
            updateRecentChatFor(jid: message.chatUserJid, moveRecent: true)
            recentChatTableView?.tableFooterView = nil
        }
    }
    
    func clearAllConversationForSyncedDevice() {

        DispatchQueue.main.async {
            self.getRecentChatList()
            self.recentChatTableView?.reloadData()
        }
        
    }

    func updateRecentChatFor(jid: String, isDelete: Bool = false, deletedMessageIds: [String] = [], moveRecent: Bool = false, updateMessageStatus: Bool = false) {
        let recentChat = ChatManager.getRechtChat(jid: jid)
        if showArchivedChat == true {
            if isDelete {
                getArchiveChat.removeAll(where: { recent in
                    return recent.jid == jid
                })
                getAllRecentChat.removeAll(where: { recent in
                    return recent.jid == jid
                })
            } else {
                if deletedMessageIds.count > 0 {
                    //deletedMessageIds.forEach { msgId in
                        if let msg = ChatManager.getMessageOfId(messageId: deletedMessageIds[0]) {
                            if let recent = ChatManager.getRechtChat(jid: msg.chatUserJid) {
                                if let index = getArchiveChat.firstIndex(where: {$0.jid == msg.chatUserJid}) {
                                    getArchiveChat[index] = recent
                                }
                            }
                        }
                    //}
                } else {
                    if let index = getArchiveChat.firstIndex(where: {$0.jid == jid}), let recent = recentChat {
                        if moveRecent {
                            getArchiveChat.remove(at: index)
                            getArchiveChat.insert(recent, at: 0)
                        } else {
                            getArchiveChat[index] = recent
                        }
                    } else {
                        if updateMessageStatus == false {
                            if let recent = recentChat, recent.isChatArchived == true {
                                getArchiveChat.insert(recent, at: 0)
                            }
                        }
                    }
                }
            }
        } else if showPrivateChat == true {
            if isDelete {
                getPrivateChats.removeAll(where: { recent in
                    return recent.jid == jid
                })
                getAllRecentChat.removeAll(where: { recent in
                    return recent.jid == jid
                })
            } else {
                if deletedMessageIds.count > 0 {
                    //deletedMessageIds.forEach { msgId in
                        if let msg = ChatManager.getMessageOfId(messageId: deletedMessageIds[0]) {
                            if let recent = ChatManager.getRechtChat(jid: msg.chatUserJid) {
                                if let index = getPrivateChats.firstIndex(where: {$0.jid == msg.chatUserJid}) {
                                    getPrivateChats[index] = recent
                                }
                            }
                        }
                    //}
                } else {
                    if let index = getPrivateChats.firstIndex(where: {$0.jid == jid}), let recent = recentChat {
                        if moveRecent {
                            getPrivateChats.remove(at: index)
                            getPrivateChats.insert(recent, at: 0)
                        } else {
                            getPrivateChats[index] = recent
                        }
                    } else {
                        if updateMessageStatus == false {
                            if let recent = recentChat, recent.isPrivateChat == true {
                                getPrivateChats.insert(recent, at: 0)
                            }
                        }
                    }
                }
            }
        } else {
            if isDelete {
                getRecentChat.removeAll(where: { recent in
                    return recent.jid == jid
                })
                getAllRecentChat.removeAll(where: { recent in
                    return recent.jid == jid
                })
            } else {
                if deletedMessageIds.count > 0 {
                    //deletedMessageIds.forEach { msgId in
                        if let msg = ChatManager.getMessageOfId(messageId: deletedMessageIds[0]) {
                            if let recent = ChatManager.getRechtChat(jid: msg.chatUserJid) {
                                if let index = getRecentChat.firstIndex(where: {$0.jid == msg.chatUserJid}) {
                                    getRecentChat[index] = recent
                                }
                            }
                        }
                    //}
                } else {
                    if let index = getRecentChat.firstIndex(where: {$0.jid == jid}), let recent = recentChat {
                        getAllRecentChat[index] = recent
                        if moveRecent {
                            if ChatManager.recentChatPinnedCount() > 0 {
                                getRecentChat.enumerated().forEach{ (indexValue,item) in
                                    if item.jid == jid {
                                        getRecentChat[indexValue] = recent
                                        self.recentChatTableView?.reloadRows(at: [IndexPath(row: indexValue, section: 0)], with: .none)
                                    }
                                }
                            } else {
                                getRecentChat.remove(at: index)
                                getRecentChat.insert(recent, at: 0 + ChatManager.recentChatPinnedCount())
                            }
                        } else {
                            if recent.unreadMessageCount == 0 {
                                FlyMessenger.shared.deleteUnreadMessageSeparatorOfAConversation(jid: jid)
                            }
                            getRecentChat[index] = recent
                        }
                    } else {
                        if updateMessageStatus == false {
                            if let recent = recentChat, recent.isChatArchived == false, recent.isPrivateChat == false {
                                if ChatManager.recentChatPinnedCount() > 0 {
                                    getRecentChat.enumerated().forEach{ (indexValue,item) in
                                        if item.jid == jid {
                                            getRecentChat[indexValue] = recent
                                            self.recentChatTableView?.reloadRows(at: [IndexPath(row: indexValue, section: 0)], with: .none)
                                        }
                                    }
                                } else {
                                    getRecentChat.insert(recent, at: 0 + ChatManager.recentChatPinnedCount())
                                }
                            }
                        }
                    }
                }
            }
        }
        recentChatTableView?.reloadData()
    }
}


// Profile Event Delegate
extension RecentChatViewController : ProfileEventsDelegate {
    func userCameOnline(for jid: String) {}
    
    func userWentOffline(for jid: String) {}
    
    func userProfileFetched(for jid: String, profileDetails: ProfileDetails?) {
        
        if let index = showPrivateChat ? getPrivateChats.firstIndex(where: { pd in pd.jid == jid }) : showArchivedChat ? getArchiveChat.firstIndex(where: { pd in pd.jid == jid }) : getRecentChat.firstIndex(where: { pd in pd.jid == jid }) {
            if showArchivedChat {
                getArchiveChat[index].profileImage = profileDetails?.image
                getArchiveChat[index].profileThumbImage = profileDetails?.thumbImage
                getArchiveChat[index].profileName = profileDetails?.name ?? ""
            } else if showPrivateChat {
                getPrivateChats[index].profileImage = profileDetails?.image
                getPrivateChats[index].profileThumbImage = profileDetails?.thumbImage
                getPrivateChats[index].profileName = profileDetails?.name ?? ""
            } else {
                getRecentChat[index].profileImage = profileDetails?.image
                getRecentChat[index].profileThumbImage = profileDetails?.thumbImage
                getRecentChat[index].profileName = profileDetails?.name ?? ""
            }
            print("userUpdatedTheirProfile currentIndex \(currentIndex)")
            let profile = ["jid": profileDetails?.jid, "name": profileDetails?.name, "image": profileDetails?.image, "status": profileDetails?.status, "thumbImage": profileDetails?.thumbImage]
            NotificationCenter.default.post(name: Notification.Name(Identifiers.ncProfileUpdate),
                                            object: nil,userInfo: profile as [AnyHashable: Any])
            NotificationCenter.default.post(name: Notification.Name(FlyConstants.contactSyncState),
                                            object: nil, userInfo: profile as [AnyHashable: Any])


            let section = showPrivateChat ? 0 : showArchivedChat ? 0 : getArchiveChat.count > 0 ? ChatManager.isArchivedSettingsEnabled() ? 1 : 0 : 0
            reloadRecentChatRow(index : index, section : section)
            //recentChatTableView?.reloadData()
        }
    }
    
    func myProfileUpdated() {}
    
    func usersProfilesFetched() {
        print("RecentChatViewController usersProfilesFetched")
        //getRecentChatList()
        if ENABLE_CONTACT_SYNC{
            getContactList()
        }
        setProfile()
    }
    
    func blockedThisUser(jid: String) {}

    func unblockedThisUser(jid: String) {}

    func usersIBlockedListFetched(jidList: [String]) {}
    
    func usersBlockedMeListFetched(jidList: [String]) {
        //recentChatTableView?.reloadData()
        jidList.forEach { jid in
            if let index = showPrivateChat ? getPrivateChats.firstIndex(where: { pd in pd.jid == jid }) : showArchivedChat ? getArchiveChat.firstIndex(where: { pd in pd.jid == jid }) : getRecentChat.firstIndex(where: { pd in pd.jid == jid }) {
                let section = showPrivateChat ? 0 : showArchivedChat ? 0 : getArchiveChat.count > 0 ? ChatManager.isArchivedSettingsEnabled() ? 1 : 0 : 0
                reloadRecentChatRow(index : index, section : section)
            }
        }
        executeOnMainThread { [weak self] in
            self?.setProfile()
        }
    }
    
    func userBlockedMe(jid: String) {
        if let recentChat = ChatManager.getRechtChat(jid: jid){
            if isSearchEnabled{
                if let indexofJid = getRecentChat.firstIndex(where: { pd in pd.jid == jid }){
                    getRecentChat[indexofJid] = recentChat
                    reloadRecentChatRow(index: indexofJid, section: 0)
                }else if let indexofJid = filteredContactList.firstIndex(where: { pd in pd.jid == jid }), let profileDetails = ChatManager.profileDetaisFor(jid: jid){
                    filteredContactList[indexofJid] = profileDetails
                    reloadRecentChatRow(index: indexofJid, section: 1)
                }
            }else if let indexofJid = showPrivateChat ? getPrivateChats.firstIndex(where: { pd in pd.jid == jid }) : showArchivedChat ? getArchiveChat.firstIndex(where: { pd in pd.jid == jid }) :  getRecentChat.firstIndex(where: { pd in pd.jid == jid }) {
                if showPrivateChat {
                    getPrivateChats[indexofJid] = recentChat
                } else if showArchivedChat {
                    getArchiveChat[indexofJid] = recentChat
                } else {
                    getRecentChat[indexofJid] = recentChat
                }
                let section = showPrivateChat ? 0 : showArchivedChat ? 0 : getArchiveChat.count > 0 ? ChatManager.isArchivedSettingsEnabled() ? 1 : 0 : 0
                reloadRecentChatRow(index : indexofJid, section : section)
                setProfile()
            }
        }
    }
    
    func userUnBlockedMe(jid: String) {
        if let recentChat = ChatManager.getRechtChat(jid: jid){
            if isSearchEnabled{
                if let indexofJid = getRecentChat.firstIndex(where: { pd in pd.jid == jid }){
                    getRecentChat[indexofJid] = recentChat
                    reloadRecentChatRow(index: indexofJid, section: 0)
                }else if let indexofJid = filteredContactList.firstIndex(where: { pd in pd.jid == jid }), let profileDetails = ChatManager.profileDetaisFor(jid: jid){
                    filteredContactList[indexofJid] = profileDetails
                    reloadRecentChatRow(index: indexofJid, section: 1)
                }
            }else if let indexofJid = showPrivateChat ? getPrivateChats.firstIndex(where: { pd in pd.jid == jid }) : showArchivedChat ? getArchiveChat.firstIndex(where: { pd in pd.jid == jid }) :  getRecentChat.firstIndex(where: { pd in pd.jid == jid }) {
                if showPrivateChat {
                    getPrivateChats[indexofJid] = recentChat
                } else if showArchivedChat {
                    getArchiveChat[indexofJid] = recentChat
                } else {
                    getRecentChat[indexofJid] = recentChat
                }
                let section = showPrivateChat ? 0 : showArchivedChat ? 0 : getArchiveChat.count > 0 ? ChatManager.isArchivedSettingsEnabled() ? 1 : 0 : 0
                reloadRecentChatRow(index : indexofJid, section : section)
                setProfile()
            }
        }
    }
    
    func hideUserLastSeen() {}
    
    func getUserLastSeen() {}
    
    func userUpdatedTheirProfile(for jid: String, profileDetails: ProfileDetails) {
        print("userUpdatedTheirProfile \(jid)")
        if let index = showPrivateChat ? getPrivateChats.firstIndex(where: { pd in pd.jid == jid }) : showArchivedChat ? getArchiveChat.firstIndex(where: { pd in pd.jid == jid }) : getRecentChat.firstIndex(where: { pd in pd.jid == jid }) {
            if showArchivedChat {
                getArchiveChat[index].profileImage = profileDetails.image
                getArchiveChat[index].profileThumbImage =  profileDetails.thumbImage
                getArchiveChat[index].profileName = profileDetails.name
            } else {
                getRecentChat[index].profileImage = profileDetails.image
                getRecentChat[index].profileThumbImage = profileDetails.thumbImage
                getRecentChat[index].profileName = profileDetails.name
            }
            print("userUpdatedTheirProfile currentIndex \(currentIndex)")
            let profile = ["jid": profileDetails.jid, "name": profileDetails.name, "image": profileDetails.image, "status": profileDetails.status, "thumbImage": profileDetails.thumbImage]
            NotificationCenter.default.post(name: Notification.Name(Identifiers.ncProfileUpdate), object: nil,
                                            userInfo: profile as [AnyHashable : Any])
            NotificationCenter.default.post(name: Notification.Name(FlyConstants.contactSyncState), object: nil,
                                            userInfo: profile as [AnyHashable : Any])

            let section = showPrivateChat ? 0 : showArchivedChat ? 0 : getArchiveChat.count > 0 ? ChatManager.isArchivedSettingsEnabled() ? 1 : 0 : 0
            reloadRecentChatRow(index : index, section : section)

            if profilePopupContainer?.isHidden == false  && currentIndex == index {
                setProfile()
            }
        }
    }
    
    func userDeletedTheirProfile(for jid : String, profileDetails:ProfileDetails){
        print("#userDeleted \(jid)  \(profileDetails.name) \(profileDetails.nickName)")
        if let index = getRecentChat.firstIndex(where: { pd in pd.jid == jid }) {
            getRecentChat[index].profileImage = profileDetails.image
            getRecentChat[index].profileName = profileDetails.name
            getRecentChat[index].nickName = profileDetails.nickName
            getRecentChat[index].isItSavedContact = false
            getRecentChat[index].isDeletedUser = true
        }
        if let index = getAllRecentChat.firstIndex(where: { pd in pd.jid == jid }) {
            getAllRecentChat[index].profileImage = profileDetails.image
            getAllRecentChat[index].profileName = profileDetails.name
            getAllRecentChat[index].nickName = profileDetails.nickName
            getAllRecentChat[index].isItSavedContact = false
            getAllRecentChat[index].isDeletedUser = true
        }
        if let index = getArchiveChat.firstIndex(where: { pd in pd.jid == jid }) {
            getArchiveChat[index].profileImage = profileDetails.image
            getArchiveChat[index].profileName = profileDetails.name
            getArchiveChat[index].nickName = profileDetails.nickName
            getArchiveChat[index].isItSavedContact = false
            getArchiveChat[index].isDeletedUser = true
        }
        if let index = getPrivateChats.firstIndex(where: { pd in pd.jid == jid }) {
            getPrivateChats[index].profileImage = profileDetails.image
            getPrivateChats[index].profileName = profileDetails.name
            getPrivateChats[index].nickName = profileDetails.nickName
            getPrivateChats[index].isItSavedContact = false
            getPrivateChats[index].isDeletedUser = true
        }
        if let index = allContactsList.firstIndex(where: { pd in pd.jid == jid }) {
            allContactsList.remove(at: index)
            
        }
        if let index = filteredContactList.firstIndex(where: { pd in pd.jid == jid }) {
            filteredContactList.remove(at: index)
        }
        recentChatTableView?.reloadData()
    }
    
    func reloadRecentChatRow(index : Int, section : Int){
        let indexPath = IndexPath(item: index, section: section)
        recentChatTableView?.reloadRows(at: [indexPath], with: .none)
    }
}

extension RecentChatViewController : GroupCreationDelegate {
    func onGroupCreated() {
        print("RecentChatViewController onGroupCreated")
        getRecentChatList()
    }
}

extension RecentChatViewController : GroupEventsDelegate {
    func didRevokedAdminAccess(groupJid: String, revokedAdminMemberJid: String, revokedByMemberJid: String) {
        DispatchQueue.main.async { [weak self] in
            self?.updateGroupInRecentChat(groupJid: groupJid)
        }
    }
    
    func didAddNewMemeberToGroup(groupJid: String, newMemberJid: String, addedByMemberJid: String) {
        DispatchQueue.main.async { [weak self] in
            self?.updateGroupInRecentChat(groupJid: groupJid)
        }
    }
    
    func didRemoveMemberFromGroup(groupJid: String, removedMemberJid: String, removedByMemberJid: String) {
        DispatchQueue.main.async { [weak self] in
            self?.updateGroupInRecentChat(groupJid: groupJid)
        }
    }
    
    func didMakeMemberAsAdmin(groupJid: String, newAdminMemberJid: String, madeByMemberJid: String) {
        DispatchQueue.main.async { [weak self] in
            self?.updateGroupInRecentChat(groupJid: groupJid)
        }
    }
    
    func didDeleteGroupLocally(groupJid: String) {
        DispatchQueue.main.async { [weak self] in
            self?.getRecentChat = self?.getRecentChat.filter({ $0.jid != groupJid}) ?? []
            self?.getAllRecentChat = self?.getAllRecentChat.filter({ $0.jid != groupJid}) ?? []
            self?.getArchiveChat = self?.getArchiveChat.filter({ $0.jid != groupJid}) ?? []
            self?.getPrivateChats = self?.getPrivateChats.filter({ $0.jid != groupJid}) ?? []
            self?.recentChatTableView?.reloadData()
        }
    }
    
    func didLeftFromGroup(groupJid: String, leftUserJid: String) {
        DispatchQueue.main.async { [weak self] in
            self?.updateGroupInRecentChat(groupJid: groupJid)
        }
    }
    
    func didCreateGroup(groupJid: String) {
        DispatchQueue.main.async { [weak self] in
            self?.updateGroupInRecentChat(groupJid: groupJid)
        }
    }
    
    func didFetchGroupMembers(groupJid: String) {
        DispatchQueue.main.async { [weak self] in
            if !(self?.availableFeatures.isChatHistoryEnabled ?? true) {
                self?.updateGroupInRecentChat(groupJid: groupJid)
            }
        }
    }
    
    func didReceiveGroupNotificationMessage(message: ChatMessage) {
        DispatchQueue.main.async { [weak self] in
            self?.updateGroupInRecentChat(groupJid: message.chatUserJid)
        }
    }
    
    func didUpdateGroupProfile(groupJid: String) {
        DispatchQueue.main.async { [weak self] in
            if let index = self?.showPrivateChat ?? false ? self?.getPrivateChats.firstIndex(where: { pd in pd.jid == groupJid }) : self?.showArchivedChat ?? false ? self?.getArchiveChat.firstIndex(where: { pd in pd.jid == groupJid }) : self?.getRecentChat.firstIndex(where: { pd in pd.jid == groupJid }) {
                let group = self?.recentChatViewModel?.getGroupDetails(groupJid: groupJid)
                if self?.showArchivedChat ?? false {
                    self?.getArchiveChat[index].profileImage = group?.image
                    self?.getArchiveChat[index].profileThumbImage = group?.thumbImage
                    self?.getArchiveChat[index].profileName = group?.name ?? ""
                } else {
                    self?.getRecentChat[index].profileImage = group?.image
                    self?.getRecentChat[index].profileThumbImage = group?.thumbImage
                    self?.getRecentChat[index].profileName = group?.name ?? ""
                }
                let groupProfile = ["jid": group?.jid, "name": group?.name, "image": group?.image, "status": group?.status, "thumbImage": group?.thumbImage]
                
                NotificationCenter.default.post(name: Notification.Name(Identifiers.ncProfileUpdate), object: nil,
                                                userInfo: groupProfile as [AnyHashable : Any])
                NotificationCenter.default.post(name: Notification.Name(FlyConstants.contactSyncState), object: nil,
                                                userInfo: groupProfile as [AnyHashable : Any])
                
                let section = self?.showPrivateChat ?? false ? 0 : self?.showArchivedChat ?? false ? 0 : self?.getArchiveChat.count ?? 0 > 0 ? ChatManager.isArchivedSettingsEnabled() ? 1 : 0 : 0
                self?.reloadRecentChatRow(index : index, section : section)
                
                if self?.profilePopupContainer?.isHidden == false  && self?.currentIndex == index {
                    self?.setProfile()
                }
            }
            if !(self?.availableFeatures.isChatHistoryEnabled ?? true) {
                self?.updateGroupInRecentChat(groupJid: groupJid)
            }
        }
    }
    
    func didFetchGroups(groups: [ProfileDetails]) {
        print("RecentChatViewController didGetGroups \(groups.count)")
        getRecentChatList()
    }
    
    func didFetchGroupProfile(groupJid: String) {
    }
}

extension RecentChatViewController : ReplyMessagesDelegate {
    func replyMessageObj(message: ChatMessage?,jid: String,messageText: String) {
        replyMessageObj = message
        replyJid = jid
        messageTxt = messageText
    }
}

extension RecentChatViewController : AdminBlockDelegate {
    func didBlockOrUnblockContact(userJid: String, isBlocked: Bool) {
        updateAdminBlockedState(jid: userJid, isBlocked: isBlocked)
    }
    
    func didBlockOrUnblockSelf(userJid: String, isBlocked: Bool) {
        
    }
    
    func didBlockOrUnblockGroup(groupJid: String, isBlocked: Bool) {
        updateAdminBlockedState(jid: groupJid, isBlocked: isBlocked)
    }
}

// To hanlde User (group, single user, current user) Bloced events
extension RecentChatViewController {
    func updateAdminBlockedState(jid : String, isBlocked : Bool) {
        executeOnMainThread { [weak self] in
            if self?.showArchivedChat ?? false {
                if let recentChats = self?.getArchiveChat {
                    for (index, recent) in recentChats.enumerated() {
                        if recent.jid == jid {
                            self?.getArchiveChat[index].isBlockedByAdmin = isBlocked
                            self?.setProfile()
                            self?.recentChatTableView?.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                            break
                        }
                    }
                }
            } else {
                if let recentChats = self?.getRecentChat {
                    for (index, recent) in recentChats.enumerated() {
                        if recent.jid == jid {
                            self?.getRecentChat[index].isBlockedByAdmin = isBlocked
                            self?.setProfile()
                            self?.recentChatTableView?.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                            break
                        }
                    }
                }
            }
        }
    }
}

// To hanlde Group Events
extension RecentChatViewController {
    
    func updateGroupInRecentChat(groupJid : String) {
        let groupAndRecent = getGroupAndRecent(groupJid: groupJid)
        if checkGroupExistInRecntChat(groupJid: groupJid) {
            executeOnMainThread { [weak self] in
                if self?.showArchivedChat ?? false {
                    self?.getArchiveChat.enumerated().forEach { (index, element) in
                        if element.jid == groupJid {
                            if let recent = groupAndRecent.recentChat {
                                self?.getArchiveChat.remove(at: index)
                                self?.getArchiveChat.insert(recent, at: index)
                                print("\(self?.getArchiveChat[index].nickName ?? "")")
                                self?.recentChatTableView?.reloadData()
                            }
                        }
                    }
                } else {
                    self?.getRecentChat.enumerated().forEach { (index, element) in
                        if element.jid == groupJid {
                            if let recent = groupAndRecent.recentChat {
                                self?.getRecentChat.remove(at: index)
                                self?.getRecentChat.insert(recent, at: element.isChatPinned ? index : ChatManager.recentChatPinnedCount())
                                print("\(self?.getRecentChat[index].nickName ?? "")")
                                self?.recentChatTableView?.reloadData()
                            }
                        }
                    }
                }
            }
        } else {
            if let recent = groupAndRecent.recentChat {
                executeOnMainThread { [weak self] in
                    self?.getRecentChat.insert(recent, at: ChatManager.recentChatPinnedCount())
                    self?.recentChatTableView?.reloadData()
                }
            }
        }
    }
    
    func getGroupAndRecent(groupJid : String) -> (groupProfile : ProfileDetails? , recentChat : RecentChat?) {
        let group = recentChatViewModel?.getGroupDetails(groupJid: groupJid)
        let recentChat = recentChatViewModel?.getRecentChat(jid: groupJid)
        return(group,recentChat)
    }
    
    func checkGroupExistInRecntChat(groupJid : String) -> Bool{
        return showArchivedChat ? getArchiveChat.filter ({$0.jid == groupJid}).first != nil : getRecentChat.filter ({$0.jid == groupJid}).first != nil
    }
}

extension RecentChatViewController : UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        if showPrivateChat == false && getPrivateChats.count > 0 && isSearchEnabled == false && showArchivedChat == false {
            if getRecentChat.count == 0 && getArchiveChat.count == 0 && getPrivateChats.count != 0 {

            } else {
                if scrollView.contentOffset.y < 0 {
                    executeOnMainThread {
                        self.privateChatHeaderView.isHidden = false
                        //self.releaseForPrivateChatHeaderView.isHidden = false
                    }
                } else if scrollView.contentOffset.y > privateChatHeaderView.frame.size.height {
                    executeOnMainThread {
                        self.privateChatHeaderView.isHidden = true
                        self.releaseForPrivateChatHeaderView.isHidden = false
                    }
                }
            }
        }

        let position  = scrollView.contentOffset.y
        print("#scroll #load recentChatList loading done \(position) :: \(recentChatTableView!.contentSize.height) :: \(scrollView.frame.size.height)")
        if !isSearchEnabled{
            
            if (position > (recentChatTableView!.contentSize.height/5)){
                if selectedTagIndex != 0 {
                    print("#scroll #load recentChatList loading done ")
                    return
                }
                
                if !isRecentLoadingInProgress{
                    isRecentLoadingInProgress = true
                  //  backgroundQueue.async { [weak self] in
                    if isRecentLoadingDone == false {
//                        executeInBackground {
                            self.loadNextSetOfData()
//                        }
                    }
                   // }
                }
            }
            
        }
        if ENABLE_CONTACT_SYNC{
            return
        }else{
            
            if position > (recentChatTableView?.contentSize.height ?? 300)-200 - scrollView.frame.size.height {
                if isPaginationCompleted() || selectedTagIndex != 0 {
                    print("#fetch Pagination Done")
                    return
                }
                //recentChatTableView?.tableFooterView = createTableFooterView()
                if !isLoadingInProgress{
                    isLoadingInProgress = true
                    getUsersList(pageNo: searchTerm.isEmpty ? nextPage : searchNextPage, pageSize: chatPageSize, searchTerm: searchTerm)
                }
            }
        }
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if showPrivateChat == false && getPrivateChats.count > 0 && isSearchEnabled == false && showArchivedChat == false {
            if getRecentChat.count == 0 && getArchiveChat.count == 0 && getPrivateChats.count != 0 {

            } else {
                if scrollView.contentOffset.y < 0 {
                    UIView.animate(withDuration: 0.25, animations: {
                        self.recentChatTableView?.contentInset.top = 0
                        self.releaseForPrivateChatHeaderView.isHidden = true
                    })
                } else if scrollView.contentOffset.y > privateChatHeaderView.frame.size.height {
                    UIView.animate(withDuration: 0.25, animations: {
                        self.recentChatTableView?.contentInset.top = -1 * self.privateChatHeaderView.frame.size.height
                    })
                }
            }
        }
    }
    
    func loadNextSetOfData()  {
        //return
        if showArchivedChat == false && showPrivateChat == false {
            print("#scroll loadNextSetOfData")
            recentChatListBuilder?.changeLimit(limit: 20)
//            executeInBackground { [weak self] in
            self.recentChatListBuilder?.nextSetOfData(completionHandler: {  [weak self] isSuccess, error, data in
                    var result = data
                    DispatchQueue.main.async { [weak self] in
                        self?.isRecentLoadingInProgress = false
                    if  let weakSelf = self, let recentChatList = result.getData() as? [RecentChat], isSuccess, !recentChatList.isEmpty{
                        weakSelf.getAllRecentChat.append(contentsOf: recentChatList)
                        weakSelf.getRecentChat.append(contentsOf: recentChatList)
                            if self?.isSearchEnabled == false {
//                                var indexPaths = [IndexPath]()
//                                let section = ChatManager.isArchivedSettingsEnabled() && (self?.getArchiveChat.count ?? 0 > 0) ? 1 : 0
//                                let numberOfRows = (self?.recentChatTableView?.numberOfRows(inSection: section) ?? 0)
//                                for item in numberOfRows...(numberOfRows + recentChatList.count - 1){
//                                    indexPaths.append(IndexPath(row: item, section: section))
//                                }
//                                self?.recentChatTableView?.beginUpdates()
//                                self?.recentChatTableView?.insertRows(at: indexPaths, with: .none)
                                self?.recentChatTableView?.reloadData()
                            }
                            self?.getOverallUnreadCount()
                    }
                }
            })
            //            }
        }
    }
    
    public func getUsersList(pageNo : Int = 1, pageSize : Int =  40, searchTerm : String){
        print("#fetch request \(pageNo) \(pageSize) \(searchTerm) ")
        if !NetStatus.shared.isConnected{
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            return
        }
        if pageNo == 1 {
            recentChatTableView?.tableFooterView = createTableFooterView()
            noNewMsgText?.isHidden = true
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
                    if pageNo == 1{
                        self.filteredContactList.removeAll()
                    }
                    let chatIds = self.getRecentChat.compactMap{$0.jid}
                    var profilesList = profileArray
                    profilesList.removeAll { pd in
                        chatIds.contains(pd.jid)
                    }
                    self.filteredContactList.append(contentsOf: profilesList)
                    profilesCount = profilesList.count
                    
                }
                if profilesCount >= pageSize{
                    self.searchNextPage += 1
                }
                self.searchTotalPages = data["totalPages"] as? Int ?? 1
                self.searchTotalUsers = data["totalRecords"] as? Int ?? 1
                print("#fetch response search total => \(self.searchTotalPages) nextPage => \(self.searchNextPage) searchTotoalUsers => \(self.searchTotalUsers) profilesCount => \(profilesCount) searchTerm => \(self.searchTerm)")
            }else{
                if !NetworkReachability.shared.isConnected{
                    AppAlert.shared.showToast(message: ErrorMessage.noInternet)
                }else{
                    var data = flyData
                    if let message = data.getMessage() as? String{
                        print("#error \(message)")
                    }
                }
            }
            
            self.recentChatTableView?.tableFooterView = nil
            self.recentChatTableView?.reloadData()
            self.showHideEmptyMessage()
            
            self.isLoadingInProgress = false
        }
    }
    
    public func isPaginationCompleted() -> Bool {
        if (searchTotalPages < searchNextPage) || filteredContactList.count == searchTotalUsers {
            return true
        }
        return false
    }
    
    public func resetDataAndFetchUsersList(){
        filteredContactList.removeAll()
        if !isSearchEnabled {
            return
        }
        resetParams()
        DispatchQueue.main.async {
            [weak self] in
            guard let self else{return}
            self.recentChatTableView?.reloadData()
            self.getUsersList(pageNo: 1, pageSize: 20, searchTerm: self.searchTerm)
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
        isFirstPageLoaded = false
    }
    
    public func createTableFooterView() -> UIView{
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 64))
        let spinner = UIActivityIndicatorView()
        spinner.center = footerView.center
        footerView.addSubview(spinner)
        spinner.startAnimating()
        return footerView
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
    }
    
    public func saveUserToDatabase(jid : String){
        if let index = filteredContactList.firstIndex { pd in pd.jid == jid}{
            ContactManager.shared.saveUser(profileDetails: filteredContactList[index], saveAs: .live)
        }
    }
}

//MARK: - Archive chat extension
extension RecentChatViewController {

    //Get status whether is archive or Unarchive
    func isArchive() -> Bool {
        return selectionRecentChatList.filter {$0.isChatArchived == false }.count > 0 ? true : false
    }

    //Update archive icon
    func updateArchiveIcon() {
        archiveChatButton.setImage(isArchive() ? UIImage(named: "archive") : UIImage(named: "unarchive"), for: .normal)
    }

    func hideArchiveHeader() {
        showArchivedChat = false
        showPrivateChat = false
        headerBackButton.isHidden = true
        searchView.isHidden = false
        createGroupButton.isHidden = false
        pinChatButton.isHidden = false
        muteChatButton.isHidden = false
        headerLabel.text = "Chats"
        archiveChatButton.isHidden = false
        readUnreadButton.isHidden = false
        CommonDefaults.isInPrivateChat = false
        contactFloatButton.isHidden = false
        contactFloatView.isHidden = false
    }

    func updateArchiveChatView() {
        self.recentChatTableView?.tableHeaderView = nil
        if getPrivateChats.count > 0 {
            self.recentChatTableView?.contentInset.top = 0
        }
        getArchiveChatList()
        showArchivedChat = true
        showPrivateChat = false
        headerBackButton.isHidden = false
        searchView.isHidden = true
        createGroupButton.isHidden = true
        pinChatButton.isHidden = true
        archiveChatButton.isHidden = false
        readUnreadButton.isHidden = true
       // muteChatButton.isHidden = true
        headerLabel.text = "Archive Chats"
        CommonDefaults.isInPrivateChat = false
        contactFloatButton.isHidden = false
        contactFloatView.isHidden = false
        recentChatTableView?.reloadData()
    }

    func updatePrivateChatView() {
        self.recentChatTableView?.tableHeaderView = nil
        if getPrivateChats.count > 0 {
            self.recentChatTableView?.contentInset.top = 0
        }
        getPrivateChatList()
        showArchivedChat = false
        showPrivateChat = true
        headerBackButton.isHidden = false
        searchView.isHidden = true
        createGroupButton.isHidden = true
        pinChatButton.isHidden = true
        archiveChatButton.isHidden = true
        readUnreadButton.isHidden = false
       // muteChatButton.isHidden = true
        headerLabel.text = "Private Chats"
        CommonDefaults.isInPrivateChat = true
        contactFloatButton.isHidden = true
        contactFloatView.isHidden = true
        recentChatTableView?.reloadData()
    }

}

extension RecentChatViewController: ArchiveEventsDelegate {
    //handle when chat archived/Unarchived
    func updateArchiveUnArchiveChats(toUser: String, archiveStatus: Bool) {
        executeOnMainThread { [ weak self] in
            guard let weakSelf = self else { return }
            weakSelf.getAllChatTags()
            if weakSelf.showArchivedChat {
                if archiveStatus == false {
                    if let index = weakSelf.getArchiveChat.firstIndex(where: { pd in pd.jid == toUser }) {
                        weakSelf.getArchiveChat.remove(at: index)
                        weakSelf.recentChatTableView?.reloadData()
                    }
                    if let recent = ChatManager.getRechtChat(jid: toUser) {
                        var isRecentNotExist = true
                        let tempGetRecent = self?.getRecentChat.filter({$0.jid == recent.jid})
                        if tempGetRecent?.count ?? 0 == 0 {
                            self?.getRecentChat.append(recent)
                        }
                        let tempGetAllRecent = self?.getAllRecentChat.filter({$0.jid == recent.jid})
                        if tempGetAllRecent?.count ?? 0 == 0 {
                            self?.getAllRecentChat.append(recent)
                        }
                        if let tempRecentList = self?.getRecentChat.sorted(by: { $0.lastMessageTime > $1.lastMessageTime }) {
                            self?.getRecentChat = tempRecentList
                        }
                        if let tempRecentList = self?.getRecentChat.sorted(by: { $0.isChatPinned && !$1.isChatPinned }) {
                            self?.getRecentChat = tempRecentList
                        }
                        weakSelf.recentChatTableView?.reloadData()
                    }
                } else {
                    if let recent = ChatManager.getRechtChat(jid: toUser) {
                        if let index = self?.getArchiveChat.firstIndex(where: {$0.lastMessageTime < recent.lastMessageTime }) {
                            weakSelf.getArchiveChat.insert(recent, at: index)
                            weakSelf.recentChatTableView?.reloadData()
                        }
                    }
                    if let index = weakSelf.getRecentChat.firstIndex(where: { pd in pd.jid == toUser }) {
                        weakSelf.getRecentChat.remove(at: index)
                        weakSelf.getAllRecentChat.remove(at: index)
                        weakSelf.recentChatTableView?.reloadData()
                    }
                }
            } else {
                if archiveStatus {
                    if let index = weakSelf.getRecentChat.firstIndex(where: { pd in pd.jid == toUser }) {
                        weakSelf.getRecentChat.remove(at: index)
                        if let allIndex = weakSelf.getAllRecentChat.firstIndex(where: {pd in pd.jid == toUser}) {
                            weakSelf.getAllRecentChat.remove(at: allIndex)
                        }
                        weakSelf.recentChatTableView?.reloadData()
                    }
                } else {
                    if let index = weakSelf.getRecentChat.firstIndex(where: {$0.jid == toUser}) {
                    } else {
                        if let recent = ChatManager.getRechtChat(jid: toUser) {
                            let tempGetRecent = self?.getRecentChat.filter({$0.jid == recent.jid})
                            if tempGetRecent?.count ?? 0 == 0 {
                                self?.getRecentChat.append(recent)
                            }
                            let tempGetAllRecent = self?.getAllRecentChat.filter({$0.jid == recent.jid})
                            if tempGetAllRecent?.count ?? 0 == 0 {
                                self?.getAllRecentChat.append(recent)
                            }
                            if let tempRecentList = self?.getRecentChat.sorted(by: { $0.lastMessageTime > $1.lastMessageTime }) {
                                self?.getRecentChat = tempRecentList
                            }
                            if let tempRecentList = self?.getRecentChat.sorted(by: { $0.isChatPinned && !$1.isChatPinned }) {
                                self?.getRecentChat = tempRecentList
                            }
                            weakSelf.recentChatTableView?.reloadData()
                        }
                    }
                }
            }
        }
    }

    //handle when archived settings changed
    func updateArchivedSettings(archivedSettingsStatus: Bool) {
        executeOnMainThread { [ weak self] in
            self?.recentChatTableView?.reloadData()
        }
    }
}

extension RecentChatViewController : AvailableFeaturesDelegate {
    
    func didUpdateAvailableFeatures(features: AvailableFeaturesModel) {
        
        availableFeatures = features
        searchBar?.isHidden = !(availableFeatures.isRecentChatSearchEnabled) ? true : false
        
        if !(availableFeatures.isRecentChatSearchEnabled){
            refreshRecentChatMessages()
        }
        showHideDeleteButton()
        
        let tabCount =  MainTabBarController.tabBarDelegagte?.currentTabCount()
        
        if (!(availableFeatures.isGroupCallEnabled || availableFeatures.isOneToOneCallEnabled) && tabCount == 5) {
            MainTabBarController.tabBarDelegagte?.removeTabAt(index: 2)
        }else {
            
            if ((availableFeatures.isGroupCallEnabled || availableFeatures.isOneToOneCallEnabled) && tabCount ?? 0 < 5){
                MainTabBarController.tabBarDelegagte?.resetTabs()
            }
            
        }
    }
}

// CollectionViewDelegate
extension RecentChatViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return getChatTags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let chatTag = getChatTags[indexPath.item]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecentTagsCollectionCell", for: indexPath) as! RecentTagsCollectionCell
        cell.setupCell(title: chatTag.tagname ?? "", isSelected: (selectedChatTag?.tagId == chatTag.tagId ||  selectedChatTag == nil && indexPath.item == 0) ? true : false)
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedChatTag = getChatTags[indexPath.item]
        selectedTagIndex = indexPath.item
        emptyMessageView?.isHidden = true
        showOnlyPrivateChatAvailableView(isShow: false)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        self.chatTagsCollectionView.reloadData()
    }
    
    func getAllChatTags() {
        DispatchQueue.init(label: "ChatTag").async{
            ChatManager.getChatTagdata(completionHandler: { isSuccess, error, data in
                if isSuccess {
                    executeOnMainThread {
                        var flyData = data
                        if let chatTags = flyData.getData() as? [ChatTagsModel]{
                            self.getChatTags = chatTags.filter({!$0.isRecommentedTag})
                            self.chatTagsCollectionView.isHidden = self.getChatTags.isEmpty
                            if self.getChatTags.count > 0 {
                                //Add Default tag "All"
                                var chatTagModel = ChatTagsModel()
                                chatTagModel.tagId = AppUtils.getMyJid()
                                chatTagModel.currentUserId = AppUtils.getMyJid()
                                chatTagModel.isRecommentedTag = false
                                chatTagModel.tagname = "All"
                                chatTagModel.memberIdList = []
                                self.getChatTags.insert(chatTagModel, at: 0)
                                self.chatTagsCollectionView.isHidden = self.showArchivedChat ? true : false
                                self.chatTagsCollectionView.isHidden = self.showPrivateChat ? true : false
                            }
                            self.chatTagsCollectionView.reloadData()
                            self.setUpPullForPrivateChat()
                            //self.recentChatTableView?.reloadData()
                    }
                    }
                }
            })
        }
    }
    
    func getRecentChatForSelectedChatTag(chatTag: ChatTagsModel?) {
        if !isSearchEnabled {
            guard let chatTag else {return}
            getRecentChat.removeAll()
            for memberID in chatTag.memberIdList {
                if let member = ChatManager.getRecentChatOf(jid: memberID) {
                    if !member.isChatArchived && !member.isPrivateChat {
                        getRecentChat.append(member)
                    }
                    getRecentChat = getRecentChat.sorted(by: { $0.lastMessageTime < $1.lastMessageTime}).reversed()
                    getRecentChat = getRecentChat.sorted(by: { $0.isChatPinned && !$1.isChatPinned })
                    self.selectionRecentChatList.enumerated().forEach { (index,selectedRecentChat) in
                        self.getRecentChat.filter({$0.jid == selectedRecentChat.jid}).first?.isSelected = selectedRecentChat.isSelected
                    }
                    
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                if self?.isSearchEnabled == false {
                    self?.showHideEmptyMessage()
                }
                self?.getOverallUnreadCount()
            }
        }
    }
    
    func updateChatTagsUserList(jids: [String]) {
        
        if getChatTags.count > 0 {
            
                for chatTag in getChatTags {
                    
                   if chatTag.tagId != AppUtils.getMyJid() {
                       
                       let removeSet = Set(jids)
                      
                        var chatTagModel = ChatTagsModel()
                        chatTagModel = chatTag
                        chatTagModel.memberIdList = chatTag.memberIdList.filter { !removeSet.contains($0) }
                        
                        ChatManager.createOrUpdateChatTagdata(chatTag: chatTagModel) { isSuccess, error, data in
                            
                        }
                    }
                }
        }
    }
}

extension RecentChatViewController: PrivateChatDelegate {

    func onPasswordSet() {

    }
    func onPrivateChatAlertSelected(option: String) {

    }
    func onPrivateChatAuthenticated() {
        updatePrivateChatView()
        recentChatTableView?.reloadData()
    }

    func pinChanged() {
        updatePrivateChatView()
        recentChatTableView?.reloadData()
    }
}
