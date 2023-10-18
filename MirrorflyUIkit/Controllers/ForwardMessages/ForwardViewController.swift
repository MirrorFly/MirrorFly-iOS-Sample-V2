//
//  ForwardViewController.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya T on 14/12/21.
//

import UIKit
import MirrorFlySDK
import RxSwift

protocol SendSelectecUserDelegate {
    func sendSelectedUsers(selectedUsers: [Profile],completion: @escaping (() -> Void))
}

class ForwardViewController: UIViewController {
    @IBOutlet weak var forwardTableView: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl?
    @IBOutlet weak var searchBar: UISearchBar?
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var emptyMessageView: UIView?
    @IBOutlet weak var segmentControlView: UIView?
    @IBOutlet weak var sendButton: UIButton?
    @IBOutlet weak var forwardHeaderView: UIView?
    @IBOutlet weak var forwardViewHeightCons: NSLayoutConstraint?
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    private var contactViewModel : ContactViewModel?
    private var recentChatViewModel: RecentChatViewModel?
    var getRecentChat: [RecentChat] = []
    var getAllRecentChat: [RecentChat] = []
    var filteredContactList =  [ProfileDetails]()
    var allContactsList =  [ProfileDetails]()
    var isSearchEnabled: Bool = false
    var randomColors = [UIColor?]()
    var segmentSelectedIndex: Int? = 0
    var selectedMessages: [Profile] = []
    var pageDismissClosure:(() -> Void)?
    var selectedUserDelegate: SendSelectecUserDelegate? = nil
    var getProfileDetails: ProfileDetails?
    var forwardMessages: [SelectedMessages] = []
    var searchedText : String = emptyString()
    var refreshProfileDelegate: RefreshProfileInfo?
    var fromJid : String? = nil
    
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

