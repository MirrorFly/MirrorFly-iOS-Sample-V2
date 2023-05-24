//
//  GroupCreationPreviewController.swift
//  MirrorflyUIkit
//
//  Created by John on 24/11/21.
//

import UIKit
import MirrorFlySDK

class GroupCreationPreviewController: UIViewController {
    
    let groupCreationViewModel = GroupCreationViewModel()
    var groupCreationDeletgate : GroupCreationDelegate?
    @IBOutlet weak var addImageView: UIImageView!
    @IBOutlet weak var contactNameTextField: UITextField!
    @IBOutlet weak var participantTableView: UITableView!
    
    var searchedParticipants = [ProfileDetails]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        configure()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        ChatManager.shared.adminBlockDelegate = self
        ContactManager.shared.profileDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ChatManager.shared.adminBlockDelegate = nil
        ContactManager.shared.profileDelegate = nil
    }
    
    func setUpUI() {
        setUpStatusBar()
        participantTableView.delegate = self
        participantTableView.dataSource = self
        participantTableView.register(UINib(nibName: Identifiers.participantCell , bundle: .main), forCellReuseIdentifier: Identifiers.participantCell)
        
        participantTableView.register(UINib(nibName: Identifiers.noResultFound , bundle: .main), forCellReuseIdentifier: Identifiers.noResultFound)
    
        contactNameTextField.addTarget(self, action: #selector(search(_ :)), for: .editingChanged)
        
        addImageView.isUserInteractionEnabled = true
        addImageView.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(didBackTap(_:))))
        addImageView.setImageInsect(insect: CGFloat(-6))
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func configure() {
        searchedParticipants = GroupCreationData.participants
        searchedParticipants = searchedParticipants.sorted(by: { getUserName(jid : $0.jid, name: $0.name, nickName: $0.nickName, contactType: $0.contactType).lowercased() < getUserName(jid : $1.jid, name: $1.name, nickName: $1.nickName, contactType: $1.contactType).lowercased() })
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            participantTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height + participantTableView.rowHeight + 90, right: 0)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        participantTableView.contentInset = .zero
    }


    @IBAction func didBackTap(_ sender: Any) {
        navigateBack()
    }
    
    @IBAction func didCreateTap(_ sender: Any) {
        createGroup()
    }
    
    func createGroup() {
        if !NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            return
        }
        if !groupCreationViewModel.checkMinimumParticipant(selectedParticipants: GroupCreationData.participants) {
            AppAlert.shared.showToast(message: atLeastTwoParticipant)
            return
        }
        startLoading(withText: pleaseWait)
        groupCreationViewModel.createGroup(groupCallBack: { [weak self] isSuccess, message in
            self?.showSuccessOrFailure(isSuccess: isSuccess, message: message)
        })
    }
    
    @objc func didAddTap(_ sender: UIImageView) {
       navigateBack()
    }
    
    func navigateBack() {
        navigationController?.popViewController(animated: true)
    }
    
    func showSuccessOrFailure(isSuccess : Bool, message: String) {
        print("showSuccessOrFailure \(isSuccess)")
        stopLoading()
        if isSuccess {
            AppAlert.shared.showAlert(view: self, title: alert, message: groupCreatedSuccess, buttonTitle: okButton)
            groupCreationViewModel.initializeGroupCreationData()
            groupCreationDeletgate?.onGroupCreated()
            navigateToRecentChat()
        } else {
            
            if(message.contains("403")){
                let message = AppUtils.shared.getErrorMessage(description: message)
                AppAlert.shared.showAlert(view: self, title: alert, message: message, buttonTitle: okButton)
            }
            else{
                
                AppAlert.shared.showAlert(view: self, title: alert, message: groupCreatedFailure, buttonOneTitle: okButton, buttonTwoTitle: retry)
                
                AppAlert.shared.onAlertAction = { [weak self] (result) ->
                    Void in
                    if result == 1 {
                        self?.createGroup()
                    } else if result == 0{
                       
                    }
                }
            }
        }
    }
    
    func navigateToRecentChat() {
        let controllers : Array = self.navigationController!.viewControllers
        for controller in controllers {
            if controller is MainTabBarController  {
                self.navigationController!.popToViewController(controller, animated: true)

            }
        }
    }

    @objc func search(_ textfield : UITextField) {
        searchedParticipants = groupCreationViewModel.searchContacts(text: textfield.text ?? "", contacts: GroupCreationData.participants)
        self.participantTableView.reloadData()
    }
    
}

