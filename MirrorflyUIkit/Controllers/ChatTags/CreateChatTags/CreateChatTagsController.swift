//
//  CreateChatTagsController.swift
//  MirrorflyUIkit
//
//  Created by MohanRaj on 09/02/23.
//

import UIKit
import MirrorFlySDK

protocol CreateChatTagsDelegate {
    func onChatTagCreated(chatTag: ChatTagsModel)
}

class CreateChatTagsController: UIViewController {
    
    
    @IBOutlet weak var userListTable: UITableView!
    @IBOutlet weak var tagNameTxtField: UITextField!
    @IBOutlet weak var createTagButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    public var tagName = emptyString()
    public var currentTagDetails: ChatTagsModel = ChatTagsModel()
    public var isFromUpdatTag: Bool = false
    public var isFromDefaultTag: Bool = false
    
    var selectedUsersArray: [RecentChat] = []
    var membersJidList: [String] = [String]()
    var randomColors = [UIColor?]()
    
    private var chatTagsArray = [ChatTagsModel]()
    
    
    public var delegate: CreateChatTagsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getAllChatTags()
        getCurrentTagDetails()
        setupSubviews()
    }
    
    func setupSubviews() {
        tagNameTxtField.delegate = self
        randomColors = AppUtils.shared.setRandomColors(totalCount: selectedUsersArray.count)
        userListTable?.estimatedRowHeight = 70
        userListTable?.delegate = self
        userListTable?.dataSource = self
        userListTable.keyboardDismissMode = .onDrag
        userListTable?.separatorStyle = .none
        let nib = UINib(nibName: "UserListCell", bundle: .main)
        userListTable?.register(nib, forCellReuseIdentifier: "UserListCell")
        if let tv = userListTable{
            tv.contentSize = CGSize(width: tv.frame.size.width, height: tv.contentSize.height);
        }
    }
    
    @IBAction func addPeopleOrGroupBtnAction(_ sender: Any) {
        
        self.view.endEditing(false)
        
        if let vc = UIStoryboard(name: "ChatTags", bundle: nil).instantiateViewController(withIdentifier: "AddPeopleOrGroupController") as? AddPeopleOrGroupController {
            vc.delegate = self
            vc.isFromUpdateTag = isFromUpdatTag
            vc.getSelectedChat = selectedUsersArray
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        GroupManager.shared.groupDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GroupManager.shared.groupDelegate = nil
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func createTagsAction(_ sender: UIButton) {
        
        self.view.endEditing(true)
        
        tagNameTxtField.text = tagNameTxtField.text?.trimmingCharacters(in: .whitespaces)
        let isDuplicateExist = checkForDuplicateTagName(tagName:  tagNameTxtField.text ?? "")
        
        
        if !isDuplicateExist {
            
            if selectedUsersArray.count > 0 && tagNameTxtField.text?.count ?? 0 > 0 {
                createChatTags()
            }else if tagNameTxtField.text?.count == 0 {
                showToastWithMessage(message: "Please enter tag name")
                
            } else {
                showToastWithMessage(message: "Please select people or group")
            }
        }
    }
    
    func createChatTags() {
        
        var chatTagModel = ChatTagsModel()
        chatTagModel.tagId = (isFromUpdatTag) ? currentTagDetails.tagId : ""
        chatTagModel.tagname = tagNameTxtField.text
        chatTagModel.memberIdList = membersJidList
        
            ChatManager.createOrUpdateChatTagdata(chatTag: chatTagModel) { isSuccess, error, data in
                
                if isSuccess{
                    var flyData = data
                    if let chatTag = flyData.getData() as? ChatTagsModel{
                        self.delegate?.onChatTagCreated(chatTag: chatTag)
                    }
                    self.navigationController?.popViewController(animated: true)
                }else {
                    self.showToastWithMessage(message: "Unexpected Error!")
                }
            }
    }
    
    func getCurrentTagDetails() {
        
        titleLabel.text = (isFromUpdatTag) ? "Edit Tag" : "Create Tag"
        createTagButton.isHidden = ((tagName.count) != 0) ? false : true
        createTagButton.setTitle((isFromUpdatTag) ? "UPDATE" : "CREATE", for: .normal)
        
        tagNameTxtField.text = tagName
        
        let currentTagMembers: [String]  = currentTagDetails.memberIdList
        membersJidList = currentTagMembers
        
        for memberID in currentTagMembers {
            if let member = ChatManager.getRecentChatOf(jid: memberID) {
                member.isSelected = true
                selectedUsersArray.append(member)
            }
        }
    }
    
    func getAllChatTags() {
        ChatManager.getCustomChatTagsdata(completionHandler: { isSuccess, error, data in
            if isSuccess {
                var flyData = data
                if let chatTags = flyData.getData() as? [ChatTagsModel]{
                    self.chatTagsArray = chatTags
                }
            }
        })
    }
    
    func checkForDuplicateTagName(tagName: String) -> Bool {
        
        if isFromUpdatTag {
            return false
            
        } else {
            
            if chatTagsArray.contains(where: {$0.tagname?.compare(tagName, options: .caseInsensitive) == .orderedSame}) {
                showToastWithMessage(message: "Tag name already exist")
                return true
            } else {
                
                return false
            }
        }
    }
    
    func showToastWithMessage(message: String) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AppAlert.shared.showToast(message: message)
        }
    }
}

