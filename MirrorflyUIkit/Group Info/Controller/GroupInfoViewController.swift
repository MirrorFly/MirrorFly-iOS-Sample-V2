//
//  GroupInfoViewController.swift
//  MirrorflyUIkit
//
//  Created by Prabakaran M on 03/03/22.
//

import UIKit
import Foundation
import AVFoundation
import MirrorFlySDK
import SDWebImage
import MobileCoreServices
import Photos
import Tatsi
import QCropper
import Contacts

protocol RefreshProfileInfo {
    func refreshProfileDetails(profileDetails:ProfileDetails?)
}

protocol GroupInfoDelegate {
    func didComefromGroupInfo()
}

class GroupInfoViewController: BaseViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var tableView: UITableView!
    
    let groupInfoViewModel = GroupInfoViewModel()
    
    var groupInfoDelegate : GroupInfoDelegate? = nil
    
    var profileDetails : ProfileDetails?
    var groupID = ""
    var currentGroupName = ""
    var groupMembers = [GroupParticipantDetail]()
    let contactInfoViewModel = ContactInfoViewModel()
    
    let imagePickerController = UIImagePickerController()
    var isImagePicked: Bool = false
    var previewImage: UIImage!
    var profileImage: UIImageView?
    var profileImageLocalPath = String()
    var lastSelectedCollection: PHAssetCollection?
    var isAdminMember: Bool = false
    var isExistMember: Bool = false
    var delegate: RefreshProfileInfo?
    var isGroupInfoUpdated: Bool = false
    var firstView: TatsiConfig.StartView {
        if let lastCollection = self.lastSelectedCollection {
            return .album(lastCollection)
        } else {
            return .userLibrary
        }
    }
    
    var availableFeatures = ChatManager.getAvailableFeatures()
    
    var optionsController : GroupInfoOptionsViewController?
    var lockScreenShown: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setupConfiguration()
        getGroupMembers()
        getParticipants()
        checkMemberExist()
        isAdminMemberGroup()
        refreshData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        handleBackgroundAndForground()
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        isGroupInfoUpdated = false
        refreshData()
        getGroupMembers()
        if groupInfoViewModel.isBlockedByAdmin(groupJid: groupID) {
            navigateOnGroupBlock()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground),
                                                       name: NSNotification.Name(didBecomeActive), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(permissionAlertNotification), name: Notification.Name(FlyConstants.callPermissionAlertShown), object: nil)
        availableFeatures = ChatManager.getAvailableFeatures()
        lockScreenShown = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        GroupManager.shared.groupDelegate = self
        ContactManager.shared.profileDelegate = self
        ChatManager.shared.adminBlockDelegate = self
        ChatManager.shared.availableFeaturesDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GroupManager.shared.groupDelegate = nil
        ContactManager.shared.profileDelegate = nil
        ChatManager.shared.adminBlockDelegate = nil
        ChatManager.shared.availableFeaturesDelegate = nil
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(FlyConstants.callPermissionAlertShown), object: nil)
    }

    override func willCometoForeground() {
        self.view.removeLaunchSubview()
    }

    @objc func willEnterForeground() {
        self.view.removeLaunchSubview()
    }
    
    override func didMoveToBackground() {
        if ChatManager.isPrivateChat(jid: groupID) {
            if !CommonDefaults.permissionAlertShown {
                self.view.addLaunchSubview()
            }
            if lockScreenShown == false {
                lockScreenShown = true
            }
        }
    }

    @objc func permissionAlertNotification(notification: Notification) {
            if let status = notification.object as? Bool {
                CommonDefaults.permissionAlertShown = status
            }
        }
    
    private func setUpUI() {
        setUpStatusBar()
        navigationController?.navigationBar.isHidden = true
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView?.register(UINib(nibName: Identifiers.contactImageCell, bundle: .main),
                            forCellReuseIdentifier: Identifiers.contactImageCell)
        tableView?.register(UINib(nibName: Identifiers.contactInfoCell, bundle: .main),
                            forCellReuseIdentifier: Identifiers.contactInfoCell)
        tableView?.register(UINib(nibName: Identifiers.muteNotificationCell, bundle: .main),
                            forCellReuseIdentifier: Identifiers.muteNotificationCell)
        tableView?.register(UINib(nibName: Identifiers.groupOptionsTableViewCell, bundle: .main),
                            forCellReuseIdentifier: Identifiers.groupOptionsTableViewCell)
        tableView?.register(UINib(nibName: Identifiers.groupMembersTableViewCell, bundle: .main),
                            forCellReuseIdentifier: Identifiers.groupMembersTableViewCell)
        tableView?.register(UINib(nibName: Identifiers.viewAllMediaCell , bundle: .main), forCellReuseIdentifier: Identifiers.viewAllMediaCell)
        tableView?.register(UINib(nibName: Identifiers.privateChatCell , bundle: .main), forCellReuseIdentifier: Identifiers.privateChatCell)
    }
    
    private func setupConfiguration() {
        if groupID.isNotEmpty {
            profileDetails = groupInfoViewModel.getContactInfo(jid: groupID)
        }
    }
    
    private func refreshData() {
        tableView?.reloadData()
    }
    
    private func updateGroupProfileImage(selectedImage: UIImage) {
        let indexPath = IndexPath(row: 0, section: 0)
        if let cell = tableView?.cellForRow(at: indexPath) as? ContactImageCell {
            cell.userImage?.image = selectedImage
        }
    }
    
    // MARK: User Intractions
    
    @objc
    func didTapBack(sender : Any) {
        navigationController?.navigationBar.isHidden = false
        navigationController?.popViewController(animated: true)
        if isGroupInfoUpdated {
            delegate?.refreshProfileDetails(profileDetails: profileDetails)
        }
        groupInfoDelegate?.didComefromGroupInfo()
    }
    
    @objc
    func didTapImage(sender : Any) {
        if let image = profileDetails?.image, image.isNotEmpty {
            performSegue(withIdentifier: Identifiers.viewUserImageController, sender: self)
        }
    }
    
    @objc
    func stateChanged(switchState: UISwitch) {
        if switchState.isOn {
            profileDetails?.isMuted = true
            groupInfoViewModel.muteNotification(jid: groupID, mute: true)
        } else {
            profileDetails?.isMuted = false
            groupInfoViewModel.muteNotification(jid: groupID, mute: false)
        }
    }
    
    @objc
    func updateGroupProfileAction(sender: Any) {
        if self.profileDetails?.image == "" {
            isImagePicked = false
        } else {
            isImagePicked = true
        }
        showActionSheet()
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
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Identifiers.viewUserImageController {
            let viewUserImageVC = segue.destination as! ViewUserImageController
            viewUserImageVC.profileDetails = profileDetails
        }
    }
    
    // MARK: Private Methods
    
    func getGroupMembers() {
      //  groupMembers = [GroupParticipantDetail]()
        let myJid = try? FlyUtils.getMyJid()
        let getGroupMembers = GroupManager.shared.getGroupMemebersFromLocal(groupJid: groupID).participantDetailArray.filter({$0.memberJid != myJid})
        //if groupMembers != getGroupMembers {
            groupMembers = getGroupMembers
            let myMember = GroupManager.shared.getGroupMemebersFromLocal(groupJid: groupID).participantDetailArray.filter({$0.memberJid == myJid})
            groupMembers = groupMembers.sorted(by: { $0.profileDetail?.name.lowercased() ?? "" < $1.profileDetail?.name.lowercased() ?? "" })
            groupMembers.append(contentsOf: myMember)

        //}
        if groupMembers != getGroupMembers {
            refreshData()
        }
    }
    
    func getParticipants() {
        GroupManager.shared.getParticipants(groupJID: groupID)
    }
    
    func checkMemberExist() {
        let isExistMember = self.groupInfoViewModel.isParticiapntExistingIn(groupJid: groupID,
                                                                            participantJid: AppUtils.getMyJid())
        self.isExistMember = isExistMember.doesExist
    }
    
    func isAdminMemberGroup() {
        let myJid = try? FlyUtils.getMyJid()
        let isAdminMember = self.groupInfoViewModel.isGroupAdminMember(participantJid: AppUtils.getMyJid(),
                                                                       groupJid: groupID)
        
        self.isAdminMember = isAdminMember.isAdmin
        
    }
    
    // MARK: Remove Profile Image
    
    func removeProfileImage(fileUrl : String){
        
        if groupInfoViewModel.isBlockedByAdmin(groupJid: groupID) {
            return
        }
        
        if NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: profilePictureRemoved.localized)
            ContactManager.shared.removeProfileImage( completionHandler: { isSuccess, flyError, flyData in
                var data  = flyData
                if isSuccess {
                    print(data.getMessage() as! String)
//                    FlyDefaults.myProfileImageUrl = ""
                } else {
                    print(data.getMessage() as! String)
                }
            })
        } else {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
        }
    }
    
    func removeGroupProfileImage(fileUrl : String) {
        
        if groupInfoViewModel.isBlockedByAdmin(groupJid: groupID) {
            return
        }
        
        if NetworkReachability.shared.isConnected {
            groupInfoViewModel.removeGroupProfileImage(groupID: groupID) {  [weak self] success, error, result in
                if success {
                    AppAlert.shared.showToast(message: "Group profile image removed successfully")
                    self?.isImagePicked = false
                    self?.profileDetails?.image = ""
                    self?.refreshData()
                } else {
                    AppAlert.shared.showToast(message: (result["message"] as? String)!)
                    self?.refreshData()
                }
            }
        } else {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
        }
    }
}

