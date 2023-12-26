//
//  ContactInfoViewController.swift
//  MirrorflyUIkit
//
//  Created by John on 28/01/22.
//

import UIKit
import MirrorFlySDK
import SDWebImage

class ContactInfoViewController: BaseViewController {
    
    @IBOutlet weak var contactInfoTableView: UITableView?
    
    var contactJid = ""
    var profileDetails : ProfileDetails?
    var isFromGroupInfo: Bool = false
    var groupId = ""
    
    let contactInfoViewModel = ContactInfoViewModel()
    let contactInfoTitle = [email, mobileNumber, status]
    let contactInfoIcon = [ImageConstant.ic_info_email, ImageConstant.ic_info_phone, ImageConstant.ic_info_status]
    var delegate: RefreshProfileInfo?
    
    var availableFeatures = ChatManager.getAvailableFeatures()

    var isFromContactInfo: Bool = false
    var lockScreenShown: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if ChatManager.isPrivateChat(jid: contactJid) && isFromContactInfo {
            showLockScreen()
            self.view.addLaunchSubview()
        }

        setConfiguration()
        setUpUI()
        setUpStatusBar()
        getLastSeen()
        networkMonitor()
        NotificationCenter.default.addObserver(self, selector: #selector(self.contactSyncCompleted(notification:)), name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(enteredBackGround), name: UIScene.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(permissionAlertNotification), name: Notification.Name(FlyConstants.callPermissionAlertShown), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ContactManager.shared.profileDelegate = self
        ChatManager.shared.adminBlockDelegate = self
        ChatManager.shared.connectionDelegate = self
        ChatManager.shared.availableFeaturesDelegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground),
                                                       name: NSNotification.Name(didBecomeActive), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ContactManager.shared.profileDelegate = nil
        ChatManager.shared.adminBlockDelegate = nil
        ChatManager.shared.connectionDelegate = nil
        ChatManager.shared.availableFeaturesDelegate = nil
        delegate = nil
        self.view.removeLaunchSubview()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        handleBackgroundAndForground()
        availableFeatures = ChatManager.getAvailableFeatures()
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        lockScreenShown = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(FlyConstants.callPermissionAlertShown), object: nil)
    }

    override func willCometoForeground() {
        self.view.removeLaunchSubview()
        if lockScreenShown == false {
            if ChatManager.isPrivateChat(jid: contactJid) {
                showLockScreen()
                lockScreenShown = true
            }
        }
    }

    @objc func willEnterForeground() {
        self.view.removeLaunchSubview()
    }

    override func didMoveToBackground() {
        if ChatManager.isPrivateChat(jid: contactJid) {
            if !CommonDefaults.permissionAlertShown {
                self.view.addLaunchSubview()
            }
        }
    }

    @objc func enteredBackGround() {
        if ChatManager.isPrivateChat(jid: contactJid) {
            self.view.addLaunchSubview()
        }
    }

    @objc func permissionAlertNotification(notification: Notification) {
        if let status = notification.object as? Bool {
            CommonDefaults.permissionAlertShown = status
        }
    }
    
    private func setConfiguration(){
        if contactJid.isNotEmpty {
            profileDetails = contactInfoViewModel.getContactInfo(jid: contactJid)
        }
    }

    func showLockScreen() {
        if CommonDefaults.appFingerprintenable {
            let vc = PrivateChatFingerPrintPINViewController(nibName: "PrivateChatFingerPrintPINViewController", bundle: nil)
            vc.isFromContactInfo = isFromContactInfo
            self.navigationController?.pushViewController(vc, animated: false)
        } else {
            let vc = PrivateChatAuthenticationPINViewController(nibName:"PrivateChatAuthenticationPINViewController", bundle: nil)
            vc.isFromContactInfo = isFromContactInfo
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
    
    private func getLastSeen() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000), execute: { [weak self] in
            guard let self else {return}
            self.contactInfoViewModel.getLastSeen(jid: self.contactJid) { lastSeen in
                if lastSeen == "error" {
                    let indexPath = IndexPath(row: 0, section: 0)
                    if let cell = self.contactInfoTableView?.cellForRow(at: indexPath) as? ContactImageCell {
                        cell.onlineStatus?.text = emptyString()
                        cell.onlineStatus?.isHidden = true
                    }
                } else {
                    self.setLastSeen(lastSeen: lastSeen)
                }
            }
        })
    }
    
    private func setLastSeen(lastSeen : String) {
        let indexPath = IndexPath(row: 0, section: 0)
        if let cell = contactInfoTableView?.cellForRow(at: indexPath) as? ContactImageCell {
            let blockedByAdmin = profileDetails?.isBlockedByAdmin ?? false
            if (profileDetails?.contactType == .deleted || blockedByAdmin || getBlocked()) || getisBlockedMe() {
                cell.onlineStatus?.text = emptyString()
                cell.onlineStatus?.isHidden = true
            }else{
                cell.onlineStatus?.text = lastSeen
                cell.onlineStatus?.isHidden = false
            }
        }
    }
    
    private func getBlocked() -> Bool {
        return ChatManager.getContact(jid: contactJid)?.isBlocked ?? false
    }
    
    private func getisBlockedMe() -> Bool {
        return ChatManager.getContact(jid: contactJid)?.isBlockedMe ?? false
    }
    
    private func refreshData() {
        contactInfoTableView?.reloadData()
    }
    
    private func setUpUI() {
        navigationController?.navigationBar.isHidden = true
        setUpStatusBar()
        contactInfoTableView?.delegate = self
        contactInfoTableView?.dataSource = self
        
        contactInfoTableView?.register(UINib(nibName: Identifiers.contactInfoCell , bundle: .main), forCellReuseIdentifier: Identifiers.contactInfoCell)

        contactInfoTableView?.register(UINib(nibName: Identifiers.privateChatCell , bundle: .main), forCellReuseIdentifier: Identifiers.privateChatCell)
        
        contactInfoTableView?.register(UINib(nibName: Identifiers.viewAllMediaCell , bundle: .main), forCellReuseIdentifier: Identifiers.viewAllMediaCell)
        
        contactInfoTableView?.register(UINib(nibName: Identifiers.muteNotificationCell , bundle: .main), forCellReuseIdentifier: Identifiers.muteNotificationCell)
        
        contactInfoTableView?.register(UINib(nibName: Identifiers.contactImageCell , bundle: .main), forCellReuseIdentifier: Identifiers.contactImageCell)
    }
    
   
    
    @objc func didTapBack(sender : Any) {
        if isFromGroupInfo == true {
            navigationController?.navigationBar.isHidden = true
            navigationController?.popViewController(animated: true)
        } else {
            navigationController?.navigationBar.isHidden = false
            navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func didTapImage(sender : Any) {
        if let isBlocked = profileDetails?.isBlockedByAdmin, isBlocked || getisBlockedMe() {
            AppAlert.shared.showToast(message: thisUerIsNoLonger)
            return
        }
        if let image = profileDetails?.image, image.isNotEmpty {
            performSegue(withIdentifier: Identifiers.viewUserImageController, sender: self)
        }
    }
    
    @objc func stateChanged(switchState: UISwitch) {
        if switchState.isOn {
            contactInfoViewModel.muteNotification(jid: contactJid, mute: true)
        } else {
            contactInfoViewModel.muteNotification(jid: contactJid, mute: false)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Identifiers.viewUserImageController {
            let viewUserImageVC = segue.destination as! ViewUserImageController
            viewUserImageVC.profileDetails = profileDetails
        }
    }
    
    func networkMonitor() {
        if !NetworkReachability.shared.isConnected {
            DispatchQueue.main.async { [weak self] in
                self?.setLastSeen(lastSeen: waitingForNetwork)
            }
        }
        NetworkReachability.shared.netStatusChangeHandler = { [weak self] in
            print("networkMonitor \(NetworkReachability.shared.isConnected)")
            DispatchQueue.main.async {
                if NetworkReachability.shared.isConnected {
                    self?.getLastSeen()
                } else {
                    self?.setLastSeen(lastSeen: waitingForNetwork)
                }
            }
        }
    }
    
    func handleUserBlockedUnblocked(jid : String) {
        if jid == contactJid {
            setConfiguration()
            refreshData()
            getLastSeen()
        }
    }
}

extension ContactInfoViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 3 {
            return 3
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.contactImageCell, for: indexPath) as? ContactImageCell)!
            
            cell.backButton?.addTarget(self, action: #selector(didTapBack(sender:)), for: .touchUpInside)
            cell.editTextField.isHidden = true
            let name = getUserName(jid: profileDetails?.jid ?? "",name: profileDetails?.name ?? "", nickName: profileDetails?.nickName ?? "", contactType: profileDetails?.contactType ?? .unknown )
            cell.userNameLabel?.text = name
            let imageUrl = profileDetails?.image  ?? ""
            var placeholder : UIImage
            
            let isBlockedByAdmin = profileDetails?.isBlockedByAdmin ?? false
            if profileDetails?.contactType == .deleted || isBlockedByAdmin || getisBlockedMe() || (IS_LIVE && ENABLE_CONTACT_SYNC && profileDetails?.isItSavedContact == false) {
                cell.userImage?.image = UIImage(named: "ic_profile_placeholder") ?? UIImage()
                cell.userImage?.contentMode = .scaleAspectFit
                cell.userImage?.backgroundColor = UIColor.darkGray
                cell.onlineStatus?.text = ""
            }else{
                let imageUrl = profileDetails?.image
                let urlString = ChatManager.getImageUrl(imageName: imageUrl ?? emptyString())
                var url = URL(string: urlString)
                placeholder = ChatUtils.getPlaceholder(name: name, userColor: ChatUtils.getColorForUser(userName: name), userImage: cell.userImage ?? UIImageView(), isRounded: false)
                cell.userImage?.sd_imageIndicator = SDWebImageActivityIndicator.grayLarge
                cell.userImage?.sd_setImage(with: url, placeholderImage: placeholder)
            }
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapImage(sender:)))
            cell.userImage?.isUserInteractionEnabled = true
            cell.userImage?.addGestureRecognizer(gestureRecognizer)
            cell.editButton?.isHidden = true
            cell.editProfileButton?.isHidden = true
            
            return cell
        } else if indexPath.section == 1 {
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.muteNotificationCell, for: indexPath) as? MuteNotificationCell)!
            cell.muteSwitch?.addTarget(self, action: #selector(stateChanged), for: .valueChanged)
            cell.muteSwitch?.setOn(profileDetails?.isMuted ?? false, animated: true)
            cell.muteSwitch?.isEnabled = ChatManager.shared.isUserUnArchived(jid: profileDetails?.jid ?? "")
            return cell
        } else if indexPath.section == 2 {
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.privateChatCell, for: indexPath) as? PrivateChatCell)!

            if let recent = ChatManager.getRechtChat(jid: profileDetails?.jid ?? "") {
                if recent.isChatArchived {
                    cell.chatLabel.textColor = .gray
                } else {
                    cell.chatLabel.textColor = .label
                }
            }

            let tap = UITapGestureRecognizer(target: self, action: #selector(self.didTapPrivateChat(_:)))
            cell.addGestureRecognizer(tap)
            return cell
        } else if indexPath.section == 3 {
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.contactInfoCell, for: indexPath) as? ContactInfoCell)!
            
            cell.titleLabel?.text = contactInfoTitle[indexPath.row]
            cell.icon?.image = UIImage(named: contactInfoIcon[indexPath.row])
              
            let mobileNumberWithoutCountryCode = AppUtils.shared.mobileNumberParse(phoneNo: (profileDetails?.mobileNumber ?? ""))
              
            if indexPath.row == 0 {
                cell.contentLabel?.text = profileDetails?.email ?? ""
            } else if indexPath.row == 1 {
                cell.contentLabel?.text = mobileNumberWithoutCountryCode
            } else if indexPath.row == 2 {
                let isBlockedByAdmin = profileDetails?.isBlockedByAdmin ?? false
                if profileDetails?.contactType == .deleted || isBlockedByAdmin || getisBlockedMe() {
                    cell.contentLabel?.text = ""
                } else {
                    cell.contentLabel?.text = profileDetails?.status ?? ""
                }
            }
            
            return cell
        } else if indexPath.section == 4 {
            if availableFeatures.isViewAllMediasEnabled {
                let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.viewAllMediaCell, for: indexPath) as? ViewAllMediaCell)!
                cell.nextImage.isHidden = false
                cell.titleLabel.text = "View All Media"
                cell.titleLabel.textColor = Color.primaryTextColor
                cell.iconImageView.image = UIImage(named:"infoViewAllMedia")
                let tap = UITapGestureRecognizer(target: self, action: #selector(self.didTapViewAllMedia(_:)))
                cell.addGestureRecognizer(tap)
                return cell
            } else {
                let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.viewAllMediaCell, for: indexPath) as? ViewAllMediaCell)!
                cell.nextImage.isHidden = true
                cell.titleLabel.text = report
                cell.titleLabel.textColor = Color.leaveGroupTextColor
                cell.iconImageView.image = UIImage(named: ImageConstant.ic_info_report)
                let tap = UITapGestureRecognizer(target: self, action: #selector(self.didTapReport(_:)))
                cell.addGestureRecognizer(tap)
                return cell
            }
            
        } else if indexPath.section == 5 {
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.viewAllMediaCell, for: indexPath) as? ViewAllMediaCell)!
            cell.nextImage.isHidden = true
            cell.titleLabel.text = report
            cell.titleLabel.textColor = Color.leaveGroupTextColor
            cell.iconImageView.image = UIImage(named: ImageConstant.ic_info_report)
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.didTapReport(_:)))
            cell.addGestureRecognizer(tap)
            return cell
        }
        
        return UITableViewCell()
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if (profileDetails?.contactType != .deleted){
            
            if (!(availableFeatures.isViewAllMediasEnabled) && !(availableFeatures.isReportEnabled)){
                return 4
            }
            else if((availableFeatures.isViewAllMediasEnabled) && !(availableFeatures.isReportEnabled)) || (!(availableFeatures.isViewAllMediasEnabled) && (availableFeatures.isReportEnabled)) {
                return 5
            }
            else{
                return 6
            }
            
        }else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 2 {
            if ChatManager.getRechtChat(jid: profileDetails?.jid ?? "") == nil {
                return 0
            }
        }
        return UITableView.automaticDimension
    }
}