    var hidePrivateChatUsers: Bool = false
    var isFromPrivateChat: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        handleBackgroundAndForground()
        contactViewModel =  ContactViewModel()
        recentChatViewModel = RecentChatViewModel()
        configTableView()
        loadChatList()
        setUpStatusBar()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        searchSubject.throttle(.milliseconds(25), scheduler: MainScheduler.instance).distinctUntilChanged().subscribe { [weak self] term in
            self?.searchTerm = term
            self?.filteredContactList.removeAll()
            self?.allContactsList.removeAll()
            self?.forwardTableView.reloadData()
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
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            forwardTableView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height + (forwardTableView?.rowHeight ?? 0.0) + 30, right: 0)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        forwardTableView?.contentInset = .zero
    }
    
    func checkMessageValidation(messages: [String]) {
        var isMessageExist: [String] = []
        forwardMessages.forEach { forwardMessage in
            isMessageExist += messages.filter({$0 == forwardMessage.chatMessage.messageId})
        }
        if isMessageExist.count > 0 {
            DispatchQueue.main.async { [weak self] in
                AppAlert.shared.showToast(message: "Your selected message is no longer available")
                self?.pageDismissClosure?()
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    // MARK: ConfigTableView
    private func configTableView() {
            searchBar?.delegate = self
            forwardTableView?.rowHeight = UITableView.automaticDimension
            forwardTableView?.estimatedRowHeight = 130
            forwardTableView?.delegate = self
            forwardTableView?.dataSource = self
            forwardTableView?.separatorStyle = .none
        let nib = UINib(nibName: Identifiers.participantCell, bundle: Bundle.main)
        forwardTableView?.register(nib, forCellReuseIdentifier: Identifiers.participantCell)
        let recentChatNib = UINib(nibName: Identifiers.recentChatCell, bundle: .main)
        forwardTableView?.register(recentChatNib, forCellReuseIdentifier: Identifiers.recentChatCell)
        if let tv = forwardTableView{
            tv.contentSize = CGSize(width: tv.frame.size.width, height: tv.contentSize.height);
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        sendButton?.isEnabled = false
        sendButton?.alpha = 0.4
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
        ContactManager.shared.profileDelegate = self
        ChatManager.shared.adminBlockDelegate = self
        ChatManager.shared.messageEventsDelegate = self
        FlyMessenger.shared.messageEventsDelegate = self
        GroupManager.shared.groupDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ContactManager.shared.profileDelegate = nil
        ChatManager.shared.messageEventsDelegate = nil
        ChatManager.shared.adminBlockDelegate = nil
        FlyMessenger.shared.messageEventsDelegate = nil
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NetStatus.networkNotificationObserver), object: nil)
    }
    
    func checkMemberOfGroup(index: Int,recentChat: RecentChat) -> Bool? {
        if recentChat.profileType == .groupChat && !isParticipantExist(index: index).doesExist {
            return true
        }
        return false
    }
    
    func isParticipantExist(index: Int) -> (doesExist : Bool, message : String) {
        return GroupManager.shared.isParticiapntExistingIn(groupJid:  getRecentChat[index].jid, participantJid: AppUtils.getMyJid())
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
            self?.navigationController?.popViewController(animated: true)
        }
    }
    @IBAction func sendButtonTapped(_ sender: Any) {
        if selectedMessages.count == 1 {
            let vc = UIStoryboard.init(name: Storyboards.chat, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.chatViewParentController) as? ChatViewParentController
            switch segmentSelectedIndex {
            case 0:
                let profile = isSearchEnabled == true ? filteredContactList.filter({$0.isSelected == true}).first : allContactsList.filter({$0.isSelected == true}).first
                vc?.getProfileDetails = profile
                let array = isSearchEnabled == true ? filteredContactList : allContactsList
                array.enumerated().forEach { (index,element) in
                    if element.jid == profile?.jid {
                        let hashcode = profile?.name.hashValue
                        if let hash = hashcode {
                            let color = randomColors[abs(hash) % randomColors.count]
                            vc?.contactColor =  color ?? .gray //randomColors[index]
                        }
                        else {
                            vc?.contactColor = .gray
                        }
                        
                    }
                }
            case 1:
                let recentChat = isSearchEnabled == true ? getRecentChat.filter({$0.isSelected == true && $0.profileType == .groupChat}).first : getAllRecentChat.filter({$0.isSelected == true && $0.profileType == .groupChat}).first
                let profile = ProfileDetails(jid: recentChat?.jid ?? "")
                profile.name =  recentChat?.profileName ?? ""
                profile.nickName = recentChat?.nickName ?? ""
                profile.image = recentChat?.profileImage ?? ""
                profile.profileChatType = ChatType(rawValue: recentChat?.profileType.rawValue ?? "") ?? .singleChat
                vc?.getProfileDetails = profile
                let array = isSearchEnabled == true ? getRecentChat.filter({$0.isSelected == true && $0.profileType == .groupChat}) : getAllRecentChat.filter({$0.isSelected == true && $0.profileType == .groupChat})
                array.enumerated().forEach { (index,element) in
                    if element.jid == profile.jid {
                        vc?.contactColor =  randomColors[index] ?? .gray
                    }
                }
                break
            case 3:
                break
            case 2:
                let recentChat = isSearchEnabled == true ? getRecentChat.filter({$0.isSelected == true}).first : getAllRecentChat.filter({$0.isSelected == true}).first
                let profile = ProfileDetails(jid: recentChat?.jid ?? "")
                profile.name =  recentChat?.profileName ?? ""
                profile.nickName = recentChat?.nickName ?? ""
                profile.image = recentChat?.profileImage ?? ""
                profile.profileChatType = ChatType(rawValue: recentChat?.profileType.rawValue ?? "") ?? .singleChat
                vc?.getProfileDetails = profile
                let array = isSearchEnabled == true ? getRecentChat : getAllRecentChat
                array.enumerated().forEach { (index,element) in
                    if element.jid == profile.jid {
                        vc?.contactColor =  randomColors[index] ?? .gray
                    }
                }
            default:
                break
            }
            vc?.isPopToRootVC = true
            selectedUserDelegate?.sendSelectedUsers(selectedUsers: selectedMessages ,completion: { [weak self] in
                self?.startLoading(withText: "Sending")
                let messageIds = self?.forwardMessages.map({$0.chatMessage.messageId})
                let jids = self?.selectedMessages.map({$0.jid})
                ChatManager.forwardMessages(messageIdList: messageIds ?? [], toJidList: jids ?? [], chatType: (self?.getProfileDetails?.profileChatType ?? .singleChat), completionHandler: {isSuccess,error,data in
                    
                })
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self?.navigationController?.modalPresentationStyle = .fullScreen
                    guard let viewController = vc else { return }
                    viewController.isFromForward = true
                    viewController.isFromPrivateChat = self?.isFromPrivateChat ?? false
                    self?.navigationController?.pushViewController(viewController, animated: true)
                    self?.stopLoading()
                }
            })
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.startLoading(withText: "Sending")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self?.stopLoading()
                    self?.selectedUserDelegate?.sendSelectedUsers(selectedUsers: self?.selectedMessages ?? [],completion: { [weak self] in
                        if let messageIds = self?.forwardMessages.map({$0.chatMessage.messageId}) {
                            let jids = self?.selectedMessages.map({$0.jid})
                            ChatManager.forwardMessages(messageIdList: messageIds, toJidList: jids ?? [], chatType: (self?.getProfileDetails?.profileChatType ?? .singleChat), completionHandler: {isSuccess,error,data in
                                
                            })
                            self?.navigationController?.popViewController(animated: true)
                        }
                    })
                }
            }
        }
    }
    
    @IBAction func SegmentControlValueChanged(_ sender: UISegmentedControl) {
        segmentSelectedIndex = sender.selectedSegmentIndex

        if segmentSelectedIndex == 1 {
            getRecentChatList(withArchive: true)
        } else {
            getRecentChatList()
        }
        if isLoadingInProgress && segmentSelectedIndex == 0 {
            initalLoader()
        }
        //forwardTableView?.reloadData()
        //handleEmptyViewWhileSearch()
        // temporarily show empty message by default
//        if segmentSelectedIndex == 2 {
//            showEmptyMessage()
//            descriptionLabel?.text = "No broadcast available"
//        }
        
        self.forwardTableView.tableFooterView?.isHidden = (segmentSelectedIndex != 0 && isLoadingInProgress) ? true : false
    }
    
    private func hideEmptyMessage() {
        emptyMessageView?.isHidden = true
    }
    
    private func showEmptyMessage() {
        emptyMessageView?.isHidden = false
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
        forwardTableView?.reloadData()
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

// TableViewDelegate
extension ForwardViewController : UITableViewDelegate, UITableViewDataSource {
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
        if let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.participantCell, for: indexPath) as? ParticipantCell) {
            switch segmentSelectedIndex {
            case 0:
                let contactDetails = isSearchEnabled == true ? filteredContactList[indexPath.row] : allContactsList[indexPath.row]
                if getBlocked(jid: contactDetails.jid) {
                    cell.contentView.alpha = 0.6
                } else {
                    cell.contentView.alpha = 1.0
                }
                cell.nameUILabel?.text = getUserName(jid: contactDetails.jid, name: contactDetails.name, nickName: contactDetails.nickName, contactType: contactDetails.contactType)
                cell.statusUILabel?.text = contactDetails.status
                let hashcode = contactDetails.name.hashValue
                let color = randomColors[abs(hashcode) % randomColors.count]
                let profileImage = contactDetails.thumbImage.isEmpty ? contactDetails.image : contactDetails.thumbImage
                cell.setImage(imageURL: profileImage, name: getUserName(jid: contactDetails.jid, name: contactDetails.name, nickName: contactDetails.nickName, contactType: contactDetails.contactType), color: color ?? .gray, profile: contactDetails)
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
                cell.receiverMessageTypeView?.isHidden = true
                let chatMessage = recentChatDetails.lastMessageContent.trim()
                if recentChatDetails.isMentionedUser, chatMessage.isNotEmpty {
                    var message = emptyString()
                    if recentChatDetails.profileType == .groupChat {
                        message = ChatUtils.getMentionTextContent(message: recentChatDetails.lastMessageContent, isMessageSentByMe: recentChatDetails.isLastMessageSentByMe, mentionedUsers: recentChatDetails.mentionedUsersIds).string
                    } else {
                        message = ChatUtils.convertMentionUser(message: recentChatDetails.lastMessageContent, mentionedUsersIds: recentChatDetails.mentionedUsersIds).replacingOccurrences(of: "`", with: "")
                    }
                    if recentChatDetails.lastMessageType == .text || recentChatDetails.lastMessageType == .notification {
                        cell.statusUILabel?.text = message
                    } else {
                        cell.receiverMessageTypeView?.isHidden = false
                        cell.statusUILabel?.text = message + (recentChatDetails.lastMessageType?.rawValue ?? "")
                    }
                } else {
                    if recentChatDetails.lastMessageType == .text || recentChatDetails.lastMessageType == .notification {
                        cell.statusUILabel?.text = recentChatDetails.lastMessageContent
                    } else if recentChatDetails.lastMessageType == .meet {
                        cell.receiverMessageTypeView?.isHidden = false
                        let message = getMessages(messageId: recentChatDetails.lastMessageId)
                        cell.statusUILabel?.text = "Scheduled on " + (((message.meetChatMessage?.scheduledDateTime != 0) ? DateFormatterUtility.shared.getSchduleMeetingDate(date: message.meetChatMessage?.scheduledDateTime ?? 0) : recentChatDetails.lastMessageType?.rawValue.capitalized) ?? "")
                    } else  {
                        cell.receiverMessageTypeView?.isHidden = false
                        cell.statusUILabel?.text = recentChatDetails.lastMessageContent + (recentChatDetails.lastMessageType?.rawValue ?? "")
                    }
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
                let chatMessage = recentChatDetails.lastMessageContent.trim()
                if recentChatDetails.isMentionedUser, chatMessage.isNotEmpty {
                    var message = emptyString()
                    if recentChatDetails.profileType == .groupChat {
                        message = ChatUtils.getMentionTextContent(message: recentChatDetails.lastMessageContent, isMessageSentByMe: recentChatDetails.isLastMessageSentByMe, mentionedUsers: recentChatDetails.mentionedUsersIds).string
                    } else {
                        message = ChatUtils.convertMentionUser(message: recentChatDetails.lastMessageContent, mentionedUsersIds: recentChatDetails.mentionedUsersIds).replacingOccurrences(of: "`", with: "")
                    }
                    if recentChatDetails.lastMessageType == .text || recentChatDetails.lastMessageType == .notification {
                        cell.statusUILabel?.text = message
                    } else {
                        cell.receiverMessageTypeView?.isHidden = false
                        cell.statusUILabel?.text = message + (recentChatDetails.lastMessageType?.rawValue ?? "")
                    }
                } else {
                    if recentChatDetails.lastMessageType == .text || recentChatDetails.lastMessageType == .notification {
                        cell.statusUILabel?.text = recentChatDetails.lastMessageContent
                    } else if recentChatDetails.lastMessageType == .meet {
                        cell.receiverMessageTypeView?.isHidden = false
                        let message = getMessages(messageId: recentChatDetails.lastMessageId)
                        cell.statusUILabel?.text = "Scheduled on " + (((message.meetChatMessage?.scheduledDateTime != 0) ? DateFormatterUtility.shared.getSchduleMeetingDate(date: message.meetChatMessage?.scheduledDateTime ?? 0) : recentChatDetails.lastMessageType?.rawValue.capitalized) ?? "")
                    } else  {
                        cell.receiverMessageTypeView?.isHidden = false
                        cell.statusUILabel?.text = recentChatDetails.lastMessageContent + (recentChatDetails.lastMessageType?.rawValue ?? "")
                    }
                }
                cell.statusUILabel?.isHidden = false
                cell.removeButton?.isHidden = true
                cell.removeIcon?.isHidden = true
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
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
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
                    if selectedMessages.filter({$0.jid == profile.jid}).count == 0  && selectedMessages.count < 5 {
                        checkUserBusyStatusEnabled(self, jid: profile.jid) { [weak self] status in
                            if status {
                                self?.getRecentChat.filter({$0.jid == profile.jid}).first?.isSelected = true
                                self?.filteredContactList[indexPath.row].isSelected = true
                                self?.selectedMessages.append(profile)
                                self?.selectedJids = self?.selectedMessages.compactMap { profile in profile.jid } ?? []
                            }
                            self?.forwardTableView?.reloadRows(at: [indexPath], with: .none)
                        }
                    } else if selectedMessages.filter({$0.jid == filteredContactList[indexPath.row].jid}).count > 0 {
                        selectedMessages.enumerated().forEach({ (index,item) in
                            if item.jid == filteredContactList[indexPath.row].jid {
                                if index <= selectedMessages.count {
                                    getRecentChat.filter({$0.jid == filteredContactList[indexPath.row].jid}).first?.isSelected = false
                                    filteredContactList[indexPath.row].isSelected = false
                                    selectedMessages.remove(at: index)
                                    selectedJids = selectedMessages.compactMap { profile in profile.jid }
                                }
                            }
                        })
                    } else {
                        AppAlert.shared.showToast(message: ErrorMessage.restrictedforwardUsers)
                    }
                    forwardTableView?.reloadRows(at: [indexPath], with: .none)
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
                    if selectedMessages.filter({$0.jid == profile.jid}).count == 0  && selectedMessages.count < 5 {
                        checkUserBusyStatusEnabled(self, jid: profile.jid) { [weak self] status in
                            if status {
                                self?.getAllRecentChat.filter({$0.jid == profile.jid}).first?.isSelected = true
                                self?.allContactsList[indexPath.row].isSelected = true
                                self?.selectedMessages.append(profile)
                                self?.selectedJids = self?.selectedMessages.compactMap { profile in profile.jid } ?? []
                            }
                            self?.forwardTableView?.reloadRows(at: [indexPath], with: .none)
                        }
                    } else if selectedMessages.filter({$0.jid == allContactsList[indexPath.row].jid}).count > 0 {
                        selectedMessages.enumerated().forEach({ (index,item) in
                            if item.jid == allContactsList[indexPath.row].jid {
                                if index <= selectedMessages.count {
                                    getAllRecentChat.filter({$0.jid == allContactsList[indexPath.row].jid}).first?.isSelected = false
                                    allContactsList[indexPath.row].isSelected = false
                                    selectedMessages.remove(at: index)
                                    selectedJids = selectedMessages.compactMap { profile in profile.jid }
                                }
                            }
                        })
                    } else {
                        AppAlert.shared.showToast(message: ErrorMessage.restrictedforwardUsers)
                    }
                    forwardTableView?.reloadRows(at: [indexPath], with: .none)
                }
            case 1:
                switch isSearchEnabled  {
                case true:
                    if checkMemberOfGroup(index: indexPath.row, recentChat: getAllRecentChat[indexPath.row]) == true {
                        AppAlert.shared.showToast(message: youCantSelectTheGroup)
                        return
                    }
                    var profile = Profile()
                    profile.profileName = getRecentChat.filter({$0.profileType == .groupChat && $0.isBlockedByAdmin == false})[indexPath.row].profileName
                    profile.jid = getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid
                    profile.isSelected = !(profile.isSelected ?? false)
                    saveUserToDatabase(jid: profile.jid)
                    if selectedMessages.filter({$0.jid == getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).count == 0  && selectedMessages.count < 5 {
                        getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].isSelected = true
                        getRecentChat.filter({$0.jid ==  getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).first?.isSelected = true
                        selectedMessages.append(profile)
                        selectedJids = selectedMessages.compactMap { profile in profile.jid }
                    } else if selectedMessages.filter({$0.jid == getRecentChat.filter({$0.profileType == .groupChat && $0.isBlockedByAdmin == false})[indexPath.row].jid}).count > 0 {
                        selectedMessages.enumerated().forEach({ (index,item) in
                            if item.jid == getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid {
                                if index <= selectedMessages.count {
                                    getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].isSelected = false
                                    getRecentChat.filter({$0.jid ==  getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).first?.isSelected = false
                                    selectedMessages.remove(at: index)
                                    selectedJids = selectedMessages.compactMap { profile in profile.jid }
                                }
                            }
                        })
                    } else {
                        AppAlert.shared.showToast(message: ErrorMessage.restrictedforwardUsers)
                    }
                    forwardTableView?.reloadRows(at: [indexPath], with: .none)
                case false:
                    if checkMemberOfGroup(index: indexPath.row, recentChat: getAllRecentChat[indexPath.row]) == true {
                        AppAlert.shared.showToast(message: youCantSelectTheGroup)
                        return
                    }
                    var profile = Profile()
                    profile.profileName = getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].profileName
                    profile.jid = getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid
                    profile.isSelected = !(profile.isSelected ?? false)
                    saveUserToDatabase(jid: profile.jid)
                    if selectedMessages.filter({$0.jid == getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).count == 0  && selectedMessages.count < 5 {
                        getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].isSelected = true
                        getAllRecentChat.filter({$0.jid ==  getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).first?.isSelected = true
                        selectedMessages.append(profile)
                        selectedJids = selectedMessages.compactMap { profile in profile.jid }
                    } else if selectedMessages.filter({$0.jid == getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).count > 0 {
                        selectedMessages.enumerated().forEach({ (index,item) in
                            if item.jid == getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid {
                                if index <= selectedMessages.count {
                                    getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].isSelected = false
                                    getAllRecentChat.filter({$0.jid ==  getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).first?.isSelected = false
                                    selectedMessages.remove(at: index)
                                    selectedJids = selectedMessages.compactMap { profile in profile.jid }
                                }
                            }
                        })
                    } else {
                        AppAlert.shared.showToast(message: ErrorMessage.restrictedforwardUsers)
                    }
                    forwardTableView?.reloadRows(at: [indexPath], with: .none)
                }
            case 3:
                break
            case 2:
                switch isSearchEnabled  {
                case true:
                    if checkMemberOfGroup(index: indexPath.row, recentChat: getRecentChat[indexPath.row]) == true {
                        AppAlert.shared.showToast(message: youCantSelectTheGroup)
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
                    if selectedMessages.filter({$0.jid == getRecentChat[indexPath.row].jid}).count == 0 && selectedMessages.count < 5 {
                        checkUserBusyStatusEnabled(self, jid: profile.jid) { [weak self] status in
                            if status {
                                self?.getRecentChat[indexPath.row].isSelected = true
                                self?.filteredContactList.filter({$0.jid == self?.getRecentChat[indexPath.row].jid}).first?.isSelected = true
                                self?.selectedMessages.append(profile)
                                self?.selectedJids = self?.selectedMessages.compactMap { profile in profile.jid } ?? []
                            }
                            self?.forwardTableView?.reloadRows(at: [indexPath], with: .none)
                        }
                    } else if selectedMessages.filter({$0.jid == getRecentChat[indexPath.row].jid}).count > 0 {
                        selectedMessages.enumerated().forEach({ (index,item) in
                            if item.jid == getRecentChat[indexPath.row].jid {
                                if index <= selectedMessages.count {
                                    getRecentChat[indexPath.row].isSelected = false
                                    filteredContactList.filter({$0.jid == getRecentChat[indexPath.row].jid}).first?.isSelected = false
                                    selectedMessages.remove(at: index)
                                    selectedJids = selectedMessages.compactMap { profile in profile.jid }
                                }
                            }
                        })
                    } else {
                        AppAlert.shared.showToast(message: ErrorMessage.restrictedforwardUsers)
                    }
                    forwardTableView?.reloadRows(at: [indexPath], with: .none)
                case false:
                    if checkMemberOfGroup(index: indexPath.row, recentChat: getAllRecentChat[indexPath.row]) == true {
                        AppAlert.shared.showToast(message: youCantSelectTheGroup)
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
                    if selectedMessages.filter({$0.jid == getAllRecentChat[indexPath.row].jid}).count == 0  && selectedMessages.count < 5 {
                        checkUserBusyStatusEnabled(self, jid: profile.jid) { [weak self] status in
                            if status {
                                self?.getAllRecentChat[indexPath.row].isSelected = true
                                self?.allContactsList.filter({$0.jid == self?.getAllRecentChat[indexPath.row].jid}).first?.isSelected = true
                                self?.selectedMessages.append(profile)
                                self?.selectedJids = self?.selectedMessages.compactMap { profile in profile.jid } ?? []
                            }
                            self?.forwardTableView?.reloadRows(at: [indexPath], with: .none)
                        }
                    } else if selectedMessages.filter({$0.jid == getAllRecentChat[indexPath.row].jid}).count > 0 {
                        selectedMessages.enumerated().forEach({ (index,item) in
                            if item.jid == getAllRecentChat[indexPath.row].jid {
                                if index <= selectedMessages.count {
                                    getAllRecentChat[indexPath.row].isSelected = false
                                    allContactsList.filter({$0.jid == getAllRecentChat[indexPath.row].jid}).first?.isSelected = false
                                    selectedMessages.remove(at: index)
                                    selectedJids = selectedMessages.compactMap { profile in profile.jid }
                                }
                            }
                        })
                    } else {
                        AppAlert.shared.showToast(message: ErrorMessage.restrictedforwardUsers)
                    }
                    forwardTableView?.reloadRows(at: [indexPath], with: .none)
                }
            default:
                break
            }
            sendButton?.isEnabled = selectedMessages.count == 0 ? false : true
            sendButton?.alpha = selectedMessages.count == 0 ? 0.4 : 1.0
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if segmentSelectedIndex == 1 {
            let recentChatDetails = isSearchEnabled == true ? getRecentChat.filter({$0.profileType == .groupChat && $0.isBlockedByAdmin == false })[indexPath.row] : getAllRecentChat.filter({$0.profileType == .groupChat && $0.isBlockedByAdmin == false})[indexPath.row]
            if recentChatDetails.isPrivateChat && hidePrivateChatUsers {
                return 0
            }
        } else if segmentSelectedIndex == 2 {
            let recentChatDetails = isSearchEnabled == true ? getRecentChat[indexPath.row] : getAllRecentChat[indexPath.row]
            if recentChatDetails.isPrivateChat && hidePrivateChatUsers {
                return 0
            }
        }
        return UITableView.automaticDimension
    }
}

// SearchBar Delegate Method
extension ForwardViewController: UISearchBarDelegate {
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
        forwardTableView?.reloadData()
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
extension ForwardViewController {
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
                        weakSelf.allContactsList = weakSelf.allContactsList.sorted {getUserName(jid: $0.jid, name: $0.name, nickName: $0.nickName, contactType: $0.contactType).capitalized < getUserName(jid: $1.jid, name: $1.name, nickName: $1.nickName, contactType: $1.contactType).capitalized }
                        
                        weakSelf.allContactsList.enumerated().forEach { (index,contact) in
                            if  weakSelf.selectedMessages.filter({$0.jid == contact.jid}).count > 0 {
                                weakSelf.allContactsList[index].isSelected = (weakSelf.selectedMessages.filter({$0.jid == contact.jid}).first?.isSelected ?? false)
                            }
                        }
                        
                        weakSelf.filteredContactList.enumerated().forEach { (index,contact) in
                            if  weakSelf.selectedMessages.filter({$0.jid == contact.jid}).count > 0 {
                                weakSelf.filteredContactList[index].isSelected = (weakSelf.selectedMessages.filter({$0.jid == contact.jid}).first?.isSelected ?? false)
                            }
                        }
                        weakSelf.forwardTableView?.reloadData()
                        
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
                        if  weakSelf.selectedMessages.filter({$0.jid == contact.jid}).count > 0 {
                            weakSelf.getAllRecentChat[index].isSelected = (weakSelf.selectedMessages.filter({$0.jid == contact.jid}).first?.isSelected ?? false)
                        }
                    }

                    weakSelf.getRecentChat.enumerated().forEach { (index,contact) in
                        if  weakSelf.selectedMessages.filter({$0.jid == contact.jid}).count > 0 {
                            weakSelf.getRecentChat[index].isSelected = (weakSelf.selectedMessages.filter({$0.jid == contact.jid}).first?.isSelected ?? false)
                        }
                    }
                }
            })
            randomColors = AppUtils.shared.setRandomColors(totalCount: getRecentChat.count)
            if isSearchEnabled == false {
                forwardTableView?.reloadData()
            }
            handleEmptyViewWhileSearch()
        } else {
            recentChatViewModel?.getRecentChatList(isBackground: false, completionHandler: { [weak self] recentChatList in
                if let weakSelf = self {
                    weakSelf.getRecentChat = recentChatList?.filter({$0.isBlockedByAdmin == false}) ?? []
                    weakSelf.getAllRecentChat = weakSelf.getRecentChat

                    weakSelf.getAllRecentChat.enumerated().forEach { (index,contact) in
                        if  weakSelf.selectedMessages.filter({$0.jid == contact.jid}).count > 0 {
                            weakSelf.getAllRecentChat[index].isSelected = (weakSelf.selectedMessages.filter({$0.jid == contact.jid}).first?.isSelected ?? false)
                        }
                    }

                    weakSelf.getRecentChat.enumerated().forEach { (index,contact) in
                        if  weakSelf.selectedMessages.filter({$0.jid == contact.jid}).count > 0 {
                            weakSelf.getRecentChat[index].isSelected = (weakSelf.selectedMessages.filter({$0.jid == contact.jid}).first?.isSelected ?? false)
                        }
                    }
                }
            })
            randomColors = AppUtils.shared.setRandomColors(totalCount: getRecentChat.count)
            if isSearchEnabled == false {
                forwardTableView?.reloadData()
            }
            handleEmptyViewWhileSearch()
        }
    }
}

