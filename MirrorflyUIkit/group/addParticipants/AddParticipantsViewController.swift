//
//  AddParticipantsViewController.swift
//  MirrorflyUIkit
//
//  Created by John on 23/11/21.
//

import UIKit
import MirrorFlySDK
import AudioToolbox
import RxSwift

protocol AddParticipantsDelegate: class {
    func updatedAddParticipants()
}

class AddParticipantsViewController: UIViewController {
    
    let groupCreationViewModel = GroupCreationViewModel()
    var groupCreationDeletgate : GroupCreationDelegate?
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var participantTableView: UITableView!
    
    weak var delegate: AddParticipantsDelegate? = nil
    
    var participants = [ProfileDetails]()
    var searchedParticipants = [ProfileDetails]()
    var existingParticipants: ProfileDetails!
    var filteredContacts = [String]()
    
    var isFromGroupInfo: Bool = false
    var groupID = ""
        
    var totalPages = 2
    var totalUsers = 0
    var nextPage = 1
    var searchTotalPages = 2
    var searchTotalUsers = 0
    var searchNextPage = 1
    var isLoadingInProgress = false
    var searchTerm = emptyString()
    let disposeBag = DisposeBag()
    var loadingCompleted = false
    let searchSubject = PublishSubject<String>()
    var internetObserver = PublishSubject<Bool>()
    var isFirstPageLoaded = false
    var networkLabel : UILabel? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        networkLable(message: ErrorMessage.noInternet)
        handleBackgroundAndForground()
        setUpUI()
        setUpTableView()
        getContacts()
        checkExistingGroup()
        NotificationCenter.default.addObserver(self, selector: #selector(self.contactSyncCompleted(notification:)), name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
        searchSubject.throttle(.milliseconds(25), scheduler: MainScheduler.instance).distinctUntilChanged().subscribe { [weak self] term in
            self?.searchTerm = term
            self?.searchedParticipants.removeAll()
            self?.participantTableView.reloadData()
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

    }
    
    @objc override func willCometoForeground() {
        if !ENABLE_CONTACT_SYNC{
            resetDataAndFetchUsersList()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(networkChange(_:)),name:Notification.Name(NetStatus.networkNotificationObserver),object: nil)
        resetSearch()
        participantTableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        ChatManager.shared.adminBlockDelegate = self
        ContactManager.shared.profileDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ChatManager.shared.adminBlockDelegate = nil
        ContactManager.shared.profileDelegate = nil
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NetStatus.networkNotificationObserver), object: nil)
    }
    
    func setUpUI() {
        setUpStatusBar()
        searchBar.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            participantTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height + participantTableView.rowHeight + 30, right: 0)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        participantTableView.contentInset = .zero
    }
    
    func setUpTableView() {
        participantTableView.delegate = self
        participantTableView.dataSource = self
        participantTableView.register(UINib(nibName: Identifiers.participantCell , bundle: .main), forCellReuseIdentifier: Identifiers.participantCell)
        participantTableView.register(UINib(nibName: Identifiers.noResultFound , bundle: .main),forCellReuseIdentifier: Identifiers.noResultFound)
    }
    
    
    @IBAction func didBackTap(_ sender: Any) {
        groupCreationViewModel.initializeGroupCreationData()
        navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func didNextTap(_ sender: Any) {
        
        if isFromGroupInfo == true {
            if GroupCreationData.participants.count == 0 {
                AppAlert.shared.showToast(message: "Please select minimum one Participant")
                return
            }
            groupCreationViewModel.addNewParticipantToGroup(groupID: groupID) { [weak self] success in
                if success {
                    self?.groupCreationViewModel.initializeGroupCreationData()
                    self?.navigationController?.popViewController(animated: true)
                    self?.delegate?.updatedAddParticipants()
                    AppAlert.shared.showToast(message: "Members added successfully")
                }
            }
            
        } else {
            if groupCreationViewModel.checkMaximumParticipant(selectedParticipant: GroupCreationData.participants) {
                AppAlert.shared.showToast(message: maximumGroupUsers)
                return
            }
            
            if groupCreationViewModel.checkMinimumParticipant(selectedParticipants: GroupCreationData.participants) {
                print("groupName\(GroupCreationData.groupName) imagePath\(GroupCreationData.groupImageLocalPath)                                selecteddd\(GroupCreationData.participants.count)")
                performSegue(withIdentifier: Identifiers.groupCreationPreview, sender: nil)
            } else {
                AppAlert.shared.showToast(message: atLeastTwoParticipant)
            }
        }
    }
    
    func getContacts() {
        if ENABLE_CONTACT_SYNC{
            groupCreationViewModel.getContacts(fromServer: false, completionHandler: { [weak self] (profiles, error) in
                if error != nil {
                    return
                }
                
                if self?.isFromGroupInfo == true {
                    self?.participants = (self?.groupCreationViewModel.removeExistingParticipants(groupID: self?.groupID ?? "", contacts: profiles ?? []) ?? []).sorted{ getUserName(jid: $0.jid,name: $0.name, nickName: $0.nickName, contactType: $0.contactType) < getUserName(jid: $1.jid,name: $1.name, nickName: $1.nickName, contactType: $1.contactType) }
                    self?.participantTableView.reloadData()
                } else {
                    
                    self?.participants = (profiles?.sorted{ getUserName(jid: $0.jid,name: $0.name, nickName: $0.nickName, contactType: $0.contactType) < getUserName(jid: $1.jid,name: $1.name, nickName: $1.nickName, contactType: $1.contactType) }) ?? []
                    self?.searchedParticipants = (profiles?.sorted{ getUserName(jid: $0.jid,name: $0.name, nickName: $0.nickName, contactType: $0.contactType) < getUserName(jid: $1.jid,name: $1.name, nickName: $1.nickName, contactType: $1.contactType) }) ?? []
                    self?.participantTableView.reloadData()
                }
            })
        } else {
            resetDataAndFetchUsersList()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Identifiers.groupCreationPreview {
            let groupCreationPreviewController = segue.destination as! GroupCreationPreviewController
            groupCreationPreviewController.groupCreationDeletgate = groupCreationDeletgate
        }
    }
    
    func checkExistingGroup() {
        if isFromGroupInfo {
            if participants.isEmpty {
                nextButton.alpha = 0.5
            } else {
                nextButton.alpha = 1.0
            }
            nextButton.setTitle("Add", for: .normal)
        } else {
            nextButton.setTitle("Next", for: .normal)
        }
    }
}

// TableViewDelegate
extension AddParticipantsViewController : UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchedParticipants.count > 0 {
            return searchedParticipants.count
        } else {
            if ENABLE_CONTACT_SYNC || isFirstPageLoaded{
                return 1
            }
            return 0
        }
    }
    
    private func getBlocked(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlocked ?? false
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if searchedParticipants.count > 0 {
            
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.participantCell, for: indexPath) as? ParticipantCell)!
            let profileDetail = searchedParticipants[indexPath.row]
            if getBlocked(jid: profileDetail.jid) {
                cell.contentView.alpha = 0.6
            } else {
                cell.contentView.alpha = 1.0
            }
            let name = getUserName(jid: profileDetail.jid,name: profileDetail.name, nickName: profileDetail.nickName, contactType: profileDetail.contactType)
            cell.nameUILabel?.text = name
            cell.statusUILabel?.text = profileDetail.status
            let hashcode = profileDetail.name.hashValue
            let color = getColor(userName: name)
            cell.removeButton?.isHidden = true
            cell.removeIcon?.isHidden = true
            cell.setImage(imageURL: profileDetail.image, name: getUserName(jid: profileDetail.jid,name: profileDetail.name, nickName: profileDetail.nickName, contactType: profileDetail.contactType), color: color, profile: profileDetail)
            cell.checkBoxImageView?.image = GroupCreationData.participants.contains(where: {$0.jid == profileDetail.jid}) ?  UIImage(named: ImageConstant.ic_checked) : UIImage(named: ImageConstant.ic_check_box)
            cell.setTextColorWhileSearch(searchText: searchBar.text ?? "", profileDetail: profileDetail)
            cell.emptyView?.isHidden = true
            return cell
        } else {
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.noResultFound, for: indexPath) as? NoResultFoundCell)!
            if NetworkReachability.shared.isConnected{
                if isFirstPageLoaded{
                    cell.messageLabel.text = "No Contacts Found"
                }else{
                    cell.messageLabel.text = ""
                }
            }else{
                cell.messageLabel.text = ErrorMessage.noInternet
            }
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searchedParticipants.count > indexPath.row {
            let profileDetail = searchedParticipants[indexPath.row]
            if getBlocked(jid: profileDetail.jid) {
                showBlockUnblockConfirmationPopUp(jid: profileDetail.jid, name: profileDetail.nickName)
                return
            }
            let cell = tableView.cellForRow(at: indexPath) as! ParticipantCell
            ContactManager.shared.saveUser(profileDetails: profileDetail, saveAs: .live)
            let jid = profileDetail.jid ?? ""
            if GroupCreationData.participants.contains(where: {$0.jid == jid}) {
                cell.checkBoxImageView?.image = UIImage(named: ImageConstant.ic_check_box)
                GroupCreationData.participants = groupCreationViewModel.removeSelectedParticipantJid(selectedParticipants: GroupCreationData.participants, participant: profileDetail)
            } else {
                cell.checkBoxImageView?.image = UIImage(named: ImageConstant.ic_checked)
                GroupCreationData.participants.append(profileDetail)
            }
        }
    }
    
    func resetSearch() {
        searchBar.text = ""
        if ENABLE_CONTACT_SYNC {
            searchedParticipants = groupCreationViewModel.searchContacts(text: "", contacts: participants)
        }
        searchBar.resignFirstResponder()
        dismissKeyboard()
    }
    
    private func getColor(userName : String) -> UIColor {
        return ChatUtils.getColorForUser(userName: userName)
    }
}