extension ContactInfoViewController : ProfileEventsDelegate {
    func userCameOnline(for jid: String) {
        if contactJid == jid {
            setLastSeen(lastSeen: online.localized)
        }
    }
    
    func userWentOffline(for jid: String) {
        if contactJid == jid {
            getLastSeen()
        }
    }
    
    func userProfileFetched(for jid: String, profileDetails: ProfileDetails?) {
        
    }
    
    func myProfileUpdated() {
        
    }
    
    func usersProfilesFetched() {
        if let profile = contactInfoViewModel.getContactInfo(jid: profileDetails?.jid ?? "") {
            profileDetails = profile
            refreshData()
            delegate?.refreshProfileDetails(profileDetails: profileDetails)
        }
    }
    
    func blockedThisUser(jid: String) {
        
    }
    
    func unblockedThisUser(jid: String) {
        
    }
    
    func usersIBlockedListFetched(jidList: [String]) {
        
    }
    
    func usersBlockedMeListFetched(jidList: [String]) {
        setConfiguration()
        contactInfoTableView?.reloadData()
    }
    
    func userUpdatedTheirProfile(for jid: String, profileDetails: ProfileDetails) {
        if jid ==  contactJid {
            let profile = ["jid": profileDetails.jid, "name": profileDetails.name, "image": profileDetails.image, "status": profileDetails.status]
            NotificationCenter.default.post(name: Notification.Name(FlyConstants.contactSyncState), object: nil, userInfo: profile as [AnyHashable : Any])
            self.profileDetails = profileDetails
            refreshData()
        }
    }
    