extension GroupInfoViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if ((availableFeatures.isViewAllMediasEnabled) && (availableFeatures.isReportEnabled) && (availableFeatures.isDeleteChatEnabled)){
            return 8
        }else if (!(availableFeatures.isViewAllMediasEnabled) && !(availableFeatures.isReportEnabled) && (!(availableFeatures.isDeleteChatEnabled) && isExistMember == false)){
            return 5
        }else if (!(availableFeatures.isViewAllMediasEnabled) && !(availableFeatures.isReportEnabled) && (!(availableFeatures.isDeleteChatEnabled) && isExistMember == true)){
            return 6
        }
        else if((availableFeatures.isViewAllMediasEnabled) && !(availableFeatures.isReportEnabled) && (!(availableFeatures.isDeleteChatEnabled) && isExistMember == false)) || (!(availableFeatures.isViewAllMediasEnabled) && (!(availableFeatures.isDeleteChatEnabled) && isExistMember == false) && (availableFeatures.isReportEnabled)) || (!(availableFeatures.isViewAllMediasEnabled) && !(availableFeatures.isReportEnabled) && (availableFeatures.isDeleteChatEnabled)) {
            return 6
        }else if((availableFeatures.isViewAllMediasEnabled) && !(availableFeatures.isReportEnabled) && (!(availableFeatures.isDeleteChatEnabled) && isExistMember == true)) || (!(availableFeatures.isViewAllMediasEnabled) && (!(availableFeatures.isDeleteChatEnabled) && isExistMember == true) && (availableFeatures.isReportEnabled)) {
            return 7
        }
        else if(!(availableFeatures.isViewAllMediasEnabled) && (availableFeatures.isReportEnabled) && (availableFeatures.isDeleteChatEnabled)) || ((availableFeatures.isViewAllMediasEnabled) && !(availableFeatures.isReportEnabled) && (availableFeatures.isDeleteChatEnabled)) || ((availableFeatures.isViewAllMediasEnabled) && (availableFeatures.isReportEnabled) && (!(availableFeatures.isDeleteChatEnabled) && isExistMember == false)) {
            return 7
        }else {
            return 8
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 4 {
            return groupMembers.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 3 {
            if isExistMember == false {
                return 0
            } else if isAdminMember == false {
                return 0
            } else {
                return UITableView.automaticDimension
            }
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.contactImageCell,
                                                      for: indexPath) as? ContactImageCell)!
            
            _ = (profileDetails?.name.isEmpty ?? false) ?
            profileDetails?.nickName : profileDetails?.name
            cell.userNameLabel?.isHidden = true
            cell.editTextField.font = AppFont.Medium.size(18)
            cell.editTextField.text = getUserName(jid: profileDetails?.jid ?? "" ,name: profileDetails?.name ?? "",
                                                  nickName: profileDetails?.nickName ?? "", contactType: profileDetails?.contactType ?? .unknown)
            cell.onlineStatus?.text = ("\(groupMembers.count) Participants")
            cell.onlineStatus?.font = AppFont.Light.size(12)
            let imageUrl = profileDetails?.image ?? ""
            cell.userImage?.sd_imageIndicator = SDWebImageActivityIndicator.grayLarge
            cell.userImage?.loadFlyImage(imageURL: imageUrl, name: getUserName(jid: profileDetails?.jid ?? "", name: profileDetails?.name ?? "", nickName: profileDetails?.nickName ?? "", contactType: profileDetails?.contactType ?? .local), chatType: profileDetails?.profileChatType ?? .groupChat, jid: profileDetails?.jid ?? "")
            let gestureRecognizer = UITapGestureRecognizer(target: self,
                                                           action: #selector(didTapImage(sender:)))
            cell.userImage?.isUserInteractionEnabled = true
            cell.userImage?.addGestureRecognizer(gestureRecognizer)
            cell.editButton?.isHidden = true
            cell.editProfileButton?.isHidden = false
            cell.delegate = self
            
            cell.backButton?.addTarget(self, action: #selector(didTapBack(sender:)),
                                       for: .touchUpInside)
            cell.editProfileButton?.addTarget(self,
                                              action: #selector(updateGroupProfileAction(sender:)),
                                              for: .touchUpInside)
            
            if isExistMember == false {
                cell.editProfileButton?.isHidden = true
                cell.editTextField.isUserInteractionEnabled = false
            }
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
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.groupOptionsTableViewCell, for: indexPath) as? GroupOptionsTableViewCell)!
            cell.optionImageview.image = UIImage(named: "add_user")
            cell.optionLabel.textColor = Color.userNameTextColor
            cell.optionLabel.text = addParticipants
            tableView.beginUpdates()
            tableView.endUpdates()
            return cell
            
        } else if indexPath.section == 4 {
            let groupMembers = groupMembers[indexPath.row]
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.groupMembersTableViewCell, for: indexPath) as? GroupMembersTableViewCell)!
            cell.getGroupInfo(groupInfo: groupMembers)
            return cell
        } else if indexPath.section == 5 {
            if availableFeatures.isViewAllMediasEnabled {
                let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.viewAllMediaCell, for: indexPath) as? ViewAllMediaCell)!
                return cell
            }else if availableFeatures.isReportEnabled {
                let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.groupOptionsTableViewCell, for: indexPath) as? GroupOptionsTableViewCell)!
                cell.optionImageview.image = UIImage(named: ImageConstant.ic_group_report)
                cell.optionLabel.textColor = Color.leaveGroupTextColor
                cell.optionLabel.text = reportGroup
                return cell
            }else {
                let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.groupOptionsTableViewCell, for: indexPath) as? GroupOptionsTableViewCell)!
                if isExistMember == true {
                    cell.optionImageview.image = UIImage(named: "leave_group")
                    cell.optionLabel.textColor = Color.leaveGroupTextColor
                    cell.optionLabel.text = leavegroup
                } else {
                    cell.optionImageview.image = UIImage(named: "ic_deletegroup")
                    cell.optionLabel.textColor = Color.leaveGroupTextColor
                    cell.optionLabel.text = deleteGroup
                }
                return cell
            }
        } else if indexPath.section == 6 {
            if availableFeatures.isViewAllMediasEnabled && availableFeatures.isReportEnabled {
                let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.groupOptionsTableViewCell, for: indexPath) as? GroupOptionsTableViewCell)!
                cell.optionImageview.image = UIImage(named: ImageConstant.ic_group_report)
                cell.optionLabel.textColor = Color.leaveGroupTextColor
                cell.optionLabel.text = reportGroup
                return cell
            } else {
                let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.groupOptionsTableViewCell, for: indexPath) as? GroupOptionsTableViewCell)!
                if isExistMember == true {
                    cell.optionImageview.image = UIImage(named: "leave_group")
                    cell.optionLabel.textColor = Color.leaveGroupTextColor
                    cell.optionLabel.text = leavegroup
                } else {
                    cell.optionImageview.image = UIImage(named: "ic_deletegroup")
                    cell.optionLabel.textColor = Color.leaveGroupTextColor
                    cell.optionLabel.text = deleteGroup
                }
                return cell
            }
        } else if indexPath.section == 7 {
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.groupOptionsTableViewCell, for: indexPath) as? GroupOptionsTableViewCell)!
            if isExistMember == true {
                cell.optionImageview.image = UIImage(named: "leave_group")
                cell.optionLabel.textColor = Color.leaveGroupTextColor
                cell.optionLabel.text = leavegroup
            } else {
                cell.optionImageview.image = UIImage(named: "ic_deletegroup")
                cell.optionLabel.textColor = Color.leaveGroupTextColor
                cell.optionLabel.text = deleteGroup
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 3 {
            if self.isAdminMember == true {
                let contactPermissionStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
                if contactPermissionStatus == .denied {
                    AppAlert.shared.contactAccess(view: self,
                                                  title: contactAccessTitle,
                                                  message: contactAccessMessage,
                                                  settingstitle: settings,
                                                  cancelTitle: cancelUppercase)
                    ContactSyncManager.updateContactPermission(isSkipped: false)
                } else {
                    let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
                    let controller = storyboard.instantiateViewController(withIdentifier: Identifiers.addParticipants) as! AddParticipantsViewController
                    controller.isFromGroupInfo = true
                    controller.groupID = groupID
                    controller.delegate = self
                    self.navigationController?.pushViewController(controller, animated: true)
                }
            } else {
                AppAlert.shared.showToast(message: adminAccess)
            }
        } else if indexPath.section == 4 {
            let groupMembers = groupMembers[indexPath.row]
            if groupMembers.memberJid != AppUtils.getMyJid() {
                let storyboard = UIStoryboard.init(name: Storyboards.chat, bundle: nil)
                optionsController = storyboard.instantiateViewController(withIdentifier: Identifiers.groupInfoOptionsViewController) as! GroupInfoOptionsViewController
                if let optionsController = optionsController {
                    optionsController.modalPresentationStyle = .overCurrentContext
                    optionsController.modalTransitionStyle = .crossDissolve
                    optionsController.groupInfoViewController = self
                    optionsController.delegate = self
                    optionsController.groupID = groupID
                    optionsController.userJid = groupMembers.memberJid
                    optionsController.userName = getUserName(jid: groupMembers.profileDetail?.jid ?? "", name: groupMembers.profileDetail?.name ?? "", nickName: groupMembers.profileDetail?.nickName ?? "", contactType: groupMembers.profileDetail?.contactType ?? .unknown)
                    optionsController.isAdminMember = self.isAdminMember
                    self.present(optionsController, animated: true, completion: nil)
                }
            }
        } else if indexPath.section == 5 {
            if availableFeatures.isViewAllMediasEnabled {
                let storyboard = UIStoryboard.init(name: Storyboards.chat, bundle: nil)
                let viewAllMediaVC = storyboard.instantiateViewController(withIdentifier: Identifiers.viewAllMediaVC) as! ViewAllMediaController
                viewAllMediaVC.jid = groupID
                self.navigationController?.pushViewController(viewAllMediaVC, animated: true)
            } else if availableFeatures.isReportEnabled {
                showReportOptions()
            }else{
                if isExistMember == true {
                    AppAlert.shared.showAlert(view: self,
                                              title: exitGroup,
                                              message: exitGroupMessage,
                                              buttonOneTitle: exitButton,
                                              buttonTwoTitle: noButton)
                    AppAlert.shared.onAlertAction = { [weak self] (result) -> Void in
                        
                        let isBlocked = self?.groupInfoViewModel.isBlockedByAdmin(groupJid: self?.groupID ?? "") ?? false
                        
                        if result == 0 && !isBlocked{
                            let groupMembers = self?.groupMembers[indexPath.row]
                            self?.leaveFromGroup()
                        }
                    }
                } else {
                    if(availableFeatures.isDeleteChatEnabled) {
                        AppAlert.shared.showAlert(view: self,
                                                  title: deleteGroup,
                                                  message: deleteGroupDescription,
                                                  buttonOneTitle: deleteText,
                                                  buttonTwoTitle: cancelUppercase)
                        AppAlert.shared.onAlertAction = { [weak self] (result) -> Void in
                        
                        let isBlocked = self?.groupInfoViewModel.isBlockedByAdmin(groupJid: self?.groupID ?? "") ?? false
                        
                        if result == 0 && !isBlocked{
                            
                            self?.groupInfoViewModel.deleteGroup(groupID: self?.groupID ?? "") {
                                [weak self] success, error, result  in
                                if success {
                                    AppAlert.shared.showToast(message: deleteGroupMessage)
                                    self?.navigationController?.navigationBar.isHidden = false
                                    self?.navigationController?.popToRootViewController(animated: true)
                                } else {
                                    AppActionSheet.shared.dismissActionSeet(animated: true)
                                    AppAlert.shared.showAlert(view: self!, title: "" , message: (result["message"] as? String ?? ""), buttonTitle: "OK")
                                    AppAlert.shared.onAlertAction = nil
                                }
                            }
                        }
                    }
                    }else {
                        AppActionSheet.shared.dismissActionSeet(animated: true)
                        AppAlert.shared.showAlert(view: self, title: "" , message: FlyConstants.ErrorMessage.forbidden, buttonTitle: "OK")
                        AppAlert.shared.onAlertAction = nil
                    }
                }
            }
        } else if indexPath.section == 6 {
            if availableFeatures.isViewAllMediasEnabled && availableFeatures.isReportEnabled {
                showReportOptions()
            }else {
                if isExistMember == true {
                    AppAlert.shared.showAlert(view: self,
                                              title: exitGroup,
                                              message: exitGroupMessage,
                                              buttonOneTitle: exitButton,
                                              buttonTwoTitle: noButton)
                    AppAlert.shared.onAlertAction = { [weak self] (result) -> Void in
                        
                        let isBlocked = self?.groupInfoViewModel.isBlockedByAdmin(groupJid: self?.groupID ?? "") ?? false
                        
                        if result == 0 && !isBlocked{
                            let groupMembers = self?.groupMembers[indexPath.row]
                            self?.leaveFromGroup()
                        }
                    }
                } else {
                    if(availableFeatures.isDeleteChatEnabled) {
                        AppAlert.shared.showAlert(view: self,
                                                  title: deleteGroup,
                                                  message: deleteGroupDescription,
                                                  buttonOneTitle: deleteText,
                                                  buttonTwoTitle: cancelUppercase)
                        AppAlert.shared.onAlertAction = { [weak self] (result) -> Void in
                            
                            let isBlocked = self?.groupInfoViewModel.isBlockedByAdmin(groupJid: self?.groupID ?? "") ?? false
                            
                            if result == 0 && !isBlocked{
                                
                                self?.groupInfoViewModel.deleteGroup(groupID: self?.groupID ?? "") {
                                    [weak self] success, error, result  in
                                    if success {
                                        AppAlert.shared.showToast(message: deleteGroupMessage)
                                        self?.navigationController?.navigationBar.isHidden = false
                                        self?.navigationController?.popToRootViewController(animated: true)
                                    } else {
                                        AppActionSheet.shared.dismissActionSeet(animated: true)
                                        AppAlert.shared.showAlert(view: self!, title: "" , message: (result["message"] as? String ?? ""), buttonTitle: "OK")
                                        AppAlert.shared.onAlertAction = nil
                                    }
                                }
                            }
                        }
                    } else {
                        AppActionSheet.shared.dismissActionSeet(animated: true)
                        AppAlert.shared.showAlert(view: self, title: "" , message: FlyConstants.ErrorMessage.forbidden, buttonTitle: "OK")
                        AppAlert.shared.onAlertAction = nil
                    }
                }
            }
        } else if indexPath.section == 7 {
            if isExistMember == true {
                AppAlert.shared.showAlert(view: self,
                                          title: exitGroup,
                                          message: exitGroupMessage,
                                          buttonOneTitle: exitButton,
                                          buttonTwoTitle: noButton)
                AppAlert.shared.onAlertAction = { [weak self] (result) -> Void in
                    
                    let isBlocked = self?.groupInfoViewModel.isBlockedByAdmin(groupJid: self?.groupID ?? "") ?? false
                    
                    if result == 0 && !isBlocked{
                        let groupMembers = self?.groupMembers[indexPath.row]
                        self?.leaveFromGroup()
                    }
                }
            } else {
                if(availableFeatures.isDeleteChatEnabled) {
                    AppAlert.shared.showAlert(view: self,
                                              title: deleteGroup,
                                              message: deleteGroupDescription,
                                              buttonOneTitle: deleteText,
                                              buttonTwoTitle: cancelUppercase)
                    AppAlert.shared.onAlertAction = { [weak self] (result) -> Void in
                        
                        let isBlocked = self?.groupInfoViewModel.isBlockedByAdmin(groupJid: self?.groupID ?? "") ?? false
                        
                        if result == 0 && !isBlocked{
                            
                            self?.groupInfoViewModel.deleteGroup(groupID: self?.groupID ?? "") {
                                [weak self] success, error, result  in
                                if success {
                                    AppAlert.shared.showToast(message: deleteGroupMessage)
                                    self?.navigationController?.navigationBar.isHidden = false
                                    self?.navigationController?.popToRootViewController(animated: true)
                                } else {
                                    AppActionSheet.shared.dismissActionSeet(animated: true)
                                    AppAlert.shared.showAlert(view: self!, title: "" , message: (result["message"] as? String ?? ""), buttonTitle: "OK")
                                    AppAlert.shared.onAlertAction = nil
                                }
                            }
                        }
                    }
                } else {
                    AppActionSheet.shared.dismissActionSeet(animated: true)
                    AppAlert.shared.showAlert(view: self, title: "" , message: FlyConstants.ErrorMessage.forbidden, buttonTitle: "OK")
                    AppAlert.shared.onAlertAction = nil
                }
            }
        }
    }
}