extension AddParticipantsViewController : UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String){
        if ENABLE_CONTACT_SYNC{
            searchedParticipants = groupCreationViewModel.searchContacts(text: searchText.trim(), contacts: participants)
            self.participantTableView.reloadData()
        }else {
            let searchString = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !searchString.isEmpty || self.searchTerm != searchString{
                resetParams()
                searchSubject.onNext(searchString.lowercased())
            }
        }
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.text = ""
        searchTerm = emptyString()
        if ENABLE_CONTACT_SYNC{
            searchedParticipants = participants
            self.participantTableView.reloadData()
        }else{
         resetDataAndFetchUsersList()
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
}

extension AddParticipantsViewController {
    @objc func contactSyncCompleted(notification: Notification) {
        if let contactSyncState = notification.userInfo?[FlyConstants.contactSyncState] as? String {
            switch ContactSyncState(rawValue: contactSyncState) {
            case .inprogress:
                break
            case .success:
                getContacts()
            case .failed:
                print("contact sync failed")
            case .none:
                print("contact sync failed")
            }
        }
    }
}

extension AddParticipantsViewController : AdminBlockDelegate {
    func didBlockOrUnblockContact(userJid: String, isBlocked: Bool) {
        checkingUserForBlocking(jid: userJid, isBlocked: isBlocked)
    }
    