    func userBlockedMe(jid: String) {
        handleUserBlockedUnblocked(jid: jid)
    }
    
    func userUnBlockedMe(jid: String) {
        handleUserBlockedUnblocked(jid: jid)
    }
    
    func hideUserLastSeen() {
        getLastSeen()
    }
    
    func getUserLastSeen() {
    }
    
    func userDeletedTheirProfile(for jid : String, profileDetails:ProfileDetails){
        self.profileDetails = profileDetails
        contactInfoTableView?.reloadData()
        setLastSeen(lastSeen: emptyString())
        delegate?.refreshProfileDetails(profileDetails: profileDetails)
    }
    
}

extension ContactInfoViewController {
    @objc func contactSyncCompleted(notification: Notification){
        if let contactSyncState = notification.userInfo?[FlyConstants.contactSyncState] as? String {
            switch ContactSyncState(rawValue: contactSyncState) {
            case .inprogress:
                break
            case .success:
               setConfiguration()
            case .failed:
                print("contact sync failed")
            case .none:
                print("contact sync failed")
            }
        }
    }
}

extension ContactInfoViewController : AdminBlockDelegate {
    func didBlockOrUnblockContact(userJid: String, isBlocked: Bool) {
        if userJid == profileDetails?.jid ?? "" {
            profileDetails?.isBlockedByAdmin = isBlocked
            refreshData()
            getLastSeen()
        }
    }
    