extension GroupInfoViewController: ContactImageCellDelegate {
    
    func leaveFromGroup() {
        if groupInfoViewModel.isBlockedByAdmin(groupJid: groupID) {
            return
        }
        startLoading(withText: pleaseWait)
        groupInfoViewModel.leaveFromGroup(groupID: groupID,userJid: AppUtils.getMyJid()) {
            [weak self] success in
            self?.stopLoading()
            if success {
                AppAlert.shared.showToast(message: leftFromgroup)
                self?.navigationController?.navigationBar.isHidden = false
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func updatedGroupName(groupName: String) {
        
        if groupInfoViewModel.isBlockedByAdmin(groupJid: groupID) {
            return
        }
        
        if groupName.trim().count == 0 {
            AppAlert.shared.showAlert(view: self, title: "Alert",
                                      message: "Kindly enter valid group name", buttonTitle: "OK")
        } else if groupName != currentGroupName {
            startLoading(withText: pleaseWait)
            groupInfoViewModel.updateGroupName(groupID: groupID, groupName: groupName) {
                [weak self] success, error, result  in
                if success {
                    self?.setupConfiguration()
                    self?.refreshData()
                    self?.isGroupInfoUpdated = true
                } else {
                    AppAlert.shared.showToast(message: "Please try again later")
                }
                self?.stopLoading()
            }
        }
    }
}

extension GroupInfoViewController: AddParticipantsDelegate {
    func updatedAddParticipants() {
        getGroupMembers()
        refreshData()
    }
}

extension GroupInfoViewController: GroupInfoOptionsDelegate {
    
    func makeGroupAdmin(groupID: String, userJid: String, userName: String) {
        
        AppAlert.shared.showAlert(view: self,
                                  title: makeAdminText,
                                  message: ("\(makeAdminDescription) \(userName)"),
                                  buttonOneTitle: adminText,
                                  buttonTwoTitle: cancelUppercase)
        AppAlert.shared.onAlertAction = { [weak self] (result) -> Void in
            
            let isBlocked = self?.groupInfoViewModel.isBlockedByAdmin(groupJid: self?.groupID ?? "") ?? false
            
            if result == 0 && !isBlocked{
                executeOnMainThread {
                    self?.startLoading(withText: pleaseWait)
                }
                
                self?.groupInfoViewModel.makeGroupAdmin(groupID: groupID, userJid: userJid) {
                    [weak self] success, error, result in
                    if self?.isAdminMember == true {
                        if success {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                                self?.getGroupMembers()
                                self?.refreshData()
                                AppAlert.shared.showToast(message: makeAdminStatus)
                            }
                        } else {
                            AppAlert.shared.showToast(message: (result["message"] as? String)!)
                        }
                    } else {
                        self?.getGroupMembers()
                        self?.refreshData()
                        AppAlert.shared.showToast(message: adminAccess)
                    }
                    executeOnMainThread {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self?.stopLoading()
                        }
                    }
                }
            }
        }
    }
    
    func removeParticipant(groupID: String, removeGroupMemberJid: String, userName: String) {
        AppAlert.shared.showAlert(view: self, title: removeTitle,
                                  message: ("\(removeDescription) \(userName)"),
                                  buttonOneTitle: removeTitle, buttonTwoTitle: cancelUppercase)
        AppAlert.shared.onAlertAction = { [weak self] (result) -> Void in
            let isBlocked = self?.groupInfoViewModel.isBlockedByAdmin(groupJid: self?.groupID ?? "") ?? false
            if result == 0 && !isBlocked {
                self?.groupInfoViewModel.removeParticipantFromGroup(groupID: groupID, removeGroupMemberJid: removeGroupMemberJid) { [weak self] success in
                    if self?.isAdminMember == true {
                        if success {
                            self?.getGroupMembers()
                            self?.refreshData()
                            AppAlert.shared.showToast(message: removeUserStatus)
                        }
                    } else {
                        self?.getGroupMembers()
                        self?.refreshData()
                        AppAlert.shared.showToast(message: adminAccess)
                    }
                }
            }
        }
    }
    
    func navigateToUserProfile(userJid: String) {
        let storyboard = UIStoryboard.init(name: Storyboards.chat, bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: Identifiers.contactInfoViewController) as! ContactInfoViewController
        controller.contactJid = userJid
        controller.isFromGroupInfo = true
        controller.groupId = groupID
        controller.isFromContactInfo = true
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func navigateToChat(userJid: String) {
        if let profile = groupMembers.filter({$0.memberJid == userJid}).first {
            let storyboard = UIStoryboard.init(name: Storyboards.chat, bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: Identifiers.chatViewParentController) as! ChatViewParentController
            controller.getProfileDetails = profile.profileDetail
            controller.isFromGroupInfo = true
            controller.groupIdForPrivateChat = groupID
            let color = getColor(userName: profile.profileDetail?.name ?? "")
            controller.contactColor = color
            groupInfoDelegate?.didComefromGroupInfo()
            navigationController?.modalPresentationStyle = .fullScreen
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func hanldeUserBlockedUnblocked(jid : String) {
        if let member = groupMembers.filter({$0.memberJid == jid}).first {
            if let profile = groupInfoViewModel.checkContactType(participantJid: jid) {
                member.profileDetail = profile
                refreshData()
            }
        }
    }
}

/**
 * Delegate For managing Profile Events
 */
extension GroupInfoViewController: ProfileEventsDelegate {
    
    func userCameOnline(for jid: String) {
        
    }
    
    func userWentOffline(for jid: String) {
        
    }
    
    func userProfileFetched(for jid: String, profileDetails: ProfileDetails?) {
        
    }
    
    func myProfileUpdated() {
        
    }
    
    func usersProfilesFetched() {
        getGroupMembers()
    }
    
    func blockedThisUser(jid: String) {
        
    }
    
    func unblockedThisUser(jid: String) {
        
    }
    
    func usersIBlockedListFetched(jidList: [String]) {
        
    }
    
    func usersBlockedMeListFetched(jidList: [String]) {
        setupConfiguration()
        self.tableView.reloadSections([0,1], with: .none)
       // refreshData()
    }
    
    func userUpdatedTheirProfile(for jid: String, profileDetails: ProfileDetails) {
        if jid ==  groupID {
            self.profileDetails = profileDetails
           // refreshData()
            self.tableView.reloadSections([0,1], with: .none)
        }else{
            if let updatedUser = groupMembers.firstIndex(where: { detail in
                detail.memberJid == jid
            }){
                getGroupMembers()
            }
        }
    }
    
    func userBlockedMe(jid: String) {
        hanldeUserBlockedUnblocked(jid : jid)
    }
    
    func userUnBlockedMe(jid: String) {
        hanldeUserBlockedUnblocked(jid : jid)
    }
    
    func hideUserLastSeen() {
        
    }
    
    func getUserLastSeen() {
        
    }
    
    func userDeletedTheirProfile(for jid : String, profileDetails:ProfileDetails){
        
    }
}

extension GroupInfoViewController : GroupEventsDelegate {
    
    func didAddNewMemeberToGroup(groupJid: String, newMemberJid: String, addedByMemberJid: String) {
        getGroupMembers()
    }
    
    func didRemoveMemberFromGroup(groupJid: String, removedMemberJid: String, removedByMemberJid: String) {
        if let row = self.groupMembers.firstIndex(where: {$0.memberJid == removedMemberJid}) {
            groupMembers.remove(at: row)
        }
        checkMemberExist()
        refreshData()
        //tableView.reloadSections(IndexSet(integer: 3), with: .none)
    }
    
    func didFetchGroupProfile(groupJid: String) {
        
    }
    
    func didUpdateGroupProfile(groupJid: String) {
        setupConfiguration()
        refreshData()
    }
    
    func didMakeMemberAsAdmin(groupJid: String, newAdminMemberJid: String, madeByMemberJid: String) {
        if let row = self.groupMembers.firstIndex(where: {$0.memberJid == newAdminMemberJid}) {
            groupMembers[row].isAdminMember = true
        }
        tableView.reloadSections(IndexSet(integer: 3), with: .none)
    }
    
    func didRemoveMemberFromAdmin(groupJid: String, removedAdminMemberJid: String, removedByMemberJid: String) {
        if let row = self.groupMembers.firstIndex(where: {$0.memberJid == removedAdminMemberJid}) {
            groupMembers[row].isAdminMember = false
        }
        tableView.reloadSections(IndexSet(integer: 3), with: .none)
    }
    
    func didDeleteGroupLocally(groupJid: String) {
        
    }
    
    func didLeftFromGroup(groupJid: String, leftUserJid: String) {
        getGroupMembers()
        checkMemberExist()
        refreshData()
    }
    
    func didCreateGroup(groupJid: String) {
        
    }
    
    func didFetchGroups(groups: [ProfileDetails]) {
        
    }
    
    func didFetchGroupMembers(groupJid: String) {
        
    }
    
    func didReceiveGroupNotificationMessage(message: ChatMessage) {
        checkMemberExist()
        isAdminMemberGroup()
        refreshData()
    }
}

extension GroupInfoViewController {
    
    func showActionSheet() {
        let alertAction = UIAlertController(title: nil, message:nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: takePhoto.localized, style: .default) { [weak self] _ in
            
            if NetworkReachability.shared.isConnected {
                if UIImagePickerController.isSourceTypeAvailable(.camera){
                    self?.checkCameraPermissionAccess(sourceType: .camera)
                } else {
                    AppAlert.shared.showAlert(view: self!, title: noCamera.localized, message: noCameraMessage.localized, buttonTitle: noCamera.localized)
                }
            } else {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
        }
        
        let galleryAction = UIAlertAction(title: chooseFromGallery.localized, style: .default) { [weak self] _ in
            if NetworkReachability.shared.isConnected {
                self?.checkGalleryPermissionAccess(sourceType: .photoLibrary)
            } else {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
        }
        let cancelAction = UIAlertAction(title: cancel, style: .cancel)
        
        cameraAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
        galleryAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
        cancelAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
        alertAction.addAction(cameraAction)
        alertAction.addAction(galleryAction)
        if(isImagePicked) {
            let removeAction = UIAlertAction(title: removePhoto.localized, style: .default) { [weak self] _ in
                guard let self = self else {
                    return
                }
                if NetworkReachability.shared.isConnected {
                    AppAlert.shared.showAlert(view: self,
                                              title: alert,
                                              message: removePhotoAlert,
                                              buttonOneTitle: cancel,
                                              buttonTwoTitle: removeButton)
                    AppAlert.shared.onAlertAction = { [weak self] (result) ->
                        Void in
                        if result == 1 {
                            self?.isImagePicked = false
                            self?.profileDetails?.image = ""
                            self?.removeGroupProfileImage(fileUrl: self!.profileImageLocalPath)
                        }
                    }
                } else {
                    AppAlert.shared.showToast(message: ErrorMessage.noInternet)
                }
            }
            removeAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
            alertAction.addAction(removeAction)
        }
        alertAction.addAction(cancelAction)
        present(alertAction, animated: true, completion: nil)
    }
    
    /// This function used to check camera Permission
    
    func checkCameraPermissionAccess(sourceType: UIImagePickerController.SourceType) {
        let authorizationStatus =  AVCaptureDevice.authorizationStatus(for: .video)
        switch authorizationStatus {
        case .denied:
            presentCameraSettings()
            break
        case .restricted:
            break
        case .authorized:
            showImagePickerController(sourceType: sourceType)
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    print("Granted access to ")
                    self.showImagePickerController(sourceType: sourceType)
                } else {
                    print("Denied access to")
                }
            }
            break
        @unknown default:
            print("Permission failed")
        }
    }
    
    func presentCameraSettings() {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "",
                message: cameraAccessDenied.localized,
                preferredStyle: UIAlertController.Style.alert
            )
            
            alert.addAction(UIAlertAction(title: cancel.localized, style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: settings.localized, style: .default, handler: { (alert) -> Void in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                    })
                }
            }))
            
            self.present(alert, animated: false, completion: nil)
        }
    }
    
    /// This function used to check gallery Permission
    
    func checkGalleryPermissionAccess(sourceType: UIImagePickerController.SourceType) {
        var config = TatsiConfig.default
        config.supportedMediaTypes = [.image]
        config.firstView = self.firstView
        config.maxNumberOfSelections = 1
        
        let pickerViewController = TatsiPickerViewController(config: config)
        pickerViewController.pickerDelegate = self
        self.present(pickerViewController, animated: true, completion: nil)
    }
    
    func getAssetThumbnail(asset: PHAsset) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var thumbnail = UIImage()
        option.isSynchronous = true
        manager.requestImage(for: asset,
                                targetSize: CGSize(width: 100, height: 100),
                                contentMode: .aspectFit,
                                options: option, resultHandler: {(result, info)->Void in
            thumbnail = result!
        })
        return thumbnail
    }
    
    func getUIImage(asset: PHAsset) -> UIImage? {
        
        var img: UIImage?
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = true
        manager.requestImageData(for: asset, options: options) { data, _, _, _ in
            
            if let data = data {
                img = UIImage(data: data)
            }
        }
        return img
    }
}