extension ForwardViewController : ProfileEventsDelegate {
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
            self?.getRecentChatList()
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
        loadChatList()
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
                forwardTableView?.reloadData()
                if let index = selectedMessages.firstIndex(where: {$0.jid == jid}){
                    selectedMessages.remove(at: index)
                    sendButton?.isEnabled = selectedMessages.count == 0 ? false : true
                    sendButton?.alpha = selectedMessages.count == 0 ? 0.4 : 1.0
                }
            }
        }
        if let indexOfFilteredList = filteredContactList.firstIndex(where: {$0.jid == jid}){
            filteredContactList.remove(at: indexOfFilteredList)
            if segmentSelectedIndex == 0 && isSearchEnabled{
                forwardTableView?.reloadData()
                if let index = selectedMessages.firstIndex(where: {$0.jid == jid}){
                    selectedMessages.remove(at: index)
                    sendButton?.isEnabled = selectedMessages.count == 0 ? false : true
                    sendButton?.alpha = selectedMessages.count == 0 ? 0.4 : 1.0
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
                forwardTableView?.reloadRows(at: [indexPath], with: .fade)
                if let index = selectedMessages.firstIndex(where: {$0.jid == jid}){
                    selectedMessages.remove(at: index)
                    sendButton?.isEnabled = selectedMessages.count == 0 ? false : true
                    sendButton?.alpha = selectedMessages.count == 0 ? 0.4 : 1.0
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
                forwardTableView?.reloadRows(at: [indexPath], with: .fade)
                if let index = selectedMessages.firstIndex(where: {$0.jid == jid}){
                    selectedMessages.remove(at: index)
                    sendButton?.isEnabled = selectedMessages.count == 0 ? false : true
                    sendButton?.alpha = selectedMessages.count == 0 ? 0.4 : 1.0
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
                    let profileImage = profileDetails.thumbImage.isEmpty ? profileDetails.image : profileDetails.thumbImage
                    filteredContactList[index].image = profileImage
                    filteredContactList[index].name = profileDetails.name
                    filteredContactList[index].status = profileDetails.status
            }
            } else {
                    if  let index = allContactsList.firstIndex(of: profileData) {
                        let profileImage = profileDetails.thumbImage.isEmpty ? profileDetails.image : profileDetails.thumbImage
                        allContactsList[index].image = profileImage
                        allContactsList[index].name = profileDetails.name
                        allContactsList[index].status = profileDetails.status
                }
            }
                let profile = ["jid": profileDetails.jid, "name": profileDetails.name, "image": profileDetails.image, "status": profileDetails.status, "thumbImage": profileDetails.thumbImage]
                NotificationCenter.default.post(name: Notification.Name(Identifiers.ncProfileUpdate), object: nil, userInfo: profile as [AnyHashable : Any])
                forwardTableView?.reloadData()
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
                let profile = ["jid": profileDetails.jid, "name": profileDetails.name, "image": profileDetails.image, "status": profileDetails.status, "thumbImage": profileDetails.thumbImage]
                NotificationCenter.default.post(name: Notification.Name(Identifiers.ncProfileUpdate), object: nil, userInfo: profile as [AnyHashable : Any])
                forwardTableView?.reloadData()
            }
    case 2:
        let profileDatas =  isSearchEnabled == true ? getRecentChat : getAllRecentChat
        if profileDatas.count > 0, let profileData = profileDatas.first  {
            if isSearchEnabled == true {
                if  let index = getRecentChat.firstIndex(of: profileData) {
                    let profileImage = profileDetails.thumbImage.isEmpty ? profileDetails.image : profileDetails.thumbImage
                    getRecentChat[index].profileImage = profileImage
                    getRecentChat[index].profileName = profileDetails.name
                }
            } else {
                    if  let index = getAllRecentChat.firstIndex(of: profileData) {
                        let profileImage = profileDetails.thumbImage.isEmpty ? profileDetails.image : profileDetails.thumbImage
                        getAllRecentChat[index].profileImage = profileImage
                        getAllRecentChat[index].profileName = profileDetails.name
                }
            }
                let profile = ["jid": profileDetails.jid, "name": profileDetails.name, "image": profileDetails.image, "status": profileDetails.status, "thumbImage": profileDetails.thumbImage]
                NotificationCenter.default.post(name: Notification.Name(Identifiers.ncProfileUpdate), object: nil, userInfo: profile as [AnyHashable : Any])
                forwardTableView?.reloadData()
            }
        default:
            break
        }
    }
}