    func didBlockOrUnblockSelf(userJid: String, isBlocked: Bool) {
        
    }
    
    func didBlockOrUnblockGroup(groupJid: String, isBlocked: Bool) {
        if isFromGroupInfo && groupId == groupJid  && isBlocked {
            self.navigationController?.navigationBar.isHidden = false
            self.navigationController?.popToRootViewController(animated: true)
            executeOnMainThread {
                AppAlert.shared.showToast(message: groupNoLongerAvailable)
            }
        }
    }
    
}

// For Reporting
extension ContactInfoViewController {
    
    @objc func didTapViewAllMedia(_ sender: UITapGestureRecognizer) {
        if let jid = profileDetails?.jid {
            let storyboard = UIStoryboard.init(name: Storyboards.chat, bundle: nil)
            let viewAllMediaVC = storyboard.instantiateViewController(withIdentifier: Identifiers.viewAllMediaVC) as! ViewAllMediaController
            viewAllMediaVC.jid = jid
            viewAllMediaVC.getProfileDetails = getProfileDetails
            self.navigationController?.pushViewController(viewAllMediaVC, animated: true)
        }
    }

    @objc func didTapPrivateChat(_ sender: UITapGestureRecognizer) {
        if let jid = profileDetails?.jid {
            if let recent = ChatManager.getRechtChat(jid: jid) {
                if recent.isChatArchived {
                    AppAlert.shared.showAlert(view: self, title: nil, message: unarchiveForPrivateLock, buttonOneTitle: "Unarchive", buttonTwoTitle: okButton)
                    AppAlert.shared.onAlertAction = { [weak self] (result)  ->
                        Void in
                        if result == 0 {
                            ChatManager.shared.updateArchiveUnArchiveChats(toUser: jid, archiveStatus: false)
                            self?.refreshData()
                        }
                    }
                } else {
                    let vc = PrivateChatEnableController(nibName: "PrivateChatEnableController", bundle: nil)
                    vc.chatJid = jid
                    vc.getProfileDetails = getProfileDetails
                    vc.fetchMessageListQuery = fetchMessageListQuery
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    @objc func didTapReport(_ sender: UITapGestureRecognizer) {
        
        if let isBlockedByAdmin = profileDetails?.isBlockedByAdmin, isBlockedByAdmin || getBlocked() {
            AppAlert.shared.showToast(message: thisUerIsNoLonger)
            return  
        }
        
        if ChatUtils.isMessagesAvailableFor(jid: profileDetails?.jid ?? "") {
            if let profileDetails = profileDetails {
                reportForJid(profileDetails: profileDetails)
            }
        } else {
            AppAlert.shared.showToast(message: noMessgesToReport)
        }
        
        // commented this code temporarly, It may be used in future
        
//        let values : [String] = ChatActions.allCases.map { $0.rawValue }
//        var actions = [(String, UIAlertAction.Style)]()
//        values.forEach { title in
//            actions.append((title, UIAlertAction.Style.default))
//        }
//
//        AppActionSheet.shared.showActionSeet(title: report, message: "", actions: actions) { [weak self] didCancelTap, tappedOption in
//            if !didCancelTap {
//                switch tappedOption {
//                case ChatActions.report.rawValue:
//                    print("\(tappedOption)")
//                    if ChatUtils.isMessagesAvailableFor(jid: self?.profileDetails?.jid ?? "") {
//                        if let profileDetails = self?.profileDetails {
//                            self?.reportForJid(profileDetails: profileDetails)
//                        }
//                    } else {
//                        AppAlert.shared.showToast(message: noMessgesToReport)
//                    }
//
//                default:
//                    print(" \(tappedOption)")
//                }
//            }
//        }
    }
}

extension ContactInfoViewController: ConnectionEventDelegate {
    func onConnectionFailed(error: FlyError) {
        
    }
    
    func onReconnecting() {
        
    }
    
    func onConnected() {
        getLastSeen()
    }
    
    func onDisconnected() {
        setLastSeen(lastSeen: waitingForNetwork)
    }
    
}

extension ContactInfoViewController : AvailableFeaturesDelegate {
    
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
        
        refreshData()
    }
}