extension GroupInfoViewController: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    func showImagePickerController(sourceType: UIImagePickerController.SourceType) {
        DispatchQueue.main.async {
            self.imagePickerController.delegate = self
            self.imagePickerController.mediaTypes = ["public.image"]
            self.imagePickerController.sourceType = sourceType
            self.present(self.imagePickerController, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo
                               info: [UIImagePickerController.InfoKey : Any]) {
        isImagePicked = true
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let cropper = CropperViewController(originalImage: userPickedImage , isCircular: true)
            cropper.delegate = self
            picker.dismiss(animated: true) {
                self.present(cropper, animated: true, completion: nil)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension GroupInfoViewController: CropperViewControllerDelegate {
    func cropperDidConfirm(_ cropper: CropperViewController, state: CropperState?) {
        cropper.dismiss(animated: true, completion: nil)
        
        if groupInfoViewModel.isBlockedByAdmin(groupJid: groupID) {
            return
        }
        
        if let state = state,
           let image = cropper.originalImage.cropped(withCropperState: state) {
            
            print(cropper.isCurrentlyInInitialState)
            print(image)
            
            let string = AppUtils.shared.getRandomString(length: 15)
            let fileName = string ?? ""
            profileImageLocalPath = AppUtils.shared.saveInDirectory(with: image.jpegData(compressionQuality: 1.0), fileName: fileName + jpg) ?? ""
            
            print("localPath-- \( profileImageLocalPath)")
            startLoading(withText: pleaseWait)
            
            groupInfoViewModel.updateGroupProfileImage(groupID: groupID,
                                                       groupProfileImageUrl: profileImageLocalPath) {
                [weak self] success in
                if success {
                    self?.setupConfiguration()
                    self?.refreshData()
                    AppAlert.shared.showToast(message: groupImageUpdateSuccess)
                    self?.isGroupInfoUpdated = true
                }
                self?.stopLoading()
            }
        }
    }
}

//MARK: For Gallery picker - Select photos and allow photos in permisssion

extension GroupInfoViewController: TatsiPickerViewControllerDelegate {
    
    func pickerViewController(_ pickerViewController: TatsiPickerViewController,
                              didSelectCollection collection: PHAssetCollection) {
        self.lastSelectedCollection = collection
        print("User selected collection: \(collection)")
    }
    
    func pickerViewController(_ pickerViewController: TatsiPickerViewController,
                              didPickAssets assets: [PHAsset]) {
        print("Picked assets: \(assets)")
        
        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = false //for icloud backup assets
        let asset : PHAsset = assets .first!
        asset.requestContentEditingInput(with: options) { (contentEditingInput, info) in
            if let uniformTypeIdentifier = contentEditingInput?.uniformTypeIdentifier {
                var fullImage: CIImage? = nil
                if let fullSizeImageURL = contentEditingInput?.fullSizeImageURL {
                    fullImage = CIImage(contentsOf: fullSizeImageURL)
                }
                print("uniformTypeIdentifier", uniformTypeIdentifier)
                //if uniformTypeIdentifier == (kUTTypePNG as String) || uniformTypeIdentifier == (kUTTypeJPEG as String) {
                self.isImagePicked = true
                
                guard let assetToImage = self.getUIImage(asset: asset) else {
                    return
                }
                let cropper = CropperViewController(originalImage: assetToImage, isCircular: true)
                cropper.delegate = self
                pickerViewController.dismiss(animated: true) {
                    self.present(cropper, animated: true, completion: nil)
                }
            }
        }
    }
    
    func setCroppedImage(_ croppedImage: UIImage) {
        self.profileImage?.image = croppedImage
    }
}

// To handle if group is being blocked by user

extension GroupInfoViewController : AdminBlockDelegate {
    func didBlockOrUnblockContact(userJid: String, isBlocked: Bool) {
        getGroupMembers()
    }
    
    func didBlockOrUnblockSelf(userJid: String, isBlocked: Bool) {
        
    }
    
    func didBlockOrUnblockGroup(groupJid: String, isBlocked: Bool) {
        if isBlocked && groupID == groupJid {
           navigateOnGroupBlock()
        }
    }
    
}

extension GroupInfoViewController {
    func navigateOnGroupBlock() {
        optionsController?.dismissView()
        self.dismiss(animated: true, completion: nil)
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.popToRootViewController(animated: true)
        executeOnMainThread { [weak self] in
            self?.stopLoading()
            AppAlert.shared.showToast(message: groupNoLongerAvailable)
        }
    }
}

// For reporting
extension GroupInfoViewController {
    func showReportOptions() {
        let values : [String] = ChatActions.allCases.map { $0.rawValue }
        var actions = [(String, UIAlertAction.Style)]()
        values.forEach { title in
            actions.append((title, UIAlertAction.Style.default))
        }
        
        if ChatUtils.isMessagesAvailableFor(jid: profileDetails?.jid ?? "") {
            if let profileDetails = profileDetails {
                reportForJid(profileDetails: profileDetails, isFromGroupInfo: false)
            }
        } else {
            AppAlert.shared.showToast(message: noMessgesToReport)
        }
        
        // commented this code temporarly. It may be used in feature case
        
//        AppActionSheet.shared.showActionSeet(title: report, message: "", actions: actions) { [weak self] didCancelTap, tappedOption in
//            if !didCancelTap {
//                switch tappedOption {
//                case ChatActions.report.rawValue:
//                    if ChatUtils.isMessagesAvailableFor(jid: self?.profileDetails?.jid ?? "") {
//                        self?.showReportingGroupOptions(completionHandler: { action in
//                            print("\(action)")
//                            if let profileDetails = self?.profileDetails {
//                                if action == GroupReportActions.report.rawValue {
//                                    self?.reportForJid(profileDetails: profileDetails, isFromGroupInfo: true)
//                                }else if action == GroupReportActions.reportAndExit.rawValue {
//                                    self?.reportAndExitFromGroup(jid: profileDetails.jid, completionHandler: { isReported in
//                                        if isReported {
//                                            self?.leaveFromGroup()
//                                        }
//                                    })
//                                }
//                            }
//                        })
//                    } else {
//                        AppAlert.shared.showToast(message: noMessgesToReport)
//                    }
//                default:
//                    print(" \(tappedOption)")
//                }
//            }
//        }
    }
}

extension GroupInfoViewController : AvailableFeaturesDelegate {
    
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
        tableView?.reloadSections([1,2,4,5,6], with: .none)
    }
}