    func didBlockOrUnblockSelf(userJid: String, isBlocked: Bool) {
       
    }
    
    func didBlockOrUnblockGroup(groupJid: String, isBlocked: Bool) {
        if isFromGroupInfo && groupID == groupJid && isBlocked {
            self.navigationController?.navigationBar.isHidden = false
            self.navigationController?.popToRootViewController(animated: true)
            executeOnMainThread {
                AppAlert.shared.showToast(message: groupNoLongerAvailable)
            }
        }
    }
    
}
// To handle user blocking by admin
extension AddParticipantsViewController : UIScrollViewDelegate {

    func checkingUserForBlocking(jid : String, isBlocked : Bool) {
        if isBlocked {
            participants = removeAdminBlockedContact(profileList: participants, jid: jid, isBlockedByAdmin: isBlocked)
            searchedParticipants = removeAdminBlockedContact(profileList: searchedParticipants, jid: jid, isBlockedByAdmin: isBlocked)
            GroupCreationData.participants = removeAdminBlockedContact(profileList: GroupCreationData.participants, jid: jid, isBlockedByAdmin: isBlocked)
        } else {
            participants = addUnBlockedContact(profileList: participants, jid: jid, isBlockedByAdmin: isBlocked)
            searchedParticipants = addUnBlockedContact(profileList: searchedParticipants, jid: jid, isBlockedByAdmin: isBlocked)
        }
        executeOnMainThread { [weak self] in
            self?.participantTableView.reloadData()
        }
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if ENABLE_CONTACT_SYNC{
            return
        }
        let position  = scrollView.contentOffset.y
         if position > participantTableView.contentSize.height-200 - scrollView.frame.size.height {
             if isPaginationCompleted(){
                 print("#fetch Pagination Done")
                 return
             }
            participantTableView.tableFooterView = createTableFooterView()
            if !isLoadingInProgress{
                isLoadingInProgress = true
                getUsersList(pageNo: searchTerm.isEmpty ? nextPage : searchNextPage, pageSize: 20, searchTerm: searchTerm)
            }else{
                print("#fetch Pagination inProgress")
            }
        }
    }
    
    
    public func getUsersList(pageNo : Int = 1, pageSize : Int =  40, searchTerm : String){
        print("#fetch request \(pageNo) \(pageSize) \(searchTerm) ")
        if pageNo == 1 {
            participantTableView.tableFooterView = createTableFooterView()
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
                            self.participants.removeAll()
                            self.searchedParticipants.removeAll()
                        }
                        self.participants.append(contentsOf: profileArray)
                        self.searchedParticipants.append(contentsOf: profileArray)
                    }else{
                        if pageNo == 1{
                            self.searchedParticipants.removeAll()
                        }
                        self.searchedParticipants.append(contentsOf: profileArray)
                    }
                    if self.isFromGroupInfo == true {
                        self.participants = self.groupCreationViewModel.removeExistingParticipants(groupID: self.groupID , contacts: self.participants)
                        self.searchedParticipants = self.groupCreationViewModel.removeExistingParticipants(groupID: self.groupID , contacts: self.searchedParticipants)
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
                    print("#fetch response \(self.totalPages) \(self.nextPage) \(self.totalUsers) \(self.participants.count) \(self.groupID)")
                }else{
                    if profilesCount >= pageSize{
                        self.searchNextPage += 1
                    }else{
                        self.loadingCompleted = true
                    }
                    self.searchTotalPages = data["totalPages"] as? Int ?? 1
                    self.searchTotalUsers = data["totalRecords"] as? Int ?? 1
                    print("#fetch response search \(self.searchTotalPages) \(self.searchNextPage) \(self.searchTotalUsers) \(self.participants.count) \(self.searchTerm)")
                }
                self.participantTableView.tableFooterView = nil
                self.participantTableView.reloadData()
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
    
