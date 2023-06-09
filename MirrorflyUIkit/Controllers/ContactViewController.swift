//  ContactViewController.swift
//  MirrorflyUIkit
//  Created by User on 11/08/21.


import UIKit
import MirrorFlySDK
import SDWebImage
import Contacts
import RxSwift

class ContactViewController: UIViewController {
    @IBOutlet weak var profilePopupContainer: UIView!
    @IBOutlet weak var profilePopup: UIView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var bottomBtn: UIButton!
    @IBOutlet weak var searchTxt: UISearchBar!
    @IBOutlet weak var contactList: UITableView!
    @IBOutlet weak var bottomBtnHeight: NSLayoutConstraint!
    @IBOutlet weak var headerVIewHeight: NSLayoutConstraint!
    @IBOutlet weak var topBarViewHeight: NSLayoutConstraint!
    @IBOutlet weak var serachFieldTopMargin: NSLayoutConstraint!
    @IBOutlet weak var titleLable: UILabel!
    @IBOutlet weak var headerView: UIView?
    
    var allContacts =  [ProfileDetails]()
    var contacts = [ProfileDetails]() {
        didSet {
            executeOnMainThread { [weak self] in
                guard let self else {return}
                self.contactList.reloadData()
            }
        }
    }
    var selectectProfiles = [ProfileDetails]()
    var selectedProfilesJid = NSMutableArray()
    var synced = false
    var isLocalCalled = false
    var currentIndex = -1
    var isMultiSelect = false
    var makeCall = false
    var isInvite = false
    var callType : CallType = .Audio
    var replyMessageObj: ChatMessage?
    var replyJid: String?
    var messageTxt: String?
    var replyTagDelegate: ReplyMessagesDelegate?
    var hideNavigationbar = false
    var tappedProfile : ProfileDetails? = nil
    var groupJid : String = ""
    var callUsers : [String] = []
    var callLink: String = ""

    var isGroupBlockedByAdmin : Bool = false

    var permissionDialogShowedOnViewDidLoad = false
    
    var refreshDelegate : RefreshProfileInfo? = nil
    