// TableViewDelegate
extension GroupCreationPreviewController : UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchedParticipants.count > 0 {
            return searchedParticipants.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if searchedParticipants.count > 0 {
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.participantCell, for: indexPath) as? ParticipantCell)!
            let profileDetail = searchedParticipants[indexPath.row]
            cell.nameUILabel?.text = getUserName(jid : profileDetail.jid,name: profileDetail.name, nickName: profileDetail.nickName, contactType: profileDetail.contactType)
            cell.statusUILabel?.text = profileDetail.status
            let color = ChatUtils.getColorForUser(userName: profileDetail.name)
            cell.setImage(imageURL: profileDetail.image, name: getUserName(jid: profileDetail.jid, name: profileDetail.name, nickName: profileDetail.nickName, contactType: profileDetail.contactType), color: color, chatType: profileDetail.profileChatType, jid: profileDetail.jid)
            cell.checkBoxImageView?.isHidden = true
            cell.removeButton?.isUserInteractionEnabled = true
            cell.removeButton?.isHidden = true
            cell.removeButton?.tag = indexPath.row
            cell.removeButton?.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(removeParticipant(sender:))))
            cell.removeButton?.setImageInsect(insect: CGFloat(-14))
            cell.removeIcon?.tag = indexPath.row
            cell.removeIcon?.addTarget(self, action: #selector(removeParticipant(sender:)), for: .touchUpInside)
            cell.emptyView?.isHidden = false
            cell.setTextColorWhileSearch(searchText: contactNameTextField.text ?? "", profileDetail: profileDetail)
            return cell
        } else {
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.noResultFound, for: indexPath) as? NoResultFoundCell)!
            return cell
        }
    }
    
    
    
    @objc func removeParticipant(sender : UIButton) {
        print("removeParticipant \(sender.tag)")
        let participant = searchedParticipants[sender.tag]
        searchedParticipants = groupCreationViewModel.removeParticipant(participant: participant, participantList: searchedParticipants)
        GroupCreationData.participants = searchedParticipants
        contactNameTextField.text = ""
        participantTableView.reloadData()
    }
    
}

extension GroupCreationPreviewController : AdminBlockDelegate {
    func didBlockOrUnblockContact(userJid: String, isBlocked: Bool) {
        checkingUserForBlocking(jid: userJid, isBlocked: isBlocked)
    }
    
    func didBlockOrUnblockSelf(userJid: String, isBlocked: Bool) {
        
    }
    
    func didBlockOrUnblockGroup(groupJid: String, isBlocked: Bool) {
        
    }
}

// To handle user blocking by admin
extension GroupCreationPreviewController {
    
    func checkingUserForBlocking(jid : String, isBlocked : Bool) {
        searchedParticipants = removeAdminBlockedContact(profileList: searchedParticipants, jid: jid, isBlockedByAdmin: isBlocked)
        GroupCreationData.participants = removeAdminBlockedContact(profileList: GroupCreationData.participants, jid: jid, isBlockedByAdmin: isBlocked)
        executeOnMainThread { [weak self] in
            self?.participantTableView.reloadData()
        }
    }
    
}


extension GroupCreationPreviewController : ProfileEventsDelegate {
    
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
        
    }
    
    func userUpdatedTheirProfile(for jid: String, profileDetails: ProfileDetails) {
        participantTableView.reloadData()
    }
    
    func userBlockedMe(jid: String) {
        participantTableView.reloadData()
    }
    
    func userUnBlockedMe(jid: String) {
        participantTableView.reloadData()
    }
    
    func hideUserLastSeen() {
        
    }
    
    func getUserLastSeen() {
        
    }
    
    func userDeletedTheirProfile(for jid : String, profileDetails:ProfileDetails){
        searchedParticipants = groupCreationViewModel.removeParticipant(participant: profileDetails, participantList: searchedParticipants)
        participantTableView.reloadData()
    }
}