    public func isPaginationCompleted() -> Bool {
        if searchTerm.isEmpty{
            if (totalPages < nextPage) || loadingCompleted {
                return true
            }
        }else{
            if (searchTotalPages < searchNextPage) || loadingCompleted {
                return true
            }
        }
        return false
    }
    
    public func resetDataAndFetchUsersList(){
        resetParams()
        searchedParticipants.removeAll()
        participantTableView.reloadData()
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
        loadingCompleted = false
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
        searchedParticipants.removeAll { pd in
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

extension AddParticipantsViewController : ProfileEventsDelegate{
    
    func userCameOnline(for jid: String) {
        
    }
    
    func userWentOffline(for jid: String) {
        
    }
    
    func userProfileFetched(for jid: String, profileDetails: ProfileDetails?) {
            
    }
    
    func myProfileUpdated() {
        
    }
    
    func usersProfilesFetched() {
        participantTableView.reloadData()
    }
    
    func blockedThisUser(jid: String) {
        
    }
    
    func unblockedThisUser(jid: String) {
        
    }
    
    func usersIBlockedListFetched(jidList: [String]) {
        
    }
    
    func usersBlockedMeListFetched(jidList: [String]) {
        getContacts()
    }
    
    func userUpdatedTheirProfile(for jid: String, profileDetails: ProfileDetails) {
        if !ENABLE_CONTACT_SYNC{
            if let index = searchedParticipants.firstIndex(where: { pd in
                pd.jid == jid
            }), index > -1 {
                searchedParticipants[index] = profileDetails
            }
        }
        participantTableView.reloadData()
    }
    
    func userBlockedMe(jid: String) {
        getContacts()
    }
    
    func userUnBlockedMe(jid: String) {
        getContacts()
    }
    
    func hideUserLastSeen() {
        
    }
    
    func getUserLastSeen() {
        
    }
    
    func userDeletedTheirProfile(for jid : String, profileDetails:ProfileDetails){
       getContacts()
        if GroupCreationData.participants.contains(where: {$0.jid == jid}) {
            GroupCreationData.participants = groupCreationViewModel.removeSelectedParticipantJid(selectedParticipants: GroupCreationData.participants, participant: profileDetails)
        }
    }
}

extension AddParticipantsViewController {

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
                        self?.getContacts()
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
                        self?.getContacts()
                        AppAlert.shared.showToast(message: "\(name ?? "") has been Unblocked")
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
}