extension ForwardViewController : GroupEventsDelegate {
    func didRemoveMemberFromAdmin(groupJid: String, removedAdminMemberJid: String, removedByMemberJid: String) {
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
                    self?.forwardTableView?.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                }
            }
        }
    }
}

// MessageEventDelegate
extension ForwardViewController : MessageEventsDelegate {
  
    func onMessageTranslated(message: ChatMessage, jid: String) {
        
    }
    
    func onMessageStatusUpdated(messageId: String, chatJid: String, status: MessageStatus) {
        if isSearchEnabled == false {
            refreshMessages()
        }
    }
    
    func onMediaStatusUpdated(message: ChatMessage) {
        
    }
    
    func onMediaStatusFailed(error: String, messageId: String, errorCode: Int) {
        
    }
    
    func onMediaProgressChanged(message: ChatMessage, progressPercentage: Float) {
        
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

extension ForwardViewController : AdminBlockDelegate {
    func didBlockOrUnblockContact(userJid: String, isBlocked: Bool) {
        checkUserForAdminBlocking(jid: userJid, isBlocked: isBlocked)
    }
    
    func didBlockOrUnblockSelf(userJid: String, isBlocked: Bool) {
    
    }
    
    func didBlockOrUnblockGroup(groupJid: String, isBlocked: Bool) {
        checkUserForAdminBlocking(jid: groupJid, isBlocked: isBlocked)
        let messages = forwardMessages.filter({$0.chatMessage.chatUserJid == groupJid})
        if isBlocked && messages.count > 0 {
            self.navigationController?.navigationBar.isHidden = false
            self.navigationController?.popToRootViewController(animated: true)
            executeOnMainThread { [weak self] in
                self?.stopLoading()
                AppAlert.shared.showToast(message: groupNoLongerAvailable)
            }
        }
    }

}

// To handle Admin Blocked user

extension ForwardViewController {
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
            self?.forwardTableView?.reloadData()
        }
        
    }
}