// TableViewDelegate
extension CreateChatTagsController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return selectedUsersArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = (tableView.dequeueReusableCell(withIdentifier: "UserListCell", for: indexPath) as? UserListCell) {
            let recentChatDetails = selectedUsersArray[indexPath.row]
            cell.contentView.alpha = getBlocked(jid: recentChatDetails.jid) ? 0.6 : 1.0
            let hashcode = recentChatDetails.profileName.hashValue
            let color = randomColors[abs(hashcode) % randomColors.count]
            cell.setUserListDetails(recentChat: recentChatDetails, color: color ?? .gray)
            
            if recentChatDetails.profileType == .groupChat {
                let membersCount = GroupManager.shared.getParticipantCountOfGroup(groupJid: recentChatDetails.jid)
                cell.subTitleLabel.isHidden = false
                cell.subTitleLabel.text = "\(membersCount) members"
            } else {
                cell.subTitleLabel.isHidden = true
            }
            cell.checkBoxImage.isHidden = true
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let alertController = UIAlertController(title: "", message: "This will remove your added people/group in tags", preferredStyle: .actionSheet)
            
               let removeAction = UIAlertAction(title: removeTitle, style: .destructive) { (action:UIAlertAction!) in
                   
                   self.selectedUsersArray.remove(at: indexPath.row)
                   self.userListTable.reloadData()
                   
                   self.membersJidList = self.selectedUsersArray.compactMap { $0.jid }
                   
               }
               let cancelAction = UIAlertAction(title: cancelUppercase, style: .cancel) { (action:UIAlertAction!) in
                   print("Cancel button tapped");
               }
        
               alertController.addAction(removeAction)
               alertController.addAction(cancelAction)
               self.present(alertController, animated: true, completion:nil)
    }
    
    private func getBlocked(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlocked ?? false
    }
}

extension CreateChatTagsController: AddPeopleOrGroupDelegate {
    
    func selectedPeopleOrGroup(people: [RecentChat]) {
        
        selectedUsersArray = people
        membersJidList = selectedUsersArray.compactMap { $0.jid }
        randomColors = AppUtils.shared.setRandomColors(totalCount: selectedUsersArray.count)
        userListTable.reloadData()
    }
}

extension CreateChatTagsController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
       
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let maxLength = 20
        let currentString: NSString = (textField.text ?? "") as NSString
        let newString: NSString =  currentString.replacingCharacters(in: range, with: string) as NSString
        
        if(newString.length > maxLength){
            
            self.view.endEditing(true)
            showToastWithMessage(message: "Tag name should be less than 20 characters")
        }
        
        createTagButton.isHidden = (newString.length != 0) ? false : true
        return newString.length <= maxLength
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
       
        createTagButton.isHidden = ((textField.text?.count) != 0) ? false : true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        createTagButton.isHidden = true
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}

extension CreateChatTagsController : GroupEventsDelegate {
    func didAddNewMemeberToGroup(groupJid: String, newMemberJid: String, addedByMemberJid: String) {
        
    }
    
    func didRemoveMemberFromGroup(groupJid: String, removedMemberJid: String, removedByMemberJid: String) {
        
    }
    
    func didFetchGroupProfile(groupJid: String) {
        
    }
    
    func didUpdateGroupProfile(groupJid: String) {
        
    }
    
    func didMakeMemberAsAdmin(groupJid: String, newAdminMemberJid: String, madeByMemberJid: String) {
        
    }
    
    func didRevokedAdminAccess(groupJid: String, revokedAdminMemberJid: String, revokedByMemberJid: String) {
        
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
        
    }
    
    func didReceiveGroupNotificationMessage(message: MirrorFlySDK.ChatMessage) {
        
    }
    
    func didSuperAdminDeleteGroup(groupJid: String, groupName: String) {
        deleteGroupChat(groupJid)
    }
    
    
}

extension CreateChatTagsController {
    func deleteGroupChat(_ groupJid: String) {
        DispatchQueue.main.async { [weak self] in
            self?.selectedUsersArray = self?.selectedUsersArray.filter({ $0.jid != groupJid}) ?? []
            self?.userListTable.reloadData()
        }
    }
}