    public var profileCount = Int()
    //var randomColors = [UIColor?]()
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
                                    #selector(ContactViewController.handleRefresh(_:)),
                                 for: UIControl.Event.valueChanged)
        refreshControl.tintColor = UIColor.gray
        return refreshControl
    }()
    private var contactViewModel : ContactViewModel!
    
    
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
    var networkLabel : UILabel? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setUpStatusBar()
        handleBackgroundAndForground()
        configureDefaults()
        bottomBtn.isEnabled = false
        bottomBtn.setTitleColor(UIColor.white, for: .normal)
        bottomBtn.setTitleColor(UIColor.white, for: .disabled)
        if makeCall || isMultiSelect {
            bottomBtnHeight.constant = 48
            bottomBtn.backgroundColor = UIColor.lightGray
            if isInvite {
                bottomBtn.setTitle("Add Participants", for: .normal)
            }else{
                bottomBtn.setTitle("Call Now", for: .normal)
            }
        }else{
            bottomBtnHeight.constant = 0
        }
        if isInvite{
            callUsers.append(contentsOf: CallManager.getCallUsersList() ?? [])
        }
        if isInvite || !groupJid.isEmpty{
            if isInvite{
                self.title = "Add participants"
            }else{
                self.title = "Participants"
            }
        }
        searchSubject.throttle(.milliseconds(25), scheduler: MainScheduler.instance).distinctUntilChanged().subscribe { [weak self] term in
            self?.searchTerm = term
            self?.allContacts.removeAll()
            self?.contacts.removeAll()
            self?.contactList.reloadData()
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
                    self.networkLabel?.isHidden = true
                }
            case .error(let error):
                print("#contactSync error \(error.localizedDescription)")
            case .completed:
                print("#contactSync completed")
            }
            
        }.disposed(by: disposeBag)
        networkLable(message: ErrorMessage.noInternet)
    }
    @objc override func willCometoForeground() {
        if ENABLE_CONTACT_SYNC || !groupJid.isEmpty{
            getCotactFromLocal(fromServer: true)
        }else{
            resetDataAndFetchUsersList()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.setNavigationBarHidden(!hideNavigationbar, animated: true)
        if hideNavigationbar {
            CallManager.onCallStatusDelegate = self
            headerVIewHeight.constant = 0
            topBarViewHeight.constant = 48
            serachFieldTopMargin.constant = 0
        }else{
            headerVIewHeight.constant = 50
            topBarViewHeight.constant = 98
            serachFieldTopMargin.constant = 4
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.methodOfReceivedNotification(notification:)), name: Notification.Name(Identifiers.ncContactRefresh), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.contactSyncCompleted(notification:)), name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(networkChange(_:)),name:Notification.Name(NetStatus.networkNotificationObserver),object: nil)
        if ENABLE_CONTACT_SYNC || !groupJid.isEmpty || searchTxt.text != "" {
            getCotactFromLocal(fromServer: false)
        }else{
            resetDataAndFetchUsersList()
        }
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("#content \(permissionDialogShowedOnViewDidLoad)")
        ContactManager.shared.profileDelegate = self
        
        ChatManager.shared.adminBlockDelegate = self
        ChatManager.shared.availableFeaturesDelegate = self
        
        if !permissionDialogShowedOnViewDidLoad && groupJid.isEmpty{
            showContactPermissionAlert(showDialogONly: true)
        }
        permissionDialogShowedOnViewDidLoad = false
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        navigationController?.setNavigationBarHidden(true, animated: false)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NetStatus.networkNotificationObserver), object: nil)
        replyTagDelegate?.replyMessageObj(message: replyMessageObj, jid: replyJid ?? "", messageText: messageTxt ?? "")
        ContactManager.shared.profileDelegate = nil
        ChatManager.shared.adminBlockDelegate = nil
        ChatManager.shared.availableFeaturesDelegate = nil
    }
    
    func setupUI() {
        navigationController?.view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(!hideNavigationbar, animated: false)
        profilePopupContainer.isHidden = true
        self.title = contact
        userName.font = UIFont.font22px_appSemibold()
        searchTxt.placeholder = search
        contactList.estimatedRowHeight = 60
        contactList.tableFooterView = UIView()
    }
    
    func configureDefaults() {
        contactViewModel =  ContactViewModel()
        searchTxt.delegate = self
        self.contactList.addSubview(self.refreshControl)
        permissionDialogShowedOnViewDidLoad = true
        if ENABLE_CONTACT_SYNC && groupJid.isEmpty{
            showContactPermissionAlert()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        profilePopupContainer.addGestureRecognizer(tap)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        if NetworkReachability.shared.isConnected {
            if groupJid.isEmpty{
                showContactPermissionAlert()
            }else{
                refreshContacts()
            }
        }else {
            refreshControl.endRefreshing()
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
        }
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        UIView.transition(with: profilePopupContainer, duration: 0.5, options: .transitionFlipFromLeft, animations: { [weak self] in
            self?.profilePopupContainer.isHidden = true
        })
    }
    
    @objc func methodOfReceivedNotification(notification: Notification) {
        if (self.view.window != nil) {
            getCotactFromLocal(fromServer: false)
        }
    }
    
    @objc func contactSyncCompleted(notification: Notification){
        if let contactSyncState = notification.userInfo?[FlyConstants.contactSyncState] as? String {
            switch ContactSyncState(rawValue: contactSyncState) {
            case .inprogress:
                refreshControl.startRotating()
            case .success:
                refreshControl.endRefreshing()
                getCotactFromLocal(fromServer: false)
            case .failed:
                refreshControl.endRefreshing()
                print("contact sync failed")
            case .none:
                print("contact sync failed")
            }
        }
    }
    
    func getCotactFromLocal(fromServer: Bool) {
        if ENABLE_CONTACT_SYNC && CNContactStore.authorizationStatus(for: CNEntityType.contacts) == .denied && groupJid.isEmpty{
            contacts.removeAll()
            allContacts.removeAll()
//            contactList.reloadData()
            return
        }
        print("#image getCotactFromLocal")
        var profileDetails = [ProfileDetails]()
        if groupJid.isEmpty{
            if fromServer{
                contactViewModel.getContacts(fromServer: true, removeContacts: callUsers) { [weak self] (profiles, error)  in
                    if error != nil {
                        return
                    }
                    if  let  contactsList = profiles {
                        profileDetails.append(contentsOf: contactsList)
                        self?.reloadTableView(profileDetails: profileDetails)
                    }
                }
            }
            contactViewModel.getContacts(fromServer: false,removeContacts: callUsers) { [weak self] (profiles, error)  in
                if error != nil {
                    return
                }
                if  let  contactsList = profiles {
                    profileDetails.append(contentsOf: contactsList)
                    self?.reloadTableView(profileDetails: profileDetails)
                }
            }
        }else{
            var groupMembers =  GroupManager.shared.getGroupMemebersFromLocal(groupJid: groupJid).participantDetailArray.filter({$0.memberJid != FlyDefaults.myJid && $0.profileDetail?.isBlockedByAdmin == false})
            if isInvite{
                groupMembers.removeAll { member in
                    callUsers.contains(member.memberJid)
                }
            }
            for item in groupMembers{
                if let pd = item.profileDetail{
                    profileDetails.append(pd)
                }
            }
            reloadTableView(profileDetails: profileDetails)
        }
    }
    
    func reloadTableView(profileDetails: [ProfileDetails]){
        DispatchQueue.main.async { [weak self] in
            self?.allContacts.removeAll()
            self?.contacts.removeAll()
            self?.allContacts = profileDetails.sorted { getUserName(jid: $0.jid,name: $0.name, nickName: $0.nickName, contactType: $0.contactType).capitalized < getUserName(jid: $1.jid, name: $1.name, nickName: $1.nickName,contactType: $1.contactType).capitalized }
            let searchString = self?.searchTxt.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            let contactDetails = searchString?.count == 0 ? self?.allContacts : self?.allContacts.filter { term in
                return getUserName(jid: term.jid ,name: term.name, nickName: term.nickName, contactType: term.contactType).lowercased().contains(searchString?.lowercased() ?? "")
            }
            self?.contacts = contactDetails ?? []
            let index = self?.currentIndex
            let count = self?.contacts.count
            if index ?? 0 > -1  && index ?? 0 < count ?? 0 {
                self?.userName.text = self?.contacts[index ?? 0].name
                self?.setProfile()
            }
            self?.refreshControl.endRefreshing()
        }
    }
    
    func refreshContacts() {
        if ENABLE_CONTACT_SYNC && CNContactStore.authorizationStatus(for: CNEntityType.contacts) == .denied && groupJid.isEmpty || FlyDefaults.isContactPermissionSkipped && ENABLE_CONTACT_SYNC{
            contacts.removeAll()
            allContacts.removeAll()
            return
        }
        if !groupJid.isEmpty{
            refreshControl.endRefreshing()
            return
        }
        searchTxt.resignFirstResponder()
        searchTxt.setShowsCancelButton(false, animated: true)
        searchTxt.text = ""
        if ENABLE_CONTACT_SYNC{
            contactViewModel.getContacts(fromServer: synced, removeContacts: callUsers) { [weak self] (profiles, error) in
                guard let weakSelf = self else { return }
                weakSelf.refreshControl.endRefreshing()
                weakSelf.synced = true
                if profiles?.count == 0 {
                    if  !weakSelf.isLocalCalled {
                        weakSelf.isLocalCalled  = true
                        weakSelf.refreshContacts()
                    }
                }
                if error == nil {
                    if  let  contactsList = profiles {
                        weakSelf.allContacts.removeAll()
                        weakSelf.contacts.removeAll()
                        weakSelf.allContacts = contactsList.sorted { getUserName(jid: $0.jid,name: $0.name, nickName: $0.nickName, contactType: $0.contactType).capitalized < getUserName(jid: $1.jid,name: $1.name, nickName: $1.nickName,contactType: $1.contactType).capitalized }
                        weakSelf.contacts = weakSelf.allContacts
                    }
                }
                // weakSelf.randomColors = AppUtils.shared.setRandomColors(totalCount: weakSelf.contacts.count)
                if error != nil {
                    weakSelf.refreshControl.endRefreshing()
                }
            }
        }else{
            resetDataAndFetchUsersList()
        }
    }
    
    @objc func closeKeyboard() {
        self.view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            contactList.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height + contactList.rowHeight, right: 0)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        contactList.contentInset = .zero
    }
    
    @IBAction func bottomBtnTapped(_ sender: Any) {
        if makeCall{
            makeFlyCall()
        }
    }
    
    @objc func imageButtonAction(_ sender:UIButton) {
        closeKeyboard()
        UIView.transition(with: profilePopupContainer, duration: 0.5, options: .transitionCrossDissolve, animations: { [weak self] in
            self?.profilePopupContainer.isHidden = false
        })
        
        let buttonTag = sender.tag
        currentIndex = buttonTag
        setProfile()
        
    }
    
    @objc
    func openContainerImage(sender: UITapGestureRecognizer? = nil) {
        if let controller = UIStoryboard.init(name: Storyboards.chat, bundle: Bundle.main).instantiateViewController(withIdentifier: "ViewUserImageController") as? ViewUserImageController {
            
            guard let getRecentChatJID = contacts[currentIndex].jid else {
                return
            }
            guard let getRecentChatProfile = ContactManager.shared.getUserProfileDetails(for: getRecentChatJID) else {
                return
            }
            
            let profile = contacts[currentIndex]
            controller.profileDetails?.jid = profile.jid
            controller.profileDetails = getRecentChatProfile
            controller.navigationController?.modalPresentationStyle = .overFullScreen
            profilePopupContainer.isHidden = true
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func setProfile() {
        if !(currentIndex > -1) || !(contacts.count > currentIndex){
            return
        }
        tappedProfile = contacts[currentIndex]
        if let profile =  tappedProfile{
            let name = getUserName(jid: profile.jid,name: profile.name, nickName: profile.nickName, contactType: profile.contactType)
            self.userName.text = name
            let urlString = FlyDefaults.baseURL + "media/" + profile.image + "?mf=" + FlyDefaults.authtoken
            var url = URL(string: urlString)
            var placeholder : UIImage?
            switch profile.profileChatType {
            case .groupChat:
                placeholder = UIImage(named: "smallGroupPlaceHolder")
            default:
                if profile.jid == FlyDefaults.myJid || getIsBlockedByMe(jid: profile.jid) || (IS_LIVE && ENABLE_CONTACT_SYNC && profile.isItSavedContact == false) {
                    url = nil
                    placeholder = UIImage(named: "ic_profile_placeholder")
                    userImage?.backgroundColor =  Color.groupIconBackgroundGray
                } else {
                    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let ipimage = IPImage(text: trimmedName, radius: Double(userImage.frame.size.height), font: UIFont.font84px_appBold(),
                                          textColor: nil, color: getColor(userName: name))
                    placeholder = ipimage.generateInitialImage()
                    userImage.backgroundColor = ChatUtils.getColorForUser(userName: name)
                }
            }
            if profile.contactType == .deleted || getIsBlockedByMe(jid: profile.jid) || profile.isBlockedByAdmin || (IS_LIVE && ENABLE_CONTACT_SYNC && profile.isItSavedContact == false){
                url = nil
                placeholder = UIImage(named: "ic_profile_placeholder")
                userImage?.backgroundColor =  Color.groupIconBackgroundGray
            }
            if !contacts.isEmpty {
                tappedProfile = contacts[currentIndex]
                if let profile =  tappedProfile{
                    let name = getUserName(jid: profile.jid,name: profile.name, nickName: profile.nickName, contactType: profile.contactType)
                    self.userName.text = name
                    userImage.loadFlyImage(imageURL: profile.image, name: name, chatType: profile.profileChatType, jid: profile.jid)
                }
            }
          
            userImage.sd_setImage(with: url, placeholderImage: placeholder)
            if userImage?.image == placeholder {
                userImage?.isUserInteractionEnabled = false
                profilePopupContainer?.isHidden = false
            } else {
                let tap = UITapGestureRecognizer(target: self, action: #selector(self.openContainerImage(sender:)))
                userImage?.isUserInteractionEnabled = true
                userImage?.addGestureRecognizer(tap)
            }
        }
    }
    
    func getPlaceholder(name: String, color: UIColor)-> UIImage {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let ipimage = IPImage(text: trimmedName, radius: Double(userImage.frame.size.height), font: UIFont.font84px_appBold(), textColor: nil, color: color)
        let placeholder = ipimage.generateInitialSqareImage()
        return placeholder ?? #imageLiteral(resourceName: "ic_profile_placeholder")
    }
    
    @IBAction func message(_ sender: Any) {
        openChat(index: currentIndex)
        profilePopupContainer?.isHidden = true
    }
    
    @IBAction func call(_ sender: Any) {
        let profile = contacts[currentIndex]
        if CallManager.isAlreadyOnAnotherCall(){
            AppAlert.shared.showToast(message: "You’re already on call, can't make new Mirrorfly call")
            return
        }
        if !NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            return
        }
        let callType = CallType.Audio
        if profile.profileChatType == .singleChat{
            if profile.contactType != .deleted {
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
        let profile = contacts[currentIndex]
        if CallManager.isAlreadyOnAnotherCall(){
            AppAlert.shared.showToast(message: "You’re already on call, can't make new Mirrorfly call")
            return
        }
        let callType = CallType.Video
        if profile.profileChatType == .singleChat{
            if profile.contactType != .deleted {
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
        let profile = contacts[currentIndex]
        if profile.profileChatType == .singleChat{
            let vc = UIStoryboard.init(name: Storyboards.chat, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.contactInfoViewController) as? ContactInfoViewController
            vc?.contactJid = profile.jid
            vc?.navigationController?.modalPresentationStyle = .overFullScreen
            self.navigationController?.pushViewController(vc!, animated: true)
        }
        profilePopupContainer?.isHidden = true
        
    }
    
    func showContactPermissionAlert(showDialogONly : Bool = false){
        
        let contactPermissionStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        
        if FlyDefaults.isContactPermissionSkipped && contactPermissionStatus == .authorized{
            syncSkippedDialog()
        }else if ENABLE_CONTACT_SYNC {
            
            if contactPermissionStatus == .authorized{
                if !showDialogONly{
                    refreshContacts()
                    refreshControl.endRefreshing()
                }
            } else if contactPermissionStatus == .denied{
                allContacts.removeAll()
                contacts.removeAll()
                contactList.reloadData()
                alertContactAccessNeeded()
            } else if (contactPermissionStatus == .restricted || contactPermissionStatus == .notDetermined){
                CNContactStore().requestAccess(for: .contacts){ [weak self] (access, error)  in
                    executeOnMainThread {
                        FlyDefaults.isContactPermissionSkipped = false
                        self?.contactViewModel.syncContacts()
                        self?.refreshControl.endRefreshing()
                    }
                }
            }
        } else{
            if !showDialogONly{
                refreshContacts()
            }
        }
    }
    
    func alertContactAccessNeeded() {
        let settingsAppURL = URL(string: UIApplication.openSettingsURLString)!
        let alert = UIAlertController(
            title: "Need Contacts permission",
            message: "Contacts access has been denied. Kindly enable contact access in app settings.",
            preferredStyle: UIAlertController.Style.alert
        )
        alert.addAction(UIAlertAction(title: "Go to settings", style: .default, handler: { (alert) -> Void in
            executeOnMainThread {
                UIApplication.shared.open(settingsAppURL, options: [:], completionHandler: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Don't  Allow ", style: .cancel, handler: { (alert) -> Void in
            executeOnMainThread {
                self.refreshControl.endRefreshing()
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func syncSkippedDialog() {
        let alert = UIAlertController(title: "Sync Contacts", message: "Do you allow the app to read and sync contacts?",
                                      preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (alert) -> Void in
            executeOnMainThread { [weak self] in
                FlyDefaults.isContactPermissionSkipped = false
                self?.contactViewModel.syncContacts()
            }
        }))
        alert.addAction(UIAlertAction(title: "No ", style: .cancel, handler: { (alert) -> Void in
            executeOnMainThread {
                self.refreshControl.endRefreshing()
            }
        }))
        present(alert, animated: true, completion: nil)
    }
}

extension ContactViewController: CallStatusContactDelegate {
    func onCallAction(callAction: CallAction, userId: String) {
        switch callAction {
        case .ACTION_REMOTE_BUSY :
            callUsers.removeAll { user in
                user == userId
            }
            resetParams()
            allContacts.removeAll()
            contacts.removeAll()
            contactList.reloadData()
            getUsersList(pageNo: 1, pageSize: 20, searchTerm: searchTerm)
            
        default: break
        }
    }
    func onCallStatusUpdated(callStatus: CALLSTATUS, userId: String) {
        switch callStatus {
        case .DISCONNECTED,.USER_LEFT,.CALL_TIME_OUT,.INVITE_CALL_TIME_OUT:
            callUsers.removeAll { user in
                user == userId
            }
            resetParams()
            allContacts.removeAll()
            contacts.removeAll()
            contactList.reloadData()
            getUsersList(pageNo: 1, pageSize: 20, searchTerm: searchTerm)
        default: break
        }
    }
}

// SearchBar Delegate Method
extension ContactViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String){
        if ENABLE_CONTACT_SYNC{
            scrollToTableViewTop()
            let searchString = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            contacts = searchString.isEmpty ? allContacts : allContacts.filter { term in
                return getUserName(jid: term.jid ,name: term.name, nickName: term.nickName, contactType: term.contactType).lowercased().contains(searchString.lowercased())
            }
        }else{
            let searchString = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !searchString.isEmpty || self.searchTerm != searchString{
                resetParams()
                if isInvite && !groupJid.isEmpty {
                    contacts = searchString.isEmpty ? allContacts : allContacts.filter { term in
                        return getUserName(jid: term.jid ,name: term.name, nickName: term.nickName, contactType: term.contactType).lowercased().contains(searchString.lowercased())
                    }
                    isFirstPageLoaded = (contacts.count == 0) ? true : false
                   
                }else {
                    searchSubject.onNext("\(searchString.lowercased().utf16)")
                }
            }else {
                if isInvite && !groupJid.isEmpty {
                    contacts = allContacts
                    searchBar.resignFirstResponder()
                }
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchTxt.setShowsCancelButton(false, animated: true)
        searchTxt.text = ""
        searchTerm = emptyString()
        if ENABLE_CONTACT_SYNC || !groupJid.isEmpty{
            contacts = allContacts
        }else{
            resetDataAndFetchUsersList()
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        scrollToTableViewTop()
        searchTxt.setShowsCancelButton(true, animated: true)
    }
    
    func scrollToTableViewTop() {
        self.contactList?.setContentOffset(.zero, animated: false)
    }
}

//Tableview Delegate
extension ContactViewController :  UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return isInvite ? 110 : 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = UIView.init(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 110))
       
        
        let titleLable = UILabel.init(frame: CGRect(x: 20, y: 5, width: tableView.frame.size.width - 40, height: 30))
        titleLable.textColor = Color.color_181818
        titleLable.font = UIFont.font14px_appSemibold()
        titleLable.text = "Call Link"
        headerView.addSubview(titleLable)
        
        let profileImg = UIImageView.init(frame: CGRect(x: 20, y: CGRectGetMaxY(titleLable.frame) + 5, width: 50, height: 50))
        profileImg.backgroundColor = Color.color_AFBDDF
        profileImg.image = UIImage(named: "icon_link")
        profileImg.contentMode = .scaleAspectFit
        profileImg.layer.cornerRadius = 50/2
        profileImg.layer.masksToBounds = true
        headerView.addSubview(profileImg)
        
        let linkLable = UILabel.init(frame: CGRect(x: CGRectGetMaxX(profileImg.frame) + 10, y: CGRectGetMaxY(titleLable.frame) + 5, width: headerView.frame.size.width - 180, height: 50))
        linkLable.textColor = Color.color_181818
        linkLable.font = UIFont.font14px_appSemibold()
        linkLable.text = callLink
        headerView.addSubview(linkLable)
        
        let copyButton = UIImageView.init(frame: CGRect(x: headerView.frame.size.width - 40, y:  CGRectGetMinY(profileImg.frame) + 10, width: 20, height: 20))
        copyButton.isUserInteractionEnabled = true
        copyButton.image = UIImage(named: "copy_link")
        copyButton.contentMode = .scaleAspectFit
        headerView.addSubview(copyButton)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTapWithCopy(_:)))
        copyButton.addGestureRecognizer(tap)
        
        
        let borderView = UIView.init(frame: CGRect(x: 20, y: CGRectGetMaxY(headerView.frame) - 5, width: headerView.frame.size.width - 20, height: 1))
        borderView.backgroundColor = Color.recentChatSelectionColor
        headerView.addSubview(borderView)
        
        return headerView
        
    }
    
    @objc func handleTapWithCopy(_ sender: UITapGestureRecognizer? = nil) {
        
        let board = UIPasteboard.general
        board.string = "\(WEB_LOGIN_URL)\(callLink)"
        AppAlert.shared.showToast(message: "Link copied to clipboard")
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if contacts.count > 0 {
            return contacts.count
        }else {
            if ENABLE_CONTACT_SYNC || isFirstPageLoaded{
                return 1
            }
            return 0
        }
    }
    
    private func getBlocked(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlocked ?? false
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if contacts.count > 0 && indexPath.row < contacts.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.contactCell) as! ContactCell
            cell.selectionStyle = .none
            let profile = contacts[indexPath.row]
            if getBlocked(jid: profile.jid) && isMultiSelect {
                cell.contentView.alpha = 0.6
            } else {
                cell.contentView.alpha = 1.0
            }
            let name = getUserName(jid: profile.jid,name: profile.name, nickName: profile.nickName, contactType: profile.contactType)
            cell.profileButton.tag = indexPath.row
            cell.profileButton.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
            cell.name.text = name
            cell.status.text = profile.status
            if getIsBlockedByMe(jid: profile.jid) || (IS_LIVE && ENABLE_CONTACT_SYNC && profile.isItSavedContact == false) {
                cell.profile.image = UIImage(named: "ic_profile_placeholder")
                cell.status.text = ""
                cell.status.isHidden = true
            } else {
                cell.status.isHidden = false
                cell.status.text = profile.status
                let profileImage = profile.thumbImage.isEmpty ? profile.image : profile.thumbImage
                cell.profile.loadFlyImage(imageURL: profileImage, name: name, contactType: profile.contactType, jid: profile.jid)
            }
            cell.checkBox.tag = indexPath.row
            cell.checkBox.isSelected = selectedProfilesJid.contains(profile.jid ?? "")
            cell.checkBox.isHidden = !isMultiSelect
            cell.setTextColorWhileSearch(searchText: (searchTxt.text ?? "").trim(), profile: profile)
            cell.setLastContentTextColor(searchText: "", profile: profile)
            return cell
        }else {
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.noContacts)
            cell?.textLabel?.font = UIFont.font15px_appMedium()
            cell?.textLabel?.textAlignment = .center
            if ENABLE_CONTACT_SYNC{
                cell?.textLabel?.text = ErrorMessage.noContactsFound
            }else{
                if NetworkReachability.shared.isConnected{
                    if isFirstPageLoaded{
                        cell?.textLabel?.text = "No Contacts Found"
                    }else{
                        cell?.textLabel?.text = ""
                    }
                }else{
                    cell?.textLabel?.text = "\(ErrorMessage.noInternet)"
                }
            }
            cell?.isUserInteractionEnabled = false
            return cell!
        }
    }
    
    func hash(_ string: String) -> Int {
        func djb(_ string: String) -> Int {
            
            return string.utf8
                .map {return $0}
                .reduce(5381) {
                    ($0 << 5) &+ $0 &+ Int($1)
                }
        }
        
        return djb(string)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isMultiSelect {
            if makeCall {
                let profile = contacts[indexPath.row]
                if getBlocked(jid: profile.jid) {
                    showBlockUnblockConfirmationPopUp(jid: profile.jid, name: profile.nickName)
                    return
                }
                ContactManager.shared.saveUser(profileDetails: profile)
                if (CallManager.getCallUsersList()?.count ?? 0) + selectedProfilesJid.count  == 7  && !selectedProfilesJid.contains(profile.jid!) {
                    self.showMaximumMemberAlert()
                }else{
                    if selectedProfilesJid.contains(profile.jid!) {
                        selectedProfilesJid.remove(profile.jid!)
                    } else {
                        selectedProfilesJid.add(profile.jid!)
                    }
                    let cell = tableView.cellForRow(at: indexPath) as! ContactCell
                    cell.checkBox.isSelected = selectedProfilesJid.contains(profile.jid!)
                    
                }
                updateBottomButton()
            }else{
                // TODO
            }
        }else{
            openChat(index: indexPath.row)
        }
    }
    
    func showMaximumMemberAlert() {
        
        let alertController = UIAlertController(title: "Alert", message: "Only upto 8 members are allowed for a call (including the caller)", preferredStyle: .alert)
            
               let removeAction = UIAlertAction(title: "Ok", style: .default) { (action:UIAlertAction!) in
                   
               }
        
               alertController.addAction(removeAction)
               self.present(alertController, animated: true, completion:nil)
    }
    
    func openChat(index: Int) {
        if !contacts.isEmpty {
            let profile = contacts[index]
            let vc = UIStoryboard.init(name: Storyboards.chat, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.chatViewParentController) as? ChatViewParentController
            vc?.getProfileDetails = profile
            let color = getColor(userName: profile.name)
            vc?.contactColor = color
            vc?.replyJid = replyJid
            vc?.replyMessageObj = replyMessageObj
            vc?.replyMessagesDelegate = self
            vc?.messageText = messageTxt
            ContactManager.shared.saveUser(profileDetails: profile, saveAs: .live)
            navigationController?.modalPresentationStyle = .fullScreen
            guard let viewController = vc else { return }
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    @objc func buttonSelected(sender: UIButton){
        let profile = contacts[sender.tag]
        if selectectProfiles.contains(profile) {
            if  let indx = selectectProfiles.firstIndex(of: profile) {
                selectectProfiles.remove(at: indx)
                contactList.reloadData()
            }
        }else{
            selectectProfiles.append(profile)
            contactList.reloadData()
        }
    }
    
    private func getIsBlockedByMe(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlockedMe ?? false
    }
    
    func updateBottomButton() {
        if makeCall{
            var btnTitle = "Call Now"
            if selectedProfilesJid.count == 0 {
                if isInvite {
                    btnTitle = "Add Participants"
                }
            } else {
                if isInvite {
                    btnTitle = "Add Participants (\(selectedProfilesJid.count))"
                }else{
                    btnTitle = "Call Now (\(selectedProfilesJid.count))"
                }
            }
            bottomBtn.setTitle(btnTitle, for: .normal)
            bottomBtn.isEnabled = selectedProfilesJid.count > 0
            bottomBtn.backgroundColor = (selectedProfilesJid.count > 0) ? UIColor.systemBlue : UIColor.lightGray
        }
    }
    
}

extension ContactViewController : ProfileEventsDelegate {
    func userCameOnline(for jid: String) {
        
    }
    
    func userWentOffline(for jid: String) {
        
    }
    
    func userProfileFetched(for jid: String, profileDetails: ProfileDetails?) {
        
    }
    
    func myProfileUpdated() {
        
    }
    
    func usersProfilesFetched() {
        if ENABLE_CONTACT_SYNC{
            getCotactFromLocal(fromServer: false)
        }
        setProfile()
    }
    
    func blockedThisUser(jid: String) {
        
    }
    
    func unblockedThisUser(jid: String) {
        
    }
    
    func usersIBlockedListFetched(jidList: [String]) {
        
    }
    
    func usersBlockedMeListFetched(jidList: [String]) {
//        for jid in jidList{
//            if let blockedIndex = contacts.firstIndex(where: { profile in
//                profile.jid == jid
//            }) {
//                contactList.reloadRows(at: [IndexPath(row: blockedIndex, section: 0)], with: .none)
//            }
//        }
        contactList.reloadData()
    }
    
    func userUpdatedTheirProfile(for jid: String, profileDetails: ProfileDetails) {
        print("userUpdatedTheirProfile \(jid)")
        if  let index = allContacts.firstIndex(where: { pd in pd.jid == jid }) {
            allContacts[index] = profileDetails
            print("userUpdatedTheirProfile currentIndex \(currentIndex)")
            let profile = ["jid": profileDetails.jid, "name": profileDetails.name, "image": profileDetails.image, "status": profileDetails.status, "thumbImage": profileDetails.thumbImage]
            NotificationCenter.default.post(name: Notification.Name(Identifiers.ncProfileUpdate), object: nil, userInfo: profile as [AnyHashable : Any])
            NotificationCenter.default.post(name: Notification.Name(FlyConstants.contactSyncState), object: nil, userInfo: profile as [AnyHashable : Any])
            if let index = contacts.firstIndex(where: { pd in pd.jid == jid })  {
                contacts[index] = profileDetails
                let indexPath = IndexPath(item: index, section: 0)
                contactList?.reloadRows(at: [indexPath], with: .fade)
                if let tappedPd = tappedProfile, tappedPd.jid == profileDetails.jid{
                    currentIndex = index
                    setProfile()
                }
            }else{
                let indexPath = IndexPath(item: index, section: 0)
                contactList?.reloadRows(at: [indexPath], with: .fade)
                if let tappedPd = tappedProfile, tappedPd.jid == profileDetails.jid{
                    currentIndex = index
                    setProfile()
                }
            }
        }
    }
    
    func userBlockedMe(jid: String) {
        getCotactFromLocal(fromServer: false)
        if let blockedIndex = contacts.firstIndex(where: { profile in
            profile.jid == jid
        }) {
            contactList.reloadRows(at: [IndexPath(row: blockedIndex, section: 0)], with: .none)
        }
        setProfile()
    }
    
    func userUnBlockedMe(jid: String) {
        getCotactFromLocal(fromServer: false)
        if let unBlockedIndex = contacts.firstIndex(where: { profile in
            profile.jid == jid
        }) {
            contactList.reloadRows(at: [IndexPath(row: unBlockedIndex, section: 0)], with: .none)
        }
        setProfile()
    }
    
    func hideUserLastSeen() {
        
    }
    
    func getUserLastSeen() {
        
    }
    
    func userDeletedTheirProfile(for jid : String, profileDetails:ProfileDetails){
        if ENABLE_CONTACT_SYNC{
            getCotactFromLocal(fromServer: false)
        }else{
            allContacts.removeAll { pd in
                pd.jid == jid
            }
            contacts.removeAll { pd in
                pd.jid == jid
            }
            contactList.reloadData()
        }
        if isMultiSelect{
            if selectedProfilesJid.contains(jid) {
                selectedProfilesJid.remove(jid)
                contactList.reloadData()
            }
        }
        if isInvite{
            if CallManager.isOneToOneCall() && CallManager.getAllCallUsersList().contains(jid){
                self.navigationController?.popViewController(animated: true)
                refreshDelegate?.refreshProfileDetails(profileDetails: profileDetails)
                refreshDelegate = nil
            }else{
                refreshDelegate?.refreshProfileDetails(profileDetails: profileDetails)
            }
        }
        updateBottomButton()
    }
}

//Call
extension ContactViewController {
    
    func makeFlyCall() {
        if isGroupBlockedByAdmin {
            AppAlert.shared.showToast(message: "\(groupNoLongerAvailable), can't make call")
            return
        }
        
        if CallManager.isAlreadyOnAnotherCall() && !isInvite{
            AppAlert.shared.showToast(message: "You’re already on call, can't make new Mirrorfly call")
            return
        }
        
        if !CallManager.isOngoingCall() || isInvite{
            if isInvite{
                CallManager.inviteUsersToOngoingCall(selectedProfilesJid as! [String]) { isSuccess, message in
                    if !isSuccess {
                        let errorMessage = AppUtils.shared.getErrorMessage(description: message)
                        AppAlert.shared.showAlert(view: self, title: "", message: errorMessage, buttonTitle: "Okay")
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            }else{
                RootViewController.sharedInstance.callViewController?.makeCall(usersList: selectedProfilesJid as! [String], callType: callType, groupId : groupJid, onCompletion: { isSuccess, message in
                    
                    if(!isSuccess){
                        let errorMessage = AppUtils.shared.getErrorMessage(description: message)
                        AppAlert.shared.showAlert(view: self, title: "", message: errorMessage, buttonTitle: "Okay")
                    }
                })
            }
            //self.navigationController?.popViewController(animated: false)
            
        }else{
            AppAlert.shared.showToast(message: "Already in another call, can't make new call")
        }
    }
}

extension ContactViewController : ReplyMessagesDelegate {
    func replyMessageObj(message: ChatMessage?,jid: String,messageText: String) {
        replyMessageObj = message
        replyJid = jid
        messageTxt = messageText
    }
}

extension ContactViewController : AdminBlockDelegate {
    func didBlockOrUnblockContact(userJid: String, isBlocked: Bool) {
        checkUserForAdminBlocking(jid: userJid, isBlocked: isBlocked)
    }
    
    func didBlockOrUnblockSelf(userJid: String, isBlocked: Bool) {
    
    }
    
    func didBlockOrUnblockGroup(groupJid: String, isBlocked: Bool) {
        checkUserForAdminBlocking(jid: groupJid, isBlocked: isBlocked)
    }

}

// To handle Admin Blocked user

extension ContactViewController {
    func checkUserForAdminBlocking(jid : String, isBlocked : Bool) {
        
        if isBlocked {
            allContacts = removeAdminBlockedContact(profileList: allContacts, jid: jid, isBlockedByAdmin: isBlocked)
            contacts = removeAdminBlockedContact(profileList: contacts, jid: jid, isBlockedByAdmin: isBlocked)
            selectectProfiles = removeAdminBlockedContact(profileList: selectectProfiles, jid: jid, isBlockedByAdmin: isBlocked)
            
            if isBlocked && selectedProfilesJid.count > 0 && selectedProfilesJid.contains(jid){
                selectedProfilesJid.remove(jid)
            }
        } else {
            if !FlyUtils.isValidGroupJid(groupJid: jid) {
                contacts = addUnBlockedContact(profileList: contacts, jid: jid, isBlockedByAdmin : isBlocked)
                allContacts = addUnBlockedContact(profileList: allContacts, jid: jid, isBlockedByAdmin: isBlocked)
            }
        }
        
        
        if FlyUtils.isValidGroupJid(groupJid: jid) && groupJid == jid {
            isGroupBlockedByAdmin = isBlocked
        }
        
        executeOnMainThread { [weak self] in
            self?.updateBottomButton()
            self?.contactList.reloadData()
        }
        profilePopupContainer.isHidden = true
    }
}


extension ContactViewController : UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !groupJid.isEmpty || ENABLE_CONTACT_SYNC{
            return
        }
        let position  = scrollView.contentOffset.y
        if position > contactList.contentSize.height-200 - scrollView.frame.size.height {
            if isPaginationCompleted(){
                print("#fetch Pagination Done")
                return
            }
            contactList.tableFooterView = createTableFooterView()
            if !isLoadingInProgress{
                isLoadingInProgress = true
                getUsersList(pageNo: searchTerm.isEmpty ? nextPage : searchNextPage, pageSize: 20, searchTerm: searchTerm)
            }
        }
    }
    
    public func getUsersList(pageNo : Int = 1, pageSize : Int =  40, searchTerm : String){
        print("#fetch request \(pageNo) \(pageSize) \(searchTerm) ")
        if pageNo == 1 {
            contactList.tableFooterView = createTableFooterView()
        }
        if !NetStatus.shared.isConnected{
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            if pageNo == 1{
                networkLabel?.isHidden = false
            }
            return
        }else{
            networkLabel?.isHidden = true
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
                    if searchTerm.isEmpty{
                        if pageNo == 1{
                            self.allContacts.removeAll()
                            self.contacts.removeAll()
                        }
                        self.allContacts.append(contentsOf: profileArray)
                        self.contacts.append(contentsOf: profileArray)
                    }else{
                        if pageNo == 1{
                            self.contacts.removeAll()
                        }
                        self.contacts.append(contentsOf: profileArray)
                    }
                    self.contacts.removeAll { pd in
                        self.callUsers.contains(pd.jid)
                    }
                    profilesCount = profileArray.count
                }
                if searchTerm.isEmpty{
                    if profilesCount >= pageSize{
                        self.nextPage += 1
                    }
                    self.totalPages = data["totalPages"] as? Int ?? 1
                    self.totalUsers = data["totalRecords"] as? Int ?? 1
                    print("#fetch response \(self.totalPages) \(self.nextPage) \(self.totalUsers) \(self.contacts.count) \(self.searchTerm)")
                    print("#internet api nextPage => \(self.nextPage)")
                }else{
                    if profilesCount >= pageSize{
                        self.searchNextPage += 1
                    }
                    self.searchTotalPages = data["totalPages"] as? Int ?? 1
                    self.searchTotalUsers = data["totalRecords"] as? Int ?? 1
                    print("#fetch response search total => \(self.searchTotalPages) nextPage => \(self.searchNextPage) searchTotoalUsers => \(self.searchTotalUsers) profilesCount => \(profilesCount) searchTerm => \(self.searchTerm)")
                }
                self.contactList.tableFooterView = nil
                self.contactList.reloadData()
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
            self.isLoadingInProgress = false
            self.refreshControl.endRefreshing()
        }
    }
    
    public func isPaginationCompleted() -> Bool {
        if searchTerm.isEmpty{
            if (totalPages < nextPage) || allContacts.count == totalUsers {
                return true
            }
        }else{
            if (searchTotalPages < searchNextPage) || contacts.count == searchTotalUsers {
                return true
            }
        }
        return false
    }
    
    public func resetDataAndFetchUsersList(){
        resetParams()
        allContacts.removeAll()
        contacts.removeAll()
        contactList.reloadData()
        getUsersList(pageNo: 1, pageSize: 20, searchTerm: searchTerm)
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
        if !ENABLE_CONTACT_SYNC && groupJid.isEmpty{
            if isLoadingInProgress || !isPaginationCompleted() {
                print("#internet nextPage => \(self.nextPage)")
                self.getUsersList(pageNo: self.searchTerm.isEmpty ? self.nextPage : self.searchNextPage, pageSize: 20, searchTerm: self.searchTerm)
            }
        }
    }
    
    func removeDuplicates(profileDetails : [ProfileDetails])  {
        let userIds = profileDetails.compactMap{$0.jid}
        contacts.removeAll { pd in
            userIds.contains(pd.jid)
        }
    }
    
    func networkLable(message : String) {
        let title = UILabel()
        title.text = message
        title.font =  UIFont.font14px_appRegular()
        title.lineBreakMode = .byWordWrapping
        title.numberOfLines = 0
        title.textAlignment = .center
        title.textColor = UIColor.darkGray
        title.sizeToFit()
        title.textAlignment = .center
        title.center = CGPoint(x: self.view.bounds.midX,y: self.view.bounds.midY)
        self.view.addSubview(title)
        networkLabel = title
        networkLabel?.isHidden = true
    }
}

extension ContactViewController {

    private func showBlockUnblockConfirmationPopUp(jid: String,name: String) {
        //showConfirmationAlert
        let alertViewController = UIAlertController.init(title: nil , message: (getBlocked(jid: jid) ) ? "Unblock \(name)?" : "Block \(name)?", preferredStyle: .alert)

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
                    executeOnMainThread { [weak self] in
                        self?.getCotactFromLocal(fromServer: false)
                        self?.contacts.enumerated().forEach { (index, value) in
                            if value.jid == jid {
                                self?.contactList.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                            }
                        }
                        AppAlert.shared.showToast(message: "\(name ?? "") has been Blocked")
                    }
                }else{
                    let message = AppUtils.shared.getErrorMessage(description: error?.description ?? "")
                    AppAlert.shared.showAlert(view: self, title: "" , message: message, buttonTitle: "OK")
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
                    executeOnMainThread { [weak self] in
                        self?.getCotactFromLocal(fromServer: false)
                        self?.contacts.enumerated().forEach { (index, value) in
                            if value.jid == jid {
                                self?.contactList.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                            }
                        }
                        AppAlert.shared.showToast(message: "\(name ?? "") has been Unblocked")
                    }
                }else {
                    let message = AppUtils.shared.getErrorMessage(description: error?.description ?? "")
                    AppAlert.shared.showAlert(view: self, title: "" , message: message, buttonTitle: "OK")
                    return
                }
            }
        } catch let error as NSError {
            print("block user error: \(error)")
        }
    }
}

extension ContactViewController: AvailableFeaturesDelegate {
    
    func didUpdateAvailableFeatures(features: AvailableFeaturesModel) {
        
        let tabCount =  MainTabBarController.tabBarDelegagte?.currentTabCount()
        
        if (!(features.isGroupCallEnabled || features.isOneToOneCallEnabled) && tabCount == 5) {
            MainTabBarController.tabBarDelegagte?.removeTabAt(index: 2)
        } else {
            if ((features.isGroupCallEnabled || features.isOneToOneCallEnabled) && tabCount ?? 0 < 5){
                MainTabBarController.tabBarDelegagte?.resetTabs()
            }
        }
    }
}