extension ForwardViewController : UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if ENABLE_CONTACT_SYNC {
            return
        }
        
        if segmentSelectedIndex != 0 {
            return
        }
        
        let position  = scrollView.contentOffset.y
         if position > forwardTableView.contentSize.height-200 - scrollView.frame.size.height {
             if isPaginationCompleted(){
                 print("#fetch Pagination Done")
                 return
             }
            forwardTableView.tableFooterView = createTableFooterView()
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
        if !NetStatus.shared.isConnected{
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
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
                self.forwardTableView.tableFooterView = nil
                self.forwardTableView.reloadData()
                self.showHideEmptyMessage(totalCount: self.searchTerm.isEmpty ? self.allContactsList.count : self.filteredContactList.count)
            }else{
                if !NetworkReachability.shared.isConnected{
                    AppAlert.shared.showToast(message: ErrorMessage.noInternet)
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
        forwardTableView.reloadData()
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
        spinner.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: forwardTableView.bounds.size.width, height: CGFloat(64))
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

extension ForwardViewController {
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
                        self?.loadChatList()
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
                        self?.loadChatList()
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

extension ForwardViewController {

    func checkUserBusyStatusEnabled(_ controller: UIViewController, jid: String, completion: @escaping (Bool)->()) {
        if ChatManager.shared.isBusyStatusEnabled() && ContactManager.shared.getUserProfileDetails(for: jid)?.profileChatType == .singleChat {
            let alertController = UIAlertController.init(title: "Disable busy Status. Do you want to continue?" , message: "", preferredStyle: .alert)
            let forwardAction = UIAlertAction(title: "Yes", style: .default) {_ in
                ChatManager.shared.enableDisableBusyStatus(!ChatManager.shared.isBusyStatusEnabled())
                completion(true)
            }
            let cancelAction = UIAlertAction(title: "No", style: .cancel) { [weak controller] (action) in
                controller?.dismiss(animated: true,completion: nil)
                completion(false)
            }
            forwardAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
            cancelAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
            alertController.addAction(cancelAction)
            alertController.addAction(forwardAction)
            executeOnMainThread { [weak controller] in
                controller?.present(alertController, animated: true)
            }
        } else {
            completion(true)
        }
    }
}
